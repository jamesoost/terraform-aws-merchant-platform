# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway elastic IP addresses"
  value       = module.vpc.nat_gateway_ips
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID (for Route 53 alias)"
  value       = module.alb.alb_zone_id
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_identifier" {
  description = "RDS database identifier"
  value       = module.rds.db_identifier
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

output "rds_database_username" {
  description = "RDS database master username"
  value       = module.rds.db_username
}

output "rds_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS password"
  value       = module.rds.db_secret_arn
}

# Observability Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.observability.sns_topic_arn
}

output "cloudtrail_logs_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.observability.cloudtrail_logs_bucket
}
