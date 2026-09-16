############################################
# EC2 - OUTPUTS
############################################

output "ec2_instance_ids" {
  description = "IDs of the Spring Boot application EC2 instances"
  value       = aws_instance.app[*].id
}

output "ec2_private_ips" {
  description = "Private IP addresses of the Spring Boot application EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "ec2_availability_zones" {
  description = "Availability zones the application EC2 instances are deployed in"
  value       = aws_instance.app[*].availability_zone
}
