#!/bin/bash
# chmod +x test_api.sh

# Esempio di script per testare le API REST del servizio WebSocket
# Assicurati di avere curl installato e di sostituire <API_ID> e
# Sostituisci con il tuo endpoint REST API (senza slash finale)

STACK_NAME="Esempio30WebSocket"
API_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='RestApiId'].OutputValue" --output text)
REGION=$(aws configure get region)

API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/Prod"
echo "API_URL: $API_URL"

echo "== Test: set_number =="
curl -s -X POST "$API_URL/set-number" \
  -H "Content-Type: application/json" \
  -d '{"nickname":"player3","number":42}'

echo -e "\n\n== Test: guess_number =="
curl -s -X POST "$API_URL/guess-number" \
  -H "Content-Type: application/json" \
  -d '{"attacker":"player3","guess":12}'

echo -e "\n\n== Test: get_scores =="
curl -s -X GET "$API_URL/scores"

echo -e "\n\n== Test: storico match =="
curl -s -X GET "$API_URL/admin/matches"

echo -e "\n\n== Test: ban user =="
curl -s -X POST "$API_URL/admin/ban" \
  -H "Content-Type: application/json" \
  -d '{"nickname":"player2","reason":"test ban"}'

echo -e "\n\n== Test: broadcast admin =="
curl -s -X POST "$API_URL/admin/broadcast" \
  -H "Content-Type: application/json" \
  -d '{"action":"broadcast","text":"Messaggio di test a tutti"}'

echo -e "\n\n== Test: reset numeri =="
curl -s -X POST "$API_URL/admin/reset-numbers" \
  -H "Content-Type: application/json" \
  -d '{"action":"reset_numbers"}'

echo -e "\n\n== Test completati =="