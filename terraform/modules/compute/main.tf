# Nomad Server VMs
resource "azurerm_linux_virtual_machine" "nomad_server" {
  count                 = var.server_count
  name                  = "${var.prefix}-server-${count.index + 1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nomad_server[count.index].id]
  size                  = var.server_vm_size
  admin_username        = "azureuser"
  tags                  = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# Nomad Server NICs
resource "azurerm_network_interface" "nomad_server" {
  count               = var.server_count
  name                = "${var.prefix}-server-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Load Balancer Public IP
resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-lb-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Load Balancer
resource "azurerm_lb" "nomad" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "nomad_servers" {
  name            = "${var.prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.nomad.id
}

# Health Probe für Nomad API
resource "azurerm_lb_probe" "nomad_api" {
  name            = "nomad-api-probe"
  loadbalancer_id = azurerm_lb.nomad.id
  protocol        = "Http"
  port            = 4646
  request_path    = "/v1/status/leader"
}

# Load Balancer Rule für Nomad UI/API
resource "azurerm_lb_rule" "nomad_ui" {
  name                           = "nomad-ui"
  loadbalancer_id                = azurerm_lb.nomad.id
  protocol                       = "Tcp"
  frontend_port                  = 4646
  backend_port                   = 4646
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_servers.id]
  probe_id                       = azurerm_lb_probe.nomad_api.id
}

# Health Probe für Consul
resource "azurerm_lb_probe" "consul" {
  name            = "consul-probe"
  loadbalancer_id = azurerm_lb.nomad.id
  protocol        = "Http"
  port            = 8500
  request_path    = "/v1/status/leader"
}

# Load Balancer Rule für Consul UI
resource "azurerm_lb_rule" "consul_ui" {
  name                           = "consul-ui"
  loadbalancer_id                = azurerm_lb.nomad.id
  protocol                       = "Tcp"
  frontend_port                  = 8500
  backend_port                   = 8500
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_servers.id]
  probe_id                       = azurerm_lb_probe.consul.id
}

# Inbound NAT Rules für SSH (ein Port pro Server)
resource "azurerm_lb_nat_rule" "ssh" {
  count                          = var.server_count
  name                           = "ssh-server-${count.index + 1}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.nomad.id
  protocol                       = "Tcp"
  frontend_port                  = 50001 + count.index
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

# NSG Association für Server NICs
resource "azurerm_network_interface_security_group_association" "nomad_server" {
  count                     = var.server_count
  network_interface_id      = azurerm_network_interface.nomad_server[count.index].id
  network_security_group_id = var.server_nsg_id
}

# Backend Pool Association für Server NICs
resource "azurerm_network_interface_backend_address_pool_association" "nomad_server" {
  count                   = var.server_count
  network_interface_id    = azurerm_network_interface.nomad_server[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nomad_servers.id
}

# NAT Rule Association für SSH
resource "azurerm_network_interface_nat_rule_association" "ssh" {
  count                 = var.server_count
  network_interface_id  = azurerm_network_interface.nomad_server[count.index].id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.ssh[count.index].id
}

# Nomad Client VMSS
resource "azurerm_linux_virtual_machine_scale_set" "nomad_client" {
  name                = "${var.prefix}-client-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.client_vm_size
  instances           = var.client_count
  admin_username      = "azureuser"
  tags                = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }

  network_interface {
    name    = "client-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
    }

    network_security_group_id = var.client_nsg_id
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  # Cloud-Init für Client-Konfiguration
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - unzip
      - wget
      - curl
      - jq
      - apt-transport-https
      - ca-certificates
      - gnupg
      - docker.io

    write_files:
      # Nomad Client Konfiguration
      - path: /etc/nomad.d/client.hcl
        owner: root:root
        permissions: '0644'
        content: |
          data_dir  = "/opt/nomad/data"
          bind_addr = "0.0.0.0"
          
          client {
            enabled = true
            servers = [
              "${azurerm_linux_virtual_machine.nomad_server[0].private_ip_address}:4647",
              "${azurerm_linux_virtual_machine.nomad_server[1].private_ip_address}:4647",
              "${azurerm_linux_virtual_machine.nomad_server[2].private_ip_address}:4647"
            ]
            network_interface = "eth0"
          }
          
          plugin "docker" {
            config {
              allow_privileged = true
              volumes {
                enabled = true
              }
              extra_labels = ["job_name", "job_id", "task_group", "task_name", "namespace", "node_name"]
              
              # ACR-Authentifizierung auf Client-Ebene
              auth {
                # Verwende die ACR-Admin-Credentials
                config = "/etc/docker/config.json"
              }
            }
          }
          
          datacenter = "${var.datacenter}"
          region     = "global"
          
          log_level = "INFO"
          log_file  = "/var/log/nomad.log"
          
          telemetry {
            publish_allocation_metrics = true
            publish_node_metrics = true
            prometheus_metrics = true
          }
        
      # Nomad systemd service
      - path: /etc/systemd/system/nomad-client.service
        content: |
          [Unit]
          Description=Nomad Client
          Documentation=https://nomadproject.io/docs/
          Wants=network-online.target
          After=network-online.target

          [Service]
          User=nomad
          Group=nomad
          ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d
          ExecReload=/bin/kill -HUP $MAINPID
          KillMode=process
          Restart=on-failure
          RestartSec=2
          LimitNOFILE=65536
          LimitNPROC=infinity
          Restart=on-failure
          RestartSec=2
          StartLimitBurst=3
          StartLimitIntervalSec=10
          TasksMax=infinity

          [Install]
          WantedBy=multi-user.target
      
      # Docker config.json template
      - path: /etc/docker/config.json.template
        owner: root:root
        permissions: '0600'
        content: |
          {
            "auths": {
              "${var.acr_login_server}": {
                "auth": "CREDENTIALS_PLACEHOLDER"
              }
            }
          }

    runcmd:
      # Debugging: Markiere den Beginn des Cloud-Init-Scripts
      - echo "===== STARTING NOMAD CLIENT SETUP =====" > /var/log/nomad-setup.log
      - date >> /var/log/nomad-setup.log
      
      # Debugging: Umgebungsvariablen anzeigen
      - echo "Environment variables:" >> /var/log/nomad-setup.log
      - env | sort >> /var/log/nomad-setup.log
      
      # Debugging: Verzeichnisstruktur anzeigen
      - echo "Directory structure:" >> /var/log/nomad-setup.log
      - ls -la / >> /var/log/nomad-setup.log
      - ls -la /etc >> /var/log/nomad-setup.log
      
      # Create directories
      - echo "Creating directories..." | tee -a /var/log/nomad-setup.log
      - mkdir -p /opt/nomad/data /etc/nomad.d /var/log
      - ls -la /opt/nomad /etc/nomad.d >> /var/log/nomad-setup.log
      
      # Download and install Nomad
      - echo "Downloading Nomad ${var.nomad_version}..." | tee -a /var/log/nomad-setup.log
      - wget -q https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip -O /tmp/nomad.zip
      - echo "Download complete, installing..." | tee -a /var/log/nomad-setup.log
      - unzip -o /tmp/nomad.zip -d /usr/local/bin
      - chmod +x /usr/local/bin/nomad
      - rm /tmp/nomad.zip
      - ls -la /usr/local/bin/nomad >> /var/log/nomad-setup.log
      - /usr/local/bin/nomad version >> /var/log/nomad-setup.log 2>&1 || echo "Failed to get Nomad version" >> /var/log/nomad-setup.log
      
      # Create Nomad user
      - echo "Creating nomad user..." | tee -a /var/log/nomad-setup.log
      - useradd --system --home /etc/nomad.d --shell /bin/false nomad || echo "User nomad may already exist" | tee -a /var/log/nomad-setup.log
      - touch /var/log/nomad.log
      - mkdir -p /opt/nomad /etc/nomad.d
      - chown -R nomad:nomad /opt/nomad /etc/nomad.d /var/log/nomad.log || echo "Chown failed, but continuing" | tee -a /var/log/nomad-setup.log
      - ls -la /etc/nomad.d >> /var/log/nomad-setup.log
      - id nomad >> /var/log/nomad-setup.log 2>&1 || echo "Failed to get nomad user info" | tee -a /var/log/nomad-setup.log
      
      # Configure Docker
      - echo "Configuring Docker..." | tee -a /var/log/nomad-setup.log
      - systemctl enable docker
      - systemctl start docker
      - systemctl status docker >> /var/log/nomad-setup.log 2>&1
      - usermod -aG docker azureuser
      - id azureuser >> /var/log/nomad-setup.log
      
      # Setup Docker config.json with ACR credentials
      - echo "Creating Docker config.json with ACR credentials..." | tee -a /var/log/nomad-setup.log
      - mkdir -p /etc/docker
      - mkdir -p /root/.docker
      - mkdir -p /home/azureuser/.docker
      
      # Direkte Erstellung der Docker-Konfigurationsdatei ohne Template
      - echo "Creating Docker config directly..." | tee -a /var/log/nomad-setup.log
      - ENCODED_AUTH=$(echo -n "${var.acr_admin_username}:${var.acr_admin_password}" | base64 -w0)
      - echo "Encoded auth created" | tee -a /var/log/nomad-setup.log
      
      # Erstelle die Konfigurationsdateien an allen relevanten Orten
      - echo '{"auths":{"'${var.acr_login_server}'":{"auth":"'"$ENCODED_AUTH"'"}}}' > /etc/docker/config.json
      - echo '{"auths":{"'${var.acr_login_server}'":{"auth":"'"$ENCODED_AUTH"'"}}}' > /root/.docker/config.json
      - echo '{"auths":{"'${var.acr_login_server}'":{"auth":"'"$ENCODED_AUTH"'"}}}' > /home/azureuser/.docker/config.json
      
      # Setze Berechtigungen
      - chmod 600 /etc/docker/config.json /root/.docker/config.json
      - chown azureuser:azureuser /home/azureuser/.docker/config.json
      - chmod 600 /home/azureuser/.docker/config.json
      
      # Überprüfe die Konfigurationsdateien
      - echo "Docker config files created:" | tee -a /var/log/nomad-setup.log
      - ls -la /etc/docker/config.json >> /var/log/nomad-setup.log
      - ls -la /root/.docker/config.json >> /var/log/nomad-setup.log
      - ls -la /home/azureuser/.docker/config.json >> /var/log/nomad-setup.log
      
      # Neustart des Docker-Dienstes
      - systemctl restart docker
      - echo "Docker restarted" | tee -a /var/log/nomad-setup.log
      
      # Test ACR authentication
      - echo "Testing ACR authentication..." | tee -a /var/log/nomad-setup.log
      - docker info >> /var/log/nomad-setup.log 2>&1
      - docker pull ${var.acr_login_server}/hello-world:latest >> /var/log/nomad-setup.log 2>&1 || echo "Failed to pull test image, but continuing" | tee -a /var/log/nomad-setup.log
      
      # Verify Nomad client configuration
      - echo "Verifying Nomad client configuration..." | tee -a /var/log/nomad-setup.log
      - cat /etc/nomad.d/client.hcl >> /var/log/nomad-setup.log
      - cat /etc/systemd/system/nomad-client.service >> /var/log/nomad-setup.log
      
      # Überprüfe die Nomad-Konfiguration vor dem Start
      - echo "Validating Nomad configuration..." | tee -a /var/log/nomad-setup.log
      - nomad validate /etc/nomad.d/client.hcl >> /var/log/nomad-setup.log 2>&1 || echo "Nomad configuration validation failed, but continuing" | tee -a /var/log/nomad-setup.log
      
      # Stelle sicher, dass die Verzeichnisse die richtigen Berechtigungen haben
      - echo "Setting correct permissions..." | tee -a /var/log/nomad-setup.log
      - mkdir -p /opt/nomad/data /etc/nomad.d
      - chown -R nomad:nomad /opt/nomad /etc/nomad.d /var/log/nomad.log || echo "Chown failed, but continuing" | tee -a /var/log/nomad-setup.log
      - chmod 755 /opt/nomad /etc/nomad.d
      - chmod 644 /etc/nomad.d/client.hcl
      - ls -la /opt/nomad /etc/nomad.d >> /var/log/nomad-setup.log
      
      # Start Nomad client
      - echo "Enabling and starting Nomad client..." | tee -a /var/log/nomad-setup.log
      - systemctl daemon-reload
      - systemctl enable nomad-client
      - systemctl start nomad-client || echo "Failed to start Nomad client service, retrying..." | tee -a /var/log/nomad-setup.log
      
      # Wenn der erste Start fehlschlägt, versuche es erneut
      - sleep 5
      - systemctl status nomad-client >> /var/log/nomad-setup.log 2>&1 || systemctl restart nomad-client
      
      # Check Nomad status
      - echo "Checking Nomad client status..." | tee -a /var/log/nomad-setup.log
      - sleep 10
      - systemctl status nomad-client >> /var/log/nomad-setup.log 2>&1 || echo "Nomad client service status check failed" | tee -a /var/log/nomad-setup.log
      
      # Ausführliche Diagnose
      - echo "Collecting diagnostic information..." | tee -a /var/log/nomad-setup.log
      - ps aux | grep nomad >> /var/log/nomad-setup.log
      - netstat -tulpn | grep nomad >> /var/log/nomad-setup.log
      - journalctl -u nomad-client -n 50 >> /var/log/nomad-setup.log 2>&1
      - ls -la /usr/local/bin/nomad >> /var/log/nomad-setup.log
      - nomad version >> /var/log/nomad-setup.log 2>&1 || echo "Failed to get Nomad version" | tee -a /var/log/nomad-setup.log
      
      # Manueller Start als Fallback
      - echo "Attempting manual start if service failed..." | tee -a /var/log/nomad-setup.log
      - systemctl status nomad-client >> /var/log/nomad-setup.log 2>&1 || nohup /usr/local/bin/nomad agent -config=/etc/nomad.d > /var/log/nomad-manual.log 2>&1 &
      
      - echo "===== NOMAD CLIENT SETUP COMPLETED =====" | tee -a /var/log/nomad-setup.log
      - date >> /var/log/nomad-setup.log
  EOF
  )
}

# RBAC-Rolle für ACR Pull (Managed Identity)
resource "azurerm_role_assignment" "nomad_client_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine_scale_set.nomad_client.identity[0].principal_id
}

# Auto-Scaling für Client VMSS
resource "azurerm_monitor_autoscale_setting" "nomad_client" {
  name                = "${var.prefix}-client-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.nomad_client.id
  tags                = var.tags

  profile {
    name = "DefaultProfile"

    capacity {
      default = var.client_count
      minimum = var.client_min_count
      maximum = var.client_max_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.nomad_client.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.nomad_client.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# VM Insights für Monitoring
resource "azurerm_virtual_machine_scale_set_extension" "client_monitoring" {
  name                         = "VMInsights"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.nomad_client.id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true
}

resource "azurerm_virtual_machine_extension" "server_monitoring" {
  count                      = var.server_count
  name                       = "VMInsights"
  virtual_machine_id         = azurerm_linux_virtual_machine.nomad_server[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

# Bastion Host wurde durch Azure Bastion Service ersetzt
