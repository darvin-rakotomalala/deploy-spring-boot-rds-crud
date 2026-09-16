############################################
# S3 - VARIABLES
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

variable "jar_bucket_name" {
  description = "Name of the S3 bucket that stores the Spring Boot JAR artifact"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Name of the S3 bucket that stores ALB access logs (leave blank to auto-generate)"
  type        = string
}

variable "iam_role_ec2_app_arn" {
  description = "ARN of IAM Role EC2 App"
  type        = string
}

variable "kms_key_alb_logs_arn" {
  description = "ARN of KMS key ALB logs"
  type        = string
}

variable "kms_key_jar_artifacts_arn" {
  description = "ARN of KMS key JAR artifacts"
  type        = string
}

variable "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  type        = string
}
