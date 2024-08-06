import json
import boto3
import datetime
import os
import uuid
import jwt
import os
import base64
import datetime #from datetime import datetime

#JwtKey = os.environ['JwtKey'] 
SmmJwtSecret = os.environ['SmmJwtSecret'] 
headers= {"Access-Control-Allow-Headers" : "*","Access-Control-Allow-Origin": "*","Access-Control-Allow-Methods": "OPTIONS,POST,GET,DELETE"}

#see https://gist.github.com/bendog/44f21a921f3e4282c631a96051718619
#see https://stackoverflow.com/questions/39313421/does-python-have-an-equivalent-to-javascripts-btoa
#see https://pyjwt.readthedocs.io/en/latest/usage.html

def login_handler(event,context):
    print("Esecuzione login_handler " + json.dumps(event) )
    token=base64.b64decode( event['headers']['Authorization'].replace('Bearer ','') ).decode("utf-8") 
    print(token)
    username=token.split(':')[0]
    payload={'user':username,'authorities':['ROLE_USER'] , "exp":datetime.datetime.now() + datetime.timedelta(seconds=3600)}
    encoded_jwt = jwt.encode(payload, SmmJwtSecret, algorithm="HS256")
    print(encoded_jwt)
    return {'body': json.dumps(encoded_jwt), 'statusCode': 200, 'headers' : headers }
