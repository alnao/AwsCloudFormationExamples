# Esempio30WebSocket - Gioco ad "indovina il numero"


Questo gioco è un esempio didattico realizzato con i principali servizi AWS, l'esecuzione di questa infrastruttura su AWS potrebbe causare l'addebito dei servizi usati.


Attenzione: Il gioco non prevede nessun sistema di autenticazione/autorizzazione.


Esiste anche una versione sviluppata in Java di tipo Cloud-agnostic disponibile al repository
```
https://github.com/alnao/JavaSpringBootExample
```


## Struttura e Componenti del Progetto
1. CloudFormation Template (`template.yaml`)
    - Definisce tutte le risorse AWS necessarie: DynamoDB, Lambda, API Gateway REST e WebSocket, S3 per hosting statico.
    - Parametrizzazione dei nomi delle tabelle, limiti e dello stage per ambienti multipli.
    - Runtime Lambda impostato a Python 3.11, architettura ARM64 per efficienza.
    - Gestione centralizzata delle variabili d’ambiente per ogni funzione.
    - Policy IAM minime per ogni Lambda (DynamoDB, CloudWatch Logs, execute-api:ManageConnections).
    - Lambda Permission per invocazione sicura da API Gateway.
    - CloudWatch Log Group configurato per REST e WebSocket API.
2. DynamoDB Tables
    - `PlayersTable`: memorizza i dati dei giocatori (nickname, stato, numero scelto, ecc.).
    - `MatchesTable`: storico dei match e delle giocate. Gestione conversione tipi numerici per compatibilità JSON.
    - `LogsTable`: logging centralizzato di tutti gli eventi e azioni.
    - `BansTable`: gestisce utenti bannati e motivazioni.
3. Lambda Functions (`functions/`)
    - Tutte le Lambda sono in un'unica cartella, con validazione input e risposta HTTP centralizzate in `utils.py`.
    - `connect.py` / `disconnect.py`: gestiscono connessioni/disconnessioni WebSocket e aggiornano lo stato del giocatore.
    - `set_number.py`: permette al giocatore di scegliere/cambiare il proprio numero (con limite giornaliero e controllo univocità).
    - `guess_number.py`: logica di gioco per indovinare il numero di altri giocatori. Penalità: il giocatore colpito non viene eliminato ma subisce azzeramento numero, -10 punti e lastUpdate retrodatato.
    - `get_scores.py`: restituisce la classifica aggiornata.
    - `ban_user.py`: endpoint di amministrazione per bannare utenti e notificare via WebSocket.
    - `get_match_log.py`: API per consultare lo storico dei match, con conversione automatica dei tipi numerici.
    - `match_control.py`: funzioni avanzate di amministrazione (broadcast messaggi, reset numeri).
    - `cleanup_inactive.py`: Lambda per rimozione automatica utenti inattivi da più di X giorni.
    - `log_event.py`: logging centralizzato su DynamoDB.
    - `cors_options.py`: Lambda dedicata per rispondere a tutte le richieste OPTIONS e gestire il CORS REST in modo centralizzato.
    - `utils.py`: funzioni di utilità (validazione input, risposta HTTP uniforme, header CORS, ecc.).
4. API Gateway
    - REST API: endpoint per amministrazione, classifica, storico match, ban, ecc. CORS gestito globalmente tramite Lambda dedicata e header uniformi.
    - WebSocket API: comunicazione in tempo reale per notifiche di gioco e amministrazione. Route $default per gestire messaggi generici (es. nickname).
5. Sicurezza e Validazione
    - Validazione input lato Lambda (nickname, numero scelto, limiti giornalieri, tentativi, ecc.).
    - Logging di tutte le azioni e errori in una tabella dedicata.
    - Gestione ban e utenti inattivi.
    - Permessi IAM minimi e Lambda Permission per sicurezza.
    - **il gioco non prevede un sistema di autenticazione/autorizzazione** *coming soon?*
6. Logging
    - Tutte le azioni e gli errori sono loggati in una tabella DynamoDB dedicata (`LogsTable`).
    - CloudWatch Log Group configurato per REST e WebSocket API.
7. Frontend
    - Pagine HTML/JS in `frontend/` (admin, user, game, index, error) con Bootstrap.
    - La pagina admin mostra lo storico completo dei match (con paginazione lato backend se necessario).
    - Tutte le chiamate fetch gestiscono errori e CORS in modo robusto.
    - Aggiornare gli endpoint API e WebSocket nei file frontend dopo il deploy.
8. Deploy
    - Bucket S3 configurato per hosting statico sicuro (solo HTTPS, policy restrittiva).
    - Comandi per build, deploy, pulizia e caricamento file frontend documentati nella sezione Deploy.
9. Best Practice
    - Applicate best practice su permessi minimi, logging, validazione input, gestione errori e CORS.
    - Tutte le risorse principali sono taggate per tracciabilità.


## Deploy su AWS
* Comandi per la creazione dell'esempio
    ```
    sam validate
    sam build
    sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao
    sam deploy --template-file packagedV1.yaml --stack-name Esempio30WebSocket --capabilities CAPABILITY_IAM
    ```
* Comando per verificare il template:
    ```
    aws cloudformation describe-stacks --stack-name Esempio30WebSocket --query "Stacks[0].Outputs"
    ```
* Comandi per caricare i file nel bucket
    ```
    BUCKET_NAME="esempio30-website-bucket"
    aws s3 cp ./frontend "s3://$BUCKET_NAME/" --recursive
        # Se vuoi che i file siano pubblicamente leggibili (già consentito dalla bucket policy, ma puoi forzare i permessi oggetto):
        aws s3 cp ./frontend "s3://$BUCKET_NAME/" --recursive --acl public-read
    ```
    - prima di essere caricati devono essere modificati sostituendo i valori delle API e WebSocket con gli indirizzi corretti creati e ritornati da CloudFormation
    - nell'attuale versione del template le pagine potrebbero non funzionare per errore di permessi
* Comandi per la rimozione totale
    ```
    # 1. Svuota il bucket S3 (necessario prima di eliminare lo stack)
    BUCKET_NAME="esempio30-website-bucket"
    aws s3 rm "s3://$BUCKET_NAME" --recursive
    
    # 2. Elimina lo stack CloudFormation (elimina tutte le risorse)
    aws cloudformation delete-stack --stack-name Esempio30WebSocket
    
    # 3. Verifica che lo stack sia stato eliminato
    aws cloudformation describe-stacks --stack-name Esempio30WEbSocket
    # Dovrebbe restituire errore "does not exist" quando completato
    
    # 4. Opzionale: elimina manualmente eventuali log group rimasti
    aws logs describe-log-groups --log-group-name-prefix "/aws/apigateway/" --query "logGroups[].logGroupName" --output text | tr '\t' '\n' | xargs -r -n 1 aws logs delete-log-group --log-group-name
    aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/" --query "logGroups[].logGroupName" --output text | tr '\t' '\n' | xargs -r -n 1 aws logs delete-log-group --log-group-name
    ```

## Stima dei costi
1. DynamoDB: Tabella on-demand (PAY_PER_REQUEST):
    - 10 utenti: pochissime letture/scritture, costo trascurabile (probabilmente sotto 1-2 €/mese).
    - 10.000 utenti: se ogni utente fa 100 operazioni/giorno → 1 milione di request/mese ≈ 1,25 €/mese (letture) + 6,5 €/mese (scritture).
    - Storage: 1 GB ≈ 0,25 €/mese (dati e log).
2. AWS Lambda
    - 10 utenti: chiamate Lambda molto basse, probabilmente gratis (rientra nel free tier: 1 milione di invocazioni/mese e 400.000 GB-sec/mese).
    - 10.000 utenti: supponiamo 1 milione di invocazioni/mese, 128 MB, 100 ms → circa 0,20 €/mese (oltre il free tier).
3. API Gateway (REST + WebSocket): REST API: 3,50 €/milione di chiamatee e WebSocket API: 1,00 €/milione di messaggi + 0,25 €/connessione/ora.
    - 10 utenti: costo trascurabile, sotto 1 €/mese.
    - 10.000 utenti: 10.000 connessioni * 24h * 30gg = 7,2 milioni di connessioni-ora ≈ 1.800 €/mese solo per WebSocket (0,25 €/connessione/ora).
    - Messaggi: 10.000 utenti * 100 msg/giorno * 30 = 30 milioni di msg/mese ≈ 30 €/mese.
4. S3 (hosting statico)
    - Storage: 1 GB ≈ 0,025 €/mese.
    - Traffic: 10 GB/mese ≈ 1 €/mese.
5. CloudWatch Logs
    - Log storage: 1 GB ≈ 0,10 €/mese.
    - Log ingestion: trascurabile per questi volu
6. Riepilogo mensile (stima, prezzi nella region *EU-Central*, agosto 2025)
    | Servizio         | 10 utenti         | 10.000 utenti         |
    |------------------|-------------------|-----------------------|
    | DynamoDB         | < 1 €             | 8 €                   |
    | Lambda           | 0 € (free tier)   | 0,20 €                |
    | API Gateway REST | < 1 €             | 10 €                  |
    | API Gateway WS   | < 1 €             | 1.800 € (connessioni) |
    | S3               | < 1 €             | 1 €                   |
    | CloudWatch Logs  | < 1 €             | 1 €                   |
    | **Totale**       | **~3-4 €**        | **~1.820 €**          |
    - Il costo delle WebSocket API cresce linearmente con le connessioni attive (0,25 €/connessione/ora). Per 10 utenti il costo è trascurabile, per 10.000 utenti il costo delle WebSocket API è molto alto. Se vuoi scalare a molti utenti, valuta soluzioni alternative (es. Amazon Elasticache, AppSync, MQTT, o architetture ibride).
    - In fondo alla chiacchierata con GitHub Copilot sono presenti alcune alternative molto più economiche.


## Chiacchieraa con GitHub Copilot
1) Creazione files
    - mi dici quale lo standard/protocollo per fare uno stream di dati tra server e client pensando ad un server su AWS eclient sito web/applicazione/dispositivo ?
    - ok vorrei usare WebSocket per trasmettere dati da un server ad un client, tipo un gioco, con una serie di utenti collegati, ogni giocatore può dire un numero o cambiare il precedente, un giocatore vince la partita quando indovina il numero di un qualsiasi altro giocatore, inizialmente i giocatori non hanno un numero di default ma vengono eliminati se non dicono un numero entro un minuto, ogni giocatore deve cambiare numero ogni 3 ore altrimenti viene eliminato. vorrei creare tutto questo con un bel template cloudformation, se ti serve un linguaggio usa python
    - vorrei anche una sezione amministrativa in modo che un amministratore possa verificare quanti giocatori siano attivi, quando un giocatore vince la manche finisce e tutti devono essere avvisati quale giocatore ha vinto e possono rincominicare un altro match con lo stesso numero o cambiarlo, il giocatore che ha visto il suo numero indovinato viene rimosso dal gioco, voglio una lista di tutti i match e di quale giocatore ha vinto, quale giocatore ha perso e quale era il numero. per ora non generare nulla 
    - ho deciso di cambiare le logiche: il giocatore quando si collega deve scegliere un numero che poi può modificare e non c'è più il limite di un 1 minuto, inoltre voglio che il limite di 3 ore diventi di 42 giorni (che sarà un parametro nel template cloudformation). non creare nulla ma dammi qualche idea per migliorare il tutto
    - bene: creami il sistema di punteggio (ogni utente può andare anche negativo), ci sarà una api per controllare il punteggio di tutti, concordo che si può modificare il numero al massimo 5 volte al giorno, per ora voglio una sola stanza pubblica, voglio che un utente sia identificato da un nickname (in futuro sarà credenziale ma per ora non pensiamoci). voglio le notifiche dirette e lo stato del gioco, voglio la divisione tra websocket e rest api, voglio un id univocolo per il match attivo, voglio che ogni operazione venga loccata in tabelle di log (come esportazione storico). concordo che tutto deve essere parametrico nel template, voglio un sistema che l'admin possa bannare un utente su una tabella ban con notivia all'utente che è stato bannato e il motivo. ora creami il template cloudformation, per lambda e api usa i tipi servless e il codice python lo voglio separato
    - ora creami lista comandi linux per creare i file python (anche vuoti)
    - creami i file python *fermato perchè superato il limite giornaliero di richieste*
2) ciao , la cartella Esempio30 è un progetto cloudformation per creare in AWS un mini-gioco dove i giocatori devono indovinare il numero che hanno impostato gli altri giornicatori, le regole sono: un giocarore si iscrive con nickName e numero, un giocatore fa un punto quando indovina il numero di un altro e quando succede il giocatore indovinato perde un punto, un giocatore deve cambiare numero ogni X giorni (parametrico), un giocatore può cabmiare numero Y volte al giorno (parametrico), parte amministrativa con ban e visualizzazione dei numeri attuali, tabella di log dove salvato tutto, lista di tutti i match eseguiti con chi ha vinto e chi perso, sistema punteggio con lista attuale con api, solo una stanza pubblica, lambda scritte in python
    - nel template ci sono le lambda permission? aggiungi le policy per Dynamo e per il log di CloudWatch
    - ora voglio spostare tutti i file python nella cartella function senza sotto cartellle, procedi
    - ma spiegami connect e disconnect, funzionano? hanno lo scopo di permettere ad un giocatore di entrare nel gioco e collegarsi al WebSocket dove il sistema avvisa il giocatore se delle notifiche
    - verifica i parametri nel template cloudformation che vengono passati alle lambda che hai appena modificato
    - ora, ri-analizza tutto il codice e tutti i file della cartella Esempio30* e dimmi cosa c'è da correggere e come potrei migliorare il gioco
    - bene allora vorrei che mi facessi queste modifiche: uniforma gli errori e risposte HTTP, aggiungi requirements con gli import che mancano, valida gli imput per esempio il nickname deve essere di almeno 5 e massimo 30 caratteri, il numero deve essere intero maggiore di zero di massimo 6 cifre, aggiungi notifica websocket per quando un giocatore vince e viene vannato e viene beccato, quando un giocatore viene beccato il suo numero diventa zero , pulisci tutti gli utenti e disconnettili dopo 10 giorni che non modificano il numero da almeno 10 giorni, centralizza il loggin di tutte le lambda e in una unica tabella dynamo, fammi una api per storico dei match, 
    - ricontrolla tutti i file python e verifica che nel cloudFormation ci siano tutti i parametri (per esempio nella ban manca WS_ENDPOINT), poi controlla su tutti i file python se hanno tutti gli import
    - scusami, controlla la ban_user e verifica quali sono i parametri e controlla se il template cloudformation gli passa tutto
    - capito, voglio dei metodi: primo per inviare un messaggio a tutti gli utenti di tipo testuale, poi voglio uno per fare reset di tutti i numeri a zero così il gioco riparte da zero e ora nel template CloudFormation voglio aggiungere le chiamate ai metodi appena creati
    - il "prod" nelle API deve essere parametrico e valore di default "esempio30", modifica anche i valori di default delle tabelle dynamo e metti "esempio30-" prima dei valori, voglio usare python3.11
3) aggiungi nel README.md spiegazione di ogni parte che abbiamo sviliuppato
4) ho trovato un errore: nel guess_number togli il target perchè voglio che l'attacker provi con tutti i giocatori attivi (non bannati)
    - nella guuess_number hai aggiunto tabelle che devo aggiungere anche nel template?
        - e la BANS_TABLE ? 
        - **allucinazione perchè si era perso questo parametro che aveva aggiunto nel python ma non nel template**
    - con questo template mi controlli che tutte le lambda abbiano i parametri in Environment e che non usano i valori di default nel python ?
    - nella set_number aggiungi contro che il numero non deve essere già presente, se già presente non fare nulla e ritorna errore perchè il giocatore non può entrare in partita
    - nella guess voglio aggiungere un controllo che un utente può eseguire un numero massimo di chiamate MAX_CHANGES_PER_DAY = int(os.environ.get('MAX_CHANGES_PER_DAY', 5))
    - nella set_number voglio che imponi il limite che si possa cambiare solo dopo le 24 ore dall'ultimo cambio
5) ora, con tutti i files che hai, mi crei un piccolo frontend in html/javascript usando la libreria grafica bootstrap per l'amministratore, crea una cartella frontend con un file admin.html: Broadcast a tutti i giocatori, Reset di tutti i numeri, Ban di un utente (nickname e motivo) e Visualizzazione dello storico match
    - ora vorrei una pagina user che visualizza tutti gli altri dati, cre un file admin.html sempre usando html/javascript e la libreria grafica bootstrap: Classifica aggiornata, Storico match, Lista giocatori attivi e Log eventi
    - ora vorrei un file game.html che permetta da un giocatore di giocare
    - modifica la game perchè prima un utente deve connettersi selezionando il suo nick, poi non può più modificarlo
    - ora modifica in modo che la connectWS sia chiamata automaticamente quando le la connectUser va a buon fine, poi aggiungi anche la disconnect
    - ok ma mi controlli che se uno chiama la disconnectWS poi non può fare altro e deve connectUser ?
    - nel template aggiungi un Bucket dove caricare i file HTML e che siano esposti come sito web pubblico (senza cloudFront), grazie
    - ora creami una bellissima index.html che pubblicizza questo gioco e che permetta di accedere al game.html e che permetta di accedere alla user.html , usa html/javascript con libreria grafica bootstrap, crea anche una error.html triste
    
6) analizza una cosa: se un utente si collega e imposta un numero ma poi chiude il browser senza fare disconnect, cosa succede?
Se un utente si collega, imposta un numero e poi chiude il browser senza fare disconnect:
    - La connessione WebSocket viene chiusa automaticamente dal browser: Se la tua Lambda associata alla route $disconnect di API Gateway è configurata correttamente, riceverà l’evento di disconnessione e potrà aggiornare lo stato del giocatore (es. rimuovere il connectionId dal record DynamoDB).
    - Il giocatore rimane nella tabella: Il nickname, il numero e lo stato del giocatore restano salvati in DynamoDB. Il giocatore non viene eliminato solo perché ha chiuso il browser. Il giocatore risulta ancora “attivo” per il sistema, finché non viene eliminato da una regola di cleanup (es. inattività > X giorni) o da un altro giocatore che indovina il suo numero.
    - Se vuoi che la disconnessione comporti anche la rimozione del giocatore dal gioco, dovresti modificare la Lambda di disconnect per eliminare il record del giocatore, ma così facendo perderesti la persistenza tra sessioni.
    - In sintesi: il giocatore resta nel gioco (con nickname e numero) anche se chiude il browser senza fare disconnect, ma non riceverà più notifiche in tempo reale finché non si riconnette.
7) eseguite diverse modifiche al template per permessi mancanti, stage websocket mancante (che poi funzia), tante bestemmie e tante discussioni con una IA spesso con allucinazioni!
8) eseguite diverse modifiche al template per la gestione del CORS: infatti usare l'APIGateway è un *casino*: aggiunta regola IAM poi tolta, infine aggiunta una lambda dedicata con la regola `{proxy+}`, poi modificato il utils.py *perdendo un sacco di tempo*
9) alla fine funziona con modifiche anche manuali
10) Revisione dei costi: dammi alternative più economiche al WebSocket ma con sempre la possiblità di avere un sistema che invia messaggi ai giocatori
    1. Amazon SNS + Polling
        Ogni giocatore si iscrive a un topic SNS (o a un endpoint HTTP personale).
        Le Lambda pubblicano messaggi su SNS.
        I client fanno polling periodico (es. ogni 5-10 secondi) su una REST API per ricevere nuovi messaggi.
        Pro: Costi bassissimi, semplice, scalabile.
        Contro: Non è realtime puro, ma “quasi realtime” (dipende dalla frequenza di polling).
    2. REST API + Long Polling
        I client fanno richieste REST (es. /messages) che restano aperte fino a quando arriva un messaggio o scade il timeout.
        Quando c’è un evento, la Lambda risponde subito.
        Pro: Più reattivo del polling classico, costi solo di REST API.
        Contro: Più complesso da gestire lato client/server, ma molto più economico di WebSocket.
    3. Amazon AppSync (GraphQL Subscriptions)
        AppSync supporta le subscription (push) via WebSocket, ma con costi molto più bassi e scalabilità migliore rispetto ad API Gateway WebSocket.
        Pro: Più economico, gestito, supporta anche fallback su polling.
        Contro: Richiede GraphQL, un po’ di apprendimento.
    4. Amazon SQS + Polling
        Ogni giocatore ha una coda SQS personale o una coda condivisa con filtro.
        Le Lambda inviano messaggi su SQS.
        I client fanno polling REST su una Lambda che legge da SQS.
        Pro: Costi molto bassi, affidabile.
        Contro: Non è push puro, ma polling.
    5. Server-Sent Events (SSE)
        REST API che tiene aperta una connessione HTTP e invia eventi dal server al client.
        Pro: Più semplice e meno costoso di WebSocket, supportato da molti browser.
        Contro: Solo server→client, non bidirezionale.
    - In sintesi: Per costi minimi su AWS, la soluzione REST API + polling (o long polling) è la più semplice e scalabile. Se vuoi push vero e costi bassi, valuta AppSync o SSE.


# AlNao.it
Tutti i codici sorgente e le informazioni presenti in questo repository sono frutto di un attento e paziente lavoro di sviluppo da parte di Alberto Nao, che si è impegnato a verificarne la correttezza nella misura massima possibile. Qualora parte del codice o dei contenuti sia stato tratto da fonti esterne, la relativa provenienza viene sempre citata, nel rispetto della trasparenza e della proprietà intellettuale. 


Alcuni contenuti e porzioni di codice presenti in questo repository sono stati realizzati anche grazie al supporto di strumenti di intelligenza artificiale, il cui contributo ha permesso di arricchire e velocizzare la produzione del materiale. Ogni informazione e frammento di codice è stato comunque attentamente verificato e validato, con l’obiettivo di garantire la massima qualità e affidabilità dei contenuti offerti. 


Per ulteriori dettagli, approfondimenti o richieste di chiarimento, si invita a consultare il sito [alnao.it](https://www.alnao.it/).


## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*

E' garantito il permesso di copiare, distribuire e/o modificare questo documento in base ai termini della GNU Free Documentation License, Versione 1.2 o ogni versione successiva pubblicata dalla Free Software Foundation. Permission is granted to copy, distribute and/or modify this document under the terms of the GNU Free Documentation License, Version 1.2 or any later version published by the Free Software Foundation.



