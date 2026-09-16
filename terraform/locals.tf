locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Region      = var.primary_region # primary or secondary
    Environment = var.environment    # dev, staging, prod
    Project     = var.project_name   # ce
    Owner       = var.team_name      # demo
    CostCenter  = var.cost_center    # "engineering"
    Compliance  = var.compliance     # "internal"
    # The timestamp() function returns a UTC timestamp string in RFC 3339 format.
    deployment_timestamp = timestamp()
  }
  naming_prefix = "${var.project_name}-${var.environment}"

  rds_identifier = "myapp-rds-postgres"

  ## UPLOAD FILES TO S3 BUCKET
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "json"  = "application/json"
    "webp"  = "image/webp"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "svg"   = "image/svg+xml"
    "ico"   = "image/x-icon"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "txt"   = "text/plain"
  }
}
