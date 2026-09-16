############################################
# Gateway VPC Endpoint for S3 - VARIABLES
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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "bucket_jar_artifacts_arn" {
  description = "ARN of S3 Bucket for JAR artifacts"
  type        = string
}

variable "bucket_alb_logs_arn" {
  description = "ARN of S3 Bucket for JAR artifacts"
  type        = string
}

variable "app_route_table_ids" {
  description = "IDs of public RT"
  type        = list(string)
}
