resource "aws_ecs_cluster" "keycloak" {
  name = "${var.project_name}-${var.environment}-keycloak"
}

resource "aws_ecs_cluster_capacity_providers" "keycloak" {
  cluster_name = aws_ecs_cluster.keycloak.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
}