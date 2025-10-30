#!/bin/bash
# Antrea NSX-T Terraform Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Antrea NSX-T Terraform Deployment ===${NC}\n"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars not found. Creating from example...${NC}"
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${YELLOW}Please edit terraform.tfvars with your NSX-T credentials before continuing.${NC}"
        echo -e "${YELLOW}Required fields:${NC}"
        echo "  - nsx_manager"
        echo "  - nsx_username"
        echo "  - nsx_password"
        echo "  - cluster_control_plane_id"
        echo ""
        read -p "Press Enter after you've updated terraform.tfvars..."
    else
        echo -e "${RED}Error: terraform.tfvars.example not found!${NC}"
        exit 1
    fi
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed!${NC}"
    echo "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
fi

echo -e "${GREEN}Step 1: Initializing Terraform...${NC}"
terraform init

echo -e "\n${GREEN}Step 2: Validating configuration...${NC}"
terraform validate

echo -e "\n${GREEN}Step 3: Planning deployment...${NC}"
terraform plan -out=tfplan

echo -e "\n${YELLOW}Review the plan above.${NC}"
read -p "Do you want to apply this configuration? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Deployment cancelled.${NC}"
    rm -f tfplan
    exit 0
fi

echo -e "\n${GREEN}Step 4: Applying configuration...${NC}"
terraform apply tfplan

rm -f tfplan

echo -e "\n${GREEN}=== Deployment Complete ===${NC}"
echo -e "${GREEN}Security policy and rules have been created in NSX-T.${NC}\n"

echo -e "${YELLOW}To view the created resources:${NC}"
echo "  terraform state list"
echo ""
echo -e "${YELLOW}To view outputs:${NC}"
echo "  terraform output"
echo ""
echo -e "${YELLOW}To destroy resources:${NC}"
echo "  terraform destroy"

