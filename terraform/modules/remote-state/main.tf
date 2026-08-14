# Get current AWS account ID
data "aws_caller_identity" "current" {}

# KMS key for state bucket encryption
resource "aws_kms_key" "state" {
  description             = "KMS key for Terraform state bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.state.key_id
}

# S3 bucket for Terraform remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket              = "terraform-state-${data.aws_caller_identity.current.account_id}"
  object_lock_enabled = false

  tags = merge(
    var.tags,
    { Name = "terraform-state" }
  )

  lifecycle {
    prevent_destroy = true
  }
}
# Enable versioning on state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled" # Set to "Enabled" with root credentials
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}
