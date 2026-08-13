variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "IDs of private app subnets"
  type        = list(string)
}

variable "eks_node_sg_id" {
  description = "EKS Node Security Group ID"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

variable "public_endpoint_access" {
  description = "Enable public endpoint access. Keep this disabled unless an approved network is explicitly allowed."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public endpoint when public_endpoint_access is enabled."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.public_access_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Each EKS public endpoint CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.public_endpoint_access == false || length(var.public_access_cidrs) > 0
    error_message = "public_access_cidrs must contain at least one approved CIDR when public_endpoint_access is true."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_access_cidrs : cidr != "0.0.0.0/0"
    ])
    error_message = "Do not allow unrestricted 0.0.0.0/0 access to the EKS public endpoint. Restrict it to trusted networks only."
  }
}

variable "log_retention_days" {
  description = "Retention period for EKS control plane logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
