variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "navigator"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "navigator"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

variable "ecs_config" {
  description = "ECS configuration"
  type = object({
    cpu           = number
    memory        = number
    desired_count = number
  })
  default = {
    cpu           = 256
    memory        = 512
    desired_count = 1
  }
}

variable "backend_repository_url" {
  description = "ECR repository URL for backend image"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  type        = string
}

variable "keycloak_credentials_secret_arn" {
  description = "ARN of the Keycloak credentials secret"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}