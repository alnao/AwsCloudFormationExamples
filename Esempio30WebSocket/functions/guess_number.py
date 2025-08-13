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
MAX_CHANGES_PER_DAY = int(os.environ.get('MAX_CHANGES_PER_DAY', 5))

apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=ws_endpoint) if ws_endpoint else None
bans_table = dynamodb.Table(os.environ.get('BANS_TABLE', 'Bans'))

def send_ws_notification(connection_id, message):
    if apigateway and connection_id:
        apigateway.post_to_connection(ConnectionId=connection_id, Data=json.dumps(message).encode('utf-8'))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        attacker = body.get("attacker")
        guess = body.get("guess")

        if not attacker or guess is None:
            return response(400, "Parametri mancanti: attacker, guess")

        # Prende i dati dell'attaccante
        attacker_data = players_table.get_item(Key={'nickname': attacker}).get('Item')
        if not attacker_data:
            return response(404, "Attaccante non esiste.")

        # Controllo limite tentativi giornalieri
        now = datetime.datetime.utcnow()
        today = now.strftime("%Y-%m-%d")
        guesses = attacker_data.get('guesses', {})
        today_guesses = guesses.get(today, 0)
        if today_guesses >= MAX_CHANGES_PER_DAY:
            return response(429, f"Hai raggiunto il numero massimo di tentativi per oggi ({MAX_CHANGES_PER_DAY}).")
        # Aggiorna il conteggio tentativi
        guesses[today] = today_guesses + 1
        attacker_data['guesses'] = guesses
        players_table.put_item(Item=attacker_data)

        # Recupera i giocatori bannati
        banned = bans_table.scan().get('Items', [])
        banned_nicknames = set(b['nickname'] for b in banned)

        # Recupera tutti i giocatori attivi (escludendo l'attaccante e i bannati)
        all_players = players_table.scan().get('Items', [])
        targets = [p for p in all_players if p['nickname'] != attacker and p['nickname'] not in banned_nicknames]

        found = False
        for target_data in targets:
            if target_data.get('number') == guess:
                # Attacco riuscito
                attacker_data['score'] = attacker_data.get('score', 0) + 1
                players_table.put_item(Item=attacker_data)

                # Log e match
                match_id = f"{attacker}-{target_data['nickname']}-{datetime.datetime.utcnow().isoformat()}"
                match_record = {
                    'matchId': match_id,
                    'timestamp': datetime.datetime.utcnow().isoformat(),
                    'winner': attacker,
                    'loser': target_data['nickname'],
                    'numberGuessed': guess
                }
                matches_table.put_item(Item=match_record)
                players_table.delete_item(Key={'nickname': target_data['nickname']})

                _log_event(attacker, f"Ha indovinato il numero di {target_data['nickname']}: {guess}")
                _log_event(target_data['nickname'], f"È stato eliminato da {attacker}.")

                # Invia notifica WebSocket
                send_ws_notification(attacker_data.get('connectionId'), {"message": f"Hai indovinato! {target_data['nickname']} è stato eliminato."})
                send_ws_notification(target_data.get('connectionId'), {"message": f"Sei stato eliminato da {attacker}."})

                found = True
        if found:
            return response(200, f"Hai indovinato almeno un numero! Giocatori eliminati: {[p['nickname'] for p in targets if p.get('number') == guess]}")
        else:
            attacker_data['score'] = attacker_data.get('score', 0) - 1
            players_table.put_item(Item=attacker_data)
            _log_event(attacker, f"Tentativo fallito su tutti. Numero sbagliato: {guess}")
            return response(200, f"Numero sbagliato. Nessun giocatore eliminato.")
    except Exception as e:
        return response(500, error=str(e))

def _log_event(nickname, message):
    logs_table.put_item(Item={
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'nickname': nickname,
        'message': message
    })
