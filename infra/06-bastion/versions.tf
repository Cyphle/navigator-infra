terraform {
  required_version = ">= 1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "navigator-state"
    key     = "terraform/bastion.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}
