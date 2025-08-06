# AWS CloudFormation Examples - 21 AutoScaling wordpress
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di ApplicationLoadBalancer e un AutoScaling group con istanze che caricano RDS e EFS, in questa configurazione è possibile installare wordpress.


## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-autoscaling-autoscalinggroup.html) di AutoScaling:
  ```
  WebServerGroup:
    Type: 'AWS::AutoScaling::AutoScalingGroup'
    Properties:
      VPCZoneIdentifier:  #VPCZoneIdentifier: !Ref Subnets
      - !Ref PrivateSubnet1
      - !Ref PrivateSubnet2
      LaunchConfigurationName: !Ref LaunchConfig
      MinSize: !Ref WebServerCapacityMin
      MaxSize: !Ref WebServerCapacityMax
      DesiredCapacity: !Ref WebServerCapacity
      TargetGroupARNs:
        - !Ref ALBTargetGroup
      Tags:
        - Key: Name
          Value: !Ref AWS::StackName 
          PropagateAtLaunch: true
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MinInstancesInService: 1
        MaxBatchSize: 1
        PauseTime: PT15M
        WaitOnResourceSignals: true
  ```

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio21autoscalingGroupWordpress --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides KeyName=xxx VpcId=vpc-xxx PublicSubnet1=subnet-xxx  PublicSubnet2=subnet-xxx PrivateSubnet1=subnet-xxx PrivateSubnet2=subnet-xxx
    ```
    *Nota*: `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` sono obbligatori per le regole IAM e CloudFormation presenti nei template    
    *Nota*: per avviare il template è necessario inserire tutti i parametri obbligatori: KeyName, VpcId, PublicSubnet1,PrivateSubnet1,PrivateSubnet2 .

    
* Comandi per verifica della istanza:
    ```
    ssh ec2-user@xxx.xxx.xxx.xxx   -i keyyyyyyy.pem
    sudo cat /var/log/cloud-init-output.log
    sudo cat /var/log/cfn-init.log
    sudo cat /var/log/cloud-init.log
    grep -ni 'error\|failure' $(sudo find /var/log -name cfn-init\* -or -name cloud-init\*)
    curl localhost
    sudo cat /mnt/efs/hostname.html
    sudo cat /tmp/create-site
    sudo cat /home/ec2-user/info.txt
    ```
    *Nota*: nel file info nella prima istanza viene indicato che WP è stato installato, dalla seconda istanza viene indicato che il WP è già presente quindi non procede con l'installazione
    *Nota*: il bilanciatore e l'ALB utilizza il file `hostname.html` per verificare lo stato di una instanza, per quello viene usato ancheper salvare la lista delle istanza avviate

* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio21autoscalingGroupWordpress
    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/index.html)
* Creare un nuovo Application Load Balancer
  ```
  aws elbv2 create-load-balancer --name my-load-balancer --subnets subnet-12345678 subnet-87654321 --security-groups sg-12345678 --scheme internet-facing --type application
  ```
* Creare un Target Group
  ```
  aws elbv2 create-target-group \
      --name my-targets \
      --protocol HTTP \
      --port 80 \
      --vpc-id vpc-12345678 \
      --health-check-protocol HTTP \
      --health-check-path /health \
      --target-type instance \
      --health-check-interval-seconds 30 \
      --health-check-timeout-seconds 5 \
      --healthy-threshold-count 2 \
      --unhealthy-threshold-count 2
  ```
* Registrare target nel Target Group
  ```
  aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/my-targets/12345678 --targets Id=i-12345678 Id=i-87654321
  ```
* Creare un Listener
  ```
  aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/my-load-balancer/12345678 --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account-id:targetgroup/my-targets/12345678
  ```
* Dettagli di un Load Balancer
  ```
  aws elbv2 describe-load-balancers --names my-load-balancer
  ```
* Dettagli di un Target Groups
  ```
  aws elbv2 describe-target-groups --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/my-load-balancer/12345678
  ```
* Verificare lo stato dei target
  ```
  aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/my-targets/12345678
  ```
* Eliminare un Listener 
  ```
  aws elbv2 delete-listener --listener-arn arn:aws:elasticloadbalancing:region:account-id:listener/app/my-load-balancer/12345678/87654321
  ```
* Eliminare un Target Group
  ```
  aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/my-targets/12345678
  ```
* Eliminare un Load Balancer
  ```
  aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/my-load-balancer/12345678
  ```
* Configurare HTTPS Listener con certificato ACM
  ```
  aws elbv2 create-listener \
      --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/my-load-balancer/12345678 \
      --protocol HTTPS \
      --port 443 \
      --certificates CertificateArn=arn:aws:acm:region:account-id:certificate/12345678-1234-1234-1234-123456789012 \
      --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account-id:targetgroup/my-targets/12345678
  ```
      

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


