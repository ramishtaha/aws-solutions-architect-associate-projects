# Task Management API Documentation

## Overview
This is a RESTful API for managing tasks, built using AWS serverless services (Lambda, API Gateway, and DynamoDB). The API follows standard REST conventions and provides full CRUD (Create, Read, Update, Delete) functionality for task management.

## Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

## Authentication
Currently, this API does not require authentication. In a production environment, you would typically add API keys, IAM authentication, or Cognito user pools.

## Data Model

### Task Object
```json
{
  "taskId": "string (UUID)",
  "title": "string (required)",
  "description": "string (optional)",
  "status": "string (enum)",
  "priority": "string (enum)",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime)"
}
```

### Field Descriptions
- **taskId**: Unique identifier (auto-generated UUID)
- **title**: Task title (required, max 255 characters)
- **description**: Detailed task description (optional)
- **status**: Task status - one of: `pending`, `in-progress`, `completed`, `cancelled`
- **priority**: Task priority - one of: `low`, `medium`, `high`, `urgent`
- **createdAt**: ISO 8601 timestamp when task was created
- **updatedAt**: ISO 8601 timestamp when task was last modified

## API Endpoints

### 1. Get All Tasks
**GET** `/tasks`

Retrieves a list of all tasks with optional filtering.

#### Query Parameters
- `status` (optional): Filter tasks by status
- `limit` (optional): Maximum number of tasks to return (default: 50, max: 100)

#### Example Request
```http
GET /tasks?status=pending&limit=10
```

#### Example Response
```json
{
  "tasks": [
    {
      "taskId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "title": "Learn AWS Lambda",
      "description": "Complete the serverless API project",
      "status": "pending",
      "priority": "high",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "count": 1,
  "message": "Retrieved 1 tasks"
}
```

#### Status Codes
- `200 OK`: Success
- `500 Internal Server Error`: Server error

---

### 2. Create Task
**POST** `/tasks`

Creates a new task.

#### Request Body
```json
{
  "title": "string (required)",
  "description": "string (optional)",
  "status": "string (optional, default: 'pending')",
  "priority": "string (optional, default: 'medium')"
}
```

#### Example Request
```http
POST /tasks
Content-Type: application/json

{
  "title": "Learn AWS Lambda",
  "description": "Complete the serverless API project for SAA-C03 preparation",
  "status": "pending",
  "priority": "high"
}
```

#### Example Response
```json
{
  "task": {
    "taskId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "title": "Learn AWS Lambda",
    "description": "Complete the serverless API project for SAA-C03 preparation",
    "status": "pending",
    "priority": "high",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  },
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 created successfully"
}
```

#### Status Codes
- `201 Created`: Task created successfully
- `400 Bad Request`: Invalid input (missing title, invalid status/priority)
- `500 Internal Server Error`: Server error

---

### 3. Get Single Task
**GET** `/tasks/{taskId}`

Retrieves a specific task by ID.

#### Path Parameters
- `taskId`: The unique identifier of the task

#### Example Request
```http
GET /tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

#### Example Response
```json
{
  "task": {
    "taskId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "title": "Learn AWS Lambda",
    "description": "Complete the serverless API project for SAA-C03 preparation",
    "status": "pending",
    "priority": "high",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  },
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 retrieved successfully"
}
```

#### Status Codes
- `200 OK`: Success
- `404 Not Found`: Task not found
- `500 Internal Server Error`: Server error

---

### 4. Update Task
**PUT** `/tasks/{taskId}`

Updates an existing task. This endpoint supports partial updates - you only need to include the fields you want to change.

#### Path Parameters
- `taskId`: The unique identifier of the task

#### Request Body
```json
{
  "title": "string (optional)",
  "description": "string (optional)",
  "status": "string (optional)",
  "priority": "string (optional)"
}
```

#### Example Request
```http
PUT /tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479
Content-Type: application/json

{
  "status": "in-progress",
  "description": "Updated description with more details"
}
```

#### Example Response
```json
{
  "task": {
    "taskId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "title": "Learn AWS Lambda",
    "description": "Updated description with more details",
    "status": "in-progress",
    "priority": "high",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:35:00Z"
  },
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 updated successfully"
}
```

#### Status Codes
- `200 OK`: Task updated successfully
- `400 Bad Request`: Invalid input (invalid status/priority)
- `404 Not Found`: Task not found
- `500 Internal Server Error`: Server error

---

### 5. Delete Task
**DELETE** `/tasks/{taskId}`

Deletes a specific task.

#### Path Parameters
- `taskId`: The unique identifier of the task

#### Example Request
```http
DELETE /tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

#### Example Response
```json
{
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 deleted successfully"
}
```

#### Status Codes
- `200 OK`: Task deleted successfully
- `404 Not Found`: Task not found
- `500 Internal Server Error`: Server error

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error message description"
}
```

### Common Error Messages
- `title is required` - Missing required title field in POST request
- `Task {taskId} not found` - Requested task doesn't exist
- `Invalid status. Must be one of: pending, in-progress, completed, cancelled`
- `Invalid priority. Must be one of: low, medium, high, urgent`
- `Invalid JSON in request body` - Malformed JSON
- `Method {method} not allowed` - Unsupported HTTP method
- `Internal server error` - Unexpected server error

## CORS Support

The API includes CORS (Cross-Origin Resource Sharing) headers to support web browser clients:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, X-Amz-Date, Authorization, X-Api-Key
```

## Rate Limiting

API Gateway provides built-in throttling. Default limits are:
- **Burst limit**: 5,000 requests
- **Rate limit**: 10,000 requests per second

## Monitoring and Logging

The API automatically logs all requests and responses to CloudWatch Logs. You can monitor:
- Request/response times
- Error rates
- Lambda function duration
- DynamoDB read/write metrics

### CloudWatch Log Groups
- `/aws/lambda/TaskAPI` - Lambda function logs
- `API-Gateway-Execution-Logs_{api-id}/prod` - API Gateway access logs

## Performance Characteristics

### Lambda Cold Starts
- First request to a new Lambda container may take 1-3 seconds
- Subsequent requests typically respond in <100ms

### DynamoDB Performance
- Single-digit millisecond latency for read/write operations
- Automatic scaling based on demand

## Security Considerations

### Current Implementation
- No authentication required
- Public API endpoint
- CORS enabled for all origins

### Production Recommendations
1. **Add Authentication**: Use API Keys, IAM roles, or Cognito User Pools
2. **Restrict CORS**: Set specific allowed origins
3. **Add Request Validation**: Implement input validation at API Gateway level
4. **Enable AWS WAF**: Add Web Application Firewall for DDoS protection
5. **Use VPC Endpoints**: Keep traffic within AWS network

## Cost Optimization

### Free Tier Usage
- **Lambda**: 1M requests + 400,000 GB-seconds per month
- **API Gateway**: 1M API calls per month
- **DynamoDB**: 25 GB storage + 25 RCU/WCU per month

### Beyond Free Tier
- **Lambda**: $0.20 per 1M requests + compute charges
- **API Gateway**: $3.50 per 1M requests
- **DynamoDB**: Pay-per-request pricing recommended for variable workloads

## SDK Examples

### JavaScript (Node.js)
```javascript
const axios = require('axios');

const apiUrl = 'https://your-api-id.execute-api.region.amazonaws.com/prod';

// Create a task
async function createTask(taskData) {
  try {
    const response = await axios.post(`${apiUrl}/tasks`, taskData);
    return response.data;
  } catch (error) {
    console.error('Error creating task:', error.response.data);
  }
}

// Get all tasks
async function getAllTasks() {
  try {
    const response = await axios.get(`${apiUrl}/tasks`);
    return response.data;
  } catch (error) {
    console.error('Error getting tasks:', error.response.data);
  }
}
```

### Python
```python
import requests
import json

api_url = 'https://your-api-id.execute-api.region.amazonaws.com/prod'

def create_task(task_data):
    try:
        response = requests.post(f'{api_url}/tasks', json=task_data)
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f'Error creating task: {e}')

def get_all_tasks():
    try:
        response = requests.get(f'{api_url}/tasks')
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f'Error getting tasks: {e}')
```

This API serves as an excellent foundation for learning serverless architecture patterns and can be extended with additional features like user authentication, task categories, due dates, and more complex querying capabilities.
