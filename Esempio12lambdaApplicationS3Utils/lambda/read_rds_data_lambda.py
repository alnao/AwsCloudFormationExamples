import os
import json
import boto3
import mysql.connector
import base64
from botocore.exceptions import ClientError

def get_rds_credentials():
    secret_arn = os.environ['RDS_SECRET_ARN']
    region = os.environ.get('AWS_REGION', 'eu-west-1')
    client = boto3.client('secretsmanager', region_name=region)
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
        secret = get_secret_value_response['SecretString']
        secret_dict = json.loads(secret)
        return secret_dict['username'], secret_dict['password']
    except Exception as e:
        raise Exception(f"Errore nel recupero delle credenziali dal secret: {str(e)}")

def handler(event, context):
    print(event)
    rds_host = os.environ['RDS_HOST']
    rds_port = os.environ['RDS_PORT']
    rds_dbname = os.environ['RDS_DATABASE_NAME']
    rds_table = os.environ['RDS_TABLE_NAME']
    db_type = os.environ.get('RDS_ENGINE', 'mysql')
    try:
        rds_user, rds_password = get_rds_credentials()
        if db_type == 'postgres':
            print("postgres (implementazione non inclusa)")
        else:
            conn = mysql.connector.connect(
                host=rds_host,
                port=int(rds_port),
                database=rds_dbname,
                user=rds_user,
                password=rds_password
            )
        with conn.cursor() as cur:
            query = f"SELECT * FROM {rds_table}"
            cur.execute(query)
            rows = cur.fetchall()
            column_names = [desc[0] for desc in cur.description]
            result = [dict(zip(column_names, row)) for row in rows]
        conn.close()
        return {
            'statusCode': 200,
            'body': json.dumps(result),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        print(f"Errore: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }