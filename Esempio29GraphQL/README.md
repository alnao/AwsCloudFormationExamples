# Esempio29GraphQL - Lista Note con AppSync, DynamoDB e Interfaccia Web
Voglio un Esempio29GraphQL dove crei una "listaNote", compreso database per salvare e una piccola interfaccia per lavorarci. scrivimi un README prendendo spunto da un altro esempio


Questo esempio mostra come creare una semplice applicazione "listaNote" utilizzando AWS AppSync (GraphQL), DynamoDB e una piccola interfaccia web statica.
- Visualizza tutte le note salvate
- Aggiungi una nuova nota
- Elimina una nota

## Risorse create
- **AppSync GraphQL API** con autenticazione tramite API Key
- **Tabella DynamoDB** per la memorizzazione delle note
- **Resolver** per le operazioni di query, inserimento e cancellazione note
- **Interfaccia web** (`index.html`) per interagire con l'API

## Deploy CloudFormation
* Comani per la creazione dello stack:
  ```
  sam build
  sam deploy --stack-name Esempio29GraphQL --capabilities CAPABILITY_NAMED_IAM --region eu-central-1
  aws cloudformation describe-stacks --stack-name Esempio29GraphQL
  ```
* Comandi per invocare il GraphQL con Curl:
  ```
  aws cloudformation describe-stacks --stack-name Esempio29GraphQL --query "Stacks[0].Outputs"
  API_URL="<GraphQLApiUrl dagli output>"
  API_KEY="<GraphQLApiKey dagli output>"
  curl -X POST "$API_URL" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query":"query { getNote { id testo } }"}'
  curl -X POST "$API_URL" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query":"mutation { addNota(testo: \"Test nota da CLI\") { id testo } }"}'
  curl -X POST "$API_URL" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query":"mutation { addNota(testo: \"Test nota da CLI\") { id testo } }"}'
  curl -X POST "$API_URL" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query":"mutation { deleteNota(id: \"<ID_NOTA>\") }"}'
  ```
* Comandi rimozione tutto
    ```
    sam delete --stack-name Esempio29GraphQL --region eu-central-1
    ```
* Configura l'interfaccia web:
   - Aprire `index.html` e sostituire i valori di `API_URL` e `API_KEY` con quelli ottenuti dagli output del template.
    ```
    const API_URL = 'INSERISCI_ENDPOINT_GRAPHQL';
    const API_KEY = 'INSERISCI_API_KEY';
    ```
   - Pubblicare la pagina su S3 static website hosting o aprirla localmente nel browser.


## Schema GraphQL
```graphql
type Nota {
  id: ID!
  testo: String!
}
type Query {
  getNote: [Nota]
}
type Mutation {
  addNota(testo: String!): Nota
  deleteNota(id: ID!): ID
}
```


## Note
- L'autenticazione è tramite API Key (solo per demo, non usare in produzione senza restrizioni aggiuntive).
- La tabella DynamoDB è in modalità on-demand (PAY_PER_REQUEST).
- **Costi previsti**:
  - **AppSync**: piano gratuito di 250.000 query/mese per 12 mesi. Oltre, circa $4/milione di query.
  - **DynamoDB**: on-demand, piano gratuito 25 GB storage e 200 milioni di richieste/mese per 12 mesi. Oltre, circa $1,25/milione di write e $0,25/milione di read.
  - **Esempio pratico**:
    - **Poche chiamate** (demo/test): rientri nel free tier, costo praticamente nullo.
    - **Tante chiamate** (es. 1 milione di query/mese):
      - AppSync: ~$4/mese
      - DynamoDB: ~$0,25/mese (solo read, se write sono molte di più, aggiungi $1,25/milione)
    - **Storage**: trascurabile per poche note.
  - **Altri costi**: eventuale S3 per hosting statico (free tier 5 GB/mese), traffico dati trascurabile per uso demo.
  - Al termine, eliminare lo stack CloudFormation per evitare costi ricorrenti.


# AlNao.it
Nessun contenuto in questo repository è stato creato con IA o automaticamente, tutto il codice è stato scritto con molta pazienza da Alberto Nao. Se il codice è stato preso da altri siti/progetti è sempre indicata la fonte. Per maggior informazioni visitare il sito [alnao.it](https://www.alnao.it/).

## License
Public projects 
<a href="https://it.wikipedia.org/wiki/GNU_General_Public_License"  valign="middle"><img src="https://img.shields.io/badge/License-GNU-blue" style="height:22px;"  valign="middle"></a> 
*Free Software!*


