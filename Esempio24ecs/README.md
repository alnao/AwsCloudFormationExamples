# AWS CloudFormation Examples - 24 ECS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di cluster ECS per eseguire una immagine docker salvata su ECR

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-service.html) di ECS:
  ```
  EcsService:
    Type: AWS::ECS::Service
    DependsOn: ListenerRule
    Properties:
      Cluster: !GetAtt ECS.Outputs.Cluster
      Role: !Ref ServiceRole
      DesiredCount: !Ref DesiredCount
      TaskDefinition: !Ref TaskDefinition
      LoadBalancers:
        - ContainerName: !Ref ContainerName 
          ContainerPort: 80
          TargetGroupArn: !Ref TargetGroup
  ```

* Comani per la creazione dello stack:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio24ecs  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides VpcId=vpc-0013c2751d04a7413 PublicSubnet1=subnet-051a66ef02691b734  PublicSubnet2=subnet-0b6f53c0291c13f02 PrivateSubnet1=subnet-0ca3ce54f35c3d3ef PrivateSubnet2=subnet-08dbf4b5fed6a83b2
    
    ```
    *Nota*: in questo template`--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` non sono necessari
    

* Comandi per il push di una immagine nel repository:
    ```
    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin xxxx.dkr.ecr.eu-west-1.amazonaws.com
    docker build -t esempio23-ecr-repository .
    docker tag esempio23-ecr-repository:latest xxxx.dkr.ecr.eu-west-1.amazonaws.com/esempio23-ecr-repository:latest
    docker push xxxx.dkr.ecr.eu-west-1.amazonaws.com/esempio23-ecr-repository:latest

    ```
* Usare l'esempio [03ApiPersoneNoDb](https://github.com/alnao/PythonExamples/tree/master/Docker/03ApiPersoneNoDb) 
    * Ricordarsi di impostare le porte 80 sia nel `app.py` sia nel `Dockerfile` perchè il bilanciatore usa la porta 80 e non 5001.
    * Comandi per testare i servizi
        ```
        curl -X GET http://esempio24ecs-xxx.eu-west-1.elb.amazonaws.com/persone -H "Content-Type: application/json"
        curl -X POST http://esempio24ecs-xxx.eu-west-1.elb.amazonaws.com/persone -H "Content-Type: application/json" -d ' {    "cognome": "Nao",    "nome": "Andrea"}'
        ```
* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio24ecs
    ```


## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ecs/index.html)
* Crea un nuovo cluster
    ```
    aws ecs create-cluster --cluster-name my-cluster
    ```
* Lista tutti i cluster
    ```
    aws ecs list-clusters
    aws ecs list-clusters --query clusterArns[*] --output table
    ```
* Dettaglio di un cluster specifico
    ```
    aws ecs describe-clusters --clusters Esempio24ecs
    aws ecs describe-clusters --clusters Esempio24ecs --query clusters[*] --output table
    ```
* Elimina un cluster
    ```
    aws ecs delete-cluster --cluster <nome>
    ```

* Registra una nuova task definition
    ```
    aws ecs register-task-definition --cli-input-json file://task-definition.json
    ```

* Lista tutte le task definitions
    ```
    aws ecs list-task-definitions
    aws ecs list-task-definitions --query taskDefinitionArns[*] --output table
    ```

* Descrivi una task definition specifica
    ```
    aws ecs describe-task-definition --task-definition esempio24-ecs:4
    ```

* Deregistra una task definition
    ```
    aws ecs deregister-task-definition --task-definition my-task:1
    ```

* Crea un nuovo service
    ```
    aws ecs create-service --cluster my-cluster --service-name my-service --task-definition my-task:1 --desired-count 2
    ```

* Lista tutti i servizi in un cluster
    ```
    aws ecs list-services --cluster Esempio24ecs
    aws ecs list-services --cluster Esempio24ecs --query serviceArns[*] --output table
    ```

* Descrivi un servizio specifico
    ```
    aws ecs describe-services --cluster Esempio24ecs --services Esempio24ecs-EcsService-6LS6lgUzCMkb
    ```

* Aggiorna un servizio modificando il numero di istanze 
    ```
    aws ecs update-service --cluster Esempio24ecs --service Esempio24ecs-EcsService-6LS6lgUzCMkb --desired-count 3
    ```

* Elimina un servizio
    ```
    aws ecs delete-service --cluster Esempio24ecs --service my-service
    ```
* Esegui una task
    ```
    aws ecs run-task --cluster Esempio24ecs --task-definition esempio24-ecs:4
    ```

* Lista tutti i task in esecuzione
    ```
    aws ecs list-tasks --cluster Esempio24ecs
    aws ecs list-tasks --cluster Esempio24ecs --query taskArns[*] --output table
    ```

* Descrivi task specifici
    ```
    aws ecs describe-tasks --cluster Esempio24ecs --tasks 0bc1160e46854c21870286cb7aed31c7
    ```

* Ferma un task
    ```
    aws ecs stop-task --cluster Esempio24ecs --task task-id
    ```

* Lista delle istanze di un container
    ```
    aws ecs list-container-instances --cluster Esempio24ecs
    ```

* Descrivi container instances specifiche
    ```
    aws ecs describe-container-instances --cluster Esempio24ecs --container-instances 0382ccab082241f49765c7257fcd0995
    ```

# ECS-agent
Se si usa EC2 come cluster o parte di un cluster, bisogna ricordare che nelle istanze deve essere obbligatoriamente installato un "ECS agent" e che deve esssere configurato, si rimanda alla documentazione ufficiale
```
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html
```
per tutti i dettagli, questo articolo vuole esserne solo un breve riassunto per chi usa le immagini Linux. 
Ipotizzando che il cluster si chiami es24manual-cluster (con molta fantasia), la sequenza di comandi per la installazione la configurazione dell'agente "ECS agent" :
```
$ sudo yum install -y ecs-init
$ sudo amazon-linux-extras install ecs
$ sudo systemctl enable --now ecs
$ sudo systemctl start ecs.service
$ sudo rm /var/lib/ecs/data/agent.db
$ sudo echo ECS_CLUSTER=es24manual-cluster >> /etc/ecs/ecs.config
$ sudo systemctl restart ecs
$ tail /var/log/ecs/ecs-agent.log
```
nel caso l'ultimo comandi visualizzi degli errori bisogna analizzarli e risolverli, per esempio se compare l'errore:
``` level=error time=2024-03-08T16:33:56Z msg="Unable to register as a container instance with ECS" error="AccessDeniedException:```
significa che l'agente nella istanza EC2 non ha avuto i permessi per accedere al Cluster ECS, per risolvere questo problema bisogna modificare la regola IAM della istanza EC2 aggiungendo la regola AmazonECS_FullAccess oppure la regola specifica ecs:RegisterContainerInstance. Per quanto riguarda il tipo di immagine AMI da utilizzare per i cluster di ECS, è consigliato usare il tipo ottimizzato messo a disposizione da AWS, in particolare è possibile recuperare la ami con il comando
```
$ aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id --region us-east-1 --query "Parameters[0].Value"
```
si rimanda alla pagina ufficiale per tutti i dettagli.
```
https://repost.aws/knowledge-center/launch-ecs-optimized-ami 
```


# Esempio di creazione con CLI
Per creare l'infrastruttura di esecuzione di una immagine docker è possibile usare la console web seguendo le varie guide online oppure è possibile usare la CLI eseguendo i comandi messi a disposizione dalla architettura, ovviamente i comandi devono essere eseguiti nella giusta sequenza, un esempio è:
- Creare un secutiry group per l'istanza EC2:
    ```
    $ aws ec2 create-security-group --group-name ecs-example --description "security group for ecs example" --vpc-id vpc-0013c2751d04a7413
    $ aws ec2 describe-security-groups --group-id sg-00312dc04172e66da
    $ aws ec2 authorize-security-group-ingress --group-id sg-00312dc04172e66da --protocol tcp --port 22 --cidr 0.0.0.0/0
    $ aws ec2 authorize-security-group-ingress --group-id sg-00312dc04172e66da --protocol tcp --port 80 --cidr 0.0.0.0/0
    $ aws ec2 authorize-security-group-ingress --group-id sg-00312dc04172e66da --protocol tcp --port 5432 --source-group sg-00312dc04172e66da
    $ aws ec2 describe-security-groups --group-id sg-00312dc04172e66da
    ```
- Crare un cluster docker con un nome specifico:
    ```
    $ aws ecs create-cluster --cluster-name es24manual-cluster
    $ aws ecs list-clusters --query clusterArns[*] --output table
    $ aws ecs describe-clusters --clusters es24manual-cluster
    ```
- Censire istanza EC2 nel cluster con un **ecs-angent**: seguire le istruzioni sopra descritte per collegare una istanza EC2 al cluster ECS, è possibile anche seguire la guida ufficiale ```https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html```, se tutto correttamente configurato, la istanza è disponbile nel cluster:
    ```
    $ aws ecs list-container-instances --cluster  es24manual-cluster
    $ aws ecs describe-container-instances --cluster default --container-instances container_instance_ID
    ```
- Registrare una task definition, ci sono tre opzioni:
    - definendo la definizione in file json, seguendo la [guida ufficiale](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html#AWSCLI_EC2_launch_container_instance), in questo esempio la task definition è copiata dall'esempio ufficiale ed esegue solo un comando sleep:
        ```
        {
        "containerDefinitions": [
            {
            "name": "sleep",
            "image": "busybox",
            "cpu": 10,
            "command": [
                "sleep",
                "360"
            ],
            "memory": 10,
            "essential": true
            }
        ],
        "family": "sleep360"
        }
        $ aws ecs register-task-definition --cli-input-json file://sleep.json
        $ aws ecs run-task --cluster es24manual-cluster --task-definition sleep360:1 --count 1
        ```
    - In alternativa è possible anche registrare inserendo la definizione nel comando ma è scosigliato:
        ```
        $ aws ecs register-task-definition --family sleep360 --container-definitions "[{\"name\":\"sleep\",\"image\":\"busybox\",\"cpu\":10,\"command\":[\"sleep\",\"360\"],\"memory\":10,\"essential\":true}]"
        ```
    - Se l'immagine è disponibile su ECR, nel file json di configurazione si indica la fonte compreso il mapping delle porte:
        ```
        {
            "containerDefinitions": [
                {
                    "name": "api-persone-nodb",
                    "image": "<accountId>.dkr.ecr.eu-west-1.amazonaws.com/esempio23-ecr-repository:latest",
                    "cpu": 1,
                    "memory": 300,
                    
                    "portMappings": [
                        {
                            "containerPort": 80,
                            "hostPort": 80, 
                            "protocol": "tcp" 
                        }
                    ],
                    "command": [
                        "python",
                        "/usr/src/app/app.py"
                    ],
                    "essential": true
                }
            ],
            "family": "api-persone-nodb"
        }
        $ aws ecs register-task-definition --cli-input-json file://task.json
        ```
    l'esempio completo si può trovare nel repository
        ```
        https://github.com/alnao/PythonExamples/blob/master/Docker/03ApiPersoneNoDb/taskECS.json
        ```
- Avvio del task, specificando che il nome del "task definition" corrisponde al valore "family" indicato nel json di definizione:
    ```
    $ aws ecs list-task-definitions
    $ aws ecs run-task --cluster es24manual-cluster --task-definition api-persone-nodb:4 --count 1
    $ aws ecs list-tasks --cluster es24manual-cluster 
    $ aws ecs describe-tasks --cluster  es24manual-cluster  --task xxxxx
    ```
- Avviato il tag si può provare ad accedere direttamente usando l'ip dell'istanza (se pubblica)
    ```
    $ curl -X GET http://ec2-18-202-233-240.eu-west-1.compute.amazonaws.com/persone -H "Content-Type: application/json"
    $ curl -X POST http://ec2-18-202-233-240.eu-west-1.compute.amazonaws.com/persone -H "Content-Type: application/json" -d '{"cognome": "Nao","nome": "Andrea"}'
    ```
- Creazione di un Security group per l'accesso al ALB
    ```
    $ aws ec2 create-security-group --group-name es24manual-sg --description "Security group for ECS with ALB" --vpc-id vpc-xxxx
    $ aws ec2 authorize-security-group-ingress --group-id sg-0ff15c5ac09e5ab46 --protocol tcp --port 80 --cidr 0.0.0.0/0
    ```
- Creazione di ALB e configurazione di un ECS-service, nota: in questa sequenza sostituire tutti gli xxxx con i nomi e arn di risorse esistenti:
    ```
    $ aws elbv2 create-load-balancer --name es24manual-alb --subnets subnet-xxxx subnet-xxxx --security-groups sg-0ff15c5ac09e5ab46  --scheme internet-facing --type application
    
    $ aws elbv2 create-target-group --name es24manual-tg --protocol HTTP --port 80 --vpc-id vpc-xxxx --target-type instance --health-check-path /persone

    $ aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:eu-west-1:xxxx:loadbalancer/app/es24manual-alb/xxxx --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:xxxx:targetgroup/es24manual-tg/xxxx

    $ aws ecs create-service --cluster es24manual-cluster --service-name es24manual-service --task-definition api-persone-nodb:4 --desired-count 1 --launch-type EC2 --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:xxxx:targetgroup/es24manual-tg/xxxx,containerName=api-persone-nodb,containerPort=80 --scheduling-strategy REPLICA --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" --health-check-grace-period-seconds 30

    $ aws ecs update-service --cluster es24manual-cluster --service es24manual-service --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:xxxx:targetgroup/es24manual-tg/xxxx,containerName=api-persone-nodb,containerPort=80 --health-check-grace-period-seconds 30
    
    $ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:xxxx:targetgroup/es24manual-tg/xxxx     --targets Id=i-xxxx

    $ curl -X GET http://es24manual-alb-xxxx.eu-west-1.elb.amazonaws.com/persone -H "Content-Type: application/json"

    $ aws ecs update-service --cluster es24manual-cluster  --service es24manual-service --force-new-deployment

    $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:xxxx:targetgroup/es24manual-tg/xxxx
    ```

- Per tutti i dettagli si rimanda alla guida completa nella [guida completa del sito ufficiale](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html). Inoltre in fase di creazione del ALB:
    - Il security group dell'ALB deve permettere il traffico in ingresso sulla porta 80
    - Il security group dell'EC2 deve permettere il traffico in ingresso dal security group dell'ALB
    - Le subnet selezionate devono essere pubbliche se l'ALB è pubblico
    - Il VPC deve avere un Internet Gateway funzionante se l'ALB è pubblico

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


