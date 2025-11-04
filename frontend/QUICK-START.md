# Quick Start: Deploy Frontend to AWS Amplify

## ⚠️ Important Change: GitHub App Required

AWS Amplify now uses **GitHub App** instead of tokens. First deployment must be via AWS Console.

## Step 1: Install GitHub App (One-Time)

1. **Go to**: https://console.aws.amazon.com/amplify/home?region=eu-west-3
2. **Click**: "Create new app" → "GitHub"
3. **Install**: AWS Amplify GitHub App
4. **Select**: `cvienot/we-counsel-ai` repository
5. **Configure**:
   - Branch: `main`
   - App name: `we-counsel-web`
   - Build file: `amplify.yml` (auto-detected)
   - Environment variables:
     ```
     API_BASE_URL=https://YOUR-BACKEND.awsapprunner.com/api
     ENVIRONMENT=production
     ```
6. **Deploy**: Wait 5-10 minutes for first build

## Step 2: Get Your Backend URL

```bash
aws cloudformation describe-stacks \
  --stack-name we-counsel-apprunner \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
  --output text
```

Use this URL in the `API_BASE_URL` environment variable.

## Step 3: Update Backend CORS

```bash
cd backend
# Edit apprunner.yaml - add your Amplify URL to FRONTEND_URL
git add apprunner.yaml
git commit -m "Add Amplify URL to CORS"
git push
```

## Step 4: Test

Visit your app: `https://main.xxxx.amplifyapp.com`

## That's It!

✅ **Every git push** now automatically deploys  
✅ **No more manual steps** needed  
✅ **Monitor builds** in Amplify Console  

## Detailed Guide

See [AMPLIFY-MANUAL-SETUP.md](AMPLIFY-MANUAL-SETUP.md) for complete instructions.
