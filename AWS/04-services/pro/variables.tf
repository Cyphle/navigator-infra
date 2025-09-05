variable "region" {
  description = "Default AWS region name"
  type        = string
  default     = "eu-west-3"
}

variable "product" {
  description = "Product name used into naming and tagging convention"
  type        = string
  default     = "lite"
}

variable "application" {
  description = "Application name used into naming and tagging convention"
  type        = string
  default     = "pro"
}

variable "environment" {
  description = "Environment name used into naming and tagging convention. Must match with workspace names."
  type        = string
}

variable "fargate_cpu" {
  description = "Amount of CPU per task 256 .25 vCPU"
  type        = number
}

variable "fargate_memory" {
  description = "Memory size in MBytes of each task"
  type        = number
}

variable "domain_name_lite" {
  description = "External domain name for the application"
  type        = string
}

variable "ecr_images_retention_in_days" {
  description = "Retention duration of old images"
  type        = number
  default     = 10
}

variable "log_retention_in_days" {
  description = "Log retention in days"
  type        = number
}

variable "backend_url_name" {
  description = "External DNS name of the backend application"
  type        = string
  default     = "app-pro"
}

variable "github_organization" {
  description = "GitHub organization to allow assuming role from OIDC provider"
  type        = string
  default     = "Lite-eco"
}

variable "github_repository" {
  description = "GitHub repository to allow assuming role from OIDC provider"
  type        = string
  default     = "lite"
}

variable "github_claim_suffixes" {
  description = "GitHub branches or environments allowed for assuming role from OIDC provider"
  type        = list(string)
}
