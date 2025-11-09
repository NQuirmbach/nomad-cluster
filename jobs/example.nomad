job "example" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 3

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name = "webapp"
      port = "http"
      
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.webapp.rule=Host(`webapp.example.com`)"
      ]
      
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
        
        volumes = [
          "local/default.conf:/etc/nginx/conf.d/default.conf",
          "local/index.html:/usr/share/nginx/html/index.html"
        ]
      }

      template {
        data = <<EOF
server {
    listen 80;
    server_name webapp.example.com;
    
    location / {
        root   /usr/share/nginx/html;
        index  index.html;
    }
}
EOF
        destination = "local/default.conf"
      }

      template {
        data = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Nomad Demo App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 30px;
            background-color: #f0f2f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0078d7;
        }
        .info {
            background-color: #e6f7ff;
            border-left: 4px solid #1890ff;
            padding: 15px;
            margin: 20px 0;
        }
        .server-info {
            font-family: monospace;
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Nomad Demo Application</h1>
        <p>This is a simple web application deployed with Nomad.</p>
        
        <div class="info">
            <h3>Container Information</h3>
            <div class="server-info">
                <p><strong>Hostname:</strong> {{ env "HOSTNAME" }}</p>
                <p><strong>Nomad Allocation ID:</strong> {{ env "NOMAD_ALLOC_ID" }}</p>
                <p><strong>Nomad Task:</strong> {{ env "NOMAD_TASK_NAME" }}</p>
                <p><strong>Datacenter:</strong> {{ env "NOMAD_DC" }}</p>
            </div>
        </div>
    </div>
</body>
</html>
EOF
        destination = "local/index.html"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
