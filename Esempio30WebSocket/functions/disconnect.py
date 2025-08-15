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
        logger.info(f"WebSocket disconnect: {connection_id}")
        
        # Cerca il giocatore con questo connectionId e lo rimuove
        response = players_table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr('connectionId').eq(connection_id)
        )
        items = response.get('Items', [])
        
        for item in items:
            logger.info(f"Removing connectionId from player {item['nickname']}")
            players_table.update_item(
                Key={'nickname': item['nickname']},
                UpdateExpression='REMOVE connectionId'
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Disconnected successfully'})
        }
        
    except Exception as e:
        logger.error(f"Error in disconnect: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
