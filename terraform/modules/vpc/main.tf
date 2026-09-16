############################################
# VPC, Internet Gateway, NAT Gateway
############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-igw"
  })
}

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.availability_zones)
}

# One Elastic IP per AZ for highly-available NAT Gateways
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-nat-eip-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-nat-gw-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main]
}

############################################
# Subnets
############################################

# ---------- Public subnets (ALB tier) ----------
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index) # 10.0.0.0/24, 10.0.1.0/24...
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

# ---------- Private subnets (Application tier, egress via NAT) ----------
resource "aws_subnet" "app" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10) # 10.0.10.0/24, 10.0.11.0/24...
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-${var.availability_zones[count.index]}"
    Tier = "application"
  })
}

# ---------- Private subnets (Database tier, fully isolated - no internet access) ----------
resource "aws_subnet" "db" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 20) # 10.0.20.0/24, 10.0.21.0/24...
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-db-${var.availability_zones[count.index]}"
    Tier = "database"
  })
}

# ---------- RDS DB Subnet Group ----------
resource "aws_db_subnet_group" "main" {
  name        = "${var.naming_prefix}-db-subnet-group"
  description = "DB subnet group spanning the isolated database-tier subnets"
  subnet_ids  = aws_subnet.db[*].id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-db-subnet-group"
  })
}

############################################
# Route Tables
############################################

# ---------- Public Route Table (-> Internet Gateway) ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Application-tier Route Tables (-> NAT Gateway, one per AZ for HA) ----------
resource "aws_route_table" "app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-rt-${var.availability_zones[count.index]}"
  })
}

# Map application route tables to the correct NAT Gateway
resource "aws_route" "app_nat_access" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# ---------- Database-tier Route Tables (no internet access) ----------
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-db-rt"
  })
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
