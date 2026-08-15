#!/bin/bash

# Deploy Flutter Web App to AWS Amplify
# This script creates the Amplify app and sets up continuous deployment from GitHub

set -e

REGION="eu-west-3"
STACK_NAME="we-counsel-frontend"
APP_NAME="we-counsel-web"
REPOSITORY="cvienot/we-counsel-ai"
BRANCH="main"

echo "========================================="
echo "Entrelace - Frontend Deployment"
echo "AWS Amplify Hosting Setup"
echo "========================================="
echo ""

# Check if AWS CLI is configured
echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi
echo "✅ AWS CLI is configured"
echo ""

# Check if backend is deployed
echo "2. Checking for backend App Runner URL..."
BACKEND_STACK="we-counsel-apprunner"
if aws cloudformation describe-stacks --stack-name $BACKEND_STACK --region $REGION &> /dev/null 2>&1; then
    BACKEND_URL=$(aws cloudformation describe-stacks \
        --stack-name $BACKEND_STACK \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$BACKEND_URL" ]; then
        # Ensure URL has https:// protocol
        if [[ ! "$BACKEND_URL" =~ ^https?:// ]]; then
            BACKEND_URL="https://${BACKEND_URL}"
        fi
        echo "✅ Found backend URL: $BACKEND_URL"
        API_BASE_URL="${BACKEND_URL}/api"
    else
        echo "⚠️  Backend deployed but URL not found. You'll need to set it manually."
        API_BASE_URL="https://your-app-runner-url.awsapprunner.com/api"
    fi
else
    echo "⚠️  Backend not deployed yet. Using placeholder URL."
    API_BASE_URL="https://your-app-runner-url.awsapprunner.com/api"
fi
echo ""

# Check for GitHub connection (can reuse from App Runner)
echo "3. Checking for GitHub connection..."

# First check if backend has a GitHub connection we can reuse
BACKEND_STACK="we-counsel-apprunner"
GITHUB_CONNECTION=""

if aws cloudformation describe-stacks --stack-name $BACKEND_STACK --region $REGION &> /dev/null 2>&1; then
    GITHUB_CONNECTION=$(aws cloudformation describe-stacks \
        --stack-name $BACKEND_STACK \
        --region $REGION \
        --query 'Stacks[0].Parameters[?ParameterKey==`GitHubConnectionArn`].ParameterValue' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$GITHUB_CONNECTION" ]; then
        echo "✅ Found GitHub connection from backend App Runner"
        echo "   Connection ARN: $GITHUB_CONNECTION"
        echo ""
        echo "ℹ️  Amplify uses GitHub Personal Access Token (different from App Runner's connection)"
        echo "   But you can use the same GitHub account."
    fi
fi

# Check if Amplify already has apps (which means token was provided before)
EXISTING_APPS=$(aws amplify list-apps --region $REGION --query 'apps[0].name' --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_APPS" ]; then
    echo "✅ Found existing Amplify apps - GitHub token already configured"
    read -p "Enter your GitHub Personal Access Token (or press Enter to reuse existing): " GITHUB_TOKEN
else
    echo "❌ No Amplify apps found. You need to set up GitHub App authentication."
    echo ""
    echo "⚠️  IMPORTANT: AWS Amplify now uses GitHub App instead of Personal Access Tokens"
    echo ""
    echo "📝 To set up GitHub App authentication:"
    echo "1. Go to AWS Amplify Console: https://console.aws.amazon.com/amplify"
    echo "2. Click 'Create new app' or 'Host web app'"
    echo "3. Choose 'GitHub' as source"
    echo "4. Click 'Authorize AWS Amplify'"
    echo "5. Install the AWS Amplify GitHub App"
    echo "6. Select your repository: cvienot/we-counsel-ai"
    echo "7. Choose branch: main"
    echo ""
    echo "After GitHub App is installed, you can use this script or the console."
    echo ""
    read -p "Have you installed the AWS Amplify GitHub App? (y/N): " GITHUB_APP_INSTALLED
    
    if [[ ! $GITHUB_APP_INSTALLED =~ ^[Yy]$ ]]; then
        echo ""
        echo "Please install the AWS Amplify GitHub App first, then run this script again."
        echo ""
        echo "Quick link: https://console.aws.amazon.com/amplify/home?region=$REGION#/create"
        exit 1
    fi
    
    echo ""
    echo "⚠️  Note: CloudFormation deployment with GitHub App requires the app to be pre-installed."
    echo "   We recommend completing the setup via AWS Console for the first deployment."
    echo ""
    read -p "Continue with CloudFormation deployment? (y/N): " CONTINUE_CF
    
    if [[ ! $CONTINUE_CF =~ ^[Yy]$ ]]; then
        echo "Please complete the setup via AWS Console:"
        echo "https://console.aws.amazon.com/amplify/home?region=$REGION#/create"
        exit 0
    fi
    
    # If continuing, we'll skip the GitHub token (GitHub App is used instead)
    GITHUB_TOKEN=""
fi
echo ""

echo "4. Deployment Configuration:"
echo "   App Name: $APP_NAME"
echo "   Repository: $REPOSITORY"
echo "   Branch: $BRANCH"
echo "   Region: $REGION"
echo "   API URL: $API_BASE_URL"
echo ""
read -p "Continue with deployment? (y/N): " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi
echo ""

# Deploy CloudFormation stack
echo "5. Deploying CloudFormation stack..."

if [ -n "$GITHUB_TOKEN" ]; then
    aws cloudformation deploy \
        --template-file cloudformation-amplify.yaml \
        --stack-name $STACK_NAME \
        --region $REGION \
        --parameter-overrides \
            AppName=$APP_NAME \
            Repository=$REPOSITORY \
            Branch=$BRANCH \
            GitHubToken=$GITHUB_TOKEN \
            ApiBaseUrl=$API_BASE_URL \
        --capabilities CAPABILITY_IAM \
        --no-fail-on-empty-changeset
else
    echo "⚠️  Skipping CloudFormation deployment without GitHub token."
    echo "   You'll need to create the Amplify app manually in the AWS Console."
fi

echo ""
echo "========================================="
echo "✅ Frontend Deployment Complete!"
echo "========================================="
echo ""

# Get the app URL
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null 2>&1; then
    APP_ID=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`AppId`].OutputValue' \
        --output text)
    
    DEFAULT_DOMAIN=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`DefaultDomain`].OutputValue' \
        --output text)
    
    echo "📱 App Details:"
    echo "   App ID: $APP_ID"
    echo "   URL: https://$BRANCH.$DEFAULT_DOMAIN"
    echo ""
    echo "🔗 Amplify Console:"
    echo "   https://eu-west-3.console.aws.amazon.com/amplify/home?region=eu-west-3#/$APP_ID"
fi

echo ""
echo "📝 Next Steps:"
echo "   1. Amplify will automatically build and deploy on every git push"
echo "   2. Update your backend's FRONTEND_URL environment variable to the Amplify URL"
echo "   3. Set up custom domain (optional): AWS Console → Amplify → Domain management"
echo ""
echo "🔧 Manual Deployment:"
echo "   Run: ./deploy-frontend-manual.sh"
echo ""
