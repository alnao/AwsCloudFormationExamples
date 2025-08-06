# AWS CloudFormation Examples - 13 Glue Jobd 
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)


Componenti di questo template:
- regola EventBridge-trigger per avviare una lambda al upload di un file
- lambda che gestisce l'avvio della step function
- step function che esegue la lambda di conversione da excel a csv e lancio processo glue
- processo glue che esegue logiche sui dati (filtro sui dati) con libreria Spark

## CloudFormation
Documentazione di [Glue-job](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-glue-job.html)
```
  GlueProcess: #see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_Glue.html
    Type: AWS::Glue::Job
    Properties:
      Name: esempio13-glue-job
      GlueVersion: "3.0" # pythonshell=1.0, glueetl=0.9 default
      ExecutionProperty:
        MaxConcurrentRuns: 20
      MaxRetries: 0
      # MaxCapacity: 1 #Max Capacity should be between 0.0 and 1.0 if present for pythonshell,
      AllocatedCapacity: 2 # only glueetl, defaul 10 with , 2 to 100
      DefaultArguments:
        "--enable-continuous-cloudwatch-log": true
        "--enable-continuous-log-filter": true
        "--additional-python-modules": "pyspark"
      Command: #see https://github.com/aws-samples/aws-etl-orchestrator/blob/master/cloudformation/glue-resources.yaml
        # Name: pythonshell #nota: se pythonshell massimo MaxCapacity:1
        # PythonVersion: "3.9"
        Name: glueetl #nota se glueetl, MaxCapacity 2-100, defaul 10 
        ScriptLocation: !Sub "s3://${Bucket}/${CodePosition}/etl_code.py"
      Role: !GetAtt GlueExecutionRole.Arn
```

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio13glueJob  --capabilities CAPABILITY_IAM 

    aws s3 cp ./glue/etl_code.py s3://cloudformation-alnao/CODE/glue/etl_code.py
    ```
* Comandi per il caricamento via CLI
    ```
    aws s3 cp .\persone.xlsx s3://cloudformation-alnao/INPUT/excel/persone.xlsx
    
    ```
* Comandi per la rimozione dello stack
    ```
    sam delete --stack-name Esempio13glueJob
    ```

## Comandi CLI specifici per i job glue
* Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/glue/index.html)
* Elenco i jobs:
    ```
    aws glue get-jobs
    aws glue get-jobs --query Jobs[*].[Name,Command.ScriptLocation,ExecutionClass] --output table
    ```
* Creazione della regola IAM per eseguire un job che accede a bucket
    ```
	aws iam create-role --role-name esempio13-role --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"glue.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    aws iam put-role-policy --role-name esempio13-role --policy-name esempio13-role-policy --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:*\",\"Resource\":[\"arn:aws:s3:::*\",\"arn:aws:s3:::*/*\"]}]}"
    ```
* Creazione un nuovo job:
    ```
    aws glue create-job --name my-job --role esempio13-role --command Name=glueetl,ScriptLocation=s3://my-bucket/my-script.py
    ```
* Avvio di un job
    ```
    aws glue start-job-run --job-name esempio13-glue-job
    ```
* Elenco delle esecuzioni di un job
    ```
    aws glue get-job-runs --job-name esempio13-glue-job
    aws glue get-job-runs --job-name esempio13-glue-job --query JobRuns[*].[StartedOn,JobRunState,CompletedOn] --output table
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
    aws iam delete-role-policy --role-name esempio13-role --policy-name esempio13-role-policy 
	aws iam delete-role --role-name esempio13-role
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it
