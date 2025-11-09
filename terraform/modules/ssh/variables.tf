variable "prefix" {
  description = "Prefix für alle Ressourcen"
  type        = string
}

variable "key_vault_id" {
  description = "ID des Key Vaults, in dem die SSH-Schlüssel gespeichert werden sollen"
  type        = string
}

variable "tags" {
  description = "Tags für alle Ressourcen"
  type        = map(string)
}

variable "save_local_keys" {
  description = "Ob die SSH-Schlüssel lokal gespeichert werden sollen"
  type        = bool
  default     = false
}
