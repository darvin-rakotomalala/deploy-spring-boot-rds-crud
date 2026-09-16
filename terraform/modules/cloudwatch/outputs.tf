############################################
# CloudWatch Monitoring APP TIER - OUTPUTS
############################################

output "app_tier_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for the Spring Boot application tier"
  value       = aws_cloudwatch_log_group.app_tier.arn
}

output "app_tier_log_group_name" {
  description = "Name of the CloudWatch Log Group for the Spring Boot application tier"
  value       = aws_cloudwatch_log_group.app_tier.name
}

output "app_tier_dashboard_name" {
  description = "Name of the EC2 application tier CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.app_tier.dashboard_name
}

output "app_tier_metric_filter_names" {
  description = "Names of the ERROR/WARN/CRITICAL log metric filters"
  value = [
    aws_cloudwatch_log_metric_filter.app_error.name,
    aws_cloudwatch_log_metric_filter.app_warning.name,
  ]
}

############################################
# CloudWatch Monitoring BUDGET - OUTPUTS
############################################

output "ec2_budget_name" {
  description = "Name of the AWS Budget tracking EC2 spend"
  value       = aws_budgets_budget.ec2.name
}

output "rds_budget_name" {
  description = "Name of the AWS Budget tracking RDS spend"
  value       = aws_budgets_budget.rds.name
}

############################################
# CloudWatch Monitoring RDS - OUTPUTS
############################################

output "rds_log_group_name" {
  description = "Name of the CloudWatch Log Group reserved for RDS PostgreSQL logs"
  value       = aws_cloudwatch_log_group.rds_exported.name
}

output "rds_dashboard_name" {
  description = "Name of the RDS CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.rds.dashboard_name
}

output "rds_alarm_names" {
  description = "Names of all CloudWatch alarms configured for RDS"
  value = [
    aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_connections.alarm_name,
  ]
}
