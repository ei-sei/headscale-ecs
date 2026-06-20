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

variable "availability_zones" {
  description = "List of availability zones to deploy resources in."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the ACM certificate."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID to use for validating the ACM"
  type        = string
}

variable "image_tag" {
  description = "The image tag to deploy."
  type        = string
  default     = "latest"
}
