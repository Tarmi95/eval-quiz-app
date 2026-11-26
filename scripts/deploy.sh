#!/usr/bin/env bash
# Déploiement de Quiz App sur Azure (ACR + Container Apps)
# Prérequis : az login, Docker démarré.
# Les secrets ne sont jamais écrits ici : ils viennent de l'environnement.
#   export ADMIN_PASSWORD=... JWT_SECRET=...   puis   ./scripts/deploy.sh
set -euo pipefail

RG=rg-quiz-app
LOC=belgiumcentral          # France Central refusée (restriction Azure for Students)
ACR=acrquizappsuli
ENV=env-quiz-app
TAG=${TAG:-1.1}
: "${ADMIN_PASSWORD:?Définir ADMIN_PASSWORD}" "${JWT_SECRET:?Définir JWT_SECRET}"

echo "== Groupe de ressources et registre"
az group create -n "$RG" -l "$LOC" -o none
az acr create -n "$ACR" -g "$RG" -l "$LOC" --sku Basic -o none
az acr login -n "$ACR"

echo "== Construction et publication des images ($TAG)"
docker build -t "$ACR.azurecr.io/quiz-backend:$TAG" ./backend
docker build -t "$ACR.azurecr.io/quiz-frontend:$TAG" .
docker push "$ACR.azurecr.io/quiz-backend:$TAG"
docker push "$ACR.azurecr.io/quiz-frontend:$TAG"

echo "== Environnement Container Apps"
az containerapp env create -n "$ENV" -g "$RG" -l "$LOC" -o none
ACR_ID=$(az acr show -n "$ACR" --query id -o tsv)

# Création + identité managée + rôle AcrPull + image (étapes séparées : plus fiable)
deploy_app () {
  local name=$1 ingress=$2 port=$3
  az containerapp create -n "$name" -g "$RG" --environment "$ENV" \
    --image mcr.microsoft.com/k8se/quickstart:latest \
    --ingress "$ingress" --target-port 80 \
    --cpu 0.25 --memory 0.5Gi --min-replicas 1 --max-replicas 1 \
    --system-assigned -o none
  local pid
  pid=$(az containerapp show -n "$name" -g "$RG" --query identity.principalId -o tsv)
  az role assignment create --assignee-object-id "$pid" \
    --assignee-principal-type ServicePrincipal --role AcrPull --scope "$ACR_ID" -o none
  sleep 30   # propagation du rôle
  az containerapp registry set -n "$name" -g "$RG" \
    --server "$ACR.azurecr.io" --identity system -o none
  az containerapp ingress update -n "$name" -g "$RG" --target-port "$port" -o none
}

echo "== Backend (privé)"
deploy_app backend internal 3007
az containerapp secret set -n backend -g "$RG" \
  --secrets admin-password="$ADMIN_PASSWORD" jwt-secret="$JWT_SECRET" -o none
az containerapp update -n backend -g "$RG" \
  --image "$ACR.azurecr.io/quiz-backend:$TAG" \
  --set-env-vars RESEND_API_KEY=re_fictive ADMIN_USERNAME=admin \
    ADMIN_PASSWORD=secretref:admin-password JWT_SECRET=secretref:jwt-secret -o none

echo "== Frontend (public)"
deploy_app frontend external 8080
az containerapp update -n frontend -g "$RG" \
  --image "$ACR.azurecr.io/quiz-frontend:$TAG" \
  --set-env-vars BACKEND_HOST=backend -o none

FQDN=$(az containerapp show -n frontend -g "$RG" --query properties.configuration.ingress.fqdn -o tsv)
echo "== Terminé : https://$FQDN"