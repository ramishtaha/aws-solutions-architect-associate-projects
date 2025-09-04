import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ServerlessAPI-Items')

def lambda_handler(event, context):
    """
    Main Lambda handler for CRUD operations on DynamoDB
    Supports GET, POST, PUT, DELETE operations
    """
    
    try:
        # Extract HTTP method and path parameters
        http_method = event.get('httpMethod')
        path_parameters = event.get('pathParameters') or {}
        
        # Route requests based on HTTP method
        if http_method == 'GET':
            if 'id' in path_parameters:
                # GET /items/{id} - Get specific item
                return get_item(path_parameters['id'])
            else:
                # GET /items - Get all items
                return get_all_items()
                
        elif http_method == 'POST':
            # POST /items - Create new item
            return create_item(event.get('body'))
            
        elif http_method == 'PUT':
            # PUT /items/{id} - Update existing item
            return update_item(path_parameters['id'], event.get('body'))
            
        elif http_method == 'DELETE':
            # DELETE /items/{id} - Delete item
            return delete_item(path_parameters['id'])
            
        else:
            return create_response(405, {'error': 'Method not allowed'})
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return create_response(500, {'error': 'Internal server error', 'details': str(e)})

def get_all_items():
    """
    Retrieve all items from DynamoDB table
    """
    try:
        response = table.scan()
        items = response.get('Items', [])
        
        # Convert Decimal objects to float for JSON serialization
        items = convert_decimals(items)
        
        return create_response(200, {
            'items': items,
            'count': len(items)
        })
        
    except Exception as e:
        print(f"Error getting all items: {str(e)}")
        return create_response(500, {'error': 'Could not retrieve items'})

def get_item(item_id):
    """
    Retrieve a specific item by ID
    """
    try:
        response = table.get_item(Key={'id': item_id})
        
        if 'Item' not in response:
            return create_response(404, {'error': 'Item not found'})
        
        item = convert_decimals(response['Item'])
        return create_response(200, item)
        
    except Exception as e:
        print(f"Error getting item {item_id}: {str(e)}")
        return create_response(500, {'error': 'Could not retrieve item'})

def create_item(body):
    """
    Create a new item in DynamoDB
    """
    try:
        if not body:
            return create_response(400, {'error': 'Request body is required'})
        
        # Parse JSON body
        data = json.loads(body)
        
        # Validate required fields
        if 'name' not in data:
            return create_response(400, {'error': 'Name field is required'})
        
        # Generate unique ID and timestamp
        item_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Prepare item for DynamoDB
        item = {
            'id': item_id,
            'name': data['name'],
            'description': data.get('description', ''),
            'created_at': timestamp,
            'updated_at': timestamp
        }
        
        # Add any additional fields from the request
        for key, value in data.items():
            if key not in ['id', 'created_at', 'updated_at']:
                item[key] = value
        
        # Save to DynamoDB
        table.put_item(Item=item)
        
        return create_response(201, item)
        
    except json.JSONDecodeError:
        return create_response(400, {'error': 'Invalid JSON in request body'})
    except Exception as e:
        print(f"Error creating item: {str(e)}")
        return create_response(500, {'error': 'Could not create item'})

def update_item(item_id, body):
    """
    Update an existing item in DynamoDB
    """
    try:
        if not body:
            return create_response(400, {'error': 'Request body is required'})
        
        # Parse JSON body
        data = json.loads(body)
        
        # Check if item exists
        existing_item = table.get_item(Key={'id': item_id})
        if 'Item' not in existing_item:
            return create_response(404, {'error': 'Item not found'})
        
        # Build update expression
        update_expression = "SET updated_at = :timestamp"
        expression_values = {':timestamp': datetime.utcnow().isoformat()}
        
        # Add fields to update
        for key, value in data.items():
            if key not in ['id', 'created_at']:  # Don't allow updating these fields
                update_expression += f", {key} = :{key}"
                expression_values[f":{key}"] = value
        
        # Update item in DynamoDB
        response = table.update_item(
            Key={'id': item_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ReturnValues='ALL_NEW'
        )
        
        updated_item = convert_decimals(response['Attributes'])
        return create_response(200, updated_item)
        
    except json.JSONDecodeError:
        return create_response(400, {'error': 'Invalid JSON in request body'})
    except Exception as e:
        print(f"Error updating item {item_id}: {str(e)}")
        return create_response(500, {'error': 'Could not update item'})

def delete_item(item_id):
    """
    Delete an item from DynamoDB
    """
    try:
        # Check if item exists
        existing_item = table.get_item(Key={'id': item_id})
        if 'Item' not in existing_item:
            return create_response(404, {'error': 'Item not found'})
        
        # Delete the item
        table.delete_item(Key={'id': item_id})
        
        return create_response(200, {'message': f'Item {item_id} deleted successfully'})
        
    except Exception as e:
        print(f"Error deleting item {item_id}: {str(e)}")
        return create_response(500, {'error': 'Could not delete item'})

def create_response(status_code, body):
    """
    Create a standardized API Gateway response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # Enable CORS
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, default=str)
    }

def convert_decimals(obj):
    """
    Convert DynamoDB Decimal objects to float for JSON serialization
    """
    if isinstance(obj, list):
        return [convert_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj
