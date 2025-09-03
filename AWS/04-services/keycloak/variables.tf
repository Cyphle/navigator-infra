# Variables for Keycloak Service

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_config" {
  description = "ECS configuration"
  type = object({
    cpu          = number
    memory       = number
    desired_count = number
  })
}

variable "keycloak_config" {
  description = "Keycloak configuration"
  type = object({
    admin_user     = string
    admin_password = string
    realm_name     = string
  })
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "keycloak_target_group_arn" {
  description = "ARN of the keycloak target group"
  type        = string
}

variable "keycloak_log_group_name" {
  description = "Name of the keycloak log group"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "keycloak_repository_url" {
  description = "URL of the keycloak ECR repository"
  type        = string
}