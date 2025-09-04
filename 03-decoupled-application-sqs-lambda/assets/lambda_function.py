import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda function to process messages from SQS queue.
    
    This function receives batches of messages from SQS and processes each one.
    In a real-world scenario, this is where you would implement your business logic
    such as processing orders, sending notifications, updating databases, etc.
    
    Args:
        event: Contains SQS records with message details
        context: Lambda runtime information
    
    Returns:
        Dictionary with statusCode and processing results
    """
    
    # Log the incoming event for debugging
    logger.info(f"Received event with {len(event['Records'])} record(s)")
    
    processed_messages = []
    failed_messages = []
    
    # Process each SQS record in the batch
    for record in event['Records']:
        try:
            # Extract message details
            message_id = record['messageId']
            receipt_handle = record['receiptHandle']
            message_body = record['body']
            
            # Log message details
            logger.info(f"Processing message ID: {message_id}")
            logger.info(f"Message body: {message_body}")
            
            # Parse JSON message body (if applicable)
            try:
                parsed_message = json.loads(message_body)
                logger.info(f"Parsed message: {parsed_message}")
                
                # Example business logic - customize this section for your use case
                if isinstance(parsed_message, dict):
                    # Process different message types
                    if 'orderId' in parsed_message:
                        process_order_message(parsed_message)
                    elif 'customerId' in parsed_message:
                        process_customer_message(parsed_message)
                    else:
                        process_generic_message(parsed_message)
                else:
                    logger.info(f"Processing non-JSON message: {message_body}")
                    
            except json.JSONDecodeError:
                # Handle non-JSON messages
                logger.info(f"Message is not JSON format, processing as plain text: {message_body}")
                process_text_message(message_body)
            
            # Mark message as successfully processed
            processed_messages.append({
                'messageId': message_id,
                'status': 'processed'
            })
            
            logger.info(f"Successfully processed message ID: {message_id}")
            
        except Exception as e:
            # Log error details
            logger.error(f"Failed to process message ID {record['messageId']}: {str(e)}")
            
            # Add to failed messages list
            failed_messages.append({
                'messageId': record['messageId'],
                'error': str(e)
            })
    
    # Log processing summary
    logger.info(f"Processing complete. Successful: {len(processed_messages)}, Failed: {len(failed_messages)}")
    
    # Return processing results
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Batch processing completed',
            'processed': len(processed_messages),
            'failed': len(failed_messages),
            'details': {
                'processed_messages': processed_messages,
                'failed_messages': failed_messages
            }
        })
    }

def process_order_message(message):
    """
    Process order-related messages.
    
    Args:
        message: Parsed JSON message containing order information
    """
    order_id = message.get('orderId', 'unknown')
    customer_id = message.get('customerId', 'unknown')
    total = message.get('total', 0)
    
    logger.info(f"Processing order {order_id} for customer {customer_id} with total ${total}")
    
    # Example processing logic:
    # - Validate order details
    # - Update inventory
    # - Send confirmation email
    # - Update order status in database
    
    logger.info(f"Order {order_id} processed successfully")

def process_customer_message(message):
    """
    Process customer-related messages.
    
    Args:
        message: Parsed JSON message containing customer information
    """
    customer_id = message.get('customerId', 'unknown')
    
    logger.info(f"Processing customer message for customer {customer_id}")
    
    # Example processing logic:
    # - Update customer profile
    # - Send welcome email
    # - Trigger marketing campaigns
    
    logger.info(f"Customer message for {customer_id} processed successfully")

def process_generic_message(message):
    """
    Process generic JSON messages.
    
    Args:
        message: Parsed JSON message
    """
    logger.info(f"Processing generic JSON message with keys: {list(message.keys())}")
    
    # Example processing logic for generic messages
    # - Log message details
    # - Route to appropriate service
    # - Store in database
    
    logger.info("Generic message processed successfully")

def process_text_message(message):
    """
    Process plain text messages.
    
    Args:
        message: Plain text message string
    """
    logger.info(f"Processing text message: {message[:100]}...")  # Log first 100 characters
    
    # Example processing logic for text messages
    # - Parse text content
    # - Extract relevant information
    # - Perform text analysis
    
    logger.info("Text message processed successfully")
