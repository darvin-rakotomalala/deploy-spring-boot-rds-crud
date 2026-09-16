############################################
# CloudWatch Monitoring for the EC2 Application Tier
############################################

resource "aws_cloudwatch_log_group" "app_tier" {
  name              = "/aws/ec2/spring-boot-backend-app-tier"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-tier-logs"
  })
}

############################################
# Metric Filters: extract ERROR / WARN counts from application logs
############################################

resource "aws_cloudwatch_log_metric_filter" "app_error" {
  name           = "${var.naming_prefix}-app-error-count"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
  pattern        = "?ERROR ?Error ?error"

  metric_transformation {
    name          = "ApplicationErrorCount"
    namespace     = "${var.naming_prefix}/AppTier"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_warning" {
  name           = "${var.naming_prefix}-app-warning-count"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
  pattern        = "?WARN ?Warning ?warning"

  metric_transformation {
    name          = "ApplicationWarningCount"
    namespace     = "${var.naming_prefix}/AppTier"
    value         = "1"
    default_value = 0
  }
}

############################################
# CloudWatch Alarms - EC2 App Tier
############################################

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = { for idx, id in var.ec2_instance_ids : idx => id }

  alarm_name          = "${var.naming_prefix}-ec2-${each.key}-cpu-high"
  alarm_description   = "Alert when CPU exceeds 80% for 5 consecutive minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { InstanceId = each.value }

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-cpu-high-${each.key}"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed" {
  for_each = { for idx, id in var.ec2_instance_ids : idx => id }

  alarm_name          = "${var.naming_prefix}-ec2-${each.key}-status-check-failed"
  alarm_description   = "Alert when status checks fail"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "missing"

  dimensions = { InstanceId = each.value }

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-status-check-failed-${each.key}"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  for_each = { for idx, id in var.ec2_instance_ids : idx => id }

  alarm_name          = "${var.naming_prefix}-ec2-${each.key}-memory-high"
  alarm_description   = "Alert when memory usage exceeds 90%"
  namespace           = "${var.naming_prefix}/EC2"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { InstanceId = each.value }

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-memory-high-${each.key}"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  for_each = { for idx, id in var.ec2_instance_ids : idx => id }

  alarm_name          = "${var.naming_prefix}-ec2-${each.key}-disk-high"
  alarm_description   = "Alert when disk usage exceeds 85%"
  namespace           = "${var.naming_prefix}/EC2"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { InstanceId = each.value, path = "/" }

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-disk-high-${each.key}"
  })
}

resource "aws_cloudwatch_metric_alarm" "app_error_count_high" {
  alarm_name          = "${var.naming_prefix}-app-error-count-high"
  alarm_description   = "This metric monitors application error logs"
  namespace           = aws_cloudwatch_log_metric_filter.app_error.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.app_error.metric_transformation[0].name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-error-count-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "app_warning_count_high" {
  alarm_name          = "${var.naming_prefix}-app-warning-count-high"
  alarm_description   = "This metric monitors application warning logs"
  namespace           = aws_cloudwatch_log_metric_filter.app_warning.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.app_warning.metric_transformation[0].name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 25
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_alerts_topic_arn]
  ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-warning-count-high"
  })
}

############################################
# CloudWatch Dashboard - EC2 App Tier
############################################

resource "aws_cloudwatch_dashboard" "app_tier" {
  dashboard_name = "${var.naming_prefix}-app-tier-dashboard"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        {
          type = "metric", x = 0, y = 0, width = 8, height = 6,
          properties = {
            title   = "EC2 CPU Utilization"
            region  = var.primary_region
            metrics = [for id in var.ec2_instance_ids : ["AWS/EC2", "CPUUtilization", "InstanceId", id, { stat = "Average", period = 60 }]]
          }
        },
        {
          type = "metric", x = 8, y = 0, width = 8, height = 6,
          properties = {
            title  = "EC2 Memory & Disk Usage"
            region = var.primary_region
            metrics = concat(
              [for id in var.ec2_instance_ids : ["${var.naming_prefix}/EC2", "mem_used_percent", "InstanceId", id, { stat = "Average", period = 60, label = "mem-${id}" }]],
              [for id in var.ec2_instance_ids : ["${var.naming_prefix}/EC2", "disk_used_percent", "InstanceId", id, "path", "/", { stat = "Average", period = 60, label = "disk-${id}" }]]
            )
          }
        },
        {
          type = "metric", x = 16, y = 0, width = 8, height = 6,
          properties = {
            title   = "Network Throughput & Connections"
            region  = var.primary_region
            metrics = [for id in var.ec2_instance_ids : ["AWS/EC2", "NetworkIn", "InstanceId", id, { stat = "Sum", period = 60 }]]
          }
        },
        {
          type = "metric", x = 0, y = 6, width = 8, height = 6,
          properties = {
            title  = "Application Log Metrics (ERROR / WARN)"
            region = var.primary_region
            metrics = [
              ["${var.naming_prefix}/AppTier", "ApplicationErrorCount", { stat = "Sum", period = 300, label = "ERROR" }],
              ["${var.naming_prefix}/AppTier", "ApplicationWarningCount", { stat = "Sum", period = 300, label = "WARN" }],
            ]
          }
        },
        {
          type = "log", x = 8, y = 6, width = 16, height = 6,
          properties = {
            title  = "Recent Error Logs"
            region = var.primary_region
            view   = "table"
            query  = "SOURCE '${aws_cloudwatch_log_group.app_tier.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          }
        },
        {
          type = "metric", x = 0, y = 12, width = 8, height = 6,
          properties = {
            title   = "Disk I/O"
            region  = var.primary_region
            metrics = [for id in var.ec2_instance_ids : ["AWS/EC2", "DiskReadBytes", "InstanceId", id, { stat = "Sum", period = 60 }]]
          }
        },
        {
          type = "metric", x = 8, y = 12, width = 8, height = 6,
          properties = {
            title   = "Status Check Failures"
            region  = var.primary_region
            metrics = [for id in var.ec2_instance_ids : ["AWS/EC2", "StatusCheckFailed", "InstanceId", id, { stat = "Maximum", period = 60 }]]
          }
        },
        {
          type = "metric", x = 16, y = 12, width = 8, height = 6,
          properties = {
            title   = "Estimated Daily Spend - EC2 (Billing metrics must be enabled in Account Settings)"
            region  = "us-east-1"
            metrics = [["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD", { stat = "Maximum", period = 86400 }]]
          }
        }
      ]
    )
  })
}
