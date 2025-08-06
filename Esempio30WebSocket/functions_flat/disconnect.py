import os
import json
import boto3

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    # Cerca il giocatore con questo connectionId e lo rimuove
    response = players_table.scan(
        FilterExpression=boto3.dynamodb.conditions.Attr('connectionId').eq(connection_id)
    )
    items = response.get('Items', [])
    for item in items:
        players_table.update_item(
            Key={'nickname': item['nickname']},
            UpdateExpression='REMOVE connectionId'
        )
    return {
        'statusCode': 200,
        'body': 'Disconnected',
        'headers': {'Content-Type': 'application/json'}
    }
