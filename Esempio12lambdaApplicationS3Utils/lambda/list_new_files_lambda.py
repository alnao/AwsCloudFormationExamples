import boto3
import os
from boto3.dynamodb.conditions import Attr

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMO_TABLE_NAME'])
    resp = table.scan(
        FilterExpression=Attr('nuovo').eq('S')
    )
    return {
        'statusCode': 200,
        'body': resp.get('Items', [])
    }
