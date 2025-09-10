# Random password for database admin (postgres user)
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Random password for Navigator user
resource "random_password" "navigator_password" {
  length  = 16
  special = true
}

# Random password for Keycloak user
resource "random_password" "keycloak_password" {
  length  = 16
  special = true
}

# Store database credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-db-secrets"
  description             = "Database secrets for Navigator application"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials_initial" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    # Admin credentials (postgres user)
    admin_username = "postgres"
    admin_password = random_password.db_password.result
    engine         = "postgres"
    port           = 5432

    # Navigator database credentials
    navigator_username = "navigator_user"
    navigator_password = random_password.navigator_password.result
    navigator_dbname   = "navigator"

    # Keycloak database credentials
    keycloak_username = "keycloak_user"
    keycloak_password = random_password.keycloak_password.result
    keycloak_dbname   = "keycloak"
  })
}
