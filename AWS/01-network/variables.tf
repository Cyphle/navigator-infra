variable "aws_region" {
  description = "AWS region for resources"
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

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}