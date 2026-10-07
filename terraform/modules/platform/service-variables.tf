variable "vpc_id" {
  description = "VPC containing the application."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for Fargate tasks."
  type        = list(string)
}

variable "image_digest" {
  description = "Existing application image digest in this environment's ECR repository."
  type        = string

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.image_digest))
    error_message = "Provide an existing sha256 image digest."
  }
}

variable "app_version" {
  description = "Git SHA corresponding to the deployed image."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.app_version))
    error_message = "Application version must be a full Git SHA."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "desired_count" {
  type = number

  validation {
    condition     = contains([1, 2], var.desired_count)
    error_message = "Use one task for dev or two for prod."
  }
}
