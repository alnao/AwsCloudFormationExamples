# AWS CloudFormation Examples - 10 Lambda Authorizer
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Componenti di questo template:
- tabella DynamoDB dove saranno salvati i dati
- bucket di appoggio dove caricare il file con i dati da caricare
- trigger sul bucket per lanciare la lambda
- lambda che segue caricamento dei dati contenuti nel csv in tabella dynamoDB
- regola IAM per permettere alla lambda di accedere a S3 e scrivere nella tabella Dynamo
- rest API con metodo get per avere l'elenco completo (scan della dynamo)
- rest API con metodo post per salvare un elemento (post/put)
- rest API con metodo delete per cancellare un elemento
- regola IAM per permetetere alle lambda API di scrivere nella tabella Dynamo
- API Gateway di AWS per l'esposizione delle API
- *Lambda Authorizer*: lambda che esegue la verifica di un token JWT
    - configurazione del API Gateway per invocare la LambdaAuth ogni chiamata della lambda
- API Gateway di AWS per l'esposizione di una API specifica per la fase di login
- lambda per la gestione della login con la creazione di un token JWT valido
notare che cancellando il tempalte si cancella anche la tabella DynamoDB e tutto il contenuto.

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-property-api-apiauth.html) di sam-property-api-apiauth:
  ```
  ApiGateway:
    Type: AWS::Serverless::Api
    Properties:
      ...
      Auth:
        DefaultAuthorizer: MyLambdaRequestAuthorizer
        AddApiKeyRequiredToCorsPreflight : false
        AddDefaultAuthorizerToCorsPreflight: false
        Authorizers:
          MyLambdaRequestAuthorizer:
            Type: TOKEN 
            #FunctionPayloadType: REQUEST #alternativa al Type: TOKEN , vedere codice della lambda auth
            FunctionArn: !GetAtt LambdaAuthorizer.Arn
            Identity:
              Headers:
                - Authorization
  ```
* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file packagedV1.yaml --stack-name Esempio10lambdaAuthorizer --capabilities CAPABILITY_IAM --parameter-overrides PasswordParam=S3cret!

    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)
* Verifica template e componenti
    ```
    aws cloudformation list-stack-resources --stack-name Esempio10lambdaAuthorizer --output text
    ```
* Comando caricamento file csv
    ```
    aws s3 cp ./lista.csv s3://es10-lambda-auth/INPUT/lista.csv
    sam logs --stack-name Esempio10lambdaAuthorizer
    aws dynamodb scan --table-name dynamo-es10 --output table --query Items[*].[id.S,name.S,genre.S]
    ```
* Comandi per test della API
    Esempio senze e con token JWT, il token può essere creato in qualunque sito [jwtbuilder](http://jwtbuilder.jamiekurtz.com/), *prestare attenzione che il token jwt che deve essere valido con la signature corretta*
    ```
    curl https://oi3j4nqzr3.execute-api.eu-west-1.amazonaws.com/dev 

    curl -H "Authorization: <TOKEN>" https://oi3j4nqzr3.execute-api.eu-west-1.amazonaws.com/dev 
    ```
* Comandi per la rimozione dello stack
    ```
    aws s3 rm s3://es10-lambda-auth/INPUT/lista.csv
    aws s3 ls s3://es10-lambda-auth/
    sam delete --stack-name Esempio10lambdaAuthorizer
    ```
* Problema trigger non avviato
    Se il trigger non viene avviato, bisogna controllare nel bucket S3 la configurazione su Proprietà --> Amazon EventBridge --> "attivato". Senza questa configurazione non viene eseguito il trigger senza nessun messaggio di errore.

## Comandi CLI
* Documentazione [API Gateway](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/apigateway/index.html)
* Creazione di un authorizer:
    ```
    aws apigateway create-authorizer --rest-api-id <api-id> --name <authorizer-name> --type TOKEN --authorizer-uri <lambda-invoke-arn> --identity-source 'method.request.header.Authorization'
    ```
*  Ottenere informazioni su un authorizer esistente:
    ```
    aws apigateway get-authorizer --rest-api-id <api-id> --authorizer-id <authorizer-id>
    ```
* Aggiornare un authorizer esistente:
    ```
    aws apigateway update-authorizer --rest-api-id <api-id> --authorizer-id <authorizer-id> --patch-operations op='replace',path='/authorizerUri',value='<new-lambda-invoke-arn>'
    ```
* Eliminare un authorizer:
    ```
    aws apigateway delete-authorizer --rest-api-id <api-id> --authorizer-id <authorizer-id>
    ```
* Elencare tutti gli authorizer per una determinata API:
    ```
    aws apigateway get-authorizers --rest-api-id <api-id>
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it