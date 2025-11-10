output "vnet_id" {
  description = "ID des Virtual Networks"
  value       = azurerm_virtual_network.nomad.id
}

output "vnet_name" {
  description = "Name des Virtual Networks"
  value       = azurerm_virtual_network.nomad.name
}

output "cluster_subnet_id" {
  description = "ID des Cluster Subnets"
  value       = azurerm_subnet.cluster.id
}

output "server_nsg_id" {
  description = "ID der Server Network Security Group"
  value       = azurerm_network_security_group.nomad_server.id
}

output "client_nsg_id" {
  description = "ID der Client Network Security Group"
  value       = azurerm_network_security_group.nomad_client.id
}

output "bastion_subnet_id" {
  description = "ID des Azure Bastion Subnets"
  value       = azurerm_subnet.bastion.id
}

output "azure_bastion_host_id" {
  description = "ID des Azure Bastion Hosts"
  value       = azurerm_bastion_host.nomad.id
}

output "azure_bastion_public_ip" {
  description = "Public IP des Azure Bastion Services"
  value       = azurerm_public_ip.bastion.ip_address
}
