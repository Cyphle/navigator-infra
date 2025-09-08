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
    cpu           = 512
    memory        = 1024
    desired_count = 1
  }
}

variable "keycloak_repository_url" {
  description = "ECR repository URL for Keycloak image"
  type        = string
}

variable "keycloak_config" {
  description = "Keycloak configuration"
  type = object({
    admin_user = string
    realm_name = string
  })
  default = {
    admin_user = "admin"
    realm_name = "navigator"
  }
}

variable "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
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

variable "keycloak_target_group_arn" {
  description = "ARN of the Keycloak target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}