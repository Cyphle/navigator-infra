provider "aws" {
  region = var.region
}

provider "postgresql" {
  host     = aws_db_instance.main.endpoint
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = local.db_creds.admin_password
  sslmode  = "require"
}
