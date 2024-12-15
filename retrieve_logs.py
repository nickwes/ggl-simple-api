import os
import boto3
import json
import logging
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        logger.info("Event received: %s", json.dumps(event))
        
        # Scan DynamoDB table
        response = table.scan()
        items = response.get('Items', [])
        
        # Sort by DateTime in descending order (most recent first)
        sorted_items = sorted(items, key=lambda x: x['DateTime'], reverse=True)
        
        # Take only the last 100 items
        latest_items = sorted_items[:100]
        
        logger.info("Retrieved %d items from DynamoDB", len(latest_items))
        
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(latest_items)
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
