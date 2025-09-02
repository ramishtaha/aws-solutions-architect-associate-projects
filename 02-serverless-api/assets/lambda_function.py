import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Tasks')

class DecimalEncoder(json.JSONEncoder):
    """Helper class to handle Decimal types from DynamoDB"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    AWS Lambda handler for Task Management API
    Handles CRUD operations for tasks stored in DynamoDB
    
    Expected API Gateway event structure with proxy integration
    """
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract HTTP method and path
        http_method = event.get('httpMethod', '')
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        
        # Parse request body if present
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Route to appropriate handler based on HTTP method and path
        if http_method == 'GET':
            if path_parameters.get('taskId'):
                # GET /tasks/{taskId} - Get single task
                return get_task(path_parameters['taskId'])
            else:
                # GET /tasks - Get all tasks
                return get_all_tasks(query_parameters)
                
        elif http_method == 'POST':
            # POST /tasks - Create new task
            return create_task(body)
            
        elif http_method == 'PUT':
            # PUT /tasks/{taskId} - Update existing task
            task_id = path_parameters.get('taskId')
            if not task_id:
                return create_response(400, {'error': 'taskId is required for PUT requests'})
            return update_task(task_id, body)
            
        elif http_method == 'DELETE':
            # DELETE /tasks/{taskId} - Delete task
            task_id = path_parameters.get('taskId')
            if not task_id:
                return create_response(400, {'error': 'taskId is required for DELETE requests'})
            return delete_task(task_id)
            
        else:
            return create_response(405, {'error': f'Method {http_method} not allowed'})
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def create_response(status_code, body, headers=None):
    """Create standardized API Gateway response"""
    default_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',  # Enable CORS for web clients
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, X-Amz-Date, Authorization, X-Api-Key'
    }
    
    if headers:
        default_headers.update(headers)
    
    return {
        'statusCode': status_code,
        'headers': default_headers,
        'body': json.dumps(body, cls=DecimalEncoder)
    }

def get_all_tasks(query_parameters):
    """Get all tasks with optional filtering"""
    try:
        logger.info("Getting all tasks")
        
        # Get optional query parameters
        status_filter = query_parameters.get('status')
        limit = query_parameters.get('limit', '50')  # Default limit of 50
        
        try:
            limit = int(limit)
            if limit > 100:  # Cap at 100 for performance
                limit = 100
        except ValueError:
            limit = 50
        
        # Build scan parameters
        scan_params = {'Limit': limit}
        
        # Add status filter if provided
        if status_filter:
            scan_params['FilterExpression'] = boto3.dynamodb.conditions.Attr('status').eq(status_filter)
        
        # Scan the table
        response = table.scan(**scan_params)
        tasks = response.get('Items', [])
        
        # Sort by creation date (newest first)
        tasks.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
        
        return create_response(200, {
            'tasks': tasks,
            'count': len(tasks),
            'message': f'Retrieved {len(tasks)} tasks'
        })
        
    except Exception as e:
        logger.error(f"Error getting all tasks: {str(e)}")
        return create_response(500, {'error': 'Failed to retrieve tasks'})

def get_task(task_id):
    """Get a single task by ID"""
    try:
        logger.info(f"Getting task: {task_id}")
        
        response = table.get_item(Key={'taskId': task_id})
        
        if 'Item' not in response:
            return create_response(404, {'error': f'Task {task_id} not found'})
        
        return create_response(200, {
            'task': response['Item'],
            'message': f'Task {task_id} retrieved successfully'
        })
        
    except Exception as e:
        logger.error(f"Error getting task {task_id}: {str(e)}")
        return create_response(500, {'error': 'Failed to retrieve task'})

def create_task(body):
    """Create a new task"""
    try:
        logger.info(f"Creating new task with data: {body}")
        
        # Validate required fields
        if not body.get('title'):
            return create_response(400, {'error': 'title is required'})
        
        # Generate unique task ID
        task_id = str(uuid.uuid4())
        current_time = datetime.utcnow().isoformat() + 'Z'
        
        # Create task item with default values
        task = {
            'taskId': task_id,
            'title': body['title'],
            'description': body.get('description', ''),
            'status': body.get('status', 'pending'),
            'priority': body.get('priority', 'medium'),
            'createdAt': current_time,
            'updatedAt': current_time
        }
        
        # Validate status
        valid_statuses = ['pending', 'in-progress', 'completed', 'cancelled']
        if task['status'] not in valid_statuses:
            return create_response(400, {
                'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'
            })
        
        # Validate priority
        valid_priorities = ['low', 'medium', 'high', 'urgent']
        if task['priority'] not in valid_priorities:
            return create_response(400, {
                'error': f'Invalid priority. Must be one of: {", ".join(valid_priorities)}'
            })
        
        # Save to DynamoDB
        table.put_item(Item=task)
        
        logger.info(f"Task created successfully: {task_id}")
        return create_response(201, {
            'task': task,
            'message': f'Task {task_id} created successfully'
        })
        
    except Exception as e:
        logger.error(f"Error creating task: {str(e)}")
        return create_response(500, {'error': 'Failed to create task'})

def update_task(task_id, body):
    """Update an existing task"""
    try:
        logger.info(f"Updating task {task_id} with data: {body}")
        
        # Check if task exists
        response = table.get_item(Key={'taskId': task_id})
        if 'Item' not in response:
            return create_response(404, {'error': f'Task {task_id} not found'})
        
        existing_task = response['Item']
        current_time = datetime.utcnow().isoformat() + 'Z'
        
        # Prepare update expression
        update_expression = "SET updatedAt = :updated_at"
        expression_values = {':updated_at': current_time}
        
        # Add fields to update if provided
        if 'title' in body:
            update_expression += ", title = :title"
            expression_values[':title'] = body['title']
        
        if 'description' in body:
            update_expression += ", description = :description"
            expression_values[':description'] = body['description']
        
        if 'status' in body:
            valid_statuses = ['pending', 'in-progress', 'completed', 'cancelled']
            if body['status'] not in valid_statuses:
                return create_response(400, {
                    'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'
                })
            update_expression += ", #status = :status"
            expression_values[':status'] = body['status']
        
        if 'priority' in body:
            valid_priorities = ['low', 'medium', 'high', 'urgent']
            if body['priority'] not in valid_priorities:
                return create_response(400, {
                    'error': f'Invalid priority. Must be one of: {", ".join(valid_priorities)}'
                })
            update_expression += ", priority = :priority"
            expression_values[':priority'] = body['priority']
        
        # Note: Using #status as expression attribute name because 'status' is a reserved keyword in DynamoDB
        expression_names = {'#status': 'status'} if 'status' in body else None
        
        # Update the item
        update_params = {
            'Key': {'taskId': task_id},
            'UpdateExpression': update_expression,
            'ExpressionAttributeValues': expression_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_names:
            update_params['ExpressionAttributeNames'] = expression_names
        
        response = table.update_item(**update_params)
        
        logger.info(f"Task updated successfully: {task_id}")
        return create_response(200, {
            'task': response['Attributes'],
            'message': f'Task {task_id} updated successfully'
        })
        
    except Exception as e:
        logger.error(f"Error updating task {task_id}: {str(e)}")
        return create_response(500, {'error': 'Failed to update task'})

def delete_task(task_id):
    """Delete a task"""
    try:
        logger.info(f"Deleting task: {task_id}")
        
        # Check if task exists
        response = table.get_item(Key={'taskId': task_id})
        if 'Item' not in response:
            return create_response(404, {'error': f'Task {task_id} not found'})
        
        # Delete the task
        table.delete_item(Key={'taskId': task_id})
        
        logger.info(f"Task deleted successfully: {task_id}")
        return create_response(200, {
            'message': f'Task {task_id} deleted successfully'
        })
        
    except Exception as e:
        logger.error(f"Error deleting task {task_id}: {str(e)}")
        return create_response(500, {'error': 'Failed to delete task'})

# Additional utility function for API Gateway OPTIONS method (CORS preflight)
def handle_options():
    """Handle CORS preflight requests"""
    return create_response(200, {}, {
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, X-Amz-Date, Authorization, X-Api-Key'
    })
