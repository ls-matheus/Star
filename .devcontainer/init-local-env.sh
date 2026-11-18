#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVATE_ENV="$ROOT/config/env/development.env"
TEMPLATE="$ROOT/config/env/development.example.env"

if [[ ! -f "$PRIVATE_ENV" ]]; then
  cp "$TEMPLATE" "$PRIVATE_ENV"
  chmod 600 "$PRIVATE_ENV"
  printf '%s\n' "Created private local development.env from development.example.env. Not for production."
fi
