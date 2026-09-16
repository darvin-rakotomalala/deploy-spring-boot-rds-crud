############################################
# IAM - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
  # default = data.aws_partition.current.partition
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "jar_bucket_name" {
  description = "Name of the S3 bucket that stores the Spring Boot JAR artifact"
  type        = string
}

variable "kms_key_rds_arn" {
  description = "ARN of RDS KMS key"
  type        = string
}

variable "kms_key_secrets_arn" {
  description = "ARN of Secrets Manager KMS key"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "ARN of CloudWatch KMS key"
  type        = string
}

variable "secretsmanager_db_credentials_arn" {
  description = "ARN of db credentials in Secrets Manager"
  type        = string
}

variable "log_group_app_tier_arn" {
  description = "ARN of CloudWatch log group App tier"
  type        = string
}

variable "kms_key_cloudwatch_id" {
  description = "ID of CloudWatch KMS key"
  type        = string
}

variable "ec2_instance_ids" {
  description = "IDs of the Spring Boot application EC2 instances"
  type        = list(string)
}
