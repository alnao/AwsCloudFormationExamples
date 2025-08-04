import boto3
import os
import hashlib
from datetime import datetime, timezone

def handler(event, context):
    s3 = boto3.client('s3')
    dynamodb = boto3.resource('dynamodb')
    bucket = os.environ['S3_BUCKET_NAME']
    table = dynamodb.Table(os.environ['DYNAMO_TABLE_NAME'])
    paginator = s3.get_paginator('list_objects_v2')
    now = datetime.now(timezone.utc).isoformat()
    
    for page in paginator.paginate(Bucket=bucket):
        for obj in page.get('Contents', []):
            key = obj['Key']
            nomeFile = key.split('/')[-1]
            path = '/'.join(key.split('/')[:-1])
            id_val = hashlib.sha256((nomeFile + path).encode()).hexdigest()
            size = obj['Size']
            created = obj['LastModified'].isoformat()
            # Check if already exists
            resp = table.get_item(Key={'id': id_val})
            if 'Item' in resp:
                # Update 'nuovo' to 'N' and update timestamp
                table.update_item(
                    Key={'id': id_val},
                    UpdateExpression="SET nuovo=:n, dataOraAggiornamentoRiga=:d",
                    ExpressionAttributeValues={':n': 'N', ':d': now}
                )
            else:
                table.put_item(Item={
                    'id': id_val,
                    'nomeFile': nomeFile,
                    'path': path,
                    'dimensione': size,
                    'dataOraCreazioneFile': created,
                    'nuovo': 'S',
                    'dataOraAggiornamentoRiga': now
                })
    return {'statusCode': 200, 'body': 'Scan completed'}
