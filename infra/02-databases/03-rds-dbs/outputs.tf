

output "navigator_database_name" {
  description = "Name of the Navigator database"
  value       = postgresql_database.navigator.name
}

output "keycloak_database_name" {
  description = "Name of the Keycloak database"
  value       = postgresql_database.keycloak.name
}
