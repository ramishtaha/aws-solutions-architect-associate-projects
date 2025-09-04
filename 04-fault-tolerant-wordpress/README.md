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
   - In the AWS Console, search for "VPC" in the top search bar
   - Click on **VPC** service
   - In the left navigation panel, click **Your VPCs**
   - Click **Create VPC** button
   - Select **VPC only** (not VPC and more)
   - Name tag: `wordpress-vpc`
   - IPv4 CIDR block: `10.0.0.0/16`
   - Leave IPv6 CIDR block as "No IPv6 CIDR block"
   - Tenancy: Default
   - Click **Create VPC**
   - After creation, select your VPC and click **Actions** → **Edit VPC settings**
   - Enable both **DNS resolution** and **DNS hostnames**

2. **Create Subnets**
   - In VPC dashboard, click **Subnets** in left navigation
   - Click **Create subnet** button
   - Select your `wordpress-vpc`
   - Create each subnet with these settings:
     - **Public Subnet 1**: 
       - Subnet name: `wordpress-public-1a`
       - Availability Zone: Select first AZ (e.g., us-east-1a)
       - IPv4 subnet CIDR block: `10.0.1.0/24`
     - **Public Subnet 2**: 
       - Subnet name: `wordpress-public-1b`
       - Availability Zone: Select second AZ (e.g., us-east-1b)
       - IPv4 subnet CIDR block: `10.0.2.0/24`
     - **Private Subnet 1**: 
       - Subnet name: `wordpress-private-1a`
       - Availability Zone: Same as Public Subnet 1
       - IPv4 subnet CIDR block: `10.0.3.0/24`
     - **Private Subnet 2**: 
       - Subnet name: `wordpress-private-1b`
       - Availability Zone: Same as Public Subnet 2
       - IPv4 subnet CIDR block: `10.0.4.0/24`

3. **Create and Attach Internet Gateway**
   - In left navigation, click **Internet gateways**
   - Click **Create internet gateway**
   - Name tag: `wordpress-igw`
   - Click **Create internet gateway**
   - Select the created gateway and click **Actions** → **Attach to VPC**
   - Select `wordpress-vpc` and click **Attach internet gateway**

4. **Configure Route Tables**
   - In left navigation, click **Route tables**
   - Note the default route table created with your VPC (rename it to `wordpress-private-rt`)
   - Click **Create route table**
   - Name: `wordpress-public-rt`
   - VPC: Select `wordpress-vpc`
   - Click **Create route table**
   - **Configure Public Route Table**:
     - Select `wordpress-public-rt`
     - Click **Routes** tab → **Edit routes**
     - Click **Add route**: Destination `0.0.0.0/0`, Target: Internet Gateway `wordpress-igw`
     - Click **Save changes**
     - Click **Subnet associations** tab → **Edit subnet associations**
     - Select both public subnets and click **Save associations**
   - **Configure Private Route Table**:
     - Select `wordpress-private-rt`
     - Click **Subnet associations** tab → **Edit subnet associations**
     - Select both private subnets and click **Save associations**

### Step 2: Database Layer Setup
1. **Create DB Subnet Group**
   - In AWS Console search bar, type "RDS" and select **RDS** service
   - In left navigation panel, click **Subnet groups**
   - Click **Create DB subnet group**
   - Name: `wordpress-db-subnet-group`
   - Description: `Subnet group for WordPress RDS database`
   - VPC: Select `wordpress-vpc`
   - Availability Zones: Select the two AZs you used for subnets
   - Subnets: Select both private subnets (`wordpress-private-1a` and `wordpress-private-1b`)
   - Click **Create**

2. **Create Database Security Group**
   - Search for "EC2" in the console search bar
   - In left navigation, scroll down and click **Security Groups**
   - Click **Create security group**
   - Security group name: `wordpress-db-sg`
   - Description: `Security group for WordPress RDS database`
   - VPC: Select `wordpress-vpc`
   - **Inbound rules**: Leave empty for now (will add after creating web server security group)
   - **Outbound rules**: Keep default (All traffic to 0.0.0.0/0)
   - Click **Create security group**

3. **Launch RDS Multi-AZ Instance**
   - Return to RDS console
   - In left navigation, click **Databases**
   - Click **Create database**
   - **Choose a database creation method**: Standard create
   - **Engine options**: MySQL
   - **Version**: MySQL 8.0.35 (or latest available)
   - **Templates**: Select **Production** (this enables Multi-AZ by default)
   - **DB instance identifier**: `wordpress-database`
   - **Master username**: `admin`
   - **Credentials management**: Self managed
   - **Master password**: Create a strong password and save it securely
   - **DB instance class**: Burstable classes - `db.t3.micro`
   - **Storage type**: General Purpose SSD (gp3)
   - **Allocated storage**: 20 GiB
   - **Storage autoscaling**: Disable (uncheck "Enable storage autoscaling")
   - **Connectivity**:
     - **Compute resource**: Don't connect to an EC2 compute resource
     - **VPC**: Select `wordpress-vpc`
     - **DB subnet group**: Select `wordpress-db-subnet-group`
     - **Public access**: No
     - **VPC security groups**: Choose existing - select `wordpress-db-sg`
     - **Availability Zone**: No preference
   - **Database authentication**: Password authentication
   - **Additional configuration**:
     - **Initial database name**: `wordpressdb`
     - **Backup retention period**: 7 days
     - **Backup window**: Default
     - **Maintenance window**: Default
     - **Deletion protection**: Disable (for easier cleanup)
   - Click **Create database**
   - Wait 10-15 minutes for database to become available

### Step 3: Application Layer Security Groups
1. **Create ALB Security Group**
   - In EC2 console, navigate to **Security Groups**
   - Click **Create security group**
   - Security group name: `wordpress-alb-sg`
   - Description: `Security group for WordPress Application Load Balancer`
   - VPC: Select `wordpress-vpc`
   - **Inbound rules** - Click **Add rule** for each:
     - Type: HTTP, Protocol: TCP, Port range: 80, Source: 0.0.0.0/0 (Anywhere-IPv4)
     - Type: HTTPS, Protocol: TCP, Port range: 443, Source: 0.0.0.0/0 (Anywhere-IPv4)
   - **Outbound rules**: Keep default (All traffic)
   - Click **Create security group**

2. **Create Web Server Security Group**
   - Click **Create security group** again
   - Security group name: `wordpress-web-sg`
   - Description: `Security group for WordPress web servers`
   - VPC: Select `wordpress-vpc`
   - **Inbound rules** - Click **Add rule** for each:
     - Type: HTTP, Protocol: TCP, Port range: 80, Source: Custom, then select `wordpress-alb-sg`
     - Type: HTTPS, Protocol: TCP, Port range: 443, Source: Custom, then select `wordpress-alb-sg`
   - **Outbound rules**: Keep default (All traffic)
   - Click **Create security group**

3. **Update Database Security Group**
   - Go back to **Security Groups** and select `wordpress-db-sg`
   - Click **Inbound rules** tab, then **Edit inbound rules**
   - Click **Add rule**:
     - Type: MYSQL/Aurora, Protocol: TCP, Port range: 3306, Source: Custom, then select `wordpress-web-sg`
   - Click **Save rules**

### Step 4: IAM Instance Profile
1. **Create IAM Role**
   - In AWS Console search bar, type "IAM" and select **IAM** service
   - In left navigation, click **Roles**
   - Click **Create role**
   - **Trusted entity type**: AWS service
   - **Use case**: EC2, then click **Next**
   - **Permissions policies**: 
     - Search for "AmazonSSMManagedInstanceCore" and check the box
     - Or create a custom policy using the `iam_ssm_policy.json` from assets folder:
       - Click **Create policy** (opens new tab)
       - Click **JSON** tab and paste the content from `iam_ssm_policy.json`
       - Click **Next**, then **Next** again
       - Policy name: `WordPress-EC2-SSM-Policy`
       - Click **Create policy**
       - Return to role creation tab and refresh, then select your custom policy
   - Click **Next**
   - **Role name**: `wordpress-ec2-ssm-role`
   - **Description**: `IAM role for WordPress EC2 instances with SSM access`
   - Click **Create role**

2. **Verify Instance Profile**
   - The instance profile is automatically created with the same name as the role
   - You can verify by going to **Roles** → select `wordpress-ec2-ssm-role` → **Trust relationships** tab

### Step 5: Launch Template Creation
1. **Get RDS Endpoint**
   - Go to RDS console → **Databases**
   - Click on your `wordpress-database`
   - In **Connectivity & security** section, copy the **Endpoint** value
   - Note down your database password

2. **Prepare User Data Script**
   - Open the `user_data.sh` file from the assets folder
   - Update these lines with your actual values:
     ```bash
     DB_HOST="your-actual-rds-endpoint-here"
     DB_PASSWORD="your-actual-db-password-here"
     ```

3. **Create Launch Template**
   - In EC2 console, go to **Launch Templates** in left navigation
   - Click **Create launch template**
   - **Launch template name**: `wordpress-launch-template`
   - **Template version description**: `WordPress LAMP stack with RDS connectivity`
   - **Application and OS Images (Amazon Machine Image)**:
     - Quick Start: Amazon Linux
     - Amazon Machine Image: Amazon Linux 2023 AMI (latest)
   - **Instance type**: t2.micro
   - **Key pair**: None (we'll use Systems Manager for access)
   - **Network settings**:
     - **Subnet**: Don't include in launch template
     - **Security groups**: Select existing security group → `wordpress-web-sg`
   - **Advanced details**:
     - **IAM instance profile**: Select `wordpress-ec2-ssm-role`
     - **User data**: Paste the updated content from `user_data.sh`
   - Click **Create launch template**

### Step 6: Auto Scaling Group Configuration
1. **Create Auto Scaling Group**
   - In EC2 console, go to **Auto Scaling Groups** in left navigation
   - Click **Create Auto Scaling group**
   - **Step 1 - Choose launch template**:
     - Auto Scaling group name: `wordpress-asg`
     - Launch template: Select `wordpress-launch-template`
     - Version: Latest
     - Click **Next**
   - **Step 2 - Choose instance launch options**:
     - VPC: Select `wordpress-vpc`
     - Availability Zones and subnets: Select both private subnets:
       - `wordpress-private-1a`
       - `wordpress-private-1b`
     - Click **Next**
   - **Step 3 - Configure advanced options**:
     - **Load balancing**: Attach to a new load balancer
     - **Load balancer type**: Application Load Balancer
     - **Load balancer name**: `wordpress-alb`
     - **Load balancer scheme**: Internet-facing
     - **Availability Zones and subnets**: Select both public subnets
     - **Default routing**: Create a target group
     - **New target group name**: `wordpress-tg`
     - **Health checks**: Turn on Elastic Load Balancing health checks
     - **Health check grace period**: 300 seconds
     - Click **Next**
   - **Step 4 - Configure group size and scaling**:
     - **Desired capacity**: 2
     - **Minimum capacity**: 1
     - **Maximum capacity**: 4
     - **Scaling policies**: None (can be added later)
     - Click **Next**
   - **Step 5 - Add notifications**: Skip, click **Next**
   - **Step 6 - Add tags**:
     - Add tag: Key = `Name`, Value = `WordPress-WebServer`
     - Click **Next**
   - **Step 7 - Review**: Click **Create Auto Scaling group**

### Step 7: Application Load Balancer Setup
1. **Configure Load Balancer Security Group**
   - The ALB was created in the previous step, but we need to update its security group
   - Go to **Load Balancers** in EC2 console
   - Select `wordpress-alb`
   - Scroll down to **Security** section and click **Edit**
   - Remove the default security group and add `wordpress-alb-sg`
   - Click **Save changes**

2. **Verify Target Group Configuration**
   - Go to **Target Groups** in EC2 console
   - Select `wordpress-tg`
   - Click **Health checks** tab
   - **Health check path**: Change from `/` to `/health.php` (optional - our user data creates this endpoint)
   - **Health check interval**: 30 seconds
   - **Healthy threshold**: 2
   - **Unhealthy threshold**: 5
   - Click **Save changes**

3. **Test Load Balancer**
   - Go back to **Load Balancers** and select `wordpress-alb`
   - Copy the **DNS name** (it looks like: wordpress-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com)
   - Wait 5-10 minutes for instances to become healthy in target group
   - Open the DNS name in your browser to access WordPress

### Step 8: Testing and WordPress Configuration
1. **Wait for Infrastructure Deployment**
   - Allow 10-15 minutes for all resources to be ready
   - **Monitor Auto Scaling Group**:
     - Go to **Auto Scaling Groups** → select `wordpress-asg`
     - **Instance management** tab should show 2 instances "InService"
   - **Check Target Group Health**:
     - Go to **Target Groups** → select `wordpress-tg`
     - **Targets** tab should show 2 healthy targets

2. **Access WordPress Setup**
   - Go to **Load Balancers** → select `wordpress-alb`
   - Copy the **DNS name**
   - Open a web browser and navigate to: `http://[ALB-DNS-NAME]`
   - You should see the WordPress installation wizard
   - **If you see an error**: Wait a few more minutes or check the troubleshooting section

3. **Complete WordPress Installation**
   - Follow the WordPress setup wizard:
     - Select your language
     - Click "Let's go!" to configure database
     - Database connection details should already be configured by the user data script
     - If prompted for database details, use:
       - Database Name: `wordpressdb`
       - Username: `admin`
       - Password: [your RDS password]
       - Database Host: [your RDS endpoint]
       - Table Prefix: `wp_`
   - Complete the site information (site title, admin username, password, email)
   - Click "Install WordPress"

4. **Test High Availability**
   - **Test instance replacement**:
     - Go to **Auto Scaling Groups** → `wordpress-asg` → **Instance management**
     - Select one instance and click **Actions** → **Detach**
     - Choose "Decrement desired capacity" and click **Detach instance**
     - Wait 2-3 minutes for a new instance to launch
     - Verify website remains accessible during the process
   - **Test load balancing**:
     - Refresh your browser multiple times
     - Each request may be served by different instances (though this is transparent to users)

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

### Step 1: Delete Auto Scaling Group
1. Go to **EC2 Console** → **Auto Scaling Groups**
2. Select `wordpress-asg`
3. Click **Actions** → **Delete**
4. Type "delete" in the confirmation field
5. Click **Delete**
6. This will automatically terminate all EC2 instances
7. Wait for all instances to terminate (5-10 minutes)

### Step 2: Delete Application Load Balancer
1. Go to **EC2 Console** → **Load Balancers**
2. Select `wordpress-alb`
3. Click **Actions** → **Delete load balancer**
4. Type "confirm" in the confirmation field
5. Click **Delete**
6. Wait for deletion to complete (5-10 minutes)

### Step 3: Delete Target Group
1. Go to **EC2 Console** → **Target Groups**
2. Select `wordpress-tg`
3. Click **Actions** → **Delete**
4. Click **Yes, delete**

### Step 4: Delete Launch Template
1. Go to **EC2 Console** → **Launch Templates**
2. Select `wordpress-launch-template`
3. Click **Actions** → **Delete template**
4. Type "delete" in the confirmation field
5. Click **Delete**

### Step 5: Delete RDS Database
1. Go to **RDS Console** → **Databases**
2. Select your WordPress database
3. Click **Actions** → **Delete**
4. **Uncheck** "Create final snapshot" (to avoid storage costs)
5. **Uncheck** "Retain automated backups"
6. **Check** "I acknowledge that upon instance deletion, automated backups will be deleted"
7. Type "delete me" in the confirmation field
8. Click **Delete DB instance**
9. Wait 10-15 minutes for deletion to complete

### Step 6: Delete DB Subnet Group
1. **RDS Console** → **Subnet groups**
2. Select `wordpress-db-subnet-group`
3. Click **Delete**
4. Click **Delete** to confirm

### Step 7: Delete Security Groups
1. Go to **EC2 Console** → **Security Groups**
2. Delete in this order (due to dependencies):
   - Select `wordpress-web-sg` → **Actions** → **Delete security groups** → **Delete**
   - Select `wordpress-alb-sg` → **Actions** → **Delete security groups** → **Delete**
   - Select `wordpress-db-sg` → **Actions** → **Delete security groups** → **Delete**

### Step 8: Delete IAM Resources
1. Go to **IAM Console** → **Roles**
2. Search for `wordpress-ec2-ssm-role`
3. Select the role and click **Delete**
4. Type the role name in the confirmation field
5. Click **Delete**

### Step 9: Delete VPC Resources
1. **Detach and Delete Internet Gateway**:
   - Go to **VPC Console** → **Internet Gateways**
   - Select `wordpress-igw`
   - Click **Actions** → **Detach from VPC**
   - Select the VPC and click **Detach internet gateway**
   - With the gateway still selected, click **Actions** → **Delete internet gateway**
   - Type "delete" and click **Delete internet gateway**

2. **Delete VPC** (this automatically deletes subnets and route tables):
   - Go to **VPC Console** → **Your VPCs**
   - Select `wordpress-vpc`
   - Click **Actions** → **Delete VPC**
   - Type "delete" in the confirmation field
   - Click **Delete VPC**

### Step 10: Verify Cleanup
1. **Check AWS Billing Dashboard** for any remaining charges
2. **Verify resource deletion** in each service console:
   - EC2: No running instances, load balancers, or target groups
   - RDS: No databases or subnet groups
   - VPC: No custom VPCs, internet gateways, or security groups
   - IAM: No custom roles
3. Resources should stop incurring charges within 1-2 hours

### Troubleshooting Cleanup Issues
- **"Resource has dependencies"**: Check if any resources are still referencing the item you're trying to delete
- **Security group deletion fails**: Ensure no EC2 instances or load balancers are using the security group
- **VPC deletion fails**: Verify all subnets, internet gateways, and other VPC components are deleted first

## 10. Associated Project Files

The following files are included in the `assets` folder for this project:

- **`user_data.sh`**: Complete EC2 user data script that installs LAMP stack, downloads WordPress, and configures database connectivity. Includes error handling and logging for troubleshooting.

- **`iam_ssm_policy.json`**: IAM policy document that grants EC2 instances the necessary permissions for AWS Systems Manager Session Manager access. This eliminates the need for SSH access and demonstrates security best practices.

These files contain production-ready code with proper error handling, security considerations, and detailed comments for educational purposes.
