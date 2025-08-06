import os
import json
import boto3
from utils import response

dynamodb = boto3.resource('dynamodb')
bans_table = dynamodb.Table(os.environ.get('BANS_TABLE', 'Bans'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))
ws_endpoint = os.environ.get('WS_ENDPOINT')

apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=ws_endpoint) if ws_endpoint else None

def send_ws_notification(connection_id, message):
    if apigateway and connection_id:
        apigateway.post_to_connection(ConnectionId=connection_id, Data=json.dumps(message).encode('utf-8'))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        nickname = body.get("nickname")
        reason = body.get("reason", "Nessun motivo specificato")
        if not nickname:
            return response(400, error="Parametro 'nickname' mancante")
        bans_table.put_item(Item={
            'nickname': nickname,
            'reason': reason,
            'bannedAt': datetime.datetime.utcnow().isoformat()
        })
        players_table.delete_item(Key={'nickname': nickname})
        # Notifica WebSocket all'utente bannato
        player = players_table.get_item(Key={'nickname': nickname}).get('Item')
        if player and 'connectionId' in player:
            send_ws_notification(player['connectionId'], {'event': 'ban', 'reason': reason})
        # Log
        logs_table.put_item(Item={
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'nickname': nickname,
            'message': f"Bannato dall'amministratore: {reason}"
        })
        return response(200, message=f"{nickname} è stato bannato. Motivo: {reason}")
    except Exception as e:
        return response(500, error=str(e))
