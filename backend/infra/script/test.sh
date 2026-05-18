#!/usr/bin/env bash
# Smoke-test deployed backend API.
# Usage: ./backend/infra/script/test.sh [dev|staging|prod]
set -euo pipefail

STAGE="${1:-dev}"
REGION="${AWS_REGION:-us-west-2}"
STACK_NAME="cloud-formation-api-${STAGE}"

case "$STAGE" in
  dev|staging|prod) ;;
  *)
    echo "Error: stage must be dev, staging, or prod (got: $STAGE)" >&2
    exit 1
    ;;
esac

BASE_URL="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
  --output text 2>/dev/null || true)"

if [[ -z "$BASE_URL" || "$BASE_URL" == "None" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BACKEND_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  cd "${BACKEND_DIR}"
  BASE_URL="$(npx serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null \
    | awk '/HttpApiUrl|endpoint/ {print $NF; exit}' | tr -d '\r')"
fi

if [[ -z "$BASE_URL" || "$BASE_URL" == "None" ]]; then
  echo "Error: Could not resolve API URL for stage $STAGE" >&2
  exit 1
fi

echo "==> GET ${BASE_URL}/health"
curl -sS "${BASE_URL}/health" | python3 -m json.tool

echo ""
echo "==> POST ${BASE_URL}/ai/chat"
curl -sS -X POST "${BASE_URL}/ai/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello from local test"}' | python3 -m json.tool
