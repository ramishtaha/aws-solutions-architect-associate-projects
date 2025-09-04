# Project 3: Decouple an Application with SQS and a Lambda consumer

## 1. Objective
Build a decoupled application architecture using Amazon SQS (Simple Queue Service) as a message queue and AWS Lambda as a consumer. This project demonstrates how to break down monolithic applications into loosely coupled components, enabling better scalability, fault tolerance, and independent deployment. You'll learn to implement asynchronous message processing patterns that are fundamental to modern cloud-native architectures.

## 2. AWS Services Used
- Amazon SQS (Simple Queue Service)
- AWS Lambda
- Amazon CloudWatch Logs
- AWS IAM (Identity and Access Management)

## 3. Difficulty
Beginner

## 4. Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │    │                 │
│   Message       │───▶│   Amazon SQS    │───▶│   AWS Lambda    │───▶│   CloudWatch    │
│   Producer      │    │   Queue         │    │   Consumer      │    │   Logs          │
│   (Manual/App)  │    │                 │    │                 │    │                 │
│                 │    │                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 5. Prerequisites
- Ensure you have completed the initial setup detailed in the main [PREREQUISITES.md](../PREREQUISITES.md) file in the repository root.
- Basic understanding of JSON format
- Familiarity with AWS Console navigation
- Basic knowledge of Python programming (for understanding the Lambda function)

## 6. Step-by-Step Guide

### Step 1: Create an SQS Queue

1. Navigate to the Amazon SQS service in the AWS Management Console
2. Click **Create queue**
3. Choose **Standard** queue type
4. Enter queue name: `message-processing-queue`
5. Keep all default settings for this beginner project
6. Click **Create queue**
7. Note down the Queue URL from the queue details page

### Step 2: Create IAM Role for Lambda Function

1. Navigate to the IAM service in the AWS Management Console
2. Click **Roles** in the left sidebar
3. Click **Create role**
4. Select **AWS service** as the trusted entity type
5. Choose **Lambda** as the use case
6. Click **Next**
7. Search for and attach the following AWS managed policies:
   - `AWSLambdaBasicExecutionRole` (for CloudWatch Logs)
8. Click **Next**
9. Enter role name: `lambda-sqs-consumer-role`
10. Click **Create role**
11. After creation, click on the role name to open its details
12. Click **Add permissions** > **Create inline policy**
13. Click **JSON** tab and paste the content from `assets/iam_policy.json`
14. Click **Next**
15. Enter policy name: `SQSProcessingPolicy`
16. Click **Create policy**

### Step 3: Create Lambda Function

1. Navigate to the AWS Lambda service in the AWS Management Console
2. Click **Create function**
3. Choose **Author from scratch**
4. Enter function name: `sqs-message-processor`
5. Choose **Python 3.12** as the runtime
6. Under **Change default execution role**, select **Use an existing role**
7. Choose the role: `lambda-sqs-consumer-role`
8. Click **Create function**
9. In the code editor, replace the default code with the content from `assets/lambda_function.py`
10. Click **Deploy** to save the function

### Step 4: Configure SQS Trigger for Lambda

1. In your Lambda function console, scroll down to the **Function overview** section
2. Click **Add trigger**
3. Select **SQS** from the trigger configuration dropdown
4. Choose your SQS queue: `message-processing-queue`
5. Set **Batch size** to `10` (default)
6. Leave other settings as default
7. Click **Add**

### Step 5: Test the Setup

1. Navigate back to your SQS queue in the SQS console
2. Click **Send and receive messages**
3. In the **Message body** field, enter a test message:
   ```json
   {
     "orderId": "12345",
     "customerId": "customer-abc",
     "items": ["item1", "item2"],
     "total": 99.99
   }
   ```
4. Click **Send message**
5. Navigate to CloudWatch Logs in the AWS Management Console
6. Look for a log group named `/aws/lambda/sqs-message-processor`
7. Click on the latest log stream to see your Lambda function's execution logs
8. Verify that the message was processed successfully

### Step 6: Send Multiple Messages (Optional)

1. Return to the SQS queue and send several more test messages with different content
2. Observe how Lambda processes the messages in batches
3. Check CloudWatch Logs to see the processing results

## 7. Learning Materials & Key Concepts

### Concept 1: Decoupling
Decoupling refers to the architectural practice of reducing dependencies between application components. In traditional monolithic applications, components are tightly coupled, meaning a failure in one component can cascade and affect the entire system. By introducing a message queue like SQS between components, we achieve:
- **Loose coupling**: Components can operate independently
- **Fault tolerance**: If the consumer is down, messages wait in the queue
- **Scalability**: Consumers can be scaled independently based on queue depth
- **Flexibility**: Different components can be updated, deployed, or replaced without affecting others

### Concept 2: Amazon SQS (Simple Queue Service)
Amazon SQS is a fully managed message queuing service that enables decoupling of application components:
- **Standard Queues**: Offer maximum throughput, best-effort ordering, and at-least-once delivery
- **FIFO Queues**: Guarantee exactly-once processing and maintain message order
- **Visibility Timeout**: The period during which a message is invisible to other consumers after being retrieved
- **Dead Letter Queues (DLQs)**: Queues that store messages that couldn't be processed successfully after a specified number of attempts
- **Message Retention**: Messages can be retained for up to 14 days
- **Polling**: SQS supports both short polling (immediate response) and long polling (wait for messages)

### Concept 3: Lambda Triggers
AWS Lambda supports event-driven execution through various triggers:
- **SQS Trigger**: Lambda polls the SQS queue and invokes the function when messages are available
- **Batch Processing**: Lambda can process multiple messages in a single invocation for efficiency
- **Error Handling**: Failed message processing can result in messages being returned to the queue or sent to a DLQ
- **Scaling**: Lambda automatically scales to handle the rate of incoming messages
- **Asynchronous Processing**: The producer doesn't need to wait for message processing to complete

## 8. Cost & Free Tier Eligibility

### Free Tier Coverage:
- **Amazon SQS**: 1 million requests per month (includes SendMessage, ReceiveMessage, DeleteMessage)
- **AWS Lambda**: 1 million requests and 400,000 GB-seconds of compute time per month
- **CloudWatch Logs**: 5 GB of log data ingestion and storage per month

### Potential Costs:
- **SQS**: $0.40 per million requests after Free Tier exhaustion
- **Lambda**: $0.20 per million requests and $0.0000166667 per GB-second after Free Tier
- **CloudWatch Logs**: $0.50 per GB ingested and $0.03 per GB stored per month after Free Tier
- **Data Transfer**: Minimal costs for data transfer between AWS services in the same region

For this beginner project with moderate testing, you should stay well within Free Tier limits.

## 9. Cleanup Instructions

**Important**: Follow these steps in order to avoid any dependency issues:

1. **Remove SQS Trigger from Lambda Function**:
   - Navigate to your Lambda function in the console
   - Go to the **Configuration** tab, then **Triggers**
   - Select the SQS trigger and click **Delete**
   - Confirm the deletion

2. **Delete Lambda Function**:
   - In the Lambda console, select your function `sqs-message-processor`
   - Click **Actions** > **Delete**
   - Type "delete" to confirm

3. **Delete IAM Role**:
   - Navigate to IAM console > **Roles**
   - Search for `lambda-sqs-consumer-role`
   - Select the role and click **Delete**
   - Confirm deletion

4. **Delete SQS Queue**:
   - Navigate to SQS console
   - Select your queue `message-processing-queue`
   - Click **Delete**
   - Type "delete" to confirm
   - Wait for the deletion to complete (may take up to 60 seconds)

5. **Clean up CloudWatch Logs** (Optional):
   - Navigate to CloudWatch > **Log groups**
   - Find `/aws/lambda/sqs-message-processor`
   - Select and delete the log group

## 10. Associated Project Files
- `assets/lambda_function.py`: Python code for the Lambda function that processes SQS messages
- `assets/iam_policy.json`: IAM policy document granting necessary SQS and CloudWatch permissions
