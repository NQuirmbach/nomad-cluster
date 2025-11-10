job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
      port "admin" {
        static = 8081
      }
    }

    service {
      name = "traefik"
      port = "http"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.10"
        ports = ["http", "admin"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.web]
    address = ":8080"
  [entryPoints.traefik]
    address = ":8081"

[api]
  dashboard = true
  insecure = true

[providers]
  [providers.nomad]
    endpoint = "http://{{ env "attr.unique.network.ip-address" }}:4646"
    stale = false
    exposedByDefault = false
    defaultRule = "Host(`{{ .Name }}.service.consul`)"
    
  [providers.file]
    filename = "/local/dynamic_conf.toml"

# Enable access logs
[accessLog]

# Enable Traefik log
[log]
  level = "INFO"
EOF

        destination = "local/traefik.toml"
      }

      template {
        data = <<EOF
[http.routers]
  [http.routers.server-info]
    rule = "PathPrefix(`/server-info`)"
    service = "server-info-svc"
    middlewares = ["server-info-stripprefix"]

[http.middlewares]
  [http.middlewares.server-info-stripprefix.stripPrefix]
    prefixes = ["/server-info"]
EOF

        destination = "local/dynamic_conf.toml"
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
