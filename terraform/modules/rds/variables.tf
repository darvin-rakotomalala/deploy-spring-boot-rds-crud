############################################
# RDS PostgreSQL - VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "kms_rds_key_arn" {
  description = "ARN of the KMS key used for RDS encryption"
  type        = string
}

variable "random_password_db_master_result" {
  description = "Random password db master result"
  type        = string
  sensitive   = true
}

variable "identifier" {
  description = "RDS identifier for the PostgreSQL primary"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class for the PostgreSQL primary"
  type        = string
}

variable "db_engine_version" {
  description = "PostgreSQL engine version (latest stable)"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage (GiB) for RDS"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Upper limit (GiB) for RDS storage autoscaling"
  type        = number
}

variable "db_name" {
  description = "Initial PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance"
  type        = string
}

variable "db_multi_az" {
  description = "Whether to deploy RDS in Multi-AZ mode"
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated RDS backups"
  type        = number
}

variable "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID of the RDS-SG security group"
  type        = string
}

variable "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the IAM role used for RDS Enhanced Monitoring"
  type        = string
}

variable "rds_log_group_name" {
  description = "Name of the CloudWatch Log Group reserved for RDS PostgreSQL logs"
  type        = string
}

variable "ec2_instance_ids" {
  description = "IDs of the Spring Boot application EC2 instances"
  type        = list(string)
}
