#!/bin/bash
# 

export GITHUB_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxx"

echo "Deploy del Esempio28codePipelineCICD"
echo "------------------------------------"

export AWS_REGION="eu-central-1"
echo "Region: $AWS_REGION"

# Trova la VPC di default
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "VPC: $DEFAULT_VPC"

# Trova le subnet della VPC di default
SUBNET_LIST=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[*].SubnetId' --output text --region $AWS_REGION | tr '\t' ',')
echo "Subnet list: $SUBNET_LIST"

echo "------------------------------------"
echo "Inizio del deploy del progetto Esempio28codePipelineCICD..."

sam validate
sam build
sam package --output-template-file packagedV1.yaml --s3-prefix REPOSITORY --s3-bucket cloudformation-alnao

sam deploy --template-file packagedV1.yaml --stack-name Esempio28codePipelineCICD  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --parameter-overrides  VpcId=$DEFAULT_VPC Subnets="$SUBNET_LIST" GitHubToken="$GITHUB_TOKEN"


echo "Deploy del Esempio28codePipelineCICD completato con successo!"
echo "-------------------------------------------------------------"

