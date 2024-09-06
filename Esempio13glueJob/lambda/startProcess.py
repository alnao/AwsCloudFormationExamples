import boto3
import os
import json
import fnmatch

client = boto3.client('stepfunctions')

def entrypoint(event, context):
    print("event: " + json.dumps(event))
    new_s3_key="NULL"
    if "object" in event["detail"]:
        new_s3_key=event["detail"]["object"]["key"]
    else:
        new_s3_key = event['detail']['requestParameters']['key']
    print("Key found: " + new_s3_key)
    file_name = os.path.basename(new_s3_key)
    print("Filename: " + file_name)
    if file_name=="":
        return
    print("File patern to match with: " + os.environ['FILE_PATTERN_MATCH'])
    if fnmatch.fnmatch(file_name, os.environ['FILE_PATTERN_MATCH']):
        print("File matched!")
        print("Start state machine " + os.environ['STATE_MACHINE_ARN'])
        client.start_execution(
            stateMachineArn=os.environ['STATE_MACHINE_ARN'],
            input='{ "filename": "' + file_name + '"  }')
                    


