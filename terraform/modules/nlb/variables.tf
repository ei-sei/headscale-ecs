variable "environment" {
  description = "The environment to deploy resources in (e.g., dev, staging, prod)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the NLB will be deployed."
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate to use for the NLB."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the NLB will be deployed."
  type        = list(string)
}
