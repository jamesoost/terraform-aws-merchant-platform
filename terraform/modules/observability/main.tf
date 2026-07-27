# SNS Topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "merchant-${var.environment}-platform-alarms"

  tags = merge(
    var.tags,
    { Name = "merchant-alarms" }
  )
}

resource "aws_sns_topic_subscription" "alarms" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = 7

  tags = merge(
    var.tags,
    { Name = "application-logs" }
  )
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.rds_identifier}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization is greater than 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

# RDS Free Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.rds_identifier}-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10737418240" # 10 GB in bytes
  alarm_description   = "RDS free storage is less than 10GB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

# ALB 5xx Error Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "merchant-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "ALB has more than 1 target 5xx error in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# ALB Target Unhealthy Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "merchant-${var.environment}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "ALB has unhealthy targets"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket              = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  object_lock_enabled = var.cloudtrail_object_lock_enabled

  tags = merge(
    var.tags,
    { Name = "cloudtrail-logs" }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Block public access to CloudTrail logs
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "merchant-${var.environment}-platform-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_logs]

  tags = merge(
    var.tags,
    { Name = "merchant-${var.environment}-platform-trail" }
  )
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail_logs" {
  count  = var.cloudtrail_object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.cloudtrail_object_lock_retention_days
    }
  }
}

# AWS Budgets for cost management
resource "aws_budgets_budget" "monthly" {
  name              = "merchant-platform-monthly"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  limit_unit        = "USD"
  limit_amount      = tostring(var.monthly_budget)
  time_period_start = "2026-01-01_00:00"
  time_period_end   = "2087-12-31_23:59"

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "FORECASTED"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.alarms.arn]
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
