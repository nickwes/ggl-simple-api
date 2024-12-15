import os
import boto3
import uuid
from datetime import datetime
import datetime as dt
import json
import logging

dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        # Log the incoming event for inspection
        logger.info("Event received: %s", json.dumps(event))
        
        # Ensure the event has a body
        if not event.get('body'):
            logger.error("Request body is missing")
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json"
                },
                "body": json.dumps({"error": "Request body is missing"})
            }

        # Parse the body from the event
        body = json.loads(event['body'])
        logger.info("Parsed body: %s", body)

        log_entry = {
            "ID": str(uuid.uuid4()),  # Generating a new ID
            "DateTime": datetime.now(dt.timezone.utc).isoformat(),
            "Severity": body.get("Severity", "info"),
            "Message": body.get("message")  # Changed to get() method
        }
        
        logger.info("Attempting to save log entry: %s", log_entry)

        # Save the log entry to DynamoDB
        table.put_item(Item=log_entry)
        
        logger.info("Successfully saved log entry")

        return {
            "statusCode": 201,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"message": "Log saved successfully"})
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
