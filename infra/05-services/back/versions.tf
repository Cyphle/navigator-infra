terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket  = "navigator-state"
    key     = "terraform/navigator-back.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}