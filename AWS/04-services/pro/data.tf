data "aws_region" "current" {}

data "aws_vpc" "core" {
  tags = {
    Name = "${var.product}-${var.environment}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.core.id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name_lite
  private_zone = false
}

data "aws_alb" "apps" {
  name = "${var.product}-apps-${var.environment}"
}

data "aws_alb_listener" "apps_443" {
  load_balancer_arn = data.aws_alb.apps.arn
  port              = 443
}

data "aws_security_group" "apps_alb" {
  filter {
    name   = "tag:Name"
    values = ["${var.product}-apps-alb-${var.environment}"]
  }
}

data "aws_secretsmanager_secret" "shared_db_pro_rw" {
  name = "${var.product}-shared-db-pro-rw-${var.environment}"
}

data "aws_secretsmanager_secret" "applications_common" {
  name = "${var.product}-common-${var.environment}"
}

data "aws_secretsmanager_secret" "datawarehouse-db-datawarehouse-rw" {
  name = "${var.product}-datawarehouse-db-datawarehouse-rw-${var.environment}"
}

data "aws_security_group" "shared_postgresql_clients" {
  filter {
    name   = "tag:Name"
    values = ["${var.product}-shared-postgresql-clients-${var.environment}"]
  }
}

data "aws_security_group" "datawarehouse_postgresql_clients" {
  filter {
    name   = "tag:Name"
    values = ["${var.product}-datawarehouse-postgresql-clients-${var.environment}"]
  }
}

data "aws_s3_bucket" "resources" {
  bucket = "${var.product}-${var.environment}-resources"
}

data "aws_s3_bucket" "raw_data" {
  bucket = "${var.product}-${var.environment}-raw-data"
}

data "aws_sqs_queue" "grdf_api_collection" {
  name = "GrdfApiCollection"
}
