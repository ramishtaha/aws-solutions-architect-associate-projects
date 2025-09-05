#!/bin/bash
# Automated VPC Setup Script for WordPress Project
# This script creates the complete VPC infrastructure for the WordPress project

set -e

# Configuration variables
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_A_CIDR="10.0.1.0/24"
PUBLIC_SUBNET_B_CIDR="10.0.2.0/24"
PRIVATE_SUBNET_A_CIDR="10.0.3.0/24"
PRIVATE_SUBNET_B_CIDR="10.0.4.0/24"
REGION="us-east-1"
AZ_A="${REGION}a"
AZ_B="${REGION}b"

echo "🚀 Starting WordPress VPC setup..."

# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --query 'Vpc.VpcId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $VPC_ID \
    --tags Key=Name,Value=wordpress-vpc \
    --region $REGION

echo "✅ VPC created: $VPC_ID"

# Enable DNS hostnames and resolution
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames \
    --region $REGION

aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-support \
    --region $REGION

# Create Internet Gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $IGW_ID \
    --tags Key=Name,Value=wordpress-igw \
    --region $REGION

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID \
    --region $REGION

echo "✅ Internet Gateway created and attached: $IGW_ID"

# Create Public Subnets
echo "Creating public subnets..."
PUBLIC_SUBNET_A_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_A_CIDR \
    --availability-zone $AZ_A \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PUBLIC_SUBNET_A_ID \
    --tags Key=Name,Value=wordpress-public-subnet-a \
    --region $REGION

PUBLIC_SUBNET_B_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_B_CIDR \
    --availability-zone $AZ_B \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PUBLIC_SUBNET_B_ID \
    --tags Key=Name,Value=wordpress-public-subnet-b \
    --region $REGION

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute \
    --subnet-id $PUBLIC_SUBNET_A_ID \
    --map-public-ip-on-launch \
    --region $REGION

aws ec2 modify-subnet-attribute \
    --subnet-id $PUBLIC_SUBNET_B_ID \
    --map-public-ip-on-launch \
    --region $REGION

echo "✅ Public subnets created: $PUBLIC_SUBNET_A_ID, $PUBLIC_SUBNET_B_ID"

# Create Private Subnets
echo "Creating private subnets..."
PRIVATE_SUBNET_A_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PRIVATE_SUBNET_A_CIDR \
    --availability-zone $AZ_A \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PRIVATE_SUBNET_A_ID \
    --tags Key=Name,Value=wordpress-private-subnet-a \
    --region $REGION

PRIVATE_SUBNET_B_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PRIVATE_SUBNET_B_CIDR \
    --availability-zone $AZ_B \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PRIVATE_SUBNET_B_ID \
    --tags Key=Name,Value=wordpress-private-subnet-b \
    --region $REGION

echo "✅ Private subnets created: $PRIVATE_SUBNET_A_ID, $PRIVATE_SUBNET_B_ID"

# Allocate Elastic IP for NAT Gateway
echo "Allocating Elastic IP for NAT Gateway..."
NAT_EIP_ALLOC_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --query 'AllocationId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $NAT_EIP_ALLOC_ID \
    --tags Key=Name,Value=wordpress-nat-eip \
    --region $REGION

# Create NAT Gateway
echo "Creating NAT Gateway..."
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET_A_ID \
    --allocation-id $NAT_EIP_ALLOC_ID \
    --query 'NatGateway.NatGatewayId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $NAT_GW_ID \
    --tags Key=Name,Value=wordpress-nat-gateway \
    --region $REGION

echo "✅ NAT Gateway created: $NAT_GW_ID"
echo "⏳ Waiting for NAT Gateway to become available..."

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available \
    --nat-gateway-ids $NAT_GW_ID \
    --region $REGION

# Create Route Tables
echo "Creating route tables..."

# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PUBLIC_RT_ID \
    --tags Key=Name,Value=wordpress-public-rt \
    --region $REGION

# Add route to Internet Gateway for public route table
aws ec2 create-route \
    --route-table-id $PUBLIC_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $REGION

# Associate public subnets with public route table
aws ec2 associate-route-table \
    --subnet-id $PUBLIC_SUBNET_A_ID \
    --route-table-id $PUBLIC_RT_ID \
    --region $REGION

aws ec2 associate-route-table \
    --subnet-id $PUBLIC_SUBNET_B_ID \
    --route-table-id $PUBLIC_RT_ID \
    --region $REGION

# Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text \
    --region $REGION)

aws ec2 create-tags \
    --resources $PRIVATE_RT_ID \
    --tags Key=Name,Value=wordpress-private-rt \
    --region $REGION

# Add route to NAT Gateway for private route table
aws ec2 create-route \
    --route-table-id $PRIVATE_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $NAT_GW_ID \
    --region $REGION

# Associate private subnets with private route table
aws ec2 associate-route-table \
    --subnet-id $PRIVATE_SUBNET_A_ID \
    --route-table-id $PRIVATE_RT_ID \
    --region $REGION

aws ec2 associate-route-table \
    --subnet-id $PRIVATE_SUBNET_B_ID \
    --route-table-id $PRIVATE_RT_ID \
    --region $REGION

echo "✅ Route tables created and associated"

# Output summary
echo ""
echo "🎉 WordPress VPC setup completed successfully!"
echo ""
echo "📋 Resource Summary:"
echo "VPC ID: $VPC_ID"
echo "Internet Gateway ID: $IGW_ID"
echo "Public Subnet A ID: $PUBLIC_SUBNET_A_ID"
echo "Public Subnet B ID: $PUBLIC_SUBNET_B_ID"
echo "Private Subnet A ID: $PRIVATE_SUBNET_A_ID"
echo "Private Subnet B ID: $PRIVATE_SUBNET_B_ID"
echo "NAT Gateway ID: $NAT_GW_ID"
echo "NAT Elastic IP Allocation ID: $NAT_EIP_ALLOC_ID"
echo "Public Route Table ID: $PUBLIC_RT_ID"
echo "Private Route Table ID: $PRIVATE_RT_ID"
echo ""
echo "💡 Next Steps:"
echo "1. Create RDS subnet group using private subnets"
echo "2. Create security groups"
echo "3. Launch RDS database"
echo "4. Create Auto Scaling Group and Application Load Balancer"
echo ""
echo "💰 Cost Note: NAT Gateway will incur charges (~$32/month)"
echo "🗑️  Remember to clean up resources when done!"

# Save configuration to file for reference
cat > vpc-config.txt << EOF
VPC_ID=$VPC_ID
IGW_ID=$IGW_ID
PUBLIC_SUBNET_A_ID=$PUBLIC_SUBNET_A_ID
PUBLIC_SUBNET_B_ID=$PUBLIC_SUBNET_B_ID
PRIVATE_SUBNET_A_ID=$PRIVATE_SUBNET_A_ID
PRIVATE_SUBNET_B_ID=$PRIVATE_SUBNET_B_ID
NAT_GW_ID=$NAT_GW_ID
NAT_EIP_ALLOC_ID=$NAT_EIP_ALLOC_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
PRIVATE_RT_ID=$PRIVATE_RT_ID
EOF

echo "📄 Configuration saved to vpc-config.txt"
