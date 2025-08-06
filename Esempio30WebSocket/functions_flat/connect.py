import os
import json
import boto3

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))

apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ.get('WS_ENDPOINT'))

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    # Puoi ricevere nickname dal client dopo la connessione
    body = json.loads(event.get('body', '{}'))
    nickname = body.get('nickname')
    if nickname:
        # Salva connectionId associato al nickname
        players_table.update_item(
            Key={'nickname': nickname},
            UpdateExpression='SET connectionId = :cid',
            ExpressionAttributeValues={':cid': connection_id}
        )
    return {
        'statusCode': 200,
        'body': 'Connected',
        'headers': {'Content-Type': 'application/json'}
    }
