import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col
import logging

# Configurazione del logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'database_name', 'rds_connection_name', 'rds_table_name'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
        
    # Leggi i dati dal Data Catalog
    logger.info("Lettura dei dati dal Data Catalog...")
    dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
        database = args['database_name'],
        table_name = "persone_csv"  # Questo dovrebbe corrispondere al nome della tabella creata dal Crawler
    )

    # Converti in DataFrame
    df = dynamic_frame.toDF()

    # Visualizza lo schema e alcuni dati di esempio
    logger.info("Schema del DataFrame:")
    df.printSchema()
    logger.info("Dati di esempio:")
    df.show(5, truncate=False)
    logger.info(f"Numero totale di righe: {df.count()}")

    # Assicurati che i nomi delle colonne corrispondano a quelli attesi nella tabella RDS
    expected_columns = ['nome', 'cognome', 'eta']
    for col_name in expected_columns:
        if col_name not in df.columns:
            logger.error(f"La colonna {col_name} non è presente nel DataFrame")
            raise ValueError(f"La colonna {col_name} non è presente nel DataFrame")

    # Seleziona solo le colonne necessarie e rinominale se necessario
    df_cleaned = df.select(
        col("nome").alias("Nome"),
        col("cognome").alias("Cognome"),
        col("eta").cast("int").alias("Eta")
    )

    logger.info("DataFrame pulito:")
    df_cleaned.show(5, truncate=False)
    logger.info(f"Numero di righe dopo la pulizia: {df_cleaned.count()}")

    # Riconverti in DynamicFrame
    dynamic_frame_cleaned = DynamicFrame.fromDF(df_cleaned, glueContext, "cleaned_data")
except Exception as e:
    logger.error(f"Errore : {str(e)}")
    raise

# Scrivi i dati nel database RDS
logger.info("Scrittura dei dati nel database RDS...")
try:
    glueContext.write_dynamic_frame.from_jdbc_conf(
        frame = dynamic_frame_cleaned,
        catalog_connection = args['rds_connection_name'],
        connection_options = {
            "dbtable": args['rds_table_name'],
            "database": "mydb"  # Assicurati che questo corrisponda al nome del tuo database RDS
        },
        redshift_tmp_dir = args["TempDir"],
        transformation_ctx = "write_to_rds"
    )
    logger.info("Scrittura nel database RDS completata con successo.")
except Exception as e:
    logger.error(f"Errore durante la scrittura nel database RDS: {str(e)}")
    raise

logger.info("Processo completato con successo!")
job.commit()