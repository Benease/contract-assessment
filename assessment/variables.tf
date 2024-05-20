variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "vnet_address_space" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The address space for the virtual network."
}

variable "web_subnet_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "The address prefix for the web tier subnet."
}

variable "db_subnet_prefix" {
  type        = string
  default     = "10.0.2.0/24"
  description = "The address prefix for the database tier subnet."
}

variable "web_vm_count" {
  type        = number
  default     = 2
  description = "Number of web tier VMs to create."
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Size of the virtual machines."
}

variable "admin_username" {
  type        = string
  description = "Admin username for the virtual machines."
}

variable "admin_password" {
  type        = string
  description = "Admin password for the virtual machines."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "Size of the OS disk in gigabytes."
}

variable "sql_admin_username" {
  type        = string
  description = "Administrator username for the Azure SQL Database."
}

variable "sql_admin_password" {
  type        = string
  description = "Administrator password for the Azure SQL Database."
  sensitive   = true
}

variable "database_connection_string" {
  description = "Connection string for the database"
}

variable "database_password" {
  description = "Password for the database"
}

variable "backup_time" {
  description = "Preferred time for VM backups"
  type        = string
  default     = "23:00" # Default backup time at 11:00 PM UTC
}

variable "retention_daily" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 7
}

variable "retention_weekly" {
  description = "Number of weeks to retain weekly backups"
  type        = number
  default     = 4
}

