# AWS CloudFormation Examples - 20 Load Balancer
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di ApplicationLoadBalancer con gruppo di istanze con WebSite che non usano RDS e non usano disco EFS condiviso, quindi è sconsigliata questa soluzione in quanto i siti non userebbero lo stesso filesystem, vedere successivi esempi.


## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-loadbalancer.html) di LoadBalancer:
  ```
  ApplicationLoadBalancer:
    Type: 'AWS::ElasticLoadBalancingV2::LoadBalancer'
    Properties:
      Subnets: 
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      Name: 'Esempio26balancer'
      #Type: application | gateway | network
      Tags:
        - Key: Name
          Value: !Ref AWS::StackName 
      LoadBalancerAttributes: 
        - Key: deletion_protection.enabled
          Value: false
      SecurityGroups: 
        - !Ref LBSecurityGroup
  ```

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio20loadBalancer --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides KeyName=xx VpcId=vpc-xx PublicSubnet1=subnet-xx  PublicSubnet2=subnet-xx PrivateSubnet1=subnet-xx PrivateSubnet2=subnet-xx
    ```
    *Nota*: `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` sono obbligatori per le regole IAM e CloudFormation presenti nei template    
    *Nota*: per avviare il template è necessario inserire tutti i parametri obbligatori: KeyName, VpcId, PublicSubnet1,PrivateSubnet1,PrivateSubnet2 .

    
* Comandi per verifica della istanza:
    ```
    ssh ec2-user@xxx.xxx.xxx.xxx   -i keyyyyyyy.pem
    sudo cat /var/log/cloud-init-output.log
    sudo cat /var/log/cfn-init.log
    sudo cat /var/log/cloud-init.log
    sudo cat /var/www/html/index.html
    curl localhost
    ```

* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio20loadBalancer
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*
