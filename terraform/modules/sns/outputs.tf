############################################
# SNS OUTPUTS
############################################

output "sns_alerts_topic_arn" {
  description = "ARN of the shared SNS topic used by ALB, EC2 and RDS CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}
