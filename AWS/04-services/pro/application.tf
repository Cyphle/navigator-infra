resource "aws_servicecatalogappregistry_application" "this" {
  provider    = aws.application
  name        = "pro"
  description = "pro application"
}
