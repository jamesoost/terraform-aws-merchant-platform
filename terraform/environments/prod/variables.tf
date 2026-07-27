variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
}

# VPC variables
variable "single_nat_gateway" {
  description = "Use single NAT gateway"
  type        = bool
}

variable "vpc_flow_log_retention_days" {
  description = "Retention period for VPC flow logs"
  type        = number
}

# EKS variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
}

variable "desired_node_count" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "min_node_count" {
  description = "Minimum number of EKS nodes"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public endpoint"
  type        = list(string)
}

variable "eks_log_retention_days" {
  description = "Retention period for EKS control plane logs"
  type        = number
}

variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
}

# RDS variables
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
}

variable "rds_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
}

# Observability variables
variable "monthly_budget" {
  description = "Monthly budget limit"
  type        = number
}

variable "cloudtrail_object_lock_enabled" {
  description = "Enable object lock for CloudTrail log bucket"
  type        = bool
}

variable "cloudtrail_object_lock_retention_days" {
  description = "Object lock COMPLIANCE retention days for CloudTrail logs"
  type        = number
}
