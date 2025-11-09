variable "prefix" {
  description = "Prefix für alle Ressourcen"
  type        = string
}

variable "location" {
  description = "Azure Region für alle Ressourcen"
  type        = string
}

variable "resource_group_name" {
  description = "Name der Resource Group"
  type        = string
}

variable "tags" {
  description = "Tags für alle Ressourcen"
  type        = map(string)
}

variable "allowed_ssh_ips" {
  description = "Liste der erlaubten IPs für SSH-Zugriff"
  type        = list(string)
}
