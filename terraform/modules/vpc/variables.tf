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