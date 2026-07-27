output "app_irsa_role_arn" {
  description = "ARN of the application IRSA role"
  value       = aws_iam_role.app_irsa.arn
}

output "app_irsa_role_name" {
  description = "Name of the application IRSA role"
  value       = aws_iam_role.app_irsa.name
}
