# Esempio30WebSocket - Gioco ad "indovina il numero"

*Esempio in fase di sviluppo*

## Struttura e Componenti del Progetto
1. CloudFormation Template (template.yaml)
    - Definisce tutte le risorse AWS necessarie: DynamoDB, Lambda, API Gateway REST e WebSocket.
    - Parametrizzazione dei nomi delle tabelle e dello stage per ambienti multipli.
    - Runtime Lambda impostato a Python 3.11, architettura ARM64 per efficienza.
    - Gestione centralizzata delle variabili d’ambiente per ogni funzione.
2. DynamoDB Tables
    - PlayersTable: memorizza i dati dei giocatori (nickname, stato, numero scelto, ecc.).
    - MatchesTable: storico dei match e delle giocate.
    - LogsTable: logging centralizzato di tutti gli eventi e azioni.
    - BansTable: gestisce utenti bannati e motivazioni.
3. Lambda Functions (functions_flat/)
    - connect.py / disconnect.py: gestiscono connessioni/disconnessioni WebSocket.
    - set_number.py: permette al giocatore di scegliere/cambiare il proprio numero (con limite giornaliero).
    - guess_number.py: logica di gioco per indovinare il numero di altri giocatori.
    - get_scores.py: restituisce la classifica aggiornata.
    - ban_user.py: endpoint di amministrazione per bannare utenti e notificare via WebSocket.
    - get_match_log.py: API per consultare lo storico dei match.
    - match_control.py: funzioni avanzate di amministrazione (broadcast messaggi, reset numeri).
    - cleanup_inactive.py: Lambda per rimozione automatica utenti inattivi da più di X giorni.
    - log_event.py: logging centralizzato su DynamoDB.
    - utils.py: funzioni di utilità (validazione input, risposta HTTP uniforme, ecc.).
4. API Gateway
    - REST API: endpoint per amministrazione, classifica, storico match, ban, ecc.
    - WebSocket API: comunicazione in tempo reale per notifiche di gioco e amministrazione.
5. Sicurezza e Validazione
    - Validazione input lato Lambda (nickname, numero scelto).
    - Logging di tutte le azioni e errori.
    - Gestione ban e utenti inattivi.
6. Parametri e Configurazione
    - Tutti i nomi delle risorse e limiti sono parametrizzati per ambienti diversi.
    - Facile estensione per nuove funzioni o endpoint.
    - In Output gli URL WebSocket e REST API forniti come output del template per integrazione client.




## Chiacchieraa con GitHub - Copilot

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


