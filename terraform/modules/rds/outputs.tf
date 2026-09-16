############################################
# RDS - OUTPUTS
############################################

output "aws_db_instance_main" {
  description = "RDS PostgreSQL primary instance"
  value       = aws_db_instance.main.id
}

output "rds_endpoint" {
  description = "Connection endpoint (host:port) of the RDS PostgreSQL primary instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS PostgreSQL primary instance"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port the RDS PostgreSQL instance listens on"
  value       = aws_db_instance.main.port
}

output "rds_identifier" {
  description = "Identifier of the RDS PostgreSQL instance"
  value       = aws_db_instance.main.identifier
}

output "rds_engine_version" {
  description = "PostgreSQL engine version deployed"
  value       = aws_db_instance.main.engine_version_actual
}

# SSM Session Manager port-forwarding command: lets a developer connect to the
# isolated RDS instance from their laptop without a bastion host or public IP,
# by tunnelling through one of the app-tier EC2 instances.
output "ssm_port_forward_command" {
  description = "AWS CLI command to open an SSM port-forwarding session from your machine to RDS via the app EC2 instance"
  value       = <<-EOT
    aws ssm start-session \
      --target ${length(var.ec2_instance_ids) > 0 ? var.ec2_instance_ids[0] : "<EC2_INSTANCE_ID>"} \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters '{"host":["${aws_db_instance.main.address}"],"portNumber":["5432"],"localPortNumber":["4898"]}' \
      --region ${var.primary_region}
  EOT
}
