# Terraform Configuration with Module Calls

# VPC Module
module "vpc" {
  source = "../01-network"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  availability_zones = data.aws_availability_zones.available.names
  domain_names       = var.domain_names
}

# ECR Module
module "ecr" {
  source = "../03-ecr"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

# Databases Module
module "databases" {
  source = "../02-databases"

  name_prefix                  = local.name_prefix
  common_tags                  = local.common_tags
  database_config              = var.database_config
  database_subnet_group_name   = module.vpc.database_subnet_group_name
  database_security_group_id   = module.vpc.database_security_group_id
}

# Services Module
module "services" {
  source = "../04-services"

  name_prefix                        = local.name_prefix
  common_tags                        = local.common_tags
  db_credentials_secret_arn          = module.databases.db_credentials_secret_arn
  keycloak_credentials_secret_arn    = module.keycloak.keycloak_credentials_secret_arn
}

# Frontend Service
module "frontend" {
  source = "04-servicesrontend"

  name_prefix                    = local.name_prefix
  common_tags                    = local.common_tags
  aws_region                     = var.aws_region
  ecs_config                     = var.ecs_config
  react_config                   = var.react_config
  ecs_cluster_id                 = module.services.ecs_cluster_id
  ecs_cluster_name               = "${local.name_prefix}-cluster"
  ecs_task_execution_role_arn    = module.services.ecs_task_execution_role_arn
  ecs_task_role_arn             = module.services.ecs_task_role_arn
  ecs_security_group_id         = module.vpc.ecs_security_group_id
  private_subnet_ids            = module.vpc.private_subnet_ids
  frontend_target_group_arn     = module.vpc.frontend_target_group_arn
  frontend_log_group_name       = module.services.frontend_log_group_name
  frontend_repository_url       = module.ecr.frontend_repository_url
  alb_listener_arn              = module.vpc.alb_listener_arn
}

# Backend Service
module "backend" {
  source = "04-servicesackend"

  name_prefix                        = local.name_prefix
  common_tags                        = local.common_tags
  aws_region                         = var.aws_region
  ecs_config                         = var.ecs_config
  ecs_cluster_id                     = module.services.ecs_cluster_id
  ecs_cluster_name                   = "${local.name_prefix}-cluster"
  ecs_task_execution_role_arn        = module.services.ecs_task_execution_role_arn
  ecs_task_role_arn                 = module.services.ecs_task_role_arn
  ecs_security_group_id             = module.vpc.ecs_security_group_id
  private_subnet_ids                = module.vpc.private_subnet_ids
  backend_target_group_arn          = module.vpc.backend_target_group_arn
  backend_log_group_name            = module.services.backend_log_group_name
  backend_repository_url            = module.ecr.backend_repository_url
  db_credentials_secret_arn         = module.databases.db_credentials_secret_arn
  keycloak_credentials_secret_arn   = module.keycloak.keycloak_credentials_secret_arn
  alb_listener_arn                  = module.vpc.alb_listener_arn
}

# Keycloak Service
module "keycloak" {
  source = "04-serviceseycloak"

  name_prefix                        = local.name_prefix
  common_tags                        = local.common_tags
  aws_region                         = var.aws_region
  ecs_config                         = var.ecs_config
  keycloak_config                    = var.keycloak_config
  ecs_cluster_id                     = module.services.ecs_cluster_id
  ecs_cluster_name                   = "${local.name_prefix}-cluster"
  ecs_task_execution_role_arn        = module.services.ecs_task_execution_role_arn
  ecs_task_role_arn                 = module.services.ecs_task_role_arn
  ecs_security_group_id             = module.vpc.ecs_security_group_id
  private_subnet_ids                = module.vpc.private_subnet_ids
  keycloak_target_group_arn         = module.vpc.keycloak_target_group_arn
  keycloak_log_group_name           = module.services.keycloak_log_group_name
  keycloak_repository_url           = module.ecr.keycloak_repository_url
  db_credentials_secret_arn         = module.databases.db_credentials_secret_arn
  alb_listener_arn                  = module.vpc.alb_listener_arn
}