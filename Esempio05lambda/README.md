# AWS CloudFormation Examples by AlNao - 05 Lambda Function
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Lambda in Python invocata da una "notifica" da un bucket S3. 

Questo è solo un esempio e non segue le best-practices di AWS:
- il trigger è generato con NotificationConfiguration di S3 al posto di EventBridge (usato nei prossimi esempi)
- il codice python è dentro il modello yaml al posti di file py separati


## CloudFormation
Documentazione di [lambda-function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html)
```
  "Type" : "AWS::Lambda::Function"
```

* Comandi per la creazione dell'esempio
    ```
    sam validate
    sam build
    sam deploy --stack-name esempio04 --capabilities CAPABILITY_IAM --parameter-overrides BucketName=esempio04s3notifica
    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)
* Comando caricamento file di prova e verifica esecuzione lambda
    ```
    aws s3 cp prova.csv s3://esempio04s3notifica/
    aws s3 ls s3://esempio04s3notifica/
    aws cloudwatch get-metric-statistics --cli-input-json file://cloudwatch-get-stats.json --query Datapoints[].[Timestamp,SampleCount] --output table
    aws logs filter-log-events --log-group-name "/aws/lambda/esempio04-S3Notification-qjayNPwcruwY" --query events[].[timestamp,message] --output text
    ```
* Comandi per la distruzione dello stack con cancellazione del bucket
    ```
    aws s3 rm s3://esempio04s3notifica/prova.csv
    sam delete --stack-name esempio04
    ```

## Comandi CLI
* Documentazione [CLI Lambda](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudfront/index.html)
* Recupero lista delle lambda e dettaglio di una lambda
    ```
    aws lambda list-functions --query Functions[].FunctionName --output table
    aws lambda   get-function --function-name esempio04-S3Notification-qjayNPwcruwY
    ```    
* Creazione di una lambda
    ```
	aws lambda --profile default create-function --function-name <nome-funzione> --runtime python3.8 --zip-file fileb://function.zip --handler lambda.handler --role arn:aws:iam::xxxxxxxx:role/lambda-formazione-dr-role
    ```
* Invocazione di una lambda
    ```
	aws lambda --profile default invoke --function-name <nome-funzione> outputfile.txt
    cat outputfile.txt
    ```
* Creazione ed esecuzione di una lambda (con regola IAM e codice python)
    ```
	echo "{  \"Version\": \"2012-10-17\",  \"Statement\": [    {      \"Effect\": \"Allow\",      \"Principal\": {      \"Service\": [        \"lambda.amazonaws.com\"      ]      },      \"Action\": \"sts:AssumeRole\"    }  ]}" > role.json
	aws iam --profile default create-role --role-name lambda-formazione-dr-role --assume-role-policy-document file://role.json
	echo "def handler(event, context): " > lambda.py
	echo "    print(event)"  >> lambda.py
	echo "    return \"{ 'statusCode': 200,        'message' : 'DR OK' }\"" >> lambda.py
	/C/Program\ Files/7-Zip/7z.exe a -tZip function.zip lambda.py
	aws lambda --profile default   create-function --function-name <nome-funzione> --runtime python3.8 --zip-file fileb://function.zip --handler lambda.handler --role arn:aws:iam::xxxxxx:role/lambda-formazione-dr-role
	aws lambda --profile default   invoke --function-name <nome-funzione> outputfile.txt
	cat outputfile.txt
* Verifica esecuzioni della Lambda su CloudWatch (metrica nel file json separato)
    ```
    aws cloudwatch get-metric-statistics --cli-input-json file://cloudwatch-get-stats.json
    aws cloudwatch get-metric-statistics --cli-input-json file://cloudwatch-get-stats.json --query Datapoints[].[Timestamp,SampleCount] --output table
    ```
* Verfiica esecuzioni della lambda su LOGS
    ```
    aws logs filter-log-events --log-group-name "/aws/lambda/esempio04-S3Notification-XuE5shURUFvH"
    aws logs filter-log-events --log-group-name "/aws/lambda/esempio04-S3Notification-XuE5shURUFvH" --query events[].[timestamp,message] --output text
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*