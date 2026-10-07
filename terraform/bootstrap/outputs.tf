output "state_bucket_name" {
  description = "S3 bucket for Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "State bucket ARN for scoped IAM policies."
  value       = aws_s3_bucket.state.arn
}

output "aws_region" {
  description = "State bucket region."
  value       = var.aws_region
}
