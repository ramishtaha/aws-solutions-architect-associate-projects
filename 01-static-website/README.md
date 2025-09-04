# Project 01: Host a Static Website on S3 with CloudFront and Route 53

## 1. Objective
Build a complete static website hosting solution using AWS services that is scalable, secure, and globally distributed. You will learn how to host static content on S3, distribute it globally via CloudFront CDN, secure it with SSL/TLS certificates, and configure custom domain routing with Route 53. This project demonstrates cost-effective web hosting architecture patterns commonly tested in the SAA-C03 exam.

## 2. AWS Services Used
- **Amazon S3** (Static website hosting and storage)
- **Amazon CloudFront** (Content Delivery Network)
- **Amazon Route 53** (DNS management and domain routing)
- **AWS Certificate Manager** (SSL/TLS certificate provisioning)
- **AWS IAM** (Identity and Access Management for security)

## 3. Difficulty
**Beginner**

## 4. Architecture Diagram
```
┌─────────────┐    DNS Query     ┌─────────────┐
│   User      │ ────────────────> │  Route 53   │
└─────────────┘                  └─────────────┘
       │                                │
       │ HTTPS Request                  │ Returns CloudFront
       │ (SSL/TLS secured)              │ Distribution Domain
       ▼                                ▼
┌─────────────┐    Origin Request  ┌─────────────┐
│ CloudFront  │ ────────────────> │     S3      │
│(Global CDN) │ <──────────────── │   Bucket    │
└─────────────┘    Cached Content  └─────────────┘
       │
       │ Cached Response
       ▼
┌─────────────┐
│   User      │
│ (Fast Load) │
└─────────────┘

Certificate Manager provides SSL/TLS certificate to CloudFront
```

## 5. Prerequisites

**Before starting this project, ensure you have completed the [Prerequisites Guide](../PREREQUISITES.md).**

**Project-specific requirements:**
- A domain name (you can use a free domain from services like Freenom, or purchase one from Route 53)
- Basic knowledge of HTML/CSS (sample files provided in this project)

## 6. Step-by-Step Guide

### Step 1: Create and Configure S3 Bucket for Static Website Hosting

1. **Create S3 Bucket**
   ```bash
   aws s3 mb s3://your-unique-bucket-name-static-website
   ```
   > Replace `your-unique-bucket-name-static-website` with a globally unique name
   > 
   > **Important**: Note which region your bucket is created in. You can check with:
   > ```bash
   > aws s3api get-bucket-location --bucket your-unique-bucket-name-static-website
   > ```

2. **Enable Static Website Hosting**
   ```bash
   aws s3 website s3://your-unique-bucket-name-static-website --index-document index.html --error-document error.html
   ```

3. **Upload Website Files**
   ```bash
   aws s3 cp assets/index.html s3://your-unique-bucket-name-static-website/
   aws s3 cp assets/error.html s3://your-unique-bucket-name-static-website/
   aws s3 cp assets/styles.css s3://your-unique-bucket-name-static-website/
   ```

4. **Disable Block Public Access Settings** (Required for static website hosting)
   
   ⚠️ **Important**: By default, S3 blocks all public access for security. For static website hosting, we need to allow public read access to serve web pages.
   
   ```bash
   aws s3api put-public-access-block --bucket your-unique-bucket-name-static-website --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
   ```
   
   **What this command does:**
   - `BlockPublicAcls=false`: Allows public ACLs
   - `IgnorePublicAcls=false`: Doesn't ignore public ACLs
   - `BlockPublicPolicy=false`: **This is the key setting** - allows public bucket policies
   - `RestrictPublicBuckets=false`: Allows public bucket policies to grant public access

5. **Configure Bucket Policy for Public Read Access**
   
   > **Note**: Update the `bucket-policy.json` file to replace `your-unique-bucket-name-static-website` with your actual bucket name before running this command.
   
   ```bash
   aws s3api put-bucket-policy --bucket your-unique-bucket-name-static-website --policy file://assets/bucket-policy.json
   ```
   
   **If you get an "AccessDenied" error**, it means the Block Public Access settings are still enabled. Make sure you completed Step 4 above.

### Step 2: Request SSL/TLS Certificate from AWS Certificate Manager

1. **Request Certificate (must be in us-east-1 region for CloudFront)**
   ```bash
   aws acm request-certificate --domain-name yourdomain.com --domain-name *.yourdomain.com --validation-method DNS --region us-east-1
   ```
   > Note the Certificate ARN returned for later use

2. **Validate Domain Ownership**
   - Go to AWS Console > Certificate Manager (us-east-1 region)
   - Click on your certificate and note the DNS validation records
   - Add these CNAME records to your domain's DNS settings

### Step 3: Create CloudFront Distribution

1. **Create Distribution Configuration File**
   - Use the provided `assets/cloudfront-config.json` file
   - Replace placeholders with your S3 bucket name and certificate ARN
   - **Critical**: Update the `DomainName` field to match your bucket's region:
     ```
     "DomainName": "your-bucket-name.s3-website-REGION.amazonaws.com"
     ```
     Replace `REGION` with your bucket's actual region (e.g., `us-east-1`, `eu-west-1`, `ap-southeast-1`)
   - To find your bucket's region, run:
     ```bash
     aws s3api get-bucket-location --bucket your-unique-bucket-name-static-website
     ```

2. **Create CloudFront Distribution**
   ```bash
   aws cloudfront create-distribution --distribution-config file://assets/cloudfront-config.json
   ```
   > Note the Distribution ID and Domain Name for later use

3. **Wait for Distribution Deployment** (takes 15-20 minutes)
   ```bash
   aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
   ```
   > Status should change from "InProgress" to "Deployed"

### Step 4: Configure Route 53 for Custom Domain

1. **Create Hosted Zone** (if you don't have one)
   ```bash
   aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)
   ```

2. **Create Alias Record Pointing to CloudFront**
   - Use the provided `assets/route53-record.json` file
   - Replace placeholders with your CloudFront distribution domain

3. **Create the DNS Record**
   ```bash
   aws route53 change-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID --change-batch file://assets/route53-record.json
   ```

### Step 5: Test the Complete Setup

1. **Test HTTP to HTTPS Redirect**
   ```bash
   curl -I http://yourdomain.com
   ```
   > Should return a 301 or 302 redirect to HTTPS

2. **Test HTTPS Access**
   ```bash
   curl -I https://yourdomain.com
   ```
   > Should return 200 OK with proper headers

3. **Test Global CDN Performance**
   - Use online tools like GTmetrix or Pingdom to test load times from different global locations

### Troubleshooting Common Issues

**Problem**: Getting "400 Bad Request - IncorrectEndpoint" error
```
The specified bucket exists in another region. Please direct requests to the specified endpoint.
```

**Solution**: Your CloudFront distribution is pointing to the wrong regional S3 endpoint.
1. **Check your bucket's region**:
   ```bash
   aws s3api get-bucket-location --bucket your-bucket-name
   ```
2. **Update the CloudFront configuration** in `assets/cloudfront-config.json`:
   - Change the `DomainName` from: `your-bucket.s3-website-us-east-1.amazonaws.com`
   - To: `your-bucket.s3-website-YOUR-ACTUAL-REGION.amazonaws.com`
3. **Update your existing distribution** or create a new one with the correct configuration

**Problem**: CloudFront distribution deployment is taking too long
**Solution**: CloudFront deployments typically take 15-20 minutes. This is normal and cannot be accelerated.

**Problem**: Getting "IllegalUpdate" error when updating CloudFront distribution
```
OriginReadTimeout is required for updates
```
**Solution**: CloudFront CLI updates require the complete current configuration, not a template.
1. **Use AWS Console instead** (easier):
   - Go to CloudFront Console → Select your distribution → Origins tab → Edit origin
   - Update the Origin Domain Name to the correct regional endpoint
2. **Or use CLI properly**:
   ```bash
   # Get complete current config
   aws cloudfront get-distribution-config --id YOUR_DISTRIBUTION_ID > current-config.json
   # Edit the file to update only the DomainName field
   # Use the ETag from the response in your update command
   ```

## 7. Learning Materials & Key Concepts

- **S3 Static Website Hosting:** S3 provides a cost-effective way to host static websites without managing servers. It's highly durable (99.999999999% durability) and can scale automatically to handle traffic spikes. This is often tested in SAA-C03 as a cost-optimization strategy compared to EC2-based hosting.

- **CloudFront CDN Benefits:** CloudFront improves website performance by caching content at edge locations worldwide, reducing latency for global users. It also provides DDoS protection and can help reduce costs by reducing requests to your S3 origin. Understanding when to use CloudFront vs. direct S3 access is crucial for the exam.

- **SSL/TLS with Certificate Manager:** AWS Certificate Manager provides free SSL/TLS certificates with automatic renewal. For CloudFront, certificates must be requested in the us-east-1 region. This demonstrates AWS security best practices and cost optimization (free certificates vs. third-party paid certificates).

- **Route 53 Alias Records:** Alias records are AWS-specific DNS records that provide performance benefits and cost savings compared to CNAME records. They can route traffic directly to AWS resources like CloudFront distributions without additional DNS lookups.

- **Security Best Practices:** The bucket policy implements least privilege access (public read-only for website content). **S3 Block Public Access** is a critical security feature that prevents accidental data exposure - we specifically disable it for static website hosting, but you should understand when and why to use it. CloudFront Origin Access Identity (OAI) can be used to restrict direct S3 access, forcing all traffic through CloudFront for better security and performance.

- **High Availability and Scalability:** This architecture is inherently highly available across multiple AWS Availability Zones and Regions. S3 provides 99.99% availability SLA, and CloudFront has a global presence, making it suitable for mission-critical static websites.

## 8. Cost & Free Tier Eligibility

**Free Tier Coverage:**
- **S3:** 5 GB of standard storage, 20,000 GET requests, 2,000 PUT requests per month
- **CloudFront:** 1 TB of data transfer out, 10,000,000 HTTP/HTTPS requests per month
- **Route 53:** First hosted zone is $0.50/month (not free, but minimal cost)
- **Certificate Manager:** SSL/TLS certificates are completely free

**Potential Costs:**
- **S3 Storage:** $0.023 per GB per month after free tier (minimal for static websites)
- **CloudFront:** $0.085 per GB for data transfer out after 1 TB (varies by region)
- **Route 53:** $0.50 per hosted zone per month + $0.40 per million queries
- **Data Transfer:** Charges apply for data transfer out to internet beyond free tier limits

**Estimated Monthly Cost:** For a typical small business website with moderate traffic, expect $1-5 per month after free tier limits are exceeded.

## 9. Cleanup Instructions

⚠️ **Important:** Follow these steps in order to avoid dependency errors and ensure complete cleanup.

1. **Delete Route 53 DNS Records**
   ```bash
   aws route53 change-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID --change-batch file://assets/delete-route53-record.json
   ```

2. **Delete CloudFront Distribution**
   ```bash
   # First disable the distribution
   aws cloudfront get-distribution-config --id YOUR_DISTRIBUTION_ID > distribution-config.json
   # Edit the config to set "Enabled": false, then update
   aws cloudfront update-distribution --id YOUR_DISTRIBUTION_ID --distribution-config file://modified-distribution-config.json --if-match ETAG_VALUE
   
   # Wait for deployment, then delete
   aws cloudfront delete-distribution --id YOUR_DISTRIBUTION_ID --if-match ETAG_VALUE
   ```

3. **Delete SSL/TLS Certificate** (optional, if not used elsewhere)
   ```bash
   aws acm delete-certificate --certificate-arn YOUR_CERTIFICATE_ARN --region us-east-1
   ```

4. **Empty and Delete S3 Bucket**
   ```bash
   aws s3 rm s3://your-unique-bucket-name-static-website --recursive
   aws s3 rb s3://your-unique-bucket-name-static-website
   ```
   
   > **Security Note**: When you delete the bucket, the Block Public Access settings are removed automatically. If you were keeping the bucket for other purposes, you should re-enable Block Public Access:
   > ```bash
   > aws s3api put-public-access-block --bucket your-bucket-name --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
   > ```

5. **Delete Route 53 Hosted Zone** (optional, if you own the domain)
   ```bash
   aws route53 delete-hosted-zone --id YOUR_HOSTED_ZONE_ID
   ```

## 10. Associated Project Files

The following files are provided in the `assets` folder:

- `assets/index.html` - Sample homepage with AWS branding
- `assets/error.html` - Custom 404 error page
- `assets/styles.css` - CSS stylesheet for the website
- `assets/bucket-policy.json` - S3 bucket policy for public read access
- `assets/cloudfront-config.json` - CloudFront distribution configuration
- `assets/route53-record.json` - Route 53 DNS record configuration
- `assets/delete-route53-record.json` - Route 53 record deletion configuration

---

**Next Project:** Once you've completed this project and cleaned up the resources, proceed to [Project 02: Create a Serverless API](../02-serverless-api/README.md) to learn about serverless architectures with API Gateway, Lambda, and DynamoDB.
