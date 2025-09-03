# Keycloak Service Configuration

# Random password for Keycloak admin
resource "random_password" "keycloak_admin_password" {
  length  = 16
  special = true
}

# Store Keycloak credentials in Secrets Manager
resource "aws_secretsmanager_secret" "keycloak_credentials" {
  name                    = "${var.name_prefix}-keycloak-credentials"
  description             = "Keycloak credentials for Navigator application"
  recovery_window_in_days = 7

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "keycloak_credentials" {
  secret_id = aws_secretsmanager_secret.keycloak_credentials.id
  secret_string = jsonencode({
    admin_user     = var.keycloak_config.admin_user
    admin_password = random_password.keycloak_admin_password.result
    realm_name     = var.keycloak_config.realm_name
    auth_server_url = "http://keycloak.${var.name_prefix}.local:8080"
    client_id      = "navigator"
    client_secret  = "navigator-secret"
  })
}



# ECS Task Definition for Keycloak
resource "aws_ecs_task_definition" "keycloak" {
  family                   = "${var.name_prefix}-keycloak"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_config.cpu
  memory                   = var.ecs_config.memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "keycloak"
      image = "${var.keycloak_repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "KEYCLOAK_ADMIN"
          value = var.keycloak_config.admin_user
        },
        {
          name  = "KEYCLOAK_ADMIN_PASSWORD"
          value = random_password.keycloak_admin_password.result
        },
        {
          name  = "KC_DB"
          value = "postgres"
        },
        {
          name  = "KC_HOSTNAME_STRICT"
          value = "false"
        },
        {
          name  = "KC_HOSTNAME_STRICT_HTTPS"
          value = "false"
        },
        {
          name  = "KC_HTTP_ENABLED"
          value = "true"
        },
        {
          name  = "KC_PROXY"
          value = "edge"
        }
      ]

      secrets = [
        {
          name      = "KC_DB_URL"
          valueFrom = "${var.db_credentials_secret_arn}:jdbc_url::"
        },
        {
          name      = "KC_DB_USERNAME"
          valueFrom = "${var.db_credentials_secret_arn}:username::"
        },
        {
          name      = "KC_DB_PASSWORD"
          valueFrom = "${var.db_credentials_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.keycloak_log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/health/ready || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = var.common_tags
}

# ECS Service for Keycloak
resource "aws_ecs_service" "keycloak" {
  name            = "${var.name_prefix}-keycloak-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.keycloak.arn
  desired_count   = var.ecs_config.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.keycloak_target_group_arn
    container_name   = "keycloak"
    container_port   = 8080
  }

  depends_on = [var.alb_listener_arn]

  tags = var.common_tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "keycloak" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.keycloak.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy
resource "aws_appautoscaling_policy" "keycloak" {
  name               = "${var.name_prefix}-keycloak-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.keycloak.resource_id
  scalable_dimension = aws_appautoscaling_target.keycloak.scalable_dimension
  service_namespace  = aws_appautoscaling_target.keycloak.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}