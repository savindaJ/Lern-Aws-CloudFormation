#!/usr/bin/env bash
# Delete frontend CloudFormation stack (empties S3 bucket first).
# Usage: ./frontend/infra/script/destroy.sh [dev|staging|prod]
set -euo pipefail

STAGE="${1:-dev}"
REGION="${AWS_REGION:-us-west-2}"
STACK_NAME="cloud-formation-web-${STAGE}"

case "$STAGE" in
  dev|staging|prod) ;;
  *)
    echo "Error: stage must be dev, staging, or prod (got: $STAGE)" >&2
    exit 1
    ;;
esac

if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1; then
  BUCKET="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='WebsiteBucketName'].OutputValue" \
    --output text 2>/dev/null || true)"

  if [[ -n "$BUCKET" && "$BUCKET" != "None" ]] \
    && aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
    echo "==> Emptying s3://${BUCKET}/"
    aws s3 rm "s3://${BUCKET}/" --recursive --region "$REGION" || true
  fi

  echo "==> Deleting stack ${STACK_NAME}"
  aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
  aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"
fi

echo "==> Frontend stack deleted."
