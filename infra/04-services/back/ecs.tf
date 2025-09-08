resource "aws_ecs_cluster" "backend" {
  name = "${var.project_name}-${var.environment}-backend"
}

resource "aws_ecs_cluster_capacity_providers" "backend" {
  cluster_name = aws_ecs_cluster.backend.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
}