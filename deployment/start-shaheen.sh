#!/usr/bin/env bash
set -e

cd /opt/SHAHEEN---AI

echo "========================================"
echo "        HACK-Y.Z.SHAHEEN AI"
echo "========================================"

if [ -f docker-compose.yml ]; then
    docker compose up -d --build
elif [ -f deployment/docker-compose.shaheen.yml ]; then
    docker compose -f deployment/docker-compose.shaheen.yml up -d --build
else
    echo "No Docker Compose configuration found."
    exit 1
fi
