data "aws_vpc" "core" {
  tags = {
    Name = "${var.project_name}-${var.environment}"
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

data "aws_alb" "apps" {
  name = "${var.project_name}-alb"
}

data "aws_alb_listener" "https" {
  load_balancer_arn = data.aws_alb.apps.arn
  port              = 443
}

data "aws_security_group" "apps_alb" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-alb-sg"]
  }
}

data "aws_security_group" "postgres_clients" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-postgresql-clients-${var.environment}"]
  }
}
