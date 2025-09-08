aws_region = "us-east-1"

project_name = "navigator"
environment  = "prod"

domain_names = {
  frontend = ["app.one-navigator.fr", "app.one-navigator.com"]
  auth     = ["auth.one-navigator.fr", "auth.one-navigator.com"]
  back    = ["api.one-navigator.fr", "api.one-navigator.com"]
}

availability_zones = ["eu-west-3a", "eu-west-3b"]

# Database
database_config = {
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
}

# ECS
github_claim_suffixes = ["environment:prod"]