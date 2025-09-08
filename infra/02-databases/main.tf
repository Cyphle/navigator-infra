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
  name                    = "${var.project_name}-db-credentials"
  description             = "Database credentials for Navigator application"
  recovery_window_in_days = 7

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    # Admin credentials (postgres user)
    admin_username = "postgres"
    admin_password = random_password.db_password.result
    engine         = "postgres"
    host           = aws_db_instance.main.endpoint
    port           = 5432
    
    # Navigator database credentials
    navigator_username = postgresql_role.navigator_user.name
    navigator_password = random_password.navigator_password.result
    navigator_dbname   = postgresql_database.navigator.name
    navigator_jdbc_url = "jdbc:postgresql://${aws_db_instance.main.endpoint}:5432/${postgresql_database.navigator.name}"
    
    # Keycloak database credentials
    keycloak_username = postgresql_role.keycloak_user.name
    keycloak_password = random_password.keycloak_password.result
    keycloak_dbname   = postgresql_database.keycloak.name
    keycloak_jdbc_url = "jdbc:postgresql://${aws_db_instance.main.endpoint}:5432/${postgresql_database.keycloak.name}"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres16"
  name   = "${var.project_name}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = var.common_tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine configuration
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = var.database_config.instance_class

  # Storage configuration
  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  username = "postgres"
  password = random_password.db_password.result
  port     = 5432

  # Network configuration
  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.database_config.backup_retention_period
  backup_window          = var.database_config.backup_window
  maintenance_window     = var.database_config.maintenance_window
  delete_automated_backups = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Deletion protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db"
  })
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Create Navigator database
resource "postgresql_database" "navigator" {
  name              = "navigator"
  owner             = "postgres"
  template          = "template0"
  encoding          = "UTF8"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true

  depends_on = [aws_db_instance.main]
}

# Create Keycloak database
resource "postgresql_database" "keycloak" {
  name              = "keycloak"
  owner             = "postgres"
  template          = "template0"
  encoding          = "UTF8"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true

  depends_on = [aws_db_instance.main]
}

# Create Navigator user
resource "postgresql_role" "navigator_user" {
  name     = "navigator_user"
  login    = true
  password = random_password.navigator_password.result

  depends_on = [postgresql_database.navigator]
}

# Create Keycloak user
resource "postgresql_role" "keycloak_user" {
  name     = "keycloak_user"
  login    = true
  password = random_password.keycloak_password.result

  depends_on = [postgresql_database.keycloak]
}

# Grant permissions to Navigator user on Navigator database
resource "postgresql_grant" "navigator_grant" {
  database    = postgresql_database.navigator.name
  role        = postgresql_role.navigator_user.name
  privileges  = ["ALL"]

  depends_on = [postgresql_role.navigator_user]
}

# Grant permissions to Keycloak user on Keycloak database
resource "postgresql_grant" "keycloak_grant" {
  database    = postgresql_database.keycloak.name
  role        = postgresql_role.keycloak_user.name
  privileges  = ["ALL"]

  depends_on = [postgresql_role.keycloak_user]
}