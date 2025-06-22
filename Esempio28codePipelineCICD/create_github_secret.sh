#!/bin/bash

# Aborta lo script in caso di errori
set -eEuo pipefail

echo "--- Script per Creare il Secret GitHub in AWS Secrets Manager ---"

# --- Parametri configurabili ---
SECRET_NAME="github/codepipeline/token" # Nome del secret
AWS_REGION="eu-central-1"               # Regione AWS di default

# --- Input utente per il token GitHub ---
read -s -p "Inserisci il tuo GitHub Personal Access Token: " GITHUB_TOKEN
echo "" # Vai a capo dopo l'input nascosto

# Verifica che il token sia stato fornito
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Errore: Il GitHub Personal Access Token non può essere vuoto."
  exit 1
fi

export AWS_DEFAULT_REGION="$AWS_REGION"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Regione AWS impostata su: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"

echo "Creazione/Aggiornamento del secret '${SECRET_NAME}' in Secrets Manager..."

# Cerca se il secret esiste già
SECRET_EXISTS=$(aws secretsmanager describe-secret \
  --secret-id "${SECRET_NAME}" \
  --query 'ARN' \
  --output text \
  --region "${AWS_REGION}" 2>/dev/null || true)

if [[ -z "$SECRET_EXISTS" ]] || [[ "$SECRET_EXISTS" == "None" ]]; then
  # Crea il secret con il tag
  aws secretsmanager create-secret \
    --name "${SECRET_NAME}" \
    --description "GitHub Personal Access Token for CodePipeline" \
    --secret-string "${GITHUB_TOKEN}" \
    --tags Key=GlobalTag,Value=AlNaoGlobal \
    --region "${AWS_REGION}"
else
  # Aggiorna il secret con il tag (se il tag non c'è già, lo aggiunge)
  aws secretsmanager update-secret \
    --secret-id "${SECRET_NAME}" \
    --secret-string "${GITHUB_TOKEN}" \
    --region "${AWS_REGION}"
  # Aggiungi il tag separatamente se update-secret non lo supporta direttamente (o per assicurarne la presenza)
  aws secretsmanager tag-resource \
    --secret-id "${SECRET_NAME}" \
    --tags Key=GlobalTag,Value=AlNaoGlobal \
    --region "${AWS_REGION}" || true # Permetti che fallisca se il tag esiste già
fi

echo "Secret '${SECRET_NAME}' creato/aggiornato con successo in AWS Secrets Manager."
echo "ARN del Secret: $(aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --query 'ARN' --output text --region "${AWS_REGION}")"
echo ""
echo "Questo secret sarà utilizzato dalla CodePipeline per autenticarsi con GitHub."


# aws secretsmanager describe-secret --secret-id "github/codepipeline/token" --query '{ARN:ARN, Name:Name}'