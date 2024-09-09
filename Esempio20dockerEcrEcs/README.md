# Articolo da rivedere

27 AWS ECS Come avvisare un singolo docker con ECS
ECS (Elastic Container Service) è il servizio di AWS per l'esecuzione e la gestione di applicazioni in contenitori Docker. Si integra con tutti gli altri servizi AWS per fornire una soluzione facile da usare per l'esecuzione di carichi di lavoro di container nel cloud e on-premise con funzionalità di sicurezza avanzate.
Il servizio si basa sul contetto di 
- cluster: la configurazione dell'infrastruttura dove eseguire i contanier (EC2 o Fargate)
- task definition: la configurazione dell'immagine del container (immagine Docker)
- service: la configurazione di avvio dei task e il suo relativo cluster di esecuzione
- task: esecuzione di una immagine docker all'interno di un service

Non sono previsti costi aggiuntivi per l'utilizzo di Amazon ECS. I prezzi sono calcolati in base alle risorse AWS (ad esempio istanze Amazon EC2 o volumi Amazon EBS) che vengono create per archiviare ed eseguire l'applicazione. I prezzi sono calcolati solo in base all'uso effettivo, senza tariffe minime né impegni anticipati. Per ogni informazione e dettaglio si rimanda alla pagina ufficiale del servizio ECS
```
https://aws.amazon.com/it/ecs/
```
e si rimanda alla documentazione ufficiale di Docker per ogni dettaglio riguardo alla creazione e alla gestione dei contenitori e delle immagini create con la tecnica docker. In questo articolo sono descritti i passi per l'esecuzione di una singola istanza in un singolo task, per quanto riguarda le esecuzioni multiple, il serizio Fargate e EKS si rimanda alla documentazione ufficiale dei corrispettivi servizi e degli articoli specifici. 

Se si usa EC2 come cluster o parte di un cluster, bisogna ricordare che nelle istanze deve essere obbligatoriamente installato un "ECS agent" e che deve esssere configurato, si rimanda alla documentazione ufficiale
```
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html
```
per tutti i dettagli, questo articolo vuole esserne solo un breve riassunto per chi usa le immagini Linux. 
Ipotizzando che il cluster si chiami docker-cluster (con molta fantasia), la sequenza di comandi per la installazione la configurazione dell'agente "ECS agent" :
```
$ sudo yum install -y ecs-init
$ sudo amazon-linux-extras install ecs
$ sudo systemctl enable --now ecs
$ sudo systemctl start ecs.service
$ sudo echo ECS_CLUSTER=docker-cluster >> /etc/ecs/ecs.config
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

Per creare l'infrastruttura di esecuzione di una immagine docker è possibile usare la console web seguendo le varie guide online
```xxx```
opprue è possibile usare la CLI eseguendo i comandi messi a disposizione dalla architettura, ovviamente i comandi devono essere eseguiti nella giusta sequenza, un esempio è:
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
$ aws ecs create-cluster --cluster-name docker-cluster
$ aws ecs list-clusters
$ aws ecs describe-clusters --clusters docker-cluster
```
- Seguire le istruzioni sopra descritte per collegare una istanza EC2 al cluster ECS, è possibile anche seguire la guida ufficiale ```https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html```
, se tutto correttamente configurato, la istanza è disponbile nel cluster:
```
$ aws ecs list-container-instances --cluster  docker-cluster
$ aws ecs describe-container-instances --cluster default --container-instances container_instance_ID
```
- Registrare una task definition seguendo la guida ufficiale  
```https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html#AWSCLI_EC2_launch_container_instance```
, la task definition è copiata dall'esempio ufficiale e non fa nulla se non un comando di sleep:
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
```
- In alternativa è possible anche registrare inserendo la definizione nel comando ma è scosigliato:
```
    or aws ecs register-task-definition --family sleep360 --container-definitions "[{\"name\":\"sleep\",\"image\":\"busybox\",\"cpu\":10,\"command\":[\"sleep\",\"360\"],\"memory\":10,\"essential\":true}]"
```
- Se l'immagine è disponibile su ECR, nel file di confiruazione è necessario indicare la fonte ed è possibile indicare la 
configurazione delle porte
```
{
    "containerDefinitions": [
        {
            "name": "api-persone-nodb",
            "image": "<accountId>.dkr.ecr.eu-west-1.amazonaws.com/formazione-ecs-repo-uno:latest",
            "cpu": 1,
            "memory": 300,
            
            "portMappings": [
                {
                    "containerPort": 5001,
                    "hostPort": 5001, 
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
```
l'esempio completo si può trovare nel repository
```
https://github.com/alnao/PythonExamples/blob/master/Docker/03ApiPersoneNoDb/taskECS.json
```
- Avvio del task, specificando che il nome del "task definition" corrisponde al valore "family" indicato nel json di definizione:
```
$ aws ecs list-task-definitions
$ aws ecs run-task --cluster docker-cluster --task-definition sleep360:1 --count 1
$ aws ecs list-tasks --cluster docker-cluster 
$ aws ecs describe-tasks --cluster  docker-cluster  --task <id>
```
Per tutti i dettagli si rimanda alla guida completa nella [guida completa del sito ufficiale](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html).

Con CloudFormation è possibile creare e gestire risorse ECS con i tipi specifici messi a disposizione, si possono prendere di esempio alcuni repository pubblici ufficiali come:
```
https://s3.amazonaws.com/ecs-refarch-cloudformation/infrastructure/ecs-cluster.yaml
https://s3.amazonaws.com/ecs-refarch-cloudformation/services/product-service/service.yaml
```
I principali oggetti sono:
```
  Cluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Ref EnvironmentName
  Service:
    Type: AWS::ECS::Service
    DependsOn: ListenerRule
    Properties:
      Cluster: !Ref Cluster
      Role: !Ref ServiceRole
      DesiredCount: !Ref DesiredCount
      TaskDefinition: !Ref TaskDefinition
      LoadBalancers:
        - ContainerName: "product-service"
          ContainerPort: 80
          TargetGroupArn: !Ref TargetGroup
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: product-service
      ContainerDefinitions:
        - Name: product-service
          Essential: true
          Image: xxxxxx.dkr.ecr.us-east-1.amazonaws.com/xxxxxxxxxxxxxx
          Memory: 128
          PortMappings:
            - ContainerPort: 80
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref CloudWatchLogsGroup
              awslogs-region: !Ref AWS::Region
```
Per tutti i dettagli si rimanda alla documentazione ufficiale
  ```
  https://docs.aws.amazon.com/it_it/AmazonECS/latest/developerguide/creating-resources-with-cloudformation.html
  ```
agli esempi nel repository pubblico:
```https://github.com/aws-samples/ecs-refarch-cloudformation/blob/master/master.yaml```
ed è possibile visionare un esempio funzionante nel solito repository:
```https://github.com/alnao/AWSCloudFormationExamples/tree/master/Esempio20dockerEcrEcs```
per provare questo semplice esempio può essere usata una immagine di prova disponbile nel repository
```https://github.com/alnao/PythonExamples/tree/master/Docker/03ApiPersoneNoDb```
* Fargatge
```https://github.com/aws-samples/cloudformation-transfer-family-efs-ecs-example/blob/main/cloudformation/tenant.yaml```



# Esempio 20 Docker with ECR e ECS
AWS CloudFormation Examples - vedere i prerequisiti nel README generale


Creazione di un repository ECR e infrastruttura ECS


L'immagine di prova usata in questo esempio è disponibile nel repository
```
https://github.com/alnao/PythonExamples/tree/master/Docker/03ApiPersoneNoDb
```


## Comandi per la creazione

```
sam validate
sam build
sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
sam deploy --template-file .\packagedV1.yaml --stack-name Esempio20dockerEcrEcs --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

```
nota: --capabilities CAPABILITY_IAM è obbligatorio per le regole IAM


## Comandi per i test
Per eseguire test del servizio 
```
$ curl  Esempio20dockerEcrEcs-xxxxxxxxx.eu-west-1.elb.amazonaws.com/persone
$ curl -d '{"nome":"Andrea", "cognome":"Nao"}' -H "Content-Type: application/json" -X POST Esempio20dockerEcrEcs-xxxxxxxxx.eu-west-1.elb.amazonaws.com/persone
$ curl  Esempio20dockerEcrEcs-xxxxxxxxx.eu-west-1.elb.amazonaws.com/persone
```



## Comandi per la rimozione
```
sam delete --stack-name Esempio20dockerEcrEcs
``` 


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*