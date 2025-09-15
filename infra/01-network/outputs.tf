# Outputs for VPC Module
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# VPC Endpoints outputs
output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.logs.id
}

output "secretsmanager_endpoint_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}