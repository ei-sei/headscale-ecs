terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

// ACM Certificate for the domain
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name        = var.domain_name
    environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Cloudflare DNS record for ACM validation
resource "cloudflare_dns_record" "dns_validation" {
  zone_id = var.cloudflare_zone_id
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  content = trimsuffix(tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value, ".")
  ttl     = 60
  proxied = false
}

# Validate the ACM certificate using the DNS record
resource "aws_acm_certificate_validation" "validated_certificate" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  ]
  depends_on = [cloudflare_dns_record.dns_validation]
}
