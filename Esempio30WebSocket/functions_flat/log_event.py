import os
import json
import boto3

dynamodb = boto3.resource('dynamodb')
logs_table = dynamodb.Table(os.environ.get('LOGS_TABLE', 'Logs'))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        nickname = body.get("nickname")
        message = body.get("message")
        if not nickname or not message:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'nickname e message obbligatori'}),
                'headers': {'Content-Type': 'application/json'}
            }
        logs_table.put_item(Item={
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'nickname': nickname,
            'message': message
        })
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Log registrato'}),
            'headers': {'Content-Type': 'application/json'}
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {'Content-Type': 'application/json'}
        }
