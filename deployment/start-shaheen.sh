#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_ROOT="${PROJECT_ROOT:-/opt/SHAHEEN---AI}"

cd "$PROJECT_ROOT"

export SHAHEEN_AI_NAME="${SHAHEEN_AI_NAME:-SHAHEEN AI}"
export SHAHEEN_AI_DOMAIN="${SHAHEEN_AI_DOMAIN:-shaheen-group.mooo.com}"
export SHAHEEN_AI_URL="${SHAHEEN_AI_URL:-https://${SHAHEEN_AI_DOMAIN}}"

# Underlying Open WebUI runtime variable.
export WEBUI_NAME="${WEBUI_NAME:-SHAHEEN AI}"
export WEBUI_URL="${WEBUI_URL:-${SHAHEEN_AI_URL}}"
export ENV="${ENV:-prod}"

umask 027

exec docker compose \
    -f deployment/docker-compose.shaheen.yml \
    up -d --remove-orphans
