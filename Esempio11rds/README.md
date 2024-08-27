# AWS CloudFormation Examples by AlNao - 11 RDS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Esempio di template CloudFormation per creare un database MySql e un database RDS con un security group dedicato.

## CloudFormation
Documentazione di [RDS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbcluster.html)
```
Resources:
  RDSCluster:
    Type: 'AWS::RDS::DBCluster'
    Properties:
      DBClusterIdentifier: my-multi-az-cluster-pit
      DBClusterInstanceClass: db.r6gd.large
      Engine: aurora-mysql
      DBName: 'rds'
      MasterUsername: 'user'
      MasterUserPassword: 'S3Cr€ts'
      
      PubliclyAccessible: true
```
e si può vedere l'[esempio ufficiale github.com/aws-samples](https://github.com/aws-samples/aws-aurora-cloudformation-samples/blob/master/cftemplates/Aurora-Postgres-DB-Cluster.yml) e [esempi](https://github.com/widdix/aws-cf-templates/blob/master/state/rds-mysql.yaml).
Verificare anche la guida sul [tipo di istanze](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.MySQL.html) e la documentazione [Aurora con server di tipo Serverless](https://docs.amazonaws.cn/en_us/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html).

* Comandi per la creazione dell'esempio
  ```
  sam validate
  sam build
  sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
  sam deploy --template-file .\packagedV1.yaml --stack-name Es11Rds --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides DBUsername=alnao SSHLocation='0.0.0.0/0' VpcId=vpc-xxx PrivateSubnet1=subnet-xxx PrivateSubnet2=subnet-xxx
  ```
  nota: --capabilities CAPABILITY_IAM e CAPABILITY_AUTO_EXPAND sono obbligatori per le regole IAM

* Comandi per la rimozione dello statck
  ```
  sam delete --stack-name Es11Rds
  ```

## Comandi CLI
* Documentazione [CLI](https://docs.aws.amazon.com/it_it/cli/latest/userguide/cli_rds_code_examples.html)
* Creazione di una istanza mysql, vedi [documentazione ufficiale](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html)
  ```
  aws rds create-db-instance --db-instance-identifier es11-cli-mysql-instance --db-instance-class db.t3.micro --engine mysql --master-username admin --master-user-password secret99 --allocated-storage 20
  ```
* Creazione di una istanza mysql con specificati subnet e security group, vedi [documentazione ufficiale](https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html)
  ```
  aws rds create-db-instance --db-instance-identifier es11-cli-mysql-instance --db-instance-class db.t3.micro --engine mysql --master-username admin --master-user-password secret99 --allocated-storage 20 --vpc-security-group-ids sg-046a835cc014b0f8c --db-subnet-group default-vpc-0013c2751d04a7413 
  ```
* Creazione di un cluster e di una istanza aurora , vedere [documentazione ufficiale](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.CreateInstance.html)
  ```
  aws rds create-db-cluster --db-cluster-identifier es11-cli-aurora-cluster --engine aurora-mysql --engine-version 8.0 --storage-type aurora-iopt1 --master-username alnao --master-user-password secret99 --db-subnet-group-name default-vpc-0013c2751d04a7413 --vpc-security-group-ids sg-046a835cc014b0f8c
  aws rds create-db-instance --db-instance-identifier es11-cli-aurora-instance --db-cluster-identifier es11-cli-aurora-cluster --engine aurora-mysql --db-instance-class db.t4g.medium
  ```
* Lista delle istanze
  ```
  aws rds describe-db-instances  
  aws rds describe-db-instances --query DBInstances[*].[DBInstanceIdentifier,Engine,ActivityStreamStatus] --output table

  ```
* Dettagli di una istanza
  ```
  aws rds describe-db-instances --db-instance-identifier  es11-cli-mysql-instance
  aws rds describe-db-instances --db-instance-identifier  es11-cli-aurora-instance
  ```
* Start e stop di una istanza
  ```
  aws rds stop-db-instance --db-instance-identifier  es11-cli-mysql-instance
  aws rds start-db-instance --db-instance-identifier es11-cli-mysql-instance
  ```

* Generare token di connessione, vedi [documentazione ufficiale](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/rds/generate-auth-token.html)
  ```
  aws rds generate-db-auth-token --hostname es11-cli-mysql-instance.cxascr23ofuc.eu-west-1.rds.amazonaws.com --port 3306 --region eu-west-1 --username alnao
  ```
  Per maggiori dettagli su come è possibile usare il token di questo tipo, vedere la [documentazione ufficiale](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Connecting.AWSCLI.html)

* Rimuovere una istanza 
  ``` 
  aws rds delete-db-instance --db-instance-identifier es11-cli-mysql-instance --final-db-snapshot-identifier es11-cli-mysql-instance-final-snap
  ```
* Rimuovere istanza e cluster aurora
  ``` 
  aws rds delete-db-instance --db-instance-identifier es11-cli-aurora-instance 
  aws rds delete-db-cluster --db-cluster-identifier es11-cli-aurora-cluster --skip-final-snapshot
  ```


* Utilizzo del **rds-data** per eseguire query nel database, *funziona solo con versioni di Aurora*, vedi [documentazione ufficiale](https://docs.aws.amazon.com/it_it/cli/latest/userguide/cli_rds-data_code_examples.html). 
  Nota: Executing statements in your database via the AWS API only works (at this time) if your database is an Aurora Serverless cluster with the Data API enabled. To use the Data API you have to pass it an ARN to a secret that contains the database credentials. Vedere [documentazione ufficiale](https://aws.amazon.com/blogs/aws/new-data-api-for-amazon-aurora-serverless/)
  ```
  aws rds-data execute-statement 
  --resource-arn "arn:aws:rds:eu-west-1:740456629644:cluster:es11-cli-aurora-cluster" 
  --database "es11" 
  --sql "update mytable set quantity=5 where id=201" 
  ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it

