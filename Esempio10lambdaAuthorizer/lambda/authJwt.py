import json
import jwt
import os
import boto3
#from datetime import datetime

#JwtKey = os.environ['JwtKey'] 
SmmJwtSecret = os.environ['SmmJwtSecret'] 

def entrypoint(event, context):
    print("Lambda auth: " + json.dumps(event))
    principalId='' #TODO
    methodArn=''
    try:
        methodArn=event['methodArn']
        token = event.get('authorizationToken')
        #token = ''+event['headers']['Authorization'] #questa è la versione alternativa con FunctionPayloadType: REQUEST, vedi template
        #token = token.replace('Bearer ','')
        print ("pre decoded:" + token)
        ssm = boto3.client('ssm')
        parameter = ssm.get_parameter(Name=SmmJwtSecret, WithDecryption=True)
        jwt_secret = parameter['Parameter']['Value']
        decoded = jwt.decode(token, jwt_secret, algorithms=['HS256'])
        print ( decoded)
    except Exception as e: 
        print(e)
        return generatePolicy(principalId, 'Deny', methodArn)
    return generatePolicy(principalId, 'Allow', methodArn )

def generatePolicy(principalId, effect, methodArn): 
    authResponse = {}
    authResponse['principalId'] = principalId
    if effect and methodArn:
        policyDocument = {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Sid': 'FirstStatement',
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': methodArn
                }
            ]
        }
        authResponse['policyDocument'] = policyDocument
    print( authResponse )
    return authResponse