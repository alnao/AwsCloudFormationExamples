# AWS CloudFormation Examples - 03 BucketS3 con WebSite
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Creazione di un bucket semplice bucket S3 con il nome parametrico. Esposizione di un sito web con in aggiunta un ```S3::BucketPolicy```. 

## CloudFormation
Documentazione di [CloudFormation - WebSite configuration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-websiteconfiguration.html)
```
      WebsiteConfiguration:
        IndexDocument: index.html
        ErrorDocument: error.html
```
Esempio di bucket policy:
```
  S3BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref NomeBucket
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Sid: AllowSSLRequestsOnly 
            Action: 's3:GetObject'
            Effect: Allow
            Resource: !Join
              - ''
              - - 'arn:aws:s3:::'
                - !Ref NomeBucket
                - /*
            Principal: '*'
```
* Note: 
    Creazione di una semplice bucket che espone un WebSite con le policy di S3.

    Questo si ispira al template ufficiale di esempio
    ```
    https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-policy.html
    ```


* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam deploy --stack-name Esempio03webSiteS3 --capabilities CAPABILITY_IAM
    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)

* Comando per la creazione con personalizzazione del nome del bucket
    ```
    sam deploy --stack-name Esempio03webSiteS3 --capabilities CAPABILITY_IAM --parameter-overrides NomeBucket=esempio03buckets3sito
    ```

* Comando per la scrittura di un file html nel bucket 
    ```
    aws s3 cp index.html s3://esempio03buckets3/index.html
    aws s3 ls s3://esempio03buckets3/
    curl http://esempio03buckets3.s3-website-eu-west-1.amazonaws.com/
    ```    

* Comandi per la distruzione dello stack svuoando prima il bucket
    ```
    aws s3 ls s3://esempio03buckets3/
    aws s3 rm s3://esempio03buckets3/index.html
    sam delete --stack-name Esempio03webSiteS3
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*