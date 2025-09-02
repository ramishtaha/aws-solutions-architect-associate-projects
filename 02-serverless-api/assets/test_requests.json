# Test Requests for Task Management API

This file contains sample API requests for testing your serverless Task Management API.

## Base URL
Replace `YOUR_API_ID` and `your-region` with your actual values:
```
https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod
```

## 1. Get All Tasks
**Method:** GET  
**Endpoint:** `/tasks`  
**Description:** Retrieve all tasks

### curl Command:
```bash
curl -X GET "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks"
```

### With Query Parameters (filter by status):
```bash
curl -X GET "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks?status=pending&limit=10"
```

### Expected Response (empty initially):
```json
{
  "tasks": [],
  "count": 0,
  "message": "Retrieved 0 tasks"
}
```

## 2. Create a New Task
**Method:** POST  
**Endpoint:** `/tasks`  
**Description:** Create a new task

### curl Command:
```bash
curl -X POST "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn AWS Lambda",
    "description": "Complete the serverless API project for SAA-C03 preparation",
    "status": "pending",
    "priority": "high"
  }'
```

### Sample Request Body:
```json
{
  "title": "Set up CI/CD Pipeline",
  "description": "Create automated deployment pipeline using AWS CodePipeline and CodeBuild",
  "status": "pending",
  "priority": "medium"
}
```

### Expected Response:
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

## 3. Get a Single Task
**Method:** GET  
**Endpoint:** `/tasks/{taskId}`  
**Description:** Retrieve a specific task by ID

### curl Command:
```bash
curl -X GET "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479"
```

### Expected Response:
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

## 4. Update a Task
**Method:** PUT  
**Endpoint:** `/tasks/{taskId}`  
**Description:** Update an existing task

### curl Command:
```bash
curl -X PUT "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn AWS Lambda - Updated",
    "description": "Complete the serverless API project and understand Lambda pricing models",
    "status": "in-progress",
    "priority": "high"
  }'
```

### Partial Update Example:
```bash
curl -X PUT "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed"
  }'
```

### Expected Response:
```json
{
  "task": {
    "taskId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "title": "Learn AWS Lambda - Updated",
    "description": "Complete the serverless API project and understand Lambda pricing models",
    "status": "in-progress",
    "priority": "high",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:35:00Z"
  },
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 updated successfully"
}
```

## 5. Delete a Task
**Method:** DELETE  
**Endpoint:** `/tasks/{taskId}`  
**Description:** Delete a specific task

### curl Command:
```bash
curl -X DELETE "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479"
```

### Expected Response:
```json
{
  "message": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 deleted successfully"
}
```

## Error Responses

### 404 - Task Not Found:
```json
{
  "error": "Task f47ac10b-58cc-4372-a567-0e02b2c3d479 not found"
}
```

### 400 - Bad Request (Missing Required Fields):
```json
{
  "error": "title is required"
}
```

### 400 - Bad Request (Invalid Status):
```json
{
  "error": "Invalid status. Must be one of: pending, in-progress, completed, cancelled"
}
```

### 500 - Internal Server Error:
```json
{
  "error": "Internal server error"
}
```

## Testing with Postman

You can also test these endpoints using Postman:

1. **Create a new collection** called "Task Management API"
2. **Set up environment variables:**
   - `api_url`: `https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod`
3. **Create requests for each endpoint:**
   - GET `{{api_url}}/tasks`
   - POST `{{api_url}}/tasks`
   - GET `{{api_url}}/tasks/{{taskId}}`
   - PUT `{{api_url}}/tasks/{{taskId}}`
   - DELETE `{{api_url}}/tasks/{{taskId}}`

## Valid Values

### Status Options:
- `pending`
- `in-progress`
- `completed`
- `cancelled`

### Priority Options:
- `low`
- `medium`
- `high`
- `urgent`

## Performance Testing

For load testing your API:

```bash
# Create multiple tasks quickly
for i in {1..10}; do
  curl -X POST "https://YOUR_API_ID.execute-api.your-region.amazonaws.com/prod/tasks" \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Test Task $i\", \"description\": \"Load testing task number $i\", \"status\": \"pending\"}"
done
```

This will help you understand Lambda cold starts and DynamoDB performance characteristics.
