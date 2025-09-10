resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keeps only last ${var.ecr_images_retention_in_days} images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${var.ecr_images_retention_in_days}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
