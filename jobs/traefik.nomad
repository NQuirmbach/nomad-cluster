job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 9080
      }
      port "admin" {
        static = 9081
      }
      # Zusätzliche Ports für interne Kommunikation
      port "ping" {
        static = 9082
      }
    }

    service {
      name = "traefik"
      port = "http"
      tags = ["traefik.enable=true"]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Service für das Traefik Dashboard
    service {
      name = "traefik-dashboard"
      port = "admin"
      tags = ["traefik.enable=true"]

      check {
        name     = "dashboard-alive"
        type     = "tcp"
        port     = "admin"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.10"
        ports = ["http", "admin", "ping"]

        # Direkte Konfiguration über Kommandozeilenargumente statt Konfigurationsdateien
        args = [
          "--entrypoints.web.address=:9080",
          "--entrypoints.dashboard.address=:9081",
          "--entrypoints.ping.address=:9082",
          "--ping.entrypoint=ping",
          "--api.dashboard=true",
          "--api.insecure=true",
          "--providers.file.filename=/local/dynamic_conf.toml",
          "--providers.file.watch=true",
          "--log.level=DEBUG"
        ]
      }

      # Kein leeres Template mehr notwendig

      # Zusätzliche Konfiguration für Traefik (Middlewares und Services)
      template {
        data = <<EOF
# Dynamische Konfiguration für Traefik

# Definiere den Server-Info Service
[http.services]
  [http.services.server-info-svc]
    [http.services.server-info-svc.loadBalancer]
      [[http.services.server-info-svc.loadBalancer.servers]]
        url = "http://127.0.0.1:8080"

# Middleware zum Entfernen des Pfad-Präfixes
[http.middlewares]
  [http.middlewares.strip-server-info.stripPrefix]
    prefixes = ["/server-info"]

# Router für die Server-Info App
[http.routers]
  [http.routers.server-info]
    rule = "PathPrefix(`/server-info`)"
    service = "server-info-svc"
    entryPoints = ["web"]
    middlewares = ["strip-server-info"]
    
  # Catch-All Router für die Startseite
  [http.routers.catchall]
    rule = "PathPrefix(`/`)"
    service = "server-info-svc"
    entryPoints = ["web"]
    priority = 1  # Niedrige Priorität, damit spezifischere Routen Vorrang haben
EOF

        destination = "local/dynamic_conf.toml"
      }

      env {
        # Debug-Modus aktivieren
        TRAEFIK_LOG_LEVEL = "DEBUG"
      }

      resources {
        cpu    = 300
        memory = 256
      }
    }
  }
}
