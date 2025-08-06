# AWS CloudFormation Examples - 17 ElasticIP
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione di una istanza EC2 con Ip fisso con servizio ElasticIP

Vedi esempio ufficiale [repository](https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/EC2/EIP_With_Association.yaml)

## CloudFormation
* Documentazione [CloudFormation](https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/services/EC2/EIP_With_Association.yaml) di ElasticIP:
  ```
  EIP: 
    Type: AWS::EC2::EIP
    Properties:
      InstanceId: !GetAtt EC2Instance.Outputs.InstanceId
  ```
* Comandi per la creazione dello stack
  ```
  sam validate
  sam build
  sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
  sam deploy --template-file .\packagedV1.yaml --stack-name Esempio17eip  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --parameter-overrides KeyName=xxx VpcId=vpc-xxx SubnetId=subnet-xxx
  ```
* Comando per la rimozione dello stack
  ```
  sam delete --stack-name Esempio17eip
  ```

## Comandi CLI
* Riferimento documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-addresses.html).
* Lista degli indirizzi e le associazioni
  ```
  aws ec2 describe-addresses 
  aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,InstanceId]' --output table
  ```
* Creazione di un indirizzo
  ```
    aws ec2 allocate-address
  ```
* Associa un indirizzo ad una istanza
  ```
    aws ec2 associate-address --instance-id i-0b358ca327f5597d4 --public-ip 54.78.228.112
  ```
* Eliminazione della associazione di un indirizzo alla istanza
  ```
    aws ec2 disassociate-address --public-ip 54.78.228.112
  ```
* Rilasciare un indirizzo rimuovendolo da ElasticIP
  ```
    aws ec2 release-address --public-ip 54.78.228.112
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*