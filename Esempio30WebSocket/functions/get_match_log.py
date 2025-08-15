import os
import json
import boto3
import decimal
from utils import response

dynamodb = boto3.resource('dynamodb')
matches_table = dynamodb.Table(os.environ.get('MATCHES_TABLE', 'Matches'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))

def convert_decimals(obj):
    if isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, decimal.Decimal):
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    else:
        return obj

def lambda_handler(event, context):
    try:
        matches = matches_table.scan().get('Items', [])
        matches = convert_decimals(matches)
        return response(200, message=matches)
    except Exception as e:
        return response(500, error=str(e))
