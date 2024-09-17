# AWS CloudFormation Examples - 16 SNS
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione di un topic SNS che invia i messaggi ad una coda SQS che invoca una lambda function

## CloudFormation
* Documentazione [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html) di SNS:
  ```
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub "es16topic"

  SNSToQueuePolicy:
    Type: AWS::SQS::QueuePolicy
    Properties:
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Sid: "allow-sns-messages"
            Effect: Allow
            Principal: "*"
            Resource: !GetAtt Queue.Arn
            Action: "SQS:SendMessage"
            Condition:
              ArnEquals:
                "aws:SourceArn": !Ref SNSTopic
      Queues:
        - Ref: Queue

  QueueSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      TopicArn: !Ref SNSTopic
      Endpoint: !GetAtt Queue.Arn
      Protocol: sqs
      RawMessageDelivery: "true"
  ```
* Comandi per la creazione dello stack
  ```
  sam validate
  sam build
  sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
  sam deploy --template-file .\packagedV1.yaml --stack-name Esempio16sns  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
  ```
* Comando per la rimozione dello stack
  ```
  sam delete --stack-name Esempio16sns
  ```

## Comandi CLI
* Riferimento documentazione [CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sns/index.html) o utilizzare il comando `aws sns help` per ottenere informazioni dettagliate su ogni comando.

* Creare un topic SNS:
    ```
    aws sns create-topic --name es16-topic-cli
    ```
* Elencare i topic SNS:
    ```
    aws sns list-topics
    aws sns list-topics  --output table --query Topics[*].TopicArn
    ```
* Sottoscrivere un endpoint a un topic:
    ```
    aws sns subscribe --topic-arn arn:aws:sns:eu-west-1:xxxx:es16-topic-cli  --protocol email --notification-endpoint bellissimo@alnao.it
    ```
* Elencare le sottoscrizioni per un topic:
    ```
    aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:eu-west-1:xxxx:es16-topic-cli
    aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:eu-west-1:xxxx:es16-topic-cli --query Subscriptions[*].[Protocol,Endpoint,SubscriptionArn] --output table
    ```
    * Cancellare una sottoscrizione:
    ```
    aws sns unsubscribe --subscription-arn arn:aws:sns:us-east-1:xxxx:es16-topic-cli:yyyyyyyyyyyyy
    ```

* Pubblicare un messaggio su un topic:
    ```
    aws sns publish --topic-arn arn:aws:sns:eu-west-1:xxxx:es16-topic-cli --message "Hello, SNS!"
    ```
* Cancellare un topic:
    ```
    aws sns delete-topic --topic-arn arn:aws:sns:eu-west-1:xxxx:es16-topic-cli
    ```


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*