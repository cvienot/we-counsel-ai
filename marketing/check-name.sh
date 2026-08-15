#!/bin/bash
# Vérifie la disponibilité .com / .app / .fr d'un ou plusieurs noms de marque.
# Usage : ./check-name.sh monnom autrenom ...
# LIBRE = le domaine est disponible à l'achat.
# Ensuite, pour un candidat sérieux :
#   1. SERP : googler "nom" entre guillemets (la requête doit être pauvre/vide)
#   2. Marques : https://data.inpi.fr (FR) et https://euipo.europa.eu/eSearch (UE)
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage : $0 <nom> [nom...]"
  exit 1
fi

for name in "$@"; do
  com=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://rdap.verisign.com/com/v1/domain/${name}.com" || echo err)
  app=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L "https://rdap.org/domain/${name}.app" || echo err)
  fr=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://rdap.nic.fr/domain/${name}.fr" || echo err)
  fmt() { [ "$1" = "404" ] && echo "LIBRE" || { [ "$1" = "200" ] && echo "pris" || echo "?"; }; }
  printf "%-20s .com: %-6s .app: %-6s .fr: %s\n" "$name" "$(fmt "$com")" "$(fmt "$app")" "$(fmt "$fr")"
done
