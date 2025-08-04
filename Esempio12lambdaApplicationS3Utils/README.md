# AWS CloudFormation Examples - 12 Lambda Application S3 Utils
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

## Descrizione e Architettura

Questo template CloudFormation implementa una soluzione serverless per la gestione di file su S3, elaborazione tramite Lambda, salvataggio dati su RDS (Aurora Serverless v2 supportato) e DynamoDB, API Gateway, EventBridge, tagging avanzato e best practice di sicurezza e monitoraggio.

### Componenti principali:
- **Bucket S3** per storage file, con "Block all public access" disabilitato e policy custom già inclusa (modifica manuale non più necessaria).
- **Lambda Functions**:
  - Caricamento file su S3 tramite presigned_url (PUT)
  - Estrazione ZIP
  - Conversione Excel → CSV
  - Caricamento dati su RDS (MySQL/Postgres/Aurora)
  - Invio file via SFTP (chiave privata in SSM)
  - Scansione S3 e salvataggio lista file su DynamoDB *scan*
  - API per elencare file nuovi e cercare file per nome
- **DynamoDB**: due tabelle, una per i log e una per la scansione file (`<nome>-scan`, suffisso parametrico)
- **RDS/Aurora**: database relazionale, gestione credenziali tramite AWS Secrets Manager
- **API Gateway**: endpoint REST per tutte le funzioni principali
- **EventBridge**: orchestrazione eventi e schedulazione (es. scansione S3 giornaliera)
- **IAM**: policy dettagliate per sicurezza
- **CloudWatch**: allarmi su errori Lambda e API Gateway
- **Tagging**: tutte le risorse supportano un tag parametrico (`esempio-12`)
- La lambda per eseguire l'invio via sftp di un file da S3 necessita di una chiave privata salvata in SSM, il parametro deve essere creato via console o usando il comando specifico di aws-cli, la chiave deve esssere in formato RSA del tipo 
    ```
    -----BEGIN RSA PRIVATE KEY-----
    riga1
    riga2
    -----END RSA PRIVATE KEY-----
    ```



## Costi stimati (con Aurora Serverless v2)

- **Aurora Serverless v2**: ~89 USD/mese (1 ACU medio, 30GB storage)
- **S3**: ~1 USD/mese
- **Lambda**: 0 USD (entro free tier)
- **DynamoDB**: ~3 USD/mese (2 tabelle)
- **EventBridge/API Gateway/CloudWatch**: <1 USD/mese
- **Totale stimato**: **~94 USD/mese**
- La voce dominante è Aurora Serverless v2. Se vuoi risparmiare valuta DynamoDB-only o Aurora Serverless v1.



## CloudFormation

* Comandi per la creazione:
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket formazione-alberto
    sam deploy --template-file packagedV1.yaml --stack-name Esempio12lambdaApplicationS3Utils --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND  --parameter-overrides VpcId=vpc-xxx Subnet1=subnet-xxx Subnet2=subnet-xxx SftpUsername=xxx SftpHost=xxx.xxx.xxx.xxx SftpPrivateKeyParam=/xxx/key

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


* Test di invio sftp
    ```
    aws s3 cp ./test.zip s3://es12-application/TOSENDSFTP/test.zip
    aws s3 ls s3://es12-application/TOSENDSFTP/test.zip
    ```
    *poi vedere nel server sftp di destinazione se il file text.zip è arrivato correttamente*

* Comandi per la rimozione dello stack
    - Prima di procedere verificare il database RDS, di default nel template c'è il flag `DeletionProtection` attivato, disattivarlo manualmente da console per poter procedere alla cancellazione
    ```
    aws s3 ls s3://es12-application/
    aws s3 rm s3://es12-application/INPUT/test.zip
    aws s3 ls s3://es12-application/DEZIPPED/
    aws s3 rm s3://es12-application/DEZIPPED/test.xlsx
    aws s3 rm s3://es12-application/CSV/test.csv
    aws s3 rm s3://es12-application/TOSENDSFTP/test.zip
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
26) a questo template aggiungi una funzione lambda in python che prende tutti i file del bucket (anche guardando le sottocartelle cartelle) e scrive una nuova tabella Dynamo con i campi: id, nomeFile, path, dimensione, dataOraCreazioneFile, nuovo, dataOraAggiornamentoRiga. il campo nuovo deve essere di default a S. aggiungi la logica se il nomeFile-path è già presente non deve inserire la riga ma modifica il campo "nuovo" s "N". fammi anche una API per leggere quali sono i file nuovi (con nuovo=S). aggiungimi lo schedulatore che esegue la lambda ogni giorno alle 01:00 della mattina, poi fammi una lambda che dato un "nomeFile" lo cerca che mi ritorna se è presente in quali path, aggiungi GSI se servono.
    1) ora aggiungimi l'output del template che c'era prima e aggiunti cose se le trovi interessanti
    2) nel template vorrei disabilitare il "Block all public access" e aggiungere la policy nel bucket "{...}"
    3) voglio che le tabelle dynamo siano 2, quella originale che c'era già prima e una seconda "<nome>-scan" usata dalla scan e della api che abbiamo creato oggi
    4) il "-scan" lo vorrei come parametro
27) ora mi analizzi quanto mi costerebbe questo template in esecuzione pensando a circa 1000 file caricati al giorno
    - S3: ~$1
    - Lambda: $0 (entro free tier)
    - DynamoDB: ~$3
    - RDS: ~$15-20
    - EventBridge/API Gateway/Logs: <$1
    Totale: circa $20-25/mese. La voce dominante è RDS. Se puoi usare Aurora Serverless o DynamoDB per tutto, puoi risparmiare molto.
    1) verifica che Aurora funzioni e che funzioni anche mysql come possibile opzione
    2) nel template voglio aggiungere RDS_ENGINE per le lambda e controllami le lambda, poi nel template controllami e sistema i parametri RDS_HOST e RDS_PORT nel caso si tratti di aurora
    3) fai queste modifiche ora: credenziali RDS su AWS Secret manager, aggiungi allarme cloudwatch per evidenziare se la lambda o l'api è andato in errore, aggiungi aurora v2, aggiungi output con le ARN e le URL che mancano, aggiungi parametro per attivare/disattivare API e EventBridge ma di default abilitato
    4) ora calcolami i costi con Aurora
28) ora vorrei modificare il template e aggiungere un tag parametrico "esempio-12" a tutte le risorse che accettano i tag
    1) perchè hai tolto il ListNewFilesLambdaPermission ?


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*