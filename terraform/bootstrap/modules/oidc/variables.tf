variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "ecr_repository_arn" {
  description = "The ARN of the ECR repository."
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket holding Terraform remote state."
  type        = string
}