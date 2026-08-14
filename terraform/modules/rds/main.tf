terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/merchant-${var.environment}-rds-encryption"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "merchant-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    var.tags,
    { Name = "merchant-${var.environment}-db-subnet-group" }
  )
}

# RDS Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name   = "merchant-${var.environment}-postgres-params"
  family = "postgres17"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries > 1 second
  }

  tags = var.tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  allocated_storage                   = var.allocated_storage
  storage_type                        = "gp3"
  engine                              = "postgres"
  engine_version                      = "17.1"
  instance_class                      = var.instance_class
  identifier                          = "merchant-${var.environment}-db"
  db_name                             = var.db_name
  username                            = var.db_username
  manage_master_user_password         = true
  parameter_group_name                = aws_db_parameter_group.postgres.name
  db_subnet_group_name                = aws_db_subnet_group.main.name
  vpc_security_group_ids              = [var.rds_sg_id]
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  deletion_protection                 = var.deletion_protection
  backup_retention_period             = var.backup_retention_period
  backup_window                       = "03:00-04:00"
  maintenance_window                  = "mon:04:00-mon:05:00"
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.rds.arn
  iam_database_authentication_enabled = true
  performance_insights_enabled        = var.enable_performance_insights
  performance_insights_kms_key_id     = var.enable_performance_insights ? aws_kms_key.rds.arn : null
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "merchant-${var.environment}-db-final-snapshot"
  copy_tags_to_snapshot               = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    { Name = "merchant-${var.environment}-db" }
  )
}
