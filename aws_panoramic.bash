#!/bin/bash
# 
# TO RUN "source aws_panoramic.bash"

# Script per Esportare Variabili d'Ambiente con Informazioni sulle Risorse AWS
# Questo script recupera ID e dettagli di varie risorse AWS (VPC di Default,
# Subnet, Internet Gateway, NAT Gateway, Security Groups, ECR, EKS, EC2, RDS,
# S3, CloudFront, CloudFormation, CloudWatch, Lambda, DynamoDB, SQS, SNS, API Gateway)
# e li esporta come variabili d'ambiente.

# --- Variabili Globali (Configurabili) ---
export AWS_REGION="eu-central-1" # Sostituisci con la tua regione AWS preferita

echo "Inizio della raccolta delle informazioni sulle risorse AWS nella regione: $AWS_REGION"
echo "Assicurati di aver configurato l'AWS CLI con le credenziali appropriate."
echo "----------------------------------------------------------------------"

# --- Funzioni di Utilità ---
function export_variable() {
  local var_name="$1"
  local var_value="$2"
  # Sostituisce spazi con underscore per nomi di variabili validi
  local clean_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]_' '_')
  echo "export $clean_var_name=\"$var_value\""
}
function print_section_header() {
  local var_name="$1"
  local var_value="$2"
  # Sostituisce spazi con underscore per nomi di variabili validi
  local clean_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]_' '_')
  echo "export $clean_var_name=\"$var_value\""
}

# --- 1. Recupero Componenti di Rete della VPC di Default ---
echo "Recupero informazioni sulla VPC di Default..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text 2>/dev/null)

if [ -z "$VPC_ID" ]; then
  echo "Nessuna VPC di default trovata nella regione $AWS_REGION. Impossibile procedere con le risorse dipendenti dalla VPC."
  # Non usciamo qui, ma le variabili dipendenti saranno vuote.
else
  echo $(export_variable "VPC_ID" "$VPC_ID")
  VPC_CIDR_BLOCK=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].CidrBlock' --output text)
  echo $(export_variable "VPC_CIDR_BLOCK" "$VPC_CIDR_BLOCK")

  # Subnet Pubbliche
  PUBLIC_SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
    --query 'Subnets[*].SubnetId' \
    --output text | tr '\t' ',')
  echo $(export_variable "PUBLIC_SUBNET_IDS" "$PUBLIC_SUBNET_IDS")

  # Subnet Private
  PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=false" \
    --query 'Subnets[*].SubnetId' \
    --output text | tr '\t' ',')
  # Fallback: se non ci sono subnet private esplicite, usiamo le pubbliche (con avviso)
  if [ -z "$PRIVATE_SUBNET_IDS" ]; then
    PRIVATE_SUBNET_IDS=$PUBLIC_SUBNET_IDS
    echo "Attenzione: Nessuna subnet privata distinta trovata nella VPC di default. Le risorse che preferirebbero subnet private useranno quelle pubbliche."
  fi
  echo $(export_variable "PRIVATE_SUBNET_IDS" "$PRIVATE_SUBNET_IDS")

  # Internet Gateway
  IGW_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text 2>/dev/null)
  echo $(export_variable "IGW_ID" "$IGW_ID")

  # NAT Gateway
  NAT_GATEWAY_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[0].NatGatewayId' \
    --output text 2>/dev/null)
  echo $(export_variable "NAT_GATEWAY_ID" "$NAT_GATEWAY_ID")
fi

# --- 2. Security Groups ---
echo "Recupero tutti i Security Groups..."
ALL_SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].GroupId' \
  --output text | tr '\t' ',')
echo $(export_variable "ALL_SECURITY_GROUP_IDS" "$ALL_SECURITY_GROUP_IDS")

# --- 3. Repository ECR ---
echo "Recupero tutti i repository ECR..."
ECR_REPOS=$(aws ecr describe-repositories \
  --query 'repositories[*].repositoryUri' \
  --output text | tr '\t' '\n' | paste -s -d ',' -) # Unisce su una singola riga separata da virgole
echo $(export_variable "ECR_REPOS" "$ECR_REPOS")

# --- 4. Cluster EKS e Nodi ---
echo "Recupero tutti i cluster EKS e i loro nodi..."
EKS_CLUSTERS=$(aws eks list-clusters \
  --query 'clusters[*]' \
  --output text | tr '\t' ',')
echo $(export_variable "EKS_CLUSTERS" "$EKS_CLUSTERS")

# Inizializza una variabile per i nodi EKS
ALL_EKS_NODES=""

if [ -n "$EKS_CLUSTERS" ]; then
  IFS=',' read -ra CLUSTER_ARRAY <<< "$EKS_CLUSTERS"
  for CLUSTER_NAME in "${CLUSTER_ARRAY[@]}"; do
    echo "  Recupero nodi per il cluster EKS: $CLUSTER_NAME"
    NODE_GROUPS=$(aws eks list-node-groups --cluster-name "$CLUSTER_NAME" \
      --query 'nodeGroups[*].nodeGroupName' \
      --output text | tr '\t' ',')

    if [ -n "$NODE_GROUPS" ]; then
      IFS=',' read -ra NODE_GROUP_ARRAY <<< "$NODE_GROUPS"
      for NODE_GROUP_NAME in "${NODE_GROUP_ARRAY[@]}"; do
        NODE_INSTANCE_IDS=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODE_GROUP_NAME" \
          --query 'nodeGroup.resources.autoScalingGroups[0].instances[*].instanceId' \
          --output text | tr '\t' ',')
        if [ -n "$NODE_INSTANCE_IDS" ]; then
          if [ -z "$ALL_EKS_NODES" ]; then
            ALL_EKS_NODES="$NODE_INSTANCE_IDS"
          else
            ALL_EKS_NODES="$ALL_EKS_NODES,$NODE_INSTANCE_IDS"
          fi
        fi
      done
    fi
  done
fi
echo $(export_variable "ALL_EKS_NODES" "$ALL_EKS_NODES")

# --- 5. Istanze EC2 ---
echo "Recupero tutte le istanze EC2..."
ALL_EC2_INSTANCES=$(aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | tr '\t' ',')
echo $(export_variable "ALL_EC2_INSTANCES" "$ALL_EC2_INSTANCES")

# --- 6. Istanze RDS ---
echo "Recupero tutte le istanze RDS..."
ALL_RDS_INSTANCES=$(aws rds describe-db-instances \
  --query 'DBInstances[*].DBInstanceIdentifier' \
  --output text | tr '\t' ',')
echo $(export_variable "ALL_RDS_INSTANCES" "$ALL_RDS_INSTANCES")

# --- 7. S3 Buckets ---
print_section_header "7. S3 Buckets"
S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "S3_BUCKETS" "$S3_BUCKETS")

# --- 8. CloudFront Distributions ---
print_section_header "8. CloudFront Distributions"
CLOUDFRONT_DISTRIBUTIONS=$(aws cloudfront list-distributions --query 'DistributionList.Items[*].Id' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "CLOUDFRONT_DISTRIBUTIONS" "$CLOUDFRONT_DISTRIBUTIONS")

# --- 9. CloudFormation Stacks ---
print_section_header "9. CloudFormation Stacks"
CLOUDFORMATION_STACKS=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE --query 'StackSummaries[*].StackName' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "CLOUDFORMATION_STACKS" "$CLOUDFORMATION_STACKS")

# --- 10. CloudWatch Alarms ---
print_section_header "10. CloudWatch Alarms"
CLOUDWATCH_ALARMS=$(aws cloudwatch describe-alarms --query 'MetricAlarms[*].AlarmName' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "CLOUDWATCH_ALARMS" "$CLOUDWATCH_ALARMS")

# --- 11. Lambda Functions ---
print_section_header "11. Lambda Functions"
LAMBDA_FUNCTIONS=$(aws lambda list-functions --query 'Functions[*].FunctionName' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "LAMBDA_FUNCTIONS" "$LAMBDA_FUNCTIONS")

# --- 12. DynamoDB Tables ---
print_section_header "12. DynamoDB Tables"
DYNAMODB_TABLES=$(aws dynamodb list-tables --query 'TableNames[*]' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "DYNAMODB_TABLES" "$DYNAMODB_TABLES")

# --- 13. SQS Queues ---
print_section_header "13. SQS Queues"
SQS_QUEUES=$(aws sqs list-queues --query 'QueueUrls[*]' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "SQS_QUEUES" "$SQS_QUEUES")

# --- 14. SNS Topics ---
print_section_header "14. SNS Topics"
SNS_TOPICS=$(aws sns list-topics --query 'Topics[*].TopicArn' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "SNS_TOPICS" "$SNS_TOPICS")

# --- 15. API Gateway REST APIs ---
print_section_header "15. API Gateway REST APIs"
API_GATEWAY_REST_APIS=$(aws apigateway get-rest-apis --query 'items[*].id' --output text | tr '\t' '\n' | paste -s -d ',' -)
echo $(export_variable "API_GATEWAY_REST_APIS" "$API_GATEWAY_REST_APIS")

echo "----------------------------------------------------------------------"
echo "Script completato. Le variabili d'ambiente sono state stampate."
echo "Per caricare queste variabili nella tua sessione corrente, esegui:"
echo "source <nome_file_script.sh>"
echo "----------------------------------------------------------------------"
