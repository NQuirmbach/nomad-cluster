# Security-Dokumentation für Nomad Cluster in Azure

Diese Dokumentation beschreibt die empfohlenen Security Best Practices für die Implementierung und den Betrieb eines Nomad Clusters in Azure sowie aktuell nicht implementierte Sicherheitsmaßnahmen.

## Aktuell nicht implementierte Sicherheitsmaßnahmen

1. **TLS Encryption**
   - Nomad und Consul kommunizieren unverschlüsselt
   - Sollte für Production aktiviert werden

2. **ACL System**
   - Keine Zugriffskontrollen für Nomad/Consul
   - Jeder mit Zugriff hat volle Admin-Rechte

3. **Private Networking**
   - Server/Clients haben öffentliche IPs
   - Sollte auf private IPs mit Bastion/VPN umgestellt werden

4. **Secrets Management**
   - Key Vault wird nur für Infrastructure-Secrets genutzt
   - Application Secrets sollten über Vault/Key Vault injiziert werden

5. **Network Security**
   - NSGs erlauben direkten Zugriff auf Management-Ports
   - Sollte auf Least-Privilege umgestellt werden

## Authentifizierung und Autorisierung

### Azure Authentifizierung

#### Federated Identity für CI/CD

- **Empfehlung**: Verwende Federated Identity (OpenID Connect) für GitHub Actions anstelle von Service Principal Secrets
- **Vorteile**: Keine langlebigen Credentials, automatische Token-Rotation, granulare Berechtigungen
- **Implementierung**: Siehe [GitHub und Azure Setup](./github-azure-setup.md)

#### Managed Identities für VMs

- **Empfehlung**: Verwende System-Assigned Managed Identities für alle VMs und VMSS
- **Vorteile**: Keine Credentials in der Konfiguration, automatische Rotation, vereinfachtes Management
- **Implementierung**: Bereits in der Terraform-Konfiguration aktiviert

### Nomad Authentifizierung

- **Empfehlung**: Aktiviere ACL-System in Nomad und verwende JWT-Authentifizierung
- **Vorteile**: Granulare Zugriffskontrolle, Integration mit Azure AD möglich
- **Implementierung**: Ergänze die Nomad-Konfiguration um ACL-Einstellungen

```hcl
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
```

### Consul Authentifizierung

- **Empfehlung**: Aktiviere ACL-System in Consul und verwende JWT-Authentifizierung
- **Vorteile**: Granulare Zugriffskontrolle, Integration mit Azure AD möglich
- **Implementierung**: Ergänze die Consul-Konfiguration um ACL-Einstellungen

```hcl
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
```

## Netzwerksicherheit

### Azure Network Security Groups

- **Empfehlung**: Beschränke den Zugriff auf Management-Ports (SSH, Nomad UI, Consul UI)
- **Vorteile**: Reduziertes Angriffsrisiko durch Einschränkung der Zugriffsquellen
- **Implementierung**: Bereits in der Terraform-Konfiguration implementiert

### Private Networks

- **Empfehlung**: Verwende private Subnets für Nomad Server und Clients
- **Vorteile**: Isolation von Workloads, kein direkter Internet-Zugriff
- **Implementierung**: Ergänze die Terraform-Konfiguration um private Subnets und Azure Bastion
- **Empfohlene Komponenten**:
  - Azure Private Link für Key Vault
  - Private Endpoints für Storage
  - Azure Bastion für SSH-Zugriff

### TLS Verschlüsselung

- **Empfehlung**: Aktiviere TLS für alle Nomad und Consul Kommunikation
- **Vorteile**: Verschlüsselte Kommunikation, Schutz vor Man-in-the-Middle-Angriffen
- **Implementierung**: Ergänze die Nomad- und Consul-Konfiguration um TLS-Einstellungen

```hcl
# Nomad TLS-Konfiguration
tls {
  http = true
  rpc  = true
  verify_server_hostname = true
  ca_file   = "/etc/nomad.d/tls/ca.crt"
  cert_file = "/etc/nomad.d/tls/server.crt"
  key_file  = "/etc/nomad.d/tls/server.key"
}
```

## Secrets Management

### Azure Key Vault

- **Empfehlung**: Speichere alle Secrets in Azure Key Vault
- **Vorteile**: Zentrale Verwaltung, Zugriffskontrolle, Audit-Logs
- **Implementierung**: Bereits in der Terraform-Konfiguration implementiert

### Nomad Vault Integration

- **Empfehlung**: Integriere HashiCorp Vault für dynamische Secrets
- **Vorteile**: Dynamische Credentials, automatische Rotation, feingranulare Zugriffskontrolle
- **Implementierung**: Ergänze die Nomad-Konfiguration um Vault-Integration

```hcl
vault {
  enabled = true
  address = "https://vault.service.consul:8200"
  token   = "VAULT_TOKEN"
  create_from_role = "nomad-cluster"
}
```

## Monitoring und Logging

### Azure Log Analytics

- **Empfehlung**: Zentralisiere Logs in Azure Log Analytics
- **Vorteile**: Zentrale Analyse, Alerting, langfristige Speicherung
- **Implementierung**: Bereits in der Terraform-Konfiguration implementiert

### Azure Monitor

- **Empfehlung**: Aktiviere Azure Monitor für alle Ressourcen
- **Vorteile**: Performance-Überwachung, Anomalie-Erkennung, Auto-Scaling
- **Implementierung**: Bereits in der Terraform-Konfiguration implementiert

## Container-Sicherheit

### Image Scanning

- **Empfehlung**: Aktiviere automatisches Image Scanning in Azure Container Registry
- **Vorteile**: Erkennung von Schwachstellen, Compliance-Prüfung
- **Implementierung**: Ergänze die ACR-Konfiguration um Security Center Integration

### Container Isolation

- **Empfehlung**: Verwende Nomad's Isolation-Features für Container
- **Vorteile**: Reduziertes Risiko bei kompromittierten Containern
- **Implementierung**: Konfiguriere Nomad mit entsprechenden Sicherheitseinstellungen

```hcl
plugin "docker" {
  config {
    allow_privileged = false
    volumes {
      enabled = true
    }
    extra_labels = ["security"]
  }
}
```

## Compliance Checkliste

- [ ] TLS für alle Kommunikation
- [ ] ACL System aktiviert
- [ ] Private Networking
- [ ] Secrets Rotation
- [ ] Audit Logging
- [ ] OS Hardening
- [ ] Container Security Scanning

## Implementierungsplan

Für eine sichere Produktionsumgebung sollten die folgenden Maßnahmen schrittweise implementiert werden:

1. **Basis-Infrastruktur**: Verwende die bestehende Terraform-Konfiguration mit Managed Identities und NSGs
2. **TLS-Verschlüsselung**: Implementiere TLS für Nomad und Consul
3. **ACL-System**: Aktiviere und konfiguriere ACLs in Nomad und Consul
4. **Secrets Management**: Integriere Vault für dynamische Secrets
5. **Monitoring**: Erweitere das Monitoring um sicherheitsrelevante Metriken
6. **Container-Sicherheit**: Implementiere Image Scanning und Container-Isolation

## Weitere Ressourcen

- [Nomad Security Documentation](https://www.nomadproject.io/docs/security)
- [Consul Security Documentation](https://www.consul.io/docs/security)
- [Azure Security Best Practices](https://learn.microsoft.com/de-de/azure/security/fundamentals/best-practices-and-patterns)
- [Container Security Best Practices](https://learn.microsoft.com/de-de/azure/container-registry/container-registry-best-practices)
