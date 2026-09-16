############################################
# EC2 Application Tier - VARIABLES
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

variable "availability_zones" {
  description = "Two AWS Availability Zones used across all tiers"
  type        = list(string)
}

variable "ec2_instance_type" {
  description = "Instance type for the Spring Boot application server"
  type        = string
}

variable "ec2_root_volume_size" {
  description = "Root EBS volume size (GiB) for the application server"
  type        = number
}

variable "app_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "jar_file_key" {
  description = "S3 object key (filename) of the Spring Boot JAR artifact"
  type        = string
}

variable "ec2_instance_count" {
  description = "Number of Spring Boot application EC2 instances to launch across the two app-tier AZs (>=2 recommended for the objective's high-availability requirement)"
  type        = number
}

variable "jar_artifacts_bucket_id" {
  description = "Name of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials"
  type        = string
}

variable "app_tier_log_group_name" {
  description = "Name of the CloudWatch Log Group for the Spring Boot application tier"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
}

variable "aws_db_instance_main" {
  description = "RDS PostgreSQL primary instance"
  type        = string
}

variable "data_aws_ami_ubuntu_id" {
  description = "ID of data AMI Ubuntu"
  type        = string
}

variable "app_subnet_ids" {
  description = "IDs of the private application-tier subnets"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "ID of the EC2-APP-SG security group"
  type        = string
}

variable "ec2_app_instance_profile_name" {
  description = "Name of the EC2 instance profile attached to the application server"
  type        = string
}

variable "jar_bucket_name" {
  description = "Name of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}
