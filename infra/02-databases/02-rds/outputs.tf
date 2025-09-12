# Outputs for Databases Module

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "navigator_database_name" {
  description = "Name of the Navigator database"
  value       = postgresql_database.navigator.name
}

output "keycloak_database_name" {
  description = "Name of the Keycloak database"
  value       = postgresql_database.keycloak.name
}

output "postgres_server_security_group_id" {
  description = "ID of the PostgreSQL server security group"
  value       = aws_security_group.postgres_server.id
}

output "postgres_clients_security_group_id" {
  description = "ID of the PostgreSQL clients security group"
  value       = aws_security_group.postgres_clients.id
}