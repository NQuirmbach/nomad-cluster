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
    public_ip_address_id          = azurerm_public_ip.nomad_server[count.index].id
  }
}

# Nomad Server Public IPs
resource "azurerm_public_ip" "nomad_server" {
  count               = var.server_count
  name                = "${var.prefix}-server-ip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags                = var.tags
}

# NSG Association für Server NICs
resource "azurerm_network_interface_security_group_association" "nomad_server" {
  count                     = var.server_count
  network_interface_id      = azurerm_network_interface.nomad_server[count.index].id
  network_security_group_id = var.server_nsg_id
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
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.subnet_id
      public_ip_address {
        name              = "client-public-ip"
        public_ip_prefix_id = azurerm_public_ip_prefix.client.id
      }
    }

    network_security_group_id = var.client_nsg_id
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# Public IP Prefix für Client VMSS
resource "azurerm_public_ip_prefix" "client" {
  name                = "${var.prefix}-client-ip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = 28
  tags                = var.tags
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
  count                = var.server_count
  name                 = "VMInsights"
  virtual_machine_id   = azurerm_linux_virtual_machine.nomad_server[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}
