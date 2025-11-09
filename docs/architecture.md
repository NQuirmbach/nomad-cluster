# Nomad Cluster Architektur in Azure

## Überblick

Dieses Dokument beschreibt die geplante Architektur für einen hochverfügbaren Nomad Cluster in Azure, der mittels Terraform und Ansible bereitgestellt wird.

## Architektur-Komponenten

### 1. Netzwerk-Architektur

#### Virtual Network (VNet)
- **Address Space**: 10.0.0.0/16
- **Subnets**:
  - **Management Subnet**: 10.0.1.0/24 (Bastion, Jump Hosts)
  - **Server Subnet**: 10.0.10.0/24 (Nomad Server Nodes)
  - **Client Subnet**: 10.0.20.0/24 (Nomad Client Nodes)
  - **Data Subnet**: 10.0.30.0/24 (Consul, Vault optional)

#### Network Security Groups (NSGs)
- **Server NSG**: 
  - Erlaubt 4646-4648 (Nomad RPC, HTTP, Serf)
  - Erlaubt 8300-8302, 8500, 8600 (Consul falls genutzt)
  - Nur internes VNet Traffic
- **Client NSG**:
  - Erlaubt 4646-4648
  - Erlaubt Application Ports (dynamic range)
- **Management NSG**:
  - SSH/RDP nur von Bastion
  - HTTPS für Management Interfaces

#### Load Balancer
- **Internal Load Balancer** für Nomad Server (Port 4646)
- **Azure Application Gateway** (optional) für externe Workload-Zugriffe

### 2. Compute-Ressourcen

#### Nomad Server Nodes
- **VM Typ**: Standard_D2s_v5 oder höher
- **Anzahl**: 3 oder 5 Nodes (ungerade Anzahl für Consensus)
- **OS**: Ubuntu 22.04 LTS
- **Availability**:
  - **Availability Zones**: Verteilung über 3 Zones
  - **Oder**: Availability Set mit 3 Fault Domains
- **Managed Disks**: Premium SSD (P10: 128 GB)

#### Nomad Client Nodes
- **VM Typ**: Variable je nach Workload (z.B. Standard_D4s_v5)
- **Anzahl**: Mindestens 3 Nodes, skalierbar via VMSS
- **OS**: Ubuntu 22.04 LTS
- **Scaling**: Azure Virtual Machine Scale Sets (VMSS)
- **Availability**: Über Availability Zones verteilt

#### Bastion/Jump Host
- **Azure Bastion Service** (empfohlen) oder dedizierte Jump Box
- Für sicheren SSH-Zugriff auf private VMs

### 3. Service Discovery & Configuration

#### Consul (empfohlen)
- **3 oder 5 Consul Server** (co-located mit Nomad Servern oder separate VMs)
- Service Discovery für Nomad
- Service Mesh Capabilities (optional)
- Key/Value Store für Configuration

#### Alternative: Azure Service Discovery
- Azure Private DNS Zones
- Weniger Features, aber einfachere Integration

### 4. Storage

#### Data Persistence
- **Azure Managed Disks**:
  - OS Disks: Premium SSD
  - Data Disks: Premium oder Ultra SSD je nach Performance-Anforderungen
- **Azure Files**: Für shared storage zwischen Workloads (optional)
- **Azure Blob Storage**: Für Artifacts und Backups

### 5. Secrets Management

#### Azure Key Vault
- **Primär**: Zertifikate, SSH Keys, API Tokens
- **Integration**: Via Managed Identity

#### Vault by HashiCorp (optional)
- Für erweiterte Secrets Management Features
- Dynamic Secrets für Datenbanken
- Co-located mit Nomad/Consul

### 6. Monitoring & Logging

#### Azure Monitor
- **VM Insights**: Für VM-Metriken
- **Application Insights**: Für Application-Level Telemetry
- **Log Analytics Workspace**: Zentrales Logging

#### Prometheus & Grafana (optional)
- Nomad, Consul Metriken
- Custom Dashboards
- Deployment als Nomad Jobs

### 7. Security

#### Identity & Access Management
- **Managed Identities**: Für Azure Resource Zugriff
- **Azure AD Integration**: User Authentication
- **RBAC**: Feingranulare Zugriffssteuerung

#### Encryption
- **Encryption at Rest**: Managed Disks mit Azure Encryption
- **Encryption in Transit**: TLS für alle Nomad/Consul Kommunikation
- **Network Security**: NSGs + Azure Firewall (optional)

### 8. Backup & Disaster Recovery

#### Backup Strategy
- **Azure Backup**: VM Snapshots (täglich)
- **Consul/Nomad State**: Snapshots ins Blob Storage
- **Geo-Redundant Storage**: Für kritische Daten

#### Disaster Recovery
- **Azure Site Recovery**: Für VM Replikation (optional)
- **Multi-Region Setup**: Für höchste Verfügbarkeit (optional)

## Architektur-Diagramm (Konzeptuell)

```
┌─────────────────────────────────────────────────────────────┐
│                        Azure Region                          │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Virtual Network                     │   │
│  │                    (10.0.0.0/16)                      │   │
│  │                                                        │   │
│  │  ┌────────────────┐  ┌────────────────────────────┐  │   │
│  │  │  Management    │  │      Server Subnet         │  │   │
│  │  │    Subnet      │  │      (10.0.10.0/24)        │  │   │
│  │  │ (10.0.1.0/24)  │  │                            │  │   │
│  │  │                │  │  ┌──────┐ ┌──────┐ ┌────┐ │  │   │
│  │  │  ┌──────────┐  │  │  │Server│ │Server│ │Srv │ │  │   │
│  │  │  │ Bastion  │  │  │  │  1   │ │  2   │ │ 3  │ │  │   │
│  │  │  │          │  │  │  │(AZ-1)│ │(AZ-2)│ │(AZ3│ │  │   │
│  │  │  └──────────┘  │  │  └──────┘ └──────┘ └────┘ │  │   │
│  │  └────────────────┘  │         ↑                  │  │   │
│  │                      │    ┌────┴─────┐            │  │   │
│  │                      │    │ Internal │            │  │   │
│  │                      │    │   LB     │            │  │   │
│  │                      │    └────┬─────┘            │  │   │
│  │                      └─────────┼──────────────────┘  │   │
│  │                                ↓                     │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │          Client Subnet (10.0.20.0/24)       │    │   │
│  │  │                                              │    │   │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐        │    │   │
│  │  │  │Client 1│  │Client 2│  │Client N│        │    │   │
│  │  │  │ (VMSS) │  │ (VMSS) │  │ (VMSS) │        │    │   │
│  │  │  └────────┘  └────────┘  └────────┘        │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                        │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Key Vault  │  │ Log Analytics│  │ Blob Storage │       │
│  │             │  │  Workspace   │  │  (Backups)   │       │
│  └─────────────┘  └──────────────┘  └──────────────┘       │
└───────────────────────────────────────────────────────────────┘
```

## Resource Gruppen Struktur

```
nomad-cluster-rg
├── network-rg (VNet, NSGs, Load Balancers)
├── compute-rg (VMs, VMSS)
├── storage-rg (Managed Disks, Storage Accounts)
├── security-rg (Key Vault)
└── monitoring-rg (Log Analytics, Dashboards)
```

## Terraform Module Struktur

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── nomad-servers/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── nomad-clients/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── security/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── ansible/
    ├── inventory/
    │   └── azure_rm.yml
    ├── playbooks/
    │   ├── nomad-server.yml
    │   ├── nomad-client.yml
    │   ├── consul.yml
    │   └── common.yml
    └── roles/
        ├── nomad/
        ├── consul/
        └── monitoring/
```

## Ansible Automation

### Provisioning Workflow
1. **Terraform**: Infrastructure Deployment (VMs, Network, etc.)
2. **Ansible Dynamic Inventory**: Azure RM Plugin
3. **Ansible Playbooks**: Software Installation & Configuration
   - OS Hardening
   - Nomad Server Installation
   - Nomad Client Installation
   - Consul Installation (optional)
   - Monitoring Agent Setup

## Kosten-Schätzung (Monatlich)

### Minimale Produktion-Setup
- **3x Nomad Server** (Standard_D2s_v5): ~€200
- **3x Nomad Client** (Standard_D4s_v5): ~€400
- **Networking** (VNet, LB, Bastion): ~€150
- **Storage** (Managed Disks): ~€50
- **Monitoring** (Log Analytics): ~€50
- **Gesamt**: **~€850/Monat**

### Erweiterte Setup mit HA
- **5x Nomad Server**: ~€330
- **5-10x Nomad Client** (VMSS): ~€650-€1300
- **Additional Services**: ~€300
- **Gesamt**: **~€1280-€1930/Monat**

## Skalierungs-Strategie

### Horizontale Skalierung
- **Client Nodes**: Auto-Scaling via VMSS basierend auf CPU/Memory
- **Workload Distribution**: Nomad Scheduler verteilt Jobs automatisch

### Vertikale Skalierung
- **VM Sizing**: Anpassung der VM-Typen nach Bedarf
- **Disk Performance**: Upgrade auf Ultra SSD bei Bedarf

## High Availability Überlegungen

### Server HA
- **Quorum**: 3 oder 5 Server für Raft Consensus
- **Availability Zones**: Verteilung über 3 AZs
- **Internal Load Balancer**: Health Checks + Auto-Failover

### Client HA
- **VMSS**: Automatische Ersetzung fehlerhafter VMs
- **Job Rescheduling**: Nomad startet Jobs auf gesunden Nodes neu

### Data HA
- **Consul State**: Repliziert über alle Server
- **Nomad State**: Repliziert über alle Server
- **Backups**: Täglich in Geo-Redundant Storage

## Security Best Practices

1. **Principle of Least Privilege**: Minimale Berechtigungen für alle Komponenten
2. **Network Segmentation**: Strikte NSG Rules
3. **Encryption Everywhere**: TLS für alle Verbindungen
4. **Managed Identities**: Keine Credentials in Code
5. **Regular Updates**: Automated Patching via Azure Update Management
6. **Audit Logging**: Alle Zugriffe werden geloggt
7. **Secrets Rotation**: Automatische Rotation via Key Vault

## Nächste Schritte

1. **Review & Approval**: Architektur-Review mit Stakeholders
2. **Environment Setup**: Azure Subscription, Service Principal, etc.
3. **Terraform Development**: Module-Entwicklung
4. **Ansible Development**: Playbook-Entwicklung
5. **Testing**: Deployment in Dev/Test Environment
6. **Production Rollout**: Staging → Production Migration
7. **Documentation**: Runbooks, Troubleshooting Guides

## Referenzen

- [Nomad Reference Architecture](https://developer.hashicorp.com/nomad/docs/install/production)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Azure Modules](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/)
