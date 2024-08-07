
# AWS CloudFormation Examples - 01 BucketS3
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

## CloudFormation
* Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) di Bucket-S3:
  ```
  S3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: !Ref NomeBucket
  ```
* Se si vuole usare il servizio S3 assieme ad EventBridge per catturare gli eventi, bisogna controllare nel bucket S3 la configurazione su Proprietà --> Amazon EventBridge. Senza questa configurazione non vengono eseguiti i trigger di EventBridge senza nessun messaggio di errore. E' possibile aggiungere la proprietà specifica nei template di CloudFormation:
    ```
      NotificationConfiguration:
        EventBridgeConfiguration:
          EventBridgeEnabled: true
    ```
* Comandi per la creazione dello stack
  ```
  sam validate
  sam build
  sam deploy --stack-name Esempio01bucketS3 --capabilities CAPABILITY_IAM
  ```
  nota: --capabilities CAPABILITY_IAM è obbligatorio per le regole IAM
* Comandi per la creazione con nome specifico
  ```
  sam deploy --stack-name Esempio01bucketS3 --capabilities CAPABILITY_IAM --parameter-overrides NomeBucket=bucket-specific-name
  ```
* Comandi per verifica del bucket
  ```
  aws s3 ls 
  aws s3 ls bucket-specific-name
  aws cloudformation list-stack-resources --stack-name Esempio01bucketS3 --output text
  ```
* Comando per la rimozione dello stack
  ```
  sam delete --stack-name Esempio01bucketS3
  ```


## Comandi CLI
* Riferimento documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/cp.html) o utilizzare il comando `aws s3 help` per ottenere informazioni dettagliate su ogni comando.
* Creare e distruggere un bucket
  ```
  aws s3 mb s3://bucket-name
  aws s3 ls
  aws s3 rb s3://bucket-name
  ```
* Gestire gli oggetti contenuti in un bucket (copiare e spostare oggetti dal sistema corrente)
  ```
  aws s3 ls bucket-name
  aws s3 mv s3://bucket-name/example.txt s3://bucket-name2/
  aws s3 mv s3://bucket-name/filename.txt ./
  aws s3 cp s3://bucket-name/example.txt s3://my-bucket/
  ```
* Sincronizzare una cartella locale ad un bucket
  ```
  aws s3 sync . s3://my-bucket/path
  ```
* Svuotare un bucket da tutti gli elementi. *Prestare attenzione perchè potrebbe essere pericoloso*
  ```
  aws s3 rm s3://my-bucket/path --recursive
  ```
* Comandi evoluti del comando s3Api per modificare la policy e per abilitare il versioning in un bucket
  ```
  aws s3api put-bucket-policy --bucket nome-del-bucket --policy file://policy.json
  aws s3api put-bucket-versioning --bucket nome-del-bucket --versioning-configuration Status=Enabled
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*