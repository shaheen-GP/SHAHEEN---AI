# SHAHEEN AI

SHAHEEN AI is a customized, self-hosted AI platform derived from Open WebUI.

## Product identity

- Product: SHAHEEN AI
- Environment namespace: SHAHEEN_AI
- Primary domain: https://shaheen-group.mooo.com
- Repository: https://github.com/shaheen-GP/SHAHEEN---AI.git
- Developer repository: https://github.com/Y-Shaheen94/Ys-Shaheen-.git

## Upstream

This project is derived from Open WebUI.

The upstream copyright, license, attribution, and required Open WebUI
branding are retained according to the applicable upstream license.

This project is not affiliated with or endorsed by the Open WebUI project.

## SHAHEEN assets

Primary logo:

`branding/shaheen-ai.png`

## Configuration model

SHAHEEN-specific configuration uses the `SHAHEEN_AI_` namespace where
possible.

Upstream-compatible variables such as `WEBUI_NAME`, `WEBUI_URL`,
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
