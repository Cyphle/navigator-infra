# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres17"
  name   = "${var.project_name}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = local.common_tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine configuration
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = var.database_config.instance_class

  # Storage configuration
  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  username = "postgres"
  password = local.db_creds.admin_password
  port     = 5432

  # Network configuration
  db_subnet_group_name   = data.aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.postgres_server.id]
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
  deletion_protection = false
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db"
  })
}

resource "aws_security_group" "postgres_clients" {
  #checkov:skip=CKV2_AWS_5:The security is attached to RDS but not EC2. Avoid false positive
  name_prefix = "${var.project_name}-postgresql-clients-${var.environment}-"
  description = "Security group for clients"
  vpc_id      = data.aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-postgresql-clients-${var.environment}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "postgres_server" {
  #checkov:skip=CKV2_AWS_5:The security is attached to RDS but not EC2. Avoid false positive
  name_prefix = "${var.project_name}-postgresql-server-${var.environment}-"
  description = "Security group for shared database server"
  vpc_id      = data.aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-postgresql-server-${var.environment}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "postgresql_server_rds_client" {
  description              = "Allow postgresql from rds_client sg"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.postgres_clients.id
  security_group_id        = aws_security_group.postgres_server.id
}

resource "aws_security_group_rule" "postgresql_server_vpc_access" {
  description       = "Allow postgresql from VPC CIDR blocks"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.postgres_server.id
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
