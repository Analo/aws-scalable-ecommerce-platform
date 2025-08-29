# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group"
  value       = aws_security_group.alb.id
}

output "web_tier_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web_tier.id
}

output "app_tier_security_group_id" {
  description = "ID of the application tier security group"
  value       = aws_security_group.app_tier.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "cache_security_group_id" {
  description = "ID of the cache security group"
  value       = aws_security_group.cache.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = var.enable_ssh_access ? aws_security_group.bastion[0].id : null
}

# Security Group ARNs
output "alb_security_group_arn" {
  description = "ARN of the Application Load Balancer security group"
  value       = aws_security_group.alb.arn
}

output "web_tier_security_group_arn" {
  description = "ARN of the web tier security group"
  value       = aws_security_group.web_tier.arn
}

output "app_tier_security_group_arn" {
  description = "ARN of the application tier security group"
  value       = aws_security_group.app_tier.arn
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.database.arn
}

output "cache_security_group_arn" {
  description = "ARN of the cache security group"
  value       = aws_security_group.cache.arn
}

# Network ACL Outputs
output "public_network_acl_id" {
  description = "ID of the public subnet network ACL"
  value       = var.enable_network_acls ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "ID of the private subnet network ACL"
  value       = var.enable_network_acls ? aws_network_acl.private[0].id : null
}

output "database_network_acl_id" {
  description = "ID of the database subnet network ACL"
  value       = var.enable_network_acls ? aws_network_acl.database[0].id : null
}

# VPC Flow Logs Outputs
output "flow_logs_log_group_name" {
  description = "Name of the CloudWatch log group for VPC flow logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "flow_logs_log_group_arn" {
  description = "ARN of the CloudWatch log group for VPC flow logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

output "flow_logs_iam_role_arn" {
  description = "ARN of the IAM role for VPC flow logs"
  value       = var.enable_flow_logs ? aws_iam_role.flow_logs[0].arn : null
}

# Security Summary
output "security_groups_summary" {
  description = "Summary of created security groups"
  value = {
    alb      = aws_security_group.alb.id
    web_tier = aws_security_group.web_tier.id
    app_tier = aws_security_group.app_tier.id
    database = aws_security_group.database.id
    cache    = aws_security_group.cache.id
    bastion  = var.enable_ssh_access ? aws_security_group.bastion[0].id : "disabled"
  }
}

output "network_acls_summary" {
  description = "Summary of created network ACLs"
  value = var.enable_network_acls ? {
    public   = aws_network_acl.public[0].id
    private  = aws_network_acl.private[0].id
    database = aws_network_acl.database[0].id
  } : {}
}

output "security_configuration" {
  description = "Complete security configuration summary"
  value = {
    ssh_enabled          = var.enable_ssh_access
    flow_logs_enabled    = var.enable_flow_logs
    network_acls_enabled = var.enable_network_acls
    waf_enabled          = var.enable_waf
    allowed_ports        = var.allowed_ports
    flow_logs_retention  = var.flow_logs_retention
  }
}