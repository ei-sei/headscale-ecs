resource "aws_ecr_repository" "ecr_repository" {
  name                 = "${var.name_prefix}-ecr-repository"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    name        = "${var.name_prefix}-ecr-repository"
    environment = var.environment
  }
}
