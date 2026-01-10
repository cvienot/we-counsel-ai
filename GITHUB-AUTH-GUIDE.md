# GitHub Authentication for AWS Deployments

## Overview

Your deployment uses **two different AWS services** that connect to GitHub, each with their own authentication method:

## 1. Backend: App Runner → GitHub Connection

**Service**: AWS App Runner  
**Authentication**: GitHub Connection (OAuth)  
**Created via**: AWS Console or CLI

### How it works:
- One-time OAuth flow through GitHub
- Creates a persistent connection in AWS
- Connection ARN can be reused across multiple App Runner services
- No tokens to manage or rotate

### Create Connection:
```bash
# Via AWS Console (easiest):
1. Go to App Runner → GitHub connections
2. Click "Add connection"
3. Name: "we-counsel-github"
4. Authorize GitHub OAuth
5. Copy the Connection ARN

# Via CLI:
aws apprunner create-connection \
  --connection-name we-counsel-github \
  --provider-type GITHUB \
  --region eu-west-3
```

### Reuse Connection:
✅ The backend deployment script saves this ARN  
✅ Multiple App Runner services can use the same connection  
✅ No expiration or rotation needed  

## 2. Frontend: Amplify → GitHub Personal Access Token

**Service**: AWS Amplify  
**Authentication**: GitHub Personal Access Token (PAT)  
**Created via**: GitHub Settings

### How it works:
- Create token in GitHub settings
- Paste token into Amplify deployment
- Amplify encrypts and stores the token
- Token scope: `repo` (full control of private repositories)

### Why Different?
- Amplify and App Runner use different AWS SDKs
- Amplify requires a PAT for build hooks and webhooks
- PATs give more granular control over permissions

### Create Token:
```bash
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "AWS Amplify - We Coach"
4. Expiration: No expiration (or 90 days if preferred)
5. Scopes: Select "repo" ✓
6. Click "Generate token"
7. Copy and save the token (you won't see it again!)
```

### Reuse Token:
✅ Same token can be used for multiple Amplify apps  
✅ Once provided to Amplify, it's stored securely  
❌ If token expires, you'll need to regenerate  

## Can I Reuse the Same GitHub Account?

**Yes!** Both methods connect to your GitHub account:

```
Your GitHub Account
       │
       ├─── App Runner Connection (OAuth)
       │    └─── Used by: Backend (App Runner)
       │
       └─── Personal Access Token
            └─── Used by: Frontend (Amplify)
```

## Comparison Table

| Feature | App Runner | Amplify |
|---------|-----------|---------|
| **Auth Method** | GitHub Connection (OAuth) | Personal Access Token |
| **Created In** | AWS Console/CLI | GitHub Settings |
| **Expires** | No | Optional (can be indefinite) |
| **Rotation** | Not needed | Manual (if expiration set) |
| **Permissions** | OAuth scope | Token scope (repo) |
| **Reusable** | ✅ Yes (ARN) | ✅ Yes (same token) |
| **Revoke** | AWS Console | GitHub Settings |

## Security Best Practices

### For App Runner Connection:
- ✅ One connection per AWS account is sufficient
- ✅ Revoke if you no longer use App Runner
- ✅ Monitor in AWS Console → App Runner → Connections

### For Amplify Token:
- ✅ Use fine-grained tokens (if available)
- ✅ Set expiration (e.g., 90 days) for security
- ✅ Use GitHub's token expiration notifications
- ✅ Revoke unused tokens in GitHub Settings → Developer settings
- ⚠️ Never commit tokens to code
- ⚠️ Store securely if saving locally

## Deployment Script Behavior

### Backend (`deploy-apprunner.sh`):
1. Checks for existing GitHub connection
2. If not found, prompts to create one
3. Saves connection ARN in CloudFormation parameters
4. Reuses same ARN on subsequent deployments

### Frontend (`deploy-amplify.sh`):
1. Checks if backend has GitHub connection (informational only)
2. Checks if Amplify already has apps (token exists)
3. Prompts for token if needed
4. Allows reusing existing token if already configured

## Troubleshooting

### App Runner: "No GitHub connection found"
```bash
# List existing connections
aws apprunner list-connections --region eu-west-3

# Create new connection
aws apprunner create-connection \
  --connection-name we-counsel-github \
  --provider-type GITHUB \
  --region eu-west-3
```

### Amplify: "Invalid GitHub token"
- Token may have expired
- Token may have been revoked
- Scope may be insufficient (needs `repo`)

**Solution**: Generate a new token with proper scopes

### Both: "Repository access denied"
- GitHub app/OAuth may not have access to private repos
- Check repository permissions in GitHub settings

## Quick Setup Guide

### First Time Setup:

**Step 1: Create GitHub Connection for App Runner**
```bash
# Go to AWS Console → App Runner → GitHub connections
# Create connection, authorize GitHub, copy ARN
```

**Step 2: Create GitHub Token for Amplify**
```bash
# Go to GitHub → Settings → Developer settings → Personal access tokens
# Generate new token (classic), select 'repo' scope, copy token
```

**Step 3: Deploy Backend**
```bash
cd backend
./deploy-apprunner.sh
# Paste GitHub Connection ARN when prompted
```

**Step 4: Deploy Frontend**
```bash
cd frontend
./deploy-amplify.sh
# Paste GitHub Personal Access Token when prompted
```

### Subsequent Deployments:

Both scripts will reuse existing credentials automatically! 🎉

```bash
# Backend - reuses GitHub Connection ARN
cd backend
./deploy-apprunner.sh  # No prompts needed

# Frontend - reuses stored token
cd frontend
./deploy-amplify.sh  # Press Enter to reuse existing token
```

## Summary

✅ **You can reuse the same GitHub account** for both services  
✅ **Two different authentication methods** required by AWS  
✅ **Set up once**, then reuse on subsequent deployments  
✅ **Both stored securely** by AWS (no need to save locally)  
✅ **Deployment scripts handle** credential management  

The setup may seem complex initially, but after the first deployment, both scripts will remember your credentials and deployments become seamless! 🚀
