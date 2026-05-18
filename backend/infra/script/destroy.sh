#!/usr/bin/env bash
# Remove backend Serverless stack for a stage.
# Usage: ./backend/infra/script/destroy.sh [dev|staging|prod]
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

cd "${BACKEND_DIR}"

echo "==> Removing Serverless stack | stage=$STAGE | region=$REGION"
npx serverless remove --stage "$STAGE" --region "$REGION"
echo "==> Backend stack removed."
