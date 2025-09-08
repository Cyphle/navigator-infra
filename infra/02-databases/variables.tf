variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "navigator"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}