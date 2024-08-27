import boto3
import pandas as pd
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
    
    # Download the Excel file from S3
    excel_obj = s3_client.get_object(Bucket=bucket, Key=key)
    excel_data = excel_obj['Body'].read()
    
    # Convert Excel to CSV
    df = pd.read_excel(io.BytesIO(excel_data))
    csv_buffer = io.StringIO()
    df.to_csv(csv_buffer, index=False)
    
    # Upload CSV to the CSV folder
    csv_key = os.path.join('CSV', os.path.splitext(os.path.basename(key))[0] + '.csv')
    s3_client.put_object(Bucket=bucket, Key=csv_key, Body=csv_buffer.getvalue())
    
    return {
        'statusCode': 200,
        'body': f'Successfully converted {key} to CSV and uploaded to {csv_key}'
    }