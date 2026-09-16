############################################
# Gateway VPC Endpoint for S3 - OUTPUTS
############################################

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 Gateway VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}
