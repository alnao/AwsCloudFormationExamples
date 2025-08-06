# AWS CloudFormation Examples - 04 Distribuzione CloudFront
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Creazione di una distribuzione CloudFront con un sito su S3.

## CloudFormation
Documentazione di [CloudFront](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudfront-distribution.html)
```
  "Type" : "AWS::CloudFront::Distribution",
```
* Comandi per la creazione:
    ```
    sam validate --lint
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file packagedV1.yaml --stack-name Esempio04cloudFront
    ```
* Comandi per il carico della pagina con invalidazione della distribuzione con aggiornamento della cache
    ```
    aws s3 cp index.html s3://alberto-es04-sito/
    aws s3 ls s3://alberto-es04-sito/
    ```
* Comandi per il carico della pagina con invalidazione della distribuzione con aggiornamento della cache
    ```
    aws cloudfront create-invalidation --distribution-id E14O91R4KXQZLB --paths "/*"
    ```
* Comandi per la rimozione dello stack
    ```
    aws s3 rm s3://alberto-es04-sito/index.html
    aws s3 ls s3://alberto-es04-sito/
    sam delete --stack-name Esempio04cloudFront
    ```

## Comandi CLI
* Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudfront/index.html)
* Lista delle distribuzioni
  ```
  aws cloudfront list-distributions
  aws cloudfront list-distributions --query "DistributionList.Items[*].[Id, DomainName, Origins.Items[0].DomainName]" --output table
  ```
* Creare e distruggere una distribuazione
  ```
  aws cloudfront create-distribution --distribution-config <value>
  aws cloudfront update-distribution[--distribution-config <value>] --id <value>
  aws cloudfront delete-distribution --id <value>
  ```
* Dettaglio di una distribuzione
  ```
  aws cloudfront get-distribution --id E14O91R4KXQZLB
  ```
* Invalidazione di una distribuzione 
  ```
  aws cloudfront create-invalidation --distribution-id E14O91R4KXQZLB --paths "/*"
  ```


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*