locals {
  tags = {
    Environment = var.environment
    Application = var.application
    Product     = var.product
    Origin      = "terraform"
  }

  service_url = "${var.backend_url_name}.${var.domain_name_lite}"
}
