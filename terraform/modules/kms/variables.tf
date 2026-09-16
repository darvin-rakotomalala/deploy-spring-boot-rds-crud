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
  # default = data.aws_partition.current.partition
}

variable "iam_role_ec2_app_arn" {
  description = "ARN of IAM Role EC2 App"
  type        = string
}
