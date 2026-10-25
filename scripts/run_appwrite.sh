#!/usr/bin/env bash
# Run Bloom against the Appwrite project in .env (never passes APPWRITE_API_KEY).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Copy .env.example to .env and fill APPWRITE_ENDPOINT and APPWRITE_PROJECT_ID." >&2
  exit 64
fi

# shellcheck disable=SC1091
set -a && source .env && set +a

if [[ -z "${APPWRITE_ENDPOINT:-}" || -z "${APPWRITE_PROJECT_ID:-}" ]]; then
  echo "Set APPWRITE_ENDPOINT and APPWRITE_PROJECT_ID in .env." >&2
  exit 64
fi

DEVICE="${1:-chrome}"
shift || true

exec flutter run -d "$DEVICE" \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="${BLOOMLY_UPI_ID:-}" \
  --dart-define=BLOOMLY_UPI_NAME="${BLOOMLY_UPI_NAME:-Bloom}" \
  "$@"
