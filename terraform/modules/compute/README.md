# Compute Infrastructure Module - Auto-Scaling Web Application

A comprehensive Terraform module for deploying auto-scaling compute infrastructure with Application Load Balancer, multi-tier EC2 instances, and comprehensive monitoring.

##  **Architecture Overview**

This module creates a robust, scalable compute environment:

```
                    Internet Gateway
                           │
                    ┌──────┴──────┐
                    │     ALB     │ ← Application Load Balancer
                    │   (Public)  │   SSL Termination & Health Checks
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
           AZ-1a        AZ-1b        AZ-1c
              │            │            │
      ┌───────┴──────┐ ┌───┴──────┐ ┌──┴─────┐
      │ Web Tier     │ │ Web Tier │ │Web Tier│
      │ Auto Scaling │ │Auto Scale│ │Auto Sc │ ← Web Servers (2-6 instances)
      │ Group        │ │Group     │ │Group   │   Target CPU: 70%
      └──────┬───────┘ └──────┬───┘ └───┬────┘
             │                │         │
             └────────────────┼─────────┘
                              │
      ┌─────────────────────────────────────────┐
      │           App Tier Auto Scaling         │ ← Application Servers (2-4 instances)
      │              Group                      │   Target CPU: 60%
      │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
      │  │App Server│ │App Server│ │App Serve│ │
      │  │          │ │          │ │         │ │
      │  └──────────┘ └──────────┘ └─────────┘ │
      └─────────────────────────────────────────┘
                              │
      ┌───────────────────────┴───────────────────┐
      │        Bastion Host (Optional)            │ ← SSH Access Point
      │         Public Subnet                     │
      └───────────────────────────────────────────┘
              │                 │
    ┌─────────┴───────┐ ┌───────┴────────┐
    │   CloudWatch    │ │  Auto Scaling  │
    │    Alarms       │ │   Policies     │ ← Monitoring & Scaling
    └─────────────────┘ └────────────────┘
```

##  **Key Features**

- ✅ **Application Load Balancer**: SSL termination, health checks, multi-AZ
- ✅ **Auto-Scaling Groups**: Web tier (2-6 instances) and App tier (2-4 instances)
- ✅ **Launch Templates**: Latest Amazon Linux 2 with CloudWatch agent
- ✅ **CloudWatch Monitoring**: CPU-based scaling with custom metrics
- ✅ **Health Checks**: Application-level health monitoring
- ✅ **Bastion Host**: Secure administrative access (optional)
- ✅ **Security Integration**: Uses security groups from security module
- ✅ **Cost Optimization**: Instance right-sizing and efficient scaling policies

##  **Quick Start**

### Basic Usage
```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  # Network configuration
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Security groups
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
}
```

### Production Configuration
```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  # Network configuration
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Security groups
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
  
  # Instance configuration
  instance_types = {
    web_tier = "t3.small"
    app_tier = "t3.medium"
    bastion  = "t3.micro"
  }
  
  # Auto scaling configuration
  auto_scaling_config = {
    web_tier = {
      min_size         = 3
      max_size         = 10
      desired_capacity = 4
      target_cpu       = 65
    }
    app_tier = {
      min_size         = 2
      max_size         = 6
      desired_capacity = 3
      target_cpu       = 55
    }
  }
  
  # Load balancer configuration
  alb_config = {
    enable_deletion_protection = true
    idle_timeout              = 120
    enable_http2              = true
    enable_waf                = true
    ssl_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
  
  # Monitoring
  enable_detailed_monitoring = true
  
  # Access
  key_pair_name      = "production-keypair"
  enable_bastion_host = true
  
  tags = {
    Owner       = "DevOps Team"
    Environment = "Production"
    Monitoring  = "Enhanced"
  }
}
```

##  **Input Variables**

### Core Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **project_name** | Name of the project for resource naming | `string` | n/a | ✅ |
| **environment** | Environment name (dev, staging, prod) | `string` | n/a | ✅ |
| **vpc_id** | ID of the VPC | `string` | n/a | ✅ |
| **public_subnet_ids** | List of public subnet IDs for ALB | `list(string)` | n/a | ✅ |
| **private_subnet_ids** | List of private subnet IDs for EC2 instances | `list(string)` | n/a | ✅ |

### Security Groups
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **alb_security_group_id** | Security group ID for Application Load Balancer | `string` | n/a | ✅ |
| **web_tier_security_group_id** | Security group ID for web tier instances | `string` | n/a | ✅ |
| **app_tier_security_group_id** | Security group ID for application tier instances | `string` | n/a | ✅ |
| **bastion_security_group_id** | Security group ID for bastion host | `string` | `null` | ❌ |

### Instance Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **instance_types** | EC2 instance types for different tiers | `object` | See below | ❌ |
| **ami_id** | AMI ID for EC2 instances (empty for latest Amazon Linux 2) | `string` | `""` | ❌ |
| **key_pair_name** | EC2 Key Pair name for SSH access | `string` | `""` | ❌ |

**Default instance_types:**
```hcl
{
  web_tier = "t3.micro"
  app_tier = "t3.small"
  bastion  = "t3.micro"
}
```

### Auto Scaling Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **auto_scaling_config** | Auto Scaling configuration for both tiers | `object` | See below | ❌ |

**Default auto_scaling_config:**
```hcl
{
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
```

### Load Balancer Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **alb_config** | Application Load Balancer configuration | `object` | See below | ❌ |
| **health_check_config** | Health check configuration for target groups | `object` | See below | ❌ |

**Default alb_config:**
```hcl
{
  enable_deletion_protection = true
  idle_timeout              = 60
  enable_http2              = true
  enable_waf                = false
  ssl_certificate_arn       = ""
}
```

**Default health_check_config:**
```hcl
{
  enabled             = true
  healthy_threshold   = 2
  unhealthy_threshold = 3
  timeout            = 5
  interval           = 30
  path               = "/health"
  matcher            = "200"
}
```

### Monitoring & Access
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **enable_bastion_host** | Enable bastion host for secure access | `bool` | `true` | ❌ |
| **enable_detailed_monitoring** | Enable detailed CloudWatch monitoring | `bool` | `true` | ❌ |
| **user_data_template** | Custom user data script template | `string` | `""` | ❌ |
| **tags** | Additional tags for all resources | `map(string)` | `{}` | ❌ |

##  **Outputs**

### Load Balancer
| Name | Description | Type |
|------|-------------|------|
| **alb_arn** | ARN of the Application Load Balancer | `string` |
| **alb_dns_name** | DNS name of the Application Load Balancer | `string` |
| **alb_zone_id** | Hosted zone ID of the Application Load Balancer | `string` |
| **application_url** | URL to access the application | `string` |
| **health_check_url** | Health check endpoint URL | `string` |

### Auto Scaling
| Name | Description | Type |
|------|-------------|------|
| **web_tier_asg_name** | Name of the web tier Auto Scaling Group | `string` |
| **web_tier_asg_arn** | ARN of the web tier Auto Scaling Group | `string` |
| **app_tier_asg_name** | Name of the app tier Auto Scaling Group | `string` |
| **app_tier_asg_arn** | ARN of the app tier Auto Scaling Group | `string` |

### Launch Templates
| Name | Description | Type |
|------|-------------|------|
| **web_tier_launch_template_id** | ID of the web tier launch template | `string` |
| **web_tier_launch_template_latest_version** | Latest version of the web tier launch template | `string` |
| **app_tier_launch_template_id** | ID of the app tier launch template | `string` |
| **app_tier_launch_template_latest_version** | Latest version of the app tier launch template | `string` |

### Target Groups
| Name | Description | Type |
|------|-------------|------|
| **web_tier_target_group_arn** | ARN of the web tier target group | `string` |
| **web_tier_target_group_name** | Name of the web tier target group | `string` |

### Scaling Policies
| Name | Description | Type |
|------|-------------|------|
| **web_tier_scale_up_policy_arn** | ARN of web tier scale up policy | `string` |
| **web_tier_scale_down_policy_arn** | ARN of web tier scale down policy | `string` |
| **app_tier_scale_up_policy_arn** | ARN of app tier scale up policy | `string` |
| **app_tier_scale_down_policy_arn** | ARN of app tier scale down policy | `string` |

### CloudWatch Alarms
| Name | Description | Type |
|------|-------------|------|
| **web_tier_high_cpu_alarm_arn** | ARN of web tier high CPU alarm | `string` |
| **web_tier_low_cpu_alarm_arn** | ARN of web tier low CPU alarm | `string` |
| **app_tier_high_cpu_alarm_arn** | ARN of app tier high CPU alarm | `string` |
| **app_tier_low_cpu_alarm_arn** | ARN of app tier low CPU alarm | `string` |

### Bastion Host
| Name | Description | Type |
|------|-------------|------|
| **bastion_instance_id** | ID of the bastion host instance | `string` |
| **bastion_public_ip** | Public IP of the bastion host | `string` |
| **bastion_private_ip** | Private IP of the bastion host | `string` |

### Configuration Summaries
| Name | Description | Type |
|------|-------------|------|
| **compute_configuration** | Summary of compute configuration | `object` |
| **auto_scaling_summary** | Auto scaling configuration summary | `object` |

##  **Auto Scaling Policies**

### Web Tier Scaling
- **Scale Up Trigger**: CPU utilization > 70% for 4 minutes (2 periods of 2 minutes)
- **Scale Down Trigger**: CPU utilization < 50% for 4 minutes
- **Scaling Action**: Add/remove 1 instance at a time
- **Cooldown Period**: 5 minutes between scaling actions
- **Capacity Range**: 2-6 instances (configurable)

### App Tier Scaling
- **Scale Up Trigger**: CPU utilization > 60% for 4 minutes
- **Scale Down Trigger**: CPU utilization < 40% for 4 minutes
- **Scaling Action**: Add/remove 1 instance at a time
- **Cooldown Period**: 5 minutes between scaling actions
- **Capacity Range**: 2-4 instances (configurable)

##  **Monitoring & Health Checks**

### Application Health Checks
- **Health Check Path**: `/health`
- **Health Check Interval**: 30 seconds
- **Healthy Threshold**: 2 consecutive successful checks
- **Unhealthy Threshold**: 3 consecutive failed checks
- **Timeout**: 5 seconds

### CloudWatch Metrics
- **CPU Utilization**: Auto-scaling trigger metric
- **Custom Metrics**: HTTP connections, memory usage
- **Log Groups**: HTTP access logs, error logs, application logs
- **Alarms**: High/low CPU for both web and app tiers

### Custom Monitoring
```bash
# Custom metrics collected every 5 minutes:
- HTTP Active Connections
- Memory Utilization Percentage
- Disk Usage Statistics
- Network I/O Statistics
```

##  **Cost Analysis**

### Monthly Cost Breakdown (US-East-1)

| Component | Configuration | Monthly Cost | Annual Cost |
|-----------|---------------|--------------|-------------|
| **Web Tier EC2** | t3.micro x 3 (avg) | $32 | $384 |
| **App Tier EC2** | t3.small x 2 (avg) | $34 | $408 |
| **Application LB** | Standard | $18 | $216 |
| **Bastion Host** | t3.micro x 1 | $11 | $132 |
| **EBS Storage** | 8GB x 6 instances | $5 | $60 |
| **Data Transfer** | 100GB/month | $9 | $108 |
| **CloudWatch** | Detailed monitoring | $15 | $180 |

### **Total Compute Cost**: $124-180/month

### Cost Optimization Strategies
| Strategy | Configuration | Monthly Savings | Use Case |
|----------|---------------|-----------------|----------|
| **Smaller Instances** | t3.micro for all tiers | $25-40 | Development/testing |
| **Disable Bastion** | `enable_bastion_host = false` | $11 | Cloud-only access |
| **Basic Monitoring** | `enable_detailed_monitoring = false` | $10-15 | Cost-sensitive environments |
| **Reserved Instances** | 1-year term | 30-40% | Predictable workloads |
| **Spot Instances** | Mixed instance policy | 50-70% | Fault-tolerant workloads |

## **Configuration Examples**

### Development Environment
```hcl
module "compute_dev" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "dev"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  
  # Cost optimization for development
  instance_types = {
    web_tier = "t3.micro"
    app_tier = "t3.micro"
    bastion  = "t3.micro"
  }
  
  auto_scaling_config = {
    web_tier = {
      min_size         = 1
      max_size         = 3
      desired_capacity = 1
      target_cpu       = 80
    }
    app_tier = {
      min_size         = 1
      max_size         = 2
      desired_capacity = 1
      target_cpu       = 75
    }
  }
  
  # Simplified ALB config
  alb_config = {
    enable_deletion_protection = false
    idle_timeout              = 60
    enable_http2              = true
    enable_waf                = false
    ssl_certificate_arn       = ""
  }
  
  enable_detailed_monitoring = false
  enable_bastion_host       = false
  
  tags = {
    Environment = "Development"
    CostCenter  = "Engineering"
  }
}
```

### High-Traffic Production
```hcl
module "compute_prod" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
  
  # High-performance instances
  instance_types = {
    web_tier = "t3.large"
    app_tier = "c5.xlarge"
    bastion  = "t3.micro"
  }
  
  # Aggressive scaling for high traffic
  auto_scaling_config = {
    web_tier = {
      min_size         = 4
      max_size         = 20
      desired_capacity = 6
      target_cpu       = 60
    }
    app_tier = {
      min_size         = 3
      max_size         = 12
      desired_capacity = 4
      target_cpu       = 50
    }
  }
  
  # Production ALB with SSL
  alb_config = {
    enable_deletion_protection = true
    idle_timeout              = 120
    enable_http2              = true
    enable_waf                = true
    ssl_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
  
  # Enhanced monitoring
  enable_detailed_monitoring = true
  enable_bastion_host       = true
  
  key_pair_name = "prod-keypair"
  
  tags = {
    Environment = "Production"
    Compliance  = "SOC2"
    Monitoring  = "Enhanced"
  }
}
```

##  **Testing & Validation**

### Pre-deployment Testing
```bash
# Validate Terraform configuration
terraform validate

# Test module with example configuration
terraform plan -var-file="compute.tfvars"

# Check launch template configuration
aws ec2 describe-launch-templates --launch-template-names "ecommerce-platform-prod-web-*"
```

### Post-deployment Testing
```bash
# Test Application Load Balancer
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -I http://$ALB_DNS/health

# Verify auto scaling groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw web_tier_asg_name)

# Test bastion host connectivity (if enabled)
BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i keypair.pem ec2-user@$BASTION_IP

# Monitor scaling events
aws autoscaling describe-scaling-activities --auto-scaling-group-name $(terraform output -raw web_tier_asg_name)
```

### Load Testing
```bash
# Install load testing tools
sudo yum install -y httpd-tools

# Generate load to trigger auto-scaling
ALB_DNS=$(terraform output -raw alb_dns_name)
ab -n 10000 -c 100 http://$ALB_DNS/

# Monitor scaling during load test
watch "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw web_tier_asg_name) --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize]' --output text"
```

##  **Monitoring & Alerting**

### Key Metrics to Monitor
- **Application Response Time**: Target < 200ms average
- **Auto Scaling Events**: Scale up/down frequency and timing
- **Instance Health**: Healthy vs unhealthy instances in target groups
- **CPU Utilization**: Per-instance and aggregate metrics
- **Network Latency**: ALB to instance communication
- **Error Rates**: HTTP 4xx/5xx response codes

### Recommended CloudWatch Dashboards
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "ecommerce-platform-prod-alb" ],
          [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "ecommerce-platform-prod-alb" ],
          [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "ecommerce-platform-prod-alb" ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "ALB Performance"
      }
    }
  ]
}
```

### Custom Alarms (Recommended)
```hcl
# High response time alarm
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-${var.environment}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.5"  # 500ms
  alarm_description   = "This metric monitors ALB response time"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
```

##  **Troubleshooting**

### Common Issues

| Issue | Symptoms | Cause | Solution |
|-------|----------|-------|----------|
| **Instances failing health checks** | Unhealthy targets in ALB | Application not responding on port 80 | Check security groups, verify web server status |
| **Auto scaling not working** | No scaling events during load | Incorrect CloudWatch alarms | Verify alarm thresholds and metrics |
| **High latency** | Slow application response | Insufficient instance resources | Scale up instance types or increase capacity |
| **SSL certificate issues** | Browser warnings | Incorrect certificate ARN | Verify certificate exists and ARN is correct |
| **Bastion host unreachable** | SSH connection timeout | Security group or network issues | Check security groups and network ACLs |

### Debugging Commands
```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecommerce-platform" --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' --output table

# Verify target group health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw web_tier_target_group_arn)

# Check auto scaling activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name $(terraform output -raw web_tier_asg_name) --max-items 10

# Review CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/ecommerce-platform"

# Test connectivity from bastion
ssh -i keypair.pem ec2-user@$(terraform output -raw bastion_public_ip) "curl -I http://PRIVATE_INSTANCE_IP"
```

### Performance Optimization
```bash
# Analyze instance performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=$(terraform output -raw web_tier_asg_name) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Check ALB performance metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=$(terraform output -raw alb_arn | cut -d'/' -f2-4) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

##  **Integration with Other Modules**

### VPC Module Integration
```hcl
module "compute" {
  source = "./modules/compute"
  
  # Use VPC module outputs
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}
```

### Security Module Integration
```hcl
module "compute" {
  source = "./modules/compute"
  
  # Use security module outputs
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
}
```

### Database Module Integration (Future)
```hcl
# Database connection will be configured via user data
locals {
  database_config = {
    endpoint = module.database.rds_endpoint
    port     = module.database.rds_port
    name     = module.database.database_name
  }
}

module "compute" {
  source = "./modules/compute"
  
  # Pass database configuration to user data
  user_data_template = templatefile("${path.module}/templates/user-data-with-db.sh", {
    project_name = var.project_name
    environment  = var.environment
    db_endpoint  = local.database_config.endpoint
    db_port      = local.database_config.port
    db_name      = local.database_config.name
  })
}
```

##  **Best Practices Implemented**

### ✅ High Availability
- **Multi-AZ Deployment**: Instances spread across multiple availability zones
- **Auto Scaling**: Automatic replacement of failed instances
- **Load Balancing**: Traffic distribution across healthy instances
- **Health Checks**: Application-level health monitoring

### ✅ Security
- **Security Group Integration**: Uses security groups from security module
- **Instance Metadata**: IMDSv2 enforced for enhanced security
- **Bastion Host**: Secure administrative access point
- **Private Subnets**: Application instances not directly accessible from internet

### ✅ Monitoring & Observability
- **CloudWatch Integration**: Comprehensive metrics and logging
- **Custom Metrics**: Application-specific monitoring
- **Detailed Monitoring**: Enhanced EC2 metrics when enabled
- **Log Aggregation**: Centralized logging for troubleshooting

### ✅ Cost Optimization
- **Right-Sizing**: Appropriate instance types for workload
- **Auto Scaling**: Pay only for needed capacity
- **Efficient Policies**: Smart scaling triggers to avoid thrashing
- **Configurable Monitoring**: Optional detailed monitoring for cost control

##  **User Data Script Features**

The included user data script provides:

### System Setup
- **Package Updates**: Automatic system package updates
- **Web Server**: Apache HTTP server installation and configuration
- **Monitoring**: CloudWatch agent setup with custom metrics

### Health Monitoring
- **Health Endpoint**: `/health` endpoint with JSON response
- **Instance Metadata**: Server information in health response
- **Custom Metrics**: HTTP connections and memory utilization
- **Log Collection**: Access and error log forwarding to CloudWatch

### Application Features
- **Welcome Page**: Professional landing page with instance information
- **Status Indicators**: Visual system status and deployment information
- **Performance Tracking**: Real-time performance metrics display

### Monitoring Configuration
```json
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
      "disk": ["used_percent"],
      "diskio": ["io_time", "read_bytes", "write_bytes"],
      "mem": ["mem_used_percent"],
      "netstat": ["tcp_established", "tcp_time_wait"],
      "swap": ["swap_used_percent"]
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/{project_name}/{environment}/httpd/access"
          },
          {
            "file_path": "/var/log/httpd/error_log", 
            "log_group_name": "/aws/ec2/{project_name}/{environment}/httpd/error"
          }
        ]
      }
    }
  }
}
```

##  **Scaling Scenarios**

### Traffic Spike Handling
```bash
# Normal Operation: 3 web instances, 2 app instances
# Traffic increases → CPU > 70% on web tier
# Action: Scale up web tier to 4 instances
# If traffic continues → Scale up to 5, then 6 instances
# App tier scales independently based on its 60% threshold
```

### Traffic Reduction
```bash  
# High traffic subsides → CPU < 50% on web tier
# Action: Scale down web tier to 2 instances (after 5-minute cooldown)
# Cost optimization: Automatically reduces infrastructure spend
```

### Failure Scenarios
```bash
# Instance failure detected by health check
# Action: Auto Scaling Group terminates unhealthy instance
# Action: Launches replacement instance in different AZ
# Result: Maintains desired capacity and high availability
```

##  **Security Features**

### Network Security
- **Private Instance Placement**: EC2 instances in private subnets only
- **Bastion Host Access**: Controlled SSH access through bastion host
- **Security Group Integration**: Leverages security module for proper isolation
- **Load Balancer Security**: ALB in public subnets with security group protection

### Instance Security  
- **IMDSv2 Enforcement**: Enhanced metadata service security
- **Key Pair Authentication**: SSH access requires proper key management
- **CloudWatch Agent**: Secure metrics and log collection
- **Automated Updates**: User data includes security patch installation

### Operational Security
- **Health Check Validation**: Ensures only healthy instances serve traffic
- **Auto Scaling Monitoring**: CloudWatch alarms track scaling events
- **Access Logging**: Complete HTTP access and error logging
- **Deletion Protection**: ALB deletion protection for production environments

##  **Performance Optimization**

### Instance Optimization
- **Right-Sized Instances**: t3.micro for development, scalable for production
- **Latest AMI**: Automatically uses latest Amazon Linux 2 AMI
- **Enhanced Monitoring**: Detailed CloudWatch metrics when enabled
- **Placement Groups**: Future enhancement for high-performance computing

### Load Balancer Optimization
- **HTTP/2 Support**: Enabled by default for better performance
- **Connection Draining**: Graceful connection handling during scaling
- **Health Check Tuning**: Balanced frequency for quick detection
- **SSL Optimization**: Modern security policies and certificate management

### Scaling Optimization
- **Predictive Scaling**: CPU-based with customizable thresholds
- **Cooldown Periods**: Prevents rapid scaling oscillations
- **Multi-Metric Support**: Ready for custom application metrics
- **Cost-Aware Scaling**: Configurable policies for cost optimization

## **Use Cases**

### E-commerce Applications
- **Variable Traffic**: Handles Black Friday / Cyber Monday traffic spikes
- **Geographic Distribution**: Multi-AZ deployment for global users
- **High Availability**: 99.9% uptime with automatic failover
- **Cost Efficiency**: Scales down during low-traffic periods

### Web Applications
- **Dynamic Content**: Application servers handle business logic
- **Static Assets**: Ready for CDN integration (future storage module)
- **User Sessions**: Stateless design supports horizontal scaling  
- **API Services**: RESTful API support with proper load balancing

### Development & Testing
- **Cost-Optimized**: Minimal instances for development environments
- **Quick Deployment**: Automated setup with user data scripts
- **Easy Access**: Bastion host for troubleshooting and maintenance
- **Monitoring**: Same monitoring stack as production for consistency

##  **Deployment Strategies**

### Blue-Green Deployments (Future Enhancement)
```hcl
# Multiple target groups for zero-downtime deployments
# Switch traffic between blue and green environments
# Requires additional ALB listener rules and target groups
```

### Rolling Updates
```hcl  
# Launch template versioning enables rolling updates
# Update launch template → Terminate old instances gradually
# Auto Scaling Group maintains capacity during updates
```

### Canary Deployments
```hcl
# Weighted routing for gradual traffic shifting
# Monitor new version performance before full deployment
# Quick rollback capability if issues detected
```

##  **Metrics & KPIs**

### Application Performance
- **Response Time**: < 200ms average (configurable alarm)
- **Throughput**: Requests per second handled by ALB
- **Error Rate**: HTTP 4xx/5xx response percentage  
- **Availability**: Percentage of healthy instances

### Infrastructure Efficiency  
- **CPU Utilization**: Target 60-70% average across instances
- **Memory Usage**: Custom CloudWatch metric monitoring
- **Network I/O**: Bandwidth utilization per instance
- **Storage IOPS**: EBS volume performance metrics

### Cost Optimization
- **Cost per Request**: Infrastructure cost divided by request volume
- **Scaling Efficiency**: Time to scale up/down during traffic changes
- **Resource Utilization**: Percentage of provisioned vs used capacity
- **Reserved Instance Coverage**: On-Demand vs Reserved instance ratio

##  **Future Enhancements**

### Planned Features
- **Spot Instance Integration**: Mixed instance types for cost savings
- **Predictive Scaling**: ML-based scaling predictions
- **Container Support**: ECS/Fargate integration options
- **Global Load Balancing**: Multi-region deployment support

### Advanced Monitoring
- **Application Performance Monitoring**: X-Ray integration
- **Custom Business Metrics**: Revenue/conversion tracking
- **Synthetic Monitoring**: Automated end-to-end testing
- **Log Analytics**: Enhanced log analysis and alerting

### Security Enhancements
- **WAF Integration**: Web Application Firewall rules
- **Certificate Management**: Automated SSL certificate renewal
- **Secrets Management**: Integration with AWS Secrets Manager
- **Vulnerability Scanning**: Automated security assessments

##  **Additional Resources**

- [AWS Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html)
- [Application Load Balancer Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [EC2 Launch Templates](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
- [CloudWatch Monitoring](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

##  **Frequently Asked Questions**

### Q: How do I customize the user data script?
A: Use the `user_data_template` variable to provide your own script, or modify the included `user-data.sh` file.

### Q: Can I use different instance types per AZ?
A: Currently, the module uses consistent instance types. For mixed instances, consider using mixed instance policies (future enhancement).

### Q: How do I add SSL certificates?
A: Set the `ssl_certificate_arn` in the `alb_config` object with your ACM certificate ARN.

### Q: What happens if an AZ goes down?
A: Auto Scaling Groups distribute instances across AZs. If one AZ fails, traffic routes to healthy instances in other AZs.

### Q: How do I scale based on custom metrics?
A: The module includes CloudWatch alarms for CPU. Add custom metric alarms and scaling policies for application-specific metrics.

### Q: Can I disable the bastion host?
A: Yes, set `enable_bastion_host = false` to save costs and use other access methods.

##  **Support & Troubleshooting**

### Getting Help
1. **Check the troubleshooting section** above for common issues
2. **Review AWS documentation** for service-specific problems  
3. **Use debugging commands** provided in this document
4. **Enable detailed monitoring** for better visibility during issues

### Performance Issues
1. **Check instance CPU/memory utilization** in CloudWatch
2. **Verify load balancer target health** and distribution
3. **Review auto scaling activity** for proper scaling behavior
4. **Analyze application logs** for bottlenecks

### Cost Optimization
1. **Review instance utilization** and right-size if needed
2. **Consider Reserved Instances** for predictable workloads
3. **Evaluate scaling policies** to avoid over-provisioning  
4. **Monitor data transfer costs** and optimize accordingly

##  **License**

This module is part of the AWS Scalable E-commerce Platform project and is licensed under the MIT License.

---

**Module Version**: 1.0.0  
**Last Updated**: December 2024  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: >= 5.0  
**Architecture**: Auto-Scaling Multi-Tier Web Application

**Maintained by**: DevOps Engineering Team  
**Documentation**: Comprehensive with examples and troubleshooting  
**Production Ready**: ✅ Tested and validated for enterprise use# Compute Infrastructure Module - Auto-Scaling Web Application

A comprehensive Terraform module for deploying auto-scaling compute infrastructure with Application Load Balancer, multi-tier EC2 instances, and comprehensive monitoring.

##  **Architecture Overview**

This module creates a robust, scalable compute environment:

```
                    Internet Gateway
                           │
                    ┌──────┴──────┐
                    │     ALB     │ ← Application Load Balancer
                    │   (Public)  │   SSL Termination & Health Checks
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
           AZ-1a        AZ-1b        AZ-1c
              │            │            │
      ┌───────┴──────┐ ┌───┴──────┐ ┌──┴─────┐
      │ Web Tier     │ │ Web Tier │ │Web Tier│
      │ Auto Scaling │ │Auto Scale│ │Auto Sc │ ← Web Servers (2-6 instances)
      │ Group        │ │Group     │ │Group   │   Target CPU: 70%
      └──────┬───────┘ └──────┬───┘ └───┬────┘
             │                │         │
             └────────────────┼─────────┘
                              │
      ┌─────────────────────────────────────────┐
      │           App Tier Auto Scaling         │ ← Application Servers (2-4 instances)
      │              Group                      │   Target CPU: 60%
      │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
      │  │App Server│ │App Server│ │App Serve│ │
      │  │          │ │          │ │         │ │
      │  └──────────┘ └──────────┘ └─────────┘ │
      └─────────────────────────────────────────┘
                              │
      ┌───────────────────────┴───────────────────┐
      │        Bastion Host (Optional)            │ ← SSH Access Point
      │         Public Subnet                     │
      └───────────────────────────────────────────┘
              │                 │
    ┌─────────┴───────┐ ┌───────┴────────┐
    │   CloudWatch    │ │  Auto Scaling  │
    │    Alarms       │ │   Policies     │ ← Monitoring & Scaling
    └─────────────────┘ └────────────────┘
```

##  **Key Features**

- ✅ **Application Load Balancer**: SSL termination, health checks, multi-AZ
- ✅ **Auto-Scaling Groups**: Web tier (2-6 instances) and App tier (2-4 instances)
- ✅ **Launch Templates**: Latest Amazon Linux 2 with CloudWatch agent
- ✅ **CloudWatch Monitoring**: CPU-based scaling with custom metrics
- ✅ **Health Checks**: Application-level health monitoring
- ✅ **Bastion Host**: Secure administrative access (optional)
- ✅ **Security Integration**: Uses security groups from security module
- ✅ **Cost Optimization**: Instance right-sizing and efficient scaling policies

## 🚀 **Quick Start**

### Basic Usage
```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  # Network configuration
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Security groups
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
}
```

### Production Configuration
```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  # Network configuration
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Security groups
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
  
  # Instance configuration
  instance_types = {
    web_tier = "t3.small"
    app_tier = "t3.medium"
    bastion  = "t3.micro"
  }
  
  # Auto scaling configuration
  auto_scaling_config = {
    web_tier = {
      min_size         = 3
      max_size         = 10
      desired_capacity = 4
      target_cpu       = 65
    }
    app_tier = {
      min_size         = 2
      max_size         = 6
      desired_capacity = 3
      target_cpu       = 55
    }
  }
  
  # Load balancer configuration
  alb_config = {
    enable_deletion_protection = true
    idle_timeout              = 120
    enable_http2              = true
    enable_waf                = true
    ssl_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
  
  # Monitoring
  enable_detailed_monitoring = true
  
  # Access
  key_pair_name      = "production-keypair"
  enable_bastion_host = true
  
  tags = {
    Owner       = "DevOps Team"
    Environment = "Production"
    Monitoring  = "Enhanced"
  }
}
```

##  **Input Variables**

### Core Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **project_name** | Name of the project for resource naming | `string` | n/a | ✅ |
| **environment** | Environment name (dev, staging, prod) | `string` | n/a | ✅ |
| **vpc_id** | ID of the VPC | `string` | n/a | ✅ |
| **public_subnet_ids** | List of public subnet IDs for ALB | `list(string)` | n/a | ✅ |
| **private_subnet_ids** | List of private subnet IDs for EC2 instances | `list(string)` | n/a | ✅ |

### Security Groups
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **alb_security_group_id** | Security group ID for Application Load Balancer | `string` | n/a | ✅ |
| **web_tier_security_group_id** | Security group ID for web tier instances | `string` | n/a | ✅ |
| **app_tier_security_group_id** | Security group ID for application tier instances | `string` | n/a | ✅ |
| **bastion_security_group_id** | Security group ID for bastion host | `string` | `null` | ❌ |

### Instance Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **instance_types** | EC2 instance types for different tiers | `object` | See below | ❌ |
| **ami_id** | AMI ID for EC2 instances (empty for latest Amazon Linux 2) | `string` | `""` | ❌ |
| **key_pair_name** | EC2 Key Pair name for SSH access | `string` | `""` | ❌ |

**Default instance_types:**
```hcl
{
  web_tier = "t3.micro"
  app_tier = "t3.small"
  bastion  = "t3.micro"
}
```

### Auto Scaling Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **auto_scaling_config** | Auto Scaling configuration for both tiers | `object` | See below | ❌ |

**Default auto_scaling_config:**
```hcl
{
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
```

### Load Balancer Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **alb_config** | Application Load Balancer configuration | `object` | See below | ❌ |
| **health_check_config** | Health check configuration for target groups | `object` | See below | ❌ |

**Default alb_config:**
```hcl
{
  enable_deletion_protection = true
  idle_timeout              = 60
  enable_http2              = true
  enable_waf                = false
  ssl_certificate_arn       = ""
}
```

### Monitoring & Access
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **enable_bastion_host** | Enable bastion host for secure access | `bool` | `true` | ❌ |
| **enable_detailed_monitoring** | Enable detailed CloudWatch monitoring | `bool` | `true` | ❌ |
| **user_data_template** | Custom user data script template | `string` | `""` | ❌ |
| **tags** | Additional tags for all resources | `map(string)` | `{}` | ❌ |

##  **Outputs**

### Load Balancer
| Name | Description | Type |
|------|-------------|------|
| **alb_arn** | ARN of the Application Load Balancer | `string` |
| **alb_dns_name** | DNS name of the Application Load Balancer | `string` |
| **alb_zone_id** | Hosted zone ID of the Application Load Balancer | `string` |
| **application_url** | URL to access the application | `string` |
| **health_check_url** | Health check endpoint URL | `string` |

### Auto Scaling
| Name | Description | Type |
|------|-------------|------|
| **web_tier_asg_name** | Name of the web tier Auto Scaling Group | `string` |
| **web_tier_asg_arn** | ARN of the web tier Auto Scaling Group | `string` |
| **app_tier_asg_name** | Name of the app tier Auto Scaling Group | `string` |
| **app_tier_asg_arn** | ARN of the app tier Auto Scaling Group | `string` |

### Launch Templates
| Name | Description | Type |
|------|-------------|------|
| **web_tier_launch_template_id** | ID of the web tier launch template | `string` |
| **app_tier_launch_template_id** | ID of the app tier launch template | `string` |

### Bastion Host
| Name | Description | Type |
|------|-------------|------|
| **bastion_instance_id** | ID of the bastion host instance | `string` |
| **bastion_public_ip** | Public IP of the bastion host | `string` |
| **bastion_private_ip** | Private IP of the bastion host | `string` |

### Configuration Summaries
| Name | Description | Type |
|------|-------------|------|
| **compute_configuration** | Summary of compute configuration | `object` |
| **auto_scaling_summary** | Auto scaling configuration summary | `object` |

##  **Auto Scaling Policies**

### Web Tier Scaling
- **Scale Up Trigger**: CPU utilization > 70% for 4 minutes (2 periods of 2 minutes)
- **Scale Down Trigger**: CPU utilization < 50% for 4 minutes
- **Scaling Action**: Add/remove 1 instance at a time
- **Cooldown Period**: 5 minutes between scaling actions
- **Capacity Range**: 2-6 instances (configurable)

### App Tier Scaling
- **Scale Up Trigger**: CPU utilization > 60% for 4 minutes
- **Scale Down Trigger**: CPU utilization < 40% for 4 minutes
- **Scaling Action**: Add/remove 1 instance at a time
- **Cooldown Period**: 5 minutes between scaling actions
- **Capacity Range**: 2-4 instances (configurable)

##  **Monitoring & Health Checks**

### Application Health Checks
- **Health Check Path**: `/health`
- **Health Check Interval**: 30 seconds
- **Healthy Threshold**: 2 consecutive successful checks
- **Unhealthy Threshold**: 3 consecutive failed checks
- **Timeout**: 5 seconds

### CloudWatch Metrics
- **CPU Utilization**: Auto-scaling trigger metric
- **Custom Metrics**: HTTP connections, memory usage
- **Log Groups**: HTTP access logs, error logs, application logs
- **Alarms**: High/low CPU for both web and app tiers

### Custom Monitoring
```bash
# Custom metrics collected every 5 minutes:
- HTTP Active Connections
- Memory Utilization Percentage
- Disk Usage Statistics
- Network I/O Statistics
```

##  **Cost Analysis**

### Monthly Cost Breakdown (US-East-1)

| Component | Configuration | Monthly Cost | Annual Cost |
|-----------|---------------|--------------|-------------|
| **Web Tier EC2** | t3.micro x 3 (avg) | $32 | $384 |
| **App Tier EC2** | t3.small x 2 (avg) | $34 | $408 |
| **Application LB** | Standard | $18 | $216 |
| **Bastion Host** | t3.micro x 1 | $11 | $132 |
| **EBS Storage** | 8GB x 6 instances | $5 | $60 |
| **Data Transfer** | 100GB/month | $9 | $108 |
| **CloudWatch** | Detailed monitoring | $15 | $180 |

### **Total Compute Cost**: $124-180/month

### Cost Optimization Strategies
| Strategy | Configuration | Monthly Savings | Use Case |
|----------|---------------|-----------------|----------|
| **Smaller Instances** | t3.micro for all tiers | $25-40 | Development/testing |
| **Disable Bastion** | `enable_bastion_host = false` | $11 | Cloud-only access |
| **Basic Monitoring** | `enable_detailed_monitoring = false` | $10-15 | Cost-sensitive environments |
| **Reserved Instances** | 1-year term | 30-40% | Predictable workloads |
| **Spot Instances** | Mixed instance policy | 50-70% | Fault-tolerant workloads |

##  **Configuration Examples**

### Development Environment
```hcl
module "compute_dev" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "dev"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  
  # Cost optimization for development
  instance_types = {
    web_tier = "t3.micro"
    app_tier = "t3.micro"
    bastion  = "t3.micro"
  }
  
  auto_scaling_config = {
    web_tier = {
      min_size         = 1
      max_size         = 3
      desired_capacity = 1
      target_cpu       = 80
    }
    app_tier = {
      min_size         = 1
      max_size         = 2
      desired_capacity = 1
      target_cpu       = 75
    }
  }
  
  # Simplified ALB config
  alb_config = {
    enable_deletion_protection = false
    idle_timeout              = 60
    enable_http2              = true
    enable_waf                = false
    ssl_certificate_arn       = ""
  }
  
  enable_detailed_monitoring = false
  enable_bastion_host       = false
  
  tags = {
    Environment = "Development"
    CostCenter  = "Engineering"
  }
}
```

### High-Traffic Production
```hcl
module "compute_prod" {
  source = "./modules/compute"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  alb_security_group_id      = module.security.alb_security_group_id
  web_tier_security_group_id = module.security.web_tier_security_group_id
  app_tier_security_group_id = module.security.app_tier_security_group_id
  bastion_security_group_id  = module.security.bastion_security_group_id
  
  # High-performance instances
  instance_types = {
    web_tier = "t3.large"
    app_tier = "c5.xlarge"
    bastion  = "t3.micro"
  }
  
  # Aggressive scaling for high traffic
  auto_scaling_config = {
    web_tier = {
      min_size         = 4
      max_size         = 20
      desired_capacity = 6
      target_cpu       = 60
    }
    app_tier = {
      min_size         = 3
      max_size         = 12
      desired_capacity = 4
      target_cpu       = 50
    }
  }
  
  # Production ALB with SSL
  alb_config = {
    enable_deletion_protection = true
    idle_timeout              = 120
    enable_http2              = true
    enable_waf                = true
    ssl_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
  
  # Enhanced monitoring
  enable_detailed_monitoring = true
  enable_bastion_host       = true
  
  key_pair_name = "prod-keypair"
  
  tags = {
    Environment = "Production"
    Compliance  = "SOC2"
    Monitoring  = "Enhanced"
  }
}
```

##  **Testing & Validation**

### Pre-deployment Testing
```bash
# Validate Terraform configuration
terraform validate

# Test module with example configuration
terraform plan -var-file="compute.tfvars"

# Check launch template configuration
aws ec2 describe-launch-templates --launch-template-names "ecommerce-platform-prod-web-*"
```

### Post-deployment Testing
```bash
# Test Application Load Balancer
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -I http://$ALB_DNS/health

# Verify auto scaling groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw web_tier_asg_name)

# Test bastion host connectivity (if enabled)
BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i keypair.pem ec2-user@$BASTION_IP

# Monitor scaling events
aws autoscaling describe-scaling-activities --auto-scaling-group-name $(terraform output -raw web_tier_asg_name)
```

### Load Testing
```bash
# Install load testing tools
sudo yum install -y httpd-tools

# Generate load to trigger auto-scaling
ALB_DNS=$(terraform output -raw alb_dns_