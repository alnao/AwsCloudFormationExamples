import json
import boto3
import csv
import codecs
import os
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
tableName = os.environ['DynamoName'] 
def entrypoint(event,context):
  print("Esecuzione" + json.dumps(event) )
  source_s3_key = event['detail']['object']['key']
  source_bucket = event['detail']['bucket']['name']
  print('Key found: ' + source_bucket + ' in Bucket: ' + source_s3_key)
  s3_object = s3.get_object(Bucket=source_bucket, Key=source_s3_key)
  data = s3_object['Body']
  table = dynamodb.Table(tableName)
  for row in csv.DictReader(codecs.getreader('utf-8')(data), delimiter=';'):
    print("Riga: " + json.dumps(row) )
    with table.batch_writer() as batch:
      batch.put_item(Item=row)
  return {'statusCode': 200 , 'body': 'OK'}