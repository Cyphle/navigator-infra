provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = merge(local.tags, aws_servicecatalogappregistry_application.this.application_tag)
  }
}

provider "aws" {
  region = "eu-west-3"
  alias  = "application"
}

provider "github" {
  owner = var.github_organization
}