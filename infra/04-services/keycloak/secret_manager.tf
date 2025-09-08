# Secret manager
resource "aws_secretsmanager_secret" "ecs_service_app_config" {
  name        = "${var.project_name}-keycloak-ecs-service-app-config-${var.environment}"
  description = "ECS service app config envs"
}

resource "aws_secretsmanager_secret_version" "ecs_service_app_config" {
  secret_id                = aws_secretsmanager_secret.ecs_service_app_config.id
  secret_string_wo_version = 1
  secret_string_wo = jsonencode(
    {
      ENV                          = var.environment,
    }
  )
}
