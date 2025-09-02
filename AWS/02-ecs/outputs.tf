output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.banana.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.banana_front.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.banana_front.dns_name
}

output "alb_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.banana_front.dns_name}"
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.banana_front.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.banana_front.arn
}
