#!/bin/bash
# User Data Script for EC2 Instances
# Configures instances with monitoring and basic web server

# Update system packages
yum update -y

# Install required packages
yum install -y httpd amazon-cloudwatch-agent htop git

# Start and enable httpd
systemctl start httpd
systemctl enable httpd

# Create a simple health check page
cat > /var/www/html/health <<EOF
{
  "status": "healthy",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "server": "$(hostname)",
  "project": "${project_name}",
  "environment": "${environment}"
}
EOF

# Create a simple index page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 20px; }
        .info { margin: 20px 0; }
        .status { background: #2ecc71; color: white; padding: 10px; border-radius: 4px; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛒 AWS Scalable E-commerce Platform</h1>
            <h2>Environment: ${environment}</h2>
        </div>
        <div class="info">
            <div class="status">✅ System Status: Operational</div>
            <p><strong>Server:</strong> $(hostname)</p>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
            <p><strong>Deployment Time:</strong> $(date)</p>
        </div>
        <div class="info">
            <h3>🎯 Project Features:</h3>
            <ul>
                <li>✅ Auto-scaling EC2 instances</li>
                <li>✅ Application Load Balancer</li>
                <li>✅ Multi-AZ deployment</li>
                <li>✅ CloudWatch monitoring</li>
                <li>✅ Security group protection</li>
                <li>✅ Health check endpoints</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "diskio": {
        "measurement": [
          "io_time",
          "read_bytes",
          "write_bytes",
          "reads",
          "writes"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/${project_name}/${environment}/httpd/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/${project_name}/${environment}/httpd/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 644 /var/www/html

# Enable CloudWatch agent on boot
systemctl enable amazon-cloudwatch-agent

# Create custom metrics script
cat > /usr/local/bin/custom-metrics.sh <<'EOL'
#!/bin/bash
# Custom CloudWatch metrics

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# HTTP connection count
HTTP_CONNECTIONS=$(netstat -an | grep :80 | grep ESTABLISHED | wc -l)
aws cloudwatch put-metric-data --region $REGION --namespace "Custom/HTTP" --metric-data MetricName=ActiveConnections,Value=$HTTP_CONNECTIONS,Unit=Count,Dimensions=InstanceId=$INSTANCE_ID

# Memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
aws cloudwatch put-metric-data --region $REGION --namespace "Custom/Memory" --metric-data MetricName=MemoryUtilization,Value=$MEMORY_USAGE,Unit=Percent,Dimensions=InstanceId=$INSTANCE_ID
EOL

chmod +x /usr/local/bin/custom-metrics.sh

# Add cron job for custom metrics
echo "*/5 * * * * /usr/local/bin/custom-metrics.sh" | crontab -

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log