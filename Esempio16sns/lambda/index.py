import boto3
import os
import json

def handler(event, context):
    print("es16 entrypoint",event)
    if 'Records' in event:
        for message in event['Records']:
            if 'body' in message:
                print("Messaggio ricevuto da SNS con il body:",message['body'])
                print("Messaggio ricevuto da SNS:",message)
                return
    print("Nessun messaggio arrivato")
