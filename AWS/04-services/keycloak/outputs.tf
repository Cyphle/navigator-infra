output "keycloak_cluster_id" {
  description = "ID of the Keycloak ECS cluster"
  value       = aws_ecs_cluster.keycloak.id
}

output "keycloak_cluster_name" {
  description = "Name of the Keycloak ECS cluster"
  value       = aws_ecs_cluster.keycloak.name
}

output "keycloak_cluster_arn" {
  description = "ARN of the Keycloak ECS cluster"
  value       = aws_ecs_cluster.keycloak.arn
}

output "keycloak_service_id" {
  description = "ID of the Keycloak ECS service"
  value       = aws_ecs_service.keycloak.id
}

output "keycloak_service_name" {
  description = "Name of the Keycloak ECS service"
  value       = aws_ecs_service.keycloak.name
}

output "keycloak_task_definition_arn" {
  description = "ARN of the Keycloak task definition"
  value       = aws_ecs_task_definition.keycloak.arn
}

output "keycloak_task_execution_role_arn" {
  description = "ARN of the Keycloak task execution role"
  value       = aws_iam_role.keycloak_task_execution_role.arn
}

output "keycloak_task_role_arn" {
  description = "ARN of the Keycloak task role"
  value       = aws_iam_role.keycloak_task_role.arn
}

output "keycloak_log_group_name" {
  description = "Name of the Keycloak CloudWatch log group"
  value       = aws_cloudwatch_log_group.keycloak.name
}

output "keycloak_credentials_secret_arn" {
  description = "ARN of the Keycloak credentials secret"
  value       = aws_secretsmanager_secret.keycloak_credentials.arn
}

output "keycloak_credentials_secret_name" {
  description = "Name of the Keycloak credentials secret"
  value       = aws_secretsmanager_secret.keycloak_credentials.name
}