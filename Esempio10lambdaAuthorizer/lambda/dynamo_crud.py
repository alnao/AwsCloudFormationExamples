import json
import boto3
from boto3.dynamodb.types import TypeSerializer, TypeDeserializer
import datetime
import os
import uuid
client = boto3.client('dynamodb')
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ['DynamoName'] 
headers= {"Access-Control-Allow-Headers" : "*","Access-Control-Allow-Origin": "*","Access-Control-Allow-Methods": "OPTIONS,POST,GET,DELETE"}

def get_handler(event,context):
    print("Esecuzione get " + json.dumps(event) )
    table = dynamodb.Table(TABLE_NAME)
    response = table.scan() #FilterExpression=Attr('id').eq('1') | Attr('id').eq('2'))
    return {'body': json.dumps(response['Items']), 'statusCode': 200, 'headers' : headers }

def post_handler(event,context):
    print("Esecuzione post " + json.dumps(event) )
    post_str = event['body']
    post = json.loads(post_str)
    current_timestamp = datetime.datetime.now().isoformat()
    post['updatedAt'] = current_timestamp
    ts= TypeSerializer()
    if 'id' not in post: #gestione ID nuovo elemento
        post['id'] = str(uuid.uuid4())
    if post['id']=='':
        post['id'] = str(uuid.uuid4())
    serialized_post= ts.serialize(post)["M"]
    res = client.put_item(TableName=TABLE_NAME,Item=serialized_post)
    return {'body': json.dumps(res), 'statusCode': 201, 'headers' : headers }

def delete_handler(event,context):
    print("Esecuzione delete " + json.dumps(event) )
    post_str = event['body']
    post = json.loads(post_str)
    id_value = post['id']
    res = client.delete_item(TableName=TABLE_NAME,Key={ 'id' : { 'S' : id_value } } )
    return {'body': json.dumps(res), 'statusCode': 204, 'headers' : headers }

#def options_handler(event,context):
#    print("Esecuzione get " + json.dumps(event) )
#    return {'body': 'OK', 'statusCode': 200, 'headers' : headers }
