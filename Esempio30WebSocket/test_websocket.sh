#!/bin/bash
# Script per testare la connessione WebSocket con wscat

# npm install -g wscat

STACK_NAME="esempio30-stack"
REGION=$(aws configure get region)
WS_API_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='WebSocketApiId'].OutputValue" --output text)

WS_URL="wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/esempio30"

# Controlla che wscat sia installato
if ! command -v wscat &> /dev/null; then
    echo "wscat non trovato! Installa con: npm install -g wscat"
    exit 1
fi

echo "== Invio automatico di ping, broadcast e set_number =="
wscat -c "$WS_URL" <<EOF
{"action":"ping"}
{"action":"broadcast","text":"Ciao a tutti!"}
{"action":"set_number","nickname":"player1","number":123456}
EOF

echo "== Connessione interattiva a $WS_URL =="
echo "Premi Ctrl+C per uscire. Puoi digitare/incollare altri messaggi JSON. Esempi:"
echo '{"action":"reset_numbers"}'
echo '{"action":"guess_number","attacker":"player1","target":"player2","guess":654321}'
echo

wscat -c "$WS_URL"

# Questo script invia i messaggi in sequenza e poi apre una connessione interattiva.
# Puoi inviare manualmente altri messaggi o semplicemente ascoltare le notifiche push.