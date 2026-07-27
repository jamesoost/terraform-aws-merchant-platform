resource "random_password" "app" {
  count   = var.password == null ? 1 : 0
  length  = var.generated_password_length
  special = var.generated_password_special
}

locals {
  resolved_password = coalesce(var.password, try(random_password.app[0].result, null))
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.environment}/merchant/app"
  description             = "Application secrets for merchant platform"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.tags,
    { Name = "${var.environment}-merchant-app-secret" }
  )
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    username = var.username
    password = local.resolved_password
  })
}
