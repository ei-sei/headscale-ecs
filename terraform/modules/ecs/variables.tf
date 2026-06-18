variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "environment" {
  description = "The environment to deploy resources in (e.g., dev, staging, prod)."
  type        = string

}

variable "name_prefix" {
  description = "A prefix for naming resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy ECS resources in."
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository."
  type        = string
}

variable "private_subnet_id" {
  description = "List of private subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "tg_controlplane_arn" {
  description = "ARN of the NLB target group for the control plane."
  type        = string
}

variable "tg_wireguard_arn" {
  description = "ARN of the NLB target group for WireGuard."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application."
  type        = string
}