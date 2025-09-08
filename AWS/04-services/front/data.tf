data "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
}

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

