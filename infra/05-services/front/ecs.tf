resource "aws_ecs_cluster" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend"
}

resource "aws_ecs_cluster_capacity_providers" "frontend" {
  cluster_name = aws_ecs_cluster.frontend.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
}