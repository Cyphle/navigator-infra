############################
# Route 53 & ACM, factorisé
############################

# Hosted Zone (.fr)
resource "aws_route53_zone" "fr" {
  name = "one-navigator.fr"
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-hosted-zone-fr" })
}

# Hosted Zone (.com)
resource "aws_route53_zone" "com" {
  name = "one-navigator.com"
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-hosted-zone-com" })
}

############################
# Certificat ACM multi-domaines
############################

# On met comme "domain_name" le 1er frontend, et en SANs le reste des frontends + tous les auth + tous les back
resource "aws_acm_certificate" "main" {
  domain_name = var.domain_names.frontend[0]

  subject_alternative_names = concat(
    slice(var.domain_names.frontend, 1, length(var.domain_names.frontend)),
    var.domain_names.auth,
    var.domain_names.back
  )

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

# Map pratique des options de validation par domaine
locals {
  dvo_by_domain = {
    for dvo in aws_acm_certificate.main.domain_validation_options :
    dvo.domain_name => dvo
  }

  # Toutes les FQDN à publier (app/auth/api)
  all_fqdns = distinct(concat(
    var.domain_names.frontend,
    var.domain_names.auth,
    var.domain_names.back
  ))
}

# CNAME de validation pour les domaines en .fr
resource "aws_route53_record" "cert_validation_fr" {
  for_each = {
    for k, v in local.dvo_by_domain : k => v if endswith(k, ".fr")
  }

  zone_id         = aws_route53_zone.fr.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# CNAME de validation pour les domaines en .com
resource "aws_route53_record" "cert_validation_com" {
  for_each = {
    for k, v in local.dvo_by_domain : k => v if endswith(k, ".com")
  }

  zone_id         = aws_route53_zone.com.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# Validation du certificat ACM
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = concat(
    [for r in aws_route53_record.cert_validation_fr  : r.fqdn],
    [for r in aws_route53_record.cert_validation_com : r.fqdn]
  )

  timeouts { create = "5m" }
}

############################
# Enregistrements DNS factorisés (app/auth/api)
# -> Un seul ALB pour tous les noms
############################

# On construit une map domaine -> zone_id selon le suffixe
locals {
  records_by_domain = {
    for d in local.all_fqdns :
    d => {
      zone_id = endswith(d, ".fr") ? aws_route53_zone.fr.zone_id : aws_route53_zone.com.zone_id
      name    = d
    }
  }
}

# Crée un enregistrement A alias vers l’ALB pour chaque FQDN
resource "aws_route53_record" "aliases" {
  for_each = local.records_by_domain

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = var.alb_dns_name   # ex: my-alb-123456.eu-west-1.elb.amazonaws.com
    zone_id                = var.alb_zone_id    # zone id de l'ALB
    evaluate_target_health = true
  }
}