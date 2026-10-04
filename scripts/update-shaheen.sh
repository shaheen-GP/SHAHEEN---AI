#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/opt/SHAHEEN---AI"

cd "$PROJECT_DIR"

git fetch origin
git pull --ff-only origin main

echo "SHAHEEN - AI source updated."
