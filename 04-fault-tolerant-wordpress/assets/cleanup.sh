#!/bin/bash
# Emergency Cleanup Script for WordPress Project
# This script removes ALL resources created for the WordPress project
# ⚠️ WARNING: This will DELETE all resources and data - use with caution!

set -e

REGION="us-east-1"

echo "⚠️  WARNING: This script will DELETE ALL WordPress project resources!"
echo "This includes:"
echo "- Auto Scaling Groups and EC2 instances"
echo "- Application Load Balancer and Target Groups"
echo "- RDS Database (and all data)"
echo "- VPC and all networking components"
echo ""
read -p "Are you sure you want to continue? (type 'DELETE' to confirm): " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "🗑️ Starting emergency cleanup..."

# Function to check if resource exists
resource_exists() {
    local resource_type=$1
    local resource_id=$2
    local check_command=$3
    
    if [ -n "$resource_id" ] && [ "$resource_id" != "None" ]; then
        if eval "$check_command" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local resource_id=$2
    local check_command=$3
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $resource_type $resource_id to be deleted..."
    
    while [ $attempt -le $max_attempts ]; do
        if ! eval "$check_command" >/dev/null 2>&1; then
            echo "✅ $resource_type deleted successfully"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - still deleting..."
        sleep 10
        ((attempt++))
    done
    
    echo "⚠️ Timeout waiting for $resource_type deletion"
    return 1
}

# Step 1: Scale down and delete Auto Scaling Group
echo "Step 1: Cleaning up Auto Scaling Group..."
ASG_NAME="wordpress-asg"

if aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --region $REGION >/dev/null 2>&1; then
    echo "Scaling down Auto Scaling Group..."
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name $ASG_NAME \
        --min-size 0 \
        --max-size 0 \
        --desired-capacity 0 \
        --region $REGION
    
    # Wait for instances to terminate
    echo "⏳ Waiting for instances to terminate..."
    sleep 30
    
    # Delete Auto Scaling Group
    aws autoscaling delete-auto-scaling-group \
        --auto-scaling-group-name $ASG_NAME \
        --force-delete \
        --region $REGION
    
    echo "✅ Auto Scaling Group cleanup initiated"
else
    echo "Auto Scaling Group not found, skipping..."
fi

# Step 2: Delete Launch Template
echo "Step 2: Deleting Launch Template..."
LAUNCH_TEMPLATE_NAME="wordpress-launch-template"

if aws ec2 describe-launch-templates --launch-template-names $LAUNCH_TEMPLATE_NAME --region $REGION >/dev/null 2>&1; then
    aws ec2 delete-launch-template \
        --launch-template-name $LAUNCH_TEMPLATE_NAME \
        --region $REGION
    echo "✅ Launch Template deleted"
else
    echo "Launch Template not found, skipping..."
fi

# Step 3: Delete Application Load Balancer
echo "Step 3: Deleting Application Load Balancer..."
ALB_NAME="wordpress-alb"

ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names $ALB_NAME \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region $REGION 2>/dev/null || echo "None")

if [ "$ALB_ARN" != "None" ]; then
    aws elbv2 delete-load-balancer \
        --load-balancer-arn $ALB_ARN \
        --region $REGION
    
    wait_for_deletion "Load Balancer" $ALB_ARN \
        "aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --region $REGION"
else
    echo "Application Load Balancer not found, skipping..."
fi

# Step 4: Delete Target Group
echo "Step 4: Deleting Target Group..."
TG_NAME="wordpress-targets"

TG_ARN=$(aws elbv2 describe-target-groups \
    --names $TG_NAME \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION 2>/dev/null || echo "None")

if [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group \
        --target-group-arn $TG_ARN \
        --region $REGION
    echo "✅ Target Group deleted"
else
    echo "Target Group not found, skipping..."
fi

# Step 5: Delete RDS Database
echo "Step 5: Deleting RDS Database..."
DB_IDENTIFIER="wordpress-db"

if aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --region $REGION >/dev/null 2>&1; then
    echo "Deleting RDS database (this may take several minutes)..."
    aws rds delete-db-instance \
        --db-instance-identifier $DB_IDENTIFIER \
        --skip-final-snapshot \
        --delete-automated-backups \
        --region $REGION
    
    wait_for_deletion "RDS Database" $DB_IDENTIFIER \
        "aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --region $REGION"
else
    echo "RDS Database not found, skipping..."
fi

# Step 6: Delete DB Subnet Group
echo "Step 6: Deleting DB Subnet Group..."
DB_SUBNET_GROUP="wordpress-db-subnet-group"

if aws rds describe-db-subnet-groups --db-subnet-group-name $DB_SUBNET_GROUP --region $REGION >/dev/null 2>&1; then
    aws rds delete-db-subnet-group \
        --db-subnet-group-name $DB_SUBNET_GROUP \
        --region $REGION
    echo "✅ DB Subnet Group deleted"
else
    echo "DB Subnet Group not found, skipping..."
fi

# Step 7: Get VPC information
echo "Step 7: Identifying VPC resources..."

# Try to find VPC by name tag
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=wordpress-vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text \
    --region $REGION 2>/dev/null || echo "None")

if [ "$VPC_ID" == "None" ]; then
    echo "WordPress VPC not found by name tag. Checking vpc-config.txt..."
    if [ -f "vpc-config.txt" ]; then
        source vpc-config.txt
        echo "Loaded VPC ID from configuration: $VPC_ID"
    else
        echo "❌ Cannot find WordPress VPC. Manual cleanup may be required."
        echo "Please check your VPC console and delete resources manually."
        exit 1
    fi
fi

# Step 8: Delete NAT Gateway
echo "Step 8: Deleting NAT Gateway..."
NAT_GW_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[0].NatGatewayId' \
    --output text \
    --region $REGION 2>/dev/null || echo "None")

if [ "$NAT_GW_ID" != "None" ]; then
    # Get Elastic IP allocation ID before deleting NAT Gateway
    EIP_ALLOC_ID=$(aws ec2 describe-nat-gateways \
        --nat-gateway-ids $NAT_GW_ID \
        --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' \
        --output text \
        --region $REGION)
    
    aws ec2 delete-nat-gateway \
        --nat-gateway-id $NAT_GW_ID \
        --region $REGION
    
    wait_for_deletion "NAT Gateway" $NAT_GW_ID \
        "aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID --region $REGION --query 'NatGateways[?State==\`available\`]'"
    
    # Release Elastic IP
    if [ "$EIP_ALLOC_ID" != "None" ]; then
        echo "Releasing Elastic IP..."
        aws ec2 release-address \
            --allocation-id $EIP_ALLOC_ID \
            --region $REGION
        echo "✅ Elastic IP released"
    fi
else
    echo "NAT Gateway not found, skipping..."
fi

# Step 9: Delete Security Groups (except default)
echo "Step 9: Deleting Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
    --output text \
    --region $REGION)

for sg_id in $SECURITY_GROUPS; do
    if [ -n "$sg_id" ]; then
        echo "Deleting Security Group: $sg_id"
        aws ec2 delete-security-group \
            --group-id $sg_id \
            --region $REGION 2>/dev/null || echo "Failed to delete $sg_id (may have dependencies)"
    fi
done

# Step 10: Delete Subnets
echo "Step 10: Deleting Subnets..."
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].SubnetId' \
    --output text \
    --region $REGION)

for subnet_id in $SUBNETS; do
    if [ -n "$subnet_id" ]; then
        echo "Deleting Subnet: $subnet_id"
        aws ec2 delete-subnet \
            --subnet-id $subnet_id \
            --region $REGION
    fi
done

# Step 11: Delete Route Tables (except main)
echo "Step 11: Deleting Route Tables..."
ROUTE_TABLES=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
    --output text \
    --region $REGION)

for rt_id in $ROUTE_TABLES; do
    if [ -n "$rt_id" ]; then
        echo "Deleting Route Table: $rt_id"
        aws ec2 delete-route-table \
            --route-table-id $rt_id \
            --region $REGION
    fi
done

# Step 12: Detach and Delete Internet Gateway
echo "Step 12: Deleting Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text \
    --region $REGION 2>/dev/null || echo "None")

if [ "$IGW_ID" != "None" ]; then
    echo "Detaching Internet Gateway..."
    aws ec2 detach-internet-gateway \
        --internet-gateway-id $IGW_ID \
        --vpc-id $VPC_ID \
        --region $REGION
    
    echo "Deleting Internet Gateway..."
    aws ec2 delete-internet-gateway \
        --internet-gateway-id $IGW_ID \
        --region $REGION
    echo "✅ Internet Gateway deleted"
else
    echo "Internet Gateway not found, skipping..."
fi

# Step 13: Delete VPC
echo "Step 13: Deleting VPC..."
aws ec2 delete-vpc \
    --vpc-id $VPC_ID \
    --region $REGION

echo "✅ VPC deleted"

# Step 14: Clean up any remaining Elastic IPs
echo "Step 14: Checking for unattached Elastic IPs..."
UNATTACHED_EIPS=$(aws ec2 describe-addresses \
    --query 'Addresses[?AssociationId==null].AllocationId' \
    --output text \
    --region $REGION)

for eip_id in $UNATTACHED_EIPS; do
    if [ -n "$eip_id" ] && [ "$eip_id" != "None" ]; then
        echo "Releasing unattached Elastic IP: $eip_id"
        aws ec2 release-address \
            --allocation-id $eip_id \
            --region $REGION 2>/dev/null || echo "Failed to release $eip_id"
    fi
done

# Clean up local files
echo "Cleaning up local configuration files..."
rm -f vpc-config.txt

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "✅ Resources deleted:"
echo "   - Auto Scaling Group and Launch Template"
echo "   - Application Load Balancer and Target Group"
echo "   - RDS Database and Subnet Group"
echo "   - VPC, Subnets, Route Tables"
echo "   - Internet Gateway and NAT Gateway"
echo "   - Security Groups"
echo "   - Elastic IPs"
echo ""
echo "💡 Please verify in the AWS Console that all resources have been deleted."
echo "💰 Check your AWS billing to ensure no unexpected charges."
echo ""
echo "🔍 If any resources remain, they may need manual deletion due to dependencies."
