output "state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "kms_key_id" {
  description = "KMS key ID for state bucket encryption"
  value       = aws_kms_key.state.id
}
