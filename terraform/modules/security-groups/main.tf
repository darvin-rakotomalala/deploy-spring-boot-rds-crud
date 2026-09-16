############################################
# Security Groups
############################################

# ---------- ALB-SG: Public-facing Internet Edge ----------
resource "aws_security_group" "alb" {
  name        = "${var.naming_prefix}-ALB-SG"
  description = "Security group for public-facing Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ALB-SG"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet (for HTTPS redirect)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Restrict ALB outbound traffic solely to the application tier"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# ---------- EC2-APP-SG: Application Tier ----------
resource "aws_security_group" "app" {
  name        = "${var.naming_prefix}-EC2-APP-SG"
  description = "Security group for Spring Boot application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-EC2-APP-SG"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_rds" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application tier to reach RDS PostgreSQL instance"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_ssm_endpoints" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow HTTPS egress to SSM interface endpoints"
  referenced_security_group_id = aws_security_group.ssm_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_https_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTPS egress for external OS updates and CloudWatch APIs"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_http_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTP egress for Linux package repository mirrors"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# ---------- RDS-SG: Database Tier ----------
resource "aws_security_group" "rds" {
  name        = "${var.naming_prefix}-RDS-SG"
  description = "Security group for isolated RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-RDS-SG"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow database traffic from application tier only"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# Note: RDS requires zero egress rules. Stateful tracking handles return responses to EC2 automatically.
# ---------- SSM-SG: VPC Interface Endpoints ----------
resource "aws_security_group" "ssm_endpoints" {
  name        = "${var.naming_prefix}-SSM-SG"
  description = "Security group for SSM Interface VPC Endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-SSM-SG"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ssm_endpoints_from_app" {
  security_group_id            = aws_security_group.ssm_endpoints.id
  description                  = "Allow HTTPS from application tier EC2 instances"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
