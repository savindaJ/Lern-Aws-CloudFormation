#!/usr/bin/env bash
# Deploy backend via Serverless Framework (serverless.yml).
# Usage: ./backend/infra/script/deploy.sh [dev|staging|prod]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

STAGE="${1:-dev}"
REGION="${AWS_REGION:-us-west-2}"

case "$STAGE" in
  dev|staging|prod) ;;
  *)
    echo "Error: stage must be dev, staging, or prod (got: $STAGE)" >&2
    exit 1
    ;;
esac

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: Node.js/npx is required." >&2
  exit 1
fi

cd "${BACKEND_DIR}"

if [[ ! -d node_modules ]]; then
  echo "==> Installing Serverless dependencies..."
  npm install --silent
fi

echo "==> Backend deploy (Serverless) | stage=$STAGE | region=$REGION"
npx serverless deploy --stage "$STAGE" --region "$REGION"

echo ""
echo "==> Endpoints:"
npx serverless info --stage "$STAGE" --region "$REGION"

STACK_NAME="cloud-formation-api-${STAGE}"
if command -v aws >/dev/null 2>&1; then
  echo ""
  echo "==> Stack outputs:"
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
    --output table 2>/dev/null || true
fi
