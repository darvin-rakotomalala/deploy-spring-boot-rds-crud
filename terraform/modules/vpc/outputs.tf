############################################
# VPC OUTPUTS
############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways (one per AZ)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_eips" {
  description = "Elastic IP addresses allocated to the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

############################################
# SUBNETS OUTPUTS
############################################

output "public_subnet_ids" {
  description = "IDs of the public (ALB) subnets"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs of the private application-tier subnets"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of the isolated database-tier subnets"
  value       = aws_subnet.db[*].id
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group"
  value       = aws_db_subnet_group.main.name
}

############################################
# RT OUTPUTS
############################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "app_route_table_ids" {
  description = "IDs of the application-tier route tables (one per AZ)"
  value       = aws_route_table.app[*].id
}

output "db_route_table_ids" {
  description = "IDs of the database-tier route tables (one per AZ, no internet route)"
  value       = aws_route_table.db[*].id
}
