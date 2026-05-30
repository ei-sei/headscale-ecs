output "vpc_id" {
  value = module.network.vpc_id
}

output "ecr_repository_url" {
  description = "The URI of the ECR repository."
  value       = aws_ecr_repository.ecr_repository.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository."
  value       = aws_ecr_repository.ecr_repository.arn
}