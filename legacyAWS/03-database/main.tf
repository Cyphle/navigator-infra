# Subnet Group pour RDS
resource "aws_db_subnet_group" "navigator" {
  name       = "navigator-db-subnet-group"
  subnet_ids = data.aws_subnet.private_subnets[*].id

  tags = {
    Name        = "navigator-db-subnet-group"
    Environment = "production"
    Project     = "navigator"
  }
}

# Security Group pour RDS
resource "aws_security_group" "rds" {
  name_prefix = "navigator-rds-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "navigator-rds-sg"
    Environment = "production"
    Project     = "navigator"
  }
}

# Instance RDS PostgreSQL
resource "aws_db_instance" "navigator_postgres" {
  identifier = "navigator-postgres"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "navigatordb"
  username = var.db_user
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.navigator.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = false
  final_snapshot_identifier = "navigator-postgres-final-snapshot"

  tags = {
    Name        = "navigator-postgres"
    Environment = "production"
    Project     = "navigator"
  }
}

# Subnet Group pour ElastiCache
resource "aws_elasticache_subnet_group" "navigator" {
  name       = "navigator-redis-subnet-group"
  subnet_ids = data.aws_subnet.private_subnets[*].id
}

# Security Group pour ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "navigator-redis-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "navigator-redis-sg"
    Environment = "production"
    Project     = "navigator"
  }
}

# Parameter Group pour Redis
resource "aws_elasticache_parameter_group" "navigator" {
  family = "redis7"
  name   = "navigator-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# Cluster ElastiCache Redis
resource "aws_elasticache_cluster" "navigator_redis" {
  cluster_id           = "navigator-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.navigator.name
  port                 = 6379

  subnet_group_name = aws_elasticache_subnet_group.navigator.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name        = "navigator-redis"
    Environment = "production"
    Project     = "navigator"
  }
}
