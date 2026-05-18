#!/usr/bin/env bash
# Build frontend dist for a stage.
# Usage: ./frontend/infra/script/build.sh [dev|staging|prod]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

STAGE="${1:-dev}"
REGION="${AWS_REGION:-us-west-2}"
STACK_NAME="cloud-formation-web-${STAGE}"
BACKEND_STACK="cloud-formation-api-${STAGE}"

case "$STAGE" in
  dev|staging|prod) ;;
  *)
    echo "Error: stage must be dev, staging, or prod (got: $STAGE)" >&2
    exit 1
    ;;
esac

if [[ -z "${VITE_API_URL:-}" ]] && command -v aws >/dev/null 2>&1; then
  VITE_API_URL="$(aws cloudformation describe-stacks \
    --stack-name "$BACKEND_STACK" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text 2>/dev/null || true)"
  [[ "$VITE_API_URL" == "None" ]] && VITE_API_URL=""
fi

if [[ -z "${VITE_APP_URL:-}" ]] && command -v aws >/dev/null 2>&1; then
  VITE_APP_URL="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" \
    --output text 2>/dev/null || true)"
  [[ "$VITE_APP_URL" == "None" ]] && VITE_APP_URL=""
fi

export VITE_STAGE="$STAGE"
export VITE_API_URL="${VITE_API_URL:-}"
export VITE_APP_URL="${VITE_APP_URL:-}"

echo "==> Frontend build | stage=$STAGE"
cd "${FRONTEND_DIR}"
npm ci --silent 2>/dev/null || npm install --silent
npm run "build:${STAGE}"
echo "==> Dist ready: ${FRONTEND_DIR}/dist"
