############################################
# KMS - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "iam_role_ec2_app_arn" {
  description = "ARN of IAM Role EC2 App"
  type        = string
}

variable "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  type        = string
}
