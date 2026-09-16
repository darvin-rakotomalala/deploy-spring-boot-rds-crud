############################################
# VPC Endpoints - AWS Systems Manager
############################################

output "vpc_endpoint_ssm_id" {
  description = "The ID of the SSM VPC Endpoint"
  value       = aws_vpc_endpoint.ssm_interfaces["ssm"].id
}

output "vpc_endpoint_ssmmessages_id" {
  description = "The ID of the SSM Messages VPC Endpoint"
  value       = aws_vpc_endpoint.ssm_interfaces["ssmmessages"].id
}

output "vpc_endpoint_ec2messages_id" {
  description = "The ID of the EC2 Messages VPC Endpoint"
  value       = aws_vpc_endpoint.ssm_interfaces["ec2messages"].id
}

output "ssm_vpc_endpoint_ids" {
  description = "Map of endpoint keys to their respective VPC Endpoint IDs"
  value       = { for k, vpce in aws_vpc_endpoint.ssm_interfaces : k => vpce.id }
}
