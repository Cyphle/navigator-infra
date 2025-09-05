locals {
  github_actions_environment_variables = {
    "LITE_PRO_APP_CONFIG_SECRET_ARN"              = aws_secretsmanager_secret.ecs_service_app_config.arn
    "LITE_PRO_DB_CONFIG_SECRET_ARN"               = data.aws_secretsmanager_secret.shared_db_pro_rw.arn
    "LITE_PRO_DATAWAREHOUSE_DB_CONFIG_SECRET_ARN" = data.aws_secretsmanager_secret.datawarehouse-db-datawarehouse-rw.arn
    "LITE_PRO_TASK_CPU"                           = var.fargate_cpu
    "LITE_PRO_TASK_MEMORY"                        = var.fargate_memory
    "LITE_PRO_API_PORT"                           = var.pro_port
  }
  github_actions_environment_secrets = {
  }
}

data "github_repository" "main" {
  name = var.github_repository
}

resource "github_actions_environment_variable" "this" {
  for_each = local.github_actions_environment_variables

  repository    = data.github_repository.main.name
  environment   = var.environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_secret" "this" {
  for_each = local.github_actions_environment_secrets

  repository      = data.github_repository.main.name
  environment     = var.environment
  secret_name     = each.key
  plaintext_value = each.value
}
