variable "environment" {
  description = "Environment name"
  type        = string
}

variable "username" {
  description = "Username to store in the secret"
  type        = string
  default     = "merchant_app"
}

variable "password" {
  description = "Password to store in the secret"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "generated_password_length" {
  description = "Length for generated password when password is not provided"
  type        = number
  default     = 32
}

variable "generated_password_special" {
  description = "Whether generated password should include special characters"
  type        = bool
  default     = true
}

variable "recovery_window_in_days" {
  description = "Recovery window for the secret"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}
