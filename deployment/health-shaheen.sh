#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

DOMAIN="${SHAHEEN_AI_DOMAIN:-shaheen-group.mooo.com}"
URL="${SHAHEEN_AI_URL:-https://${DOMAIN}}"

printf 'SHAHEEN AI URL: %s\n' "$URL"

curl_args=(
    --fail
    --silent
    --show-error
    --location
    --connect-timeout 10
    --max-time 30
)

if command -v curl >/dev/null 2>&1; then
    curl "${curl_args[@]}" -o /dev/null "$URL"
else
    printf 'curl is required for the HTTP health check.\n' >&2
    exit 1
fi

printf 'HTTP health check: OK\n'
