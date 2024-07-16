# AWS CloudFormation Examples by AlNao - 09 Dynamo e API
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Esempio di template CloudFormation per creare una tabella Dynamo, una piccola infrastruttura con API-REST per leggere e scrivere nella tabella

In questo esempio viene usato il tipo "Serverless":
```
Type: AWS::Serverless::Api
```

## CloudFormation
Documentazione di [Dynamo](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html). Oggetti creati di tipo
```
Resources:
  Dynamo:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Ref DynamoName
      AttributeDefinitions:
        - 
          AttributeName: "id"
          AttributeType: "S"
      KeySchema: 
        - 
          AttributeName: "id"
          KeyType: "HASH"
      ProvisionedThroughput: 
        ReadCapacityUnits: "5"
        WriteCapacityUnits: "5"
```

* Comandi per la creazione dell'esempio

    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio09dynamoApiCrud --capabilities CAPABILITY_IAM

    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)
* Comando caricamento file csv
    ```
    aws s3 cp ./films.csv s3://alberto-bucket-es09/INPUT/films.csv
    sam logs --stack-name Esempio09dynamoApiCrud
    ```
* Comandi per avere la lista e inserire un nuovo elemento da API-REST
    ```
    curl https://jy4qo88d3d.execute-api.eu-west-1.amazonaws.com/dev
    curl -i -H "Accept: application/json" -X POST -d "{\"id\":\"4\",\"name\":\"The Hobbit\",\"genre\":\"Fantasy\"}" https://jy4qo88d3d.execute-api.eu-west-1.amazonaws.com/dev

    ```
* Comandi per la rimozione dello statck
    ```
    aws s3 rm s3://alberto-bucket-es09/INPUT/films.csv
    aws s3 ls s3://alberto-bucket-es09/
    sam delete --stack-name Esempio09dynamoApiCrud
    ```
* Problema trigger non avviato
    Se il trigger non viene avviato, bisogna controllare nel bucket S3 la configurazione su Proprietà --> Amazon EventBridge --> "attivato". Senza questa configurazione non viene eseguito il trigger senza nessun messaggio di errore. In questo template c'è il parametro
    ```
      NotificationConfiguration:
        EventBridgeConfiguration:
          EventBridgeEnabled: true
    ```

## Comandi CLI
* Documentazione [CLI](https://docs.aws.amazon.com/cli/v1/userguide/cli-services-dynamodb.html)
* Lista e dettaglio delle tabelle disponibili
  ```
  aws dynamodb list-tables 
  aws dynamodb describe-table   --table-name  alberto-dynamo-es09  
  ```
* Creare una tabella
  ```
  aws dynamodb create-table \
    --table-name  alberto-dynamo-es09b \
    --attribute-definitions AttributeName=Artist,AttributeType=S AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
  ```
* Aggiungere un elemento in una tabella
  ```
  aws dynamodb put-item --table-name alberto-dynamo-es09 --item "{\"id\":{\"S\":\"5\"},\"name\":{\"S\":\"Matrix\"},\"genre\":{\"S\":\"Tecnology\"}}"
  ```
* Eseguire una scan su tutta la tabella e formattare il risultato in formato leggibile
  ```
  aws dynamodb scan --table-name alberto-dynamo-es09 --output table --query Items[*].[id.S,name.S,genre.S]
  aws dynamodb scan --table-name alberto-dynamo-es09 --output table --query Items[*].[id.S,name.S,genre.S] --filter-expression "genre = :genre"  --expression-attribute-values  "{\":genre\":{\"S\":\"Tecnology\"} }"
  ```
* Eseguire una query in tabella su chiave primaria o query mista tra chiave primaria eunita ad espressioni
  ```
  aws dynamodb query --table-name alberto-dynamo-es09 --key-condition-expression "#gn = :genre" --expression-attribute-names "{\"#gn\": \"id\"}" --expression-attribute-values  "{\":genre\":{\"S\":\"1\"}}"
  aws dynamodb query --table-name alberto-dynamo-es09 --filter-expression "genre = :genre" --key-condition-expression "#gn = :id" --expression-attribute-names "{\"#gn\": \"id\"}" --expression-attribute-values  "{\":genre\":{\"S\":\"Tecnology\"},\":id\":{\"S\":\"5\"} }"
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it