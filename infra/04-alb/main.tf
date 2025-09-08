# Application Load Balancer Configuration

# ALB
resource "aws_alb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = false

  tags = local.common_tags
}

# ALB Target Groups
# TODO ce sera dans les dossiers services
# resource "aws_alb_target_group" "backend" {
#   name        = "${var.project_name}-backend-tg"
#   port        = 8080
#   protocol    = "HTTP"
#   vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
#   target_type = "ip"
#
#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     interval            = 30
#     matcher             = "200"
#     path                = "/q/health"
#     port                = "traffic-port"
#     protocol            = "HTTP"
#     timeout             = 5
#     unhealthy_threshold = 2
#   }
#
#   tags = local.common_tags
# }
#
# resource "aws_alb_target_group" "keycloak" {
#   name        = "${var.project_name}-keycloak-tg"
#   port        = 8080
#   protocol    = "HTTP"
#   vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
#   target_type = "ip"
#
#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     interval            = 30
#     matcher             = "200"
#     path                = "/health/ready"
#     port                = "traffic-port"
#     protocol            = "HTTP"
#     timeout             = 5
#     unhealthy_threshold = 2
#   }
#
#   tags = local.common_tags
# }

# ALB Listeners
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.common_tags
}

# ALB Listener Rules
# TODO ce sera dans les dossiers services
# resource "aws_alb_listener_rule" "backend" {
#   count = length(var.domain_names.frontend)
#
#   listener_arn = aws_alb_listener.https.arn
#   priority     = 200 + count.index
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.backend.arn
#   }
#
#   condition {
#     host_header {
#       values = [var.domain_names.frontend[count.index]]
#     }
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }
#
# resource "aws_alb_listener_rule" "keycloak" {
#   count = length(var.domain_names.auth)
#
#   listener_arn = aws_alb_listener.https.arn
#   priority     = 300 + count.index
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.keycloak.arn
#   }
#
#   condition {
#     host_header {
#       values = [var.domain_names.auth[count.index]]
#     }
#   }
# }