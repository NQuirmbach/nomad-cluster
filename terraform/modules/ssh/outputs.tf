output "public_key" {
  description = "Der generierte öffentliche SSH-Schlüssel"
  value       = tls_private_key.ssh.public_key_openssh
}

output "private_key" {
  description = "Der generierte private SSH-Schlüssel"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_private_key_secret_name" {
  description = "Name des Key Vault Secrets für den privaten SSH-Schlüssel"
  value       = azurerm_key_vault_secret.ssh_private_key.name
}

output "ssh_public_key_secret_name" {
  description = "Name des Key Vault Secrets für den öffentlichen SSH-Schlüssel"
  value       = azurerm_key_vault_secret.ssh_public_key.name
}
