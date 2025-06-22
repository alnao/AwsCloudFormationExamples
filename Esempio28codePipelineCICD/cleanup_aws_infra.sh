#!/bin/bash

# Aborta lo script in caso di errori
set -eEuo pipefail

echo "--- Script di Rimozione AWS CLI per CI/CD ---"

# --- Parametri configurabili (devono corrispondere a quelli usati nel deploy) ---
PROJECT_NAME="esempio28"
AWS_REGION="eu-central-1"

export AWS_DEFAULT_REGION="$AWS_REGION"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Regione AWS impostata su: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"

echo ""
echo "--- Inizio rimozione risorse ---"

# --- 1. CodePipeline ---
echo "Rimozione CodePipeline..."
CODEPIPELINE_NAME="${PROJECT_NAME}-pipeline"
# Verifica l'esistenza della CodePipeline
CODEPIPELINE_EXISTS=$(aws codepipeline list-pipelines --query "pipelines[?name=='${CODEPIPELINE_NAME}'].name | [0]" --output text 2>/dev/null || true)
if [[ -n "$CODEPIPELINE_EXISTS" ]] && [[ "$CODEPIPELINE_EXISTS" != "None" ]]; then
  aws codepipeline delete-pipeline --name "${CODEPIPELINE_NAME}" || true
  echo "CodePipeline '${CODEPIPELINE_NAME}' eliminata. Attesa di 5 secondi..."
  sleep 5
else
  echo "CodePipeline '${CODEPIPELINE_NAME}' non trovata. Saltato."
fi

# --- 2. CodeBuild Projects ---
echo "Rimozione CodeBuild Projects..."
CODEBUILD_PROJECT_BACKEND_NAME="${PROJECT_NAME}-backend-build"
# Verifica l'esistenza del CodeBuild Project Backend
CODEBUILD_PROJECT_BACKEND_EXISTS=$(aws codebuild list-projects --query "projects[?starts_with(@, '${CODEBUILD_PROJECT_BACKEND_NAME}')]" --output text 2>/dev/null || true)
if [[ -n "$CODEBUILD_PROJECT_BACKEND_EXISTS" ]] && [[ "$CODEBUILD_PROJECT_BACKEND_EXISTS" != "None" ]]; then
  aws codebuild delete-project --name "${CODEBUILD_PROJECT_BACKEND_NAME}" || true
  echo "CodeBuild Project Backend eliminato."
else
  echo "CodeBuild Project Backend non trovato. Saltato."
fi

# Frontend CodeBuild Project (se creato in una run precedente)
CODEBUILD_PROJECT_FRONTEND_NAME="${PROJECT_NAME}-frontend-build"
# Verifica l'esistenza del CodeBuild Project Frontend
CODEBUILD_PROJECT_FRONTEND_EXISTS=$(aws codebuild list-projects --query "projects[?starts_with(@, '${CODEBUILD_PROJECT_FRONTEND_NAME}')][0]" --output text 2>/dev/null || true)
if [[ -n "$CODEBUILD_PROJECT_FRONTEND_EXISTS" ]] && [[ "$CODEBUILD_PROJECT_FRONTEND_EXISTS" != "None" ]]; then
  aws codebuild delete-project --name "${CODEBUILD_PROJECT_FRONTEND_NAME}" || true
  echo "CodeBuild Project Frontend eliminato."
else
  echo "CodeBuild Project Frontend non trovato. Saltato."
fi
echo ""

# --- 3. ECS Service ---
echo "Rimozione ECS Service..."
ECS_CLUSTER_NAME="${PROJECT_NAME}-cluster"
ECS_SERVICE_NAME="${PROJECT_NAME}-backend-service"
# Verifica l'esistenza dell'ECS Service
ECS_SERVICE_ARN=$(aws ecs describe-services --cluster "${ECS_CLUSTER_NAME}" --services "${ECS_SERVICE_NAME}" --query 'services[0].serviceArn' --output text 2>/dev/null || true)
if [[ -n "$ECS_SERVICE_ARN" ]] && [[ "$ECS_SERVICE_ARN" != "None" ]]; then
  # Set desired count to 0 to stop tasks before deleting
  aws ecs update-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_SERVICE_NAME}" --desired-count 0 || true
  echo "ECS Service desired count impostato a 0. Attesa di 10 secondi per la terminazione delle task..."
  sleep 10
  aws ecs delete-service --cluster "${ECS_CLUSTER_NAME}" --service "${ECS_SERVICE_NAME}" --force || true
  echo "ECS Service eliminato."
else
  echo "ECS Service non trovato. Saltato."
fi
echo ""

# --- 4. ECS Task Definition ---
echo "Deregistrazione ECS Task Definition..."
# Note: Task definitions cannot be "deleted", only deregistered (making them inactive)
TASK_DEFINITION_FAMILY="${PROJECT_NAME}-backend-task"
TASK_DEFINITIONS=$(aws ecs list-task-definitions --family-prefix "${TASK_DEFINITION_FAMILY}" --query 'taskDefinitionArns' --output text 2>/dev/null || true)
if [[ -n "$TASK_DEFINITIONS" ]] && [[ "$TASK_DEFINITIONS" != "None" ]]; then
  for TD_ARN in $TASK_DEFINITIONS; do
    aws ecs deregister-task-definition --task-definition "${TD_ARN}" || true
    echo "Task Definition '${TD_ARN}' deregistrata."
  done
else
  echo "Nessuna Task Definition trovata. Saltato."
fi
echo ""

# --- 5. ALB Listeners ---
echo "Rimozione ALB Listeners..."
ALB_NAME="${PROJECT_NAME}-alb"
# Verifica l'esistenza dell'ALB per ottenere il suo ARN
ALB_ARN=$(aws elbv2 describe-load-balancers --names "${ALB_NAME}" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [[ -n "$ALB_ARN" ]] && [[ "$ALB_ARN" != "None" ]]; then
  # Verifica e elimina l'HTTP Listener
  HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" --query 'Listeners[?Port==`80`][0].ListenerArn' --output text 2>/dev/null || true)
  if [[ -n "$HTTP_LISTENER_ARN" ]] && [[ "$HTTP_LISTENER_ARN" != "None" ]]; then
    aws elbv2 delete-listener --listener-arn "${HTTP_LISTENER_ARN}" || true
    echo "HTTP Listener eliminato."
  else
    echo "HTTP Listener non trovato. Saltato."
  fi

  # Verifica e elimina l'HTTPS Listener
  HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" --query 'Listeners[?Port==`443`][0].ListenerArn' --output text 2>/dev/null || true)
  if [[ -n "$HTTPS_LISTENER_ARN" ]] && [[ "$HTTPS_LISTENER_ARN" != "None" ]]; then
    aws elbv2 delete-listener --listener-arn "${HTTPS_LISTENER_ARN}" || true
    echo "HTTPS Listener eliminato."
  else
    echo "HTTPS Listener non trovato. Saltato."
  fi
else
  echo "ALB non trovato, Listeners saltati."
fi
echo ""

# --- 6. ALB Target Group ---
echo "Rimozione ALB Target Group..."
ALB_TARGET_GROUP_BACKEND_NAME="${PROJECT_NAME}-tg-backend"
# Verifica l'esistenza dell'ALB Target Group
ALB_TARGET_GROUP_BACKEND_ARN=$(aws elbv2 describe-target-groups --names "${ALB_TARGET_GROUP_BACKEND_NAME}" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [[ -n "$ALB_TARGET_GROUP_BACKEND_ARN" ]] && [[ "$ALB_TARGET_GROUP_BACKEND_ARN" != "None" ]]; then
  aws elbv2 delete-target-group --target-group-arn "${ALB_TARGET_GROUP_BACKEND_ARN}" || true
  echo "ALB Target Group Backend eliminato."
else
  echo "ALB Target Group Backend non trovato. Saltato."
fi
echo ""

# --- 7. ALB (Application Load Balancer) ---
echo "Rimozione ALB..."
# ALB_ARN è già stato recuperato nella sezione 5
if [[ -n "$ALB_ARN" ]] && [[ "$ALB_ARN" != "None" ]]; then
  aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" || true
  echo "ALB eliminato."
else
  echo "ALB non trovato. Saltato."
fi
echo ""

# --- 8. EC2 Security Groups ---
echo "Rimozione Security Groups..."

# Nuova funzione per revocare le regole di ingresso di un Security Group
revoke_ingress_rules() {
  local sg_id="$1"

  local ingress_permissions=$(aws ec2 describe-security-groups --group-ids "${sg_id}" --query 'SecurityGroups[0].IpPermissions' --output json 2>/dev/null || true)

  if [[ -z "$ingress_permissions" || "$ingress_permissions" == "null" ]]; then
    echo "  Nessuna regola di ingresso trovata per SG ${sg_id} o SG non esistente."
    return 0
  fi

  echo "  Revoca delle regole di ingresso per SG: ${sg_id}"
  echo "$ingress_permissions" | jq -c '.[]' | while read -r perm; do
    local protocol=$(echo "$perm" | jq -r '.IpProtocol' 2>/dev/null || true)
    local from_port=$(echo "$perm" | jq -r '.FromPort' 2>/dev/null || true)
    local to_port=$(echo "$perm" | jq -r '.ToPort' 2>/dev/null || true)

    # Gestione di IpRanges (CIDR)
    for ip_range in $(echo "$perm" | jq -r '.IpRanges[].CidrIp' 2>/dev/null || true); do
      if [[ -n "$ip_range" ]]; then
        if [[ "$protocol" == "-1" ]]; then # Tutti i protocolli
          aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol -1 --cidr "${ip_range}" || true
        elif [[ -n "$from_port" ]] && [[ -n "$to_port" ]]; then
          if [[ "$from_port" == "$to_port" ]]; then # Porta singola
            aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol "${protocol}" --port "${from_port}" --cidr "${ip_range}" || true
          else # Intervallo di porte
            aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol "${protocol}" --port "${from_port}-${to_port}" --cidr "${ip_range}" || true
          fi
        fi
      fi
    done

    # Gestione di UserIdGroupPairs (Security Group sorgente)
    for user_id_group_pair in $(echo "$perm" | jq -r '.UserIdGroupPairs[].GroupId' 2>/dev/null || true); do
      if [[ -n "$user_id_group_pair" ]]; then
        if [[ "$protocol" == "-1" ]]; then # Tutti i protocolli
          aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol -1 --source-group "${user_id_group_pair}" || true
        elif [[ -n "$from_port" ]] && [[ -n "$to_port" ]]; then
          if [[ "$from_port" == "$to_port" ]]; then # Porta singola
            aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol "${protocol}" --port "${from_port}" --source-group "${user_id_group_pair}" || true
          else # Intervallo di porte
            aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --protocol "${protocol}" --port "${from_port}-${to_port}" --source-group "${user_id_group_pair}" || true
          fi
        fi
      fi
    done
  done
}

# Ottieni gli ID dei Security Group prima di iniziare a revocare le regole
SECURITY_GROUP_ALB_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${PROJECT_NAME}-alb-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
SECURITY_GROUP_ECS_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${PROJECT_NAME}-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)

# Revoca e elimina Security Group ALB
if [[ -n "$SECURITY_GROUP_ALB_ID" ]] && [[ "$SECURITY_GROUP_ALB_ID" != "None" ]]; then
  revoke_ingress_rules "${SECURITY_GROUP_ALB_ID}" # Chiama la funzione per revocare le regole
  aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ALB_ID}" || true
  echo "ALB Security Group eliminato."
else
  echo "ALB Security Group non trovato. Saltato."
fi

# Revoca e elimina Security Group ECS
if [[ -n "$SECURITY_GROUP_ECS_ID" ]] && [[ "$SECURITY_GROUP_ECS_ID" != "None" ]]; then
  revoke_ingress_rules "${SECURITY_GROUP_ECS_ID}" # Chiama la funzione per revocare le regole
  aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ECS_ID}" || true
  echo "ECS Security Group eliminato."
else
  echo "ECS Security Group non trovato. Saltato."
fi
echo ""

# --- 9. ECS Cluster ---
echo "Rimozione ECS Cluster..."
# Verifica l'esistenza dell'ECS Cluster
ECS_CLUSTER_ARN=$(aws ecs describe-clusters --clusters "${PROJECT_NAME}-cluster" --query 'clusters[0].clusterArn' --output text 2>/dev/null || true)
if [[ -n "$ECS_CLUSTER_ARN" ]] && [[ "$ECS_CLUSTER_ARN" != "None" ]]; then
  aws ecs delete-cluster --cluster "${ECS_CLUSTER_ARN}" || true
  echo "ECS Cluster eliminato."
else
  echo "ECS Cluster non trovato. Saltato."
fi
echo ""

# --- 10. CloudWatch Log Group ---
echo "Rimozione CloudWatch Log Group..."
LOG_GROUP_BACKEND_NAME="/ecs/${PROJECT_NAME}-backend"
# Verifica l'esistenza del CloudWatch Log Group
LOG_GROUP_BACKEND_ARN=$(aws logs describe-log-groups --log-group-name-prefix "${LOG_GROUP_BACKEND_NAME}" --query "logGroups[?logGroupName=='${LOG_GROUP_BACKEND_NAME}'].arn | [0]" --output text 2>/dev/null || true)
if [[ -n "$LOG_GROUP_BACKEND_ARN" ]] && [[ "$LOG_GROUP_BACKEND_ARN" != "None" ]]; then
  aws logs delete-log-group --log-group-name "${LOG_GROUP_BACKEND_NAME}" || true
  echo "CloudWatch Log Group eliminato."
else
  echo "CloudWatch Log Group non trovato. Saltato."
fi
echo ""

# --- 11. CodePipeline Artifact Store Bucket ---
echo "Rimozione CodePipeline Artifact Store Bucket..."
CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME_PREFIX="codepipeline-${PROJECT_NAME}-${AWS_REGION}-${AWS_ACCOUNT_ID}"
# Verifica l'esistenza del Bucket S3
CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME_PREFIX}')].Name | [0]" --output text 2>/dev/null || true)
if [[ -n "$CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME" ]] && [[ "$CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME" != "None" ]]; then
  # Svuota il bucket prima di eliminarlo
  aws s3 rm "s3://${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" --recursive --include "/*" # --exclude "*" 
  # Elimina il bucket
  aws s3api delete-bucket --bucket "${CODEPIPELINE_ARTIFACT_STORE_BUCKET_NAME}" || true
  echo "CodePipeline Artifact Store Bucket eliminato."
else
  echo "CodePipeline Artifact Store Bucket non trovato. Saltato."
fi
echo ""

# --- 12. ECR Repository ---
echo "Rimozione ECR Repository..."
ECR_REPO_BACKEND_NAME="${PROJECT_NAME}-backend"
# Verifica l'esistenza dell'ECR Repository
ECR_REPO_BACKEND_URI=$(aws ecr describe-repositories --repository-names "${ECR_REPO_BACKEND_NAME}" --query 'repositories[0].repositoryUri' --output text 2>/dev/null || true)
if [[ -n "$ECR_REPO_BACKEND_URI" ]] && [[ "$ECR_REPO_BACKEND_URI" != "None" ]]; then
  aws ecr delete-repository --repository-name "${ECR_REPO_BACKEND_NAME}" --force || true
  echo "ECR Repository Backend eliminato."
else
  echo "ECR Repository Backend non trovato. Saltato."
fi
echo ""

# --- 13. IAM Roles and Policies (Last due to dependencies) ---
echo "Rimozione IAM Roles e Policies..."

# Funzione helper per scollegare e eliminare i ruoli IAM
cleanup_iam_role() {
    local role_name="$1"
    local policy_names_to_detach="$2" # Lista di ARN di policy gestite (separate da spazio)
    local inline_policy_name="$3"

    # Verifica l'esistenza del ruolo
    local role_arn=$(aws iam get-role --role-name "${role_name}" --query 'Role.Arn' --output text 2>/dev/null || true)

    if [[ -n "$role_arn" ]] && [[ "$role_arn" != "None" ]]; then
        echo "Pulizia ruolo: ${role_name}"

        # Scollega le policy gestite
        for policy_arn in ${policy_names_to_detach}; do
            aws iam detach-role-policy --role-name "${role_name}" --policy-arn "${policy_arn}" || true
        done

        # Elimina la policy inline (se specificata)
        if [[ -n "$inline_policy_name" ]]; then
            aws iam delete-role-policy --role-name "${role_name}" --policy-name "${inline_policy_name}" || true
        fi
        
        # Elimina il ruolo
        aws iam delete-role --role-name "${role_name}" || true
        echo "Ruolo '${role_name}' eliminato."
    else
        echo "Ruolo '${role_name}' non trovato. Saltato."
    fi
}

cleanup_iam_role \
  "${PROJECT_NAME}-CodeBuildRoleBackend" \
  "arn:aws:iam::aws:policy/PowerUserAccess" \
  "CodeBuildPolicyBackend"

cleanup_iam_role \
  "${PROJECT_NAME}-EcsTaskExecutionRole" \
  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" \
  ""

cleanup_iam_role \
  "${PROJECT_NAME}-CodePipelineRole" \
  "arn:aws:iam::aws:policy/AdministratorAccess" \
  "CodePipelineAccess"

echo ""
echo "--- Tutte le risorse create (tranne il secret GitHub) sono state rimosse. ---"