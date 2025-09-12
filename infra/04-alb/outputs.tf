# Outputs for ALB Module
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_alb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_alb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_alb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_alb.main.zone_id
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "hosted_zone_id" {
  description = "ID of the .fr hosted zone"
  value       = aws_route53_zone.fr.zone_id
}

output "hosted_zone_com_id" {
  description = "ID of the .com hosted zone"
  value       = aws_route53_zone.com.zone_id
}