output "frontend_cluster_id" {
  description = "ID of the frontend ECS cluster"
  value       = aws_ecs_cluster.frontend.id
}

output "frontend_cluster_name" {
  description = "Name of the frontend ECS cluster"
  value       = aws_ecs_cluster.frontend.name
}

output "frontend_cluster_arn" {
  description = "ARN of the frontend ECS cluster"
  value       = aws_ecs_cluster.frontend.arn
}

output "frontend_service_id" {
  description = "ID of the frontend ECS service"
  value       = aws_ecs_service.frontend.id
}

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = aws_ecs_service.frontend.name
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "frontend_task_execution_role_arn" {
  description = "ARN of the frontend task execution role"
  value       = aws_iam_role.frontend_task_execution_role.arn
}

output "frontend_task_role_arn" {
  description = "ARN of the frontend task role"
  value       = aws_iam_role.frontend_task_role.arn
}

output "frontend_log_group_name" {
  description = "Name of the frontend CloudWatch log group"
  value       = aws_cloudwatch_log_group.frontend.name
}