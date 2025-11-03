# Complete AWS Deployment Guide

## Overview

This guide walks you through deploying We Counsel AI to AWS using CloudFormation (Infrastructure as Code).

**Deployment Order:**
1. DynamoDB tables (database)
2. Secrets Manager (secure credentials)
3. App Runner (backend service)

All infrastructure is defined in code and can be version controlled!

## Prerequisites

- ✅ AWS CLI installed and configured
- ✅ AWS account with appropriate permissions
- ✅ GitHub repository with your code

```bash
# Verify AWS CLI
aws --version
aws sts get-caller-identity
```

## Step 1: Deploy DynamoDB Tables

Create all database tables with one command:

```bash
cd backend

aws cloudformation create-stack \
  --stack-name we-counsel-dynamodb \
  --template-body file://cloudformation-dynamodb.yaml \
  --region eu-west-3

# Wait for completion (~2-3 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3
```

**What gets created:**
- 5 DynamoDB tables (Users, Conversations, Messages, Couples, Invitations)
- Global Secondary Indexes for efficient queries
- Pay-per-request billing mode

**Verify:**
```bash
aws dynamodb list-tables --region eu-west-3
```

## Step 2: Deploy Secrets to Secrets Manager

Store all sensitive credentials securely:

```bash
./deploy-secrets.sh
```

The script will prompt you for:
- JWT_SECRET (or auto-generate)
- OPENAI_API_KEY
- AWS credentials (optional - recommended to use IAM role)
- EMAIL_FROM (SES verified email)
- FRONTEND_URL

**What gets created:**
- Secrets encrypted with KMS
- IAM policy for reading secrets
- Multiple secret stores for different purposes

**Cost:** ~$2-3/month

## Step 3: Deploy App Runner Service

Deploy your backend service:

```bash
./deploy-apprunner.sh
```

The script will:
1. Check that secrets are deployed
2. Find or prompt for GitHub connection ARN
3. Deploy App Runner service with CloudFormation

**What gets created:**
- App Runner service (auto-scaling web service)
- IAM roles with DynamoDB, SES, and Secrets Manager access
- Auto-deployment from GitHub
- Health checks and monitoring

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Account (eu-west-3)                │
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │   GitHub     │─────▶│  App Runner  │                     │
│  │ (your repo)  │      │   Service    │                     │
│  └──────────────┘      │              │                     │
│                        │  • Node.js   │                     │
│                        │  • Port 3000 │                     │
│                        │  • Auto-scale│                     │
│                        └──────┬───────┘                     │
│                               │                              │
│                   ┌───────────┼───────────┐                 │
│                   │           │           │                 │
│            ┌──────▼─────┐ ┌──▼────────┐ ┌▼──────────────┐  │
│            │  DynamoDB  │ │  Secrets  │ │     SES       │  │
│            │   Tables   │ │  Manager  │ │   (Email)     │  │
│            │            │ │           │ │               │  │
│            │ • Users    │ │ • JWT     │ │ • Send emails │  │
│            │ • Messages │ │ • OpenAI  │ │ • Invites     │  │
│            │ • Convos   │ │ • Config  │ │               │  │
│            └────────────┘ └───────────┘ └───────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## GitHub Connection Setup

App Runner needs permission to access your GitHub repository. This is a **one-time manual step**:

### Option 1: AWS Console (Easiest)
1. Go to [App Runner Console](https://console.aws.amazon.com/apprunner)
2. Click "GitHub connections" → "Add connection"
3. Name: `we-counsel-github`
4. Authorize with GitHub
5. Copy the Connection ARN

### Option 2: AWS CLI
```bash
aws apprunner create-connection \
  --connection-name we-counsel-github \
  --provider-type GITHUB \
  --region eu-west-3
```

Then complete OAuth in AWS Console.

## Deployment Scripts Overview

### `cloudformation-dynamodb.yaml`
- **Purpose:** Creates DynamoDB tables
- **Cost:** Pay-per-request (cheap for low traffic)
- **One-time deployment:** Yes

### `cloudformation-secrets.yaml`
- **Purpose:** Stores secrets in Secrets Manager
- **Cost:** ~$2-3/month
- **Updates:** Anytime via `deploy-secrets.sh`

### `cloudformation-apprunner.yaml`
- **Purpose:** Deploys backend service
- **Cost:** ~$20-50/month (scales with usage)
- **Updates:** Auto-deploys on git push

## Complete Deployment (All-in-One)

```bash
cd backend

# 1. Deploy DynamoDB
aws cloudformation create-stack \
  --stack-name we-counsel-dynamodb \
  --template-body file://cloudformation-dynamodb.yaml \
  --region eu-west-3

aws cloudformation wait stack-create-complete \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3

# 2. Deploy Secrets
./deploy-secrets.sh

# 3. Deploy App Runner
./deploy-apprunner.sh

# Done! Your backend is live.
```

## Post-Deployment

### Get Your Service URL

```bash
aws cloudformation describe-stacks \
  --stack-name we-counsel-apprunner \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
  --output text
```

### Test Your Backend

```bash
SERVICE_URL=$(aws cloudformation describe-stacks \
  --stack-name we-counsel-apprunner \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
  --output text)

curl https://$SERVICE_URL/health
# Expected: {"status":"ok","timestamp":"..."}
```

### Update Frontend

Update your Flutter app to use the production URL:

```dart
// lib/services/api_service.dart
static const String baseUrl = 'https://your-app-runner-url.eu-west-3.awsapprunner.com';
```

### Update CORS

Update the `FRONTEND_URL` secret to your production frontend URL:

```bash
aws secretsmanager update-secret \
  --secret-id we-counsel/application/secrets \
  --secret-string '{
    "JWT_SECRET": "...",
    "OPENAI_API_KEY": "...",
    "FRONTEND_URL": "https://your-frontend-url.com",
    ...
  }' \
  --region eu-west-3
```

## Updating Your Application

### Code Changes (Auto-Deploy)

Just push to GitHub:
```bash
git add .
git commit -m "Update feature"
git push
```

App Runner automatically detects the push and redeploys!

### Update Secrets

```bash
# Update specific secret
aws secretsmanager update-secret \
  --secret-id we-counsel/openai-api-key \
  --secret-string '{"OPENAI_API_KEY":"sk-new-key"}' \
  --region eu-west-3

# Restart App Runner to pick up new secrets
aws apprunner start-deployment \
  --service-arn $(aws cloudformation describe-stacks \
      --stack-name we-counsel-apprunner \
      --region eu-west-3 \
      --query 'Stacks[0].Outputs[?OutputKey==`ServiceArn`].OutputValue' \
      --output text) \
  --region eu-west-3
```

### Update Infrastructure

```bash
# Modify cloudformation-*.yaml files
# Then redeploy:
aws cloudformation deploy \
  --template-file cloudformation-apprunner.yaml \
  --stack-name we-counsel-apprunner \
  --parameter-overrides GitHubConnectionArn="..." \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-west-3
```

## Monitoring

### View Logs

```bash
# App Runner logs
aws logs tail /aws/apprunner/we-counsel-backend/service --follow --region eu-west-3
```

### Check Status

```bash
aws apprunner describe-service \
  --service-arn $(aws cloudformation describe-stacks \
      --stack-name we-counsel-apprunner \
      --region eu-west-3 \
      --query 'Stacks[0].Outputs[?OutputKey==`ServiceArn`].OutputValue' \
      --output text) \
  --region eu-west-3 \
  --query 'Service.Status'
```

## Troubleshooting

### "Stack already exists"
```bash
# Update instead of create
aws cloudformation update-stack ...
# Or use deploy (handles both create and update)
aws cloudformation deploy ...
```

### "Access Denied" errors
Check IAM permissions:
- CloudFormation
- App Runner
- Secrets Manager
- DynamoDB
- SES

### App fails to start
1. Check CloudWatch logs
2. Verify all secrets exist
3. Check DynamoDB tables exist
4. Verify IAM role permissions

### GitHub connection issues
1. Check connection status in App Runner console
2. Reauthorize GitHub OAuth
3. Verify repository access

## Cost Breakdown

| Service | Cost | Notes |
|---------|------|-------|
| **DynamoDB** | ~$5-10/month | Pay-per-request |
| **Secrets Manager** | ~$2-3/month | $0.40/secret |
| **App Runner** | ~$20-50/month | 1 vCPU, 2GB RAM |
| **SES** | Free | First 62k emails/month |
| **KMS** | $1/month | Encryption key |
| **CloudWatch** | $1-2/month | Logs |
| **Total** | **~$30-70/month** | Scales with usage |

## Clean Up (Delete Everything)

⚠️ **Warning:** This deletes ALL data!

```bash
# Delete App Runner
aws cloudformation delete-stack \
  --stack-name we-counsel-apprunner \
  --region eu-west-3

# Delete Secrets
aws cloudformation delete-stack \
  --stack-name we-counsel-secrets \
  --region eu-west-3

# Delete DynamoDB (ALL DATA LOST!)
aws cloudformation delete-stack \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3
```

## Best Practices

1. ✅ **Use Secrets Manager** for all sensitive data
2. ✅ **Use IAM roles** instead of access keys
3. ✅ **Enable CloudTrail** for audit logging
4. ✅ **Set up CloudWatch alarms** for errors
5. ✅ **Regular backups** (DynamoDB on-demand backups)
6. ✅ **Use separate stacks** for different environments
7. ✅ **Version control** all CloudFormation templates

## Multi-Environment Setup

To deploy staging and production:

```bash
# Staging
aws cloudformation deploy \
  --stack-name we-counsel-staging-dynamodb \
  --template-file cloudformation-dynamodb.yaml \
  --region eu-west-3

# Production
aws cloudformation deploy \
  --stack-name we-counsel-production-dynamodb \
  --template-file cloudformation-dynamodb.yaml \
  --region eu-west-3
```

Update table names in code based on environment.

## Next Steps

1. ✅ Backend deployed
2. Deploy frontend (AWS Amplify or S3 + CloudFront)
3. Set up custom domain
4. Configure SSL certificate
5. Set up monitoring and alerts
6. Implement backups
7. Add CI/CD pipeline

## Support

- AWS Documentation: https://docs.aws.amazon.com/
- CloudFormation: https://docs.aws.amazon.com/cloudformation/
- App Runner: https://docs.aws.amazon.com/apprunner/
- Secrets Manager: https://docs.aws.amazon.com/secretsmanager/
