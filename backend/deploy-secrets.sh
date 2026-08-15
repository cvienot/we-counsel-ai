#!/bin/bash

# Deploy secrets to AWS Secrets Manager using CloudFormation

set -e

REGION="eu-west-3"
STACK_NAME="we-counsel-secrets"

echo "===================================="
echo "Entrelace - Secrets Deployment"
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

echo "Enter STRIPE_SECRET_KEY (live sk_live_ or rk_live_):"
read -s STRIPE_SECRET_KEY
echo ""

echo "Enter STRIPE_WEBHOOK_SECRET (live whsec_ for production endpoint):"
read -s STRIPE_WEBHOOK_SECRET
echo ""

echo "Enter STRIPE_PRICE_ESSENTIAL_MONTHLY:"
read STRIPE_PRICE_ESSENTIAL_MONTHLY
echo ""

echo "Enter STRIPE_PRICE_ESSENTIAL_ANNUAL:"
read STRIPE_PRICE_ESSENTIAL_ANNUAL
echo ""

echo "Enter STRIPE_PRICE_PREMIUM_MONTHLY:"
read STRIPE_PRICE_PREMIUM_MONTHLY
echo ""

echo "Enter STRIPE_PRICE_PREMIUM_ANNUAL:"
read STRIPE_PRICE_PREMIUM_ANNUAL
echo ""

echo "ℹ️  Non-sensitive config (AWS_REGION, EMAIL_FROM, FRONTEND_URL) is stored in apprunner.yaml"
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
        StripeSecretKey="$STRIPE_SECRET_KEY" \
        StripeWebhookSecret="$STRIPE_WEBHOOK_SECRET" \
        StripePriceEssentialMonthly="$STRIPE_PRICE_ESSENTIAL_MONTHLY" \
        StripePriceEssentialAnnual="$STRIPE_PRICE_ESSENTIAL_ANNUAL" \
        StripePricePremiumMonthly="$STRIPE_PRICE_PREMIUM_MONTHLY" \
        StripePricePremiumAnnual="$STRIPE_PRICE_PREMIUM_ANNUAL" \
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
