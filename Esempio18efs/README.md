# AWS CloudFormation Examples - 18 Disco EFS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di disco EFS con istanza EC2 che monta il disco

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-filesystem.html) di EFS:
  ```
  FileSystem:
    Type: AWS::EFS::FileSystem
    Properties:
      Encrypted: !Ref Encryption
      FileSystemTags:
        - Key: Name
          Value: !If [hasFsTags, !Ref FileSystemName, !Sub "${AWS::StackName}FileSystem"]
      KmsKeyId: !If [useDefaultCMK, !Ref "AWS::NoValue", !Ref KmsKeyId]
      PerformanceMode: !Ref PerformanceMode
      ThroughputMode: !Ref ThroughputMode
      ProvisionedThroughputInMibps: !If [provisionedThroughputMode, !Ref ProvisionedThroughputInMibps, !Ref 'AWS::NoValue']
  ```
  
* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio18efs --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides KeyName=xxxxx VpcId=vpc-xxxx SubnetId=subnet-xxxx

    ```
    *Nota*: `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` è obbligatorio per le regole IAM eventualmente presenti nei template
    
    *Nota*: per avviare il template è necessario inserire tre parametri obbligatori: KeyName, VpcId e SubnetId.
* Comandi per verifica della istanza e del webserver
    ```
    ssh ec2-user@xx.xx.xx.xx  -i /C/Transito/000_FILES/Keys/20230116_Formazione/AlbertoNaoFormazione.pem
    curl localhost
    sudo cat /var/log/cloud-init-output.log
    sudo cat /var/log/cfn-init.log
    sudo cat /var/log/cloud-init.log
    ls /mnt/efs
    cat  /mnt/efs/index.html
    ```
* Comandi per il montaggio del EFS da un'altra istanza EC2 nella stessa subnet
    ```
    ssh ec2-user@xx.xx.xx.xx  -i /C/Transito/000_FILES/Keys/20230116_Formazione/AlbertoNaoFormazione.pem
    sudo yum update
    sudo yum install -y amazon-efs-utils
    sudo mkdir /mnt/efs
    sudo chmod 777 /mnt/efs 
    sudo mount -t efs -o tls fs-XXXXX.efs.eu-west-1.amazonaws.com:/ /mnt/efs
    ls /mnt/efs
    cat  /mnt/efs/index.html
    sudo nano /mnt/efs/index.html
    sudo umount /mnt/efs
    ```
    *Nota:* la istanza EC2 deve avere lo stesso security groups creato nel template altrimenti il mount non funziona.

* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio18efs
    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/index.html)
* Creare un nuovo file system EFS
  ```
  aws efs create-file-system --creation-token <token>
  ```
* Elencare tutti i file system EFS esistenti
  ```
  aws efs describe-file-systems
  aws efs describe-file-systems --query FileSystems[*].[FileSystemId,Name,LifeCycleState,SizeInBytes.Value] --output table
  ```
* Creare un punto di montaggio per un file system EFS
  ```
  aws efs create-mount-target --file-system-id <fs-id> --subnet-id <subnet-id>
  ```
* Elimina un file system EFS.
  ```
  aws efs delete-file-system --file-system-id <fs-id>
  ```
* Fornisce informazioni sui punti di montaggio di un file system EFS.
  ```
  aws efs describe-mount-targets --file-system-id <fs-id>
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*
