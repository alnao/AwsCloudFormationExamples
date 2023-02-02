# AWSCloudFormationExamples
AWS CloudFormation Examples by [AlNao](https://www.alnao.it/wordpress/aws)

## Prerequisiti
- Un account AWS attivo
- La AWS-CLI installata correttamente, [documentazione ufficiale](https://docs.aws.amazon.com/it_it/cli/v1/userguide/cli-chap-install.html)
- Configurazione utenza tecnica su IAM di tipo programmatico con permessi di esecuzione di CloudFormation e configurazione della AWS-CLI con il comando
    - ```aws configuration```
- La AWS-CLI-SAM installata correttamente, [documentazione ufficiale](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Per ogni template, se non indicato diversamente, i comandi da eseguire per eseguire il deploy sono:
  - ```sam validate```
  - ```sam build```
  - ```sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket alberto-input```
  - ```sam deploy --template-file .\packagedV1.yaml --stack-name esempio00name --capabilities CAPABILITY_IAM```

## Esempi
- 01: creazione bucket semplice
- 02: creazione bucket con abilitazione a sito esposto (senza CloudFront)
- 03: creazione bucket e parametri modificabili da riga di comando o console
- 04: lambda(Py) che viene avviata al caricamento di un file in un S3, la lambda scrive solo un log
- 05: lambsa(Py) che da un file CSV caricato su bucket S3 carica una tabella Dynamo, la prima riga del CSV è l'elenco dei campi del tracciato (Dynamo non è schema-less)
- 06: lambda(Py) che copia in un file da un bucket ad un altro con trigger nel primo
- 07: lambda con python esterno (come da best-practices)
- 08: lambda(Py) triggerata ad un upload di un se, chiamata ad una stepFunction che copia il file e poi lo cancella dalla sorgente
- 09: lambda(Py) triggerata ad un upload di un se, chiamata ad una stepFunction che esegue dei passaggi
  - copia in una cartella staging IN
  - cancellazione dell'originale
  - copia in una cartella staging OUT
  - copia in un bucket esterno
- 10: api rest con chiamata lambda (script da ApiManager)
- 11: lambda(Py) esposta con API che ritorna un json di esempio
- 12: CRUD Api su Tabella Dynamo (schema-less)
- 13: lambda(Py) per gestire file (leggere e scrivere)
- 14: avvio istanze EC2
- 15: lambda in Java-maven
- 16: lambda(Py) esposta con API che valida un token Jwt
- 17: lambda(Py) che esegue unzip di un file da un bucket ad un altro
- 18: template di istanza EC2 con parametri recuperati dal SSM Parameter Store
- 19: template di istanza EC2 evolutiva del 18 con definizione di matrice mappins per dimensione dell'istanza
- 20: template di istanze EC2 evolutiva del 19 con condition: creazione di un volume in produzione e non in dev
- 21: template che crea un coda con il Servizio SQS e due semplici lambda in PY per leggere e scrivere nella coda
- 22: template che crea una VPC e un VPNendpoint da usare con il client da desktop
- 23: template che crea una VPC, un RDS MySql e una EC2, nella EC2 viene installato in automatico un Wordpress

## See
Tutti questi esempi sono spiegati nel sito [alnao.it](https://www.alnao.it/wordpress/aws/) nella pagina di AWS nella sottosezione dedicata ad CloudFormation.

