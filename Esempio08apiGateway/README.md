# AWS CloudFormation Examples by AlNao - 08 ApiGateway
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Esempio di template CloudFormation per creare una API di tipo Rest che invoca una lambda function che ritorna una costante.

In questo esempio viene usato il tipo nativo:
```
Type: AWS::ApiGateway::RestApi
```
in successivi esempi verrà usato il tipo "serverless":
```
Type: AWS::Serverless::Api
```

## CloudFormation
Documentazione di [API Gateway function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-restapi.html). Oggetti creati di tipo
```
  ApiGatewayResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      ParentId: !GetAtt ApiGatewayRestApi.RootResourceId
      PathPart: 'lambda'
      RestApiId: !Ref ApiGatewayRestApi
  ApiGatewayMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      ...
  ApiGatewayModel:
    Type: AWS::ApiGateway::Model
    Properties:
      ...
  ApiGatewayStage:
    Type: AWS::ApiGateway::Stage
    Properties:
      ...
  ApiGatewayDeployment:
    Type: AWS::ApiGateway::Deployment
    DependsOn: ApiGatewayMethod
    Properties:
      ...
```
Il tipo serverless è definito con un tipo specifico che si aggancia in automatico alle lambda function:
```
  ApiGateway:
    Type: AWS::Serverless::Api
    Properties:
      StageName: !Ref Stage
      Cors:
        AllowMethods: "'GET,POST,PUT,DELETE,OPTIONS'"
        AllowHeaders: "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        AllowOrigin: "'*'"
        MaxAge: "'600'"
      OpenApiVersion: 3.0.2
      CacheClusterEnabled: false
      CacheClusterSize: '0.5'
  ...
  LambdaGetMethod:
    Type: AWS::Serverless::Function
    Properties:
      ...
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /getMethod
            Method: GET
            RestApiId: !Ref ApiGateway
```

* Comandi per la creazione dell'esempio
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio08apiGateway --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)
* Comando caricamento file di prova e verifica esecuzione lambda
    ```
    curl https://XXXXXXXX.execute-api.eu-west-1.amazonaws.com/dev/lambda 
    aws logs filter-log-events --log-group-name /aws/lambda/lambda-es08-apigaway
    ```

* Comandi per la distruzione dello stack
    ```
    sam delete --stack-name Esempio08apiGateway
    ```


## Comandi CLI
* Documentazione [API Gateway](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/apigateway/index.html)
* Elenco di tutte le API
  ```
  aws apigateway get-rest-apis
  aws apigateway get-rest-apis --query items[].name --output table
  aws apigateway get-rest-apis --query items[].[id,name] --output table
  ```
* Dettaglio di una API con elenco deployments,resources e methods:
  ```
  aws apigateway get-deployments --rest-api-id j4mcalp3ne
  aws apigateway get-deployments --rest-api-id j4mcalp3ne --query items[].[id,description] --output table
  aws apigateway get-deployment --rest-api-id j4mcalp3ne --deployment-id fhf91x
  aws apigateway get-resources --rest-api-id j4mcalp3ne
  aws apigateway get-resources --rest-api-id j4mcalp3ne --query items[].[id,path] --output table
  aws apigateway get-resource --rest-api-id j4mcalp3ne --resource-id 13p7e1
  aws apigateway get-method --rest-api-id j4mcalp3ne --resource-id 13p7e1 --http-method GET
  aws apigateway get-method --rest-api-id j4mcalp3ne --resource-id 13p7e1 --http-method GET --query [httpMethod,operationName] --output table
  ```

## Configurazione API private con VPC-EndPoint
Di default l'API gateway è esposto in internet con end-point nel formato
```
https://XXXXXXXX.execute-api.eu-west-1.amazonaws.com/<STAGE>/<metodo>
```
E' possibile configurare via ConsoleWeb (e forse via CloudFormation) il servizio API Gateway in modo tale che l'endpoint sia in rete privata ed esposto solo tramite VPC-EndPoint:
- nel dettaglio della API, premendo il bottone "Edit", bisogna selezionare il "API endpoint type"="Private" e bisogna inserire il vpc-endpoint nel formato `vpc-xxxxx`, ricordarsi di usare il bottone "Add" altrimenti non salva la configurazione
- nel dettaglio della API, nella vista "recource policy" bisogna aggiungere il blocco che permette al VPC-endpoint di invocare chiamare la API:
  ```
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:eu-west-1:<ID-ACCOUNT>:<ID-API>/*/*/*"
      }
    ]
  }
  ```
- abilitare il CORS, nel dettaglio della risorsa (non dello stage), elezionare il metodo e usare il bottone "Enable CORS", selezionare la voce "Options" e salvare
- eseguire il deploy della risorsa selezionando lo stage corretto


Così facendo l'endpoint diventa del tipo:
```
https://<ID-APIGATEWAY>-<VPC-ENDPOINT>.execute-api.eu-west-1.amazonaws.com/<STAGE>/<metodo>
```
inoltre, bisogna ricordarsi che il DNS locale può metterci anche mezz'ora ad aggiornarsi.
 

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*