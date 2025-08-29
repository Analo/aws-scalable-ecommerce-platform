variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks of database subnets"
  type        = list(string)
}

variable "enable_ssh_access" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = length(var.ssh_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified for SSH access."
  }
}

variable "allowed_ports" {
  description = "Map of allowed ports for different services"
  type = object({
    http         = number
    https        = number
    mysql        = number
    redis        = number
    ssh          = number
    custom_app   = number
  })
  default = {
    http         = 80
    https        = 443
    mysql        = 3306
    redis        = 6379
    ssh          = 22
    custom_app   = 8080
  }
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_retention" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention)
    error_message = "Flow logs retention must be a valid CloudWatch logs retention period."
  }
}

variable "enable_waf" {
  description = "Enable AWS WAF for application protection"
  type        = bool
  default     = true
}

variable "enable_network_acls" {
  description = "Enable custom Network ACLs for additional security"
  type        = bool
  default     = true
}

variable "office_ip_ranges" {
  description = "Office IP ranges for administrative access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}