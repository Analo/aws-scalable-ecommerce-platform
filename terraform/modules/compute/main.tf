# Compute Infrastructure Module
# Auto-scaling EC2 instances with Application Load Balancer

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
    Module      = "compute"
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# APPLICATION LOAD BALANCER
# =============================================================================

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  
  security_groups = [var.alb_security_group_id]
  subnets        = var.public_subnet_ids

  enable_deletion_protection = var.alb_config.enable_deletion_protection
  idle_timeout              = var.alb_config.idle_timeout
  enable_http2              = var.alb_config.enable_http2

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
    Type = "application-load-balancer"
  })
}

# ALB Target Group - Web Tier
resource "aws_lb_target_group" "web_tier" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = var.health_check_config.enabled
    healthy_threshold   = var.health_check_config.healthy_threshold
    unhealthy_threshold = var.health_check_config.unhealthy_threshold
    timeout            = var.health_check_config.timeout
    interval           = var.health_check_config.interval
    path               = var.health_check_config.path
    matcher            = var.health_check_config.matcher
    port               = "traffic-port"
    protocol           = "HTTP"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-target-group"
    Tier = "presentation"
  })
}

# ALB Listener - HTTP
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-http-listener"
  })
}

# ALB Listener - HTTPS (conditional)
resource "aws_lb_listener" "web_https" {
  count = var.alb_config.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.alb_config.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-https-listener"
  })
}

# ALB Listener - HTTP (fallback when no SSL)
resource "aws_lb_listener" "web_http_fallback" {
  count = var.alb_config.ssl_certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-http-listener-fallback"
  })
}

# =============================================================================
# LAUNCH TEMPLATES
# =============================================================================

# User data script
locals {
  default_user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))
  
  user_data = var.user_data_template != "" ? base64encode(var.user_data_template) : local.default_user_data
}

# Launch Template - Web Tier
resource "aws_launch_template" "web_tier" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.web_tier
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [var.web_tier_security_group_id]

  user_data = local.user_data

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-web-instance"
      Tier = "presentation"
      Type = "web-server"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-launch-template"
    Tier = "presentation"
  })
}

# Launch Template - App Tier
resource "aws_launch_template" "app_tier" {
  name_prefix   = "${var.project_name}-${var.environment}-app-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.app_tier
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [var.app_tier_security_group_id]

  user_data = local.user_data

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-app-instance"
      Tier = "application"
      Type = "application-server"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-launch-template"
    Tier = "application"
  })
}

# =============================================================================
# AUTO SCALING GROUPS
# =============================================================================

# Auto Scaling Group - Web Tier
resource "aws_autoscaling_group" "web_tier" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web_tier.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.auto_scaling_config.web_tier.min_size
  max_size         = var.auto_scaling_config.web_tier.max_size
  desired_capacity = var.auto_scaling_config.web_tier.desired_capacity

  launch_template {
    id      = aws_launch_template.web_tier.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "presentation"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group - App Tier
resource "aws_autoscaling_group" "app_tier" {
  name                = "${var.project_name}-${var.environment}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.auto_scaling_config.app_tier.min_size
  max_size         = var.auto_scaling_config.app_tier.max_size
  desired_capacity = var.auto_scaling_config.app_tier.desired_capacity

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "application"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# AUTO SCALING POLICIES
# =============================================================================

# Auto Scaling Policy - Web Tier Scale Up
resource "aws_autoscaling_policy" "web_tier_scale_up" {
  name                   = "${var.project_name}-${var.environment}-web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_tier.name
}

# Auto Scaling Policy - Web Tier Scale Down
resource "aws_autoscaling_policy" "web_tier_scale_down" {
  name                   = "${var.project_name}-${var.environment}-web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_tier.name
}

# Auto Scaling Policy - App Tier Scale Up
resource "aws_autoscaling_policy" "app_tier_scale_up" {
  name                   = "${var.project_name}-${var.environment}-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_tier.name
}

# Auto Scaling Policy - App Tier Scale Down
resource "aws_autoscaling_policy" "app_tier_scale_down" {
  name                   = "${var.project_name}-${var.environment}-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_tier.name
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# CloudWatch Alarm - Web Tier High CPU
resource "aws_cloudwatch_metric_alarm" "web_tier_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-web-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.auto_scaling_config.web_tier.target_cpu
  alarm_description   = "This metric monitors web tier CPU utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_tier.name
  }

  alarm_actions = [aws_autoscaling_policy.web_tier_scale_up.arn]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-high-cpu-alarm"
    Tier = "presentation"
  })
}

# CloudWatch Alarm - Web Tier Low CPU
resource "aws_cloudwatch_metric_alarm" "web_tier_low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-web-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.auto_scaling_config.web_tier.target_cpu - 20
  alarm_description   = "This metric monitors web tier CPU utilization for scale down"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_tier.name
  }

  alarm_actions = [aws_autoscaling_policy.web_tier_scale_down.arn]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-low-cpu-alarm"
    Tier = "presentation"
  })
}

# CloudWatch Alarm - App Tier High CPU
resource "aws_cloudwatch_metric_alarm" "app_tier_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.auto_scaling_config.app_tier.target_cpu
  alarm_description   = "This metric monitors app tier CPU utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_tier.name
  }

  alarm_actions = [aws_autoscaling_policy.app_tier_scale_up.arn]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-high-cpu-alarm"
    Tier = "application"
  })
}

# CloudWatch Alarm - App Tier Low CPU
resource "aws_cloudwatch_metric_alarm" "app_tier_low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-app-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.auto_scaling_config.app_tier.target_cpu - 20
  alarm_description   = "This metric monitors app tier CPU utilization for scale down"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_tier.name
  }

  alarm_actions = [aws_autoscaling_policy.app_tier_scale_down.arn]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-low-cpu-alarm"
    Tier = "application"
  })
}

# =============================================================================
# BASTION HOST
# =============================================================================

# Bastion Host Instance
resource "aws_instance" "bastion" {
  count = var.enable_bastion_host ? 1 : 0

  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.bastion
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_security_group_id]
  associate_public_ip_address = true

  monitoring = var.enable_detailed_monitoring

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOL
    {
      "metrics": {
        "namespace": "Bastion/Metrics",
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_iowait"],
            "metrics_collection_interval": 60,
            "totalcpu": false
          },
          "disk": {
            "measurement": ["used_percent"],
            "metrics_collection_interval": 60,
            "resources": ["*"]
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOL
    
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOF
  )

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-host"
    Type = "bastion"
    Tier = "management"
  })

  lifecycle {
    create_before_destroy = true
  }
}