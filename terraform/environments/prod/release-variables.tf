variable "image_digest" {
  description = "Digest of an image already pushed to this environment's ECR repository."
  type        = string
}

variable "app_version" {
  description = "Git SHA identifying that image."
  type        = string
}
