# AWS CloudFormation Examples - 28 CodePipeline
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Contenuto dell'esempio:
- Script `deploy_cloudformation.sh`: script sh per eseguire il rilascio del CloudFormation, questo permette di evitare di dover impostare i parametri ma li calcola con i valori di default (VPC e Subnet)
- Script `template.sh`: template CloudFormation per la definizione di tutti i componenti descritti qua sotto
- Script `create_github_secret.sh`: script sh per creare il "Parametro SSM" necessario con il token GitHub
- Script `create_infra.sh`: script sh per creare tutta l'infrastruttura (alternativa al CloudFormation)
- Script `cleanup_aws_infra.sh`: script sh per distruggere tutti gli elementi creati con lo script (alternativa al CloudFormation)


**CodeCommit** è stato deprecato da AWS quindi viene usato un repository pubblico GitHub. See [AWS Blog](https://aws.amazon.com/it/blogs/devops/how-to-migrate-your-aws-codecommit-repository-to-another-git-provider/): After careful consideration, we have made the decision to close new customer access to AWS CodeCommit, effective July 25, 2024. AWS CodeCommit existing customers can continue to use the service as normal. AWS continues to invest in security, availability, and performance improvements for AWS CodeCommit, but we do not plan to introduce new features.


## IA
I comandi per creare questi esempi sono stati: un microservizio in java spring boot "Esempio03dbDockerAWS-backend" e un mini sito ""Esempio03dbDockerAWS-frontend", eseguiti su due docker (ogni progetto ha il suo dockerfile), vorrei creare su AWS una infratuttura per un CD/CI usando cloudFormation, dammi il template completo e tutti i comandi. Per semplicità ho tolto il frontend perchè non funzionava molto.


Ecco un template CloudFormation completo e i comandi necessari. Considereremo l'utilizzo di:
- Il repository di codice è GitHub.
- AWS CodeBuild per costruire le immagini Docker e testare.
- AWS ECR (Elastic Container Registry) per archiviare le immagini Docker.
- AWS CodePipeline per orchestrare la pipeline CI/CD.
- AWS ECS (Elastic Container Service) con Fargate per eseguire i container (serverless, senza gestire EC2).
- AWS Application Load Balancer (ALB) per distribuire il traffico.
- Amazon S3 per il frontend React (se statico) o un'altra istanza ECS/Fargate se anche il frontend è servito da un'applicazione a runtime.


Architettura CI/CD
- Source Stage: Il codice viene recuperato da un repository GitHub.
- Build Stage (Backend): CodeBuild costruisce l'immagine Docker del microservizio Spring Boot, la testa, e la pusha su ECR.
- Build Stage (Frontend): CodeBuild costruisce il frontend React (produzione), lo impacchetta e lo carica su un bucket S3.
- Deploy Stage (Backend): CodePipeline aggiorna la definizione della Task ECS e il servizio ECS per deployare la nuova immagine Docker del backend.
- Deploy Stage (Frontend): CodePipeline (o S3 in questo caso) distribuisce i file statici del frontend.


Prerequisiti
- Account AWS configurato: AWS CLI installato e configurato con le credenziali appropriate. VPC e subnet di default esistenti oppure create a mano.
- Un progetto Spring Boot (Esempio03dbDockerAWS-backend) con il suo Dockerfile nella root.
- Un progetto React (Esempio03dbDockerAWS-frontend) con il suo Dockerfile (se lo deployi su ECS) o pronto per il build statico (se su S3). Per il caso di S3, assicurati che il comando npm run build o yarn build produca i file statici in una directory come build o dist.
- Repository Git: Carica il codice sorgente del backend e del frontend in un repository GitHub.


## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-eks-cluster-computeconfig.html) di EKS:
```

  CodePipeline:
    Type: AWS::CodePipeline::Pipeline
    DependsOn: EcsServiceBackend
    Properties:
      Name: !Sub ${ProjectName}-pipeline
      RoleArn: !GetAtt CodePipelineRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref CodePipelineArtifactStoreBucket
      Stages:
        - Name: Source
          Actions:
            # ONLY ONE SOURCE ACTION, pulling the entire mono-repo
            - Name: SourceMonoRepo
              ActionTypeId:
                Category: Source
                Owner: ThirdParty
                Provider: GitHub
                Version: '1'
              OutputArtifacts:
                - Name: SourceCode # This artifact will contain the entire JavaSpringBootExample repo
              Configuration:
                Owner: !Ref GitHubOwner
                Repo: !Ref RepositoryMasterName # Use the master repository name
                Branch: !Ref BranchName
                OAuthToken: !Ref GitHubToken
                PollForSourceChanges: true
              RunOrder: 1
        - Name: BuildBackend
          Actions:
            - Name: BuildBackendImage
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              InputArtifacts:
                - Name: SourceCode # Input is the entire mono-repo
              OutputArtifacts:
                - Name: BackendBuildOutput
              Configuration:
                ProjectName: !Ref CodeBuildProjectBackend
              RunOrder: 1
        - Name: DeployBackend
          Actions:
            - Name: DeployToECS
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: ECS
                Version: '1'
              InputArtifacts:
                - Name: BackendBuildOutput
              Configuration:
                ClusterName: !Ref EcsCluster
                ServiceName: !Ref EcsServiceBackend
                ImageDefinitions: BackendBuildOutput::imageDetail.json
              RunOrder: 1

      Tags:
        - Key: Project
          Value: !Ref ProjectName
```

* Comani per la creazione dello stack, vedere il file deploy.sh:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file packagedV1.yaml --stack-name Esempio28codePipelineCICD  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --parameter-overrides  VpcId=$DEFAULT_VPC Subnets="$SUBNET_LIST" GitHubToken="$GITHUB_TOKEN"
    ```
* Comandi per il rilascio sul repository ECR:
    ```
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin xxxxx.dkr.ecr.eu-central-1.amazonaws.com
    docker build -t esempio28-backend . -f Dockerfile-backend 
    docker tag esempio28-backend:latest 565949435749.dkr.ecr.eu-central-1.amazonaws.com/esempio28-backend:latest
    docker push xxxxx.dkr.ecr.eu-central-1.amazonaws.com/esempio28-backend:latest
    ````
* Comandi rimozione tutto
    ```
    sam delete --stack-name Esempio28codePipelineCICD
    ```


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


