resource "aws_ecs_cluster" "pro" {
  name = "${var.product}-${var.application}-${var.environment}"
}

resource "aws_ecs_cluster_capacity_providers" "pro" {
  cluster_name = aws_ecs_cluster.pro.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
}