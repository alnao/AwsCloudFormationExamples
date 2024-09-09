import boto3
import os
import json

headers= {"Access-Control-Allow-Headers" : "*","Access-Control-Allow-Origin": "*","Access-Control-Allow-Methods": "OPTIONS,POST,GET,DELETE"}

def entrypoint(event, context):
    print("consumer entrypoint",event)
    sqs=boto3.client('sqs')
    QueueName = os.environ['QueueName']
    AccountId = os.environ['AccountId']
    response=sqs.get_queue_url( QueueName=QueueName , QueueOwnerAWSAccountId=AccountId )
    url=response['QueueUrl']
    queue=sqs.receive_message(
        QueueUrl=url,
        AttributeNames=['All'],
        MessageAttributeNames=['All'],
        MaxNumberOfMessages=1, #1 or 10
        VisibilityTimeout=0,
        WaitTimeSeconds=1,
    )
    data=[]
    if 'Messages' in queue:
        for e in queue['Messages']:
            data.append( json.loads( e['Body'] ) )
            sqs.delete_message(
                QueueUrl=url,
                ReceiptHandle=e['ReceiptHandle']
            )
       
    return {'statusCode': queue['ResponseMetadata']['HTTPStatusCode'] , 'body': json.dumps(data) , 'headers' : headers}
