# Esempio29GraphQL - Lista Note con AppSync, DynamoDB e Interfaccia Web

*Esempio in fase di sviluppo*
- ora voglio un Esempio29GraphQL dove crei una "listaNote", compreso database per salvare e una piccola interfaccia per lavorarci. scrivimi un README prendendo spunto da un altro esempio


Questo esempio mostra come creare una semplice applicazione "listaNote" utilizzando AWS AppSync (GraphQL), DynamoDB e una piccola interfaccia web statica.
- Visualizza tutte le note salvate
- Aggiungi una nuova nota
- Elimina una nota

## Risorse create
- **AppSync GraphQL API** con autenticazione tramite API Key
- **Tabella DynamoDB** per la memorizzazione delle note
- **Resolver** per le operazioni di query, inserimento e cancellazione note
- **Interfaccia web** (`index.html`) per interagire con l'API

## Deploy
1. **Deploy del template CloudFormation**
   - Carica e avvia `template.yaml` tramite la console AWS CloudFormation o AWS CLI.
2. **Recupera i parametri di output**
   - Dopo il deploy, prendi l'endpoint GraphQL (`GraphQLApiUrl`) e la API Key (`GraphQLApiKey`) dagli output dello stack.
3. **Configura l'interfaccia web**
   - Apri `index.html` e sostituisci i valori di `API_URL` e `API_KEY` con quelli ottenuti dagli output.
   - Puoi pubblicare la pagina su S3 static website hosting o aprirla localmente nel browser.


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
