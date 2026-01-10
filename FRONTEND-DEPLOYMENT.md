# Frontend Deployment Guide

## Overview
This guide covers deploying the We Coach Flutter web app to AWS Amplify Hosting with support for future iOS and Android app deployments.

## Prerequisites

1. **AWS Account** with CLI configured
2. **GitHub Personal Access Token** (for Amplify)
3. **Backend deployed** to App Runner (optional, but recommended)
4. **Flutter installed** and configured

## Quick Start

### ⚠️ IMPORTANT: GitHub App Setup Required

AWS Amplify now uses **GitHub App** instead of Personal Access Tokens. For the **first deployment**, you must use the AWS Console to install the GitHub App.

**See**: [AMPLIFY-MANUAL-SETUP.md](AMPLIFY-MANUAL-SETUP.md) for step-by-step instructions.

### Option 1: AWS Console Setup (Required for First Deployment)

Follow the manual setup guide: [AMPLIFY-MANUAL-SETUP.md](AMPLIFY-MANUAL-SETUP.md)

This is a **one-time setup**:
- ✅ Install AWS Amplify GitHub App
- ✅ Select your repository
- ✅ Configure build settings
- ✅ Set environment variables
- ✅ Deploy and get your URL

After initial setup, **every git push automatically deploys**! 🎉

### Option 2: Automated Script (After GitHub App Installed)

```bash
cd frontend
./deploy-amplify.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Fetch your backend API URL automatically
- ✅ Verify GitHub App is installed
- ✅ Guide you through any remaining setup

### Option 2: Manual Build & Deploy

```bash
cd frontend
./deploy-frontend-manual.sh
```

This builds the web app locally. Useful for:
- Testing production builds locally
- Debugging build issues
- Manual deployment workflows

## Step-by-Step Deployment

### 1. Create GitHub Personal Access Token

> **📝 Note**: Amplify uses a different auth method than App Runner. See [GITHUB-AUTH-GUIDE.md](GITHUB-AUTH-GUIDE.md) for details.

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Name: `AWS Amplify - We Coach`
4. Scopes: Select `repo` (full control of private repositories)
5. Click **"Generate token"**
6. **Copy the token** (you won't see it again!)

> **💡 Tip**: You can reuse the same GitHub account as your backend, just different auth methods.

### 2. Deploy Backend First (if not done)

The frontend needs your backend API URL:

```bash
cd ../backend
./deploy-apprunner.sh
```

Note the App Runner URL from the output.

### 3. Deploy Frontend to Amplify

```bash
cd ../frontend
./deploy-amplify.sh
```

When prompted:
- Enter your **GitHub Personal Access Token**
- Confirm deployment settings
- Wait for CloudFormation to complete (~5 minutes)

### 4. Verify Deployment

After deployment, Amplify will:
1. Connect to your GitHub repository
2. Build the Flutter web app
3. Deploy to a unique URL: `https://main.xxxxxx.amplifyapp.com`

Check the build status:
```bash
# Get your app ID from the output, then:
aws amplify list-jobs --app-id <YOUR_APP_ID> --branch-name main --region eu-west-3
```

Or visit the Amplify Console:
```
https://eu-west-3.console.aws.amazon.com/amplify/home
```

## Configuration

### Environment Variables

The app uses different API URLs for different environments:

**Development** (`.env.development`):
```
API_BASE_URL=http://localhost:3000/api
ENVIRONMENT=development
```

**Production** (`.env.production`):
```
API_BASE_URL=https://your-app-runner-url.awsapprunner.com/api
ENVIRONMENT=production
```

### Update Backend URL

If you deploy backend after frontend, update the API URL:

1. Go to AWS Amplify Console
2. Select your app → Environment variables
3. Update `API_BASE_URL` with your App Runner URL
4. Trigger a new build

Or use CLI:
```bash
aws amplify update-branch \
  --app-id <YOUR_APP_ID> \
  --branch-name main \
  --environment-variables API_BASE_URL=https://your-url.awsapprunner.com/api \
  --region eu-west-3
```

## Continuous Deployment

Amplify automatically rebuilds and deploys when you:
- Push to the `main` branch
- Merge a pull request

To trigger a manual build:
```bash
aws amplify start-job \
  --app-id <YOUR_APP_ID> \
  --branch-name main \
  --job-type RELEASE \
  --region eu-west-3
```

## Custom Domain (Optional)

### Add Custom Domain in AWS Console

1. Go to: Amplify Console → Domain management
2. Click "Add domain"
3. Enter your domain (e.g., `wecounsel.app`)
4. Follow DNS configuration steps
5. Wait for SSL certificate provisioning (~15 minutes)

### Update DNS Records

Add these records to your domain DNS:

```
Type: CNAME
Name: www
Value: <your-amplify-domain>

Type: A (or ALIAS)
Name: @
Value: <amplify-provided-value>
```

## Mobile App Preparation

Your Flutter app is already configured for multi-platform:

### iOS Deployment (Future)

```bash
cd frontend
flutter build ios --release
# Use Xcode to upload to App Store Connect
```

### Android Deployment (Future)

```bash
cd frontend
flutter build appbundle --release
# Upload to Google Play Console
```

## Troubleshooting

### Build Fails on Amplify

**Check build logs:**
1. Go to Amplify Console
2. Click on your app
3. View the build details
4. Check for Flutter/Dart errors

**Common issues:**
- Missing dependencies: Run `flutter pub get`
- Flutter version mismatch: Update `amplify.yml` Flutter version
- API URL issues: Verify environment variables

### CORS Errors

If you see CORS errors in browser console:

1. Update backend CORS configuration in `backend/src/server.js`
2. Add your Amplify URL to allowed origins:

```javascript
const corsOptions = {
  origin: [
    'http://localhost:8080',
    'https://main.xxxxxx.amplifyapp.com'  // Add your Amplify URL
  ],
  credentials: true
};
```

3. Redeploy backend

### API Not Connecting

**Verify API URL:**
```bash
# Check environment variable in Amplify
aws amplify get-branch \
  --app-id <YOUR_APP_ID> \
  --branch-name main \
  --region eu-west-3
```

**Test API directly:**
```bash
curl https://your-app-runner-url.awsapprunner.com/health
```

## Cost Estimate

AWS Amplify Hosting pricing:
- **Build minutes**: $0.01/minute (~5 min/build = $0.05)
- **Hosting**: $0.15/GB served
- **Storage**: $0.023/GB stored

**Estimated monthly cost**: $5-10 for typical usage

## Files Reference

- `amplify.yml` - Amplify build configuration
- `cloudformation-amplify.yaml` - Infrastructure as Code template
- `deploy-amplify.sh` - Automated deployment script
- `deploy-frontend-manual.sh` - Manual build script
- `lib/config/environment.dart` - Environment configuration
- `.env.production` - Production environment variables
- `.env.development` - Development environment variables

## Next Steps

1. ✅ Deploy backend (if not done)
2. ✅ Deploy frontend to Amplify
3. ✅ Update backend FRONTEND_URL to Amplify URL
4. ✅ Test the deployed app
5. 🔄 Set up custom domain (optional)
6. 🔄 Configure mobile app builds (iOS/Android)
7. 🔄 Set up staging environment (optional)

## Support

For issues:
1. Check CloudWatch logs (backend)
2. Check Amplify build logs (frontend)
3. Verify environment variables
4. Test API endpoints directly
