import paramiko
import io
import boto3
import os
import json

username=os.environ['USERNAME']
host=os.environ['HOST']
port=int(os.environ['PORT'])
key_param_name=os.environ['PRIVATE_KEY_PARAM']

def handler(event, context):
    print("event",event)
    ssm = boto3.client('ssm')
    s3 = boto3.client('s3')
    private_key_str = ssm.get_parameter(Name=key_param_name, WithDecryption=True)['Parameter']['Value']
    private_key = paramiko.RSAKey.from_private_key(io.StringIO(private_key_str,))
    transport = paramiko.Transport(host, port)
    transport.connect(username=username,pkey=private_key)
    sftp = paramiko.SFTPClient.from_transport(transport)

    source_bucket = event['detail']['bucket']['name']
    source_key = event['detail']['object']['key']
    dest_path = os.path.basename(source_key)
    print("sending file", dest_path)
    with sftp.open(dest_path, 'wb', 32768) as f:
        s3.download_fileobj(source_bucket, source_key, f)
    return {
        'statusCode': 300,
        'body': json.dumps('File '+ dest_path +' has been Successfully Copied')
    }
        
