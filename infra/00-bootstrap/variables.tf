variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "navigator-state"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}