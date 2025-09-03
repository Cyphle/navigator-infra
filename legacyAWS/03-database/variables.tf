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

variable "db_user" {
  type        = string
  sensitive   = true
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

variable "redis_user" {
  type        = string
  sensitive   = true
  description = "Redis username"
}

variable "redis_password" {
  type        = string
  sensitive   = true
  description = "Redis password"
}
