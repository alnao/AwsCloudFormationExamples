import os
import json
import boto3
from botocore.exceptions import ClientError

def handler(event, context):
    print(event)
    s3_client = boto3.client('s3', config=boto3.session.Config(signature_version='s3v4'))
    bucket_name = os.environ['S3_BUCKET_NAME']
    input_folder = os.environ['INPUT_FOLDER_NAME']
    
    # Ottieni il nome del file dalla query string
    file_name = event['queryStringParameters'].get('file_name')
    
    if not file_name:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'File name not provided'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    
    # Controlla l'estensione del file
    if not file_name.lower().endswith('.zip'):
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'File must have .zip extension'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    
    # Costruisci il percorso completo del file
    file_key = f"{input_folder}/{file_name}"
    
    try:
        # Genera un URL pre-firmato per l'upload
        url = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': bucket_name, 'Key': file_key},
            ExpiresIn=3600,  # URL valido per 1 ora
            HttpMethod='PUT'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'upload_url': url}),
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