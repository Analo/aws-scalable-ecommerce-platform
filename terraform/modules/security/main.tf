# Security Module for Multi-tier Architecture
# Implements security groups, NACLs, and monitoring

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Module      = "security"
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # Inbound HTTP
  ingress {
    description = "HTTP from internet"
    from_port   = var.allowed_ports.http
    to_port     = var.allowed_ports.http
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS
  ingress {
    description = "HTTPS from internet"
    from_port   = var.allowed_ports.https
    to_port     = var.allowed_ports.https
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to web tier
  egress {
    description     = "HTTP to web tier"
    from_port       = var.allowed_ports.http
    to_port         = var.allowed_ports.http
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  # Outbound to web tier HTTPS
  egress {
    description     = "HTTPS to web tier"
    from_port       = var.allowed_ports.https
    to_port         = var.allowed_ports.https
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  # Outbound custom app port
  egress {
    description     = "Custom app port to web tier"
    from_port       = var.allowed_ports.custom_app
    to_port         = var.allowed_ports.custom_app
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Tier = "load-balancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Web Tier Security Group
resource "aws_security_group" "web_tier" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  vpc_id      = var.vpc_id
  description = "Security group for web tier instances"

  # Inbound from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.allowed_ports.http
    to_port         = var.allowed_ports.http
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = var.allowed_ports.https
    to_port         = var.allowed_ports.https
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Custom app port from ALB"
    from_port       = var.allowed_ports.custom_app
    to_port         = var.allowed_ports.custom_app
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH access (conditional)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      description = "SSH access"
      from_port   = var.allowed_ports.ssh
      to_port     = var.allowed_ports.ssh
      protocol    = "tcp"
      cidr_blocks = length(var.office_ip_ranges) > 0 ? var.office_ip_ranges : var.ssh_cidr_blocks
    }
  }

  # Outbound to app tier
  egress {
    description     = "Custom app port to app tier"
    from_port       = var.allowed_ports.custom_app
    to_port         = var.allowed_ports.custom_app
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  # Outbound internet access (for updates, etc.)
  egress {
    description = "HTTPS outbound for updates"
    from_port   = var.allowed_ports.https
    to_port     = var.allowed_ports.https
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound for updates"
    from_port   = var.allowed_ports.http
    to_port     = var.allowed_ports.http
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
    Tier = "presentation"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application Tier Security Group
resource "aws_security_group" "app_tier" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  vpc_id      = var.vpc_id
  description = "Security group for application tier instances"

  # Inbound from web tier
  ingress {
    description     = "Custom app port from web tier"
    from_port       = var.allowed_ports.custom_app
    to_port         = var.allowed_ports.custom_app
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  # SSH access (conditional)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      description = "SSH access"
      from_port   = var.allowed_ports.ssh
      to_port     = var.allowed_ports.ssh
      protocol    = "tcp"
      cidr_blocks = length(var.office_ip_ranges) > 0 ? var.office_ip_ranges : var.ssh_cidr_blocks
    }
  }

  # Outbound to database
  egress {
    description     = "MySQL to database"
    from_port       = var.allowed_ports.mysql
    to_port         = var.allowed_ports.mysql
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
  }

  # Outbound to Redis cache
  egress {
    description     = "Redis to cache"
    from_port       = var.allowed_ports.redis
    to_port         = var.allowed_ports.redis
    protocol        = "tcp"
    security_groups = [aws_security_group.cache.id]
  }

  # Outbound internet access
  egress {
    description = "HTTPS outbound for APIs and updates"
    from_port   = var.allowed_ports.https
    to_port     = var.allowed_ports.https
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound for APIs and updates"
    from_port   = var.allowed_ports.http
    to_port     = var.allowed_ports.http
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
    Tier = "application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for database instances"

  # Inbound from app tier
  ingress {
    description     = "MySQL from app tier"
    from_port       = var.allowed_ports.mysql
    to_port         = var.allowed_ports.mysql
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  # No outbound rules - databases should not initiate outbound connections
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cache Security Group (Redis/ElastiCache)
resource "aws_security_group" "cache" {
  name_prefix = "${var.project_name}-${var.environment}-cache-"
  vpc_id      = var.vpc_id
  description = "Security group for cache instances (Redis)"

  # Inbound from app tier
  ingress {
    description     = "Redis from app tier"
    from_port       = var.allowed_ports.redis
    to_port         = var.allowed_ports.redis
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cache-sg"
    Tier = "cache"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion Host Security Group (if SSH access needed)
resource "aws_security_group" "bastion" {
  count = var.enable_ssh_access ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-bastion-"
  vpc_id      = var.vpc_id
  description = "Security group for bastion host"

  # SSH from office/admin IPs
  ingress {
    description = "SSH from admin networks"
    from_port   = var.allowed_ports.ssh
    to_port     = var.allowed_ports.ssh
    protocol    = "tcp"
    cidr_blocks = length(var.office_ip_ranges) > 0 ? var.office_ip_ranges : var.ssh_cidr_blocks
  }

  # Outbound SSH to private instances
  egress {
    description = "SSH to private subnets"
    from_port   = var.allowed_ports.ssh
    to_port     = var.allowed_ports.ssh
    protocol    = "tcp"
    cidr_blocks = concat(var.private_subnet_cidrs, var.database_subnet_cidrs)
  }

  # Outbound HTTPS for updates
  egress {
    description = "HTTPS for updates"
    from_port   = var.allowed_ports.https
    to_port     = var.allowed_ports.https
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
    Tier = "management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# NETWORK ACLs (Additional Layer of Security)
# =============================================================================

# Public Subnet Network ACL
resource "aws_network_acl" "public" {
  count  = var.enable_network_acls ? 1 : 0
  vpc_id = var.vpc_id

  # Inbound HTTP
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.http
    to_port    = var.allowed_ports.http
  }

  # Inbound HTTPS
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.https
    to_port    = var.allowed_ports.https
  }

  # Inbound SSH (conditional)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      rule_no    = 120
      protocol   = "tcp"
      action     = "allow"
      cidr_block = length(var.office_ip_ranges) > 0 ? var.office_ip_ranges[0] : "0.0.0.0/0"
      from_port  = var.allowed_ports.ssh
      to_port    = var.allowed_ports.ssh
    }
  }

  # Inbound ephemeral ports for return traffic
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound HTTP
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.http
    to_port    = var.allowed_ports.http
  }

  # Outbound HTTPS
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.https
    to_port    = var.allowed_ports.https
  }

  # Outbound to private subnets
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.custom_app
    to_port    = var.allowed_ports.custom_app
  }

  # Outbound ephemeral ports
  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-nacl"
    Tier = "public"
  })
}

# Private Subnet Network ACL
resource "aws_network_acl" "private" {
  count  = var.enable_network_acls ? 1 : 0
  vpc_id = var.vpc_id

  # Inbound from public subnets
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.custom_app
    to_port    = var.allowed_ports.custom_app
  }

  # Inbound SSH from bastion
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      rule_no    = 110
      protocol   = "tcp"
      action     = "allow"
      cidr_block = var.vpc_cidr_block
      from_port  = var.allowed_ports.ssh
      to_port    = var.allowed_ports.ssh
    }
  }

  # Inbound ephemeral ports
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound to internet via NAT
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.http
    to_port    = var.allowed_ports.http
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.allowed_ports.https
    to_port    = var.allowed_ports.https
  }

  # Outbound to database subnets
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.mysql
    to_port    = var.allowed_ports.mysql
  }

  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.redis
    to_port    = var.allowed_ports.redis
  }

  # Outbound ephemeral ports
  egress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-nacl"
    Tier = "private"
  })
}

# Database Subnet Network ACL
resource "aws_network_acl" "database" {
  count  = var.enable_network_acls ? 1 : 0
  vpc_id = var.vpc_id

  # Inbound from private subnets only
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.mysql
    to_port    = var.allowed_ports.mysql
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.allowed_ports.redis
    to_port    = var.allowed_ports.redis
  }

  # Inbound ephemeral ports for return traffic
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound ephemeral ports (for return traffic only)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-database-nacl"
    Tier = "database"
  })
}

# =============================================================================
# VPC FLOW LOGS
# =============================================================================

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-flow-logs-"
  role        = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}