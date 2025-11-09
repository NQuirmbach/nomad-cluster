# Architektur-Entscheidungen für Nomad Cluster in Azure

## ADR-001: Verwendung von Terraform für Infrastructure as Code

### Status
Accepted

### Kontext
Wir benötigen ein IaC-Tool für die Bereitstellung der Azure-Infrastruktur.

### Entscheidung
Verwendung von Terraform als primäres IaC-Tool.

### Begründung
- **Cloud-agnostisch**: Terraform unterstützt Multi-Cloud Szenarien
- **State Management**: Native State-Verwaltung mit Remote Backends
- **Große Community**: Umfangreiche Module und Dokumentation
- **HashiCorp Stack**: Konsistenz mit Nomad, Consul, Vault
- **Azure Provider**: Vollständige Unterstützung aller Azure-Ressourcen

### Alternativen
- **Bicep/ARM**: Azure-nativ, aber weniger flexibel für Multi-Cloud
- **Pulumi**: Modernere Alternative, aber kleinere Community
- **Ansible**: Besser für Configuration Management, weniger für Infrastructure Provisioning

---

## ADR-002: Verwendung von Ansible für Configuration Management

### Status
Accepted

### Kontext
Nach der Infrastructure-Bereitstellung müssen VMs konfiguriert werden (Software-Installation, Konfiguration).

### Entscheidung
Verwendung von Ansible für Configuration Management.

### Begründung
- **Agentless**: Kein Agent auf Ziel-VMs erforderlich
- **Idempotent**: Wiederholte Ausführung sicher
- **YAML-basiert**: Einfache Syntax und Lesbarkeit
- **Azure Integration**: Dynamisches Inventory über Azure RM Plugin
- **Große Community**: Viele fertige Roles verfügbar

### Alternativen
- **Cloud-Init**: Nur für initiales Bootstrapping geeignet
- **Chef/Puppet**: Komplexer, erfordern Agents
- **Azure Automation DSC**: Azure-spezifisch, weniger flexibel

---

## ADR-003: Server-Anzahl (3 vs 5 Nodes)

### Status
Accepted (3 Nodes als Minimum, 5 für Production)

### Kontext
Nomad Server verwenden Raft Consensus, benötigen ungerade Anzahl für Quorum.

### Entscheidung
- **Dev/Test**: 3 Server Nodes
- **Production**: 5 Server Nodes (empfohlen)

### Begründung
**3 Nodes:**
- Toleriert 1 Node Ausfall
- Geringere Kosten
- Ausreichend für kleinere Setups

**5 Nodes:**
- Toleriert 2 Node Ausfälle
- Höhere Verfügbarkeit
- Bessere Performance bei Read-Heavy Workloads
- Empfohlen für kritische Production Workloads

### Trade-offs
- 3 Nodes: Geringere Kosten, aber Single Point of Failure bei gleichzeitigen Ausfällen
- 5 Nodes: Höhere Kosten (~€330 vs €200/Monat), aber robustere HA

---

## ADR-004: Verwendung von Availability Zones

### Status
Accepted

### Kontext
Azure bietet Availability Zones für höhere Verfügbarkeit innerhalb einer Region.

### Entscheidung
Verteilung der Server und Client Nodes über 3 Availability Zones.

### Begründung
- **Physische Isolation**: Schutz vor Datacenter-Ausfällen
- **SLA Verbesserung**: 99.99% vs 99.95% mit Availability Sets
- **Keine zusätzlichen Kosten**: Nur für Inter-AZ Traffic
- **Azure Standard**: Best Practice für Production Workloads

### Alternativen
- **Availability Sets**: Geringere Isolation, niedrigeres SLA
- **Einzelne Zone**: Keine Ausfallsicherheit bei Zone-Problemen

---

## ADR-005: Consul für Service Discovery

### Status
Accepted (empfohlen)

### Kontext
Nomad benötigt Service Discovery für dynamische Workload-Kommunikation.

### Entscheidung
Verwendung von Consul als Service Discovery Lösung.

### Begründung
- **Native Integration**: Consul ist für Nomad entwickelt
- **Service Mesh**: Erweiterte Networking-Features
- **KV Store**: Configuration Management integriert
- **Health Checks**: Automatische Service Health Monitoring
- **DNS Interface**: Einfache Integration für Legacy Apps

### Alternativen
- **Azure Service Discovery**: Einfacher, aber weniger Features
- **Kubernetes Service Discovery**: Nicht mit Nomad kompatibel
- **Custom DNS**: Zu simpel für dynamische Workloads

---

## ADR-006: Azure Key Vault für Secrets Management

### Status
Accepted

### Kontext
Sensible Daten (Zertifikate, Keys, Passwords) müssen sicher gespeichert werden.

### Entscheidung
Azure Key Vault als primärer Secrets Store.

### Begründung
- **Managed Service**: Keine Wartung erforderlich
- **Compliance**: FIPS 140-2 Level 2 zertifiziert
- **Integration**: Native Azure-Integration via Managed Identity
- **Auditing**: Vollständiges Access Logging
- **Key Rotation**: Automatisierte Rotation möglich

### Zusätzlich (Optional)
- **HashiCorp Vault**: Für erweiterte Features (Dynamic Secrets, PKI)
- **Hybrid Ansatz**: Key Vault für Azure-Credentials, Vault für Application-Secrets

---

## ADR-007: Virtual Machine Scale Sets für Client Nodes

### Status
Accepted

### Kontext
Client Nodes müssen dynamisch skalieren können basierend auf Workload.

### Entscheidung
Verwendung von Azure VMSS (Virtual Machine Scale Sets) für Nomad Clients.

### Begründung
- **Auto-Scaling**: CPU/Memory-basiertes Scaling
- **Self-Healing**: Automatische Ersetzung fehlerhafter VMs
- **Uniform Orchestration**: Konsistente Konfiguration aller Nodes
- **Rolling Updates**: Zero-Downtime Updates möglich
- **Cost Optimization**: Automatisches Scale-Down bei geringer Last

### Alternativen
- **Einzelne VMs**: Keine Auto-Scaling Capabilities
- **Azure Container Instances**: Nicht für langlebige Workloads geeignet

---

## ADR-008: Internal Load Balancer für Nomad Server

### Status
Accepted

### Kontext
Clients und externe Tools müssen mit Nomad Server kommunizieren.

### Entscheidung
Azure Internal Load Balancer vor Nomad Server Nodes.

### Begründung
- **High Availability**: Automatisches Failover bei Node-Ausfall
- **Health Checks**: Nur gesunde Server erhalten Traffic
- **Single Endpoint**: Clients benötigen nur eine IP/DNS
- **Keine externe Exposition**: Sicherheit durch private IPs

### Konfiguration
- **Frontend**: Private IP im Server Subnet
- **Backend Pool**: Alle Nomad Server Nodes
- **Health Probe**: HTTP GET auf `/v1/status/leader` (Port 4646)

---

## ADR-009: Network Segmentation mit Subnets

### Status
Accepted

### Kontext
Verschiedene Komponenten benötigen unterschiedliche Sicherheitslevel.

### Entscheidung
Separate Subnets für Management, Server, Clients, und Data Tier.

### Begründung
- **Security Isolation**: NSGs können granular konfiguriert werden
- **Traffic Control**: Flow Logs pro Subnet
- **Compliance**: Network Segmentation ist Best Practice
- **Flexibility**: Einfachere Erweiterung und Migration

### Subnet Design
```
Management: 10.0.1.0/24   - Bastion, Monitoring
Server:     10.0.10.0/24  - Nomad Server Nodes
Client:     10.0.20.0/24  - Nomad Client Nodes
Data:       10.0.30.0/24  - Consul, Vault, Databases (optional)
```

---

## ADR-010: Premium SSD für Server Nodes

### Status
Accepted

### Kontext
Nomad Server benötigen zuverlässigen Storage für State Management.

### Entscheidung
Premium SSD (P10: 128 GB) für Nomad Server OS und Data Disks.

### Begründung
- **IOPS**: 500 IOPS, ausreichend für Raft Consensus
- **Latency**: Niedrige Latenz kritisch für Consensus
- **Reliability**: 99.9% SLA
- **Cost/Performance**: Gutes Verhältnis für Production

### Alternativen
- **Standard SSD**: Zu niedrige Performance für Server
- **Ultra SSD**: Overkill für typische Nomad Workloads
- **Standard HDD**: Ungeeignet für transaktionale Workloads

---

## ADR-011: Azure Bastion für Secure Access

### Status
Accepted

### Kontext
Admins benötigen SSH-Zugriff auf private VMs.

### Entscheidung
Azure Bastion Service für Remote Access.

### Begründung
- **Security**: Kein public SSH Port exposure
- **Managed**: Keine Jump Box Wartung
- **Compliance**: Audit Logging integriert
- **SSL/TLS**: Verschlüsselter Browser-basierter Zugriff

### Alternativen
- **Jump Box**: Zusätzliche VM-Wartung erforderlich
- **VPN Gateway**: Komplexer, höhere Kosten
- **Public IP auf VMs**: Sicherheitsrisiko

---

## ADR-012: Log Analytics für Centralized Logging

### Status
Accepted

### Kontext
Logs von allen Komponenten müssen zentral gesammelt und analysiert werden.

### Entscheidung
Azure Log Analytics Workspace als zentrale Logging-Plattform.

### Begründung
- **Native Integration**: Alle Azure-Services unterstützt
- **KQL Queries**: Mächtige Query Language
- **Alerting**: Integrierte Alert-Regeln
- **Retention**: Flexible Aufbewahrungsrichtlinien
- **Cost Effective**: Pay-per-GB Model

### Zusätzlich (Optional)
- **ELK Stack**: Für erweiterte Log-Analyse
- **Prometheus/Grafana**: Für Metriken und Dashboards

---

## Offene Entscheidungen

### OAD-001: Multi-Region Setup
**Status**: To Be Decided

**Überlegungen**:
- Kostet ~2x die Infrastruktur
- Erfordert Federation oder WAN Joining
- Nur bei hohen Verfügbarkeitsanforderungen notwendig

### OAD-002: HashiCorp Vault Integration
**Status**: To Be Decided

**Überlegungen**:
- Zusätzliche Komplexität
- Erweiterte Secrets Features
- Dynamic Secrets für Datenbanken
- Könnte in Phase 2 hinzugefügt werden

### OAD-003: GPU-enabled Client Nodes
**Status**: To Be Decided

**Überlegungen**:
- Abhängig von Workload-Anforderungen
- Signifikant höhere Kosten
- Nur wenn ML/AI Workloads geplant sind
