# AWS CloudFormation Examples by AlNao - 06 EventBridge
AWS CloudFormation Examples by [AlNao](https://www.alnao.it), nel README esterno i prerequisiti come AWS-CLI-SAM. 

Esempio di template CloudFormation per creare un trigger che esegue una lambda che esegue una step function se il file match con un pattern. La step function copia il file in un altro bucket, cancella la sorgente e poi esegue una lambda finale.

## CloudFormation
Documentazione di [step function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-stepfunctions-statemachine.html)
```
  StateMachine:
    Type: AWS::Serverless::StateMachine
    Properties:
      Name: !Ref SFName
      Type: STANDARD
      DefinitionUri: statemachine.yaml
      Role: !GetAtt StateMachineRole.Arn
      DefinitionSubstitutions:
        DestFileName: !Ref DestFileName
      Logging:
        Destinations:
          - CloudWatchLogsLogGroup:
              LogGroupArn: !GetAtt StateMachineLogGroup.Arn
        Level: ALL
        IncludeExecutionData: True
  StateMachineLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      RetentionInDays: 30
      LogGroupName: !Sub /aws/vendedlogs/states/${SFName}-statemachine-logs
```

* Comandi per la creazione dell'esempio

    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file .\packagedV1.yaml --stack-name Esempio07stepFunction --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

    ```
    - nota: il parametro ```--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND``` è obbligatorio per la gestione delle regole IAM con template CloudFormation, vedere la [documentazione ufficiale](https://repost.aws/knowledge-center/cloudformation-objectownership-acl-error)

* Comando caricamento file di prova e verifica esecuzione lambda
    ```
    aws s3 cp ../Esempio05lambda/prova.csv s3://formazione-sftp-simulator/INPUT/
    aws s3 ls s3://formazione-sftp-simulator/INPUT/
    aws s3 ls s3://formazione-alberto/OUTPUT/

    aws stepfunctions list-executions --state-machine-arn arn:aws:states:eu-west-1:xxx:stateMachine:smEsempio07 --output table  --query executions[*].[status,startDate,stopDate]

    aws logs filter-log-events --log-group-name /aws/lambda/Esempio07stepFunction-Process-xxxxx
    ```

* Comandi per la distruzione dello stack
    ```
    sam delete --stack-name Esempio07stepFunction
    ```

### Possibile problema trigger non avviato
Se il trigger che dovrebbe generare l'evento dal bucket S3 non viene avviato, bisogna controllare nel bucket S3 la configurazione su Proprietà con voce "Amazon EventBridge" sia nello stato " "attivato". Senza questa configurazione non viene eseguito il trigger senza nessun messaggio di errore.
*A causa di questa configurazione è possibile perdere una marea di tempo perchè non si capisce e non c'è nessun log che lo segnala!*

## Comandi CLI
* Documentazione [Step function](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/stepfunctions/index.html)
* Recupero di tutte le definizione
    ```
    aws stepfunctions   list-state-machines
    aws stepfunctions   list-state-machines  --query stateMachines[].name --output table
    ```
* Descrizione di una step function
    ```
    aws stepfunctions    describe-state-machine --state-machine-arn arn:aws:states:eu-west-1:xxx:stateMachine:smEsempio08 
    ```
* Lista di tutte le esecuzioni di una step function
    ```
    aws stepfunctions list-executions --state-machine-arn arn:aws:states:eu-west-1:xxx:stateMachine:smEsempio08 --output table  --query executions[*].[status,startDate,stopDate]
    aws stepfunctions  get-execution-history --execution-arn <execution-arn>
    ```
* Avvio e stop di una esecuzione
    ```
    aws stepfunctions start-execution --state-machine-arn arn:aws:states:eu-west-1:xxxx:stateMachine:smEsempio08
    aws stepfunctions stop-execution <execution-arn>
    ```
* Creazione e rimozione di una step function
    ```
    aws stepfunctions create-state-machine --name <value> --definition <value> --role-arn <value>
    aws stepfunctions delete-state-machine --state-machine-arn arn:aws:states:eu-west-1:xxxx:stateMachine:sfProva
    ```

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*