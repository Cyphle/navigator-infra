
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "navigator-state"
    key    = "terraform/vpc.tfstate"
    region = "eu-west-3"
  }
}