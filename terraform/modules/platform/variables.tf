variable "name" {
  description = "Environment-specific platform name."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch application log retention."
  type        = number

  validation {
    condition     = contains([7, 30], var.log_retention_days)
    error_message = "Use 7 days for dev or 30 days for prod."
  }
}
