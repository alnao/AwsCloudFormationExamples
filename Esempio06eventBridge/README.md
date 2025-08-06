# AWS CloudFormation Examples by AlNao - 06 EventBridge
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Configurazione di Eventbridge per richiamare una lambda come trigger o come evento Cron. In questo esempio la lambda è in un file python dedicato. 


## CloudFormation
Documentazione di [event bridge](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-events-rule.html)
```
  EventBridgeTriggerRole:
    Type: AWS::Events::Rule
    Properties:
      EventBusName: default
      State: !Ref StateTrigger
      EventPattern: 
        source: 
          - "aws.s3"
        detail-type:
          - "Object Created"
        detail: 
          bucket:
            name: 
              - !Ref SourceBucket
          object:
            key:
              - prefix: !Ref SourcePath
      Targets:
        - Id: id1
          Arn: !GetAtt LambdaCopyFunction.Arn
  EventBridgeCronRole:
    Type: AWS::Events::Rule
    Properties: 
      EventBusName: default
      State: !Ref StateTrigger
      ScheduleExpression: cron(00 09 ? * 1 *) #ogni domenica alle 9 di mattina (orario UDC)
      Targets:
        - Id: id1
          Arn: !GetAtt LambdaDeleteFunction.Arn
```

* Comandi per la creazione dell'esempio
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file packagedV1.yaml --stack-name Esempio06eventBridge --capabilities CAPABILITY_IAM
    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)
* Comando caricamento file di prova e verifica esecuzione lambda
    ```
    aws s3 cp ../Esempio05lambda/prova.csv s3://formazione-sftp-simulator/INPUT/prova.csv
    sam logs --stack-name Esempio06eventBridge
    aws s3 ls s3://cloudformation-alnao/OUTPUT/
    ```
* Comandi per la distruzione dello stack con cancellazione del bucket
    ```
    sam delete --stack-name Esempio06eventBridge
    ```

### Possibile problema trigger non avviato
Se il trigger che dovrebbe generare l'evento dal bucket S3 non viene avviato, bisogna controllare nel bucket S3 la configurazione su Proprietà con voce "Amazon EventBridge" sia nello stato " "attivato". Senza questa configurazione non viene eseguito il trigger senza nessun messaggio di errore.
*A causa di questa configurazione è possibile perdere una marea di tempo perchè non si capisce e non c'è nessun log che lo segnala!*

## Comandi CLI
* Documentazione [CLI EventBridge](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/events/index.html)
* Recupero di tutte le regola
    ```
    aws events list-rules
    aws events list-rules --query Rules[].Name --output table
    ```
* Dettaglio di una regola
    ```
    aws events describe-rule --name Esempio06eventBridge-EventBridgeCronRole-izQcLanJGLeb
    aws events describe-rule --name Esempio06eventBridge-EventBridgeTriggerRole-deFyca2ijSro
    aws events describe-event-source --name Esempio06eventBridge-EventBridgeTriggerRole-deFyca2ijSro
    ```
* Abilitare e disabilitare una regola
    ```
    aws events disable-rule --name Esempio06eventBridge-EventBridgeCronRole-izQcLanJGLeb
    aws events enable-rule --name Esempio06eventBridge-EventBridgeCronRole-izQcLanJGLeb
    ```
* Creare una regola
    ```
    aws events  put-rule --name ProvaAlbertoCli --state ENABLED --event-bus-name default --schedule-expression "cron(00 09 ? * 1 *)"
    aws events describe-rule --name ProvaAlbertoCli
    aws events put-targets --event-bus-name default --rule ProvaAlbertoCli --targets "..."
    
    aws events  put-rule --name ProvaAlbertoCli --state ENABLED --event-bus-name default --event-pattern  "..."
    ```
* Eliminare una regola
    ```
    aws events delete-rule --event-bus-name default --name ProvaAlbertoCli
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*