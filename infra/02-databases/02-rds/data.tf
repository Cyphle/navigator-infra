data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

data "aws_db_subnet_group" "database" {
  name = "${var.project_name}-db-subnet-group"
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-db-secrets"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  # db_creds.admin_username
  # db_creds.admin_password
  # db_creds.port
  # db_creds.navigator_username, etc.
}