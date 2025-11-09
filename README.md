# Nomad Cluster in Azure

Dieses Projekt implementiert einen hochverfügbaren HashiCorp Nomad Cluster in Azure mittels Terraform und Ansible. Der Cluster wird über GitHub Actions automatisiert bereitgestellt und kann für die Orchestrierung verschiedener Workloads verwendet werden.

## Projektstruktur

```
nomad-cluster/
├── Taskfile.yml                # Hauptaufgabendatei für das Projekt
├── .github/                   # GitHub Actions Workflows
│   └── workflows/            
│       ├── provision-cluster.yml # Workflow für Cluster-Bereitstellung
│       └── deploy-app.yml       # Workflow für App-Deployment
├── terraform/                 # Terraform IaC für Azure
│   ├── main.tf               # Hauptkonfiguration
│   ├── variables.tf           # Variablendefinitionen
│   ├── outputs.tf             # Output-Definitionen
│   └── terraform.tfvars.example # Beispiel-Variablenwerte
├── ansible/                   # Ansible Konfiguration
│   ├── playbooks/             # Ansible Playbooks
│   └── templates/             # Konfigurationsvorlagen
├── jobs/                      # Nomad Job-Definitionen
│   └── example.nomad          # Beispiel-Job
└── docs/                      # Dokumentation
    ├── architecture.md         # Vollständige Architektur
    ├── architecture-simple.md  # Vereinfachte Architektur
    ├── decisions.md            # Architektur-Entscheidungen
    ├── quick-start.md          # Schnellstart-Anleitung
    └── security-notes.md       # Sicherheitshinweise
```

## Über Nomad

[HashiCorp Nomad](https://www.nomadproject.io/) ist ein flexibler Workload-Orchestrator, der die Bereitstellung und Verwaltung von Containern und nicht-containerisierten Anwendungen vereinfacht. Nomad ist:

- **Einfach**: Leicht zu bedienen und zu betreiben, mit einer einzigen Binärdatei für Client und Server
- **Flexibel**: Unterstützt verschiedene Workload-Typen (Docker, VMs, ausführbare Dateien)
- **Skalierbar**: Kann von einem einzelnen Entwicklungscluster bis zu Produktionsumgebungen mit tausenden Knoten skalieren
- **Hochverfügbar**: Bietet Fehlertoleranz und automatische Wiederherstellung

## Funktionen dieses Projekts

- **Hochverfügbarer Nomad Cluster**: 3-Server-Setup für Consensus und Ausfallsicherheit
- **Auto-Scaling**: Automatische Skalierung der Client-Nodes basierend auf Auslastung
- **Infrastructure as Code**: Vollständig automatisierte Bereitstellung mit Terraform
- **Configuration Management**: Automatisierte Konfiguration mit Ansible
- **CI/CD-Integration**: GitHub Actions Workflows für Infrastruktur und Anwendungen
- **Zentrales Logging**: Log Analytics Workspace für Monitoring und Fehlersuche
- **Secrets Management**: Azure Key Vault für sichere Speicherung von Secrets

## Voraussetzungen

- **Azure Subscription** mit Owner/Contributor-Rechten
- **GitHub Repository** mit Actions aktiviert
- **Service Principal** für Azure-Zugriff
- **SSH Key Pair** für VM-Zugriff

## Erste Schritte

### 1. Repository klonen

```bash
git clone https://github.com/yourusername/nomad-cluster.git
cd nomad-cluster
```

### 2. GitHub Actions Secrets einrichten

Richten Sie folgende Secrets in Ihrem GitHub Repository ein:

- `AZURE_CREDENTIALS`: JSON-Credentials des Service Principals
- `TF_STATE_RG`: Name der Resource Group für Terraform State
- `TF_STATE_SA`: Name des Storage Accounts für Terraform State
- `SSH_PRIVATE_KEY`: Privater SSH-Schlüssel für VM-Zugriff
- `SSH_PUBLIC_KEY`: Öffentlicher SSH-Schlüssel für VM-Zugriff

### 3. Terraform State Storage vorbereiten

```bash
az group create --name nomad-tfstate-rg --location westeurope
az storage account create --name nomadtfstate$RANDOM --resource-group nomad-tfstate-rg --sku Standard_LRS
az storage container create --name tfstate --account-name <storage-account-name>
```

### 4. Terraform Variablen anpassen

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Bearbeiten Sie terraform.tfvars mit Ihren Werten
```

### 5. Cluster bereitstellen

Starten Sie den GitHub Actions Workflow "Provision Nomad Cluster" manuell oder durch Push auf den main-Branch.

## Nomad-Jobs verwalten

### Job-Deployment über GitHub Actions

Um die Beispielanwendung im Nomad-Cluster zu deployen:

1. Navigieren Sie zu Ihrem GitHub Repository
2. Wählen Sie den "Actions"-Tab
3. Starten Sie den Workflow "Deploy Application to Nomad"
4. Wählen Sie den Job-Pfad (z.B. `jobs/example.nomad`)

Alternativ wird der Workflow auch automatisch ausgelöst, wenn Änderungen an Dateien im `jobs/`-Verzeichnis gepusht werden.

### Job-Status überprüfen

Um den Status des Nomad-Clusters und der laufenden Jobs zu überprüfen:

```bash
# Exportieren Sie die Nomad-Server-IP aus der Terraform-Ausgabe oder GitHub Actions
export NOMAD_ADDR=http://<server-ip>:4646

# Cluster-Status anzeigen
nomad server members
nomad node status

# Job-Status anzeigen
nomad job status example
```

Alternativ können Sie auch die Nomad Web-UI unter `http://<server-ip>:4646/ui` besuchen.

### Job-Logs anzeigen

Um die Logs eines laufenden Jobs anzuzeigen:

```bash
nomad alloc logs <alloc-id>
```

Die Allokations-ID können Sie mit `nomad job status example` ermitteln.

## Nomad Job-Konfiguration

Die Beispiel-Job-Konfiguration in `jobs/example.nomad` demonstriert wichtige Nomad-Konzepte:

- **Job-Typen**: Konfiguration als Service-Job für langlebige Dienste
- **Netzwerk**: Port-Mapping und Service-Discovery
- **Ressourcen**: Zuweisung von CPU und Speicher
- **Docker-Integration**: Verwendung des Docker-Treibers
- **Templates**: Dynamische Konfiguration mit Consul-Template
- **Health Checks**: Zustandsprüfung für Services

## Erweiterte Nomad-Konzepte

### Umgebungsvariablen und Interpolation

Nomad bietet leistungsstarke Möglichkeiten zur Konfiguration von Umgebungsvariablen:

```hcl
env {
  # Statische Werte
  APP_ENV = "nomad"

  # Node-Attribute verwenden
  HOSTNAME = "${attr.unique.hostname}"
  NODE_IP = "${attr.unique.network.ip-address}"

  # Nomad-Metadaten verwenden
  NOMAD_ALLOC_ID = "${NOMAD_ALLOC_ID}"
}
```

### Nomad-Variablen

Variablen ermöglichen dynamische Konfigurationen:

```hcl
variable "IMAGE_VERSION" {
  type = string
  default = "local"
}

# Verwendung
config {
  image = "app:${var.IMAGE_VERSION}"
}
```

### Service-Discovery

Nomad bietet integrierte Service-Discovery:

```hcl
service {
  name = "web-service"
  port = "http"
  provider = "nomad"
}
```

## Terraform-Befehle

Wenn Sie Terraform lokal ausführen möchten:

```bash
# Terraform initialisieren
cd terraform
terraform init \
  -backend-config="resource_group_name=nomad-tfstate-rg" \
  -backend-config="storage_account_name=<storage-account-name>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=nomad-cluster.tfstate"

# Terraform Plan erstellen
terraform plan -out=tfplan

# Terraform Apply ausführen
terraform apply tfplan

# Terraform Destroy ausführen
terraform destroy
```

## Nomad-Befehle

Nützliche Nomad-Befehle für die Verwaltung des Clusters:

```bash
# Job-Status anzeigen
nomad job status

# Job stoppen
nomad job stop example

# Job-Definition validieren
nomad job validate jobs/example.nomad

# Job-Plan anzeigen (Dry-Run)
nomad job plan jobs/example.nomad

# Allokationen für einen Job anzeigen
nomad job allocs example

# Nomad-Knoten auflisten
nomad node status

# Nomad-Server-Status prüfen
nomad server members

# Consul-Status prüfen
consul members
```

## Dokumentation

Dieses Projekt enthält umfangreiche Dokumentation im `docs/`-Verzeichnis:

- **architecture.md**: Vollständige Produktions-Architektur mit allen Features
- **architecture-simple.md**: Vereinfachte Architektur für schnelles Deployment
- **decisions.md**: Architektur-Entscheidungen und Begründungen
- **quick-start.md**: Detaillierte Schritt-für-Schritt Anleitung
- **security-notes.md**: Sicherheitshinweise und Best Practices

Für weitere Informationen zu Nomad, Terraform und Ansible, besuchen Sie die offiziellen Dokumentationen:

- [HashiCorp Nomad](https://www.nomadproject.io/docs)
- [HashiCorp Terraform](https://www.terraform.io/docs)
- [Ansible](https://docs.ansible.com/)
- [Azure](https://learn.microsoft.com/de-de/azure/)
