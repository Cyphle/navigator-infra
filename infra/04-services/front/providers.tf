provider "aws" {
  region = "eu-west-3"
  
  default_tags {
    tags = merge(local.common_tags)
  }
}

provider "github" {
  owner = "Cyphle"
}