# Variables for Databases Module

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class         = string
    allocated_storage      = number
    max_allocated_storage  = number
    backup_retention_period = number
    backup_window          = string
    maintenance_window     = string
  })
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "database_security_group_id" {
  description = "ID of the database security group"
  type        = string
}