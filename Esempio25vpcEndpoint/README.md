# AWS CloudFormation Examples - 25 VPC
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di una rete VPC completa usando template AWS ufficiale e un VPC EndPoint.

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html) di VPC e template [ufficale](https://s3.amazonaws.com/ecs-refarch-cloudformation/infrastructure/vpc.yaml):
  ```
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: 'true'
      EnableDnsHostnames: 'true'
      Tags:
       - Key: stack
         Value: production
  VPCcomplete:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/ecs-refarch-cloudformation/infrastructure/vpc.yaml
      Parameters:
        EnvironmentName: !Ref AWS::StackName #usato come tag per le risorse
        VpcCIDR: !Ref CidrBlockVPC # "10.84.0.0/16"
        PublicSubnet1CIDR: !Ref CidrBlockSubnetA # "10.84.1.0/24"
        PublicSubnet2CIDR: !Ref CidrBlockSubnetB # "10.84.2.0/24"
        PrivateSubnet1CIDR: !Ref CidrBlockSubnetC # "10.84.3.0/24"
        PrivateSubnet2CIDR: !Ref CidrBlockSubnetD # "10.84.4.0/24"
  ```

* Comani per la creazione dello stack:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio25vpcEndpoint  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM 
    
    ```
    *Nota*: in questo template`--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` non sono necessari
* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio25vpcEndpoint
    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/create-vpc.html):
* Creare una VPC: Per creare una nuova VPC, puoi utilizzare il comando create-vpc. Questo comando richiede di specificare il blocco CIDR per la VPC.
  ```
    aws ec2 create-vpc --cidr-block 10.0.0.0/16
  ```
* Descrivere le VPC: Il comando describe-vpcs permette di ottenere informazioni sulle VPC esistenti. Puoi filtrare i risultati per ID della VPC o altri criteri.
  ```
    aws ec2 describe-vpcs
  ```
* Eliminare una VPC: Per eliminare una VPC, utilizza il comando delete-vpc specificando l'ID della VPC che desideri eliminare.
  ```
    aws ec2 delete-vpc --vpc-id vpc-12345678
  ```
* Creare una Subnet: Le subnet sono segmenti all'interno di una VPC. Puoi creare una subnet con il comando create-subnet.
  ```
    aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.1.0/24
  ```
* Descrivere le Subnet: Per ottenere informazioni sulle subnet, utilizza il comando describe-subnets.
  ```
    aws ec2 describe-subnets
  ```
* Creare un Internet Gateway: Un Internet Gateway permette alla VPC di comunicare con Internet. Puoi crearlo con il comando create-internet-gateway.
  ```
    aws ec2 create-internet-gateway
  ```
* Allegare un Internet Gateway a una VPC: Dopo aver creato un Internet Gateway, devi allegarlo alla tua VPC con il comando attach-internet-gateway.
  ```
    aws ec2 attach-internet-gateway --vpc-id vpc-12345678 --internet-gateway-id igw-12345678
  ```
* Creare una Route Table: Le route table determinano come il traffico viene instradato all'interno della VPC. Puoi crearne una con il comando create-route-table.
  ```
    aws ec2 create-route-table --vpc-id vpc-12345678
  ```
* Aggiungere una Route a una Route Table: Per aggiungere una route a una route table, utilizza il comando create-route.
  ```
    aws ec2 create-route --route-table-id rtb-12345678 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-12345678
  ```
* Associare una Route Table a una Subnet: Infine, per associare una route table a una subnet, utilizza il comando associate-route-table.
  ```
    aws ec2 associate-route-table --route-table-id rtb-12345678 --subnet-id subnet-12345678
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*










## CloudFormation

# AWSCloudFormationExamples
AWS CloudFormation Examples - vedere i prerequisiti nel README generale

## Esempio22lamp
Template che crea un server apache e un RDS mysql


### Comandi per la creazione

```
sam validate
sam build
sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket alberto-input
sam deploy --template-file .\packagedV1.yaml --stack-name VPCendpoint --capabilities CAPABILITY_IAM

```
nota: --capabilities CAPABILITY_IAM è obbligatorio per le regole IAM

### Comandi per la rimozione
```
sam delete --stack-name VPCendpoint
``` 
