provider "aws" {
  region = var.aws_region
}

provider "postgresql" {
  host     = aws_db_instance.main.endpoint
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = random_password.db_password.result
  sslmode  = "require"
}
