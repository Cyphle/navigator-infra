variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret key"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS region"
}

variable "repository_name" {
  type        = string
  default     = "banana"
  description = "Name of the ECR repository"
}
