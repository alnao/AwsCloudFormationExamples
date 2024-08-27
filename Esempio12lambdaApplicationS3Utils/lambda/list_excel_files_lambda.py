import os
import json
import boto3

def handler(event, context):
    print(event)
    s3 = boto3.client('s3')
    bucket_name = os.environ['S3_BUCKET_NAME']
    dezipped_folder = os.environ['DEZIPPED_FOLDER_NAME']
    
    try:
        response = s3.list_objects_v2(
            Bucket=bucket_name,
            Prefix=f"{dezipped_folder}/"
        )
        
        excel_files = [
            {
                'key': obj['Key'],
                'name': os.path.basename(obj['Key']),
                'size': obj['Size'],
                'last_modified': obj['LastModified'].isoformat()
            }
            for obj in response.get('Contents', [])
            if obj['Key'].lower().endswith(('.xlsx', '.xls'))
        ]
        
        return {
            'statusCode': 200,
            'body': json.dumps(excel_files),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }