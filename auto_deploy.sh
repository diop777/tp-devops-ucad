#!/bin/bash

# ============================================================
# auto_deploy.sh - Script de déploiement automatique
# UCAD - Département Informatique - TP DevOps 2025-2026
# ============================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---- Fichier de log ----
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

# Fonction de log avec horodatage (Question 2)
log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a "$LOG_FILE"
}

log "INFO" "${GREEN}=== Déploiement automatique ===${NC}"

# ---- Vérification de l'argument (Question 1) ----
# Le script accepte l'URL du dépôt en paramètre
if [ -z "$1" ]; then
    log "ERROR" "${RED}Usage : $0 <URL_DU_DEPOT> [NOM_DOSSIER]${NC}"
    log "ERROR" "Exemple : $0 https://github.com/mon-user/mon-app.git mon_app"
    exit 1
fi

REPO_URL="$1"
PROJECT_DIR="${2:-mon_app}"   # Valeur par défaut si non fourni

log "INFO" "Dépôt cible  : $REPO_URL"
log "INFO" "Dossier local : $PROJECT_DIR"

# ---- Vérification des dépendances ----
log "INFO" "Vérification des dépendances..."

for cmd in git node npm; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        log "ERROR" "${RED}$cmd est requis mais non installé. Abandon.${NC}"
        exit 1
    fi
    log "INFO" "  ✔ $cmd trouvé : $(command -v $cmd)"
done

# ---- Clonage ou mise à jour du dépôt ----
if [ -d "$PROJECT_DIR" ]; then
    log "INFO" "Le répertoire $PROJECT_DIR existe déjà. Mise à jour..."
    cd "$PROJECT_DIR" || exit 1
    git pull >> "../$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "${RED}Échec du git pull. Abandon.${NC}"
        exit 1
    fi
else
    log "INFO" "Clonage du repository..."
    git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "${RED}Échec du clonage. Vérifiez l'URL. Abandon.${NC}"
        exit 1
    fi
    cd "$PROJECT_DIR" || exit 1
fi

# ---- Installation des dépendances ----
log "INFO" "Installation des dépendances npm..."
npm install >> "../$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "ERROR" "${RED}Échec de npm install. Abandon.${NC}"
    exit 1
fi
log "INFO" "${GREEN}Dépendances installées avec succès.${NC}"

# ---- Lancement des tests ----
log "INFO" "Lancement des tests unitaires..."
npm test >> "../$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log "INFO" "${GREEN}Tests passés avec succès.${NC}"

    # ---- Démarrage en arrière-plan + sauvegarde du PID (Question 3) ----
    log "INFO" "Démarrage de l'application en arrière-plan..."
    npm start >> "../$LOG_FILE" 2>&1 &
    APP_PID=$!

    # Sauvegarder le PID dans un fichier
    echo "$APP_PID" > "../app.pid"
    log "INFO" "${GREEN}Application démarrée. PID : $APP_PID (sauvegardé dans app.pid)${NC}"
    log "INFO" "Pour arrêter l'application : kill \$(cat app.pid)"
else
    log "ERROR" "${RED}Échec des tests. Déploiement interrompu.${NC}"
    exit 1
fi

log "INFO" "${GREEN}=== Déploiement terminé avec succès ===${NC}"
log "INFO" "Logs disponibles dans : $LOG_FILE"
