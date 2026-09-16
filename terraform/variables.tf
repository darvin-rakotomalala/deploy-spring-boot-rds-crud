############################################
# MAIN VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "availability_zones" {
  description = "Two AWS Availability Zones used across all tiers"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "single_nat_gateway" {
  type        = bool
  description = "If true, deploy a single NAT Gateway across all AZs to cut costs in dev/staging environments."
}

variable "alert_emails" {
  description = "Email address subscribed to SNS alert topics for CloudWatch alarms"
  type        = list(string)
}

variable "app_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "db_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "alb_logs_bucket_name" {
  description = "Name of the S3 bucket that stores ALB access logs (leave blank to auto-generate)"
  type        = string
}

variable "jar_bucket_name" {
  description = "Name of the S3 bucket that stores the Spring Boot JAR artifact"
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

variable "ec2_instance_type" {
  description = "Instance type for the Spring Boot application server"
  type        = string
}

variable "ec2_root_volume_size" {
  description = "Root EBS volume size (GiB) for the application server"
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

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the ALB target group uses for application health checks"
  type        = string
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion protection will be enabled on the Application Load Balancer to prevent accidental deletion."
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener (empty if domain_name was not set)"
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

variable "source_file" {
  description = "JAR file"
  type        = string
}
