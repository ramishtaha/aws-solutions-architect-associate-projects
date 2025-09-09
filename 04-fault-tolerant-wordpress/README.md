# Project 4: Deploy a fault-tolerant WordPress site using EC2, an Application Load Balancer (ALB), and an RDS Multi-AZ database in a custom VPC

## 1. Objective
In this project, you will build a highly available, fault-tolerant WordPress website that can withstand the failure of individual components. You'll learn how to design and implement a resilient architecture using multiple Availability Zones, an Application Load Balancer for traffic distribution, Auto Scaling for automatic recovery, and an RDS Multi-AZ database for data redundancy. This project demonstrates core principles of the AWS Well-Architected Framework, particularly the Reliability and Security pillars.

## 2. AWS Services Used
- **Amazon VPC** - Custom networking environment with public and private subnets
- **Amazon EC2** - Web servers hosting WordPress
- **Application Load Balancer (ALB)** - Traffic distribution and health checking
- **Auto Scaling Group** - Automatic instance replacement and scaling
- **Amazon RDS (MySQL)** - Multi-AZ database for high availability
- **Amazon Route 53** - DNS resolution (optional)
- **AWS Systems Manager Session Manager** - Secure instance access
- **Security Groups** - Network-level security controls
- **IAM** - Identity and access management

## 3. Difficulty
**Intermediate**

## 4. Architecture Diagram

```
                                    Internet Gateway
                                           |
                               ┌───────────┴───────────┐
                               │     Public Subnets    │
                               │   (Multi-AZ: a & b)   │
                               │                       │
                           ┌───┴───┐               ┌───┴───┐
                           │  ALB  │               │  NAT  │
                           │ (AZ-a)│               │Gateway│
                           └───┬───┘               └───┬───┘
                               │                       │
                    ┌──────────┼───────────┐           │
                    │          │           │           │
                ┌───▼───┐  ┌───▼───┐   ┌───▼───┐      │
                │  EC2  │  │  EC2  │   │  EC2  │      │
                │(AZ-a) │  │(AZ-b) │   │(AZ-c) │      │
                └───────┘  └───────┘   └───────┘      │
                    │          │           │          │
                    └──────────┼───────────┘          │
                               │                      │
                    ┌──────────┴───────────┐          │
                    │   Private Subnets    │◄─────────┘
                    │   (Multi-AZ: a & b)  │
                    │                      │
                    │  ┌─────────────────┐ │
                    │  │   RDS MySQL     │ │
                    │  │   (Multi-AZ)    │ │
                    │  └─────────────────┘ │
                    └──────────────────────┘
```

## 5. Prerequisites
- Ensure you have completed the initial setup detailed in the main [PREREQUISITES.md](../PREREQUISITES.md) file in the repository root.

## 6. Step-by-Step Guide

### Phase 1: VPC and Networking Setup

#### Step 1: Create VPC
1. Navigate to **VPC Console** → **Your VPCs** → **Create VPC**
2. Configure:
   - **Name**: `wordpress-vpc`
   - **IPv4 CIDR**: `10.0.0.0/16`
   - **IPv6 CIDR**: No IPv6 CIDR block
   - **Tenancy**: Default
3. Click **Create VPC**

#### Step 2: Create Subnets
Create the following subnets:

**Public Subnets (for ALB):**
1. **Public Subnet 1**:
   - **Name**: `wordpress-public-1a`
   - **VPC**: Select `wordpress-vpc`
   - **AZ**: Choose first AZ (e.g., us-east-1a)
   - **IPv4 CIDR**: `10.0.1.0/24`

2. **Public Subnet 2**:
   - **Name**: `wordpress-public-1b`
   - **VPC**: Select `wordpress-vpc`
   - **AZ**: Choose second AZ (e.g., us-east-1b)
   - **IPv4 CIDR**: `10.0.2.0/24`

**Private Subnets (for EC2 and RDS):**
3. **Private Subnet 1**:
   - **Name**: `wordpress-private-1a`
   - **VPC**: Select `wordpress-vpc`
   - **AZ**: Same as public subnet 1
   - **IPv4 CIDR**: `10.0.11.0/24`

4. **Private Subnet 2**:
   - **Name**: `wordpress-private-1b`
   - **VPC**: Select `wordpress-vpc`
   - **AZ**: Same as public subnet 2
   - **IPv4 CIDR**: `10.0.12.0/24`

#### Step 3: Internet Gateway
1. **VPC Console** → **Internet Gateways** → **Create Internet Gateway**
2. **Name**: `wordpress-igw`
3. **Actions** → **Attach to VPC** → Select `wordpress-vpc`

#### Step 4: NAT Gateway
1. **VPC Console** → **NAT Gateways** → **Create NAT Gateway**
2. Configure:
   - **Name**: `wordpress-nat`
   - **Subnet**: Select `wordpress-public-1a`
   - **Connectivity type**: Public
   - **Elastic IP**: Allocate new IP
3. Click **Create NAT Gateway**

#### Step 5: Route Tables
**Public Route Table:**
1. **Route Tables** → **Create Route Table**
2. **Name**: `wordpress-public-rt`
3. **VPC**: Select `wordpress-vpc`
4. **Routes tab** → **Edit routes** → **Add route**:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Internet Gateway (`wordpress-igw`)
5. **Subnet associations** → Associate public subnets

**Private Route Table:**
1. Create another route table: `wordpress-private-rt`
2. **Routes tab** → **Edit routes** → **Add route**:
   - **Destination**: `0.0.0.0/0`
   - **Target**: NAT Gateway (`wordpress-nat`)
3. **Subnet associations** → Associate private subnets

### Phase 2: Security Groups

#### Step 6: Create Security Groups
**ALB Security Group:**
1. **EC2 Console** → **Security Groups** → **Create Security Group**
2. Configure:
   - **Name**: `wordpress-alb-sg`
   - **Description**: Security group for Application Load Balancer
   - **VPC**: Select `wordpress-vpc`
   - **Inbound rules**:
     - HTTP (80) from Anywhere (0.0.0.0/0)
     - HTTPS (443) from Anywhere (0.0.0.0/0)

**EC2 Security Group:**
1. Create another security group: `wordpress-ec2-sg`
2. **Inbound rules**:
   - HTTP (80) from ALB Security Group (`wordpress-alb-sg`)
   - HTTPS (443) from ALB Security Group (`wordpress-alb-sg`)

**RDS Security Group:**
1. Create security group: `wordpress-rds-sg`
2. **Inbound rules**:
   - MySQL/Aurora (3306) from EC2 Security Group (`wordpress-ec2-sg`)

### Phase 3: Database Setup

#### Step 7: Create RDS Subnet Group
1. **RDS Console** → **Subnet groups** → **Create DB subnet group**
2. Configure:
   - **Name**: `wordpress-db-subnet-group`
   - **Description**: Subnet group for WordPress database
   - **VPC**: Select `wordpress-vpc`
   - **Availability Zones**: Select 2 AZs
   - **Subnets**: Select both private subnets

#### Step 8: Create RDS Database
1. **RDS Console** → **Databases** → **Create database**
2. **Engine options**: MySQL
3. **Templates**: Production (for Multi-AZ)
4. **Settings**:
   - **DB instance identifier**: `wordpress-db`
   - **Master username**: `admin`
   - **Password**: `YourSecurePassword123!` (use a strong password)
5. **Instance configuration**:
   - **DB instance class**: db.t3.micro (Free Tier eligible)
6. **Storage**: 20 GB GP2 (minimum for Multi-AZ)
7. **Availability & durability**:
   - **Multi-AZ deployment**: Create a standby instance
8. **Connectivity**:
   - **VPC**: Select `wordpress-vpc`
   - **Subnet group**: `wordpress-db-subnet-group`
   - **VPC security groups**: Select `wordpress-rds-sg`
   - **Publicly accessible**: No
9. **Additional configuration**:
   - **Initial database name**: `wordpress`
10. Click **Create database**

### Phase 4: IAM Role for EC2

#### Step 9: Create IAM Role
1. **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → EC2
3. **Permissions**: 
   - Create custom policy using the content from `assets/iam_ssm_policy.json`
   - Name the policy: `WordPressSSMPolicy`
4. **Role name**: `WordPressEC2Role`
5. **Create role**

#### Step 10: Create Instance Profile
The instance profile is automatically created with the role, but verify it exists in IAM → Roles → WordPressEC2Role.

### Phase 5: Launch Template and Auto Scaling

#### Step 11: Create Launch Template
1. **EC2 Console** → **Launch Templates** → **Create launch template**
2. Configure:
   - **Name**: `wordpress-launch-template`
   - **Description**: Launch template for WordPress servers
   - **AMI**: Amazon Linux 2023 AMI
   - **Instance type**: t3.micro
   - **Key pair**: Skip (we'll use SSM)
   - **Network settings**:
     - **Security groups**: Select `wordpress-ec2-sg`
   - **Advanced details**:
     - **IAM instance profile**: `WordPressEC2Role`
     - **User data**: Copy content from `assets/user_data.sh`
     - **Replace `REPLACE_WITH_RDS_ENDPOINT`** with your actual RDS endpoint

#### Step 12: Create Auto Scaling Group
1. **EC2 Console** → **Auto Scaling Groups** → **Create Auto Scaling group**
2. Configure:
   - **Name**: `wordpress-asg`
   - **Launch template**: Select `wordpress-launch-template`
   - **VPC**: Select `wordpress-vpc`
   - **Subnets**: Select both private subnets
   - **Group size**:
     - **Desired**: 2
     - **Minimum**: 2
     - **Maximum**: 4
   - **Health checks**: ELB health checks
   - **Health check grace period**: 300 seconds

### Phase 6: Application Load Balancer

#### Step 13: Create Target Group
1. **EC2 Console** → **Target Groups** → **Create target group**
2. Configure:
   - **Target type**: Instances
   - **Name**: `wordpress-targets`
   - **Protocol**: HTTP
   - **Port**: 80
   - **VPC**: Select `wordpress-vpc`
   - **Health check path**: `/health.html`
   - **Health check interval**: 30 seconds
3. **Register targets**: Skip (Auto Scaling will handle this)

#### Step 14: Create Application Load Balancer
1. **EC2 Console** → **Load Balancers** → **Create Load Balancer**
2. Select **Application Load Balancer**
3. Configure:
   - **Name**: `wordpress-alb`
   - **Scheme**: Internet-facing
   - **IP address type**: IPv4
   - **VPC**: Select `wordpress-vpc`
   - **Subnets**: Select both public subnets
   - **Security groups**: Select `wordpress-alb-sg`
   - **Listeners**: HTTP:80
   - **Default action**: Forward to `wordpress-targets`

#### Step 15: Update Auto Scaling Group
1. Edit the Auto Scaling Group
2. **Load balancing** → **Target groups**: Select `wordpress-targets`
3. **Health checks**: Enable ELB health checks

### Phase 7: Testing and Verification

#### Step 16: Test the Setup
1. Wait for all instances to be healthy in the target group (5-10 minutes)
2. Copy the ALB DNS name from the Load Balancer details
3. Open the DNS name in a browser
4. Complete WordPress setup:
   - Select language
   - Enter site title, admin username, password, and email
   - Click "Install WordPress"

#### Step 17: Verify Fault Tolerance
1. **EC2 Console** → **Instances**
2. Terminate one instance
3. Verify that Auto Scaling launches a replacement
4. Confirm the website remains accessible during the replacement

## 7. Troubleshooting Common Issues

### Problem 1: The ALB's DNS link gives a 503 Service Temporarily Unavailable error or times out

**Potential Causes:**
- Incorrect Security Group rules preventing ALB from reaching EC2 instances
- EC2 instances failing health checks
- User data script errors preventing proper WordPress installation

**Solutions:**
1. **Check Security Group Rules:**
   - Verify ALB security group allows inbound HTTP/HTTPS from 0.0.0.0/0
   - Verify EC2 security group allows inbound HTTP from ALB security group
   - Check outbound rules are not restrictive

2. **Verify Target Group Health:**
   - Go to **Target Groups** → Select `wordpress-targets` → **Targets tab**
   - If instances show "unhealthy", check **Health check details**
   - Common fix: Ensure health check path `/health.html` is accessible

3. **Debug Health Check:**
   - Use SSM Session Manager to connect to an instance
   - Run: `curl http://localhost/health.html`
   - If it fails, check Apache status: `sudo systemctl status httpd`

### Problem 2: The WordPress page shows an "Error establishing a database connection"

**Potential Causes:**
- RDS security group not allowing traffic from EC2 instances
- Incorrect database credentials in wp-config.php
- RDS endpoint not properly configured in user data script
- Database not fully initialized

**Solutions:**
1. **Check RDS Security Group:**
   - Verify RDS security group allows inbound MySQL (3306) from EC2 security group
   - Ensure no typos in security group references

2. **Verify Database Configuration:**
   - Connect to EC2 using SSM Session Manager
   - Check wp-config.php: `sudo cat /var/www/html/wp-config.php`
   - Verify DB_HOST matches RDS endpoint exactly
   - Test database connection: 
     ```bash
     mysql -h YOUR_RDS_ENDPOINT -u admin -p wordpress
     ```

3. **Check User Data Script Execution:**
   - Review user data logs: `sudo cat /var/log/cloud-init-output.log`
   - Look for sed command errors or missing RDS endpoint replacement

### Problem 3: EC2 instances are not launching or are terminating shortly after launch

**Potential Causes:**
- Errors in the user_data.sh script causing bootstrap failure
- Insufficient permissions for the IAM role
- Network connectivity issues in private subnets

**Solutions:**
1. **Check User Data Logs:**
   - Connect via SSM Session Manager: **Systems Manager** → **Session Manager** → **Start session**
   - View logs: `sudo cat /var/log/cloud-init-output.log`
   - Look for package installation failures or script errors

2. **Verify IAM Permissions:**
   - Ensure the EC2 role has the SSM policy attached
   - Check if SSM agent can register: `sudo systemctl status amazon-ssm-agent`

3. **Debug Network Connectivity:**
   - From private subnet, test internet access: `curl -I http://google.com`
   - If failed, verify NAT Gateway routing in private route table
   - Check route table associations for private subnets

### Problem 4: Auto Scaling is not replacing terminated instances

**Potential Causes:**
- Auto Scaling Group not properly configured
- Launch template issues
- Subnet or security group problems

**Solutions:**
1. **Check Auto Scaling Activity:**
   - **Auto Scaling Groups** → Select group → **Activity** tab
   - Review failed launch attempts and error messages

2. **Verify Launch Template:**
   - Ensure security group exists and allows required traffic
   - Check if IAM role is properly attached
   - Validate user data script syntax

3. **Monitor CloudWatch Logs:**
   - Check Auto Scaling group events in CloudWatch
   - Review any launch failures or capacity issues

## 8. Learning Materials & Key Concepts

### High Availability and Fault Tolerance
- **Multi-AZ Architecture**: Deploying resources across multiple Availability Zones protects against AZ-level failures
- **RDS Multi-AZ**: Provides synchronous replication and automatic failover for database high availability
- **Auto Scaling**: Automatically replaces failed instances and maintains desired capacity

### Load Balancing and Health Checks
- **Application Load Balancer**: Distributes incoming traffic across multiple targets and performs health checks
- **Health Checks**: Regular probes to determine if targets are healthy and should receive traffic
- **Target Groups**: Logical grouping of targets for load balancer routing

### VPC Networking Best Practices
- **Public vs Private Subnets**: Public subnets for internet-facing resources, private for internal resources
- **NAT Gateway**: Allows private subnet resources to access the internet for updates while remaining private
- **Security Groups**: Act as virtual firewalls controlling traffic at the instance level

### Security Best Practices
- **Least Privilege**: IAM roles grant only necessary permissions
- **Network Segmentation**: Using security groups and subnets to control traffic flow
- **SSM Session Manager**: Secure access to instances without SSH keys or open ports

### SAA-C03 Exam Topics Covered
- **Design Resilient Architectures**: Multi-AZ deployment, Auto Scaling, fault tolerance
- **High-Performing Architectures**: Load balancing, caching considerations
- **Secure Applications**: VPC design, security groups, IAM roles
- **Cost-Optimized Architectures**: Right-sizing instances, understanding cost implications

## 9. Cost & Free Tier Eligibility

### ⚠️ **Important Cost Warning**
This project uses several services that are **NOT** eligible for the AWS Free Tier and **WILL INCUR CHARGES**:

**Services with charges:**
- **RDS Multi-AZ deployment**: ~$25-30/month for db.t3.micro
- **NAT Gateway**: ~$32/month + data processing charges
- **Application Load Balancer**: ~$16/month + data processing
- **Data transfer**: Charges for data transfer between AZs and to internet

**Free Tier eligible components:**
- **EC2 t3.micro instances**: 750 hours/month (if within first 12 months)
- **VPC and Security Groups**: No charge
- **Route 53 hosted zone**: $0.50/month for hosted zone if used

**Estimated monthly cost**: $70-80 USD

### Cost Optimization Tips
- Use this project for learning and delete resources immediately after completion
- Consider using a single AZ for learning (reduces costs but eliminates high availability)
- Monitor AWS Billing Dashboard daily during the project

## 10. Cleanup Instructions

**⚠️ Critical: Follow this order to avoid dependency errors and additional charges**

### Phase 1: Application Layer Cleanup
1. **Auto Scaling Group**:
   - Set desired capacity to 0
   - Wait for all instances to terminate
   - Delete the Auto Scaling Group

2. **Load Balancer**:
   - **EC2 Console** → **Load Balancers** → Select ALB → **Actions** → **Delete**

3. **Target Group**:
   - **Target Groups** → Select group → **Actions** → **Delete**

4. **Launch Template**:
   - **Launch Templates** → Select template → **Actions** → **Delete**

### Phase 2: Database Cleanup
5. **RDS Database**:
   - **RDS Console** → **Databases** → Select database
   - **Actions** → **Delete**
   - Uncheck "Create final snapshot" (for learning environment)
   - Type the confirmation text → **Delete**

6. **DB Subnet Group**:
   - Wait for RDS deletion to complete
   - **Subnet groups** → Select group → **Delete**

### Phase 3: Network Infrastructure
7. **NAT Gateway**:
   - **VPC Console** → **NAT Gateways** → Select gateway → **Actions** → **Delete**
   - **Elastic IPs** → Release the associated Elastic IP

8. **Security Groups**:
   - Delete in order: RDS SG → EC2 SG → ALB SG

9. **Route Tables**:
   - Disassociate subnets from custom route tables
   - Delete custom route tables (keep default)

10. **Subnets**:
    - Delete all created subnets

11. **Internet Gateway**:
    - Detach from VPC first, then delete

12. **VPC**:
    - Delete the VPC (this will clean up remaining dependencies)

### Phase 4: IAM Cleanup
13. **IAM Role and Policy**:
    - **IAM Console** → **Roles** → Delete `WordPressEC2Role`
    - **Policies** → Delete custom policy

### Verification
- Check **Billing Dashboard** to ensure no ongoing charges
- Review all regions to ensure no orphaned resources
- Verify Elastic IP addresses are released

## 11. Associated Project Files

### Files in the `assets` folder:

1. **`user_data.sh`**
   - Complete bootstrap script for EC2 instances
   - Installs and configures LAMP stack (Apache, PHP, MySQL client)
   - Downloads and configures WordPress
   - Sets up health check endpoint for ALB
   - Configures WordPress for load balancer environment

2. **`iam_ssm_policy.json`**
   - IAM policy document for EC2 instance role
   - Grants permissions for AWS Systems Manager Session Manager
   - Enables secure access to EC2 instances without SSH
   - Includes CloudWatch Logs permissions for monitoring

These files provide the foundation for a production-ready, fault-tolerant WordPress deployment that demonstrates enterprise-level AWS architecture patterns suitable for the Solutions Architect Associate certification.
