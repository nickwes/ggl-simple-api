import os
import boto3
import json
import logging

dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info("Event received: %s", json.dumps(event))
        
        # Scan DynamoDB table to get all items
        response = table.scan()
        items = response.get('Items', [])
        
        logger.info("Retrieved %d items from DynamoDB", len(items))
        
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(items)
        }
    except Exception as e:
        logger.error("Error occurred: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": str(e)})
        }
