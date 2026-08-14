terraform {
  backend "s3" {
    # Replace <ACCOUNT_ID> with your 12-digit AWS account ID before terraform init.
    bucket       = "terraform-state-<ACCOUNT_ID>"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
