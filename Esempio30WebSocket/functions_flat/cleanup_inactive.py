import os
import boto3
import datetime
from utils import response

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))

INACTIVITY_DAYS = 10

def lambda_handler(event, context):
    now = datetime.datetime.utcnow()
    cutoff = now - datetime.timedelta(days=INACTIVITY_DAYS)
    response_scan = players_table.scan()
    players = response_scan.get('Items', [])
    removed = []
    for p in players:
        last_update = p.get('lastUpdate')
        if last_update:
            last_dt = datetime.datetime.fromisoformat(last_update)
            if last_dt < cutoff:
                players_table.delete_item(Key={'nickname': p['nickname']})
                removed.append(p['nickname'])
    return response(200, message={"removed": removed})
