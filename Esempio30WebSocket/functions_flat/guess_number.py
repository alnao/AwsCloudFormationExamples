import os
import json
import boto3
import datetime
from utils import response

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))
matches_table = dynamodb.Table(os.environ.get('MATCHES_TABLE', 'Matches'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))
ws_endpoint = os.environ.get('WS_ENDPOINT')

apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=ws_endpoint) if ws_endpoint else None

def send_ws_notification(connection_id, message):
    if apigateway and connection_id:
        apigateway.post_to_connection(ConnectionId=connection_id, Data=json.dumps(message).encode('utf-8'))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        attacker = body.get("attacker")
        target = body.get("target")
        guess = body.get("guess")

        if not attacker or not target or guess is None:
            return response(400, "Parametri mancanti: attacker, target, guess")

        # Prende i dati dei due giocatori
        attacker_data = players_table.get_item(Key={'nickname': attacker}).get('Item')
        target_data = players_table.get_item(Key={'nickname': target}).get('Item')

        if not attacker_data or not target_data:
            return response(404, "Uno dei giocatori non esiste.")

        if target_data.get('number') == guess:
            # Attacco riuscito
            attacker_data['score'] = attacker_data.get('score', 0) + 1
            players_table.put_item(Item=attacker_data)

            # Log e match
            match_id = f"{attacker}-{target}-{datetime.datetime.utcnow().isoformat()}"
            match_record = {
                'matchId': match_id,
                'timestamp': datetime.datetime.utcnow().isoformat(),
                'winner': attacker,
                'loser': target,
                'numberGuessed': guess
            }
            matches_table.put_item(Item=match_record)
            players_table.delete_item(Key={'nickname': target})

            _log_event(attacker, f"Ha indovinato il numero di {target}: {guess}")
            _log_event(target, f"È stato eliminato da {attacker}.")

            # Invia notifica WebSocket
            send_ws_notification(attacker_data['connection_id'], {"message": f"Hai indovinato! {target} è stato eliminato."})
            send_ws_notification(target_data['connection_id'], {"message": f"Sei stato eliminato da {attacker}."})

            return response(200, f"Hai indovinato! {target} è stato eliminato.")
        else:
            attacker_data['score'] = attacker_data.get('score', 0) - 1
            players_table.put_item(Item=attacker_data)
            _log_event(attacker, f"Tentativo fallito su {target}. Numero sbagliato: {guess}")
            return response(200, f"Numero sbagliato. Tentativo fallito su {target}.")
    except Exception as e:
        return response(500, error=str(e))

def _log_event(nickname, message):
    logs_table.put_item(Item={
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'nickname': nickname,
        'message': message
    })
