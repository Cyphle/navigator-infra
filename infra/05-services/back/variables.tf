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

variable "github_claim_suffixes" {
  description = "GitHub branches or environments allowed for assuming role from OIDC provider"
  type        = list(string)
}

variable "github_repository" {
  description = "GitHub repository to allow assuming role from OIDC provider"
  type        = string
  default     = "navigator-back"
}

variable "fargate_cpu" {
  description = "Amount of CPU per task 256 .25 vCPU"
  type        = number
}

variable "fargate_memory" {
  description = "Memory size in MBytes of each task"
  type        = number
}

variable "backend_port" {
  description = "Port of backend"
  type        = number
  default     = 8080
}

variable "backend_health_check_path" {
  description = "URI used by ALB to check target health"
  type        = string
  default     = "/health/ready"
}

variable "backend_container_name" {
  description = "Name of the main container"
  type        = string
  default     = "backend"
}

variable "log_retention_in_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "backend_desired_tasks_count" {
  description = "Number of containers to execute in parallel"
  type        = number
  default     = 1
}

variable "backend_rule_priority" {
  description = "Rule priority for ALB listener"
  type        = number
  default     = 10
}

variable "domain_names" {
  description = "Domain names for the application"
  type = object({
    backend = list(string)
    auth     = list(string)
    back     = list(string)
  })
}

variable "github_organization" {
  description = "Github name because I'm not an organization"
  type        = string
  default     = "Cyphle"
}
