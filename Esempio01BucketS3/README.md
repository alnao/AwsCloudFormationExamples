
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
* Comandi per la creazione dello stack
  ```
  sam validate
  sam build
  sam deploy --stack-name aws01-bucket-s3 --capabilities CAPABILITY_IAM
  ```
  nota: --capabilities CAPABILITY_IAM è obbligatorio per le regole IAM
* Comandi per la creazione con nome specifico
  ```
  sam deploy --stack-name aws01-bucket-s3 --capabilities CAPABILITY_IAM --parameter-overrides NomeBucket=bucket-specific-name
  ```
* Comandi per verifica del bucket
  ```
  aws s3 ls 
  aws s3 ls esempio01-bucket-s3
  aws cloudformation list-stack-resources --stack-name aws01-bucket-s3 --output text
  ```
* Comando per la rimozione dello stack
  ```
  sam delete --stack-name aws01-bucket-s3
  ```

## Comandi CLI
* Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/cp.html)
* Creare e distruggere un bucket
  ```
  aws s3 mb s3://bucket-name
  aws s3 ls
  aws s3 rb s3://bucket-name
  ```
* Gestire gli oggetti contenuti in un bucket
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
* Svuotare un bucket
  ```
  aws s3 rm s3://my-bucket/path --recursive
  ```


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*