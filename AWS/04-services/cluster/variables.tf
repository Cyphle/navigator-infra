# Variables for Services Module

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  type        = string
}

variable "keycloak_credentials_secret_arn" {
  description = "ARN of the Keycloak credentials secret"
  type        = string
}