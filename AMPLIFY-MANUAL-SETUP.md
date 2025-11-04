# AWS Amplify - Manual Setup Guide (GitHub App)

## Why Manual Setup?

AWS Amplify has migrated from OAuth/Personal Access Tokens to **GitHub App** authentication. The GitHub App offers:
- ✅ Better security with fewer permissions
- ✅ More granular access control
- ✅ Easier revocation and management
- ✅ Better audit trail

CloudFormation doesn't support GitHub App setup directly, so the **first deployment must be done via AWS Console**.

## Step-by-Step Setup

### 1. Install AWS Amplify GitHub App

1. **Go to AWS Amplify Console**:
   ```
   https://console.aws.amazon.com/amplify/home?region=eu-west-3
   ```

2. **Click "Create new app" or "Host web app"**

3. **Choose GitHub as source**:
   - Click "GitHub" button
   - You'll be redirected to GitHub

4. **Install AWS Amplify App**:
   - Click "Install & Authorize"
   - Choose: "Only select repositories"
   - Select: `cvienot/we-counsel-ai`
   - Click "Install"

5. **Return to AWS Console**:
   - You should see your repository listed
   - Select: `cvienot/we-counsel-ai`
   - Click "Next"

### 2. Configure Build Settings

1. **Choose branch**:
   - Branch: `main`
   - Click "Next"

2. **App name**:
   - App name: `we-counsel-web`
   - Environment name: `production`

3. **Build settings** (AWS will auto-detect):
   - AWS should find `amplify.yml` in your repo
   - If not, paste this:

   ```yaml
   version: 1
   frontend:
     phases:
       preBuild:
         commands:
           - flutter channel stable
           - flutter upgrade
           - cd frontend
           - flutter pub get
       build:
         commands:
           - flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL --dart-define=ENVIRONMENT=production
     artifacts:
       baseDirectory: frontend/build/web
       files:
         - '**/*'
     cache:
       paths:
         - frontend/.flutter-plugins
         - frontend/.flutter-plugins-dependencies
         - frontend/.dart_tool/**/*
   ```

4. **Advanced settings** (expand):
   - Add environment variables:
     - `API_BASE_URL`: `https://YOUR-BACKEND-URL.awsapprunner.com/api`
     - `ENVIRONMENT`: `production`
   
   To get your backend URL:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name we-counsel-apprunner \
     --region eu-west-3 \
     --query 'Stacks[0].Outputs[?OutputKey==`ServiceUrl`].OutputValue' \
     --output text
   ```

5. **Review and create**:
   - Review all settings
   - Click "Save and deploy"

### 3. Wait for Deployment

The first build takes ~5-10 minutes:

1. **Monitor build progress**:
   - You'll see: Provision → Build → Deploy → Verify
   
2. **Check for errors**:
   - Click on the build to see logs
   - Common issues: Flutter version, dependencies

3. **Get your URL**:
   - Once deployed, you'll see: `https://main.xxxx.amplifyapp.com`

### 4. Update Backend CORS

Your backend needs to allow requests from your Amplify URL:

```bash
cd backend

# Edit apprunner.yaml, add your Amplify URL
# In the environment variables section:
FRONTEND_URL=https://main.xxxx.amplifyapp.com

# Commit and push
git add apprunner.yaml
git commit -m "Add Amplify URL to CORS whitelist"
git push  # This triggers App Runner redeployment
```

### 5. Test Deployment

1. **Visit your Amplify URL**: `https://main.xxxx.amplifyapp.com`
2. **Open browser console** (F12)
3. **Register a new account**
4. **Check for CORS errors**
5. **Test login and features**

## Continuous Deployment

Now that GitHub App is installed, **every push to `main` automatically triggers a new build and deployment**! 🎉

```bash
# Make changes to frontend
git add .
git commit -m "Update UI"
git push  # Amplify automatically rebuilds
```

## Troubleshooting

### Build Fails

**Check build logs**:
1. Go to Amplify Console
2. Click on your app
3. Click on the failed build
4. Review each phase (Provision, Build, Deploy)

**Common issues**:
- Flutter SDK version mismatch
- Missing dependencies
- Environment variable issues

### CORS Errors

If you see CORS errors in browser console:

```bash
# Update backend CORS
cd backend
# Edit src/server.js or apprunner.yaml
# Add your Amplify URL to the allowed origins
git push
```

### Wrong API URL

Update environment variable in Amplify:

```bash
aws amplify update-branch \
  --app-id YOUR_APP_ID \
  --branch-name main \
  --environment-variables API_BASE_URL=https://YOUR-BACKEND.awsapprunner.com/api \
  --region eu-west-3
```

Or via console:
1. Amplify Console → Your app
2. Environment variables
3. Edit `API_BASE_URL`
4. Redeploy

## Managing GitHub App Permissions

### View Installed Apps
```
https://github.com/settings/installations
```

### Revoke Access
1. Go to GitHub Settings → Applications
2. Find "AWS Amplify"
3. Click "Configure"
4. Click "Uninstall"

### Update Repository Access
1. GitHub Settings → Applications → AWS Amplify
2. Click "Configure"
3. Select/deselect repositories

## Alternative: Use Amplify CLI

If you prefer command-line:

```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Initialize Amplify
cd frontend
amplify init

# Add hosting
amplify add hosting

# Deploy
amplify publish
```

## Cost Tracking

Monitor your Amplify costs:

```bash
# Get billing info
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-11-30 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE \
  --filter file://filter.json
```

Or check AWS Console → Billing Dashboard

## Summary

✅ **First time**: Use AWS Console to install GitHub App  
✅ **Subsequent deploys**: Automatic on git push  
✅ **Environment updates**: Use AWS Console or CLI  
✅ **No more tokens**: GitHub App handles everything  

**Your Amplify app is now live at**: `https://main.xxxx.amplifyapp.com` 🚀
