#!/bin/bash

# Deploy marketing website to S3 + CloudFront.
#
# The infrastructure (bucket, CloudFront distribution, OAC, DNS, ACM cert)
# already exists and is NOT managed by this script. The CloudFormation
# template kept in this directory was never successfully applied; the live
# resources are referenced directly below.
set -euo pipefail

REGION="eu-west-3"
BUCKET="we-connect-marketing-eu-west-3"
DISTRIBUTION_ID="E1R3P7NKXEJIPP"
DOMAIN="entrelace.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "Entrelace - Marketing Site Deployment"
echo "========================================="
echo ""

echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured."
    exit 1
fi
echo "✅ AWS CLI configured"
echo ""

# Upload files to S3. Internal docs (*.md), infra files and dotfiles must
# never reach the public bucket.
echo "2. Uploading marketing site to s3://${BUCKET}..."
aws s3 sync "$SCRIPT_DIR/" "s3://${BUCKET}/" \
    --exclude "*.sh" \
    --exclude "*.yaml" \
    --exclude "*.yml" \
    --exclude "*.md" \
    --exclude "*.DS_Store" \
    --exclude "README*" \
    --cache-control "public, max-age=86400" \
    --region $REGION

# HTML gets a short cache so content updates propagate quickly. For every
# fr/<slug>/index.html an object is also written at the directory key
# "fr/<slug>/" because the CloudFront origin is the S3 REST endpoint, which
# only maps "/" to index.html (DefaultRootObject), not subdirectories.
echo ""
echo "3. Uploading HTML with short cache + directory keys..."
while IFS= read -r HTML_FILE; do
    S3_KEY="${HTML_FILE#$SCRIPT_DIR/}"
    aws s3 cp "$HTML_FILE" "s3://${BUCKET}/${S3_KEY}" \
        --cache-control "public, max-age=300" \
        --content-type "text/html; charset=utf-8" \
        --region $REGION \
        --only-show-errors

    if [[ "$S3_KEY" == */index.html ]]; then
        DIRECTORY_KEY="${S3_KEY%index.html}"
        aws s3api put-object \
            --bucket "$BUCKET" \
            --key "$DIRECTORY_KEY" \
            --body "$HTML_FILE" \
            --cache-control "public, max-age=300" \
            --content-type "text/html; charset=utf-8" \
            --region $REGION > /dev/null
    fi
done < <(find "$SCRIPT_DIR" -name "*.html" -type f)
echo "✅ Files uploaded"
echo ""

echo "4. Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)
echo "✅ Cache invalidation started (${INVALIDATION_ID})"
echo ""

echo "========================================="
echo "✅ Marketing site deployed!"
echo ""
echo "🌐 https://${DOMAIN}"
echo "🌐 https://www.${DOMAIN}"
echo ""
echo "S3 Bucket: ${BUCKET} (${REGION})"
echo "CloudFront Distribution: ${DISTRIBUTION_ID}"
echo "========================================="
