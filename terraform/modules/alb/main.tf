############################################
# Application Load Balancer (public-facing, 2 AZs)
############################################

resource "aws_lb" "app" {
  name               = "${var.naming_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.alb_logs_bucket_id
    prefix  = "alb-access-logs"
    enabled = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb"
  })

  depends_on = [var.bucket_policy_alb_logs]
}

# ---------- Target Group: forwards to the Spring Boot app tier ----------
resource "aws_lb_target_group" "app" {
  name        = "${var.naming_prefix}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-tg"
  })
}

locals {
  # Treat null or empty string as "no certificate provided"
  has_acm_cert = var.acm_certificate_arn != null && var.acm_certificate_arn != ""

  ec2_instance_id_map = { for idx, id in var.ec2_instance_ids : idx => id }
}

# ---------- Target Attachments (Use ONLY for static EC2 fleets) --------
# NOTE: Remove this resource if integrating with an Auto Scaling Group (ASG)
resource "aws_lb_target_group_attachment" "app" {
  for_each         = local.ec2_instance_id_map
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value
  port             = var.app_port
}

# ---------- Listener 80 (HTTP) ----------
# If a cert is available: redirect all HTTP -> HTTPS.
# If no cert is available: forward HTTP directly to the target group
# so the environment is still reachable (dev/sandbox/bootstrap case).
resource "aws_lb_listener" "http_redirect" {
  count             = local.has_acm_cert ? 1 : 0
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "http_forward" {
  count             = local.has_acm_cert ? 0 : 1
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------- Listener 443 (HTTPS) ----------
# Only created once a valid ACM certificate ARN is supplied.
resource "aws_lb_listener" "https" {
  count             = local.has_acm_cert ? 1 : 0
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # supports TLS 1.2 and TLS 1.3
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
