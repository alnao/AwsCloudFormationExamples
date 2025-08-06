import os
import json
import boto3
from utils import response

dynamodb = boto3.resource('dynamodb')
players_table = dynamodb.Table(os.environ.get('PLAYERS_TABLE', 'Players'))

def lambda_handler(event, context):
    try:
        response_scan = players_table.scan()
        players = response_scan.get('Items', [])
        active_players = [p for p in players if p.get('score', None) is not None]
        return response(200, message=active_players)
    except Exception as e:
        return response(500, error=str(e))
