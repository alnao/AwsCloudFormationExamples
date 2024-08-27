import os
import json
import boto3
from botocore.exceptions import ClientError

def handler(event, context):
    print(event)
    s3 = boto3.client('s3')
    bucket_name = os.environ['S3_BUCKET_NAME']
    
    # Ottieni il nome del file dalla query string
    file_key = event['queryStringParameters'].get('file_key')
    
    if not file_key:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'File key not provided'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    
    try:
        # Genera un URL pre-firmato per il download
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket_name, 'Key': file_key},
            ExpiresIn=3600  # URL valido per 1 ora
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'download_url': url}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }