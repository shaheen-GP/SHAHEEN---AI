#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/opt/SHAHEEN---AI"

cd "$PROJECT_DIR"

if [ ! -f ".env" ]; then
    cp .env.example .env
    chmod 600 .env
    echo "Created $PROJECT_DIR/.env"
    echo "Edit .env before starting SHAHEEN - AI."
    exit 0
fi

echo "SHAHEEN - AI environment already exists."
