variable "environment" {
  description = "Environment name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for the EKS cluster"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
  default     = "merchant-app"
}

variable "secret_arn" {
  description = "ARN of the secret this role should be able to read"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the IAM resources"
  type        = map(string)
  default     = {}
}
