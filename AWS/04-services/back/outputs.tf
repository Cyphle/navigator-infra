output "backend_cluster_id" {
  description = "ID of the backend ECS cluster"
  value       = aws_ecs_cluster.backend.id
}

output "backend_cluster_name" {
  description = "Name of the backend ECS cluster"
  value       = aws_ecs_cluster.backend.name
}

output "backend_cluster_arn" {
  description = "ARN of the backend ECS cluster"
  value       = aws_ecs_cluster.backend.arn
}

output "backend_service_id" {
  description = "ID of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "backend_task_execution_role_arn" {
  description = "ARN of the backend task execution role"
  value       = aws_iam_role.backend_task_execution_role.arn
}

output "backend_task_role_arn" {
  description = "ARN of the backend task role"
  value       = aws_iam_role.backend_task_role.arn
}

output "backend_log_group_name" {
  description = "Name of the backend CloudWatch log group"
  value       = aws_cloudwatch_log_group.backend.name
}