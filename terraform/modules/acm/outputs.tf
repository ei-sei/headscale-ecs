output "certificate_arn" {
  description = "The ARN of the ACM certificate."
  value       = aws_acm_certificate_validation.validated_certificate.certificate_arn
}

output "domain_validation_options" {
  value = aws_acm_certificate.cert.domain_validation_options
}

output "certificate_status" {
  value = aws_acm_certificate.cert.status
}

output "validated_certificate" {
  description = "The validated certificate"
  value       = aws_acm_certificate_validation.validated_certificate
}
