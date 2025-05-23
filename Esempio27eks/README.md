# AWS CloudFormation Examples - 27 EKS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di cluster e nodo EKS per eseguire una immagine docker salvata dockerHub (per ora DockeHub, in futuro anche su ECR).

L'immagine docker è un microservizio in Java, vedere il repository Esempio03dbDockerAWS:
```
https://github.com/alnao/JavaSpringBootExample/tree/master/Esempio03dbDockerAWS
```

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-eks-cluster-computeconfig.html) di EKS:
```
# EKS Cluster
EKSCluster:
    Type: AWS::EKS::Cluster
    DependsOn: GetDefaultSubnets
    Properties:
        Name: !Ref ClusterName
        Version: '1.29'
        RoleArn: !GetAtt EKSClusterRole.Arn
        ResourcesVpcConfig:
        SecurityGroupIds:
            - !Ref ControlPlaneSecurityGroup
        SubnetIds: !Split 
            - ','
            - !GetAtt GetDefaultSubnets.SubnetIds
        EndpointConfigPublic: true
        EndpointConfigPrivate: false
        Logging:
        ClusterLogging:
            EnabledTypes:
            - Type: api
            - Type: audit

# EKS Node Group
EKSNodegroup:
    Type: AWS::EKS::Nodegroup
    DependsOn: EKSCluster
    Properties:
        ClusterName: !Ref ClusterName
        NodegroupName: !Ref NodeGroupName
        ScalingConfig:
        MinSize: !Ref NodeGroupMinSize
        DesiredSize: !Ref NodeGroupDesiredCapacity
        MaxSize: !Ref NodeGroupMaxSize
        InstanceTypes:
        - !Ref NodeInstanceType
        NodeRole: !GetAtt EKSNodeRole.Arn
        Subnets: !Split 
        - ','
        - !GetAtt GetDefaultSubnets.SubnetIds
        AmiType: AL2_x86_64
        CapacityType: ON_DEMAND
        DiskSize: 20
        ForceUpdateEnabled: false
        Labels:
        Environment: production
        Application: springboot
```

* Comani per la creazione dello stack:
    ```
    aws s3 mb s3://cloudformation-alnao --region eu-central-1

    # Trova la VPC di default
    DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
    echo $DEFAULT_VPC
    # Trova le subnet della VPC di default
    SUBNET_LIST1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[*].[SubnetId,AvailabilityZone][0][0]' --output text)
    SUBNET_LIST2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[*].[SubnetId,AvailabilityZone][1][0]' --output text)
    SUBNET_LIST3=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[*].[SubnetId,AvailabilityZone][2][0]' --output text)
    SUBNET_LIST=$SUBNET_LIST1,$SUBNET_LIST2,$SUBNET_LIST3
    echo $SUBNET_LIST

    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file packagedV1.yaml --stack-name Esempio27eks  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --parameter-overrides  DefaultVPCId=$DEFAULT_VPC SubnetIds="$SUBNET_LIST"
    
    ```
    *Nota*: in questo template `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` non sono necessari ma lasciati ugualmente
    

* Comandi per il push di una immagine nel repository:
    ```
    # Configurazione kubectl locale 
    aws eks update-kubeconfig --region eu-central-1 --name aws-j-es03-cloudformation-eks-cluster
    aws cloudformation describe-stacks --stack-name Esempio27eks --query 'Stacks[0].Outputs[?OutputKey==`MySQLEndpoint`].OutputValue' --output text
    RDS_PATH=$(aws cloudformation describe-stacks --stack-name Esempio27eks --query 'Stacks[0].Outputs[?OutputKey==`MySQLEndpoint`].OutputValue' --output text)
    echo $RDS_PATH
    # Avvio microservizio con kubectl
    kubectl apply -f springboot-k8s.yaml
    kubectl get services springboot-app-service
    kubectl get service springboot-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    ```
* Verifica endpoint e api di *info*
    ```
    ENDPOINT=$(kubectl get service springboot-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    ENDPOINTinfo=$ENDPOINT/api/persone/info
    curl $ENDPOINTinfo
    ```
* Distruzione di tutto
    ```
    kubectl get services
    kubectl get deployments
    kubectl get horizontalpodautoscalers

    kubectl delete service springboot-app-service
    kubectl delete deployment springboot-app
    kubectl delete horizontalpodautoscaler springboot-app-hpa

    sam delete --stack-name Esempio27eks
    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/eks/index.html)
* Crea un nuovo cluster EKS
    ```
    aws eks create-cluster --name my-cluster --version 1.29 --role-arn arn:aws:iam::account:role/eks-service-role
    ```
* Lista tutti i cluster EKS
    ```
    aws eks list-clusters
    ```
* Ottieni dettagli di un cluster specifico
    ```
    aws eks describe-cluster --name aws-j-es03-cloudformation-eks-cluster
    ```
* Elimina un cluster EKS
    ```
    aws eks delete-cluster --name my-cluster
    ```
* Aggiorna la versione di Kubernetes del cluster
    ```
    aws eks update-cluster-version --name aws-j-es03-cloudformation-eks-cluster --version 1.30
    ```
* Configura kubectl per connettersi al cluster
    ```
    aws eks update-kubeconfig --region eu-central-1 --name aws-j-es03-cloudformation-eks-cluster
    ```
* Configura kubectl con alias per il contesto
    ```
    aws eks update-kubeconfig --region eu-central-1 --name aws-j-es03-cloudformation-eks-cluster --alias my-cluster-context
    ```
* Crea un nuovo node group
    ```
    aws eks create-nodegroup --cluster-name aws-j-es03-cloudformation-eks-cluster --nodegroup-name aws-j-es03-cloudformation-eks-nodegroup
    ```
* Lista tutti i node group di un cluster
    ```
    aws eks list-nodegroups --cluster-name aws-j-es03-cloudformation-eks-cluster
    ```
* Ottieni dettagli di un node group specifico
    ```
    aws eks describe-nodegroup --cluster-name aws-j-es03-cloudformation-eks-cluster --nodegroup-name aws-j-es03-cloudformation-eks-nodegroup
    ```
* Elimina un node group
    ```
    aws eks delete-nodegroup --cluster-name aws-j-es03-cloudformation-eks-cluster --nodegroup-name aws-j-es03-cloudformation-eks-nodegroup
    ```


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


