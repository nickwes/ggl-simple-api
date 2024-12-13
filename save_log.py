import os
import boto3
import uuid
from datetime import datetime, UTC
import json

dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

def handler(event, context):
    try:
        body = json.loads(event['body'])
        log_entry = {
            "ID": str(uuid.uuid4()),
            "DateTime": datetime.now(UTC).isoformat(),
            "Severity": body.get("Severity", "info"),
            "Message": body["Message"]
        }
        table.put_item(Item=log_entry)
        return {
            "statusCode": 201,
            "body": json.dumps({"message": "Log saved successfully"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
