import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))

def lambda_handler(event, context):
    try:
        connection_id = event['requestContext']['connectionId']
        logger.info(f"WebSocket connect: {connection_id}")
        
        # Puoi ricevere nickname dal client dopo la connessione
        body = json.loads(event.get('body', '{}'))
        nickname = body.get('nickname')
        
        if nickname:
            logger.info(f"Associating connection {connection_id} with nickname {nickname}")
            # Salva connectionId associato al nickname
            players_table.update_item(
                Key={'nickname': nickname},
                UpdateExpression='SET connectionId = :cid',
                ExpressionAttributeValues={':cid': connection_id}
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Connected successfully'})
        }
        
    except Exception as e:
        logger.error(f"Error in connect: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
