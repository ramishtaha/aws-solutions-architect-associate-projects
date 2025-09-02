# 10 Hands-On Projects for AWS Solutions Architect Associate (SAA-C03) Preparation

## Introduction

Welcome to this comprehensive hands-on learning repository designed specifically for students preparing for the AWS Solutions Architect - Associate (SAA-C03) certification exam. This repository contains 10 carefully crafted projects that progressively build your practical experience with core AWS services while reinforcing key architectural concepts tested in the SAA-C03 exam.

Each project is designed to be:
- **Hands-on and practical**: You'll build real AWS solutions, not just read theory
- **Exam-focused**: Every project reinforces concepts directly tested in SAA-C03
- **Cost-conscious**: Most projects can be completed within AWS Free Tier limits
- **Progressive**: Projects increase in complexity to build your confidence gradually

## How to Use This Repository

1. **Start with Project 1** and work through them sequentially for the best learning experience
2. **Follow the cleanup instructions** carefully after each project to avoid unnecessary costs
3. **Study the "Learning Materials & Key Concepts"** section of each project to understand the architectural principles
4. **Practice multiple times** - repetition is key to retaining the knowledge for the exam

## Projects Overview

| Project # | Project Title | Core AWS Services | Difficulty | Description |
|-----------|---------------|------------------|------------|-------------|
| 01 | Host a Static Website on S3 with CloudFront and Route 53 | S3, CloudFront, Route 53, Certificate Manager | Beginner | Learn static website hosting, CDN distribution, DNS management, and SSL/TLS certificates |
| 02 | Create a Serverless API using API Gateway, Lambda, and DynamoDB | API Gateway, Lambda, DynamoDB, IAM | Beginner | Build a complete serverless backend with RESTful API, compute functions, and NoSQL database |
| 03 | Decouple an Application with SQS and Lambda | SQS, Lambda, CloudWatch, IAM | Beginner | Implement message queuing for application decoupling and asynchronous processing |
| 04 | Deploy a Fault-Tolerant WordPress Site | EC2, ALB, RDS, VPC, Auto Scaling | Intermediate | Build a scalable, highly available web application with load balancing and database redundancy |
| 05 | Build a Secure Three-Tier Network Architecture | VPC, Subnets, NAT Gateway, Bastion Host, Security Groups, NACLs | Intermediate | Design and implement a secure network foundation with proper tier isolation |
| 06 | Automate Infrastructure with CloudFormation | CloudFormation, EC2, VPC, RDS | Intermediate | Learn Infrastructure as Code principles by automating the deployment from Project 5 |
| 07 | Implement Cross-Region Disaster Recovery | S3 Cross-Region Replication, RDS Cross-Region Snapshots, Route 53 Health Checks | Intermediate | Design and implement disaster recovery strategies for business continuity |
| 08 | Create a Data Processing Pipeline | S3 Event Notifications, Lambda, Kinesis Data Firehose, CloudWatch | Advanced | Build an event-driven data processing workflow for analytics |
| 09 | Deploy Containerized Application with ECS Fargate | ECS, Fargate, ECR, Application Load Balancer, CloudWatch | Advanced | Learn container orchestration and serverless container deployment |
| 10 | Analyze Security and Cost Optimization | AWS Trusted Advisor, AWS Budgets, Cost Explorer, AWS Well-Architected Tool | Advanced | Implement monitoring, cost optimization, and security best practices analysis |

## Learning Path Recommendation

- **Beginners**: Start with Projects 1-3 to build foundational knowledge
- **Intermediate learners**: Focus on Projects 4-7 for core architectural patterns
- **Advanced learners**: Challenge yourself with Projects 8-10 for complex scenarios

## Prerequisites

**🚀 Before starting any projects, please complete the one-time setup by following our [Prerequisites Guide](./PREREQUISITES.md).**

The prerequisites guide covers:
- AWS Account creation and security setup (IAM user creation)
- AWS CLI installation and configuration  
- Recommended tools installation (VS Code, Git)
- Cost management and billing alerts setup

This setup takes about 30-45 minutes but is essential for all projects in this repository.

## Cost Considerations

Most projects in this repository are designed to work within AWS Free Tier limits. However, always:
- Monitor your AWS billing dashboard
- Follow cleanup instructions after each project
- Set up billing alerts using AWS Budgets (covered in Project 10)

## Contributing

Found an error or want to suggest improvements? Feel free to open an issue or submit a pull request!

## Certification Resources

- [AWS Solutions Architect Associate Official Exam Guide](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## Disclaimer

This repository is created for educational purposes. Always follow AWS best practices and security guidelines when working with AWS services. The authors are not responsible for any costs incurred while following these tutorials.

---

**Ready to start your AWS journey? Begin with [Project 01: Host a Static Website](./01-static-website/README.md)!**
