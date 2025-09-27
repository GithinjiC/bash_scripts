import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Create a CloudFront client
        cloudfront = boto3.client('cloudfront')

        # Extract path parameters or query parameters from the event (if needed)
        path_params = event.get('pathParameters', {})
        query_params = event.get('queryStringParameters', {})

        # Construct the Cloudfront URL dynamically
        cloudfront_url = f"https://my-cloudfront/api/v1/" 
        # Add path parameters if needed
        cloudfront_url += f"/{path_params.get('id')}" if 'id' in path_params else "" 

        # Make a GET request to Cloudfront (using requests library for more flexibility)
        import requests
        response = requests.get(cloudfront_url, params=query_params) 

        # Check for Cloudfront response status code
        if response.status_code != 200:
            raise Exception(f"Cloudfront returned status code: {response.status_code}")

        # Extract and process the response body
        data = response.json() 

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(data)
        }
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }