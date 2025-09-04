# Variables for Navigator Application Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

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

variable "domain_names" {
  description = "Domain names for the application"
  type = object({
    frontend = list(string)
    auth     = list(string)
  })
  default = {
    frontend = ["app.one-navigator.fr", "app.one-navigator.com"]
    auth     = ["auth.one-navigator.fr", "auth.one-navigator.com"]
  }
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class    = string
    allocated_storage = number
    max_allocated_storage = number
    backup_retention_period = number
    backup_window     = string
    maintenance_window = string
  })
  default = {
    instance_class         = "db.t3.micro"
    allocated_storage      = 20
    max_allocated_storage  = 100
    backup_retention_period = 7
    backup_window          = "03:00-04:00"
    maintenance_window     = "sun:04:00-sun:05:00"
  }
}

variable "ecs_config" {
  description = "ECS configuration"
  type = object({
    cpu    = number
    memory = number
    desired_count = number
  })
  default = {
    cpu          = 256
    memory       = 512
    desired_count = 1
  }
}

variable "keycloak_config" {
  description = "Keycloak configuration"
  type = object({
    admin_user     = string
    admin_password = string
    realm_name     = string
  })
  default = {
    admin_user     = "admin"
    admin_password = "admin123!" # Change this in production
    realm_name     = "quarkusexample"
  }
  sensitive = true
}

variable "quarkus_config" {
  description = "Quarkus backend configuration"
  type = object({
    database_url      = string
    database_username = string
    database_password = string
    keycloak_url      = string
    keycloak_realm    = string
    keycloak_client_id = string
    keycloak_client_secret = string
  })
  sensitive = true
}

variable "react_config" {
  description = "React frontend configuration"
  type = object({
    api_url = string
    auth_url = string
    auth_realm = string
    auth_client_id = string
  })
}