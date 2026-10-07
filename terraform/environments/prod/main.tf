provider "aws" {
  region              = "eu-west-2"
  allowed_account_ids = ["732108543574"]

  default_tags {
    tags = {
      Project     = "finzla"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}
