import json
import csv
import boto3
import logging
from urllib.parse import unquote_plus
from io import StringIO

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
firehose_client = boto3.client('firehose')

# Configuration - Update this with your actual Firehose stream name
FIREHOSE_STREAM_NAME = 'data-transformation-stream'

def lambda_handler(event, context):
    """
    Lambda function to process CSV files from S3 and send transformed JSON to Kinesis Data Firehose.
    
    This function is triggered by S3 events when CSV files are uploaded.
    It reads the CSV file, transforms each row to JSON, and sends the records to Firehose.
    """
    
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Process each record in the event (S3 can send multiple records)
        for record in event['Records']:
            # Extract S3 bucket and object information
            bucket_name = record['s3']['bucket']['name']
            object_key = unquote_plus(record['s3']['object']['key'])
            
            logger.info(f"Processing file: {object_key} from bucket: {bucket_name}")
            
            # Validate file extension
            if not object_key.lower().endswith('.csv'):
                logger.warning(f"Skipping non-CSV file: {object_key}")
                continue
            
            # Download and process the CSV file
            process_csv_file(bucket_name, object_key)
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully processed CSV files',
                'processedFiles': len(event['Records'])
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise e

def process_csv_file(bucket_name, object_key):
    """
    Download CSV file from S3, transform to JSON, and send to Firehose.
    
    Args:
        bucket_name (str): S3 bucket name
        object_key (str): S3 object key (file path)
    """
    
    try:
        # Download CSV file from S3
        logger.info(f"Downloading file {object_key} from bucket {bucket_name}")
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        csv_content = response['Body'].read().decode('utf-8')
        
        # Parse CSV content
        csv_reader = csv.DictReader(StringIO(csv_content))
        
        # Track processing statistics
        total_rows = 0
        successful_records = 0
        failed_records = 0
        
        # Process each row in the CSV
        for row in csv_reader:
            total_rows += 1
            
            try:
                # Transform CSV row to JSON and send to Firehose
                json_record = transform_row_to_json(row, object_key)
                send_to_firehose(json_record)
                successful_records += 1
                
                logger.info(f"Successfully processed row {total_rows}: {json_record}")
                
            except Exception as row_error:
                failed_records += 1
                logger.error(f"Failed to process row {total_rows}: {str(row_error)}")
                # Continue processing other rows even if one fails
                continue
        
        # Log processing summary
        logger.info(f"Processing complete for {object_key}:")
        logger.info(f"  Total rows: {total_rows}")
        logger.info(f"  Successful: {successful_records}")
        logger.info(f"  Failed: {failed_records}")
        
        if total_rows == 0:
            logger.warning(f"No data rows found in {object_key}")
        
    except Exception as e:
        logger.error(f"Error processing CSV file {object_key}: {str(e)}")
        raise e

def transform_row_to_json(csv_row, source_file):
    """
    Transform a CSV row dictionary to a JSON record with additional metadata.
    
    Args:
        csv_row (dict): CSV row as dictionary (column_name: value)
        source_file (str): Source file name for metadata
        
    Returns:
        dict: Transformed JSON record
    """
    
    try:
        # Create JSON record with original data plus metadata
        json_record = {
            'data': csv_row,
            'metadata': {
                'source_file': source_file,
                'processed_timestamp': context.aws_request_id if 'context' in globals() else 'unknown',
                'transformation_type': 'csv_to_json'
            }
        }
        
        # Clean up empty values and strip whitespace
        cleaned_data = {}
        for key, value in csv_row.items():
            if value is not None:
                cleaned_value = str(value).strip()
                if cleaned_value:  # Only include non-empty values
                    cleaned_data[key] = cleaned_value
        
        json_record['data'] = cleaned_data
        
        return json_record
        
    except Exception as e:
        logger.error(f"Error transforming CSV row to JSON: {str(e)}")
        raise e

def send_to_firehose(json_record):
    """
    Send a JSON record to Kinesis Data Firehose.
    
    Args:
        json_record (dict): JSON record to send to Firehose
    """
    
    try:
        # Convert JSON to string and add newline for proper formatting
        record_data = json.dumps(json_record) + '\n'
        
        # Send record to Firehose
        response = firehose_client.put_record(
            DeliveryStreamName=FIREHOSE_STREAM_NAME,
            Record={
                'Data': record_data
            }
        )
        
        logger.info(f"Successfully sent record to Firehose. Record ID: {response['RecordId']}")
        
    except Exception as e:
        logger.error(f"Error sending record to Firehose: {str(e)}")
        raise e

def validate_environment():
    """
    Validate that required environment variables and configurations are set.
    This function can be called during Lambda initialization if needed.
    """
    
    if not FIREHOSE_STREAM_NAME:
        raise ValueError("FIREHOSE_STREAM_NAME must be configured")
    
    logger.info(f"Lambda function configured with Firehose stream: {FIREHOSE_STREAM_NAME}")

# Optional: Validate environment on import
# validate_environment()
