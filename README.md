# Nomad Cluster Beispielprojekt

Dieses Projekt demonstriert die Einrichtung und Verwendung eines HashiCorp Nomad Clusters für die Orchestrierung von Workloads. Als Beispielanwendung dient eine einfache Python-Web-App, die Informationen über ihre Laufzeitumgebung anzeigt.

## Projektstruktur

```
nomad-cluster/
├── Taskfile.yml          # Hauptaufgabendatei für das Projekt
├── ops/                  # Operations-Dateien
│   └── nomad/            # Nomad-Jobdefinitionen
│       └── web.nomad.hcl # Nomad-Job für die Web-App
└── src/                  # Quellcode der Web-Anwendung
    ├── app.py            # Flask-Anwendung
    ├── Dockerfile        # Docker-Build-Definition
    ├── requirements.txt  # Python-Abhängigkeiten
    ├── Taskfile.yml      # Aufgabendatei für die Anwendung
    └── templates/        # HTML-Templates
        └── index.html    # Hauptseite der Anwendung
```

## Über Nomad

[HashiCorp Nomad](https://www.nomadproject.io/) ist ein flexibler Workload-Orchestrator, der die Bereitstellung und Verwaltung von Containern und nicht-containerisierten Anwendungen vereinfacht. Nomad ist:

- **Einfach**: Leicht zu bedienen und zu betreiben, mit einer einzigen Binärdatei für Client und Server
- **Flexibel**: Unterstützt verschiedene Workload-Typen (Docker, VMs, ausführbare Dateien)
- **Skalierbar**: Kann von einem einzelnen Entwicklungscluster bis zu Produktionsumgebungen mit tausenden Knoten skalieren
- **Hochverfügbar**: Bietet Fehlertoleranz und automatische Wiederherstellung

## Funktionen dieses Projekts

- **Nomad Dev-Cluster**: Einfache Einrichtung eines lokalen Entwicklungsclusters
- **Nomad Job-Definitionen**: HCL-Konfiguration für die Bereitstellung von Workloads
- **Docker-Integration**: Beispiel für die Verwendung des Docker-Treibers in Nomad
- **Umgebungsvariablen**: Demonstration der Konfiguration von Umgebungsvariablen in Nomad-Jobs
- **Versionierung**: Beispiel für die Verwendung von Variablen in Nomad-Jobs für dynamische Image-Tags

## Voraussetzungen

- [Task](https://taskfile.dev/) - Task-Runner für Projektaufgaben
- [Docker](https://www.docker.com/) - Für Container-Builds und lokale Ausführung
- [Nomad](https://www.nomadproject.io/) - Für Cluster-Orchestrierung
- [Python 3.6+](https://www.python.org/) - Für lokale Entwicklung

## Erste Schritte mit Nomad

### 1. Nomad CLI installieren

Zunächst muss die Nomad CLI installiert werden:

```bash
task install-nomad-cli
```

Dies installiert die Nomad-Binärdatei über Homebrew. Alternativ können Sie Nomad auch direkt von der [offiziellen Website](https://www.nomadproject.io/downloads) herunterladen.

### 2. Nomad-Cluster starten

Dieses Projekt verwendet einen Nomad-Entwicklungscluster für einfaches lokales Testen. Der Entwicklungsmodus ist ideal für das Kennenlernen von Nomad und zum Testen von Konfigurationen.

```bash
task start-dev-cluster
```

Der Entwicklungsserver startet mit:
- Einem einzelnen Knoten, der sowohl als Server als auch als Client fungiert
- Einer lokalen Adresse (http://localhost:4646) für die Web-UI und API
- In-Memory-Speicherung (keine Persistenz zwischen Neustarts)

Nach dem Start können Sie die Nomad-UI unter http://localhost:4646 aufrufen.

## Nomad-Jobs verwalten

### Job-Deployment

Um die Beispielanwendung im Nomad-Cluster zu deployen:

```bash
task deploy-web
```

Dieser Befehl:

1. Erstellt ein Docker-Image mit einem Zeitstempel-Tag für einfache Versionierung
2. Stellt den Job im Nomad-Cluster bereit, wobei die Image-Version als Variable übergeben wird

### Job-Status überprüfen

Um den Status des Nomad-Clusters und der laufenden Jobs zu überprüfen:

```bash
task status
nomad job status server-info-web
```

### Job-Logs anzeigen

Um die Logs eines laufenden Jobs anzuzeigen:

```bash
nomad alloc logs <alloc-id>
```

Die Allokations-ID können Sie mit `nomad job status server-info-web` ermitteln.

## Nomad Job-Konfiguration

Die Job-Konfiguration in `ops/nomad/web.nomad.hcl` demonstriert wichtige Nomad-Konzepte:

- **Variablen**: Verwendung von Variablen für dynamische Konfiguration
- **Job-Typen**: Konfiguration als Service-Job für langlebige Dienste
- **Netzwerk**: Port-Mapping und Service-Discovery
- **Ressourcen**: Zuweisung von CPU und Speicher
- **Umgebungsvariablen**: Konfiguration der Laufzeitumgebung
- **Docker-Integration**: Verwendung des Docker-Treibers

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

## Weitere Nomad-Befehle

```bash
# Job-Status anzeigen
nomad job status

# Job stoppen
nomad job stop server-info-web

# Job-Definition validieren
nomad job validate ops/nomad/web.nomad.hcl

# Job-Plan anzeigen (Dry-Run)
nomad job plan ops/nomad/web.nomad.hcl

# Allokationen für einen Job anzeigen
nomad job allocs server-info-web

# Nomad-Knoten auflisten
nomad node status
```

## Verfügbare Tasks

Dieses Projekt verwendet Taskfile für die Automatisierung. Alle verfügbaren Aufgaben anzeigen:

```bash
task
```
