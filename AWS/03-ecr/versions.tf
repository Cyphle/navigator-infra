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
    key     = "terraform/navigator-database.tfstate"
    region  = "us-east-1"  # Change this to your preferred region
    encrypt = true
  }
}
