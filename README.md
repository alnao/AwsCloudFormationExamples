# AWS CloudFormation Examples by AlNao

<p align="center">
    <img src="https://img.shields.io/badge/AWS-%23FF9900?style=plastic&logo=AmazonAWS&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/Ec2-%23FF9900?style=plastic&logo=amazon-ec2&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/Lambda-%23FF9900?style=plastic&logo=AWSlambda&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/S3-%23569A31?style=plastic&logo=amazon-s3&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/RDS-%23527FFF?style=plastic&logo=amazon-rds&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/DynamoDB-%23527FFF?style=plastic&logo=amazon-DynamoDB&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/CloudWatch-%23FF4F8B?style=plastic&logo=amazon-cloudwatch&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/API Gateway-%23FF4F8B?style=plastic&logo=amazon-API-Gateway&logoColor=black" style="height:28px;" />
    <img src="https://img.shields.io/badge/SQS-%23FF4F8B?style=plastic&logo=amazon-sqs&logoColor=black" style="height:28px;" />
</p>

AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

# Prerequisiti
- Un account AWS attivo
- La **AWS-CLI** installata, [documentazione ufficiale](https://docs.aws.amazon.com/it_it/cli/v1/userguide/cli-chap-install.html) con una utenza tecnica di tipo programmatico configurata su IAM con permessi di esecuzione di CloudFormation e configurazione della AWS-CLI con il comando
  - ```aws configuration```
  - è possibile anche configurare un profilo con la AWS-CLI con la sequenza di comandi
    ```
    aws configure set --profile nome_profilo aws_access_key_id xxxxxx
    aws configure set --profile nome_profilo aws_secret_access_key xxxxxx
    aws configure set --profile nome_profilo region eu-west-1
    aws configure set --profile nome_profilo output json
    ```
- La **AWS-CLI-SAM** installata correttamente, [documentazione ufficiale](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Per ogni template, se non indicato diversamente, i comandi da eseguire per eseguire il deploy sono:
  - ```sam validate```
  - ```sam build```
  - ```sam deploy --template-file .\packagedV1.yaml --stack-name <esempio00name> --capabilities CAPABILITY_IAM```
- Se si tratta di template con più files è indispensabile eseguire il comando di package tra i comandi di build e deploy:
  - ```sam package --output-template-file <packagedV1.yaml> --s3-prefix <repository-path> --s3-bucket <bucket-name>```
- Se nei template sono presenti regole IAM vedere sezione "Capabilities"

# Lista esempi
- 01 **Bucket S3**: creazione e gestione di un bucket S3
- 02 **Istanze EC2**: istanza EC2 con un web-server (compresi user-data, security group, VPC & subnet), esempio anche con cfn-helper-scripts e SSM parameter store
- 03 **WebSite con S3**: bucket S3 pubblicamente accessibile con un hosted-website (senza CloudFront)
- 04 **WebSite con CloudFront**: distribuzione CloudFront che espone un sito statico salavto in un bucket S3
- 05 **Lambda**: lambda in Python avviato da una "notifica" da un bucket S3 (senza EventBridge) 
  - nota: *questo esempio non segue le best-practices perchè la lambda è inline dentro al template e non in files dedicati, vedere successivi esempi per lambda in files separati*
- 06 **EventBridge**: due regole EventBridge (un trigger & una regola cron) per l'invocazioni di Lambda Function in python
- 07 **Step Function**: definizione di una step function, invocata da un EventBridge-Lambda
  - la macchina a stati esegue i passi: copia un file da S3 a S3, cancellazione del file originale e esecuzione di una lambda function
- 08 **ApiGateway**: definizione di una API di tipo Rest (HTTP-GET) che invoca una lambda *con codice inline*
  - in questo esempio per la definizione delle API viene usato il tipo ```AWS::ApiGateway::RestApi```
- 09 **Dynamo**: tabella dynamo con API per scrivere e leggere nella tabella (Api Gateway e Lambda function)
- 10 **Lambda Authorizer**: esempio tabella dynamo, CRUD in Lambda Function con in aggiunta una Lambda Authorizer per Api Gateway
- 11 **RDS**: creazione di un database MySql e un database Aurora con un SecurityGroup dedicato per le regole di accesso
- 12 **Application S3-Utils**: mini-applicazione che permette di caricare un file excel in un database RDS
  - database RDS come base dati
  - bucket S3 come storage dei files
  - lambda di estrazione ZIP, conversione da excel a csv e caricamento dati nel database
  - api gateway per recupero dati dal databse e caricamento file nel bucket tramite **presigned url** di tipo PUT
  - tabella Dynamo per la gestione dei log di caricamenti
- 13 **Job Glue**: definizione Job ETL Glue e una step function che esegue logiche per l'invocazione del Job
- 14 **Job ClawlerRDS**: definizione di Glue database, Glue table, Glue crawler, Glue job e Gluetrigger con step function l'per l'invocazione del Workflow Glue con database RDS destinazione finale dei dati
- 15 **SQS**: definizione di una coda SQS e due API-Lambda come producer e consumer
- 16 **SNS**: definizione di un topic SNS invocato da una StepFunction, messaggi inviati dia mail e ad una coda SQS verso una lambda function
- 17 **Elastic IP**: definizione di un indirizzo IP con Elastic IP assegnato ad una EC2 creata con l'esempio 02
- 18 **EFS**: un file system EFS montato da una istanza EC2 in automatico nel user-data
- 19 **Wordpress**: template che crea un RDS MySql e una EC2, nella EC2 viene installato in automatico un Wordpress
- 20 **LoadBalancer**: template che crea un bilanciatere con solo una istanza EC2 che esegue un Wordpress senza usare RDS e senza EFS
- 21 **AutoScaling**: template che crea un ApplicationLoadBalancer e un AutoScalingGroup con istanze che caricano RDS e EFS, in questa configurazione è possibile installare Wordpress in esecuzioni su più istanze
- 22 **CloudWatch Alarm**: template che crea degli allarmi per scalare l'autoscaling gruop dell'esempio precedente
- 23 **ECR**: template che crea un ECR Elastic Container Registry, base per i successivi templates
- 24 **ECS**: template che crea un ECS e avvia un servizio contenuto in una immagine docker come task con ALB che espone il servizio pubblicamente
- 25 **VPC & Client Vpn Endpoint**: template che crea una VPC usando un template AWS ufficiale e un Client-Vpn-Endpoint
- 26 **Blockchain**: template che crea usa Lambda e Dynamo per creare una piccola blockchain con algormitmo *proof of work* con difficoltà molto bassa
- 27 **EKS**: template che crea un cluster e un nodo EKR con l'esecuzione di un microservizio java che si collega ad un database Mysql-RDS
- 28 **CodePipeline**: template che crea una PipeLine di deploy CICD usando GitHub e docker (ECR & ECS): *non funziona molto bene ma non riesco a capire perchè la PipeLine rimane appesa in CREATE_IN_PROGRESS*
- 99: template e file vari *abbandonati a se stessi*

# Note su CloudFormation & YAML
Facendo riferimento alla [documentazione ufficiale](https://docs.aws.amazon.com/cloudformation/), CloudFormation è un servizio **Iaac** dichiarativo in YAML (è possibile usare anche JSON *ma meglio non usarlo*). La base della sintassi di CloudFormation in YAML può essere riassunta in questi punti:
* **Template di partenza** con le tre sezioni principali (parametri, risorse e output) ma solo risorse è veramente obbligatorio
  ```
  AWSTemplateFormatVersion: 2010-09-09
  Description: AWS CloudFormation Examples by AlNao - 01 BucketS3
  # questa è una riga di commento, nota: AWSTemplateFormatVersion e Description sono obbligatori
  # see documentation https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html

  # blocco Parametri
  Parameters:
    NomeBucket:
      Type: String
      Default: esempio01-bucket-s3
      Description: Nome del bucket
      MinLength: 9
  # blocco Risorse, questo è l'unico blocco obbligatorio
  Resources:
    S3Bucket:
      Type: 'AWS::S3::Bucket'
      Properties:
        BucketName: !Ref NomeBucket
  # blocco Outputs
  Outputs:
    S3Bucket:
      Value: !GetAtt S3Bucket.Arn
      Description: S3 bucket ARN

  ```
* **Capabilities** vedere la [documentazione](https://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html) e sito
[knowledge-center](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error):
  - ```CAPABILITY_IAM``` & ```CAPABILITY_NAMED_IAM``` Some stack templates might include resources that can affect permissions in your AWS account; for example, by creating new AWS Identity and Access Management (IAM) users. For those stacks, you must explicitly acknowledge this by specifying one of these capabilities. The following IAM resources require you to specify either the CAPABILITY_IAM or CAPABILITY_NAMED_IAM capability.
    - If you have IAM resources, you can specify either capability.
    - If you have IAM resources with custom names, you must specify CAPABILITY_NAMED_IAM.
    - If you don't specify either of these capabilities, AWS CloudFormation returns an InsufficientCapabilities error.
  - ```CAPABILITY_AUTO_EXPAND``` If you want to create a stack from a stack template that contains macros and/or nested stacks, you must create the stack directly from the template using this capability.
  - In console warning/note: "following resources require capabilities AWS::IAM::Role" and check to confirm.
	
* **Psedo-parametri** vedere la [documentazione](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) :
	- AWS::AccountId
	- AWS::Region
	- AWS::StackId
	- AWS::StackName
	- AWS::NotificationARNs
	- AWS::NoValue
  Esempio di utilizzo:
  ```
  ...
      Resource: !Sub "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:db:${RDSDatabase}"
  ...
      Tags:
        -
          Key: StackId
          Value: !Ref AWS::StackId
  ...
  StackName:
    Description: Deployed StackName for update
    Value: !Ref AWS::StackName
  ```
* **Mapping** necessita di una sezione dedicata oltre a le tre nell'esempio sopra (*fixed variables in template*) 
  ```
  Mappings:
    EnvInstance:
      dev:
        EC2Type: t2.micro
      prod:
        EC2Type: t2.small
  ...
      InstanceType: !FindInMap [EnvInstance, !Ref 'EnvName', EC2Type]
  ```
  vedere esempio 05 per un template completo.
* **Conditions** definire logiche all'interno di template, sezione dedicata:
  ```
  Conditions:
    CreateVolume: !Equals [!Ref EnvName, prod]
  ...
  Resources:
    MountPoint:
      Type: AWS::EC2::VolumeAttachment
      Condition: CreateProd
  ```
  vedere esempio 02 per un template completo con la creazione di un EBS condizionato da un parametro.
* **Intrinsic Functions** vedere la [documentazione](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html):
	- !Ref: get a refefence to parametar or resources (ID):
      ```
      Parameters:
        NomeBucket:
        Type: String
        Default: esempio01-bucket-s3
      Resources:
        S3Bucket:
        Type: 'AWS::S3::Bucket'
        Properties:
          BucketName: !Ref NomeBucket
      ```
	- Fn::GetAtt (get AZ of an EC2 instance):
      ```
      Outputs:
        WebsiteURL:
        Value: !GetAtt S3Bucket.WebsiteURL
        Description: URL for website hosted on S3
      ```
	- Fn::FindInMap
	- Fn::ImportValue: import valules that are expored in other stack
	- Fn::Base64: convert string to base64 rappresentation, example to pass encoded data to EC2 user-data property:
      ```
      UserData: !Base64
        Fn::Join:
        - ''
        - - |
      ```
	- Fn::Join
      ```
      UserData: !Base64 
        'Fn::Join':
          - ''
          - - |
              #!/bin/bash -xe
            - |  #nota non serve il sudo per questo, non so il motivo
              yum update -y aws-cfn-bootstrap
            - |+ # nota: non cancellare questa riga vuota che serve per andare a capo nel user-data

            - 'sudo /opt/aws/bin/cfn-init -v '
            - '         --stack '
            - !Ref 'AWS::StackName'
            - '         --resource LaunchConfig ' #nota: corretto che qua sia LaunchConfig e non WebServerGroup
            - '         --configsets wordpress_install '
            - '         --region '
            - !Ref 'AWS::Region'
            - |+ #nota: la riga successiva deve essere vuota per formato yaml corretto

            - |
              sudo yum install -y amazon-efs-utils
              sudo mkdir /mnt/efs
              sudo chmod 777 /mnt/efs 
            - 'sudo mount -t efs -o tls '
            - !Ref EFSFileSystemId
            - ':/ /mnt/efs '
            - |+ # nota: non cancellare questa riga vuota che serve per andare a capo nel user-data


      ```
	- Fn::Sub
	- Fn::ForEach
	- Fn::ToJsonString
	- Fn::If, Fn::Not, Fn::Equals ... 
	- others 

* **SSM Parameter store** Vedere la [documentazione ufficiale](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) del servizio e la [documentazione di cloud formation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html) per lo sviluppo in template di un parametro:
  ```
  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: /nao/prova
      Type: String
      Value: date
      Description: SSM Parameter for running date command.
      AllowedPattern: "^[a-zA-Z]{1,10}$"
      Tags:
        Environment: DEV
  ```
  Comando CLI per creare o modificare un parametro:
  ```
  aws ssm put-parameter --overwrite --profile default --name "/nao/envName" --type String --value "dev"
  ```
  Template per recuperare il valore:
  ```
  Parameters:
    EnvName:
      Type: AWS::SSM::Parameter::Value<String>
      Default: /nao/envName
  ...
    Proprieta=!Ref EnvName
  ```


# Panoramic script
Script `aws_panoramic.bash` creato con l'IA:
- fammi un nuovo script che mi crea variabili d'ambiente con le informazioni: vpc di default, subnets e igw, natg, tutti i security group, tutte le role iam non di default, tutti gli ECR, tutti eks cluster, tutti gli eks nodes, tutte le ec2, tutti gli RDS,
- facciamo così: fammi un nuovo script che mi crea variabili d'ambiente con le informazioni: vpc di default, subnets e igw, natg, tutti i security group, tutti gli ECR, tutti eks cluster, tutti gli eks nodes, tutte le ec2, tutti gli RDS,
- nello script aggiungi S3, cloudfront, cloudformation, cloudwatch e altri 5 servizi a tua scelta
- dammi il codice della funzione print_section_header
To run:
```
source aws_panoramic.bash
```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*