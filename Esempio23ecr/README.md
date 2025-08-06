# AWS CloudFormation Examples - 23 ECR
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di un repository con AWS Elastic Container Registry

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecr-repository.html) di ECR:
  ```
  EcrRepo:
    Type: AWS::ECR::Repository
    Properties: 
      RepositoryName: !Sub ${RepoName}-repository
      ImageScanningConfiguration: 
        ScanOnPush: true
  ```

* Comani per la creazione dello stack:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio23ecr
    
    ```
    *Nota*: in questo template`--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` non sono necessari
    
* Comandi per il push di una immagine nel repository:
    ```
    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin xxx.dkr.ecr.eu-west-1.amazonaws.com
    docker build -t esempio23-ecr-repository .
    docker tag esempio23-ecr-repository:latest xxx.dkr.ecr.eu-west-1.amazonaws.com/esempio23-ecr-repository:latest
    docker push xxx.dkr.ecr.eu-west-1.amazonaws.com/esempio23-ecr-repository:latest

    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/index.html)
* Autenticazione al registry ECR
    ```
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
    ```
* Creazione di un repository
    ```
    aws ecr create-repository --repository-name <nome-repo> --region <region>
    ```
* Elenco dei repository
    ```
    aws ecr describe-repositories
    aws ecr describe-repositories  --query repositories[*].[repositoryName] --output table
    ```
* Elenco delle immagini in un repository
    ```
    aws ecr list-images --repository-name esempio23-ecr-repository
    aws ecr list-images --repository-name esempio23-ecr-repository  --query imageIds[*].[imageTag,imageDigest] --output table
    ```

* Tag di un'immagine locale per ECR
    ```
    docker tag <image>:<tag> <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<nome-repo>:<tag>
    ```
* Push di un'immagine su ECR
    ```
    docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<nome-repo>:<tag>
    ```
* Pull di un'immagine da ECR
    ```
    docker pull <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<nome-repo>:<tag>
    ```
* Eliminazione di un'immagine
    ```
    aws ecr batch-delete-image --repository-name <nome-repo> --image-ids imageTag=<tag>
    ```
* Eliminazione di un repository
    ```
    aws ecr delete-repository --repository-name <nome-repo> --force
    ```
* Ottenere informazioni dettagliate su un'immagine
    ```
    aws ecr describe-images --repository-name <nome-repo> --image-ids imageTag=<tag>
    aws ecr describe-images --repository-name esempio23-ecr-repository --image-ids imageTag=latest
    aws ecr describe-images --repository-name esempio23-ecr-repository --image-ids imageTag=latest  --query imageDetails[*].[repositoryName,imagePushedAt,artifactMediaType] --output table
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


