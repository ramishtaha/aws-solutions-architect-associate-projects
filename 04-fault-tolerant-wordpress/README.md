# Project 4: Deploy a fault-tolerant WordPress site using EC2, an Application Load Balancer (ALB), and an RDS Multi-AZ database in a custom VPC

## 1. Objective
Build a highly available and fault-tolerant WordPress web application deployed across multiple Availability Zones. This project demonstrates critical SAA-C03 concepts including VPC design, multi-tier architecture, Auto Scaling, Load Balancing, and database high availability. Students will create a production-ready WordPress deployment that can withstand individual component failures while maintaining service availability.

## 2. AWS Services Used
- **Amazon VPC** - Custom Virtual Private Cloud with public and private subnets
- **Amazon EC2** - Web server instances running WordPress
- **Amazon RDS** - Multi-AZ MySQL database for WordPress data
- **Application Load Balancer (ALB)** - Layer 7 load balancing and traffic distribution
- **Auto Scaling Groups** - Automatic scaling and instance replacement
- **IAM** - Instance profiles and policies for secure access
- **Security Groups** - Network-level security controls
- **AWS Systems Manager** - Secure instance management without SSH

## 3. Difficulty
Intermediate

## 4. Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet Gateway                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│                    Custom VPC (10.0.0.0/16)                    │
│                                                                 │
│  ┌─────────────────┐                    ┌─────────────────┐     │
│  │   Public Subnet │                    │   Public Subnet │     │
│  │   AZ-1a         │                    │   AZ-1b         │     │
│  │   10.0.1.0/24   │                    │   10.0.2.0/24   │     │
│  │                 │                    │                 │     │
│  │    ┌─────────┐  │                    │  ┌─────────┐    │     │
│  │    │   ALB   │◄─┼────────────────────┼─►│   ALB   │    │     │
│  │    └─────────┘  │                    │  └─────────┘    │     │
│  └─────────────────┘                    └─────────────────┘     │
│           │                                       │             │
│  ┌─────────┴───────┐                    ┌─────────┴───────┐     │
│  │  Private Subnet │                    │  Private Subnet │     │
│  │   AZ-1a         │                    │   AZ-1b         │     │
│  │   10.0.3.0/24   │                    │   10.0.4.0/24   │     │
│  │                 │                    │                 │     │
│  │  ┌──────────┐   │                    │   ┌──────────┐  │     │
│  │  │    EC2   │   │                    │   │    EC2   │  │     │
│  │  │WordPress │   │                    │   │WordPress │  │     │
│  │  └──────────┘   │                    │   └──────────┘  │     │
│  └─────────┬───────┘                    └───────┬─────────┘     │
│            │                                    │               │
│  ┌─────────┴────────────────────────────────────┴─────────┐     │
│  │              Private DB Subnet Group                  │     │
│  │                                                        │     │
│  │               ┌─────────────────┐                      │     │
│  │               │   RDS Multi-AZ  │                      │     │
│  │               │     MySQL       │                      │     │
│  │               └─────────────────┘                      │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## 5. Prerequisites
- Ensure you have completed the initial setup detailed in the main [PREREQUISITES.md](../PREREQUISITES.md) file in the repository root.
- Basic understanding of VPC networking concepts
- Familiarity with MySQL database basics
- Understanding of WordPress application architecture

## 6. Step-by-Step Guide

### Step 1: VPC and Networking Setup
1. **Create a Custom VPC**
   - Navigate to VPC Console
   - Create VPC with CIDR block `10.0.0.0/16`
   - Name: `wordpress-vpc`
   - Enable DNS hostnames and DNS resolution

2. **Create Subnets**
   - **Public Subnet 1**: `10.0.1.0/24` in AZ-1a (e.g., us-east-1a)
   - **Public Subnet 2**: `10.0.2.0/24` in AZ-1b (e.g., us-east-1b)
   - **Private Subnet 1**: `10.0.3.0/24` in AZ-1a
   - **Private Subnet 2**: `10.0.4.0/24` in AZ-1b

3. **Create and Attach Internet Gateway**
   - Create Internet Gateway: `wordpress-igw`
   - Attach to `wordpress-vpc`

4. **Configure Route Tables**
   - **Public Route Table**: Add route `0.0.0.0/0` → Internet Gateway
   - Associate with public subnets
   - **Private Route Table**: Keep default (local traffic only)
   - Associate with private subnets

### Step 2: Database Layer Setup
1. **Create DB Subnet Group**
   - Navigate to RDS Console
   - Create DB Subnet Group: `wordpress-db-subnet-group`
   - Select private subnets from both AZs

2. **Create Database Security Group**
   - Name: `wordpress-db-sg`
   - Allow inbound MySQL/Aurora (port 3306) from web server security group (to be created)

3. **Launch RDS Multi-AZ Instance**
   - Engine: MySQL 8.0
   - Template: Production (for Multi-AZ)
   - DB Instance: `db.t3.micro` (smallest for cost efficiency)
   - Storage: 20 GB General Purpose SSD
   - Database name: `wordpressdb`
   - Master username: `admin`
   - Master password: Create strong password and note it down
   - VPC: `wordpress-vpc`
   - DB Subnet Group: `wordpress-db-subnet-group`
   - Security Group: `wordpress-db-sg`
   - **Important**: Enable Multi-AZ deployment

### Step 3: Application Layer Security Groups
1. **Create ALB Security Group**
   - Name: `wordpress-alb-sg`
   - Inbound rules:
     - HTTP (80) from 0.0.0.0/0
     - HTTPS (443) from 0.0.0.0/0

2. **Create Web Server Security Group**
   - Name: `wordpress-web-sg`
   - Inbound rules:
     - HTTP (80) from ALB security group
     - HTTPS (443) from ALB security group

3. **Update Database Security Group**
   - Add inbound rule: MySQL/Aurora (3306) from `wordpress-web-sg`

### Step 4: IAM Instance Profile
1. **Create IAM Role**
   - Service: EC2
   - Attach policy: Use the `iam_ssm_policy.json` from assets folder
   - Role name: `wordpress-ec2-ssm-role`

2. **Create Instance Profile**
   - Attach the IAM role to instance profile

### Step 5: Launch Template Creation
1. **Navigate to EC2 Console → Launch Templates**
2. **Create Launch Template**
   - Name: `wordpress-launch-template`
   - AMI: Amazon Linux 2023 (latest)
   - Instance type: `t2.micro`
   - Security groups: `wordpress-web-sg`
   - IAM instance profile: `wordpress-ec2-ssm-role`
   - User data: Copy content from `user_data.sh` in assets folder
   - **Important**: Update the user data script with your RDS endpoint before creating the template

### Step 6: Auto Scaling Group Configuration
1. **Create Auto Scaling Group**
   - Name: `wordpress-asg`
   - Launch template: `wordpress-launch-template`
   - VPC: `wordpress-vpc`
   - Subnets: Select both private subnets
   - Desired capacity: 2
   - Minimum capacity: 1
   - Maximum capacity: 4
   - Health check type: ELB
   - Health check grace period: 300 seconds

### Step 7: Application Load Balancer Setup
1. **Create Target Group**
   - Target type: Instances
   - Protocol: HTTP
   - Port: 80
   - VPC: `wordpress-vpc`
   - Health check path: `/`

2. **Create Application Load Balancer**
   - Name: `wordpress-alb`
   - Scheme: Internet-facing
   - IP address type: IPv4
   - VPC: `wordpress-vpc`
   - Subnets: Select both public subnets
   - Security group: `wordpress-alb-sg`
   - Listener: HTTP:80 → Target Group

3. **Update Auto Scaling Group**
   - Attach the target group to the Auto Scaling Group

### Step 8: Testing and WordPress Configuration
1. **Wait for Infrastructure Deployment**
   - Allow 10-15 minutes for all resources to be ready
   - Check that EC2 instances are healthy in target group

2. **Access WordPress Setup**
   - Copy ALB DNS name from EC2 Console
   - Navigate to `http://[ALB-DNS-NAME]`
   - Complete WordPress installation wizard
   - Use RDS endpoint details for database configuration

3. **Test High Availability**
   - Terminate one EC2 instance manually
   - Verify new instance launches automatically
   - Confirm website remains accessible

## 7. Learning Materials & Key Concepts

### Concept 1: High Availability vs. Fault Tolerance
**High Availability** refers to systems designed to remain operational most of the time, typically 99.9% or higher uptime. This project achieves high availability through:
- **Multi-AZ RDS deployment**: Automatic failover to standby instance in different AZ
- **Auto Scaling Group across multiple AZs**: Replaces failed instances automatically
- **Application Load Balancer**: Routes traffic away from unhealthy instances

**Fault Tolerance** goes further, ensuring zero downtime even during component failures. While this project provides excellent availability, true fault tolerance would require additional components like Amazon ElastiCache for session management and Amazon EFS for shared file storage.

### Concept 2: Stateful vs. Stateless Application Tiers
**Stateless Web Tier**: Each EC2 instance in our WordPress deployment is stateless, meaning:
- No critical data stored locally on instances
- User sessions and application data stored in RDS database
- Instances can be terminated and replaced without data loss
- Enables horizontal scaling through Auto Scaling Groups

**Stateful Database Tier**: The RDS instance maintains state:
- Persistent storage of WordPress posts, users, and configuration
- Multi-AZ deployment ensures database availability
- Automatic backups provide point-in-time recovery

### Concept 3: VPC Networking and Security
**Public vs. Private Subnets**:
- **Public subnets**: Contain ALB, have routes to Internet Gateway
- **Private subnets**: Contain EC2 instances, no direct internet access
- **Database subnets**: RDS in private subnets, only accessible from application layer

**Security Groups as Stateful Firewalls**:
- **ALB Security Group**: Allows HTTP/HTTPS from internet
- **Web Security Group**: Only allows traffic from ALB
- **Database Security Group**: Only allows MySQL traffic from web servers
- Demonstrates principle of least privilege access

### Concept 4: Scalability and Load Distribution
**Horizontal Scaling**: Auto Scaling Group automatically adjusts capacity based on:
- CPU utilization metrics
- Target group health checks
- Custom CloudWatch metrics

**Load Balancing**: Application Load Balancer provides:
- **Layer 7 routing**: Can route based on HTTP headers, paths
- **Health checks**: Removes unhealthy instances from rotation
- **Cross-AZ load balancing**: Distributes traffic across availability zones
- **SSL termination**: Can handle HTTPS traffic and certificate management

**SAA-C03 Exam Focus**: This architecture demonstrates all major pillars of AWS Well-Architected Framework:
- **Security**: VPC isolation, security groups, IAM roles
- **Reliability**: Multi-AZ deployment, Auto Scaling
- **Performance**: Load balancing, appropriately sized instances
- **Cost Optimization**: Right-sizing instances, Auto Scaling
- **Operational Excellence**: Systems Manager for maintenance

## 8. Cost & Free Tier Eligibility

### Free Tier Coverage
- **EC2 t2.micro instances**: 750 hours per month (covers 1 instance full-time)
- **Application Load Balancer**: **NOT** covered by Free Tier ($16-18/month)
- **Data transfer**: First 1GB outbound per month

### Potential Costs (Monthly estimates)
- **RDS Multi-AZ db.t3.micro**: $25-30/month (**Primary cost driver**)
- **Application Load Balancer**: $16-18/month
- **Additional EC2 instances**: $8-10/month per t2.micro beyond Free Tier
- **Data transfer**: $0.09/GB after first 1GB
- **EBS storage**: $0.10/GB per month

**Total estimated monthly cost**: $50-70/month if running continuously

### Cost Optimization Tips
- Use this project for learning sessions, not continuous deployment
- Follow cleanup instructions immediately after testing
- Consider using RDS Single-AZ for learning (reduces cost by ~50%)
- Monitor AWS Billing Dashboard regularly

## 9. Cleanup Instructions

**⚠️ CRITICAL**: Follow this exact order to avoid dependency errors and additional charges.

### Step 1: Delete Application Load Balancer
1. Navigate to EC2 Console → Load Balancers
2. Select `wordpress-alb`
3. Actions → Delete
4. Wait for deletion to complete (5-10 minutes)

### Step 2: Delete Target Group
1. Navigate to EC2 Console → Target Groups
2. Select WordPress target group
3. Actions → Delete

### Step 3: Delete Auto Scaling Group
1. Navigate to EC2 Console → Auto Scaling Groups
2. Select `wordpress-asg`
3. Actions → Delete
4. This will automatically terminate all EC2 instances
5. Wait for all instances to terminate (5-10 minutes)

### Step 4: Delete Launch Template
1. Navigate to EC2 Console → Launch Templates
2. Select `wordpress-launch-template`
3. Actions → Delete launch template

### Step 5: Delete RDS Database
1. Navigate to RDS Console → Databases
2. Select WordPress database
3. Actions → Delete
4. **Uncheck** "Create final snapshot" (to avoid storage costs)
5. **Check** "I acknowledge that upon instance deletion, automated backups will be deleted"
6. Type "delete me" in confirmation field
7. Delete database (this takes 10-15 minutes)

### Step 6: Delete DB Subnet Group
1. RDS Console → Subnet Groups
2. Select `wordpress-db-subnet-group`
3. Delete

### Step 7: Delete Security Groups
1. EC2 Console → Security Groups
2. Delete in this order (due to dependencies):
   - `wordpress-web-sg`
   - `wordpress-alb-sg`
   - `wordpress-db-sg`

### Step 8: Delete IAM Resources
1. IAM Console → Roles
2. Delete `wordpress-ec2-ssm-role`

### Step 9: Delete VPC Resources
1. **Detach Internet Gateway**:
   - VPC Console → Internet Gateways
   - Select `wordpress-igw`
   - Actions → Detach from VPC
   - Actions → Delete Internet Gateway

2. **Delete VPC** (this deletes subnets and route tables automatically):
   - VPC Console → Your VPCs
   - Select `wordpress-vpc`
   - Actions → Delete VPC

### Step 10: Verify Cleanup
1. Check AWS Billing Dashboard for any remaining charges
2. Verify all resources are deleted in each service console
3. Resources should stop incurring charges within 1-2 hours

## 10. Associated Project Files

The following files are included in the `assets` folder for this project:

- **`user_data.sh`**: Complete EC2 user data script that installs LAMP stack, downloads WordPress, and configures database connectivity. Includes error handling and logging for troubleshooting.

- **`iam_ssm_policy.json`**: IAM policy document that grants EC2 instances the necessary permissions for AWS Systems Manager Session Manager access. This eliminates the need for SSH access and demonstrates security best practices.

These files contain production-ready code with proper error handling, security considerations, and detailed comments for educational purposes.
