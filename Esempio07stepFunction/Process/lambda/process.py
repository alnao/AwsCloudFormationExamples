import json
import boto3
import csv
import codecs
import os

#client = boto3.client('stepfunctions')
DestBucket = os.environ['DestBucket']
DestFilePath = os.environ['DestFilePath']
s3 = boto3.client('s3')

def entrypoint(event, context):
    print(event)
    #event= {'file': {'source': 'OUTPUT/prova.csv-2023-10-23T13:05:05.025Z'}}
    s3_object = s3.get_object(Bucket=DestBucket, Key=event['file']['source'])
    data = s3_object['Body']
    for row in csv.DictReader(codecs.getreader('utf-8')(data), delimiter=';'):
        print("Riga: " + json.dumps(row) )
#TODO in future versioni: salvare i dati in DynamoDB
#  table = dynamodb.Table(tableName)
#  for row in csv.DictReader(codecs.getreader('utf-8')(data), delimiter=';'):
#    print("Riga: " + json.dumps(row) )
#    with table.batch_writer() as batch:
#      batch.put_item(Item=row)
    return {'statusCode': 200 , 'body': 'OK'}
    
