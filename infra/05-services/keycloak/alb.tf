resource "aws_alb_target_group" "keycloak" {
  name                 = "${var.project_name}-keycloak-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.core.id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.keycloak_health_check_path
    port                = var.keycloak_port
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_alb_listener_rule" "keycloak" {
  count = length(var.domain_names.auth)

  listener_arn = data.aws_alb_listener.https.arn
  priority     = var.keycloak_rule_priority + count.index

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.keycloak.arn
  }

  condition {
    host_header {
      values = [var.domain_names.keycloak[count.index]]
    }
  }
}
