# AWS CloudFormation Examples - 15 SQS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione di una semplice cosa SQS con due lambda che scrivono e leggono elementi dallac odsa

## CloudFormation
* Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html) di SQS:
  ```
  SqsQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Ref QueueName
      VisibilityTimeout: 180
      Tags:
        -
          Key: StackId
          Value: !Ref AWS::StackId
  ```
* Comandi per la creazione dello stack
  ```
  sam validate
  sam build
  sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
  sam deploy --template-file .\packagedV1.yaml --stack-name Esempio15sqs --capabilities CAPABILITY_IAM 
  ```
* Comandi per la gestione della coda con le API REST
  ```
  curl  https://qiw9d6flu4.execute-api.eu-west-1.amazonaws.com/dev  

  curl -i -H "Accept: application/json" -X POST -d "{\"messageEvent\":\"messaggio evento\"}"  https://qiw9d6flu4.execute-api.eu-west-1.amazonaws.com/dev 

  curl  https://qiw9d6flu4.execute-api.eu-west-1.amazonaws.com/dev  

  ```
* Comando per la rimozione dello stack
  ```
  sam delete --stack-name Esempio15sqs
  ```

## Comandi CLI
* Riferimento documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sqs/index.html) o utilizzare il comando `aws sqs help` per ottenere informazioni dettagliate su ogni comando.
* Creazione una coda
  ```
  aws sqs create-queue --queue-name MyQueue --attributes file://create-queue.json
  ```
* Elenco code disponibli
  ```
  aws sqs list-queues
  ```
* Dettaglio coda disponibile
  ```
  aws sqs get-queue-attributes --queue-url https://sqs.eu-west-1.amazonaws.com/<accountId>/MyQueue --attribute-names All
  aws sqs get-queue-attributes --queue-url https://sqs.eu-west-1.amazonaws.com/<accountId>/MyQueue --attribute-names ApproximateNumberOfMessages --output table
  ```
* Invio messaggio nella coda (producer)
  ```
  aws sqs send-message --queue-url https://sqs.eu-west-1.amazonaws.com/<accountId>/MyQueue --message-body "{\"messageEvent\":\"messaggio evento da cli\"}" --delay-seconds 10
  ```
* Invio messaggio nella coda con file esterno (producer)
  ```
  aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/<accountId>/MyQueue --message-body "Information about the largest city in Any Region." --delay-seconds 10 --message-attributes file://send-message.json
  ```
* Ricezione di un messaggio e cancellazione dalla coda (consumer)
  ```
  aws sqs receive-message --queue-url https://sqs.eu-west-1.amazonaws.com/<accountId>/MyQueue --attribute-names All --message-attribute-names All --max-number-of-messages 10
  ```
* Eliminazione una coda
  ```
  aws sqs delete-queue --queue-url https://sqs.us-east-1.amazonaws.com/<accountId>/MyQueue
  ```





# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*