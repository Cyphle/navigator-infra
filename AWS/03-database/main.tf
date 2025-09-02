# Subnet Group pour RDS
resource "aws_db_subnet_group" "banana" {
  name       = "banana-db-subnet-group"
  subnet_ids = data.aws_subnet.private_subnets[*].id

  tags = {
    Name        = "banana-db-subnet-group"
    Environment = "production"
    Project     = "banana"
  }
}

# Security Group pour RDS
resource "aws_security_group" "rds" {
  name_prefix = "banana-rds-"
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
    Name        = "banana-rds-sg"
    Environment = "production"
    Project     = "banana"
  }
}

# Instance RDS PostgreSQL
resource "aws_db_instance" "banana_postgres" {
  identifier = "banana-postgres"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "bananadb"
  username = var.db_user
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.banana.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = false
  final_snapshot_identifier = "banana-postgres-final-snapshot"

  tags = {
    Name        = "banana-postgres"
    Environment = "production"
    Project     = "banana"
  }
}

# Subnet Group pour ElastiCache
resource "aws_elasticache_subnet_group" "banana" {
  name       = "banana-redis-subnet-group"
  subnet_ids = data.aws_subnet.private_subnets[*].id
}

# Security Group pour ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "banana-redis-"
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
    Name        = "banana-redis-sg"
    Environment = "production"
    Project     = "banana"
  }
}

# Parameter Group pour Redis
resource "aws_elasticache_parameter_group" "banana" {
  family = "redis7"
  name   = "banana-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# Cluster ElastiCache Redis
resource "aws_elasticache_cluster" "banana_redis" {
  cluster_id           = "banana-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.banana.name
  port                 = 6379

  subnet_group_name = aws_elasticache_subnet_group.banana.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name        = "banana-redis"
    Environment = "production"
    Project     = "banana"
  }
}
