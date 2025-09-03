# Variables for Backend Service

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

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "backend_log_group_name" {
  description = "Name of the backend log group"
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

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "backend_repository_url" {
  description = "URL of the backend ECR repository"
  type        = string
}