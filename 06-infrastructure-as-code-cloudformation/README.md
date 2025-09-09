# Project 6: Automate a VPC Deployment with AWS CloudFormation

## 1. Objective

In this project, you will learn to automate infrastructure deployment using AWS CloudFormation, Amazon's Infrastructure as Code (IaC) service. You'll take the three-tier network architecture from Project 5 (which was created manually through the AWS console) and define it as code using a CloudFormation template. This approach transforms infrastructure management from manual, error-prone processes into automated, repeatable, and version-controlled deployments.

By completing this project, you will understand how to:
- Write comprehensive CloudFormation templates using YAML syntax
- Use CloudFormation parameters, mappings, and outputs for flexible deployments
- Deploy and manage AWS infrastructure through code
- Troubleshoot common CloudFormation deployment issues
- Implement Infrastructure as Code best practices

The goal is to demonstrate how the same complex network infrastructure can be deployed consistently across different environments (development, staging, production) with a single command, eliminating configuration drift and human errors.

## 2. AWS Services Used

**Primary Service:**
- **AWS CloudFormation** - Infrastructure as Code service for automating resource deployment

**Infrastructure Services Being Deployed:**
- **Amazon VPC** - Virtual Private Cloud for network isolation
- **Amazon EC2** - Virtual servers for web and application tiers
- **Internet Gateway** - Provides internet access to public subnets
- **NAT Gateway** - Enables internet access for private subnet resources
- **Route Tables** - Controls network traffic routing
- **Security Groups** - Virtual firewalls for EC2 instances
- **IAM** - Identity and Access Management for EC2 instance roles

## 3. Difficulty

**Intermediate** - This project requires understanding of AWS networking concepts from Project 5 and introduces Infrastructure as Code principles. You'll work with CloudFormation syntax and troubleshoot deployment issues.

## 4. Architecture Diagram

```
                    ┌─────────────────────────────────────────────────────┐
                    │                  Internet                           │
                    └─────────────────────┬───────────────────────────────┘
                                          │
                              ┌───────────▼────────────┐
                              │    Internet Gateway    │
                              └───────────┬────────────┘
                                          │
    ┌─────────────────────────────────────▼─────────────────────────────────────┐
    │                           VPC (10.0.0.0/16)                                │
    │  ┌─────────────────────┬─────────────────────┬─────────────────────────┐  │
    │  │   PUBLIC SUBNET 1   │   PUBLIC SUBNET 2   │    PUBLIC SUBNET 3      │  │
    │  │   (10.0.1.0/24)     │   (10.0.2.0/24)     │    (10.0.3.0/24)        │  │
    │  │  ┌───────────────┐  │  ┌───────────────┐  │                         │  │
    │  │  │  Web Server   │  │  │  Web Server   │  │    ┌─────────────────┐  │  │
    │  │  │  (Nginx)      │  │  │  (Nginx)      │  │    │   NAT Gateway   │  │  │
    │  │  │               │  │  │               │  │    │                 │  │  │
    │  │  └───────────────┘  │  └───────────────┘  │    └─────────────────┘  │  │
    │  └─────────────────────┴─────────────────────┴─────────────────────────┘  │
    │                                          │                                 │
    │  ┌─────────────────────┬─────────────────────┬─────────────────────────┐  │
    │  │  PRIVATE SUBNET 1   │  PRIVATE SUBNET 2   │   PRIVATE SUBNET 3      │  │
    │  │   (10.0.4.0/24)     │   (10.0.5.0/24)     │    (10.0.6.0/24)        │  │
    │  │  ┌───────────────┐  │  ┌───────────────┐  │                         │  │
    │  │  │  App Server   │  │  │  App Server   │  │                         │  │
    │  │  │               │  │  │               │  │                         │  │
    │  │  │               │  │  │               │  │                         │  │
    │  │  └───────────────┘  │  └───────────────┘  │                         │  │
    │  └─────────────────────┴─────────────────────┴─────────────────────────┘  │
    └─────────────────────────────────────────────────────────────────────────────┘

    📋 CloudFormation Stack manages ALL resources above as code
    🔄 Single template deployment creates entire infrastructure
    🗑️ Single stack deletion removes all resources cleanly
```

## 5. Prerequisites

- Ensure you have completed the initial setup detailed in the main [PREREQUISITES.md](../PREREQUISITES.md) file in the repository root.

## 6. Step-by-Step Guide

### Phase 1: Understanding the CloudFormation Template

Before deploying, let's examine the key components of our `template.yml` file:

**1. Template Structure Overview**
Our CloudFormation template is organized into these main sections:

```yaml
AWSTemplateFormatVersion: '2010-09-09'  # CloudFormation template version
Description: 'Three-tier VPC architecture with web and app servers'
Parameters:    # Input values for customization
Mappings:      # Static lookup tables (e.g., AMI IDs by region)
Resources:     # AWS resources to create
Outputs:       # Values to return after stack creation
```

**2. Parameters Section**
Parameters make your template flexible and reusable:
```yaml
Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    Description: EC2 instance type for web and app servers
```
This allows you to specify different instance types for different environments without changing the template code.

**3. Mappings Section**
Mappings provide static lookups, commonly used for AMI IDs that vary by region:
```yaml
Mappings:
  RegionMap:
    us-east-1:
      AMI: ami-0abcdef1234567890
```

**4. Key Resource Examples**

**VPC Resource:**
```yaml
VPC:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16
    EnableDnsHostnames: true
    EnableDnsSupport: true
```

**EC2 Instance with Reference:**
```yaml
WebServer1:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: !FindInMap [RegionMap, !Ref 'AWS::Region', AMI]
    InstanceType: !Ref InstanceType
    SubnetId: !Ref PublicSubnet1
    SecurityGroupIds:
      - !Ref WebSecurityGroup
```

Notice how `!Ref` creates dependencies between resources, and CloudFormation automatically determines the correct creation order.

**5. Outputs Section**
Outputs provide useful information after deployment:
```yaml
Outputs:
  WebServer1PublicIP:
    Description: Public IP of Web Server 1
    Value: !GetAtt WebServer1.PublicIp
```

### Phase 2: Deploying the Stack

**Step 1: Access CloudFormation Console**
1. Sign in to the AWS Management Console
2. Navigate to **Services** → **Management & Governance** → **CloudFormation**
3. Ensure you're in your preferred region (e.g., us-east-1)

**Step 2: Create the Stack**
1. Click **Create stack** → **With new resources (standard)**
2. Under **Specify template**:
   - Select **Upload a template file**
   - Click **Choose file** and select `assets/template.yml` from this project
   - Click **Next**

**Step 3: Configure Stack Details**
1. **Stack name**: Enter `three-tier-vpc-stack` (or your preferred name)
2. **Parameters section**: Review the default values:
   - **InstanceType**: Leave as `t2.micro` (Free Tier eligible)
   - **KeyPairName**: Select an existing EC2 Key Pair (create one if needed)
3. Click **Next**

**Step 4: Configure Stack Options**
1. **Tags** (optional): Add tags like `Project: CloudFormation-Demo`
2. **Permissions**: Leave **IAM role** empty (uses your current permissions)
3. **Advanced options**: Leave defaults
4. Click **Next**

**Step 5: Review and Create**
1. Review all settings carefully
2. Check the box: **I acknowledge that AWS CloudFormation might create IAM resources**
3. Click **Submit**

### Phase 3: Monitoring Stack Creation

**Understanding Stack Status:**
- **CREATE_IN_PROGRESS**: Resources are being created
- **CREATE_COMPLETE**: All resources created successfully
- **CREATE_FAILED**: Creation failed (stack will rollback)
- **ROLLBACK_COMPLETE**: Failed creation was cleaned up

**Monitoring Progress:**
1. In the CloudFormation console, click on your stack name
2. Go to the **Events** tab to see real-time progress
3. Watch as resources are created in dependency order:
   - VPC → Internet Gateway → Subnets → Route Tables → Security Groups → EC2 Instances

**Typical Creation Time:** 5-10 minutes (NAT Gateway takes the longest)

### Phase 4: Verifying Resources

**Step 1: Check Stack Outputs**
1. In your completed stack, click the **Outputs** tab
2. Note important values like:
   - `WebServer1PublicIP`: IP address to test web server
   - `VPCId`: ID of the created VPC

**Step 2: Verify VPC Resources**
1. Navigate to **VPC** console
2. Confirm creation of:
   - 1 VPC with CIDR 10.0.0.0/16
   - 6 subnets (3 public, 3 private)
   - 1 Internet Gateway attached to VPC
   - 1 NAT Gateway in public subnet
   - Route tables with correct routes

**Step 3: Test Web Servers**
1. Copy the **WebServer1PublicIP** from stack outputs
2. Open a browser and navigate to `http://[WebServer1PublicIP]`
3. You should see the Nginx welcome page
4. Repeat for WebServer2PublicIP

### Phase 5: Exploring CloudFormation Features

**View Template in Console:**
1. In your stack, go to **Template** tab
2. Review the processed template with all references resolved

**Understand Resource Dependencies:**
1. Go to **Resources** tab
2. Click on any resource to see its details
3. Notice how resources reference each other through their CloudFormation logical names

### Phase 6: Cleaning Up

**The Power of IaC - One-Click Cleanup:**
1. In the CloudFormation console, select your stack
2. Click **Delete**
3. Confirm deletion by typing the stack name
4. Watch as CloudFormation automatically:
   - Determines the correct deletion order
   - Removes all resources that were part of the stack
   - Handles dependencies (e.g., detaches Internet Gateway before deleting VPC)

**Cleanup Time:** 5-8 minutes (NAT Gateway deletion takes longest)

## 7. Troubleshooting Common Issues

### 1. **Problem: Stack creation fails and enters `ROLLBACK_COMPLETE` state**

**Potential Causes:**
- Syntax error in the CloudFormation template
- Invalid parameter value (e.g., non-existent EC2 instance type)
- Resource limit exceeded (e.g., VPC limit reached)
- Insufficient IAM permissions for stack deployment
- Resource name conflicts with existing resources

**Solution:**
1. Go to the **Events** tab of your failed stack
2. Scroll down to find the first event with status `CREATE_FAILED`
3. Read the **Status reason** column - this contains the exact error message
4. Common specific solutions:
   - **"InvalidInstanceID.NotFound"**: Check if the AMI ID exists in your region
   - **"InvalidKeyPair.NotFound"**: Ensure the KeyPair parameter references an existing key pair
   - **"LimitExceeded"**: Check service limits in AWS Service Quotas console
   - **"AccessDenied"**: Verify your IAM user has necessary permissions (EC2, VPC, IAM)

### 2. **Problem: Stack gets stuck in `UPDATE_ROLLBACK_FAILED` state during an update**

**Potential Causes:**
- Resource was manually modified outside of CloudFormation (configuration drift)
- Dependency conflicts during rollback
- Resource in an inconsistent state that prevents rollback

**Solution:**
1. **For beginners**: Delete the stack and recreate it - this is often the simplest solution
2. **For advanced users**: 
   - Click **Continue update rollback** in the console
   - Identify resources causing rollback failure
   - Manually fix the resource state or skip the problematic resource
   - For learning purposes, document what manual changes were made outside CloudFormation

### 3. **Problem: Template validation fails during stack creation**

**Potential Causes:**
- YAML syntax errors (indentation, missing colons)
- Invalid CloudFormation functions or references
- Circular dependencies between resources

**Solution:**
1. Use the **Validate template** feature in CloudFormation console before creating stack
2. Check YAML syntax using online validators
3. Verify all `!Ref` and `!GetAtt` references point to valid resources
4. Review the CloudFormation documentation for correct resource property syntax

### 4. **Problem: EC2 instances created but web server not accessible**

**Potential Causes:**
- User data script failed to install Nginx properly
- Security group rules blocking HTTP traffic
- Instance in private subnet but accessed as if public

**Solution:**
1. SSH into the instance and check system logs: `sudo tail -f /var/log/cloud-init-output.log`
2. Verify Nginx is running: `sudo systemctl status nginx`
3. Check security group allows inbound HTTP (port 80) from 0.0.0.0/0
4. Confirm instance is in public subnet with Internet Gateway route

### 5. **Problem: "Parameter validation failed" error**

**Potential Causes:**
- Parameter constraints not met (e.g., instance type not allowed in region)
- Required parameters missing values
- Parameter values don't match expected format

**Solution:**
1. Review parameter constraints in the template
2. Ensure all required parameters have values
3. Verify parameter values match AWS requirements (e.g., valid instance types for region)
4. Check parameter descriptions for guidance on expected values

## 8. Learning Materials & Key Concepts

### **Concept 1: Infrastructure as Code (IaC)**

**Definition:** Infrastructure as Code is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

**Core Benefits:**
- **Automation**: Eliminate manual, error-prone infrastructure setup
- **Repeatability**: Deploy identical environments consistently across regions/accounts
- **Version Control**: Track infrastructure changes using Git, enabling rollbacks and change history
- **Peer Review**: Infrastructure changes go through code review processes
- **Documentation**: The template serves as living documentation of your architecture
- **Cost Control**: Easily tear down entire environments when not needed

**SAA-C03 Relevance:** Understanding IaC principles is crucial for designing scalable, maintainable architectures that can be deployed consistently across multiple environments.

### **Concept 2: CloudFormation Fundamentals**

**Stack:** A collection of AWS resources managed as a single unit. When you create, update, or delete a stack, all resources in that stack are affected together.

**Template:** A JSON or YAML formatted text file that describes the AWS resources you want to create. Templates are declarative - you specify what you want, not how to create it.

**Key Template Sections:**
- **Parameters**: Input values that make templates flexible and reusable across environments
- **Mappings**: Static lookup tables for conditional values (e.g., AMI IDs by region)
- **Resources**: The AWS components to create (VPC, EC2, RDS, etc.)
- **Outputs**: Values returned after stack creation, useful for integration with other stacks

**Functions:** CloudFormation provides intrinsic functions like `!Ref`, `!GetAtt`, and `!Sub` for creating dynamic references between resources.

### **Concept 3: Declarative vs. Imperative**

**Declarative (CloudFormation):** You describe the desired end state, and CloudFormation figures out how to achieve it. Example: "I want a VPC with these subnets and these security groups."

**Imperative (Traditional Scripting):** You specify the exact steps to execute. Example: "First create VPC, then create subnet 1, then create subnet 2, etc."

**Benefits of Declarative:**
- CloudFormation automatically determines resource creation order based on dependencies
- Updates are handled intelligently (only changes what needs to change)
- Rollback is automatic if any resource fails to create
- Drift detection can identify manual changes made outside CloudFormation

### **Concept 4: Change Sets and Drift Detection**

**Change Sets:** Before updating a stack, you can create a change set to preview exactly what changes will be made:
- Which resources will be added, modified, or deleted
- Whether changes require resource replacement (downtime)
- Impact assessment before applying changes

**Drift Detection:** CloudFormation can detect when resources have been modified outside of CloudFormation:
- Compare current resource configuration with template definition
- Identify configuration drift that might cause future updates to fail
- Helps maintain infrastructure consistency

**Best Practice:** Always use change sets for production updates and regularly run drift detection to ensure template accuracy.

### **Concept 5: Stack Dependencies and Nested Stacks**

**Cross-Stack References:** Use Outputs from one stack as Inputs to another stack, enabling modular architecture:
- Network stack exports VPC and subnet IDs
- Application stack imports these values for EC2 deployment
- Database stack can be managed separately from compute resources

**Nested Stacks:** Large templates can be broken into smaller, reusable components:
- Parent template orchestrates child templates
- Promotes code reuse and easier maintenance
- Enables team specialization (network team, security team, application team)

## 9. Cost & Free Tier Eligibility

**CloudFormation Service:** AWS CloudFormation itself is **free** - you only pay for the AWS resources that your templates create and manage.

**Resources Created by This Template:**
- **EC2 Instances (4x t2.micro)**: Free Tier provides 750 hours/month of t2.micro usage
- **NAT Gateway**: ~$32/month (this is the primary cost - not Free Tier eligible)
- **VPC, Subnets, Internet Gateway, Route Tables, Security Groups**: Free
- **Data Transfer**: First 1GB/month free, then $0.09/GB

**Estimated Monthly Cost:**
- **With Free Tier**: ~$32/month (primarily NAT Gateway)
- **Without Free Tier**: ~$45/month (adds EC2 instance costs)

**Cost Optimization Tips:**
- Delete the stack when not actively using it
- Consider using NAT Instances instead of NAT Gateway for learning (though less managed)
- Use CloudFormation's cost estimation feature during stack creation

## 10. Cleanup Instructions

**The Primary Benefit of Infrastructure as Code - Effortless Cleanup:**

1. **Navigate to CloudFormation Console**
   - Go to **Services** → **CloudFormation**
   - Select the stack you created (e.g., `three-tier-vpc-stack`)

2. **Delete the Stack**
   - Click **Delete**
   - Type the stack name to confirm deletion
   - Click **Delete stack**

3. **Monitor Deletion Progress**
   - Watch the **Events** tab as resources are deleted
   - CloudFormation automatically handles the correct deletion order:
     - EC2 Instances → NAT Gateway → Route Tables → Subnets → Internet Gateway → VPC
   - Deletion typically takes 5-8 minutes

4. **Verify Complete Cleanup**
   - Stack status shows `DELETE_COMPLETE`
   - Verify in VPC console that all resources are removed
   - Check EC2 console that instances are terminated

**Comparison with Manual Cleanup:**
- **Manual Process**: 15-20 steps, easy to miss resources, potential for orphaned resources
- **CloudFormation**: 1 click, automatic dependency handling, guaranteed complete cleanup

This demonstrates one of the most powerful benefits of Infrastructure as Code - the ability to completely and cleanly remove complex infrastructure with a single action.

## 11. Associated Project Files

### `assets/template.yml`
A comprehensive CloudFormation template that creates the complete three-tier VPC architecture. This template demonstrates Infrastructure as Code best practices including:
- Parameterized inputs for flexibility across environments
- Region-specific AMI mappings for portability
- Logical resource naming and comprehensive tagging
- Proper security group configurations with least privilege access
- Outputs for integration with other stacks or external tools

### `assets/install_nginx.sh`
A user data script that automatically installs and configures the Nginx web server on EC2 instances. This script:
- Updates the system packages
- Installs Nginx web server
- Starts and enables Nginx service
- Creates a simple custom welcome page
- Ensures the web server is accessible immediately after instance launch

This demonstrates how CloudFormation can integrate with instance bootstrapping to create fully functional infrastructure in a single deployment.
