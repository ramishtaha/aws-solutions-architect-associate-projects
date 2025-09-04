# Project 2: Create a Serverless API using API Gateway, Lambda, and DynamoDB

## 1. Objective
Build a complete serverless API that allows you to perform CRUD (Create, Read, Update, Delete) operations on a DynamoDB table through API Gateway endpoints. This project will teach you the fundamentals of serverless architecture, event-driven computing, and how to build scalable APIs without managing servers.

## 2. AWS Services Used
- **Amazon API Gateway** - RESTful API creation and management
- **AWS Lambda** - Serverless compute service for API logic
- **Amazon DynamoDB** - NoSQL database for data storage
- **AWS IAM** - Identity and Access Management for permissions
- **Amazon CloudWatch** - Monitoring and logging

## 3. Difficulty
Beginner

## 4. Architecture Diagram
```
┌─────────────┐    ┌─────────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │───▶│  API Gateway    │───▶│   Lambda    │───▶│  DynamoDB   │
│ (Browser/   │    │   (REST API)    │    │  Function   │    │   Table     │
│  App/curl)  │◄───│                 │◄───│             │◄───│             │
└─────────────┘    └─────────────────┘    └─────────────┘    └─────────────┘
                            │                      │
                            │                      │
                            ▼                      ▼
                   ┌─────────────────┐    ┌─────────────┐
                   │   CloudWatch    │    │     IAM     │
                   │     Logs        │    │    Role     │
                   └─────────────────┘    └─────────────┘
```

## 5. Prerequisites
- Ensure you have completed the initial setup detailed in the main [PREREQUISITES.md](../PREREQUISITES.md) file in the repository root.
- Basic understanding of REST APIs and HTTP methods (GET, POST, PUT, DELETE)
- Familiarity with JSON data format

## 6. Step-by-Step Guide

### Step 1: Create DynamoDB Table
1. Open the AWS Management Console and navigate to DynamoDB
2. Click "Create table"
3. Configure the table:
   - **Table name**: `ServerlessAPI-Items`
   - **Partition key**: `id` (String)
   - Leave other settings as default (On-demand billing)
4. Click "Create table" and wait for it to be created

### Step 2: Create IAM Role for Lambda
1. Navigate to the IAM service in AWS Console
2. Click "Roles" → "Create role"
3. Select "AWS service" → "Lambda" → "Next"
4. Click "Create policy" and switch to JSON tab
5. Copy and paste the IAM policy from `assets/iam_policy.json`
6. Name the policy: `ServerlessAPI-Lambda-Policy`
7. Create the policy and attach it to your role
8. Name the role: `ServerlessAPI-Lambda-Role`
9. Create the role

### Step 3: Create Lambda Function
1. Navigate to AWS Lambda service
2. Click "Create function"
3. Configure the function:
   - **Function name**: `ServerlessAPI-Function`
   - **Runtime**: Python 3.11
   - **Execution role**: Use existing role → `ServerlessAPI-Lambda-Role`
4. Click "Create function"
5. In the code editor, replace the default code with the content from `assets/lambda_function.py`
6. Click "Deploy" to save the changes

### Step 4: Test Lambda Function
1. In the Lambda function console, click "Test"
2. Create a new test event:
   - **Event name**: `CreateItemTest`
   - **Event JSON**:
   ```json
   {
     "httpMethod": "POST",
     "body": "{\"name\": \"Test Item\", \"description\": \"This is a test item\"}"
   }
   ```
3. Click "Test" and verify the function executes successfully

### Step 5: Create API Gateway
1. Navigate to API Gateway service
2. Click "Create API" → "REST API" → "Build"
3. Configure the API:
   - **API name**: `ServerlessAPI`
   - **Description**: `Serverless CRUD API for DynamoDB`
   - **Endpoint Type**: Regional
4. Click "Create API"

### Step 6: Create API Resources and Methods
1. In your API, click "Actions" → "Create Resource"
2. Configure resource:
   - **Resource Name**: `items`
   - **Resource Path**: `/items`
   - Enable CORS if needed
3. Click "Create Resource"

4. Create individual item resource:
   - Select `/items` resource
   - Click "Actions" → "Create Resource"
   - **Resource Name**: `item`
   - **Resource Path**: `/{id}`
   - Click "Create Resource"

5. Add methods to `/items` resource:
   - **GET** (list all items):
     - Click "Actions" → "Create Method" → "GET"
     - Integration type: Lambda Function
     - Lambda Function: `ServerlessAPI-Function`
     - Click "Save"
   
   - **POST** (create new item):
     - Click "Actions" → "Create Method" → "POST"
     - Integration type: Lambda Function
     - Lambda Function: `ServerlessAPI-Function`
     - Click "Save"

6. Add methods to `/items/{id}` resource:
   - **GET** (get specific item):
     - Click "Actions" → "Create Method" → "GET"
     - Integration type: Lambda Function
     - Lambda Function: `ServerlessAPI-Function`
     - Click "Save"
   
   - **PUT** (update item):
     - Click "Actions" → "Create Method" → "PUT"
     - Integration type: Lambda Function
     - Lambda Function: `ServerlessAPI-Function`
     - Click "Save"
   
   - **DELETE** (delete item):
     - Click "Actions" → "Create Method" → "DELETE"
     - Integration type: Lambda Function
     - Lambda Function: `ServerlessAPI-Function`
     - Click "Save"

### Step 7: Deploy API
1. Click "Actions" → "Deploy API"
2. Create new deployment stage:
   - **Stage name**: `prod`
   - **Stage description**: `Production stage`
3. Click "Deploy"
4. Note down the **Invoke URL** displayed

### Step 8: Test the API
Use the following curl commands or a tool like Postman to test your API:

1. **Create an item** (POST):
```bash
curl -X POST [YOUR_INVOKE_URL]/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Sample Item", "description": "This is a sample item"}'
```

2. **Get all items** (GET):
```bash
curl -X GET [YOUR_INVOKE_URL]/items
```

3. **Get specific item** (GET):
```bash
curl -X GET [YOUR_INVOKE_URL]/items/[ITEM_ID]
```

4. **Update an item** (PUT):
```bash
curl -X PUT [YOUR_INVOKE_URL]/items/[ITEM_ID] \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Item", "description": "This item has been updated"}'
```

5. **Delete an item** (DELETE):
```bash
curl -X DELETE [YOUR_INVOKE_URL]/items/[ITEM_ID]
```

## 7. Learning Materials & Key Concepts

- **Serverless Computing:** Learn how serverless architecture eliminates the need to provision and manage servers. AWS Lambda automatically scales your application and charges only for the compute time you consume. This is essential for the SAA-C03 exam as serverless is a key architectural pattern for building cost-effective, scalable solutions.

- **IAM Execution Roles:** Understand how AWS services authenticate with each other using IAM roles rather than embedding credentials in code. The Lambda execution role grants your function the minimum necessary permissions to access DynamoDB and CloudWatch, following the principle of least privilege - a critical security concept in the SAA-C03 exam.

- **API Gateway Integration Patterns:** Explore how API Gateway acts as a "front door" for your applications, handling request routing, authentication, rate limiting, and transformations. Understanding when to use API Gateway versus Application Load Balancer is a common exam topic.

- **DynamoDB Design Patterns:** Learn why DynamoDB is chosen for serverless applications - it's fully managed, scales automatically, and integrates seamlessly with Lambda. Understanding NoSQL design patterns and when to choose DynamoDB over RDS is crucial for the exam.

- **Event-Driven Architecture:** This project demonstrates how different AWS services communicate through events (HTTP requests triggering Lambda functions), which is a fundamental pattern in modern cloud architectures covered extensively in the SAA-C03 exam.

## 8. Cost & Free Tier Eligibility

**Free Tier Coverage:**
- **Lambda**: 1 million requests per month and 400,000 GB-seconds of compute time
- **API Gateway**: 1 million API calls per month for the first 12 months
- **DynamoDB**: 25 GB storage and 25 provisioned read/write capacity units (enough for this project)
- **CloudWatch**: Basic monitoring and 5 GB of log ingestion

**Potential Costs:**
- This project should remain within Free Tier limits for learning purposes
- If you exceed Free Tier limits:
  - Lambda: $0.20 per 1 million requests + $0.0000166667 per GB-second
  - API Gateway: $3.50 per million requests after Free Tier
  - DynamoDB: $0.25 per GB storage per month for additional storage

## 9. Cleanup Instructions

**⚠️ Important: Delete resources in this exact order to avoid errors:**

1. **Delete API Gateway:**
   - Go to API Gateway console
   - Select your `ServerlessAPI`
   - Click "Actions" → "Delete API"
   - Confirm deletion

2. **Delete Lambda Function:**
   - Go to Lambda console
   - Select `ServerlessAPI-Function`
   - Click "Actions" → "Delete function"
   - Type "delete" to confirm

3. **Delete IAM Role and Policy:**
   - Go to IAM console → Roles
   - Select `ServerlessAPI-Lambda-Role`
   - Click "Delete role"
   - Go to Policies → Select `ServerlessAPI-Lambda-Policy`
   - Click "Actions" → "Delete"

4. **Delete DynamoDB Table:**
   - Go to DynamoDB console
   - Select `ServerlessAPI-Items` table
   - Click "Delete table"
   - Type "confirm" to delete

5. **Verify CloudWatch Logs Cleanup (Optional):**
   - Go to CloudWatch → Log groups
   - Delete any log groups starting with `/aws/lambda/ServerlessAPI-Function`

## 10. Associated Project Files
- `lambda_function.py`: Complete Python code for the Lambda function handling all CRUD operations
- `iam_policy.json`: IAM execution role policy granting necessary DynamoDB and CloudWatch permissions
