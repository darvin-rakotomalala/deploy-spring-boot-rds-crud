############################################
# VPC Endpoints - AWS Systems Manager
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "app_subnet_ids" {
  description = "IDs of the private application-tier subnets"
  type        = list(string)
}

variable "ssm_endpoints_security_group_id" {
  description = "ID of the SSM-SG security group used by the interface VPC endpoints"
  type        = string
}
