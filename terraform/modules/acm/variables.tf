variable "environment" {
  description = "The environment to deploy resources in (e.g., dev, staging, prod)."
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
