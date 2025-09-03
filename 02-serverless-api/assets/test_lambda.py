#!/usr/bin/env python3
"""
Lambda Function Tester for Task Management API
This script provides a reliable way to test Lambda functions when AWS CLI has encoding issues.
Works across all platforms including WSL2.
"""
import boto3
import json
import sys

def test_lambda_function():
    """Test the TaskAPI Lambda function with various scenarios"""
    
    # Initialize Lambda client
    try:
        lambda_client = boto3.client('lambda')
        print("✅ AWS SDK initialized successfully")
    except Exception as e:
        print(f"❌ Error initializing AWS SDK: {e}")
        print("Make sure you have configured AWS credentials:")
        print("  aws configure")
        return False

    # Test scenarios
    test_cases = [
        {
            "name": "GET All Tasks",
            "payload": {
                "httpMethod": "GET",
                "pathParameters": None,
                "queryStringParameters": None,
                "body": None,
                "headers": {"Content-Type": "application/json"},
                "isBase64Encoded": False
            }
        },
        {
            "name": "GET Tasks with Query Parameters",
            "payload": {
                "httpMethod": "GET",
                "pathParameters": None,
                "queryStringParameters": {"status": "pending", "limit": "10"},
                "body": None,
                "headers": {"Content-Type": "application/json"},
                "isBase64Encoded": False
            }
        },
        {
            "name": "POST Create Task",
            "payload": {
                "httpMethod": "POST",
                "pathParameters": None,
                "queryStringParameters": None,
                "body": json.dumps({
                    "title": "Test Task from Python",
                    "description": "Testing Lambda function with Python script",
                    "status": "pending",
                    "priority": "medium"
                }),
                "headers": {"Content-Type": "application/json"},
                "isBase64Encoded": False
            }
        }
    ]

    success_count = 0
    total_tests = len(test_cases)

    for i, test_case in enumerate(test_cases, 1):
        print(f"\n🧪 Test {i}/{total_tests}: {test_case['name']}")
        print("-" * 50)
        
        try:
            # Invoke the Lambda function
            response = lambda_client.invoke(
                FunctionName='TaskAPI',
                Payload=json.dumps(test_case['payload'])
            )
            
            # Read the response
            response_payload = response['Payload'].read().decode('utf-8')
            
            # Parse and display the response
            try:
                parsed_response = json.loads(response_payload)
                print(f"Status Code: {parsed_response.get('statusCode', 'Unknown')}")
                
                if 'body' in parsed_response:
                    body = json.loads(parsed_response['body']) if isinstance(parsed_response['body'], str) else parsed_response['body']
                    print(f"Response: {json.dumps(body, indent=2)}")
                else:
                    print(f"Response: {json.dumps(parsed_response, indent=2)}")
                
                # Check if response is successful
                status_code = parsed_response.get('statusCode', 0)
                if 200 <= status_code < 300:
                    print("✅ Test PASSED")
                    success_count += 1
                else:
                    print("❌ Test FAILED (HTTP error)")
                    
            except json.JSONDecodeError:
                print(f"Raw response: {response_payload}")
                print("⚠️  Response is not valid JSON")
                
        except Exception as e:
            print(f"❌ Error invoking Lambda function: {e}")
            
    # Summary
    print(f"\n📊 Test Summary")
    print("=" * 50)
    print(f"Tests passed: {success_count}/{total_tests}")
    
    if success_count == total_tests:
        print("🎉 All tests passed! Your Lambda function is working correctly.")
        print("\n💡 Next steps:")
        print("1. Set up API Gateway to expose your Lambda function")
        print("2. Test the complete API with curl or Postman")
        return True
    else:
        print("⚠️  Some tests failed. Check the Lambda function logs in CloudWatch.")
        print("\n🔍 Debugging tips:")
        print("1. Check CloudWatch logs: aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/TaskAPI'")
        print("2. Verify DynamoDB table exists: aws dynamodb describe-table --table-name Tasks")
        print("3. Check IAM permissions for the Lambda execution role")
        return False

def main():
    """Main function"""
    print("🚀 Task Management API - Lambda Function Tester")
    print("=" * 60)
    
    # Check if boto3 is installed
    try:
        import boto3
    except ImportError:
        print("❌ boto3 is not installed. Please install it:")
        print("   pip3 install boto3")
        sys.exit(1)
    
    # Run tests
    success = test_lambda_function()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
