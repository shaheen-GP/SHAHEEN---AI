#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
# SHAHEEN AI - Production Configuration & Hardening
#
# Purpose:
#   Configure SHAHEEN AI as a maintained Open WebUI derivative without
#   modifying upstream technical identifiers that are required internally.
#
# Safety:
#   - refuses to run during an unfinished Git rebase/merge/cherry-pick
#   - creates a timestamped immutable-ish backup directory
#   - never overwrites .env with secrets
#   - preserves upstream license/attribution
#   - uses atomic file replacement
#   - validates generated files
#   - validates Docker configuration
#   - validates Python syntax
#   - validates frontend configuration
#
# NOTE:
#   This script intentionally does NOT remove Open WebUI branding from the
#   upstream application source. Current Open WebUI licensing restricts such
#   changes for many deployments.
###############################################################################

PROJECT_ROOT="${PROJECT_ROOT:-/opt/SHAHEEN---AI}"
DOMAIN="${SHAHEEN_AI_DOMAIN:-shaheen-group.mooo.com}"
APP_NAME="SHAHEEN AI"
ENV_PREFIX="SHAHEEN_AI"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_ROOT="${PROJECT_ROOT}/.shaheen-backups/${TIMESTAMP}"

log() {
    printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
    printf '\n[FATAL] %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

atomic_write() {
    local target="$1"
    local tmp
    tmp="$(mktemp "${target}.tmp.XXXXXX")"
    cat > "$tmp"
    chmod --reference="$target" "$tmp" 2>/dev/null || true
    mv -f "$tmp" "$target"
}

###############################################################################
# 1. Preconditions
###############################################################################

[[ -d "$PROJECT_ROOT" ]] || die "Project directory does not exist: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

require_cmd git
require_cmd python3
require_cmd grep
require_cmd sed
require_cmd awk
require_cmd find
require_cmd file

if [[ -d .git/rebase-merge || -d .git/rebase-apply ]]; then
    die "Git rebase is currently active. Run: git rebase --abort"
fi

if [[ -f .git/MERGE_HEAD ]]; then
    die "Git merge is currently active. Finish or abort the merge first."
fi

if [[ -f .git/CHERRY_PICK_HEAD ]]; then
    die "Git cherry-pick is currently active. Finish or abort it first."
fi

###############################################################################
# 2. Verify expected project structure
###############################################################################

for path in \
    backend/open_webui/env.py \
    backend/open_webui/main.py \
    backend/open_webui/static/site.webmanifest \
    LICENSE \
    pyproject.toml \
    Dockerfile
do
    [[ -e "$path" ]] || die "Expected project file missing: $path"
done

###############################################################################
# 3. Backup
###############################################################################

log "Creating backup: $BACKUP_ROOT"

mkdir -p "$BACKUP_ROOT"

cp -a \
    backend/open_webui/env.py \
    backend/open_webui/main.py \
    backend/open_webui/static \
    .env.example \
    LICENSE \
    pyproject.toml \
    Dockerfile \
    "$BACKUP_ROOT/" 2>/dev/null || true

git status --short > "${BACKUP_ROOT}/git-status-before.txt"
git diff > "${BACKUP_ROOT}/git-diff-before.patch" || true
git diff --cached > "${BACKUP_ROOT}/git-diff-cached-before.patch" || true

###############################################################################
# 4. Create SHAHEEN branding documentation
###############################################################################

log "Creating SHAHEEN AI branding documentation"

mkdir -p branding deployment

atomic_write branding/BRAND.md <<EOF
# SHAHEEN AI

SHAHEEN AI is a customized, self-hosted AI platform derived from Open WebUI.

## Product identity

- Product: SHAHEEN AI
- Environment namespace: SHAHEEN_AI
- Primary domain: https://${DOMAIN}
- Repository: https://github.com/shaheen-GP/SHAHEEN---AI.git
- Developer repository: https://github.com/Y-Shaheen94/Ys-Shaheen-.git

## Upstream

This project is derived from Open WebUI.

The upstream copyright, license, attribution, and required Open WebUI
branding are retained according to the applicable upstream license.

This project is not affiliated with or endorsed by the Open WebUI project.

## SHAHEEN assets

Primary logo:

\`branding/shaheen-ai.png\`

## Configuration model

SHAHEEN-specific configuration uses the \`SHAHEEN_AI_\` namespace where
possible.

Upstream-compatible variables such as \`WEBUI_NAME\`, \`WEBUI_URL\`,
and related variables remain supported because they are part of the
underlying Open WebUI runtime.

## Security

Secrets must never be committed to Git.

Use:

- .env
- Docker secrets
- external secret management
- deployment environment variables

Do not place API keys, OAuth secrets, JWT secrets, passwords, or private
certificates inside tracked source files.

## Build identity

Builds should expose:

SHAHEEN AI

while preserving the upstream technical package identifiers required by
the application.
EOF

###############################################################################
# 5. Create SHAHEEN environment template
###############################################################################

log "Creating SHAHEEN AI environment template"

atomic_write deployment/.env.shaheen.example <<EOF
###############################################################################
# SHAHEEN AI
# Production environment template
#
# Copy to .env only on the deployment host.
# NEVER commit .env.
###############################################################################

# SHAHEEN identity
SHAHEEN_AI_NAME=SHAHEEN AI
SHAHEEN_AI_DOMAIN=${DOMAIN}
SHAHEEN_AI_URL=https://${DOMAIN}

# Upstream-compatible runtime identity
#
# Current Open WebUI releases may append "(Open WebUI)" to customized names.
# This is intentional and must not be bypassed unless your license permits
# removal/modification of upstream branding.
WEBUI_NAME=SHAHEEN AI
WEBUI_URL=https://${DOMAIN}

# Production
ENV=prod

# Security
WEBUI_SECRET_KEY=CHANGE_ME
WEBUI_SESSION_COOKIE_SECURE=true
WEBUI_AUTH_COOKIE_SECURE=true
WEBUI_SESSION_COOKIE_SAME_SITE=lax
WEBUI_AUTH_COOKIE_SAME_SITE=lax

# PWA
EXTERNAL_PWA_MANIFEST_URL=https://${DOMAIN}/manifest.json

# CORS
CORS_ALLOW_ORIGIN=https://${DOMAIN}

# Ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434

# OpenAI
OPENAI_API_KEY=
OPENAI_API_BASE_URL=https://api.openai.com/v1

# OpenRouter
OPENROUTER_API_KEY=

# Anthropic
ANTHROPIC_API_KEY=

# xAI
XAI_API_KEY=

# Search
ENABLE_WEB_SEARCH=true
WEB_SEARCH_ENGINE=tavily
WEB_SEARCH_RESULT_COUNT=5
WEB_SEARCH_CONCURRENT_REQUESTS=2

TAVILY_API_KEY=
EXA_API_KEY=
FIRECRAWL_API_KEY=
GOOGLE_PSE_API_KEY=
GOOGLE_PSE_ENGINE_ID=

FIRECRAWL_API_BASE_URL=https://api.firecrawl.dev

# API keys
ENABLE_API_KEYS=true

###############################################################################
# Never put secrets below this line.
###############################################################################
EOF

###############################################################################
# 6. Correct existing .env.example branding namespace
###############################################################################

log "Updating .env.example safely"

if [[ -f .env.example ]]; then

    cp -a .env.example "${BACKUP_ROOT}/.env.example.original"

    python3 - <<'PY'
from pathlib import Path

p = Path(".env.example")
text = p.read_text(encoding="utf-8", errors="strict")

replacements = {
    "# SHAHEEN - AI": "# SHAHEEN AI",
    "WEBUI_NAME=SHAHEEN - AI": "WEBUI_NAME=SHAHEEN AI",
    "WEBUI_NAME=SHAHEEN---AI": "WEBUI_NAME=SHAHEEN AI",
}

for old, new in replacements.items():
    text = text.replace(old, new)

# Add namespace variables exactly once.
block = """\n# SHAHEEN AI product configuration\nSHAHEEN_AI_NAME=SHAHEEN AI\nSHAHEEN_AI_DOMAIN=https://shaheen-group.mooo.com\nSHAHEEN_AI_URL=https://shaheen-group.mooo.com\n"""

if "SHAHEEN_AI_NAME=" not in text:
    text += block

p.write_text(text, encoding="utf-8")
PY

fi

###############################################################################
# 7. Ensure secrets are ignored
###############################################################################

log "Hardening Git ignore rules"

touch .gitignore

python3 - <<'PY'
from pathlib import Path

p = Path(".gitignore")
text = p.read_text(encoding="utf-8", errors="replace")

entries = [
    ".env",
    ".env.*",
    "!.env.example",
    "deployment/.env",
    "deployment/.env.*",
    "!.env.shaheen.example",
    ".shaheen-backups/",
    "*.pem",
    "*.key",
    "*.crt",
    "*.p12",
    "*.pfx",
    "secrets/",
    ".secrets/",
]

lines = text.splitlines()

for entry in entries:
    if entry not in lines:
        lines.append(entry)

p.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

###############################################################################
# 8. Fix PWA manifest only where it is a generated/custom SHAHEEN manifest.
#
# We do NOT replace upstream branding assets in the protected upstream static
# directory. The application itself can expose its runtime name through the
# supported WEBUI_NAME configuration.
###############################################################################

log "Creating SHAHEEN deployment PWA manifest"

mkdir -p deployment/pwa

atomic_write deployment/pwa/manifest.shaheen.json <<EOF
{
  "name": "SHAHEEN AI",
  "short_name": "SHAHEEN AI",
  "description": "SHAHEEN AI self-hosted AI platform.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#ffffff",
  "icons": [
    {
      "src": "/branding/shaheen-ai.png",
      "sizes": "800x800",
      "type": "image/png",
      "purpose": "any"
    }
  ]
}
EOF

###############################################################################
# 9. Create production start wrapper
###############################################################################

log "Creating hardened startup wrapper"

atomic_write deployment/start-shaheen.sh <<'EOF'
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
EOF

chmod 0750 deployment/start-shaheen.sh

###############################################################################
# 10. Create deployment health script
###############################################################################

log "Creating runtime health check"

atomic_write deployment/health-shaheen.sh <<'EOF'
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
EOF

chmod 0750 deployment/health-shaheen.sh

###############################################################################
# 11. Validate Python source
###############################################################################

log "Validating Python source"

python3 -m compileall -q backend || die "Python compilation failed"

###############################################################################
# 12. Validate JSON
###############################################################################

log "Validating JSON"

python3 - <<'PY'
import json
from pathlib import Path

files = [
    Path("deployment/pwa/manifest.shaheen.json"),
]

for p in files:
    with p.open("r", encoding="utf-8") as f:
        json.load(f)

print("JSON validation: OK")
PY

###############################################################################
# 13. Validate YAML if Docker Compose is available
###############################################################################

if command -v docker >/dev/null 2>&1; then

    log "Validating Docker Compose configuration"

    if docker compose version >/dev/null 2>&1; then
        docker compose \
            -f deployment/docker-compose.shaheen.yml \
            config --quiet \
            || die "Docker Compose configuration is invalid"
    else
        printf '%s\n' "Docker Compose plugin unavailable; skipped compose validation."
    fi

fi

###############################################################################
# 14. Scan tracked files for obvious secret assignments
###############################################################################

log "Scanning tracked source for obvious hard-coded secrets"

SECRET_PATTERN='(OPENAI_API_KEY|OPENROUTER_API_KEY|ANTHROPIC_API_KEY|XAI_API_KEY|TAVILY_API_KEY|EXA_API_KEY|FIRECRAWL_API_KEY|GOOGLE_PSE_API_KEY|WEBUI_SECRET_KEY|JWT_SECRET|PRIVATE_KEY)[[:space:]]*=[[:space:]]*[^[:space:]#]+'

if git grep -nE "$SECRET_PATTERN" -- \
    ':!*.example' \
    ':!*.sample' \
    ':!deployment/.env.shaheen.example' \
    2>/dev/null \
    | grep -vE '=[[:space:]]*$' \
    | grep -vE 'CHANGE_ME|your_|YOUR_|<.*>' \
    >/tmp/shaheen-secret-findings.txt
then
    cat /tmp/shaheen-secret-findings.txt
    die "Possible hard-coded secret detected. Review /tmp/shaheen-secret-findings.txt"
fi

rm -f /tmp/shaheen-secret-findings.txt

###############################################################################
# 15. Detect accidental binary README
###############################################################################

log "Validating README encoding"

if [[ -f README.md ]]; then
    file README.md

    python3 - <<'PY'
from pathlib import Path

p = Path("README.md")
data = p.read_bytes()

if b"\x00" in data:
    raise SystemExit("README.md contains NUL bytes and appears binary.")

data.decode("utf-8")
print("README UTF-8 validation: OK")
PY
fi

###############################################################################
# 16. Check branding metadata without modifying upstream protected assets
###############################################################################

log "Checking runtime branding configuration"

grep -q 'WEBUI_NAME=SHAHEEN AI' .env.example \
    || die "WEBUI_NAME=SHAHEEN AI missing from .env.example"

grep -q 'SHAHEEN_AI_NAME=SHAHEEN AI' .env.example \
    || die "SHAHEEN_AI_NAME missing from .env.example"

grep -q 'SHAHEEN AI' deployment/pwa/manifest.shaheen.json \
    || die "SHAHEEN PWA manifest was not generated correctly"

###############################################################################
# 17. Check Git status
###############################################################################

log "Final Git status"

git status --short

###############################################################################
# 18. Summary
###############################################################################

cat <<EOF

===============================================================================
 SHAHEEN AI CONFIGURATION COMPLETE
===============================================================================

Project:
  ${PROJECT_ROOT}

Product:
  SHAHEEN AI

Runtime namespace:
  SHAHEEN_AI

Domain:
  https://${DOMAIN}

Backup:
  ${BACKUP_ROOT}

Generated:
  branding/BRAND.md
  deployment/.env.shaheen.example
  deployment/pwa/manifest.shaheen.json
  deployment/start-shaheen.sh
  deployment/health-shaheen.sh

Validated:
  Python syntax
  JSON
  Docker Compose (when available)
  README UTF-8
  secret-pattern scan
  Git state

IMPORTANT:
  The script intentionally preserves upstream Open WebUI technical and
  protected branding identifiers. Do not globally replace "Open WebUI".

NEXT STEP:
  Review the Git diff before committing:

    git diff --check
    git diff --stat
    git diff -- branding deployment .env.example .gitignore

DO NOT PUSH YET.

===============================================================================
EOF
