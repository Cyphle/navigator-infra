# Route 53 DNS Configuration

# Hosted Zone
resource "aws_route53_zone" "main" {
  name = "one-navigator.fr"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-hosted-zone"
  })
}

# Hosted Zone for .com domain
resource "aws_route53_zone" "com" {
  name = "one-navigator.com"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-hosted-zone-com"
  })
}

# SSL Certificate (using AWS Certificate Manager)
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_names.frontend[0]
  subject_alternative_names = concat(
    slice(var.domain_names.frontend, 1, length(var.domain_names.frontend)),
    var.domain_names.auth
  )
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

# Certificate validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# DNS Records for Frontend
resource "aws_route53_record" "frontend_fr" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.one-navigator.fr"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "frontend_com" {
  zone_id = aws_route53_zone.com.zone_id
  name    = "app.one-navigator.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# DNS Records for Keycloak
resource "aws_route53_record" "keycloak_fr" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "auth.one-navigator.fr"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "keycloak_com" {
  zone_id = aws_route53_zone.com.zone_id
  name    = "auth.one-navigator.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}