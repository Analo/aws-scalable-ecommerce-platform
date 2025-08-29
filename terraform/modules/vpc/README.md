# VPC Network Infrastructure Module

A production-ready Terraform module for creating AWS VPC with multi-tier architecture, high availability, and enterprise-grade networking features.

## **Architecture Overview**

This module creates a secure, scalable network foundation with:

```
                            Internet Gateway
                                   │
                        ┌──────────┴──────────┐
                        │        VPC          │
                        │   (10.0.0.0/16)     │
                        └──────────┬──────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                 AZ-1a           AZ-1b          AZ-1c
                    │              │              │
            ┌───────┴─────┐ ┌──────┴──────┐ ┌────┴──────┐
            │Public Subnet│ │Public Subnet│ │Public Sub │
            │10.0.1.0/24  │ │10.0.2.0/24  │ │10.0.3.0/24│
            └─────┬───────┘ └──────┬──────┘ └─────┬─────┘
                  │                │              │
            ┌─────▼─────┐    ┌─────▼─────┐  ┌─────▼─────┐
            │NAT Gateway│    │NAT Gateway│  │NAT Gateway│
            └─────┬─────┘    └─────┬─────┘  └─────┬─────┘
                  │                │              │
        ┌─────────▼────────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │Private Subnet    │ │Private Sub│ │Private Sub  │
        │(App Tier)        │ │(App Tier) │ │(App Tier)   │
        │10.0.11.0/24      │ │10.0.12/24 │ │10.0.13.0/24 │
        └──────────────────┘ └───────────┘ └─────────────┘
                  │                │              │
        ┌─────────▼────────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │Database Subnet   │ │Database   │ │Database     │
        │(Data Tier)       │ │Subnet     │ │Subnet       │
        │10.0.21.0/24      │ │10.0.22/24 │ │10.0.23.0/24 │
        └──────────────────┘ └───────────┘ └─────────────┘
```

##  **Key Features**

- ✅ **Multi-AZ Deployment**: High availability across 3 availability zones
- ✅ **3-Tier Network Architecture**: Public, private (app), and database subnets
- ✅ **Flexible NAT Strategy**: Single or multiple NAT gateways for cost optimization
- ✅ **Internet Connectivity**: Internet Gateway for public subnets
- ✅ **Private Network Access**: NAT Gateways for private subnet internet access
- ✅ **Database Isolation**: Dedicated database subnets with no internet access
- ✅ **VPN Ready**: Optional VPN gateway for hybrid cloud connectivity
- ✅ **DNS Support**: Configurable DNS hostnames and resolution
- ✅ **Comprehensive Tagging**: Consistent resource tagging strategy
- ✅ **Route Table Management**: Automatic routing configuration

##  **Quick Start**

### Basic Usage
```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name = "ecommerce-platform"
  environment  = "prod"
  
  tags = {
    Owner      = "DevOps Team"
    CostCenter = "Engineering"
  }
}
```

### Advanced Configuration
```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name    = "ecommerce-platform"
  environment     = "prod"
  vpc_cidr        = "10.0.0.0/16"
  
  availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false  # Use multiple NAT gateways for HA
  enable_vpn_gateway = true   # Enable VPN for hybrid connectivity
  
  tags = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Environment = "Production"
  }
}
```

##  **Input Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **project_name** | Name of the project for resource naming | `string` | n/a | ✅ |
| **environment** | Environment name (dev, staging, prod) | `string` | n/a | ✅ |
| **vpc_cidr** | CIDR block for VPC | `string` | `"10.0.0.0/16"` | ❌ |
| **availability_zones** | List of availability zones to use | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | ❌ |
| **public_subnet_cidrs** | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | ❌ |
| **private_subnet_cidrs** | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | ❌ |
| **database_subnet_cidrs** | CIDR blocks for database subnets | `list(string)` | `["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]` | ❌ |
| **enable_nat_gateway** | Enable NAT Gateway for private subnets | `bool` | `true` | ❌ |
| **single_nat_gateway** | Use single NAT Gateway (cost optimization) | `bool` | `false` | ❌ |
| **enable_vpn_gateway** | Enable VPN Gateway for hybrid connectivity | `bool` | `false` | ❌ |
| **enable_dns_hostnames** | Enable DNS hostnames in VPC | `bool` | `true` | ❌ |
| **enable_dns_support** | Enable DNS support in VPC | `bool` | `true` | ❌ |
| **tags** | Additional tags for all resources | `map(string)` | `{}` | ❌ |

## 📤 **Outputs**

### VPC Information
| Name | Description | Type |
|------|-------------|------|
| **vpc_id** | ID of the VPC | `string` |
| **vpc_cidr_block** | CIDR block of the VPC | `string` |
| **vpc_arn** | ARN of the VPC | `string` |
| **internet_gateway_id** | ID of the Internet Gateway | `string` |

### Subnet Information
| Name | Description | Type |
|------|-------------|------|
| **public_subnet_ids** | List of IDs of the public subnets | `list(string)` |
| **public_subnet_arns** | List of ARNs of the public subnets | `list(string)` |
| **public_subnet_cidr_blocks** | List of CIDR blocks of the public subnets | `list(string)` |
| **private_subnet_ids** | List of IDs of the private subnets | `list(string)` |
| **private_subnet_arns** | List of ARNs of the private subnets | `list(string)` |
| **private_subnet_cidr_blocks** | List of CIDR blocks of the private subnets | `list(string)` |
| **database_subnet_ids** | List of IDs of the database subnets | `list(string)` |
| **database_subnet_group_name** | Name of the database subnet group | `string` |

### Network Connectivity
| Name | Description | Type |
|------|-------------|------|
| **nat_gateway_ids** | List of IDs of the NAT Gateways | `list(string)` |
| **nat_public_ips** | List of public Elastic IPs for NAT Gateways | `list(string)` |
| **public_route_table_id** | ID of the public route table | `string` |
| **private_route_table_ids** | List of IDs of the private route tables | `list(string)` |
| **database_route_table_id** | ID of the database route table | `string` |
| **availability_zones** | List of availability zones used | `list(string)` |
| **vpn_gateway_id** | ID of the VPN Gateway (if enabled) | `string` |

##  **Cost Analysis**

### Monthly Cost Breakdown (US-East-1)

| Component | Configuration | Quantity | Monthly Cost | Annual Cost |
|-----------|---------------|----------|--------------|-------------|
| **VPC** | Standard | 1 | $0.00 | $0.00 |
| **Internet Gateway** | Standard | 1 | $0.00 | $0.00 |
| **NAT Gateway (Single)** | Standard | 1 | $32.85 | $394.20 |
| **NAT Gateway (Multi-AZ)** | Standard | 3 | $98.55 | $1,182.60 |
| **Elastic IPs** | NAT Gateway | 1-3 | $0.00* | $0.00* |
| **Data Processing** | NAT Gateway | 100GB | $4.50 | $54.00 |
| **VPN Gateway** | Standard | 1 | $36.50 | $438.00 |

*Free when associated with running NAT Gateway*

### Cost Optimization Strategies

| Strategy | Configuration | Monthly Savings | Use Case |
|----------|---------------|-----------------|----------|
| **Single NAT Gateway** | `single_nat_gateway = true` | ~$65/month | Development, Testing |
| **No VPN Gateway** | `enable_vpn_gateway = false` | ~$37/month | Cloud-only workloads |
| **Right-sized Subnets** | Custom CIDR blocks | Variable | Specific requirements |
| **Regional Selection** | Non-US regions | 10-20% | Global deployments |

### **Total Estimated Costs**
- **Development Environment**: $37-42/month
- **Staging Environment**: $70-75/month  
- **Production Environment**: $135-140/month

##  **Security Features**

### Network Isolation
- **Public Subnets**: Direct internet access via Internet Gateway
- **Private Subnets**: Internet access only through NAT Gateways
- **Database Subnets**: Completely isolated from internet access
- **Route Table Segregation**: Separate routing for each tier

### Access Control
- **Security Groups**: Applied at instance level (configured in other modules)
- **Network ACLs**: Subnet-level filtering (can be extended)
- **VPC Flow Logs**: Available for monitoring (can be enabled)

### Best Practices Implemented
- ✅ Multi-AZ deployment for fault tolerance
- ✅ Subnet segregation by application tier
- ✅ NAT Gateways in public subnets for private subnet access
- ✅ Database subnets without internet gateway routing
- ✅ Consistent resource tagging for governance

##  **Testing & Validation**

### Pre-deployment Validation
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan deployment
terraform plan -var-file="terraform.tfvars"
```

### Post-deployment Testing
```bash
# Test VPC creation
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)

# Verify subnet creation
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Check NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Validate internet connectivity from private subnet (requires EC2 instance)
# This would be tested in the compute module
```

## 🔧 **Troubleshooting**

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **NAT Gateway creation fails** | No Elastic IP available | Increase EIP limit or use single NAT |
| **Subnet creation fails** | CIDR conflicts | Ensure non-overlapping CIDR blocks |
| **Route table errors** | Dependency issues | Apply with `-parallelism=1` |
| **VPN Gateway timeout** | AWS provisioning delay | Increase timeout or retry |

### Debugging Commands
```bash
# Check resource status
terraform show
terraform state list

# Validate configuration
terraform validate
terraform plan

# Debug specific resources
terraform state show module.vpc.aws_vpc.main
terraform state show module.vpc.aws_nat_gateway.main
```

##  **Examples**

### Development Environment
```hcl
module "vpc_dev" {
  source = "./modules/vpc"

  project_name = "ecommerce-platform"
  environment  = "dev"
  vpc_cidr     = "10.1.0.0/16"
  
  # Cost optimization for development
  single_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Environment = "Development"
    Owner       = "DevOps Team"
  }
}
```

### Production Environment
```hcl
module "vpc_prod" {
  source = "./modules/vpc"

  project_name = "ecommerce-platform"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"
  
  # High availability for production
  single_nat_gateway = false
  enable_vpn_gateway = true
  
  tags = {
    Environment = "Production"
    Owner       = "DevOps Team"
    Compliance  = "Required"
  }
}
```

### Custom Network Configuration
```hcl
module "vpc_custom" {
  source = "./modules/vpc"

  project_name    = "ecommerce-platform"
  environment     = "staging"
  vpc_cidr        = "172.16.0.0/16"
  
  # Custom subnet configuration
  availability_zones     = ["us-west-2a", "us-west-2b"]
  public_subnet_cidrs    = ["172.16.1.0/24", "172.16.2.0/24"]
  private_subnet_cidrs   = ["172.16.11.0/24", "172.16.12.0/24"]
  database_subnet_cidrs  = ["172.16.21.0/24", "172.16.22.0/24"]
  
  tags = {
    Environment = "Staging"
    Owner       = "DevOps Team"
  }
}
```

##  **Integration with Other Modules**

### Security Module Integration
```hcl
# Use VPC outputs in security module
module "security" {
  source = "./modules/security"
  
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  database_subnet_ids   = module.vpc.database_subnet_ids
}
```

### Compute Module Integration
```hcl
# Use VPC outputs in compute module
module "compute" {
  source = "./modules/compute"
  
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}
```

### Database Module Integration
```hcl
# Use VPC outputs in database module
module "database" {
  source = "./modules/database"
  
  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
}
```

##  **Additional Resources**

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Network ACLs vs Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)

##  **License**

This module is part of the AWS Scalable E-commerce Platform project and is licensed under the MIT License.

---
