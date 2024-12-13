
import os
import boto3
import json

dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

def handler(event, context):
    try:
        response = table.scan()
        logs = sorted(response["Items"], key=lambda x: x["DateTime"], reverse=True)[:100]
        return {
            "statusCode": 200,
            "body": json.dumps(logs)
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
