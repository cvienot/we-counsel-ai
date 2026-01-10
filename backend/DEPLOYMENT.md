# AWS Deployment Guide for We Coach

## Prerequisites
- AWS CLI installed and configured
- AWS account with appropriate permissions
- GitHub repository connected to App Runner

## Step 1: Create DynamoDB Tables

### Option A: Using CloudFormation (Recommended)

```bash
# Deploy the CloudFormation stack
aws cloudformation create-stack \
  --stack-name we-counsel-dynamodb \
  --template-body file://cloudformation-dynamodb.yaml \
  --region eu-west-3

# Check deployment status
aws cloudformation describe-stacks \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3 \
  --query 'Stacks[0].StackStatus'

# Wait for completion (should show CREATE_COMPLETE)
aws cloudformation wait stack-create-complete \
  --stack-name we-counsel-dynamodb \
  --region eu-west-3
```

### Option B: Manual Creation via AWS Console

1. Go to DynamoDB Console → Tables → Create table
2. Create these 5 tables with the following configurations:

**Table 1: we-counsel-users**
- Partition key: `userId` (String)
- GSI: `email-index` with partition key `email` (String)

**Table 2: we-counsel-conversations**
- Partition key: `conversationId` (String)
- GSI: `coupleId-index` with partition key `coupleId` (String)

**Table 3: we-counsel-messages**
- Partition key: `messageId` (String)
- GSI 1: `conversationId-timestamp-index` with partition key `conversationId` (String) and sort key `timestamp` (Number)
- GSI 2: `userId-index` with partition key `userId` (String)

**Table 4: we-counsel-couples**
- Partition key: `coupleId` (String)

**Table 5: we-counsel-invitations**
- Partition key: `invitationId` (String)
- GSI: `email-index` with partition key `email` (String)

## Step 2: Configure Environment Variables in App Runner

Go to your App Runner service → Configuration → Environment variables

Add these variables:

```bash
# Required - Generate a strong secret
JWT_SECRET=<generate-with: openssl rand -base64 32>

# Required - Your OpenAI API key
OPENAI_API_KEY=sk-...

# Required - AWS credentials (or use IAM role - see below)
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
AWS_REGION=eu-west-3

# Required - DynamoDB region
DYNAMODB_REGION=eu-west-3

# Required - Email configuration
EMAIL_FROM=noreply@yourdomain.com

# Required - Frontend URL (update after frontend deployment)
FRONTEND_URL=https://your-frontend-url.com

# Already set in apprunner.yaml
NODE_ENV=production
```

### Better Option: Use IAM Role (Recommended for AWS credentials)

Instead of using AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY:

1. Create an IAM role with these policies:
   - `AmazonDynamoDBFullAccess` (or a custom policy with only required permissions)
   - `AmazonSESFullAccess` (or custom policy for sending emails)

2. Attach the role to your App Runner service:
   - Go to App Runner → Your service → Configuration
   - Security → Instance role → Select your IAM role

3. Remove AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from environment variables

## Step 3: Set Up Amazon SES for Email

1. Go to Amazon SES Console
2. Verify your email address or domain:
   - Verified identities → Create identity
   - Choose Email address or Domain
   - Follow verification steps

3. If in SES Sandbox mode:
   - Also verify recipient email addresses, OR
   - Request production access (recommended)

4. Update EMAIL_FROM environment variable with your verified email

## Step 4: Deploy to App Runner

Your App Runner service should automatically redeploy when you push to GitHub.

To manually trigger a deployment:
1. Go to AWS App Runner Console
2. Select your service
3. Click "Deploy" button

Monitor the logs:
- Watch deployment logs for any errors
- Once deployed, check service logs for application startup

## Step 5: Test the Deployment

1. Get your App Runner service URL from the AWS Console
2. Test the health endpoint:
   ```bash
   curl https://your-app-runner-url.eu-west-3.awsapprunner.com/health
   ```

3. Expected response:
   ```json
   {"status":"ok","timestamp":"..."}
   ```

## Step 6: Update Frontend Configuration

Once backend is deployed:

1. Update frontend API endpoint to point to your App Runner URL
2. Update FRONTEND_URL in App Runner environment variables
3. Redeploy backend for CORS to work correctly

## Troubleshooting

### Deployment fails with "Failed to deploy your application source code"

**Check App Runner logs for specific error**

Common issues:
1. **Missing environment variables** - Ensure all required env vars are set
2. **DynamoDB tables don't exist** - Create tables first (Step 1)
3. **Invalid AWS credentials** - Check credentials or IAM role permissions
4. **SES not configured** - Verify email addresses in SES

### Application starts but crashes

Check service logs in App Runner:
- Look for connection errors to DynamoDB
- Check for missing environment variables
- Verify AWS region matches where tables are created

### Can't send emails

- Verify email address in SES
- Check SES sandbox mode restrictions
- Verify EMAIL_FROM matches verified identity

## Cost Optimization

- **DynamoDB**: Using PAY_PER_REQUEST mode (cheaper for low traffic)
- **App Runner**: Scales to zero when not in use (or configure min instances)
- **SES**: First 62,000 emails/month free (when sending from EC2/App Runner)

## Security Checklist

- ✅ Use IAM roles instead of hardcoded credentials
- ✅ JWT_SECRET is strong and random
- ✅ Environment variables are encrypted at rest (App Runner does this automatically)
- ✅ CORS is configured for specific frontend URL only
- ✅ SES email address is verified
- ✅ DynamoDB tables have appropriate permissions

## Next Steps

1. Set up monitoring with CloudWatch
2. Configure custom domain for App Runner
3. Set up automated backups for DynamoDB
4. Implement CloudWatch alarms for errors
5. Deploy frontend to AWS Amplify or S3 + CloudFront
