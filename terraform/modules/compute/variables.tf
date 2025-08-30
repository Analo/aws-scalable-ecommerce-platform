variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  type        = string
}

variable "web_tier_security_group_id" {
  description = "Security group ID for web tier instances"
  type        = string
}

variable "app_tier_security_group_id" {
  description = "Security group ID for application tier instances"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  type        = string
  default     = null
}

variable "instance_types" {
  description = "EC2 instance types for different tiers"
  type = object({
    web_tier    = string
    app_tier    = string
    bastion     = string
  })
  default = {
    web_tier    = "t3.micro"
    app_tier    = "t3.small"
    bastion     = "t3.micro"
  }
}

variable "auto_scaling_config" {
  description = "Auto Scaling configuration"
  type = object({
    web_tier = object({
      min_size         = number
      max_size         = number
      desired_capacity = number
      target_cpu       = number
    })
    app_tier = object({
      min_size         = number
      max_size         = number
      desired_capacity = number
      target_cpu       = number
    })
  })
  default = {
    web_tier = {
      min_size         = 2
      max_size         = 6
      desired_capacity = 3
      target_cpu       = 70
    }
    app_tier = {
      min_size         = 2
      max_size         = 4
      desired_capacity = 2
      target_cpu       = 60
    }
  }
}

variable "alb_config" {
  description = "Application Load Balancer configuration"
  type = object({
    enable_deletion_protection = bool
    idle_timeout              = number
    enable_http2              = bool
    enable_waf                = bool
    ssl_certificate_arn       = string
  })
  default = {
    enable_deletion_protection = true
    idle_timeout              = 60
    enable_http2              = true
    enable_waf                = false
    ssl_certificate_arn       = ""
  }
}

variable "health_check_config" {
  description = "Health check configuration for target groups"
  type = object({
    enabled             = bool
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout            = number
    interval           = number
    path               = string
    matcher            = string
  })
  default = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout            = 5
    interval           = 30
    path               = "/health"
    matcher            = "200"
  }
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

variable "enable_bastion_host" {
  description = "Enable bastion host for secure access"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "user_data_template" {
  description = "User data script template for EC2 instances"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty for latest Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}