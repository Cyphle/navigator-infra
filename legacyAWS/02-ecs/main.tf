# Cluster ECS
resource "aws_ecs_cluster" "navigator" {
  name = "navigator-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "navigator-ecs-cluster"
    Environment = "production"
    Project     = "navigator"
  }
}

# IAM Role pour l'exécution ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "navigator-ecs-execution-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role pour les tâches ECS
resource "aws_iam_role" "ecs_task_role" {
  name = "navigator-ecs-task-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Task Definition pour l'application
resource "aws_ecs_task_definition" "navigator_front" {
  family                   = "navigator-front"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "navigator-front"
      image = "rg.fr-par.scw.cloud/navigator/navigator-front:latest"
      
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.navigator_front.name
          awslogs-region        = "eu-west-3"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
  ])

  tags = {
    Name        = "navigator-front-task-definition"
    Environment = "production"
    Project     = "navigator"
  }
}

# Service ECS
resource "aws_ecs_service" "navigator_front" {
  name            = "navigator-front-service"
  cluster         = aws_ecs_cluster.navigator.id
  task_definition = aws_ecs_task_definition.navigator_front.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.navigator_front.arn
    container_name   = "navigator-front"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.navigator_front]

  tags = {
    Name        = "navigator-front-service"
    Environment = "production"
    Project     = "navigator"
  }
}

# Application Load Balancer
resource "aws_lb" "navigator_front" {
  name               = "navigator-front-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "navigator-front-alb"
    Environment = "production"
    Project     = "navigator"
  }
}

# Target Group
resource "aws_lb_target_group" "navigator_front" {
  name        = "navigator-front-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "navigator-front-target-group"
    Environment = "production"
    Project     = "navigator"
  }
}

# Listener ALB
resource "aws_lb_listener" "navigator_front" {
  load_balancer_arn = aws_lb.navigator_front.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.navigator_front.arn
  }
}

# Security Group pour ALB
resource "aws_security_group" "alb" {
  name_prefix = "navigator-front-alb-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "navigator-front-alb-sg"
    Environment = "production"
    Project     = "navigator"
  }
}

# Security Group pour ECS Service
resource "aws_security_group" "ecs_service" {
  name_prefix = "navigator-front-ecs-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "navigator-front-ecs-sg"
    Environment = "production"
    Project     = "navigator"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "navigator_front" {
  name              = "/ecs/navigator-front"
  retention_in_days = 7

  tags = {
    Name        = "navigator-front-logs"
    Environment = "production"
    Project     = "navigator"
  }
}
