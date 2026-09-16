############################################
# CloudWatch Monitoring - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
}

variable "kms_cloudwatch_key_arn" {
  description = "ARN of the KMS key used for CloudWatch Logs / SNS encryption"
  type        = string
}

variable "sns_alerts_topic_arn" {
  description = "ARN of the shared SNS topic used by ALB, EC2 and RDS CloudWatch alarms"
  type        = string
}

variable "ec2_instance_ids" {
  description = "IDs of the Spring Boot application EC2 instances"
  type        = list(string)
}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "rds_identifier" {
  description = "Identifier of the RDS PostgreSQL instance"
  type        = string
}

variable "aws_db_instance_main" {
  description = "RDS PostgreSQL primary instance"
  type        = string
}

variable "connection_threshold_percent" {
  type        = number
  description = "Percentage of max_connections allowed before alerting"
}

variable "cpu_threshold_percent" {
  type        = number
  description = "CPU threshold percent allowed before alerting"
}

variable "db_instance_class" {
  description = "RDS instance class for the PostgreSQL primary"
  type        = string
}
