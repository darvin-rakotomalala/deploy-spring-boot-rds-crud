############################################
# SNS VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "kms_key_cloudwatch_id" {
  description = "ID of CloudWatch KMS key"
  type        = string
}

variable "alert_emails" {
  description = "Email address subscribed to SNS alert topics for CloudWatch alarms"
  type        = list(string)
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}
