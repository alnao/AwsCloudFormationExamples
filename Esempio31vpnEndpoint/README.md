# AWSCloudFormationExamples
AWS CloudFormation Examples - vedere i prerequisiti nel README generale

## Esempio22lamp
Template che crea una VPC e un relativo VPC endpoint con tutte le configurazioni di rete


### Comandi per la creazione

```
sam validate
sam build
sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket alberto-input
sam deploy --template-file .\packagedV1.yaml --stack-name VPNendpointFormaz --capabilities CAPABILITY_IAM

```
nota: --capabilities CAPABILITY_IAM è obbligatorio per le regole IAM

### Comandi per la rimozione
```
sam delete --stack-name VPNendpointFormaz
``` 
