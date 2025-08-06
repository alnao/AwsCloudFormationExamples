# AWS CloudFormation Examples - 19 Wodpress
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di istanze EC2 con installato un Wordpress che usa un DB RDS e disco EFS

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-instance.html) di Ec2:


* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio19wordpressSingle --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides KeyName=xx VpcId=vpc-xx PublicSubnetId=subnet-xx PrivateSubnet1=subnet-xx PrivateSubnet2=subnet-xx
    ```
    *Nota*: `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` sono obbligatori per le regole IAM e CloudFormation presenti nei template    
    *Nota*: per avviare il template è necessario inserire tutti i parametri obbligatori: KeyName, VpcId, PublicSubnetId,PrivateSubnet1,PrivateSubnet2 .

    
* Comandi per verifica della istanza:
    ```
    ssh ec2-user@xxx.xxx.xxx.xxx   -i keyyyyyyy.pem
    curl localhost
    sudo cat /var/log/cloud-init-output.log
    sudo cat /var/log/cfn-init.log
    sudo cat /var/log/cloud-init.log
    sudo cat /var/log/amazon/efs/mount.log
    ```

* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio19wordpressSingle
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*
