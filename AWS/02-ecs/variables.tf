variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret key"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS region"
}

variable "app_image" {
  type        = string
  default     = "rg.fr-par.scw.cloud/banana/banana-front:latest"
  description = "Docker image for the application"
}

variable "app_port" {
  type        = number
  default     = 80
  description = "Port exposed by the application"
}

variable "app_cpu" {
  type        = number
  default     = 256
  description = "CPU units for the task (256 = 0.25 vCPU)"
}

variable "app_memory" {
  type        = number
  default     = 512
  description = "Memory for the task in MB"
}

variable "app_desired_count" {
  type        = number
  default     = 2
  description = "Desired number of tasks running"
}

variable "app_environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}
