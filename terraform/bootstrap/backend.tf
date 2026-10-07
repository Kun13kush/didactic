terraform {
  backend "s3" {
    bucket              = "finzla-tfstate-732108543574-eu-west-2"
    key                 = "bootstrap/terraform.tfstate"
    region              = "eu-west-2"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["732108543574"]
  }
}
