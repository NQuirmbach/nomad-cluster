# Grundlegende Einstellungen
prefix     = "nmdclstr"
location   = "westeurope"
datacenter = "dc1"

# VM Konfiguration
server_count     = 3
client_count     = 2
client_min_count = 2
client_max_count = 10
server_vm_size   = "Standard_B2s"
client_vm_size   = "Standard_B2ms"

# SSH Zugriff
# SSH-Schlüssel werden automatisch generiert und in Key Vault gespeichert
allowed_ssh_ips = ["123.123.123.123/32"]  # Deine IP-Adresse

# GitHub Actions Integration
enable_github_actions_rbac = true  # Aktiviert RBAC für GitHub Actions Managed Identity

# Software Versionen
nomad_version  = "1.7.5"
consul_version = "1.16.0"

# Tags
tags = {
  Environment = "Dev"
  Project     = "NomadCluster"
  ManagedBy   = "Terraform"
  Owner       = "YourName"
}
