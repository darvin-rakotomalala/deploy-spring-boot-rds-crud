############################################
# Networking
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

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
