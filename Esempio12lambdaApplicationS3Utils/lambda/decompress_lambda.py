import boto3
import zipfile
import io
import os

s3_client = boto3.client('s3')

def handler(event, context):
    print(event)
    # Get bucket name and file key from the S3 event
    if 'Records' in event:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
    else:
        bucket = event['detail']['bucket']['name']
        key = event['detail']['object']['key']

    # Download the zip file from S3
    zip_obj = s3_client.get_object(Bucket=bucket, Key=key)
    buffer = io.BytesIO(zip_obj['Body'].read())
    
    # Unzip the contents
    with zipfile.ZipFile(buffer) as zip_file:
        for filename in zip_file.namelist():
            file_content = zip_file.read(filename)
            
            # Upload each file to the DEZIPPED folder
            dezipped_key = os.path.join('DEZIPPED', os.path.basename(filename))
            s3_client.put_object(Bucket=bucket, Key=dezipped_key, Body=file_content)
    
    return {
        'statusCode': 200,
        'body': f'Successfully unzipped and uploaded contents of {key}'
    }