# SSH-Schlüssel generieren
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Schlüssel in Key Vault speichern
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "${var.prefix}-ssh-private-key"
  value        = tls_private_key.ssh.private_key_pem
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "${var.prefix}-ssh-public-key"
  value        = tls_private_key.ssh.public_key_openssh
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  tags         = var.tags
}

# Optional: Speichern der Schlüssel als lokale Dateien für einfachen Zugriff
resource "local_file" "private_key" {
  count    = var.save_local_keys ? 1 : 0
  content  = tls_private_key.ssh.private_key_pem
  filename = "${path.root}/ssh_keys/${var.prefix}_id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  count    = var.save_local_keys ? 1 : 0
  content  = tls_private_key.ssh.public_key_openssh
  filename = "${path.root}/ssh_keys/${var.prefix}_id_rsa.pub"
  file_permission = "0644"
}
