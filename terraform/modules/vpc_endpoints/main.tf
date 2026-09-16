############################################
# VPC Endpoints - AWS Systems Manager
# Enables SSM to manage EC2 instances in private subnets with no
# internet access (no bastion host / no public IP required).
############################################

# Local map to dynamically iterate over core SSM endpoints
locals {
  ssm_services = toset([
    "ssm",
    "ssmmessages",
    "ec2messages"
  ])
}

# Interface Endpoints for Systems Manager
resource "aws_vpc_endpoint" "ssm_interfaces" {
  for_each = local.ssm_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.primary_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.app_subnet_ids
  security_group_ids  = [var.ssm_endpoints_security_group_id]
  private_dns_enabled = true

  # Attach restricted policy (Least-Privilege)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSMAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.current_account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpce-${each.key}"
  })
}
