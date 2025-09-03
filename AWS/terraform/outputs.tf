# Main Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.vpc.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.vpc.alb_zone_id
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.vpc.certificate_arn
}

output "hosted_zone_id" {
  description = "ID of the main hosted zone"
  value       = module.vpc.hosted_zone_id
}

output "hosted_zone_com_id" {
  description = "ID of the .com hosted zone"
  value       = module.vpc.hosted_zone_com_id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.databases.db_instance_endpoint
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.services.ecs_cluster_arn
}

output "frontend_ecr_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.backend_repository_url
}

output "keycloak_ecr_repository_url" {
  description = "URL of the keycloak ECR repository"
  value       = module.ecr.keycloak_repository_url
}

output "keycloak_credentials_secret_arn" {
  description = "ARN of the Keycloak credentials secret"
  value       = module.keycloak.keycloak_credentials_secret_arn
}