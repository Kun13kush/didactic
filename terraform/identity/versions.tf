terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket              = "finzla-tfstate-732108543574-eu-west-2"
    key                 = "identity/terraform.tfstate"
    region              = "eu-west-2"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["732108543574"]
  }
}

provider "aws" {
  region              = "eu-west-2"
  allowed_account_ids = ["732108543574"]

  default_tags {
    tags = {
      Project   = "finzla"
      ManagedBy = "Terraform"
      Purpose   = "github-deployment"
    }
  }
}
