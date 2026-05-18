#!/usr/bin/env bash
# Deploy frontend: CloudFormation (S3 + CloudFront) → build → S3 upload → return URL.
# Usage: ./frontend/infra/script/deploy.sh [dev|staging|prod]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRONTEND_DIR="$(cd "${INFRA_DIR}/.." && pwd)"

STAGE="${1:-dev}"
REGION="${AWS_REGION:-us-west-2}"
TEMPLATE="${INFRA_DIR}/template.yaml"
PARAMS_FILE="${INFRA_DIR}/parameters/${STAGE}.json"
STACK_NAME="cloud-formation-web-${STAGE}"
BACKEND_STACK="cloud-formation-api-${STAGE}"

case "$STAGE" in
  dev|staging|prod) ;;
  *)
    echo "Error: stage must be dev, staging, or prod (got: $STAGE)" >&2
    exit 1
    ;;
esac

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI is required." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "Error: Node.js/npm is required." >&2
  exit 1
fi

if [[ ! -f "$PARAMS_FILE" ]]; then
  echo "Error: parameters file not found: $PARAMS_FILE" >&2
  exit 1
fi

echo "==> Frontend deploy (CloudFormation) | stage=$STAGE | region=$REGION"

echo "==> Deploying stack: ${STACK_NAME}"
aws cloudformation deploy \
  --template-file "$TEMPLATE" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --parameter-overrides file://"${PARAMS_FILE}" \
  --no-fail-on-empty-changeset

BUCKET="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteBucketName'].OutputValue" \
  --output text)"

DIST_ID="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
  --output text)"

WEBSITE_URL="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" \
  --output text)"

API_URL=""
if aws cloudformation describe-stacks --stack-name "$BACKEND_STACK" --region "$REGION" >/dev/null 2>&1; then
  API_URL="$(aws cloudformation describe-stacks \
    --stack-name "$BACKEND_STACK" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text)"
fi

export VITE_STAGE="$STAGE"
export VITE_API_URL="${API_URL:-}"
export VITE_APP_URL="$WEBSITE_URL"
"${SCRIPT_DIR}/build.sh" "$STAGE"

echo "==> Uploading dist/ to s3://${BUCKET}/"
aws s3 sync "${FRONTEND_DIR}/dist/" "s3://${BUCKET}/" \
  --region "$REGION" \
  --delete \
  --cache-control "public,max-age=31536000,immutable" \
  --exclude "index.html" \
  --exclude "*.html"

aws s3 sync "${FRONTEND_DIR}/dist/" "s3://${BUCKET}/" \
  --region "$REGION" \
  --exclude "*" \
  --include "*.html" \
  --cache-control "public,max-age=0,must-revalidate"

echo "==> Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --output text --query "Invalidation.Id" >/dev/null

echo ""
echo "==> WebsiteUrl: ${WEBSITE_URL}"
