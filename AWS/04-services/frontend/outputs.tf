# Outputs for Frontend Service

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.frontend.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.frontend.id
}