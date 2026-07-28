locals {
  common_tags = {
    Environment = var.environment
    Terraform   = true
    ManagedBy   = "Terraform"
  }
}

# Remote State Module (bootstrap only, usually applied separately)
# Uncomment to apply remote-state bootstrap:
# module "remote_state" {
#   source = "../../modules/remote-state"
#   tags   = local.common_tags
# }

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr                 = "10.0.0.0/16"
  az_list                  = ["eu-west-1a", "eu-west-1b"]
  public_subnet_cidrs      = ["10.0.0.0/24", "10.0.1.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]
  single_nat_gateway       = var.single_nat_gateway
  enable_flow_logs         = true
  flow_log_retention_days  = var.vpc_flow_log_retention_days
  environment              = var.environment
  tags                     = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  tags        = local.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.security_groups.alb_sg_id
  certificate_arn            = var.certificate_arn
  environment                = var.environment
  enable_deletion_protection = var.alb_enable_deletion_protection
  tags                       = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name              = "merchant-${var.environment}"
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.vpc.vpc_id
  private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  eks_node_sg_id            = module.security_groups.eks_node_sg_id
  node_instance_types       = var.node_instance_types
  desired_size              = var.desired_node_count
  min_size                  = var.min_node_count
  max_size                  = var.max_node_count
  enable_container_insights = true
  public_endpoint_access    = true
  public_access_cidrs       = var.eks_public_access_cidrs
  log_retention_days        = var.eks_log_retention_days
  tags                      = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  repository_names      = ["merchant-api"]
  image_expiration_days = 30
  scan_on_push          = true
  tags                  = local.common_tags
}

# Secrets Manager Module
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  environment = var.environment
  tags        = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment                = var.environment
  oidc_provider_arn          = module.eks.oidc_provider_arn
  oidc_provider_url          = module.eks.cluster_oidc_issuer_url
  secret_arn                 = module.secrets_manager.secret_arn
  kubernetes_namespace       = "default"
  kubernetes_service_account = "merchant-app"
  tags                       = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  db_name                     = "merchantdb"
  db_username                 = "postgres"
  instance_class              = var.rds_instance_class
  allocated_storage           = var.rds_allocated_storage
  private_db_subnet_ids       = module.vpc.private_db_subnet_ids
  rds_sg_id                   = module.security_groups.rds_sg_id
  multi_az                    = var.rds_multi_az
  deletion_protection         = var.rds_deletion_protection
  backup_retention_period     = 7
  enable_performance_insights = var.rds_performance_insights
  environment                 = var.environment
  tags                        = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# Observability Module
module "observability" {
  source = "../../modules/observability"

  cluster_name                          = module.eks.cluster_id
  alarm_email                           = var.alarm_email
  rds_identifier                        = module.rds.db_identifier
  alb_arn_suffix                        = split(":", module.alb.alb_arn)[5]
  monthly_budget                        = var.monthly_budget
  enable_cloudtrail                     = var.environment == "prod"
  cloudtrail_object_lock_enabled        = var.cloudtrail_object_lock_enabled
  cloudtrail_object_lock_retention_days = var.cloudtrail_object_lock_retention_days
  environment                           = var.environment
  tags                                  = local.common_tags

  depends_on = [module.eks, module.rds, module.alb]
}
