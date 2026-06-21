variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "The environment to deploy resources in (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "headscale"
}

variable "state_bucket_name" {
  description = "Globally unique name for the S3 bucket that stores Terraform remote state."
  type        = string
}
