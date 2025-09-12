variable "region" {
  description = "Default AWS region name"
  type        = string
  default     = "eu-west-3"
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
    back     = list(string)
  })
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}