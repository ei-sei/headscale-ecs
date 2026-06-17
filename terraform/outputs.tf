output "vpc_id" {
  value = module.network.vpc_id
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate."
  value       = module.acm.certificate_arn
}

output "domain_validation_options" {
  value = module.acm.domain_validation_options
}

output "certificate_status" {
  value = module.acm.certificate_status
}

output "validated_certificate" {
  description = "The validated certificate"
  value       = module.acm.validated_certificate
}

output "nlb_dns_name" {
  value = module.nlb.nlb_dns_name
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}
