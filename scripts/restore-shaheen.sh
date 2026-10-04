#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage:"
    echo "$0 /path/to/open-webui-backup.tar.gz"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

docker compose -f /opt/open-webui/docker-compose.yml down

docker run --rm \
  -v open-webui:/data \
  -v "$(dirname "$BACKUP_FILE")":/backup:ro \
  alpine:latest \
  sh -c "rm -rf /data/* /data/.[!.]* /data/..?* 2>/dev/null || true; tar -xzf /backup/$(basename "$BACKUP_FILE") -C /data"

docker compose -f /opt/open-webui/docker-compose.yml up -d
