import os
import json
import boto3
import datetime
from utils import response

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))

MAX_CHANGES_PER_DAY = int(os.environ.get('MAX_CHANGES_PER_DAY', 5))

# Validazione nickname e numero

def validate_nickname(nickname):
    return isinstance(nickname, str) and 5 <= len(nickname) <= 30 and nickname.isalnum()

def validate_number(number):
    return isinstance(number, int) and 0 < number <= 99

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        nickname = body.get("nickname")
        number = body.get("number")

        if not validate_nickname(nickname):
            return response(400, error="Nickname non valido (5-30 caratteri, solo lettere/numeri)")
        if not validate_number(number):
            return response(400, error="Numero non valido (intero >0, max 6 cifre)")

        # Controllo univocità nickname
        response_nick = players_table.get_item(Key={'nickname': nickname})
        if 'Item' in response_nick:
            player = response_nick['Item']
            # Controllo tempo ultimo cambio
            last_update = player.get('lastUpdate')
            if last_update:
                last_dt = datetime.datetime.fromisoformat(last_update)
                now = datetime.datetime.utcnow()
                if (now - last_dt).total_seconds() < 86400:
                    return response(429, error="Puoi cambiare il numero solo una volta ogni 24 ore.")
            # Controllo che il numero non sia già stato scelto da altri
            scan = players_table.scan(
                ProjectionExpression='#num, nickname',
                ExpressionAttributeNames={'#num': 'number'}
            )
            for p in scan.get('Items', []):
                if p['number'] == number and p['nickname'] != nickname:
                    return response(409, error=f"Numero già scelto da un altro giocatore ({p['nickname']}). Scegli un altro numero.")
            # Aggiorna il numero e lastUpdate
            player['number'] = number
            player['lastUpdate'] = datetime.datetime.utcnow().isoformat()
            players_table.put_item(Item=player)
            _log_event(nickname, f"Giocatore {nickname} ha cambiato numero in {number}")
            return response(200, message=f"Numero cambiato in {number}")
        else:
            # Controllo che il numero non sia già stato scelto da altri
            scan = players_table.scan(
                ProjectionExpression='#num, nickname',
                ExpressionAttributeNames={'#num': 'number'}
            )
            for p in scan.get('Items', []):
                if p['number'] == number:
                    return response(409, error=f"Numero già scelto da un altro giocatore ({p['nickname']}). Scegli un altro numero.")
            # Nuovo giocatore
            now = datetime.datetime.utcnow()
            today = now.strftime("%Y-%m-%d")
            player = {
                'nickname': nickname,
                'number': number,
                'score': 0,
                'changes': {today: 1},
                'lastUpdate': now.isoformat()
            }
            players_table.put_item(Item=player)
            _log_event(nickname, f"Giocatore {nickname} iscritto con numero {number}")
            return response(200, message=f"Giocatore {nickname} iscritto con numero {number}")
    except Exception as e:
        return response(500, error=str(e))


def _log_event(nickname, message):
    timestamp = datetime.datetime.utcnow().isoformat()
    logs_table.put_item(Item={
        'timestamp': timestamp,
        'nickname': nickname,
        'message': message
    })
