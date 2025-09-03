# Outputs for Keycloak Service

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.keycloak.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.keycloak.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.keycloak.id
}

output "keycloak_credentials_secret_arn" {
  description = "ARN of the Keycloak credentials secret"
  value       = aws_secretsmanager_secret.keycloak_credentials.arn
}