resource "aws_iam_role" "app_irsa" {
  name = "${var.environment}-merchant-app-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    { Name = "${var.environment}-merchant-app-irsa" }
  )
}

resource "aws_iam_role_policy" "app_secrets" {
  name = "${var.environment}-merchant-app-secrets"
  role = aws_iam_role.app_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_basic" {
  role       = aws_iam_role.app_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
