# AWS CloudFormation Examples - 22 CloudWatch alarm
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di un allarme CloudWatch usando lo stesso autoscaling group usato nell'esempio 21

## CloudFormation
Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudwatch-alarm.html) di cloudwatch-alarm:
  ```
  CPUScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !GetAtt Base.Outputs.AutoScalingGroupName
      Cooldown: 60
      ScalingAdjustment: 1
  CPUAlarmHigh:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: Scale-up if CPU > 84% for 10 minutes
      MetricName: CPUUtilization
      Namespace: AWS/EC2
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 84
      AlarmActions: [!Ref CPUScaleUpPolicy]
      Dimensions:
        - Name: AutoScalingGroupName
          Value: !GetAtt Base.Outputs.AutoScalingGroupName
      ComparisonOperator: GreaterThanThreshold
  ```

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio22cloudWatchAlarm --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides KeyName=xxx VpcId=vpc-xxx PublicSubnet1=subnet-xxx  PublicSubnet2=subnet-xxx PrivateSubnet1=subnet-xxx PrivateSubnet2=subnet-xxx
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

* Forzare l'allarme di un alarm per forzare lo scaling verticale
    ```
    aws cloudwatch set-alarm-state --alarm-name "Esempio22cloudWatchAlarm-CPUAlarmHigh-xxx" --state-value ALARM --state-reason "Testing alarm"
    aws cloudwatch set-alarm-state --alarm-name "Esempio22cloudWatchAlarm-CPUAlarmHigh-xxx" --state-value OK --state-reason "Testing alarm OK"
    ```

* Comandi per la rimozione di uno stack:
    ```
    sam delete --stack-name Esempio22cloudWatchAlarm
    ```

## Comandi CLI
Documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elbv2/index.html)
* Lista degli allarmi esistenti
    ```
    aws cloudwatch describe-alarms
    aws cloudwatch describe-alarms --query MetricAlarms[*].[AlarmName,StateValue] --output table
    aws cloudwatch describe-alarms --state-value ALARM
    aws cloudwatch describe-alarms --state-value ALARM --query MetricAlarms[*].[AlarmName,StateValue] --output table
    ```
* Creare un allarme 
    ```
    aws cloudwatch put-metric-alarm \
        --alarm-name "CPUUtilizationHigh" \
        --alarm-description "CPU high utilization" \
        --metric-name CPUUtilization \
        --namespace AWS/EC2 \
        --statistic Average \
        --period 300 \
        --threshold 84 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions arn:aws:autoscaling:region:account-id:scalingPolicy:policy-id \
        --dimensions Name=AutoScalingGroupName,Value=my-asg-name
    ```
* Cancellare un allarme    
    ```
    aws cloudwatch delete-alarms --alarm-names "MyAlarm1" "MyAlarm2"
    ```
* Abilitare/disablitare un allarme
    ```
    aws cloudwatch enable-alarm-actions --alarm-names "MyAlarm1"
    aws cloudwatch disable-alarm-actions --alarm-names "MyAlarm1"
    ```
* Visualizzare la storia di un allarme
    ```
    aws cloudwatch describe-alarm-history --alarm-name "MyAlarm1"
    ```
* Recuperare lo stato di un allarme
    ```
    aws cloudwatch describe-alarms --alarm-names "MyAlarm1" --query 'MetricAlarms[].StateValue'
    ```
* Forzare l'allarme di un alarm
    ```
    aws cloudwatch set-alarm-state --alarm-name "MyAlarm1" --state-value ALARM --state-reason "Testing alarm"
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


