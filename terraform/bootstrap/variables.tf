variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "eu-west-2"
}

variable "aws_account_id" {
  description = "Expected AWS account."
  type        = string
  default     = "732108543574"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must contain 12 digits."
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 state bucket name."
  type        = string
  default     = "finzla-tfstate-732108543574-eu-west-2"
}
