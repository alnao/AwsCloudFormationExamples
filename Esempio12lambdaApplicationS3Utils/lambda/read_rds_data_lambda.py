import os
import json
#import psycopg2
#import pymysql
import mysql.connector

def handler(event, context):
    print(event)
    # Recupera i parametri di connessione dalle variabili d'ambiente
    rds_host = os.environ['RDS_HOST']
    rds_port = os.environ['RDS_PORT']
    rds_dbname = os.environ['RDS_DATABASE_NAME']
    rds_user = os.environ['RDS_USERNAME']
    rds_password = os.environ['RDS_PASSWORD']
    rds_table = os.environ['RDS_TABLE_NAME']

    # Determina il tipo di database (MySQL o PostgreSQL)
    db_type = os.environ.get('RDS_ENGINE', 'mysql')

    try:
        # Stabilisce la connessione al database
        if db_type == 'postgres':
#            conn = psycopg2.connect(
#                host=rds_host,
#                port=rds_port,
#                dbname=rds_dbname,
#                user=rds_user,
#                password=rds_password
#            )
            print("postgres ")
        else:  # assume MySQL
            conn = mysql.connector.connect(
                host=rds_host,
                port=int(rds_port),
                database=rds_dbname,
                user=rds_user,
                password=rds_password
                #,ssl_ca='rds-ca-2019-root.pem'  # Assicurati di includere questo file nel pacchetto Lambda
            )
#            conn = pymysql.connect(
#                host=rds_host,
#                port=int(rds_port),
#                database=rds_dbname,
#                user=rds_user,
#                password=rds_password
#            )

        with conn.cursor() as cur:
            # Esegue la query per leggere i dati
            query = f"SELECT * FROM {rds_table}"
            cur.execute(query)

            # Recupera i risultati
            rows = cur.fetchall()

            # Ottiene i nomi delle colonne
            column_names = [desc[0] for desc in cur.description]

            # Converte i risultati in un formato JSON-serializzabile
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