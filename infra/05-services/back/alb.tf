resource "aws_alb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id               = data.aws_vpc.core.id
  target_type = "ip"
  deregistration_delay = 60

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.backend_health_check_path
    port                = var.backend_port
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "backend" {
  count = length(var.domain_names.backend)

  listener_arn = data.aws_alb_listener.https.arn
  priority     = var.backend_rule_priority + count.index

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend.arn
  }

  condition {
    host_header {
      values = [var.domain_names.backend[count.index]]
    }
  }
}
