locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  service_urls = [
    "app.one-navigator.fr",
    "app.one-navigator.com"
  ]
}