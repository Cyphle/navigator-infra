# Quarkus Backend Service Configuration

# ECS Task Definition for Backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_config.cpu
  memory                   = var.ecs_config.memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${var.backend_repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "QUARKUS_PROFILE"
          value = "prod"
        },
        {
          name  = "QUARKUS_HTTP_PORT"
          value = "8080"
        },
        {
          name  = "QUARKUS_HTTP_HOST"
          value = "0.0.0.0"
        }
      ]

      secrets = [
        {
          name      = "QUARKUS_DATASOURCE_JDBC_URL"
          valueFrom = "${var.db_credentials_secret_arn}:jdbc_url::"
        },
        {
          name      = "QUARKUS_DATASOURCE_USERNAME"
          valueFrom = "${var.db_credentials_secret_arn}:username::"
        },
        {
          name      = "QUARKUS_DATASOURCE_PASSWORD"
          valueFrom = "${var.db_credentials_secret_arn}:password::"
        },
        {
          name      = "QUARKUS_OIDC_AUTH_SERVER_URL"
          valueFrom = "${var.keycloak_credentials_secret_arn}:auth_server_url::"
        },
        {
          name      = "QUARKUS_OIDC_CLIENT_ID"
          valueFrom = "${var.keycloak_credentials_secret_arn}:client_id::"
        },
        {
          name      = "QUARKUS_OIDC_CREDENTIALS_SECRET"
          valueFrom = "${var.keycloak_credentials_secret_arn}:client_secret::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.backend_log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/q/health || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.common_tags
}

# ECS Service for Backend
resource "aws_ecs_service" "backend" {
  name            = "${var.name_prefix}-backend-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.ecs_config.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [var.alb_listener_arn]

  tags = var.common_tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy
resource "aws_appautoscaling_policy" "backend" {
  name               = "${var.name_prefix}-backend-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}