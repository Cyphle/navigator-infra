data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

data "aws_db_subnet_group" "database" {
  name = "${var.project_name}-db-subnet-group"
}
