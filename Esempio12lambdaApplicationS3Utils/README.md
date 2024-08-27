# AWS CloudFormation Examples - 12 Lambda Application S3 Utils
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Componenti di questo template:
  - database RDS come base dati (di default viene usato il tipo Aurora più economico)
  - bucket S3 come storage dei files
    - * nota: per il caricamento/upload tramite lambda è necessario modificare *manualmente* le proprietà del bucket disattivando il "Block all public access" e aggiungendo la policy nel bucket:
    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "uno",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "*",
                "Resource": "arn:aws:s3:::es12-application/*"
            },
            {
                "Sid": "due",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "*",
                "Resource": "arn:aws:s3:::es12-application"
            }
        ]
    }
    ```
    nota: questa policy potrebbe è molto permissiva, ci sono versioni con più restrizioni su IP sorgente o altre limitazioni possibili, si rimanda alla [documetazione ufficiale](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html) per tutti i dettagli
  - lambda per il caricamento di un file su S3 tramite **presigned_url** di tipo Put
  - lambda function per estrazione ZIP 
  - lambda per la conversione conversione da excel a csv
  - lambda function per caricamento dati nel database
  - api gateway per recupero dati dal databse e caricamento file nel bucket con due lambda function specifiche
  - tabella Dynamo per la gestione dei log di caricamenti
  - regola IAM per la gestione dei permessi 
  - regole per la gestione del cors

## CloudFormation

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file packagedV1.yaml --stack-name Esempio12lambdaApplicationS3Utils --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides VpcId=vpc-0013c2751d04a7413 Subnet1=subnet-0ca3ce54f35c3d3ef Subnet2=subnet-08dbf4b5fed6a83b2

* Comandi per il caricamento via CLI
    ```
    aws s3 cp ./test.zip s3://es12-application/INPUT/test.zip
    aws s3 ls s3://es12-application/CSV/test.csv
    ```

* Usare la pagina index.html di prova, usando la pagina html senza webserver potrebbero esseci problemi di CORS, usando un webserver comune si evitano problemi, per lanciare il webserver base usare il comando:
    ```
    python -m http.server 8080
    ```
    e poi accedere alla pagina `http://localhost:8080/`


* Comandi per la rimozione dello stack
    - Prima di procedere verificare il database RDS, di default nel template c'è il flag `DeletionProtection` attivato, disattivarlo manualmente da console per poter procedere alla cancellazione
    ```
    aws s3 ls s3://es12-application/
    aws s3 rm s3://es12-application/INPUT/test.zip
    aws s3 rm s3://es12-application/DEZIPPED/test.xlsx
    aws s3 rm s3://es12-application/CSV/test.csv
    aws s3 ls s3://es12-application/
    sam delete --stack-name Esempio12lambdaApplicationS3Utils
    ```
    
# Comandi su claude:
1) Ho bisogno che mi crei un template cloudformation AWS per gestire i componenti:
    1) bucket S3 il cui nome deve essere parametrico con default "es11-application"
    2) trigger sul bucket in un path parametrico con valore default "INPUT" e per i file con estensione parametrica con valore default "zip"
    3) il trigger del punto 2 deve eseguire una aws lambda in python che decomprime lo zip caricato al punto precedente e salva il contenuto in un path parametrico con valore default "DEZIPPED"
    4) trigger sul bucket nel path del punto 3 per i file con estensione parametrica con valore di default "xlsx"
    5) il trigger del punto 4 deve eseguire una aws lambda in python che converte il file excel del punto precedente in un csv e salva il file in un path parametrico con valore default "CSV"
    6) trigger sul bucket nel path del punto 5 per i file con estensione parametrica con valore di default "csv"
    7) il trigger del punto 6 deve eseguire una aws lambda in python che prende tutti i dati e salva i dati in un database RDS (punto 8) e salva una riga di log in una tabella Dynamo (punto 9)
    8) il nome database RDS e la tabella deve essere parametrica con valori di default "es11-db" e "es11-table"
    9) la tabella dynamo deve avere nome parametrico con valore default "es11-log" con campi id (univoco), nome_file, data_caricamento, esito_caricamento
    10) api get per leggere i dati dalla tabella RDS
    11) api get per leggere i dati dalla tabella Dynamo
    12) api per caricare il file zip nella cartella usata nel punto 2 con presigned url
    13) api per scaricare file excel caricati del punto 4
    13) per ogni trigger su eventbridge crea un parametro "StateTrigger" che di default "ENABLED" per poter 
    per le lambda usa il tipo "AWS::Serverless::Function" e per le api usa il tipo "AWS::Serverless::Api"
2) ora completami il pezzo su RDS
3) ora scrimi i file python per le lambda
4) ora riscrimi i pezzi di CloudFormation per aggiungere tutti i parametri alle lambda e perchè i file python sono posizionati dentro ad una cartella lambda
5) ora crea una regola IAM per permettere alle lambda di fare tutto quello che serve
6) scrivi le API per leggere i dati da RDS , scrimi il codice della lambda python e il codice del template cloudformation
7) scrivi le API per leggere i dati dalla tabella dynamo, scrimi il codice della lambda python e il codice del template cloudformation
8) ora riscrivi il componente "AWS::Serverless::Api" aggiungendo le regole "Cors" , "MethodSettings", stage parametrico con usando "dev" come valore di default e CacheClusterEnabled: false
9) mi da questo errore "CreateChangeSet operation: Parameters: PasswordParam must have values", mi risolvi il problema?
10) mi da questo errore "Error: PythonPipBuilder:ResolveDependencies - {psycopg2==2.9.9(wheel)}", come risolvo?
11) mi servono altre due API: una per avere la lista di tutti gli excel nella cartella "DezippedFolderName" e una seconda API per scaricare un singolo file ritornato dall'elenco della prima
12) ora creami la lambda UploadZipLambda per caricare zip nella cartella InputFolderName, nella lambda aggiungi un controllo che il file deve avere estensione ZIP
13) ho questo errore "Status: FAILED. Reason: Circular dependency between resources: [ServerlessRestApiDeployment098849be71, ...]" me lo sistemi?
    Certamente! Questo errore indica una dipendenza circolare tra le risorse nel tuo template CloudFormation. Per risolvere questo problema, dobbiamo riorganizzare il template in modo da eliminare queste dipendenze circolari. La soluzione principale consiste nel separare la definizione dell'API Gateway dalle funzioni Lambda e utilizzare riferimenti espliciti invece di eventi impliciti.
14) al posto di BucketNotification utilizza EventBridge, grazie
15) mi riscrivi la definizione di tutte le lambda usando i parametri LambdaRuntime, LambdaMemorySize e LambdaTimeout
16) ciao, modificami la process_csv_lambda, prima della insert, se la tabella non esiste deve essere creata, i campi della tabella sono quelli presenti nel csv con tipo stringa di 100 caratteri
17) puoi modificare la lambda in modo che non vada in errore se nel csv ci sono colonne non presenti nella tabella ?
18) Ciao, usando il template ho l'errore "CloudWatch Logs role ARN must be set in account settings to enable logging", riesci a riscrivere i pezzi da sistemare ?

19) ciao, mi crei una pagina web che usi bootstrap5 chiami la api con endpoint "" con quattro blocchi
    1) permette di caricare il file con metodo upload
    2) visualizzi in lista i valori ritornati dalla tabella dynamo
    3) visualizzi la lista dei file excel e che permetta di scaricare i files
    4) visualizzi la tabella RDS (la tabella deve essere filtrabile e scollabile)

20) Usando questo template ho l'errore "CloudWatch Logs role ARN must be set in account settings to enable logging", me lo modifichi per risolvere il problema?
21) ciao, mi recuperi il codice della lambda read_dynamodb_data_lambda ?
22) e recuperami il codice della lambda read_rds_data_lambda
23) provando a caricare un file, il presigned url di upload mi da errore 403, cosa può essere?
24) L'URL presigned mi ritorna errore 500 , perchè ?
25) io utilizzo la pagina in allegato, modificala e utilizza axios quando chiami la api per fare upload del file "data.upload_url"

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
**Free Software, Hell Yeah!**
See [MIT](https://it.wikipedia.org/wiki/Licenza_MIT)

Copyright (c) 2023 AlNao.it