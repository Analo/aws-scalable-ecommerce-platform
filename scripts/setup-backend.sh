#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Terraform Backend Infrastructure${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure'.${NC}"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Initialize and apply backend
cd terraform/backend

echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo -e "${YELLOW}Planning backend infrastructure...${NC}"
terraform plan -out=tfplan

echo -e "${YELLOW}Applying backend infrastructure...${NC}"
terraform apply tfplan

# Get outputs
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

echo -e "${GREEN}🎉 Backend infrastructure created successfully!${NC}"
echo -e "${BLUE}📝 Backend Configuration:${NC}"
echo -e "S3 Bucket: ${S3_BUCKET}"
echo -e "DynamoDB Table: ${DYNAMODB_TABLE}"

# Create backend config template
cat > ../backend-config.hcl << EOF
# Backend configuration for main infrastructure
# Copy this to your terraform block

terraform {
  backend "s3" {
    bucket         = "${S3_BUCKET}"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${DYNAMODB_TABLE}"
    encrypt        = true
  }
}
EOF

echo -e "${GREEN}✅ Backend configuration saved to terraform/backend-config.hcl${NC}"