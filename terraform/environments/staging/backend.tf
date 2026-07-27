terraform {
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "staging/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
