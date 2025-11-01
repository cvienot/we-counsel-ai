#!/bin/bash

# Deploy App Runner service using CloudFormation
# This script helps you set up and deploy your App Runner service

set -e

REGION="eu-west-3"
STACK_NAME="we-counsel-apprunner"

echo "================================"
echo "We Counsel AI - App Runner Setup"
echo "================================"
echo ""

# Check if AWS CLI is configured
echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi
echo "✅ AWS CLI is configured"
echo ""

# Check if GitHub connection exists
echo "2. Checking for GitHub connection..."
GITHUB_CONNECTION=$(aws apprunner list-connections --region $REGION --query 'ConnectionSummaryList[?ProviderType==`GITHUB`].ConnectionArn' --output text 2>/dev/null || echo "")

if [ -z "$GITHUB_CONNECTION" ]; then
    echo "❌ No GitHub connection found."
    echo ""
    echo "You need to create a GitHub connection first:"
    echo "1. Go to AWS Console → App Runner → GitHub connections"
    echo "2. Click 'Add connection'"
    echo "3. Name it: we-counsel-github"
    echo "4. Follow OAuth flow to connect your GitHub account"
    echo "5. Copy the Connection ARN"
    echo ""
    echo "Or use this AWS CLI command:"
    echo "  aws apprunner create-connection --connection-name we-counsel-github --provider-type GITHUB --region $REGION"
    echo ""
    read -p "Enter your GitHub Connection ARN (or press Enter to exit): " GITHUB_CONNECTION
    
    if [ -z "$GITHUB_CONNECTION" ]; then
        echo "Exiting. Please create a GitHub connection first."
        exit 1
    fi
else
    echo "✅ Found GitHub connection: $GITHUB_CONNECTION"
fi
echo ""

# Collect required parameters
echo "3. Collecting deployment parameters..."
echo ""

# JWT Secret
read -sp "Enter JWT_SECRET (or press Enter to generate): " JWT_SECRET
echo ""
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
    echo "Generated JWT_SECRET: $JWT_SECRET"
fi

# OpenAI API Key
read -sp "Enter OPENAI_API_KEY: " OPENAI_API_KEY
echo ""

# AWS Credentials (optional - better to use IAM role)
echo ""
echo "For AWS credentials, you can either:"
echo "  A) Provide AWS Access Keys (less secure)"
echo "  B) Skip and use the IAM role created by CloudFormation (recommended)"
echo ""
read -p "Do you want to provide AWS Access Keys? (y/N): " USE_KEYS

if [[ $USE_KEYS =~ ^[Yy]$ ]]; then
    read -p "Enter AWS_ACCESS_KEY_ID: " AWS_KEY_ID
    read -sp "Enter AWS_SECRET_ACCESS_KEY: " AWS_SECRET_KEY
    echo ""
else
    AWS_KEY_ID="NOT_NEEDED_USING_IAM_ROLE"
    AWS_SECRET_KEY="NOT_NEEDED_USING_IAM_ROLE"
    echo "✅ Will use IAM role instead of access keys"
fi

# Email
read -p "Enter EMAIL_FROM (verified SES email): " EMAIL_FROM

# Frontend URL
read -p "Enter FRONTEND_URL (default: http://localhost:8080): " FRONTEND_URL
FRONTEND_URL=${FRONTEND_URL:-http://localhost:8080}

echo ""
echo "4. Creating CloudFormation stack..."

# Create/Update the stack
aws cloudformation deploy \
    --template-file cloudformation-apprunner.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        GitHubConnectionArn="$GITHUB_CONNECTION" \
        GitHubRepo="cvienot/we-counsel-ai" \
        GitHubBranch="main" \
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
    echo "✅ App Runner service deployed successfully!"
    echo ""
    
    # Get service URL
    SERVICE_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
        --output text)
    
    echo "🚀 Your backend is available at: https://$SERVICE_URL"
    echo ""
    echo "Test it with:"
    echo "  curl https://$SERVICE_URL/health"
    echo ""
    echo "Next steps:"
    echo "1. Update your frontend to use this URL"
    echo "2. Update FRONTEND_URL in App Runner environment variables"
    echo "3. Verify SES email address if not already done"
else
    echo ""
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi
