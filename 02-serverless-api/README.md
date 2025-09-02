# Project 02: Create a Serverless API using API Gateway, Lambda, and DynamoDB

## 1. Objective
Build a complete serverless RESTful API that demonstrates the power of AWS's serverless architecture. You will create a Task Management API that allows users to create, read, update, and delete tasks using HTTP requests. This project teaches you how to design scalable, cost-effective APIs without managing servers, and demonstrates key serverless patterns commonly tested in the SAA-C03 exam.

## 2. AWS Services Used
- **AWS Lambda** (Serverless compute for API logic)
- **Amazon API Gateway** (RESTful API endpoint management)
- **Amazon DynamoDB** (NoSQL database for task storage)
- **AWS IAM** (Identity and Access Management for security)
- **Amazon CloudWatch** (Logging and monitoring)

## 3. Difficulty
**Beginner**

## 4. Architecture Diagram
```
┌─────────────┐    HTTPS Request     ┌─────────────┐    Invoke      ┌─────────────┐
│   Client    │ ──────────────────> │ API Gateway │ ─────────────> │   Lambda    │
│ (Browser/   │                     │  (REST API) │                │  Function   │
│  Postman)   │ <────────────────── └─────────────┘ <───────────── └─────────────┘
└─────────────┘    JSON Response                                           │
                                                                           │
                                                                           │ Read/Write
                                                                           ▼
                                                                   ┌─────────────┐
                                                                   │  DynamoDB   │
                                                                   │    Table    │
                                                                   │   (Tasks)   │
                                                                   └─────────────┘

API Gateway handles:                Lambda Function handles:       DynamoDB provides:
- Authentication                   - Business logic               - NoSQL data storage
- Rate limiting                    - Data validation             - Auto-scaling
- Request/Response mapping         - CRUD operations              - High availability
- CORS headers                     - Error handling               - Consistent performance
```

## 5. Prerequisites

**Before starting this project, ensure you have completed the [Prerequisites Guide](../PREREQUISITES.md).**

**Project-specific requirements:**
- Basic understanding of HTTP methods (GET, POST, PUT, DELETE)
- Familiarity with JSON data format
- Basic knowledge of REST API concepts (optional, but helpful)

## 6. Step-by-Step Guide

### Step 1: Create DynamoDB Table for Task Storage

1. **Create DynamoDB Table**
   ```bash
   aws dynamodb create-table \
       --table-name Tasks \
       --attribute-definitions AttributeName=taskId,AttributeType=S \
       --key-schema AttributeName=taskId,KeyType=HASH \
       --billing-mode PAY_PER_REQUEST \
       --region your-region
   ```

2. **Verify Table Creation**
   ```bash
   aws dynamodb describe-table --table-name Tasks --region your-region
   ```
   > Wait until the table status shows "ACTIVE" before proceeding

3. **Test Table with Sample Data** (optional)
   ```bash
   aws dynamodb put-item \
       --table-name Tasks \
       --item '{"taskId": {"S": "test-123"}, "title": {"S": "Test Task"}, "description": {"S": "This is a test task"}, "status": {"S": "pending"}, "createdAt": {"S": "2024-01-01T00:00:00Z"}}' \
       --region your-region
   ```

### Step 2: Create IAM Role for Lambda Function

1. **Create Trust Policy for Lambda**
   ```bash
   aws iam create-role \
       --role-name LambdaTaskAPIRole \
       --assume-role-policy-document '{
         "Version": "2012-10-17",
         "Statement": [
           {
             "Effect": "Allow",
             "Principal": {
               "Service": "lambda.amazonaws.com"
             },
             "Action": "sts:AssumeRole"
           }
         ]
       }'
   ```

2. **Attach Basic Lambda Execution Policy**
   ```bash
   aws iam attach-role-policy \
       --role-name LambdaTaskAPIRole \
       --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
   ```

3. **Create and Attach DynamoDB Access Policy**
   ```bash
   aws iam create-policy \
       --policy-name LambdaDynamoDBPolicy \
       --policy-document file://assets/iam_policy.json
   ```
   
   > Note the Policy ARN returned for the next step

4. **Attach DynamoDB Policy to Role**
   ```bash
   aws iam attach-role-policy \
       --role-name LambdaTaskAPIRole \
       --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/LambdaDynamoDBPolicy
   ```
   > Replace YOUR_ACCOUNT_ID with your actual AWS account ID

### Step 3: Create and Deploy Lambda Function

1. **Create Lambda Function Deployment Package**
   ```bash
   # Navigate to the assets directory
   cd assets
   
   # Create deployment package
   zip lambda-deployment.zip lambda_function.py
   
   # Return to project root
   cd ..
   ```

2. **Create Lambda Function**
   ```bash
   aws lambda create-function \
       --function-name TaskAPI \
       --runtime python3.9 \
       --role arn:aws:iam::YOUR_ACCOUNT_ID:role/LambdaTaskAPIRole \
       --handler lambda_function.lambda_handler \
       --zip-file fileb://assets/lambda-deployment.zip \
       --description "Serverless Task Management API" \
       --timeout 30 \
       --region your-region
   ```
   > Replace YOUR_ACCOUNT_ID with your actual AWS account ID

3. **Test Lambda Function**
   ```bash
   aws lambda invoke \
       --function-name TaskAPI \
       --payload '{"httpMethod": "GET", "pathParameters": null, "queryStringParameters": null, "body": null}' \
       --region your-region \
       response.json
   
   # View the response
   type response.json
   ```

### Step 4: Create API Gateway REST API

1. **Create REST API**
   ```bash
   aws apigateway create-rest-api \
       --name TaskManagementAPI \
       --description "Serverless Task Management API for SAA-C03 Project" \
       --region your-region
   ```
   > Note the API ID returned for subsequent commands

2. **Get Root Resource ID**
   ```bash
   aws apigateway get-resources \
       --rest-api-id YOUR_API_ID \
       --region your-region
   ```
   > Note the root resource ID (usually looks like a random string)

3. **Create 'tasks' Resource**
   ```bash
   aws apigateway create-resource \
       --rest-api-id YOUR_API_ID \
       --parent-id YOUR_ROOT_RESOURCE_ID \
       --path-part tasks \
       --region your-region
   ```
   > Note the new resource ID for the tasks resource

4. **Create Individual Task Resource (with path parameter)**
   ```bash
   aws apigateway create-resource \
       --rest-api-id YOUR_API_ID \
       --parent-id YOUR_TASKS_RESOURCE_ID \
       --path-part "{taskId}" \
       --region your-region
   ```

### Step 5: Configure API Gateway Methods

1. **Create GET Method for All Tasks (GET /tasks)**
   ```bash
   aws apigateway put-method \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKS_RESOURCE_ID \
       --http-method GET \
       --authorization-type NONE \
       --region your-region
   ```

2. **Create POST Method for Creating Tasks (POST /tasks)**
   ```bash
   aws apigateway put-method \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKS_RESOURCE_ID \
       --http-method POST \
       --authorization-type NONE \
       --region your-region
   ```

3. **Create GET Method for Single Task (GET /tasks/{taskId})**
   ```bash
   aws apigateway put-method \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKID_RESOURCE_ID \
       --http-method GET \
       --authorization-type NONE \
       --region your-region
   ```

4. **Create PUT Method for Updating Tasks (PUT /tasks/{taskId})**
   ```bash
   aws apigateway put-method \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKID_RESOURCE_ID \
       --http-method PUT \
       --authorization-type NONE \
       --region your-region
   ```

5. **Create DELETE Method (DELETE /tasks/{taskId})**
   ```bash
   aws apigateway put-method \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKID_RESOURCE_ID \
       --http-method DELETE \
       --authorization-type NONE \
       --region your-region
   ```

### Step 6: Integrate API Gateway with Lambda

**For each method created above, you need to set up Lambda integration:**

1. **Example: Set up Integration for GET /tasks**
   ```bash
   aws apigateway put-integration \
       --rest-api-id YOUR_API_ID \
       --resource-id YOUR_TASKS_RESOURCE_ID \
       --http-method GET \
       --type AWS_PROXY \
       --integration-http-method POST \
       --uri arn:aws:apigateway:your-region:lambda:path/2015-03-31/functions/arn:aws:lambda:your-region:YOUR_ACCOUNT_ID:function:TaskAPI/invocations \
       --region your-region
   ```

2. **Grant API Gateway Permission to Invoke Lambda**
   ```bash
   aws lambda add-permission \
       --function-name TaskAPI \
       --statement-id api-gateway-invoke-lambda \
       --action lambda:InvokeFunction \
       --principal apigateway.amazonaws.com \
       --source-arn "arn:aws:execute-api:your-region:YOUR_ACCOUNT_ID:YOUR_API_ID/*/*/*" \
       --region your-region
   ```

3. **Repeat integration setup for all methods** (POST, PUT, DELETE)
   > Use the same integration command but change the resource-id and http-method parameters

### Step 7: Deploy API Gateway

1. **Deploy API to Stage**
   ```bash
   aws apigateway create-deployment \
       --rest-api-id YOUR_API_ID \
       --stage-name prod \
       --stage-description "Production stage for Task API" \
       --description "Initial deployment of Task Management API" \
       --region your-region
   ```

2. **Get API Endpoint URL**
   ```bash
   echo "Your API endpoint: https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks"
   ```

### Step 8: Test Your Serverless API

1. **Test GET All Tasks** (should return empty array initially)
   ```bash
   curl -X GET https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks
   ```

2. **Test POST Create New Task**
   ```bash
   curl -X POST https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks \
        -H "Content-Type: application/json" \
        -d '{
          "title": "Learn AWS Lambda",
          "description": "Complete the serverless API project for SAA-C03 prep",
          "status": "pending"
        }'
   ```

3. **Test GET Single Task** (use the taskId returned from POST)
   ```bash
   curl -X GET https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/TASK_ID_HERE
   ```

4. **Test PUT Update Task**
   ```bash
   curl -X PUT https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/TASK_ID_HERE \
        -H "Content-Type: application/json" \
        -d '{
          "title": "Learn AWS Lambda - Updated",
          "description": "Complete the serverless API project and understand Lambda pricing",
          "status": "in-progress"
        }'
   ```

5. **Test DELETE Task**
   ```bash
   curl -X DELETE https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/TASK_ID_HERE
   ```

## 7. Learning Materials & Key Concepts

- **Serverless Architecture Benefits:** This project demonstrates the "No Server Management" principle - you focus purely on code and business logic. AWS handles scaling, patching, and infrastructure management. This is a key cost-optimization pattern in SAA-C03, especially for variable or unpredictable workloads.

- **API Gateway as a Managed Service:** API Gateway provides built-in features like rate limiting, authentication, CORS handling, and request/response transformation. Understanding when to use API Gateway vs. Application Load Balancer (ALB) is crucial for the exam - API Gateway is ideal for serverless and microservices architectures.

- **Lambda Function Pricing Model:** Lambda charges only for compute time consumed (pay-per-request). No charges when code isn't running. The first 1 million requests per month are free. This makes it extremely cost-effective for APIs with sporadic traffic patterns.

- **DynamoDB as a Serverless Database:** DynamoDB automatically scales read/write capacity, provides single-digit millisecond latency, and offers built-in security features. The key exam concept is understanding when to choose DynamoDB (flexible scaling, serverless) vs. RDS (complex queries, ACID transactions).

- **IAM Best Practices in Serverless:** The Lambda execution role follows the principle of least privilege - it only has permissions to write logs to CloudWatch and perform specific DynamoDB operations. This is a critical security pattern tested in SAA-C03.

- **Event-Driven Architecture:** API Gateway triggers Lambda functions based on HTTP requests. This loose coupling allows each component to scale independently and makes the architecture highly resilient to failure.

- **JSON Data Format and REST Principles:** The API follows RESTful conventions (GET for retrieval, POST for creation, PUT for updates, DELETE for removal) and uses JSON for data exchange, which are industry standards for web APIs.

## 8. Cost & Free Tier Eligibility

**Free Tier Coverage:**
- **Lambda:** 1 million free requests per month + 400,000 GB-seconds of compute time
- **API Gateway:** 1 million API calls per month for REST APIs
- **DynamoDB:** 25 GB of storage, 25 units of read/write capacity
- **CloudWatch:** 10 custom metrics, 1 million API requests

**Potential Costs:**
- **Lambda:** $0.20 per 1M requests + $0.0000166667 per GB-second after free tier
- **API Gateway:** $3.50 per million API calls after free tier
- **DynamoDB:** $0.25 per GB per month for storage + read/write capacity costs
- **Data Transfer:** Standard AWS data transfer charges apply

**Estimated Monthly Cost:** For a typical development/learning project with moderate usage, expect $0-2 per month within free tier limits. Production APIs with higher traffic might cost $10-50+ depending on request volume.

## 9. Cleanup Instructions

⚠️ **Important:** Follow these steps in order to avoid dependency errors and ensure complete cleanup.

1. **Delete API Gateway**
   ```bash
   aws apigateway delete-rest-api --rest-api-id YOUR_API_ID --region your-region
   ```

2. **Delete Lambda Function**
   ```bash
   aws lambda delete-function --function-name TaskAPI --region your-region
   ```

3. **Delete DynamoDB Table**
   ```bash
   aws dynamodb delete-table --table-name Tasks --region your-region
   ```

4. **Detach and Delete IAM Policies**
   ```bash
   # Detach policies from role
   aws iam detach-role-policy --role-name LambdaTaskAPIRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
   aws iam detach-role-policy --role-name LambdaTaskAPIRole --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/LambdaDynamoDBPolicy
   
   # Delete custom policy
   aws iam delete-policy --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/LambdaDynamoDBPolicy
   
   # Delete IAM role
   aws iam delete-role --role-name LambdaTaskAPIRole
   ```

5. **Delete Local Files**
   ```bash
   del assets\lambda-deployment.zip
   del response.json
   ```

## 10. Associated Project Files

The following files are provided in the `assets` folder:

- `assets/lambda_function.py` - Complete Python code for the Lambda function handling all CRUD operations
- `assets/iam_policy.json` - IAM policy granting Lambda function access to DynamoDB operations
- `assets/test_requests.json` - Sample API requests for testing (curl commands and JSON payloads)
- `assets/api_documentation.md` - Complete API documentation with request/response examples

---

**Next Project:** Once you've completed this project and cleaned up the resources, proceed to [Project 03: Decouple an Application with SQS and Lambda](../03-sqs-decoupling/README.md) to learn about message queuing and application decoupling patterns.
