# Random pet for resource group name
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${random_pet.rg_name.id}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Web Tier Subnet
resource "azurerm_subnet" "web" {
  name                 = "web-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_prefix]
}

# Database Tier Subnet
resource "azurerm_subnet" "db" {
  name                 = "db-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_prefix]
}

# Availability Set for Web Tier VMs
resource "azurerm_availability_set" "web_availability_set" {
  name                = "${random_pet.rg_name.id}-web-availability-set"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Web Tier NSG
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-tier-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Database Tier NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-tier-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_SQL_From_Web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.web.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

# Windows VM Configuration for Web Tier
resource "azurerm_windows_virtual_machine" "web_vm" {
  count                         = var.web_vm_count
  name                          = "${random_pet.rg_name.id}-web-${count.index}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  size                          = var.vm_size
  availability_set_id           = azurerm_availability_set.web_availability_set.id
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  network_interface_ids         = [element(azurerm_network_interface.web_nic.*.id, count.index)]
  os_disk {
    caching                     = "ReadWrite"
    storage_account_type        = "Premium_LRS"
    disk_size_gb                = var.os_disk_size_gb
  }
  source_image_reference {
    publisher                   = "MicrosoftWindowsServer"
    offer                       = "WindowsServer"
    sku                         = "2019-Datacenter"
    version                     = "latest"
  }
}

# Network Interface for Web VMs
resource "azurerm_network_interface" "web_nic" {
  count                      = var.web_vm_count
  name                       = "${random_pet.rg_name.id}-web-nic-${count.index}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows VM Configuration for Database Tier
resource "azurerm_windows_virtual_machine" "db_vm" {
  count                         = 1
  name                          = "${random_pet.rg_name.id}-db"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  size                          = "Standard_D4s_v3"
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  network_interface_ids         = [azurerm_network_interface.db_nic.id]
  os_disk {
    caching                     = "ReadWrite"
    storage_account_type        = "Premium_LRS"
    disk_size_gb                = 256
  }
  source_image_reference {
    publisher                   = "MicrosoftWindowsServer"
    offer                       = "WindowsServer"
    sku                         = "2019-Datacenter"
    version                     = "latest"
  }
}

# Network Interface for Database VM
resource "azurerm_network_interface" "db_nic" {
  name                      = "${random_pet.rg_name.id}-db-nic"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP address for Azure Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "${random_pet.rg_name.id}-lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Azure Load Balancer
resource "azurerm_lb" "lb" {
  name                = "${random_pet.rg_name.id}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Backend Address Pool for Azure Load Balancer
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  name                = "${random_pet.rg_name.id}-lb-backend-pool"
  loadbalancer_id     = azurerm_lb.lb.id
}

# HTTP Probe for Azure Load Balancer
resource "azurerm_lb_probe" "lb_http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  request_path        = "/"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule for Azure Load Balancer
resource "azurerm_lb_rule" "lb_http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.lb_http_probe.id
  frontend_port                  = 80
  backend_port                   = 80
  protocol                       = "Tcp"
}

# Add the web tier VMs to the backend pool
resource "azurerm_network_interface_backend_address_pool_association" "web_nic_lb_association" {
  count                    = var.web_vm_count
  network_interface_id     = element(azurerm_network_interface.web_nic.*.id, count.index)
  ip_configuration_name    = "internal"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.lb_backend_pool.id
}

# Azure Application Gateway Public IP
resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "${random_pet.rg_name.id}-app-gateway-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Azure Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = "${random_pet.rg_name.id}-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name                  = "app_gateway_ip_configuration"
    subnet_id             = azurerm_subnet.web.id
  }

  frontend_ip_configuration {
    name                 = "frontend_ip_configuration"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }

  backend_http_settings {
    name                  = "http_settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  frontend_port {
    name = "frontend_port"
    port = 80
  }

  backend_address_pool {
    name = "backend_pool"
  }

  http_listener {
    name                           = "http_listener"
    frontend_ip_configuration_name = "frontend_ip_configuration"
    frontend_port_name             = "frontend_port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request_routing_rule"
    rule_type                  = "Basic"
    http_listener_name         = "http_listener"
    backend_address_pool_name  = "backend_pool"
    backend_http_settings_name = "http_settings"
  }
}

# Azure SQL Server
resource "azurerm_sql_server" "sql_server" {
  name                         = "${random_pet.rg_name.id}-sql-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
}

# Azure SQL Database
resource "azurerm_sql_database" "sql_db" {
  name                        = "${random_pet.rg_name.id}-sql-db"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  server_name                 = azurerm_sql_server.sql_server.name
  edition                     = "Standard"
  requested_service_objective_name = "S0"
}

# Define the Azure client configuration data source
data "azurerm_client_config" "current" {}

# Note: Azure Backup Vaults cannot be managed directly via Terraform

# Azure Backup Policy for Virtual Machines
resource "azurerm_backup_policy_vm" "vm_backup_policy" {
  name                 = "${random_pet.rg_name.id}-vm-backup-policy"
  resource_group_name  = azurerm_resource_group.rg.name
  recovery_vault_name  = "your_recovery_vault_name_here"

  backup {
    frequency        = 24
    time             = var.backup_time
  }

  retention_daily    = var.retention_daily
  retention_weekly   = var.retention_weekly
}


# Azure Backup Protected VM
resource "azurerm_backup_protected_vm" "vm_backup" {
  source_vm_id         = azurerm_windows_virtual_machine.web_vm[0].id
  backup_policy_id     = azurerm_backup_policy_vm.vm_backup_policy.id
  recovery_vault_name  = "your_recovery_vault_name_here"
}

# Azure Backup Policy for SQL
# Note: Azure does not support defining backup policies for SQL databases directly using Terraform

#Azure Security Center
resource "azurerm_security_center_subscription_pricing" "security_center" {
  tier                = "Standard"
}

