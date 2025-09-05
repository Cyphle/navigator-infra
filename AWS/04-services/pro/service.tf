resource "aws_ecr_repository" "pro" {
  name                 = "${var.product}-${var.application}-${var.environment}"
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "pro" {
  repository = aws_ecr_repository.pro.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keeps only last ${var.ecr_images_retention_in_days} images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${var.ecr_images_retention_in_days} 
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "pro_taskexec" {
  name               = "${var.product}-${var.application}-ecs-taskexec-${var.region}-${var.environment}"
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
  name = "${var.product}-secret-${var.region}-${var.environment}"
  role = aws_iam_role.pro_taskexec.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          data.aws_secretsmanager_secret.applications_common.arn,
          data.aws_secretsmanager_secret.shared_db_pro_rw.arn,
          data.aws_secretsmanager_secret.datawarehouse-db-datawarehouse-rw.arn,
          aws_secretsmanager_secret.ecs_service_app_config.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pro_exec_amazonecstaskexecutionrolepolicy" {
  role       = aws_iam_role.pro_taskexec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "pro_task" {
  name               = "${var.product}-${var.application}-ecs-task-${var.region}-${var.environment}"
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
  name = "${var.product}-ecs-ssmmessages-${var.region}-${var.environment}"
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

resource "aws_iam_policy" "pro_access" {
  name = "${var.product}-app-access-${var.region}-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "sqsAccess"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = [
          data.aws_sqs_queue.grdf_api_collection.arn,
        ]
      },
      {
        Sid    = "s3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject*",
          "s3:GetObject*",
          "s3:DeleteObject*"
        ]
        Resource = [
          "${data.aws_s3_bucket.resources.arn}/*",
          "${data.aws_s3_bucket.raw_data.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "pro_task" {
  role_name = aws_iam_role.pro_task.name
  policy_arns = [
    aws_iam_policy.ssmmessages_access.arn,
    aws_iam_policy.pro_access.arn
  ]
}

resource "aws_ecs_task_definition" "pro" {
  family                   = "${var.product}-${var.application}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.pro_task.arn
  execution_role_arn       = aws_iam_role.pro_taskexec.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${aws_ecr_repository.pro.repository_url}",
    "memory": ${var.fargate_memory},
    "name": "${var.pro_container_name}",
    "linuxParameters":
      {
        "initProcessEnabled": true
      },
    "portMappings": [
      {
        "containerPort": ${var.pro_port},
        "hostPort": ${var.pro_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.pro.name}",
        "awslogs-region": "${data.aws_region.current.name}",
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

resource "aws_cloudwatch_log_group" "pro" {
  name              = "/fargate/service/${var.product}-${var.application}-${var.environment}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_security_group" "pro_service" {
  name_prefix = "${var.product}-${var.application}-service-${var.environment}-"
  description = "${var.application} container SecurityGroup"
  vpc_id      = data.aws_vpc.core.id
  tags = {
    Name = "${var.product}-${var.application}-service-${var.environment}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "pro" {
  name                              = var.application
  cluster                           = aws_ecs_cluster.pro.id
  task_definition                   = aws_ecs_task_definition.pro.arn
  desired_count                     = var.pro_desired_tasks_count
  launch_type                       = "FARGATE"
  propagate_tags                    = "SERVICE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 600

  network_configuration {
    security_groups = [aws_security_group.pro_service.id]
    subnets         = data.aws_subnets.private.ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.pro.id
    container_name   = var.pro_container_name
    container_port   = var.pro_port
  }

  lifecycle {
    ignore_changes = [desired_count, load_balancer, task_definition, capacity_provider_strategy]
  }

  depends_on = [data.aws_alb_listener.apps_443]
}

# The AWSServiceRoleForApplicationAutoScaling_ECSService role will be created automaticaly
resource "aws_appautoscaling_target" "pro" {
  min_capacity       = var.pro_min_capacity
  max_capacity       = var.pro_max_capacity
  resource_id        = "service/${aws_ecs_cluster.pro.name}/${aws_ecs_service.pro.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "pro_morning_up" {
  count              = var.pro_stop_non_business_hours ? 1 : 0
  name               = "start-weekday-9am"
  service_namespace  = aws_appautoscaling_target.pro.service_namespace
  resource_id        = aws_appautoscaling_target.pro.resource_id
  scalable_dimension = aws_appautoscaling_target.pro.scalable_dimension
  schedule           = var.pro_start_time
  timezone           = var.pro_timezone

  scalable_target_action {
    min_capacity = var.pro_min_capacity
    max_capacity = var.pro_max_capacity
  }
}

resource "aws_appautoscaling_scheduled_action" "pro_evening_down" {
  count              = var.pro_stop_non_business_hours ? 1 : 0
  name               = "stop-weekday-8pm"
  service_namespace  = aws_appautoscaling_target.pro.service_namespace
  resource_id        = aws_appautoscaling_target.pro.resource_id
  scalable_dimension = aws_appautoscaling_target.pro.scalable_dimension
  schedule           = var.pro_stop_time
  timezone           = var.pro_timezone

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

resource "aws_alb_target_group" "pro" {
  name                 = "${var.product}-${var.application}-${var.environment}"
  port                 = var.pro_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.core.id
  target_type          = "ip"
  deregistration_delay = 60
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = var.pro_health_check_path
    port                = var.pro_port
    matcher             = "200"
  }
}

resource "aws_lb_listener_rule" "pro" {
  listener_arn = data.aws_alb_listener.apps_443.arn
  priority     = var.pro_rule_priority

  action {
    target_group_arn = aws_alb_target_group.pro.arn
    type             = "forward"
  }
  condition {
    host_header {
      values = [local.service_url]
    }
  }
}

# Service access

resource "aws_security_group_rule" "pro_https_output_access" {
  description       = "Service ${var.application} https egress access"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.pro_service.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_from_alb_access" {
  description              = "Allow traffic from ALB to ${var.application}"
  type                     = "ingress"
  from_port                = var.pro_port
  to_port                  = var.pro_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.pro_service.id
  source_security_group_id = data.aws_security_group.apps_alb.id
}

resource "aws_security_group_rule" "alb_to_app_access" {
  description              = "Allow traffic from ALB to ${var.application}"
  type                     = "egress"
  from_port                = var.pro_port
  to_port                  = var.pro_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.pro_service.id
  security_group_id        = data.aws_security_group.apps_alb.id
}

resource "aws_route53_record" "alb_api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.service_url
  type    = "A"
  alias {
    name                   = data.aws_alb.apps.dns_name
    zone_id                = data.aws_alb.apps.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group_rule" "pro_db_output_access" {
  description       = "Service ${var.application} access to postgres DB"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.pro_service.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "pro_shared_db_access" {
  description              = "Service ${var.application} access"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.pro_service.id
  security_group_id        = data.aws_security_group.shared_postgresql_clients.id
}

resource "aws_security_group_rule" "pro_datawarehouse_db_access" {
  description              = "Service ${var.application} access"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.pro_service.id
  security_group_id        = data.aws_security_group.datawarehouse_postgresql_clients.id
}
