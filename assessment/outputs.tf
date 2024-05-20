output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "web_vm_names" {
  value = azurerm_windows_virtual_machine.web_vm[*].name
}

output "db_vm_name" {
  value = azurerm_windows_virtual_machine.db_vm[0].name
}

output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "app_gateway_frontend_ip" {
  value = azurerm_public_ip.app_gateway_public_ip.ip_address
}

output "sql_server_name" {
  value = azurerm_sql_server.sql_server.name
}

output "sql_database_name" {
  value = azurerm_sql_database.sql_db.name
}

output "vm_backup_policy_id" {
  value = azurerm_backup_policy_vm.vm_backup_policy.id
}

output "vm_backup_protected_vm_id" {
  value = azurerm_backup_protected_vm.vm_backup.id
}

output "security_center_subscription_pricing_id" {
  value = azurerm_security_center_subscription_pricing.security_center.id
}

output "backup_policy_id" {
  description = "ID of the Azure Backup policy for VMs"
  value       = azurerm_backup_policy_vm.vm_backup_policy.id
}

