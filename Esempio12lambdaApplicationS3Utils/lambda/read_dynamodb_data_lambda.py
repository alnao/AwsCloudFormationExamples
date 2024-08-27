import os
import json
import boto3
from boto3.dynamodb.conditions import Key

def handler(event, context):
    print(event)
    # Recupera il nome della tabella DynamoDB dalla variabile d'ambiente
    table_name = os.environ['DYNAMODB_TABLE_NAME']

    # Inizializza il client DynamoDB
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)

    try:
        # Esegue una scansione della tabella
        response = table.scan()

        # Recupera i risultati
        items = response['Items']

        # Se ci sono più pagine di risultati, continua la scansione
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response['Items'])

        return {
            'statusCode': 200,
            'body': json.dumps(items),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }

    except Exception as e:
        print(f"Errore: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }