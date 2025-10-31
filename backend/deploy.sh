#!/bin/bash

# Deploy We Counsel Backend to AWS App Runner

echo "🚀 Deploying We Counsel Backend to AWS App Runner..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   brew install awscli"
    exit 1
fi

# Check if logged in to AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Not logged in to AWS. Please run: aws configure"
    exit 1
fi

echo ""
echo "⚠️  Before deploying, make sure you have:"
echo "   1. Pushed your code to GitHub"
echo "   2. Set up your .env variables in AWS App Runner console"
echo "   3. Created DynamoDB tables in production"
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Service name
SERVICE_NAME="we-counsel-api"
REGION="${AWS_REGION:-us-east-1}"

echo ""
echo "📦 Deployment Steps:"
echo "   1. Go to: https://console.aws.amazon.com/apprunner"
echo "   2. Click 'Create service'"
echo "   3. Connect to your GitHub repository"
echo "   4. Use configuration file: apprunner.yaml"
echo "   5. Add environment variables"
echo ""
echo "🔐 Required Environment Variables:"
echo "   - JWT_SECRET"
echo "   - OPENAI_API_KEY"
echo "   - AWS_REGION"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - EMAIL_FROM (verified in SES)"
echo "   - FRONTEND_URL"
echo ""
echo "📚 After deployment, run database setup:"
echo "   You'll need to SSH or use a one-time script to run: npm run setup:db"
echo ""
echo "✅ Your App Runner service will be available at:"
echo "   https://your-service.awsapprunner.com"
