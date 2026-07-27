output "secret_arn" {
  description = "ARN of the application secret"
  value       = aws_secretsmanager_secret.app.arn
}

output "secret_id" {
  description = "ID of the application secret"
  value       = aws_secretsmanager_secret.app.id
}
