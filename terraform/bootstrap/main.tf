data "aws_caller_identity" "current" {}

module "oidc" {
  source             = "./modules/oidc"
  aws_region         = var.aws_region
  name_prefix        = var.name_prefix
  ecr_repository_arn = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}"
  state_bucket_arn   = aws_s3_bucket.tfstate.arn
}

# Bucket that will hold the Terraform remote state for the main config.
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Bucket must outlive accidental `terraform destroy` runs against this root,
  # since it holds the state for everything else in the project.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    name        = "${var.name_prefix}-tfstate"
    environment = var.environment
  }
}

# Keeps prior state file versions, so a corrupted/bad state can be rolled back.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypts state at rest, since state files can contain sensitive values.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Blocks all public access to the bucket, at both config and enforcement level.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
