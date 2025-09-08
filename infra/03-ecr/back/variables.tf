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

variable "ecr_images_retention_in_days" {
  description = "Retention duration of old images"
  type        = number
  default     = 10
}
