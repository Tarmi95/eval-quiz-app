#!/usr/bin/env bash
# =====================================================================
# deploy.sh – Déploiement de Quiz App sur Azure (J3 : groupe + ACR + images)
# Prérequis : Azure CLI installé, "az login" fait, Docker lancé.
# Aucun secret dans ce fichier : les mots de passe seront passés plus tard
# (J4/J5) via des variables d'environnement ou des secrets Container Apps.
# Usage : ./scripts/deploy.sh   (depuis la racine du projet)
# =====================================================================

# Arrêter le script à la première erreur (-e), sur variable non définie (-u)
# et si une commande d'un pipe échoue (-o pipefail)
set -euo pipefail

# ---------------------------------------------------------------------
# Variables (modifiables sans toucher au reste du script)
# La syntaxe ${VAR:-valeur} = utiliser VAR si elle existe, sinon la valeur par défaut
# ---------------------------------------------------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-<rg-quiz-app>}"   # Groupe de ressources
LOCATION="${LOCATION:-<francecentral>}"             # Région autorisée par l'abonnement étudiant
ACR_NAME="${ACR_NAME:-<nomdupregistre>}"            # Nom ACR : unique au monde, minuscules + chiffres, 5-50 caractères

# Tag des images = SHA court du commit Git (traçable : 1 image = 1 commit)
TAG="$(git rev-parse --short HEAD)"

echo "==> Groupe : $RESOURCE_GROUP | Région : $LOCATION | ACR : $ACR_NAME | Tag : $TAG"

# ---------------------------------------------------------------------
# 1. Vérifier qu'on est connecté à Azure (sinon arrêt avec un message clair)
# ---------------------------------------------------------------------
az account show --query "{abonnement:name}" -o table >/dev/null \
  || { echo "Pas connecté : lancez 'az login --use-device-code'"; exit 1; }

# ---------------------------------------------------------------------
# 2. Enregistrer les fournisseurs Azure nécessaires (sans effet s'ils le sont déjà)
# ---------------------------------------------------------------------
az provider register --namespace Microsoft.ContainerRegistry --wait
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

# ---------------------------------------------------------------------
# 3. Créer le groupe de ressources (sans effet s'il existe déjà)
# ---------------------------------------------------------------------
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o none

# ---------------------------------------------------------------------
# 4. Créer le registre ACR seulement s'il n'existe pas encore
#    SKU Basic = l'offre la moins chère, suffisante pour le projet
# ---------------------------------------------------------------------
if ! az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" -o none 2>/dev/null; then
  echo "==> Création du registre $ACR_NAME"
  az acr create --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" --sku Basic -o none
else
  echo "==> Le registre $ACR_NAME existe déjà"
fi

# Adresse complète du registre, ex : monregistre.azurecr.io
ACR_SERVER="$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)"

# ---------------------------------------------------------------------
# 5. Se connecter au registre avec son compte Azure (pas de mot de passe stocké)
# ---------------------------------------------------------------------
az acr login --name "$ACR_NAME"

# ---------------------------------------------------------------------
# 6. Construire, taguer et pousser les 2 images
#    --platform linux/amd64 : architecture des serveurs Azure
# ---------------------------------------------------------------------
docker build --platform linux/amd64 -t "$ACR_SERVER/quiz-backend:$TAG" ./backend
docker build --platform linux/amd64 -t "$ACR_SERVER/quiz-frontend:$TAG" .

docker push "$ACR_SERVER/quiz-backend:$TAG"
docker push "$ACR_SERVER/quiz-frontend:$TAG"

# ---------------------------------------------------------------------
# 7. Vérification : lister les tags présents dans le registre (preuve J3)
# ---------------------------------------------------------------------
echo "==> Images dans $ACR_SERVER :"
az acr repository show-tags --name "$ACR_NAME" --repository quiz-backend -o table
az acr repository show-tags --name "$ACR_NAME" --repository quiz-frontend -o table

# ---------------------------------------------------------------------
# J4 (à venir) : environnement Container Apps + applications backend et frontend
# ---------------------------------------------------------------------
echo "==> J3 terminé : images $TAG publiées dans $ACR_SERVER"