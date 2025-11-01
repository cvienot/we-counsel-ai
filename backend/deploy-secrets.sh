#!/bin/bash

# Deploy secrets to AWS Secrets Manager using CloudFormation

set -e

REGION="eu-west-3"
STACK_NAME="we-counsel-secrets"

echo "===================================="
echo "We Counsel AI - Secrets Deployment"
echo "===================================="
echo ""

# Check AWS CLI
echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi
echo "✅ AWS CLI is configured"
echo ""

# Collect secrets
echo "2. Collecting secrets to store in AWS Secrets Manager..."
echo ""

# JWT Secret
echo "Enter JWT_SECRET (or press Enter to auto-generate):"
read -s JWT_SECRET
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
    echo "Generated JWT_SECRET: $JWT_SECRET"
fi
echo ""

# OpenAI API Key
echo "Enter OPENAI_API_KEY:"
read -s OPENAI_API_KEY
echo ""

# AWS Credentials (optional)
echo ""
echo "AWS Credentials (optional - leave empty to use IAM roles):"
echo "Enter AWS_ACCESS_KEY_ID (or press Enter to skip):"
read AWS_KEY_ID
AWS_KEY_ID=${AWS_KEY_ID:-USE_IAM_ROLE}

if [ "$AWS_KEY_ID" != "USE_IAM_ROLE" ]; then
    echo "Enter AWS_SECRET_ACCESS_KEY:"
    read -s AWS_SECRET_KEY
else
    AWS_SECRET_KEY="USE_IAM_ROLE"
    echo "✅ Will use IAM roles instead of credentials"
fi
echo ""

# Email
echo "Enter EMAIL_FROM (verified SES email):"
read EMAIL_FROM
echo ""

# Frontend URL
echo "Enter FRONTEND_URL (default: http://localhost:8080):"
read FRONTEND_URL
FRONTEND_URL=${FRONTEND_URL:-http://localhost:8080}
echo ""

# Deploy secrets
echo "3. Deploying secrets to AWS Secrets Manager..."
echo ""

aws cloudformation deploy \
    --template-file cloudformation-secrets.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        JWTSecret="$JWT_SECRET" \
        OpenAIAPIKey="$OPENAI_API_KEY" \
        AWSAccessKeyId="$AWS_KEY_ID" \
        AWSSecretAccessKey="$AWS_SECRET_KEY" \
        EmailFrom="$EMAIL_FROM" \
        FrontendURL="$FRONTEND_URL" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Secrets deployed successfully to AWS Secrets Manager!"
    echo ""
    
    # Get secret ARNs
    echo "📦 Secret ARNs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' \
        --output table
    
    echo ""
    echo "🔐 Your secrets are now stored securely in AWS Secrets Manager"
    echo ""
    echo "Next steps:"
    echo "1. Deploy App Runner using: ./deploy-apprunner.sh"
    echo "2. The App Runner service will automatically access these secrets"
    echo "3. Update secrets anytime with: aws secretsmanager update-secret"
    echo ""
    echo "To rotate secrets:"
    echo "  aws secretsmanager rotate-secret --secret-id we-counsel/jwt-secret --region $REGION"
else
    echo ""
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi
