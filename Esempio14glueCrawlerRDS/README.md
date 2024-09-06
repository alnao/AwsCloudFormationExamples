# AWS CloudFormation Examples - 14 Glue Crawler
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Componenti di questo template:
- Database RDS 
- Glue Database: database Glue per memorizzare i metadati dei file CSV.
- Glue Table: tabella per il salvataggio dei dati
- Glue Crawler: Crawler Glue che analizzerà il file nel bucket S3 per aggiornare il catalogo dati.
- Glue Job: utilizza il Data Catalog come fonte dei dati invece di leggere direttamente da S3 e scrive i dati nel database RDS
- Glue Workflow: gestire il flusso di esecuzione del Crawler e poi il Job in sequenza
- IAM Role: Aggiornato il ruolo IAM con le autorizzazioni necessarie per il Crawler e l'accesso al Data Catalog.
- EventBridge Rule: regola evento per avviare la step function quando viene caricato un file in un bucket
- StepFunction per gestire l'esecuzione delle lambda
- Lambda function per avviare il Workflows
- Lambda function per ottenere lo stato del Workflows
- IAM role: regole di accesso delle lambda ai servizi glue

Note:
- dopo la creazione del database RDS è necessario creare manualmente  la tabella persone
  ```
  -- mydb.persone definition
  CREATE TABLE `persone` (
    `Nome` varchar(100) DEFAULT NULL,
    `Cognome` varchar(100) DEFAULT NULL,
    `Eta` int DEFAULT NULL,
    `Id` int NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (`Id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
  ```
- è stata usata la tecnica di stepfunctione e lambda, la regola eventbridge che scatena il Workflow non funziona correttamente, per maggiori dettagli vedere la [documentazione](https://docs.aws.amazon.com/it_it/glue/latest/dg/starting-workflow-eventbridge.html) e gli [articoli dedicati](https://repost.aws/knowledge-center/glue-workflow-not-triggered)
- *questo template potrebbe prevedere dei costi aggiuntivi non trascurabili. Prestare attenzione prima di rilasciare questo template*

## CloudFormation
Documentazione di [Glue-job](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-glue-job.html)
```
  GlueCrawler:
    Type: AWS::Glue::Crawler
    Properties:
      Name: csv-s3-crawler
      Role: !Ref GlueRole
      DatabaseName: !Ref GlueDatabase
      Targets:
        S3Targets:
          - Path: !Sub s3://${BucketName}/${CSVPath}
      Schedule:
        ScheduleExpression: cron(0 0 * * ? *)  # Run daily at midnight UTC
      SchemaChangePolicy:
        UpdateBehavior: "UPDATE_IN_DATABASE"
        DeleteBehavior: "LOG"
  GlueRDSConnection:
    Type: AWS::Glue::Connection
    Properties:
      CatalogId: !Ref AWS::AccountId
      ConnectionInput:
        ConnectionType: JDBC
        ConnectionProperties:
          JDBC_CONNECTION_URL: !Sub 
            - jdbc:mysql://${RDSEndpoint}:3306/mydb
            - RDSEndpoint: !GetAtt RDSInstance.Endpoint.Address
          USERNAME: admin
          PASSWORD: !Join ['', ['{{resolve:secretsmanager:', !Ref RDSSecret, ':SecretString:password}}' ]]
        Name: rds-connection
        PhysicalConnectionRequirements:
          SecurityGroupIdList: 
            - !Ref SecurityGroup
          SubnetId: !Ref Subnet
  GlueDatabase:
    Type: AWS::Glue::Database
    Properties:
      CatalogId: !Ref AWS::AccountId
      DatabaseInput:
        Name: csv_to_rds_database
        Description: Database for CSV to RDS pipeline
```

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio14glueCrawlerRDS  --capabilities CAPABILITY_IAM --parameter-overrides VpcId=vpc-0013c2751d04a7413 PrivateSubnet1=subnet-0ca3ce54f35c3d3ef PrivateSubnet2=subnet-08dbf4b5fed6a83b2

    aws s3 cp ./glue/glue_esempio14.py s3://formazione-sftp-simulator/CODE/glue/glue_esempio14.py
    ```
* Comandi per il caricamento via CLI
    ```
    aws s3 cp .\persone.csv s3://formazione-sftp-simulator/INPUT/persone.csv
    
    ```
* Comandi per la rimozione dello stack
    ```
    sam delete --stack-name Esempio14glueCrawlerRDS
    ```

## Comandi CLI specifici per i job glue
* Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/glue/index.html)
* Elenco i jobs:
    ```
    aws glue get-jobs
    aws glue get-jobs --query Jobs[*].[Name,Command.ScriptLocation,ExecutionClass] --output table
    ```
* Creazione un nuovo job:
    ```
    aws glue create-job --name my-job --role my-glue-role --command Name=glueetl,ScriptLocation=s3://my-bucket/my-script.py
    ```
* Avvio di un job
    ```
    aws glue start-job-run --job-name esempio13-glue-job
    ```
* Dettaglio di una esecuzione di un job 
    ```
    aws glue get-job-run --job-name esempio13-glue-job --run-id jr_xxx
    aws glue get-job-run --job-name esempio13-glue-job --run-id jr_xxx  --query JobRun[StartedOn,JobRunState,CompletedOn] --output table
    ```
* Aggiornare un job esistente:
    ```
    aws glue update-job --job-name my-job --job-update Role=my-new-role,Command={ScriptLocation=s3://my-bucket/my-updated-script.py}
    ```
* Eliminare un job:
    ```
    aws glue delete-job --job-name my-job
    ```
* Elencare i crawlers:
  ```
  aws glue get-crawlers
  aws glue get-crawlers --query Crawlers[*].[Name,Targets.S3Targets.Path,DatabaseName,State] --output table
  ```
* Creare un nuovo crawler:
  ```
  aws glue create-crawler --name my-crawler --role my-crawler-role --database-name my-database --targets S3Targets=[{Path=s3://my-bucket/my-data}]
  ```
* Avviare un crawler:
  ```
  aws glue start-crawler --name my-crawler
  ```
* Ottenere lo stato di un crawler:
  ```
  aws glue get-crawler --name my-crawler
  ```
* Aggiornare un crawler esistente:
  ```
  aws glue update-crawler --name my-crawler --role my-new-crawler-role
  ```
* Eliminare un crawler:
  ```
  aws glue delete-crawler --name my-crawler
  ```
* Creare un glue-database:
  ```
  aws glue create-database --database-input Name=my-database
  ```
* Elencare i database:
  ```
  aws glue get-databases
  aws glue get-databases  --query DatabaseList[*].[Name,Description,CreateTime] --output table
  ```
* Ottenere dettagli di una tabella:
  ```
  aws glue get-table --database-name csv_to_rds_database --name persone_csv
  ```
* Creare una tabella:
  ```
  aws glue create-table --database-name my-database --table-input '{"Name":"my-table","StorageDescriptor":{"Columns":[{"Name":"column1","Type":"string"}],"Location":"s3://my-bucket/my-data","InputFormat":"org.apache.hadoop.mapred.TextInputFormat","OutputFormat":"org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat","SerdeInfo":{"SerializationLibrary":"org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"}}}'
  ```
* Eliminare una tabella:
  ```
  aws glue delete-table --database-name my-database --name my-table
  ```
* Creare una connessione:
  ```
  aws glue create-connection --connection-input '{"Name":"my-connection","ConnectionType":"JDBC","ConnectionProperties":{"JDBC_CONNECTION_URL":"jdbc:mysql://myhost:3306/mydb","USERNAME":"username","PASSWORD":"password"}}'
  ```
* Elencare le connessioni:
  ```
  aws glue get-connections
  aws glue get-connections --query ConnectionList[*].[Name,ConnectionType,ConnectionProperties.JDBC_CONNECTION_URL] --output table
  ```
* Eliminare una connessione:
  ```
  aws glue delete-connection --name my-connection
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it
