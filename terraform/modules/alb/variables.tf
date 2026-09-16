############################################
# Application Load Balancer - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "alb_security_group_id" {
  description = "ID of the ALB-SG security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public (ALB) subnets"
  type        = list(string)
}

variable "alb_logs_bucket_id" {
  description = "ID of the S3 bucket storing ALB access logs"
  type        = string
}

variable "bucket_policy_alb_logs" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}

variable "app_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "health_check_path" {
  description = "HTTP path the ALB target group uses for application health checks"
  type        = string
}

variable "ec2_instance_count" {
  description = "Number of Spring Boot application EC2 instances to launch across the two app-tier AZs (>=2 recommended for the objective's high-availability requirement)"
  type        = number
}

variable "ec2_instance_ids" {
  description = "IDs of the Spring Boot application EC2 instances"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener (empty if domain_name was not set)"
  type        = string
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion protection will be enabled on the Application Load Balancer to prevent accidental deletion."
}
