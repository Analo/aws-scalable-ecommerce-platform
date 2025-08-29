# Security Module - Multi-Tier Network Security

A comprehensive Terraform module implementing enterprise-grade security controls for AWS multi-tier architecture with defense-in-depth strategy.

## 🔒 **Security Architecture**

This module implements a layered security approach with multiple security controls:

```
                    Internet Gateway
                           │
                    ┌──────┴──────┐
                    │   AWS WAF   │ ← Web Application Firewall
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │     ALB     │ ← Application Load Balancer
                    │   (SG: ALB) │   Security Group
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
           AZ-1a        AZ-1b        AZ-1c
              │            │            │
      ┌───────┴──────┐ ┌───┴──────┐ ┌──┴─────┐
      │ Public Subnet│ │Public Sub│ │Public  │
      │    NACL-1    │ │  NACL-1  │ │NACL-1  │ ← Network ACLs
      │ ┌──────────┐ │ │┌─────────┤ │┌──────┐│
      │ │Web Tier  │ │ ││Web Tier │ ││Web T ││
      │ │(SG: Web) │ │ ││(SG: Web)│ ││(SG:W)││ ← Security Groups
      │ └──────────┘ │ │└─────────┘ │└──────┘│
      └──────┬───────┘ └──────┬─────┘ └───┬───┘
             │                │           │
             └────────────────┼───────────┘
                              │
      ┌─────────────────────────────────────────┐
      │           Private Subnets               │
      │              NACL-2                     │ ← Network ACLs
      │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
      │  │App Tier  │ │App Tier  │ │App Tier │ │
      │  │(SG: App) │ │(SG: App) │ │(SG: App)│ │ ← Security Groups
      │  └──────────┘ └──────────┘ └─────────┘ │
      └─────────────────┬───────────────────────┘
                        │
      ┌─────────────────┴───────────────────────┐
      │          Database Subnets               │
      │              NACL-3                     │ ← Network ACLs
      │  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
      │  │Database │ │Database │ │Database  │  │
      │  │(SG: DB) │ │(SG: DB) │ │(SG: DB)  │  │ ← Security Groups
      │  └─────────┘ └─────────┘ └──────────┘  │
      └─────────────────────────────────────────┘
              │                 │
    ┌─────────┴───────┐ ┌───────┴────────┐
    │   VPC Flow      │ │  CloudWatch    │
    │     Logs        │ │    Alarms      │ ← Monitoring
    └─────────────────┘ └────────────────┘
```

## 🎯 **Key Security Features**

- ✅ **Defense in Depth**: Multiple layers of security controls
- ✅ **Zero Trust Network**: Least-privilege access between tiers
- ✅ **Security Groups**: Instance-level stateful firewalls
- ✅ **Network ACLs**: Subnet-level stateless firewalls
- ✅ **VPC Flow Logs**: Complete network traffic monitoring
- ✅ **WAF Ready**: Web application firewall integration support
- ✅ **Bastion Host**: Secure administrative access
- ✅ **SSH Hardening**: Configurable SSH access controls
- ✅ **Compliance Ready**: SOC 2, PCI DSS security patterns

## 🚀 **Quick Start**

### Basic Usage
```hcl
module "security" {
  source = "./modules/security"

  project_name = "ecommerce-platform"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr_block = "10.0.0.0/16"
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}
```

### Production Configuration
```hcl
module "security" {
  source = "./modules/security"

  project_name = "ecommerce-platform"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr_block = "10.0.0.0/16"
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  # Security hardening
  enable_ssh_access    = true
  office_ip_ranges     = ["203.0.113.0/24", "198.51.100.0/24"]  # Your office IPs
  enable_flow_logs     = true
  flow_logs_retention  = 90
  enable_network_acls  = true
  enable_waf           = true
  
  # Custom port configuration
  allowed_ports = {
    http         = 80
    https        = 443
    mysql        = 3306
    redis        = 6379
    ssh          = 22
    custom_app   = 8080
  }
  
  tags = {
    Owner       = "SecOps Team"
    Compliance  = "SOC2"
    Environment = "Production"
  }
}
```

## 📋 **Input Variables**

### Core Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **project_name** | Name of the project for resource naming | `string` | n/a | ✅ |
| **environment** | Environment name (dev, staging, prod) | `string` | n/a | ✅ |
| **vpc_id** | ID of the VPC where security groups will be created | `string` | n/a | ✅ |
| **vpc_cidr_block** | CIDR block of the VPC | `string` | n/a | ✅ |
| **public_subnet_cidrs** | CIDR blocks of public subnets | `list(string)` | n/a | ✅ |
| **private_subnet_cidrs** | CIDR blocks of private subnets | `list(string)` | n/a | ✅ |
| **database_subnet_cidrs** | CIDR blocks of database subnets | `list(string)` | n/a | ✅ |

### Security Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **enable_ssh_access** | Enable SSH access to instances | `bool` | `true` | ❌ |
| **ssh_cidr_blocks** | CIDR blocks allowed for SSH access | `list(string)` | `["0.0.0.0/0"]` | ❌ |
| **office_ip_ranges** | Office IP ranges for administrative access | `list(string)` | `[]` | ❌ |
| **enable_flow_logs** | Enable VPC Flow Logs for security monitoring | `bool` | `true` | ❌ |
| **flow_logs_retention** | CloudWatch logs retention period in days | `number` | `30` | ❌ |
| **enable_network_acls** | Enable custom Network ACLs | `bool` | `true` | ❌ |
| **enable_waf** | Enable AWS WAF for application protection | `bool` | `true` | ❌ |

### Port Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **allowed_ports** | Map of allowed ports for different services | `object` | See below | ❌ |

**Default allowed_ports:**
```hcl
{
  http         = 80
  https        = 443
  mysql        = 3306
  redis        = 6379
  ssh          = 22
  custom_app   = 8080
}
```

### Additional Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **tags** | Additional tags for all resources | `map(string)` | `{}` | ❌ |

## 📤 **Outputs**

### Security Group IDs
| Name | Description | Type |
|------|-------------|------|
| **alb_security_group_id** | ID of the Application Load Balancer security group | `string` |
| **web_tier_security_group_id** | ID of the web tier security group | `string` |
| **app_tier_security_group_id** | ID of the application tier security group | `string` |
| **database_security_group_id** | ID of the database security group | `string` |
| **cache_security_group_id** | ID of the cache security group | `string` |
| **bastion_security_group_id** | ID of the bastion host security group | `string` |

### Security Group ARNs
| Name | Description | Type |
|------|-------------|------|
| **alb_security_group_arn** | ARN of the ALB security group | `string` |
| **web_tier_security_group_arn** | ARN of the web tier security group | `string` |
| **app_tier_security_group_arn** | ARN of the app tier security group | `string` |
| **database_security_group_arn** | ARN of the database security group | `string` |
| **cache_security_group_arn** | ARN of the cache security group | `string` |

### Network ACLs
| Name | Description | Type |
|------|-------------|------|
| **public_network_acl_id** | ID of the public subnet network ACL | `string` |
| **private_network_acl_id** | ID of the private subnet network ACL | `string` |
| **database_network_acl_id** | ID of the database subnet network ACL | `string` |

### Monitoring & Logging
| Name | Description | Type |
|------|-------------|------|
| **flow_logs_log_group_name** | Name of the CloudWatch log group for VPC flow logs | `string` |
| **flow_logs_log_group_arn** | ARN of the CloudWatch log group for VPC flow logs | `string` |
| **flow_logs_iam_role_arn** | ARN of the IAM role for VPC flow logs | `string` |

### Summary Outputs
| Name | Description | Type |
|------|-------------|------|
| **security_groups_summary** | Summary of all created security groups | `object` |
| **network_acls_summary** | Summary of all created network ACLs | `object` |
| **security_configuration** | Complete security configuration summary | `object` |

## 🔒 **Security Groups Deep Dive**

### ALB Security Group
**Purpose**: Controls traffic to Application Load Balancer
- ✅ **Inbound**: HTTP (80), HTTPS (443) from internet (0.0.0.0/0)
- ✅ **Outbound**: HTTP, HTTPS, Custom App Port to Web Tier only

### Web Tier Security Group  
**Purpose**: Controls traffic to web servers
- ✅ **Inbound**: HTTP, HTTPS, Custom App Port from ALB only
- ✅ **Inbound**: SSH from office IPs or bastion (if enabled)
- ✅ **Outbound**: Custom App Port to App Tier, HTTPS for updates

### Application Tier Security Group
**Purpose**: Controls traffic to application servers
- ✅ **Inbound**: Custom App Port from Web Tier only
- ✅ **Inbound**: SSH from office IPs or bastion (if enabled)
- ✅ **Outbound**: MySQL to Database, Redis to Cache, HTTPS for APIs

### Database Security Group
**Purpose**: Controls traffic to database instances
- ✅ **Inbound**: MySQL (3306) from App Tier only
- ❌ **Outbound**: No outbound rules (databases shouldn't initiate connections)

### Cache Security Group
**Purpose**: Controls traffic to Redis/ElastiCache
- ✅ **Inbound**: Redis (6379) from App Tier only
- ❌ **Outbound**: No outbound rules needed

### Bastion Security Group
**Purpose**: Secure administrative access (when enabled)
- ✅ **Inbound**: SSH from office IP ranges only
- ✅ **Outbound**: SSH to private subnets, HTTPS for updates

## 🛡️ **Network ACLs (NACLs)**

### Public Subnet NACLs
**Additional subnet-level protection for public resources**
- ✅ **Inbound**: HTTP (80), HTTPS (443), SSH (22), Ephemeral Ports (1024-65535)
- ✅ **Outbound**: HTTP, HTTPS to internet, Custom App Port to VPC, Ephemeral Ports

### Private Subnet NACLs  
**Protection for application tier**
- ✅ **Inbound**: Custom App Port from VPC, SSH from VPC, Ephemeral Ports
- ✅ **Outbound**: HTTP/HTTPS to internet, MySQL/Redis to VPC, Ephemeral Ports

### Database Subnet NACLs
**Maximum protection for data tier**
- ✅ **Inbound**: MySQL (3306), Redis (6379) from VPC only, Ephemeral Ports
- ✅ **Outbound**: Ephemeral Ports to VPC only (return traffic)

## 📊 **VPC Flow Logs**

### What Gets Logged
- ✅ **All Network Traffic**: Accepted, rejected, and all traffic
- ✅ **Source & Destination**: IPs, ports, protocols
- ✅ **Traffic Metadata**: Bytes, packets, time windows
- ✅ **Security Actions**: Accept/reject decisions

### Log Format
```
account_id interface_id srcaddr dstaddr srcport dstport protocol packets bytes windowstart windowend action flowlogstatus
```

### Retention & Storage
- **Default Retention**: 30 days (configurable: 1-3653 days)
- **Storage**: CloudWatch Logs with encryption
- **Cost**: ~$0.50 per GB ingested + storage costs

## 💰 **Cost Analysis**

### Monthly Cost Breakdown (US-East-1)

| Component | Configuration | Monthly Cost | Annual Cost |
|-----------|---------------|--------------|-------------|
| **Security Groups** | 6 groups, unlimited rules | $0.00 | $0.00 |
| **Network ACLs** | 3 ACLs, ~20 rules each | $0.00 | $0.00 |
| **VPC Flow Logs** | All traffic, 30-day retention | $15-50 | $180-600 |
| **CloudWatch Logs** | Flow logs storage | $5-20 | $60-240 |
| **NAT Gateway Data** | Processing charges | $4.50/100GB | $54/TB |
| **WAF (if enabled)** | Web ACL + rules | $5-25 | $60-300 |

### **Total Security Cost**: $25-120/month

### Cost Optimization Strategies
| Strategy | Configuration | Monthly Savings | Use Case |
|----------|---------------|-----------------|----------|
| **Disable Flow Logs** | `enable_flow_logs = false` | $15-50 | Development environments |
| **Shorter Retention** | `flow_logs_retention = 7` | $10-30 | Non-compliance workloads |
| **Disable NACLs** | `enable_network_acls = false` | $0 | Trust security groups only |
| **Office IP Restriction** | Set `office_ip_ranges` | $0* | Improved security posture |

*Doesn't reduce costs but improves security

## 🔧 **Configuration Examples**

### Development Environment
```hcl
module "security_dev" {
  source = "./modules/security"

  project_name = "ecommerce-platform"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr_block = "10.1.0.0/16"
  
  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
  database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24"]
  
  # Cost optimization for development
  enable_flow_logs     = false
  enable_network_acls  = false
  enable_waf          = false
  flow_logs_retention = 7
  
  # Relaxed SSH access for development
  ssh_cidr_blocks = ["0.0.0.0/0"]
  
  tags = {
    Environment = "Development"
    CostCenter  = "Engineering"
  }
}
```

### Production Environment
```hcl
module "security_prod" {
  source = "./modules/security"

  project_name = "ecommerce-platform"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr_block = "10.0.0.0/16"
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  # Maximum security for production
  enable_flow_logs     = true
  enable_network_acls  = true
  enable_waf          = true
  flow_logs_retention = 90
  
  # Restricted access
  office_ip_ranges = [
    "203.0.113.0/24",  # Office Network 1
    "198.51.100.0/24"  # Office Network 2
  ]
  
  tags = {
    Environment = "Production"
    Compliance  = "SOC2-PCI"
    DataClass   = "Confidential"
  }
}
```

### Multi-Environment with Different Security Levels
```hcl
# High-security production
module "security_prod" {
  source = "./modules/security"
  
  # ... configuration ...
  
  enable_flow_logs     = true
  enable_network_acls  = true
  flow_logs_retention = 365  # 1 year for compliance
  office_ip_ranges    = var.office_networks
}

# Medium-security staging
module "security_staging" {
  source = "./modules/security"
  
  # ... configuration ...
  
  enable_flow_logs     = true
  enable_network_acls  = false
  flow_logs_retention = 30
  office_ip_ranges    = var.office_networks
}

# Low-security development
module "security_dev" {
  source = "./modules/security"
  
  # ... configuration ...
  
  enable_flow_logs     = false
  enable_network_acls  = false
  ssh_cidr_blocks     = ["0.0.0.0/0"]  # Development only!
}
```

## 🧪 **Testing & Validation**

### Pre-deployment Validation
```bash
# Validate Terraform configuration
terraform validate

# Check security group rules
terraform plan -target=module.security

# Validate variable inputs
terraform plan -var-file="security.tfvars"
```

### Post-deployment Security Tests
```bash
# Test connectivity between tiers
aws ec2 describe-security-groups --group-ids $(terraform output -raw web_tier_security_group_id)

# Verify flow logs are working
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flow-logs"

# Check Network ACL rules
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Test security group rules
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"
```

### Security Compliance Validation
```bash
# Check for unrestricted SSH access
aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?FromPort==`22` && IpRanges[?CidrIp==`0.0.0.0/0`]]]'

# Verify database isolation
aws ec2 describe-security-groups --group-ids $(terraform output -raw database_security_group_id)

# Check flow logs configuration
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$(terraform output -raw vpc_id)"
```

## 🔍 **Security Monitoring**

### Key Metrics to Monitor
- **Failed Connection Attempts**: Rejected traffic in flow logs
- **Unusual Traffic Patterns**: Unexpected source/destination combinations  
- **SSH Access**: All SSH connections and attempts
- **Database Connections**: Direct database access attempts
- **Port Scanning**: Sequential port access attempts

### CloudWatch Alarms (Recommended)
```hcl
# Example: SSH brute force detection
resource "aws_cloudwatch_log_metric_filter" "ssh_brute_force" {
  name           = "ssh-brute-force-attempts"
  log_group_name = module.security.flow_logs_log_group_name
  
  pattern = "[version, account, eni, source, destination=\"*\", srcport, destport=\"22\", protocol=\"6\", packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"
  
  metric_transformation {
    name      = "SSHBruteForceAttempts"
    namespace = "Security/VPC"
    value     = "1"
  }
}
```

## 🔧 **Troubleshooting**

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **Can't SSH to instances** | Security group blocks SSH | Check SSH ingress rules and source IPs |
| **Web tier can't reach app tier** | Missing security group reference | Verify security group references in rules |
| **Database connection fails** | Security group misconfiguration | Check MySQL port (3306) from app tier |
| **Flow logs not appearing** | IAM permissions or log group issues | Verify IAM role and CloudWatch permissions |
| **High data transfer costs** | Inefficient security group rules | Review and optimize outbound rules |

### Debugging Commands
```bash
# Check security group effective rules
aws ec2 describe-security-group-rules --group-ids sg-xxxxxxxxx

# Test network connectivity
aws ec2 describe-vpc-endpoint-connections --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"

# Review flow logs
aws logs get-log-events --log-group-name "/aws/vpc/flow-logs/ecommerce-platform-prod" --log-stream-name "eni-xxxxxxxxx-all"

# Validate NACL rules
aws ec2 describe-network-acls --network-acl-ids acl-xxxxxxxxx
```

### Security Incident Response
```bash
# Emergency: Block suspicious IP
aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxxxx --protocol tcp --port 0-65535 --source-group sg-xxxxxxxxx

# Review recent security events
aws logs filter-log-events --log-group-name "/aws/vpc/flow-logs/ecommerce-platform-prod" --start-time $(date -d "1 hour ago" +%s)000

# Export security configuration for analysis
terraform show -json | jq '.values.root_module.child_modules[] | select(.address=="module.security")'
```

## 🤝 **Integration with Other Modules**

### VPC Module Integration
```hcl
module "security" {
  source = "./modules/security"
  
  # Use VPC module outputs
  vpc_id                = module.vpc.vpc_id
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  public_subnet_cidrs   = module.vpc.public_subnet_cidr_blocks
  private_subnet_cidrs  = module.vpc.private_subnet_cidr_blocks
  database_subnet_cidrs = module.vpc.database_subnet_cidr_blocks
}
```

### Compute Module Integration
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

### Database Module Integration
```hcl
module "database" {
  source = "./modules/database"
  
  # Use security module outputs
  database_security_group_id = module.security.database_security_group_id
  cache_security_group_id    = module.security.cache_security_group_id
}
```

## 📚 **Security Best Practices Implemented**

### ✅ Network Security
- **Principle of Least Privilege**: Minimal required access only
- **Defense in Depth**: Multiple security layers (SG + NACL)
- **Network Segmentation**: Isolated tiers with controlled communication
- **Zero Trust**: No implicit trust between network segments

### ✅ Access Control
- **Restricted SSH**: Office IP ranges or bastion host only
- **Service-to-Service**: Security group references instead of CIDR blocks
- **Database Isolation**: No direct internet access to database tier
- **Administrative Access**: Controlled through bastion host

### ✅ Monitoring & Logging
- **Complete Visibility**: VPC Flow Logs for all network traffic
- **Retention Policies**: Configurable log retention for compliance
- **Real-time Monitoring**: CloudWatch integration for alerts
- **Audit Trail**: All network access attempts logged

### ✅ Compliance Support
- **SOC 2 Ready**: Network controls and monitoring in place
- **PCI DSS Support**: Database isolation and encryption in transit
- **GDPR Considerations**: Data flow visibility and control
- **Industry Standards**: CIS Benchmarks compliance patterns

## 📖 **Additional Resources**

- [AWS VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Security Groups vs NACLs](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [CIS AWS Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)

## 📄 **License**

This module is part of the AWS Scalable E-commerce Platform project and is licensed under the MIT License.

---