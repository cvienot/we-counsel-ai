# App Runner Deployment with CloudFormation

## Why Use CloudFormation for App Runner?

**Benefits:**
- 🔄 **Reproducible**: Deploy to multiple environments (staging, production)
- 📝 **Version Control**: Infrastructure changes tracked in Git
- 🔒 **Security**: IAM roles instead of hardcoded credentials
- 🎯 **All-in-one**: Service + IAM roles + auto-scaling in one file
- ⚡ **Fast updates**: Change configuration and redeploy instantly

## Prerequisites

### 1. Create GitHub Connection (One-time setup)

App Runner needs permission to access your GitHub repository. You must create this connection manually:

**Option A: Using AWS Console** (Easiest)
1. Go to [App Runner Console](https://console.aws.amazon.com/apprunner)
2. Click on "GitHub connections" in left sidebar
3. Click "Add connection"
4. Name it: `we-counsel-github`
5. Click "Connect to GitHub" and authorize AWS
6. Copy the Connection ARN (looks like: `arn:aws:apprunner:eu-west-3:123456789:connection/we-counsel-github/abc123`)

**Option B: Using AWS CLI**
```bash
aws apprunner create-connection \
  --connection-name we-counsel-github \
  --provider-type GITHUB \
  --region eu-west-3
```

Then complete the OAuth flow in the AWS Console.

### 2. Verify SES Email (If not already done)

```bash
aws ses verify-email-identity \
  --email-address noreply@yourdomain.com \
  --region eu-west-3
```

Check your email and click the verification link.

## Deployment Methods

### Method 1: Interactive Script (Recommended)

```bash
cd backend
./deploy-apprunner.sh
```

The script will:
- ✅ Check AWS CLI configuration
- ✅ Find or prompt for GitHub connection
- ✅ Ask for required secrets (JWT, OpenAI key, etc.)
- ✅ Deploy using CloudFormation
- ✅ Show you the service URL

### Method 2: Manual CloudFormation Deployment

```bash
# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Deploy the stack
aws cloudformation deploy \
  --template-file cloudformation-apprunner.yaml \
  --stack-name we-counsel-apprunner \
  --parameter-overrides \
      GitHubConnectionArn="arn:aws:apprunner:eu-west-3:ACCOUNT:connection/NAME/ID" \
      JWTSecret="$JWT_SECRET" \
      OpenAIAPIKey="sk-your-key-here" \
      AWSAccessKeyId="YOUR_KEY" \
      AWSSecretAccessKey="YOUR_SECRET" \
      EmailFrom="noreply@yourdomain.com" \
      FrontendURL="http://localhost:8080" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-west-3
```

### Method 3: Using AWS Console (If you prefer)

1. Go to CloudFormation → Create stack
2. Upload `cloudformation-apprunner.yaml`
3. Fill in the parameters
4. Create stack

## What Gets Created

The CloudFormation template creates:

1. **IAM Roles**:
   - `WeCounselAppRunnerInstanceRole` - Grants App Runner access to DynamoDB and SES
   - `WeCounselAppRunnerAccessRole` - Grants App Runner access to GitHub

2. **App Runner Service**:
   - Name: `we-counsel-backend`
   - Auto-deploy from GitHub on push
   - Uses `apprunner.yaml` from repository
   - Health check on `/health` endpoint

3. **Auto Scaling**:
   - Min instances: 1
   - Max instances: 25
   - Max concurrent requests: 100

## Update the Service

To update environment variables or configuration:

```bash
# Edit cloudformation-apprunner.yaml or parameters
# Then redeploy:
./deploy-apprunner.sh
```

Or update directly in AWS Console:
- App Runner → Your service → Configuration → Edit

## Monitor Deployment

```bash
# Watch stack events
aws cloudformation describe-stack-events \
  --stack-name we-counsel-apprunner \
  --region eu-west-3 \
  --max-items 10

# Check service status
aws apprunner describe-service \
  --service-arn $(aws cloudformation describe-stacks \
      --stack-name we-counsel-apprunner \
      --region eu-west-3 \
      --query 'Stacks[0].Outputs[?OutputKey==`ServiceArn`].OutputValue' \
      --output text) \
  --region eu-west-3 \
  --query 'Service.Status'
```

## Get Service URL

```bash
aws cloudformation describe-stacks \
  --stack-name we-counsel-apprunner \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
  --output text
```

## Troubleshooting

### "GitHub connection not found"
- Create the GitHub connection first (see Prerequisites)
- Make sure you're in the correct region (eu-west-3)

### "Service failed to start"
- Check CloudWatch logs: App Runner → Service → Logs
- Verify environment variables are set correctly
- Ensure DynamoDB tables exist (run `cloudformation-dynamodb.yaml` first)

### "Authentication failed"
- Verify JWT_SECRET is set
- Check AWS credentials or IAM role permissions

### "Email not sending"
- Verify email in SES: `aws ses list-verified-email-addresses --region eu-west-3`
- Check SES sandbox mode restrictions

## Clean Up

To delete everything:

```bash
# Delete App Runner stack
aws cloudformation delete-stack \
  --stack-name we-counsel-apprunner \
  --region eu-west-3

# Delete DynamoDB stack (CAUTION: deletes all data!)
aws cloudformation delete-stack \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3
```

## Cost Optimization

- App Runner charges: ~$0.007/hour + $0.064/GB compute time
- Auto-scales to 1 instance when idle
- DynamoDB on-demand pricing: Pay only for what you use
- First 62,000 SES emails/month are free

## Next Steps

1. ✅ Deploy App Runner service
2. Get the service URL
3. Update frontend to use production URL
4. Update `FRONTEND_URL` in App Runner environment
5. Test end-to-end functionality
6. Deploy frontend to AWS Amplify or S3
