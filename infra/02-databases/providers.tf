provider "aws" {
  region = var.region
}

provider "postgresql" {
  host     = aws_db_instance.main.address
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = random_password.db_password.result
  sslmode  = "require"
}
