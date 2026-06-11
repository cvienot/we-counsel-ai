#!/bin/bash

# Deploy marketing website to S3 + CloudFront
set -e

REGION="eu-west-3"
STACK_NAME="we-connect-marketing"
DOMAIN="we-connect-app.com"
HOSTED_ZONE_ID="Z0856928IQYP7JTR6GFB"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "We Connect - Marketing Site Deployment"
echo "========================================="
echo ""

# Check AWS CLI
echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured."
    exit 1
fi
echo "✅ AWS CLI configured"
echo ""

# CloudFront requires ACM certificate in us-east-1
echo "2. Checking for ACM certificate in us-east-1..."
CERT_ARN=$(aws acm list-certificates \
    --region us-east-1 \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" \
    --output text 2>/dev/null || echo "")

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" = "None" ]; then
    echo "⚠️  No ACM certificate found in us-east-1 for ${DOMAIN}"
    echo ""
    echo "CloudFront requires certificates in us-east-1."
    echo "Requesting certificate now..."
    
    CERT_ARN=$(aws acm request-certificate \
        --domain-name "$DOMAIN" \
        --subject-alternative-names "*.${DOMAIN}" \
        --validation-method DNS \
        --region us-east-1 \
        --query 'CertificateArn' \
        --output text)
    
    echo "✅ Certificate requested: $CERT_ARN"
    echo ""
    
    # Wait for DNS validation records
    echo "   Waiting for validation details..."
    sleep 5
    
    VALIDATION_NAME=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[0].ResourceRecord.Name' \
        --output text)
    
    VALIDATION_VALUE=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[0].ResourceRecord.Value' \
        --output text)
    
    echo "   Adding DNS validation record..."
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"${VALIDATION_NAME}\",
                    \"Type\": \"CNAME\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{\"Value\": \"${VALIDATION_VALUE}\"}]
                }
            }]
        }" > /dev/null 2>&1
    
    echo "   ✅ DNS validation record added"
    echo ""
    echo "   ⏳ Waiting for certificate validation (this may take a few minutes)..."
    echo "   Note: DNS must be propagated from OVH first."
    echo ""
    
    aws acm wait certificate-validated \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 2>/dev/null || {
        echo "   ⚠️  Certificate not yet validated."
        echo "   This is expected if OVH nameservers haven't been updated yet."
        echo "   Re-run this script after DNS propagation."
        exit 1
    }
    
    echo "   ✅ Certificate validated"
else
    # Check if it's validated
    CERT_STATUS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.Status' \
        --output text)
    
    if [ "$CERT_STATUS" != "ISSUED" ]; then
        echo "⚠️  Certificate exists but status is: $CERT_STATUS"
        echo "   Wait for DNS validation or re-run after OVH nameserver update."
        exit 1
    fi
    echo "✅ Certificate found: $CERT_ARN"
fi
echo ""

# Deploy CloudFormation stack
echo "3. Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file "$SCRIPT_DIR/cloudformation-marketing.yaml" \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        DomainName="$DOMAIN" \
        CertificateArn="$CERT_ARN" \
        HostedZoneId="$HOSTED_ZONE_ID" \
    --region $REGION

echo "✅ CloudFormation stack deployed"
echo ""

# Get bucket name and distribution ID
BUCKET=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

# Upload files to S3
echo "4. Uploading marketing site to S3..."
aws s3 sync "$SCRIPT_DIR/" "s3://${BUCKET}/" \
    --exclude "*.sh" \
    --exclude "*.yaml" \
    --exclude "*.yml" \
    --exclude ".DS_Store" \
    --exclude "README*" \
    --cache-control "public, max-age=86400" \
    --region $REGION

# Set shorter cache for HTML files, including localized pages.
while IFS= read -r HTML_FILE; do
    S3_KEY="${HTML_FILE#$SCRIPT_DIR/}"
    aws s3 cp "$HTML_FILE" "s3://${BUCKET}/${S3_KEY}" \
        --cache-control "public, max-age=300" \
        --content-type "text/html; charset=utf-8" \
        --region $REGION

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

# Invalidate CloudFront cache
echo "5. Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text > /dev/null 2>&1

echo "✅ Cache invalidation started"
echo ""

echo "========================================="
echo "✅ Marketing site deployed!"
echo ""
echo "🌐 https://${DOMAIN}"
echo "🌐 https://www.${DOMAIN}"
echo ""
echo "S3 Bucket: ${BUCKET}"
echo "CloudFront Distribution: ${DISTRIBUTION_ID}"
echo "========================================="
