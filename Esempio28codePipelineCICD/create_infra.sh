#!/bin/bash

# Aborta lo script in caso di errori
set -eEuo pipefail

echo "--- Script di Deploy AWS CLI per CI/CD (Solo Backend, con Secrets Manager) ---"

# --- Parametri configurabili ---
PROJECT_NAME="esempio28" # Deve essere tutto minuscolo per ECR, S3, ecc.
GITHUB_OWNER="alnao"
REPOSITORY_MASTER_NAME="JavaSpringBootExample"
BRANCH_NAME="master"
CONTAINER_PORT_BACKEND="8080"
GITHUB_SECRET_NAME="github/codepipeline/token" # Nome del secret GitHub in Secrets Manager

# --- Parametri da riga di comando o default ---
VPC_ID=""
SUBNET_LIST=""
AWS_REGION="eu-central-1" # Regione di default, può essere sovrascritta con -r
CERTIFICATE_ARN=""         # ARN del certificato ACM per HTTPS (opzionale)

# --- Variabili globali per gli ARN/ID delle risorse create ---
ECR_REPO_BACKEND_URI=""
CODEBUILD_ROLE_BACKEND_ARN=""
CODEBUILD_PROJECT_BACKEND_ARN=""
ECS_CLUSTER_ARN=""
LOG_GROUP_BACKEND_ARN=""
ECS_TASK_EXECUTION_ROLE_ARN=""
ECS_TASK_DEFINITION_ARN=""
SECURITY_GROUP_ALB_ID=""
SECURITY_GROUP_ECS_ID=""
ALB_ARN=""
ALB_DNS_NAME=""
ALB_CANONICAL_HOSTED_ZONE_ID=""
ALB_TARGET_GROUP_BACKEND_ARN=""
ALB_LISTENER_HTTP_ARN=""
ALB_LISTENER_HTTPS_ARN=""
ECS_SERVICE_ARN=""
CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME=""
CODEPIPELINE_ROLE_ARN=""
CODEPIPELINE_ARN=""
GITHUB_SECRET_ARN_FULL="" # ARN completo del secret

# --- Funzione per mostrare l'uso dello script ---
usage() {
  echo "Uso: $0 [-r <aws_region>] [-v <vpc_id>] [-s <subnet_list>] [-c <certificate_arn>]"
  echo "  -r <aws_region>         Regione AWS da usare (default: $AWS_REGION)"
  echo "  -v <vpc_id>             ID della VPC. Se omesso, cercherà la VPC di default."
  echo "  -s <subnet_list>        Lista delle Subnet ID separate da virgola. Se omesso, cercherà le subnet della VPC di default."
  echo "  -c <certificate_arn>    ARN del certificato ACM per listener HTTPS ALB (opzionale)."
  echo "  -h                      Mostra questo aiuto."
  echo ""
  echo "Assicurati di aver già creato il secret '${GITHUB_SECRET_NAME}' in AWS Secrets Manager con lo script apposito."
  exit 1
}

# Parsifica gli argomenti da riga di comando
while getopts "r:v:s:c:h" opt; do
  case ${opt} in
    r) AWS_REGION="${OPTARG}";;
    v) VPC_ID="${OPTARG}";;
    s) SUBNET_LIST="${OPTARG}";;
    c) CERTIFICATE_ARN="${OPTARG}";;
    h) usage;;
    *) usage;;
  esac
done

export AWS_DEFAULT_REGION="$AWS_REGION"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Regione AWS impostata su: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"

# --- Recupera l'ARN del Secret GitHub ---
echo "Recupero l'ARN del Secret GitHub da Secrets Manager..."
SECRET_DESCRIPTION=$(aws secretsmanager describe-secret \
  --secret-id "${GITHUB_SECRET_NAME}" \
  --query '{ARN:ARN, Name:Name}' \
  --output json --region "${AWS_REGION}" 2>/dev/null || true)

if [[ -z "$SECRET_DESCRIPTION" ]] || [[ "$(echo "$SECRET_DESCRIPTION" | jq -r '.ARN')" == "null" ]]; then
  echo "Errore: Secret '${GITHUB_SECRET_NAME}' non trovato in Secrets Manager."
  echo "Esegui prima lo script 'create_github_secret.sh'."
  exit 1
fi
GITHUB_SECRET_ARN_FULL=$(echo "$SECRET_DESCRIPTION" | jq -r '.ARN')
echo "ARN del Secret GitHub: ${GITHUB_SECRET_ARN_FULL}"

# --- Recupera VPC e Subnet se non fornite ---
echo "Recupero VPC e Subnet..."
if [[ -z "$VPC_ID" ]]; then
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
  if [[ -z "$VPC_ID" ]] || [[ "$VPC_ID" == "None" ]]; then
    echo "Errore: Nessuna VPC di default trovata nella regione $AWS_REGION."
    echo "Si prega di specificare un VPC_ID valido con -v."
    exit 1
  fi
  echo "VPC di default trovata: $VPC_ID"
else
  echo "VPC specificata: $VPC_ID"
fi

if [[ -z "$SUBNET_LIST" ]]; then
  SUBNET_LIST=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
  if [[ -z "$SUBNET_LIST" ]]; then
    echo "Errore: Nessuna subnet trovata per la VPC $VPC_ID."
    echo "Si prega di specificare le Subnet ID valide con -s."
    exit 1
  fi
  echo "Subnet trovate: $SUBNET_LIST"
else
  echo "Subnet specificate: $SUBNET_LIST"
fi

echo ""

# --- Funzioni helper ---

# Helper function for create_or_update_role (tagging for IAM roles maintained as per best practice)
create_or_update_role() {
    local role_name="$1"
    local assume_role_policy_doc_path="$2"
    local policy_arn="$3"
    local inline_policy_name="$4"
    local inline_policy_doc_path="$5"
    local tags_json="$6"

    local role_arn=$(aws iam get-role --role-name "${role_name}" --query 'Role.Arn' --output text 2>/dev/null || true)

    if [[ -z "$role_arn" ]] || [[ "$role_arn" == "None" ]]; then
        #echo "Creazione ruolo: ${role_name}"
        role_arn=$(aws iam create-role \
            --role-name "${role_name}" \
            --assume-role-policy-document "file://${assume_role_policy_doc_path}" \
            --tags "${tags_json}" \
            --query 'Role.Arn' --output text)
    else
        #echo "Ruolo esistente: ${role_name}. Aggiornamento policy di assunzione e tag."
        aws iam update-assume-role-policy \
            --role-name "${role_name}" \
            --policy-document "file://${assume_role_policy_doc_path}"
        aws iam tag-role --role-name "${role_name}" --tags "${tags_json}" || true
    fi

    if [[ -n "$policy_arn" ]]; then
        aws iam attach-role-policy \
            --role-name "${role_name}" \
            --policy-arn "${policy_arn}" || true # Allow to fail if already attached
    fi

    if [[ -n "$inline_policy_name" ]] && [[ -n "$inline_policy_doc_path" ]]; then
        aws iam put-role-policy \
            --role-name "${role_name}" \
            --policy-name "${inline_policy_name}" \
            --policy-document "file://${inline_policy_doc_path}"
    fi
    echo "$role_arn"
}

# Helper function for retries with exponential backoff for AWS CLI commands
# This function captures the output and returns it on success, or exits on persistent failure.
retry_aws_cli_command() {
    local cmd_output=""
    local last_exit_code=0
    local retries=7 # Increased retries to provide more resilience
    local delay=5   # Initial delay in seconds

    # Store the command arguments
    local aws_command=("aws" "$@")

    for i in $(seq 1 "$retries"); do
        echo "Tentativo $i/$retries: Eseguendo AWS CLI comando: ${aws_command[@]}" >&2
        # Execute the command and capture its stdout/stderr
        if cmd_output=$("${aws_command[@]}" 2>&1); then
            # Command succeeded, print its output and return 0
            echo "$cmd_output"
            return 0
        else
            last_exit_code=$?
            echo "Errore AWS CLI (tentativo $i/$retries, codice: $last_exit_code):" >&2
            echo "$cmd_output" >&2 # Print the error message
            if [[ "$i" -lt "$retries" ]]; then
                echo "Riprovo in $delay secondi..." >&2
                sleep "$delay"
                delay=$((delay * 2))
            else
                echo "Errore persistente dopo $retries tentativi. Uscita." >&2
                return "$last_exit_code"
            fi
        fi
    done
    return "$last_exit_code" # Should not be reached if it fails after retries
}


# --- 1. ECR Repositories ---
echo "Creazione ECR Repositories..."
ECR_REPO_BACKEND_NAME="${PROJECT_NAME}-backend"
# La seguente riga gestisce già l'idempotenza:
# Se create-repository fallisce (es. perché esiste già), esegue describe-repositories per ottenere l'URI.
ECR_REPO_BACKEND_URI=$(aws ecr create-repository \
  --repository-name "${ECR_REPO_BACKEND_NAME}" \
  --image-scanning-configuration scanOnPush=true \
  --tags Key=Project,Value="${PROJECT_NAME}" \
  --query 'repository.repositoryUri' --output text || \
  aws ecr describe-repositories --repository-names "${ECR_REPO_BACKEND_NAME}" --query 'repositories[0].repositoryUri' --output text) # If exists
echo "ECR Backend URI: ${ECR_REPO_BACKEND_URI}"
echo ""

# --- 2. IAM Roles for CodeBuild and ECS Task Execution ---
echo "Creazione/Aggiornamento IAM Roles e Policies..."

# Create temporary policy files
CODEBUILD_ASSUME_ROLE_POLICY_FILE=$(mktemp)
cat <<EOF > "${CODEBUILD_ASSUME_ROLE_POLICY_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

ECS_TASK_ASSUME_ROLE_POLICY_FILE=$(mktemp)
cat <<EOF > "${ECS_TASK_ASSUME_ROLE_POLICY_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

CODEPIPELINE_ASSUME_ROLE_POLICY_FILE=$(mktemp)
cat <<EOF > "${CODEPIPELINE_ASSUME_ROLE_POLICY_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Inline policies for CodeBuild Backend
CODEBUILD_POLICY_BACKEND_FILE=$(mktemp)
cat <<EOF > "${CODEBUILD_POLICY_BACKEND_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:log-group:/aws/codebuild/${PROJECT_NAME}-backend-build:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/${ECR_REPO_BACKEND_NAME}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline-${PROJECT_NAME}-${AWS_REGION}-${AWS_ACCOUNT_ID}-*",
        "arn:aws:s3:::codepipeline-${PROJECT_NAME}-${AWS_REGION}-${AWS_ACCOUNT_ID}-*/*"
      ]
    }
  ]
}
EOF


# Inline policy for CodePipeline
CODEPIPELINE_POLICY_FILE=$(mktemp)
cat <<EOF > "${CODEPIPELINE_POLICY_FILE}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "codebuild:*",
        "ecr:*",
        "ecs:*",
        "iam:PassRole",
        "codepipeline:ListConnection",
        "codepipeline:UseConnection",
        "appsync:StartSchemaCreation",
        "appsync:GetSchemaCreationStatus"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "${GITHUB_SECRET_ARN_FULL}"
    }
  ]
}
EOF

# Common tags for IAM roles (maintained as per best practice for IAM roles)
IAM_ROLE_TAGS="Key=Project,Value=${PROJECT_NAME}"

# CodeBuild Backend Role
CODEBUILD_ROLE_BACKEND_ARN=$(create_or_update_role \
  "${PROJECT_NAME}-CodeBuildRoleBackend" \
  "${CODEBUILD_ASSUME_ROLE_POLICY_FILE}" \
  "arn:aws:iam::aws:policy/PowerUserAccess" \
  "CodeBuildPolicyBackend" \
  "${CODEBUILD_POLICY_BACKEND_FILE}" \
  "${IAM_ROLE_TAGS}")
echo "CodeBuild Backend Role ARN: ${CODEBUILD_ROLE_BACKEND_ARN}"

# ECS Task Execution Role
ECS_TASK_EXECUTION_ROLE_ARN=$(create_or_update_role \
  "${PROJECT_NAME}-EcsTaskExecutionRole" \
  "${ECS_TASK_ASSUME_ROLE_POLICY_FILE}" \
  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" \
  "" "" \
  "${IAM_ROLE_TAGS}")
echo "ECS Task Execution Role ARN: ${ECS_TASK_EXECUTION_ROLE_ARN}"

# CodePipeline Role
CODEPIPELINE_ROLE_ARN=$(create_or_update_role \
  "${PROJECT_NAME}-CodePipelineRole" \
  "${CODEPIPELINE_ASSUME_ROLE_POLICY_FILE}" \
  "arn:aws:iam::aws:policy/AdministratorAccess" \
  "CodePipelineAccess" \
  "${CODEPIPELINE_POLICY_FILE}" \
  "${IAM_ROLE_TAGS}")
echo "CodePipeline Role ARN: ${CODEPIPELINE_ROLE_ARN}"

# Cleanup temporary policy files
rm "${CODEBUILD_ASSUME_ROLE_POLICY_FILE}"
rm "${ECS_TASK_ASSUME_ROLE_POLICY_FILE}"
rm "${CODEPIPELINE_ASSUME_ROLE_POLICY_FILE}"
rm "${CODEBUILD_POLICY_BACKEND_FILE}"
rm "${CODEPIPELINE_POLICY_FILE}"

echo "Attesa di 15 secondi per la propagazione dei ruoli IAM..."
sleep 15
echo ""

# --- 3. CloudWatch Log Group for ECS Backend ---
echo "Creazione CloudWatch Log Group per ECS Backend..."
LOG_GROUP_BACKEND_NAME="/ecs/${PROJECT_NAME}-backend"
LOG_GROUP_BACKEND_ARN=$(aws logs describe-log-groups --log-group-name-prefix "${LOG_GROUP_BACKEND_NAME}" --query 'logGroups[?logGroupName==`'${LOG_GROUP_BACKEND_NAME}'`].arn' --output text 2>/dev/null || true)
if [[ -z "$LOG_GROUP_BACKEND_ARN" ]] || [[ "$LOG_GROUP_BACKEND_ARN" == "None" ]]; then
    LOG_GROUP_BACKEND_ARN=$(aws logs create-log-group \
      --log-group-name "${LOG_GROUP_BACKEND_NAME}" \
      --tags Key=Project,Value="${PROJECT_NAME}" \
      --query 'logGroup.arn' --output text)
fi
echo "Log Group Backend ARN: ${LOG_GROUP_BACKEND_ARN}"
echo ""

# --- 4. ECS Cluster ---
echo "Creazione ECS Cluster..."
ECS_CLUSTER_NAME="${PROJECT_NAME}-cluster"
ECS_CLUSTER_ARN=$(aws ecs describe-clusters --cluster-names "${ECS_CLUSTER_NAME}" --query 'clusters[0].clusterArn' --output text 2>/dev/null || true)
if [[ -z "$ECS_CLUSTER_ARN" ]] || [[ "$ECS_CLUSTER_ARN" == "None" ]]; then
    ECS_CLUSTER_ARN=$(aws ecs create-cluster \
      --cluster-name "${ECS_CLUSTER_NAME}" \
      --query 'cluster.clusterArn' --output text)
fi
echo "ECS Cluster ARN: ${ECS_CLUSTER_ARN}"
echo ""

# --- 5. EC2 Security Groups ---
echo "Creazione Security Groups..."
# Helper function to create or get SG ID and add tags
create_or_get_sg_id() {
    local sg_name="$1"
    local description="$2"
    local vpc_id="$3"
    local tags_json="$4"

    local sg_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" "Name=group-name,Values=${sg_name}" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
    if [[ -z "$sg_id" ]] || [[ "$sg_id" == "None" ]]; then
        sg_id=$(aws ec2 create-security-group \
            --group-name "${sg_name}" \
            --description "${description}" \
            --vpc-id "${vpc_id}" \
            --query 'GroupId' --output text)
    fi
    echo "$sg_id"
}

SECURITY_GROUP_ALB_ID=$(create_or_get_sg_id "${PROJECT_NAME}-alb-sg" "Enable HTTP/HTTPS access to ALB" "${VPC_ID}" "Key=Project,Value=${PROJECT_NAME}")
echo "ALB Security Group ID: ${SECURITY_GROUP_ALB_ID}"

# Authorize ingress rules for ALB SG (idempotent)
aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ALB_ID}" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0 || true # Avoid error if rule exists
aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ALB_ID}" \
  --protocol tcp --port 443 --cidr 0.0.0.0/0 || true # Avoid error if rule exists

SECURITY_GROUP_ECS_ID=$(create_or_get_sg_id "${PROJECT_NAME}-ecs-sg" "Enable inbound access from ALB to ECS containers" "${VPC_ID}" "Key=Project,Value=${PROJECT_NAME}")
echo "ECS Security Group ID: ${SECURITY_GROUP_ECS_ID}"

# Authorize ingress rule for ECS SG from ALB SG (idempotent)
aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ECS_ID}" \
  --protocol tcp --port "${CONTAINER_PORT_BACKEND}" \
  --source-group "${SECURITY_GROUP_ALB_ID}" || true # Avoid error if rule exists
echo ""

# --- 6. ALB (Application Load Balancer) ---
echo "Creazione ALB..."
ALB_NAME="${PROJECT_NAME}-alb"
ALB_ARN=$(aws elbv2 describe-load-balancers --names "${ALB_NAME}" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [[ -z "$ALB_ARN" ]] || [[ "$ALB_ARN" == "None" ]]; then
    ALB_ARN=$(aws elbv2 create-load-balancer \
      --name "${ALB_NAME}" \
      --subnets ${SUBNET_LIST//,/ } \
      --security-groups "${SECURITY_GROUP_ALB_ID}" \
      --query 'LoadBalancers[0].LoadBalancerArn' --output text)
fi
ALB_DNS_NAME=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "${ALB_ARN}" \
  --query 'LoadBalancers[0].DNSName' --output text)
ALB_CANONICAL_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "${ALB_ARN}" \
  --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)

echo "ALB ARN: ${ALB_ARN}"
echo "ALB DNS Name: ${ALB_DNS_NAME}"

ALB_TARGET_GROUP_BACKEND_NAME="${PROJECT_NAME}-tg-backend"
ALB_TARGET_GROUP_BACKEND_ARN=$(aws elbv2 describe-target-groups --names "${ALB_TARGET_GROUP_BACKEND_NAME}" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [[ -z "$ALB_TARGET_GROUP_BACKEND_ARN" ]] || [[ "$ALB_TARGET_GROUP_BACKEND_ARN" == "None" ]]; then
    ALB_TARGET_GROUP_BACKEND_ARN=$(aws elbv2 create-target-group \
      --name "${ALB_TARGET_GROUP_BACKEND_NAME}" \
      --port "${CONTAINER_PORT_BACKEND}" \
      --protocol HTTP \
      --vpc-id "${VPC_ID}" \
      --health-check-path "/actuator/health" \
      --health-check-interval-seconds 30 \
      --health-check-timeout-seconds 5 \
      --healthy-threshold-count 2 \
      --unhealthy-threshold-count 2 \
      --target-type ip \
      --query 'TargetGroups[0].TargetGroupArn' --output text)
fi
echo "ALB Target Group Backend ARN: ${ALB_TARGET_GROUP_BACKEND_ARN}"

# Create/update HTTP Listener
ALB_LISTENER_HTTP_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" --query 'Listeners[?Port==`80`].ListenerArn' --output text 2>/dev/null || true)
if [[ -z "$ALB_LISTENER_HTTP_ARN" ]] || [[ "$ALB_LISTENER_HTTP_ARN" == "None" ]]; then
    ALB_LISTENER_HTTP_ARN=$(aws elbv2 create-listener \
      --load-balancer-arn "${ALB_ARN}" \
      --port 80 \
      --protocol HTTP \
      --default-actions Type=forward,TargetGroupArn="${ALB_TARGET_GROUP_BACKEND_ARN}" \
      --query 'Listeners[0].ListenerArn' --output text)
else
    echo "HTTP Listener già esistente. Nessun aggiornamento necessario."
fi
echo "ALB HTTP Listener ARN: ${ALB_LISTENER_HTTP_ARN}"

# Optional HTTPS Listener (requires CertificateArn parameter passed to script if used)
if [[ -n "$CERTIFICATE_ARN" ]]; then
  ALB_LISTENER_HTTPS_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" --query 'Listeners[?Port==`443`].ListenerArn' --output text 2>/dev/null || true)
  if [[ -z "$ALB_LISTENER_HTTPS_ARN" ]] || [[ "$ALB_LISTENER_HTTPS_ARN" == "None" ]]; then
    ALB_LISTENER_HTTPS_ARN=$(aws elbv2 create-listener \
      --load-balancer-arn "${ALB_ARN}" \
      --port 443 \
      --protocol HTTPS \
      --certificates CertificateArn="${CERTIFICATE_ARN}" \
      --default-actions Type=forward,TargetGroupArn="${ALB_TARGET_GROUP_BACKEND_ARN}" \
      --query 'Listeners[0].ListenerArn' --output text)
  else
    echo "HTTPS Listener già esistente. Nessun aggiornamento necessario."
  fi
  echo "ALB HTTPS Listener ARN: ${ALB_LISTENER_HTTPS_ARN}"
fi
echo ""

# --- 7. ECS Task Definition ---
echo "Registrazione ECS Task Definition..."
# Note: Task Definition Family is unique, a new revision is created on re-registration
TASK_DEFINITION_FAMILY="${PROJECT_NAME}-backend-task"
TASK_DEFINITION_JSON=$(cat <<EOF
[
  {
    "name": "backend-container",
    "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:latest",
    "portMappings": [
      {
        "containerPort": ${CONTAINER_PORT_BACKEND},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${LOG_GROUP_BACKEND_NAME}",
        "awslogs-region": "${AWS_REGION}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
)
# Wrap the task definition registration in the retry_aws_cli_command function
ECS_TASK_DEFINITION_ARN=$(retry_aws_cli_command ecs register-task-definition \
  --family "${TASK_DEFINITION_FAMILY}" \
  --cpu "256" \
  --memory "512" \
  --network-mode "awsvpc" \
  --requires-compatibilities "FARGATE" \
  --execution-role-arn "${ECS_TASK_EXECUTION_ROLE_ARN}" \
  --container-definitions "${TASK_DEFINITION_JSON}" \
  --query 'taskDefinition.taskDefinitionArn' --output text)
echo "ECS Task Definition ARN: ${ECS_TASK_DEFINITION_ARN}"
echo ""

# --- 8. ECS Service ---
echo "Creazione ECS Service..."
ECS_SERVICE_NAME="${PROJECT_NAME}-backend-service"
ECS_SERVICE_ARN=$(aws ecs describe-services --cluster "${ECS_CLUSTER_ARN}" --services "${ECS_SERVICE_NAME}" --query 'services[0].serviceArn' --output text 2>/dev/null || true)
if [[ -z "$ECS_SERVICE_ARN" ]] || [[ "$ECS_SERVICE_ARN" == "None" ]]; then
    ECS_SERVICE_ARN=$(aws ecs create-service \
      --cluster "${ECS_CLUSTER_ARN}" \
      --service-name "${ECS_SERVICE_NAME}" \
      --task-definition "${ECS_TASK_DEFINITION_ARN}" \
      --desired-count 1 \
      --launch-type "FARGATE" \
      --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_LIST}],securityGroups=[${SECURITY_GROUP_ECS_ID}],assignPublicIp=ENABLED}" \
      --load-balancers "containerName=backend-container,containerPort=${CONTAINER_PORT_BACKEND},targetGroupArn=${ALB_TARGET_GROUP_BACKEND_ARN}" \
      --query 'service.serviceArn' --output text)
else
    echo "ECS Service '${ECS_SERVICE_NAME}' già esistente. Aggiornamento con la nuova Task Definition."
    aws ecs update-service \
      --cluster "${ECS_CLUSTER_ARN}" \
      --service "${ECS_SERVICE_NAME}" \
      --task-definition "${ECS_TASK_DEFINITION_ARN}" \
      --force-new-deployment \
      --query 'service.serviceArn' --output text
fi
echo "ECS Service ARN: ${ECS_SERVICE_ARN}"
echo ""

# --- 9. CodeBuild Projects ---
echo "Creazione CodeBuild Projects..."

# CodeBuild Backend Project
CODEBUILD_BACKEND_BUILDSPEC_FILE=$(mktemp)
cat <<EOF > "${CODEBUILD_BACKEND_BUILDSPEC_FILE}"
version: 0.2
phases:
  install:
    runtime-versions:
      java: corretto17
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region \$AWS_DEFAULT_REGION | docker login --username AWS --password-stdin \$AWS_ACCOUNT_ID.dkr.ecr.\$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on \`date\`
      - echo Building the Docker image for backend...
      - ls -l
      - cd Esempio03dbDockerAWS/backend-springboot # Navigate to your backend project directory
      - mvn clean install -DskipTests
      - docker build -t \$ECR_REPOSITORY_URI_BACKEND:\$IMAGE_TAG .
      - docker tag \$ECR_REPOSITORY_URI_BACKEND:\$IMAGE_TAG \$ECR_REPOSITORY_URI_BACKEND:\$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on \`date\`
      - echo Pushing the Docker image to ECR...
      - docker push \$ECR_REPOSITORY_URI_BACKEND:\$IMAGE_TAG
      - printf '[{"name":"backend-container","imageUri":"%s"}]' "\$ECR_REPOSITORY_URI_BACKEND:\$IMAGE_TAG" > imageDetail.json
artifacts:
  files:
    - imageDetail.json
  base-directory: Esempio03dbDockerAWS/backend-springboot # Output artifact from this specific directory
EOF

CODEBUILD_PROJECT_BACKEND_NAME="${PROJECT_NAME}-backend-build"
CODEBUILD_PROJECT_BACKEND_ARN=$(aws codebuild create-project \
  --name "${CODEBUILD_PROJECT_BACKEND_NAME}" \
  --description "CodeBuild project for the Spring Boot backend." \
  --service-role "${CODEBUILD_ROLE_BACKEND_ARN}" \
  --artifacts "type=CODEPIPELINE,name=BackendBuildOutput" \
  --environment "computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:7.0,type=LINUX_CONTAINER,privilegedMode=true,environmentVariables=[{name=AWS_ACCOUNT_ID,value=${AWS_ACCOUNT_ID}},{name=ECR_REPOSITORY_URI_BACKEND,value=${ECR_REPO_BACKEND_URI}},{name=IMAGE_TAG,value=latest}]" \
  --source "type=CODEPIPELINE,buildspec=\"file://${CODEBUILD_BACKEND_BUILDSPEC_FILE}\"" \
  --query 'project.arn' --output text || \
  aws codebuild update-project \
    --name "${CODEBUILD_PROJECT_BACKEND_NAME}" \
    --description "CodeBuild project for the Spring Boot backend." \
    --service-role "${CODEBUILD_ROLE_BACKEND_ARN}" \
    --artifacts "type=CODEPIPELINE,name=BackendBuildOutput" \
    --environment "computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:7.0,type=LINUX_CONTAINER,privilegedMode=true,environmentVariables=[{name=AWS_ACCOUNT_ID,value=${AWS_ACCOUNT_ID}},{name=ECR_REPOSITORY_URI_BACKEND,value=${ECR_REPO_BACKEND_URI}},{name=IMAGE_TAG,value=latest}]" \
    --source "type=CODEPIPELINE,buildspec=\"file://${CODEBUILD_BACKEND_BUILDSPEC_FILE}\"" \
    --query 'project.arn' --output text) # If exists, update
echo "CodeBuild Backend Project ARN: ${CODEBUILD_PROJECT_BACKEND_ARN}"

# Clean up temporary buildspec file
rm "${CODEBUILD_BACKEND_BUILDSPEC_FILE}"

echo ""

# --- 10. CodePipeline Artifact Store Bucket ---
echo "Creazione CodePipeline Artifact Store Bucket..."
# Generate a random suffix for global uniqueness
RANDOM_SUFFIX=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8 || true)
CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME_PREFIX="codepipeline-${PROJECT_NAME}-${AWS_REGION}-${AWS_ACCOUNT_ID}"

# Find an existing bucket that matches the prefix, otherwise create a new one
EXISTING_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME_PREFIX}')].Name | [0]" --output text 2>/dev/null || true)

if [[ -n "$EXISTING_BUCKET" ]] && [[ "$EXISTING_BUCKET" != "None" ]]; then
    CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME="$EXISTING_BUCKET"
    echo "Trovato bucket esistente per gli artefatti: ${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}. Riutilizzo."
else
    CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME="${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME_PREFIX}-${RANDOM_SUFFIX}-art" # Changed "artifacts" to "art"
    aws s3api create-bucket \
      --bucket "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" \
      --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    aws s3api put-bucket-versioning \
      --bucket "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" \
      --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption \
      --bucket "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

aws s3api put-bucket-tagging \
  --bucket "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" \
  --tagging "TagSet=[{Key=Project,Value=${PROJECT_NAME}}]" || true # Idempotent for tagging
echo "CodePipeline Artifact Store Bucket: ${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}"
echo ""

# --- 11. CodePipeline ---
echo "Creazione/Aggiornamento CodePipeline..."
CODEPIPELINE_NAME="${PROJECT_NAME}-pipeline"

# Define pipeline JSON as a variable for create-pipeline
PIPELINE_JSON=$(cat <<EOF
{
  "pipeline": {
    "name": "${CODEPIPELINE_NAME}",
    "roleArn": "${CODEPIPELINE_ROLE_ARN}",
    "artifactStore": {
      "type": "S3",
      "location": "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "SourceMonoRepo",
            "actionTypeId": {
              "category": "Source",
              "owner": "ThirdParty",
              "provider": "GitHub",
              "version": "1"
            },
            "outputArtifacts": [
              {
                "name": "SourceCode"
              }
            ],
            "configuration": {
              "Owner": "${GITHUB_OWNER}",
              "Repo": "${REPOSITORY_MASTER_NAME}",
              "Branch": "${BRANCH_NAME}",
              "OAuthToken": "${GITHUB_SECRET_ARN_FULL}",
              "PollForSourceChanges": "true"
            },
            "runOrder": 1
          }
        ]
      },
      {
        "name": "BuildBackend",
        "actions": [
          {
            "name": "BuildBackendImage",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "inputArtifacts": [
              {
                "name": "SourceCode"
              }
            ],
            "outputArtifacts": [
              {
                "name": "BackendBuildOutput"
              }
            ],
            "configuration": {
              "ProjectName": "${PROJECT_NAME}-backend-build"
            },
            "runOrder": 2
          }
        ]
      },
      {
        "name": "DeployBackend",
        "actions": [
          {
            "name": "DeployToECS",
            "actionTypeId": {
              "category": "Deploy",
              "owner": "AWS",
              "provider": "ECS",
              "version": "1"
            },
            "inputArtifacts": [
              {
                "name": "BackendBuildOutput"
              }
            ],
            "configuration": {
              "ClusterName": "${PROJECT_NAME}-cluster",
              "ServiceName": "${PROJECT_NAME}-backend-service",
              "FileName": "BackendBuildOutput::imageDetail.json"
            },
            "runOrder": 3
          }
        ]
      }
    ]
  }
}
EOF
)

echo "--------------------------------------------------"
echo ${PIPELINE_JSON}
echo "--------------------------------------------------"

# Check if pipeline exists
CODEPIPELINE_EXISTS=$(aws codepipeline list-pipelines --query "pipelines[?name=='${CODEPIPELINE_NAME}'].name" --output text 2>/dev/null || true)
if [[ -z "$CODEPIPELINE_EXISTS" ]] || [[ "$CODEPIPELINE_EXISTS" == "None" ]]; then
    CODEPIPELINE_ARN=$(aws codepipeline create-pipeline --cli-input-json "${PIPELINE_JSON}" --query 'pipeline.pipelineArn' --output text)
    #--tags Key=Project,Value="${PROJECT_NAME}" 
else
    echo "CodePipeline '${CODEPIPELINE_NAME}' già esistente. Aggiornamento."
    aws codepipeline update-pipeline --cli-input-json "${PIPELINE_JSON}"
    # Tags can't be updated via update-pipeline, so add them separately if they don't exist
    aws codepipeline tag-resource --resource-arn "${CODEPIPELINE_ARN}"  || true
    #--tags Key=Project,Value="${PROJECT_NAME}"
fi
echo "CodePipeline ARN: ${CODEPIPELINE_ARN}"
echo ""

echo "--- Deploy AWS CLI completato! ---"
echo ""
echo "Per monitorare la pipeline, visita:"
echo "https://${AWS_REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${PROJECT_NAME}-pipeline/view?region=${AWS_REGION}"
echo ""
echo "URL del Load Balancer Backend (potrebbe impiegare alcuni minuti per diventare attivo):"
echo "http://${ALB_DNS_NAME}"