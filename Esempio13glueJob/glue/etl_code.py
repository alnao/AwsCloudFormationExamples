import sys
import boto3
import json
import os
#import zipfile 
from zipfile import ZipFile, ZIP_DEFLATED
import tempfile
from awsglue.utils import getResolvedOptions
from datetime import datetime 
#from boxsdk import Client, OAuth2
from pyspark import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col,length #, lit, length, monotonically_increasing_id, count, collect_set, concat_ws, trim, upper, size, split, coalesce, array_contains, to_date

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
args = getResolvedOptions(sys.argv, ['JOB_NAME','BUCKET','SOURCE_PATH','SOURCE_FILE','DEST_PATH','numero_righe','file_name'])
job.init(args['JOB_NAME'], args)
logger = glueContext.get_logger()

C_BUCKET=args['BUCKET']
C_SOURCE_PATH=args['SOURCE_PATH']
C_SOURCE_FILE=args['SOURCE_FILE']
C_DEST_PATH=args['DEST_PATH']
numero_righe=args['numero_righe']
file_name=args['file_name']

C_LIST_DELIMETER=";"
s3_client = boto3.client('s3') #s3_res = boto3.resource('s3')
s3 = boto3.resource('s3')
#data_oggi=datetime.today().strftime('%Y%m%d')

numero_righe=0
file_name='error'
try:
    numero_righe=args['numero_righe']
    file_name=args['file_name']
    logger.info("File: " + C_BUCKET + "//" + file_name)
except Exception:
    logger.info("errore recupero parametri")
    numero_righe=0
logger.info("Eseguo il numero_righe=" + str(numero_righe) + " nella file_name=" + str(file_name) )

#logic here!
if int(numero_righe)>0 :
    content = spark.read.options(header=True, delimiter=";").csv('s3://' + C_BUCKET + "/" + file_name)
    normalized_columns = list(map(lambda x: x.lower().replace(" ","_"), content.columns))
    content = content.toDF(*normalized_columns)
    content_filtered=content.filter( (length(col("nome"))>0) & (col("cognome").isNotNull())).filter("eta < 42 ").filter(col("eta").cast("int") > 18 )
    content_filtered.show()
    logger.info("Scrivo il file " + C_BUCKET + "/" + file_name.replace(C_SOURCE_PATH,C_DEST_PATH) )
    content_filtered.select("*").toPandas().to_csv('s3://' + C_BUCKET + "/" + file_name.replace(C_SOURCE_PATH,C_DEST_PATH), index = False, header=True, sep =';')
else:
    logger.info("Nessun file eseguito " )    
    job.commit()
    sys.exit(1) #1=exit_code error 
esito="OK" #"esegui_gruppo(gruppo_id,cartella_run)"
logger.info("Fine con esito" + esito)
job.commit()