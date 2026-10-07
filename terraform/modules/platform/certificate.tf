variable "domain_name" {
  description = "Application hostname controlled by the operator."
  type        = string
}

resource "aws_acm_certificate" "app" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

output "certificate_arn" {
  value = aws_acm_certificate.app.arn
}

output "certificate_dns_records" {
  value = [
    for record in aws_acm_certificate.app.domain_validation_options : {
      name  = record.resource_record_name
      type  = record.resource_record_type
      value = record.resource_record_value
    }
  ]
}
