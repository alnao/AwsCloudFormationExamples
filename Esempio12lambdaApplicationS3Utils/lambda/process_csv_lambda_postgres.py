import os
import json
import boto3
import pandas as pd
import psycopg2
from psycopg2 import sql
from botocore.exceptions import ClientError
from datetime import datetime
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

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
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Recupera i dettagli del file S3 dall'evento
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # Recupera le variabili d'ambiente
    rds_host = os.environ['RDS_HOST']
    rds_port = os.environ['RDS_PORT']
    rds_dbname = os.environ['RDS_DATABASE_NAME']
    rds_table = os.environ['RDS_TABLE_NAME']
    dynamo_table = os.environ['DYNAMO_TABLE_NAME']
    errore = None 
    try:
        rds_user, rds_password = get_rds_credentials()
        # Scarica il file CSV da S3
        logger.info(f"Downloading CSV file from S3: {bucket}/{key}")
        csv_obj = s3_client.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(csv_obj['Body'])
        logger.info(f"CSV file downloaded and read successfully. Shape: {df.shape}")

        # Connessione al database RDS
        logger.info(f"Connecting to RDS: {rds_host}:{rds_port}/{rds_dbname}")
        conn = psycopg2.connect(
            host=rds_host,
            port=rds_port,
            dbname=rds_dbname,
            user=rds_user,
            password=rds_password,
            sslmode='require'  # Forza l'uso di SSL
        )
        logger.info("Connected to RDS successfully")
        
        cur = conn.cursor()

        # Verifica se la tabella esiste e ottieni le colonne esistenti
        cur.execute(sql.SQL("SELECT * FROM {} LIMIT 0").format(sql.Identifier(rds_table)))
        existing_columns = [desc[0] for desc in cur.description] if cur.description else []

        # Se la tabella non esiste, creala con tutte le colonne del CSV
        if not existing_columns:
            logger.info(f"Creating new table: {rds_table}")
            create_table_query = sql.SQL("CREATE TABLE IF NOT EXISTS {} ({})").format(
                sql.Identifier(rds_table),
                sql.SQL(', ').join(
                    sql.SQL("{} VARCHAR(100)").format(sql.Identifier(col)) for col in df.columns
                )
            )
            cur.execute(create_table_query)
            conn.commit()
            existing_columns = df.columns.tolist()
        
        # Filtra le colonne del DataFrame per includere solo quelle presenti nella tabella
        df_filtered = df[df.columns.intersection(existing_columns)]

        # Inserisci i dati nella tabella
        logger.info(f"Inserting {len(df_filtered)} rows into RDS table")
        for _, row in df_filtered.iterrows():
            insert_query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
                sql.Identifier(rds_table),
                sql.SQL(', ').join(map(sql.Identifier, df_filtered.columns)),
                sql.SQL(', ').join(sql.Placeholder() * len(df_filtered.columns))
            )
            cur.execute(insert_query, tuple(row))

        conn.commit()
        cur.close()
        conn.close()
        logger.info("Data inserted into RDS successfully")

        # Salva il log in DynamoDB
        table = dynamodb.Table(dynamo_table)
        log_item = {
            'id': str(datetime.now().timestamp()),
            'nome_file': os.path.basename(key),
            'data_caricamento': datetime.now().isoformat(),
            'esito_caricamento': 'Successo',
            'colonne_ignorate': list(set(df.columns) - set(existing_columns))
        }
        table.put_item(Item=log_item)
        logger.info(f"Log saved to DynamoDB: {json.dumps(log_item)}")

        return {
            'statusCode': 200,
            'body': json.dumps(f'File {key} processato con successo e dati inseriti in RDS e DynamoDB')
        }

    except ClientError as e:
        errore=e
        logger.error(f"Boto3 ClientError: {str(e)}")
        if e.response['Error']['Code'] == 'SSLHandshakeError':
            logger.error("SSL Handshake failed. Check SSL configuration.")
    except psycopg2.OperationalError as e:
        errore=e
        logger.error(f"Database connection error: {str(e)}")
    except Exception as e:
        errore=e
        logger.error(f"Unexpected error: {str(e)}")
    
    # In caso di errore, salva comunque un log in DynamoDB
    try:
        table = dynamodb.Table(dynamo_table)
        table.put_item(
            Item={
                'id': str(datetime.now().timestamp()),
                'nome_file': os.path.basename(key),
                'data_caricamento': datetime.now().isoformat(),
                'esito_caricamento': f'Errore: {str(errore)}'
            }
        )
    except Exception as dynamo_error:
        logger.error(f"Error saving to DynamoDB: {str(dynamo_error)}")
    
    return {
        'statusCode': 500,
        'body': json.dumps(f'Errore nel processare il file {key}: {str(errore)}')
    }