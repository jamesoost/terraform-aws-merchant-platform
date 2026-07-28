variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "rds_identifier" {
  description = "RDS database identifier"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "monthly_budget" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "cloudtrail_object_lock_enabled" {
  description = "Enable object lock on the CloudTrail logs bucket"
  type        = bool
  default     = false
}

variable "cloudtrail_object_lock_retention_days" {
  description = "Default COMPLIANCE retention period for CloudTrail object lock"
  type        = number
  default     = 365
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
