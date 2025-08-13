import os
import json
import boto3
from utils import response

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))

def lambda_handler(event, context):
    try:
        response_scan = players_table.scan()
        players = response_scan.get('Items', [])
        result = sorted([
            {
                'nickname': p['nickname'],
                'score': int(p.get('score', 0)),
                'lastUpdate': p.get('lastUpdate', '')
            }
            for p in players
        ], key=lambda x: x['score'], reverse=True)
        return response(200, message=result)
    except Exception as e:
        return response(500, error=str(e))
