import os
import json
import boto3
import pandas as pd
import mysql.connector
from mysql.connector import Error as MySQLError
from botocore.exceptions import ClientError
from datetime import datetime
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Recupera i dettagli del file S3 dall'evento
    if 'Records' in event:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
    else:
        bucket = event['detail']['bucket']['name']
        key = event['detail']['object']['key']
    
    # Recupera le variabili d'ambiente
    rds_host = os.environ['RDS_HOST']
    rds_port = int(os.environ['RDS_PORT'])
    rds_dbname = os.environ['RDS_DATABASE_NAME']
    rds_user = os.environ['RDS_USERNAME']
    rds_password = os.environ['RDS_PASSWORD']
    rds_table = os.environ['RDS_TABLE_NAME']
    dynamo_table = os.environ['DYNAMO_TABLE_NAME']
    errore = None 
    try:
        # Scarica il file CSV da S3
        logger.info(f"Downloading CSV file from S3: {bucket}/{key}")
        csv_obj = s3_client.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(csv_obj['Body'])
        logger.info(f"CSV file downloaded and read successfully. Shape: {df.shape}")

        # Connessione al database RDS MySQL
        logger.info(f"Connecting to MySQL RDS: {rds_host}:{rds_port}/{rds_dbname}")
        conn = mysql.connector.connect(
            host=rds_host,
            port=rds_port,
            database=rds_dbname,
            user=rds_user,
            password=rds_password
            #,ssl_ca='rds-ca-2019-root.pem'  # Assicurati di includere questo file nel pacchetto Lambda
        )
        logger.info("Connected to MySQL RDS successfully")
        
        cursor = conn.cursor()

        # Verifica se la tabella esiste e ottieni le colonne esistenti
        existing_columns=None
        try:
            cursor.execute(f"SHOW COLUMNS FROM {rds_table}")
            existing_columns = [column[0] for column in cursor.fetchall()]
        except MySQLError as e:
            existing_columns = False
            logger.error(f"MySQL Database error: {str(e)}")

        # Se la tabella non esiste, creala con tutte le colonne del CSV
        if not existing_columns:
            logger.info(f"Creating new table: {rds_table}")
            create_table_query = f"CREATE TABLE IF NOT EXISTS {rds_table} ({', '.join([f'{col} VARCHAR(100)' for col in df.columns])})"
            cursor.execute(create_table_query)
            conn.commit()
            existing_columns = df.columns.tolist()
        
        # Filtra le colonne del DataFrame per includere solo quelle presenti nella tabella
        df_filtered = df[df.columns.intersection(existing_columns)]

        # Inserisci i dati nella tabella
        logger.info(f"Inserting {len(df_filtered)} rows into RDS table")
        for _, row in df_filtered.iterrows():
            placeholders = ', '.join(['%s'] * len(df_filtered.columns))
            columns = ', '.join(df_filtered.columns)
            insert_query = f"INSERT INTO {rds_table} ({columns}) VALUES ({placeholders})"
            cursor.execute(insert_query, tuple(row))

        conn.commit()
        cursor.close()
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
        if 'SSL' in str(e):
            logger.error("SSL connection failed. Check SSL configuration.")
    except MySQLError as e:
        errore=e
        logger.error(f"MySQL Database error: {str(e)}")
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