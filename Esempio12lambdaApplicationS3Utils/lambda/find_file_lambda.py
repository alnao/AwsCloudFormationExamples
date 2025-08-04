import boto3
import os
from boto3.dynamodb.conditions import Key

def handler(event, context):
    params = event.get('queryStringParameters', {}) or {}
    nomeFile = params.get('nomeFile')
    if not nomeFile:
        return {'statusCode': 400, 'body': 'Missing nomeFile'}
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMO_TABLE_NAME'])
    resp = table.query(
        IndexName='nomeFile-index',
        KeyConditionExpression=Key('nomeFile').eq(nomeFile)
    )
    return {
        'statusCode': 200,
        'body': resp.get('Items', [])
    }
