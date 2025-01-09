# AWS CloudFormation Examples - 26 Blockchain in lambda
AWS CloudFormation Examples by [AlNao](https://www.alnao.it)

Creazione e gestione di una rete BlockChain con sistema di blocci con algormito **proof of work** con bassa difficoltà *per spendere meno*.

## CloudFormation
* Comani per la creazione dello stack senza SAM ma usando il comando **AWS CLI** diretto:
- Creazione dello stack
  ```
  aws cloudformation create-stack --stack-name es26-bc-stack --template-body file://blockchain.yaml --capabilities CAPABILITY_IAM
  aws cloudformation wait stack-create-complete --stack-name es26-bc-stack
  aws cloudformation describe-stacks --stack-name es26-bc-stack
  ```
- Modifica di uno stack
  ```
  aws cloudformation update-stack --stack-name es26-bc-stack --template-body file://blockchain.yaml --capabilities CAPABILITY_IAM
  ```
- Distruzione di uno stack
  ```
  aws cloudformation delete-stack --stack-name es26-bc-stack
  aws cloudformation wait stack-delete-complete --stack-name es26-bc-stack
  ```
- Impostazione dell'URL dell'API in una variabile
  ```
  set API_URL=https://xxxxxxxx.execute-api.eu-west-1.amazonaws.com/dev
  ```
- Aggiunta di transazioni
  ```
  curl -X POST %API_URL%/transaction -H "Content-Type: application/json" -d "{\"sender\":\"Root\",\"recipient\":\"Nao\",\"amount\":1984}"
  curl -X POST %API_URL%/transaction -H "Content-Type: application/json" -d "{\"sender\":\"Nao\",\"recipient\":\"Alice\",\"amount\":50}"
  curl -X POST %API_URL%/transaction -H "Content-Type: application/json" -d "{\"sender\":\"Nao\",\"recipient\":\"Vale\",\"amount\":42}"
  ```
- Esecuzione di mining per creazione di un nuovo blocco
  ```
  curl -X POST %API_URL%/mine
  ```
- Recupero di tutte le transazioni
  ```
  curl %API_URL%/transactions
  ```
- Recupero di tutti i saldi
  ```
  curl %API_URL%/balances
  ```

## Comandi eseguiti da Claude
- come creare una blockchain in aws ?
- e se invece volessi fare una blockchain senza usare Amazon Managed Blockchain?
- ma se volessi usare aws lambda?
- e se volessi usare CloudFormation ?
- vorrei modificare il tutto con le seguenti modifiche. primo: nella tabella delle transazioni non cancellare quando una transazione è minata ma mettila in stato eseguito, secondo: le transazioni eseguite non devono essere più minate, terzo: api per recuperare tutte le transazioni con la proprietà se è minata, quarto: api per recuperare il saldo di tutti gli address
- quando una transazione viene minata deve essere salvato l'informazione dell'indice del blocco
- nelle lambda aggiungi un po' di log
- dammi la BlockchainLambdaRole:
- dammi i comandi da eseguire per testare tutto
- nella lambda, vorrei aggiungere il nome dello stack nel FunctionName
- i metodi mine e transactions mi dicono {"error": "Object of type Decimal is not JSON serializable"}
- il metodo "mine" mi da ancora errore {"error": "Object of type Decimal is not JSON serializable"}, sistema e ridammi il codice completo
- ora che funziona tutto, creami una pagina html con grafica bootstrap e che usi javascript per chiamare le api, come prima riga ci deve essere la definizione dell'url della api, fammi 4 tab, ogni uno per ogni metodo
- mi dice "from origin 'null' has been blocked by CORS policy: No 'Access-Control-Allow-Origin'", come risolvo?
- riesci a ridarmi tutto il template cloudformation ? 
- no, ridammi tutto il template mettendo il codice lambda in file py separati **errore perchè non si può**
- no, torniamo indietro: mettiamo il codice python dentro al template cloudformation, ridammi solo AddTransactionFunction
- ora dammi il MineBlockFunction
- ora dammi il GetTransactionsFunction
- ora dammi il GetAllBalancesFunction
- *rimesso assieme il template e ora funziona*

# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


