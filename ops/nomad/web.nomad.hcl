variable "IMAGE_VERSION" {
  type = string
  default = "local"
  description = "The version tag for the Docker image"
}

job "server-info-web" {
  type = "service"

  ui {
    description = "Server Info Web"
  }

  group "server-info" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name     = "server-info-svc"
      port     = "http"
      provider = "nomad"
    }

    task "server-info-task" {
      driver = "docker"

      resources {
        cpu = 512
        memory = 256
      }

      env {
        # Static environment variables
        APP_ENV = "nomad"
        HOSTNAME = "${attr.unique.hostname}"
        NODE_IP = "${attr.unique.network.ip-address}"
        
        # You can also reference Nomad variables
        NOMAD_ALLOC_ID = "${NOMAD_ALLOC_ID}"
        NOMAD_JOB_NAME = "${NOMAD_JOB_NAME}"
        NOMAD_TASK_NAME = "${NOMAD_TASK_NAME}"
      }
      
      config {
        image = "server-info-app:${var.IMAGE_VERSION}"
        ports = ["http"]
      }
    }
  }
}
