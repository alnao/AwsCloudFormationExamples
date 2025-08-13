import os
import json
import boto3
from utils import response
import datetime

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))
ws_endpoint = os.environ.get('WS_ENDPOINT')
apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=ws_endpoint) if ws_endpoint else None

def send_ws_to_all(message):
    response_scan = players_table.scan()
    players = response_scan.get('Items', [])
    for p in players:
        connection_id = p.get('connectionId')
        if apigateway and connection_id:
            apigateway.post_to_connection(ConnectionId=connection_id, Data=json.dumps(message).encode('utf-8'))

def reset_all_numbers():
    response_scan = players_table.scan()
    players = response_scan.get('Items', [])
    # Calcola timestamp di 24 ore e 1 minuto fa
    dt = datetime.datetime.utcnow() - datetime.timedelta(hours=24, minutes=1)
    last_update_value = dt.isoformat()
    for p in players:
        p['number'] = 0
        p['lastUpdate'] = last_update_value
        players_table.put_item(Item=p)

def lambda_handler(event, context):
    body = json.loads(event.get("body", "{}"))
    action = body.get('action')
    if action == 'broadcast':
        text = body.get('text', '')
        send_ws_to_all({'event': 'broadcast', 'text': text})
        return response(200, message='Messaggio inviato a tutti')
    elif action == 'reset_numbers':
        reset_all_numbers()
        send_ws_to_all({'event': 'reset', 'text': 'Tutti i numeri sono stati azzerati'})
        return response(200, message='Numeri azzerati per tutti')
    else:
        return response(400, error='Azione non riconosciuta')
