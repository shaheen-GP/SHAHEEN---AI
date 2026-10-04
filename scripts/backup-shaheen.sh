#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/open-webui/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/open-webui-backup-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v open-webui:/data:ro \
  -v "$BACKUP_DIR":/backup \
  alpine:latest \
  tar -czf "/backup/open-webui-backup-$TIMESTAMP.tar.gz" -C /data .

echo "Backup created:"
echo "$BACKUP_FILE"
