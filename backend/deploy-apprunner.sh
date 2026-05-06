#!/bin/bash

# Deploy App Runner service using CloudFormation
# Prerequisites: 
#   1. Deploy secrets first: ./deploy-secrets.sh
#   2. Create GitHub connection

set -e

REGION="eu-west-3"
STACK_NAME="we-counsel-apprunner"
SECRETS_STACK="we-counsel-secrets"

echo "======================================="
echo "We Connect - App Runner Deployment"
echo "======================================="
echo ""

# Check if AWS CLI is configured
echo "1. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi
echo "✅ AWS CLI is configured"
echo ""

# Check if secrets stack exists
echo "2. Checking for Secrets Manager stack..."
if ! aws cloudformation describe-stacks --stack-name $SECRETS_STACK --region $REGION &> /dev/null; then
    echo "❌ Secrets stack not found!"
    echo ""
    echo "You need to deploy secrets first:"
    echo "  ./deploy-secrets.sh"
    echo ""
    read -p "Do you want to deploy secrets now? (y/N): " DEPLOY_SECRETS
    
    if [[ $DEPLOY_SECRETS =~ ^[Yy]$ ]]; then
        ./deploy-secrets.sh
    else
        echo "Exiting. Please deploy secrets first."
        exit 1
    fi
else
    echo "✅ Secrets stack found"
fi
echo ""

# Check if GitHub connection exists
echo "3. Checking for GitHub connection..."
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

echo "4. Checking existing stack status..."
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "NOT_EXISTS")

if [ "$STACK_STATUS" = "ROLLBACK_COMPLETE" ]; then
    echo "⚠️  Stack is in ROLLBACK_COMPLETE state (previous deployment failed)"
    echo "   Deleting the failed stack..."
    
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION
    
    echo "   Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    echo "✅ Failed stack deleted successfully"
    echo ""
fi

echo "5. Deploying App Runner service..."
echo ""

# Create/Update the stack
aws cloudformation deploy \
    --template-file cloudformation-apprunner.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        GitHubConnectionArn="$GITHUB_CONNECTION" \
        GitHubRepo="cvienot/we-counsel-ai" \
        GitHubBranch="main" \
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
