#!/usr/bin/env bash
# Supprime TOUTES les ressources Azure du projet (irréversible).
# À lancer uniquement après avoir sauvegardé les preuves et avec l'accord du formateur.
set -euo pipefail
RG=rg-quiz-app
read -r -p "Supprimer définitivement le groupe $RG et tout son contenu ? (oui/non) " rep
[ "$rep" = "oui" ] || { echo "Annulé."; exit 0; }
az group delete -n "$RG" --yes --no-wait
echo "Suppression lancée (quelques minutes) : az group show -n $RG pour suivre."