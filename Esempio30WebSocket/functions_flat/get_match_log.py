import os
import json
import boto3
from utils import response

dynamodb = boto3.resource('dynamodb')
matches_table = dynamodb.Table(os.environ.get('MATCHES_TABLE', 'Matches'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))

def lambda_handler(event, context):
    try:
        matches = matches_table.scan().get('Items', [])
        return response(200, message=matches)
    except Exception as e:
        return response(500, error=str(e))
