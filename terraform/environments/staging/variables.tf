variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC"
  type        = string

  validation {
    condition     = var.vpc_cidr == "10.1.0.0/16"
    error_message = "staging vpc_cidr must be the approved 10.1.0.0/16 CIDR block."
  }
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

variable "eks_public_endpoint_access" {
  description = "Whether to enable the public EKS API endpoint for this environment"
  type        = bool
  default     = false
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public endpoint when enabled"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.eks_public_access_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "Each EKS public access CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.eks_public_endpoint_access == false || length(var.eks_public_access_cidrs) > 0
    error_message = "eks_public_access_cidrs must include at least one approved CIDR when eks_public_endpoint_access is true."
  }

  validation {
    condition = alltrue([
      for cidr in var.eks_public_access_cidrs : cidr != "0.0.0.0/0"
    ])
    error_message = "Do not allow unrestricted 0.0.0.0/0 access to the EKS public endpoint."
  }
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
