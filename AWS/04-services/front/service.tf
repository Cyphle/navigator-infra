resource "aws_iam_role" "frontend_taskexec" {
  name = "${var.project_name}-frontend-ecs-taskexec-${var.region}-${var.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "secret_access" {
  name = "${var.project_name}-secret-${var.region}-${var.environment}"
  role = aws_iam_role.frontend_taskexec.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.ecs_service_app_config.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_amazonecstaskexecutionrolepolicy" {
  role = aws_iam_role.frontend_taskexec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "frontend_task" {
  name = "${var.project_name}-frontend-ecs-task-${var.region}-${var.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ssmmessages_access" {
  name = "${var.project_name}-ecs-ssmmessages-${var.region}-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "frontend_access" {
  name = "${var.project_name}-app-access-${var.region}-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "frontend_task" {
  role_name = aws_iam_role.frontend_task.name
  policy_arns = [
    aws_iam_policy.ssmmessages_access.arn,
    aws_iam_policy.frontend_access.arn
  ]
}

resource "aws_ecs_task_definition" "frontend" {
  family = "${var.project_name}-frontend-${var.environment}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.fargate_cpu
  memory = var.fargate_memory
  task_role_arn = aws_iam_role.frontend_task.arn
  execution_role_arn = aws_iam_role.frontend_taskexec.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${aws_ecr_repository.frontend.repository_url}",
    "memory": ${var.fargate_memory},
    "name": "${var.frontend_container_name}",
    "linuxParameters":
      {
        "initProcessEnabled": true
      },
    "portMappings": [
      {
        "containerPort": ${var.frontend_port},
        "hostPort": ${var.frontend_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend.name}",
        "awslogs-region": "${var.region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/fargate/service/${var.project_name}-frontend-${var.environment}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_security_group" "frontend_service" {
  name_prefix = "${var.project_name}-frontend-service-${var.environment}-"
  description = "frontend container SecurityGroup"
  vpc_id      = data.aws_vpc.core.id
  tags = {
    Name = "${var.project_name}-frontend-service-${var.environment}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

# ECS Service
resource "aws_ecs_service" "frontend" {
  name                              = "frontend"
  cluster                           = aws_ecs_cluster.frontend.id
  task_definition                   = aws_ecs_task_definition.frontend.arn
  desired_count                     = var.frontend_desired_tasks_count
  launch_type                       = "FARGATE"
  propagate_tags                    = "SERVICE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 600

  network_configuration {
    security_groups = [aws_security_group.frontend_service.id]
    subnets         = data.aws_subnets.private.ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.frontend.id
    container_name   = var.frontend_container_name
    container_port   = var.frontend_port
  }

  lifecycle {
    ignore_changes = [desired_count, load_balancer, task_definition, capacity_provider_strategy]
  }

  depends_on = [data.aws_alb_listener.https]
}

# ALB



# Service access
resource "aws_security_group_rule" "frontend_https_output_access" {
  description       = "Service frontend https egress access"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.frontend_service.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_from_alb_access" {
  description              = "Allow traffic from ALB to frontend"
  type                     = "ingress"
  from_port                = var.frontend_port
  to_port                  = var.frontend_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_service.id
  source_security_group_id = data.aws_security_group.apps_alb.id
}

resource "aws_security_group_rule" "alb_to_app_access" {
  description              = "Allow traffic from ALB to frontend"
  type                     = "egress"
  from_port                = var.frontend_port
  to_port                  = var.frontend_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_service.id
  security_group_id        = data.aws_security_group.apps_alb.id
}

# DNS Record is in Route53
# resource "aws_route53_record" "alb_api" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = local.service_url
#   type    = "A"
#   alias {
#     name                   = data.aws_alb.apps.dns_name
#     zone_id                = data.aws_alb.apps.zone_id
#     evaluate_target_health = false
#   }
# }

# Secret manager
resource "aws_secretsmanager_secret" "ecs_service_app_config" {
  name        = "${var.project_name}-frontend-ecs-service-app-config-${var.environment}"
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
