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

variable "cluster_name" {
  type        = string
  default     = "banana-cluster"
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  default     = "1.30"
  description = "Kubernetes version for the cluster"
}

variable "node_group_name" {
  type        = string
  default     = "banana-node-group"
  description = "Name of the EKS node group"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Instance types for the node group"
}

variable "desired_size" {
  type        = number
  default     = 1
  description = "Desired number of nodes"
}

variable "max_size" {
  type        = number
  default     = 2
  description = "Maximum number of nodes"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of nodes"
}
