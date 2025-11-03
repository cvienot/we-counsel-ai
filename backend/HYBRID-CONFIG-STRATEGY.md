# Hybrid Configuration Strategy: Environment Variables + Secrets Manager

## Overview

**Best of both worlds:** Use environment variables for non-sensitive config (free) and Secrets Manager only for sensitive secrets (minimal cost).

## Cost Comparison

### ❌ All in Secrets Manager
- Cost: ~$3/month
- 5-6 secrets × $0.40 = ~$2.40
- API calls: ~$0.50
- Total: **$2.90/month**

### ✅ Hybrid Approach (Recommended)
- Cost: ~$1/month
- 2 secrets × $0.40 = $0.80
- API calls: ~$0.20
- Total: **$1.00/month**
- **Savings: $1.90/month (65% cheaper!)**

## What Goes Where

### Environment Variables (apprunner.yaml) - FREE 🆓

```yaml
env:
  - name: NODE_ENV
    value: production
  - name: AWS_REGION
    value: eu-west-3
  - name: DYNAMODB_REGION
    value: eu-west-3
  - name: EMAIL_FROM
    value: noreply@yourdomain.com
  - name: FRONTEND_URL
    value: https://your-frontend.com
```

**Why it's safe:**
- ✅ Not sensitive (knowing your AWS region doesn't help attackers)
- ✅ Public information (email address is in every email you send)
- ✅ Configuration, not credentials
- ✅ Can be version controlled

### Secrets Manager - $1/month 🔒

```json
{
  "JWT_SECRET": "base64-encoded-secret-key",
  "OPENAI_API_KEY": "sk-..."
}
```

**Why it needs protection:**
- ❌ JWT_SECRET: If leaked, anyone can forge authentication tokens
- ❌ OPENAI_API_KEY: Costs you money if stolen

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              App Runner Container                       │
│                                                           │
│  ┌──────────────────────────────────────────────┐      │
│  │  Environment Variables (from apprunner.yaml) │      │
│  │  • NODE_ENV=production                       │      │
│  │  • AWS_REGION=eu-west-3                      │      │
│  │  • EMAIL_FROM=noreply@domain.com            │      │
│  │  • FRONTEND_URL=https://...                 │      │
│  └──────────────────────────────────────────────┘      │
│                      │                                   │
│                      ▼                                   │
│  ┌──────────────────────────────────────────────┐      │
│  │  Application Startup (server.js)             │      │
│  │  await loadSecrets()                         │      │
│  └──────────────────────────────────────────────┘      │
│                      │                                   │
│                      ▼                                   │
│  ┌──────────────────────────────────────────────┐      │
│  │  Secrets Loader (src/config/secrets.js)     │      │
│  │  Fetches from Secrets Manager                │      │
│  └──────────────────────────────────────────────┘      │
│                      │                                   │
│                      ▼                                   │
│  ┌──────────────────────────────────────────────┐      │
│  │  process.env now has ALL config:             │      │
│  │  • JWT_SECRET (from Secrets Manager)         │      │
│  │  • OPENAI_API_KEY (from Secrets Manager)     │      │
│  │  • NODE_ENV (from env vars)                  │      │
│  │  • AWS_REGION (from env vars)                │      │
│  │  • ... everything else                        │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## Decision Matrix

| Variable | Where | Why | Cost |
|----------|-------|-----|------|
| `JWT_SECRET` | Secrets Manager | ❌ Critical security | $0.40/mo |
| `OPENAI_API_KEY` | Secrets Manager | ❌ Costs money if leaked | $0.40/mo |
| `AWS_ACCESS_KEY_ID` | ❌ **Don't use!** | Use IAM roles instead | Free |
| `AWS_SECRET_ACCESS_KEY` | ❌ **Don't use!** | Use IAM roles instead | Free |
| `NODE_ENV` | Env var | ✅ Not sensitive | Free |
| `AWS_REGION` | Env var | ✅ Public info | Free |
| `DYNAMODB_REGION` | Env var | ✅ Public info | Free |
| `EMAIL_FROM` | Env var | ✅ Public (in emails) | Free |
| `FRONTEND_URL` | Env var | ✅ Public (in browser) | Free |
| `PORT` | Env var | ✅ Configuration | Free |

## How It Works

### Development (.env file)
```bash
# .env
NODE_ENV=development
JWT_SECRET=dev-secret
OPENAI_API_KEY=sk-dev-key
AWS_REGION=us-east-1
DYNAMODB_REGION=us-east-1
EMAIL_FROM=dev@localhost
FRONTEND_URL=http://localhost:8080
```

### Production (Hybrid)
```yaml
# apprunner.yaml (non-sensitive)
env:
  - name: NODE_ENV
    value: production
  - name: AWS_REGION
    value: eu-west-3
  - name: EMAIL_FROM
    value: noreply@yourdomain.com
```

```javascript
// src/config/secrets.js (loads sensitive at runtime)
await loadSecrets(); // Fetches JWT_SECRET and OPENAI_API_KEY
```

## Implementation

### 1. Deploy Secrets (Only 2 secrets!)

```bash
./deploy-secrets.sh
# Only asks for:
# - JWT_SECRET (or generates)
# - OPENAI_API_KEY
```

### 2. Update apprunner.yaml

```yaml
env:
  - name: EMAIL_FROM
    value: noreply@yourdomain.com  # ← Update this!
  - name: FRONTEND_URL
    value: https://your-frontend.com  # ← Update this after frontend deployment!
```

### 3. Deploy App Runner

```bash
./deploy-apprunner.sh
```

### 4. Update Non-Sensitive Config Anytime

No redeployment needed! Just update `apprunner.yaml` and push to git:

```bash
# Edit apprunner.yaml
vi backend/apprunner.yaml

# Commit and push
git add backend/apprunner.yaml
git commit -m "Update email config"
git push

# App Runner auto-deploys!
```

## Updating Configuration

### Update Non-Sensitive (Email, URLs, etc.)

**Method 1: Via code (recommended)**
```bash
# Edit apprunner.yaml
vi backend/apprunner.yaml

# Commit and push - auto deploys!
git add backend/apprunner.yaml
git commit -m "Update FRONTEND_URL"
git push
```

**Method 2: Via AWS Console**
1. App Runner → Your service → Configuration
2. Edit environment variables
3. Deploy

### Update Sensitive (JWT, OpenAI Key)

```bash
# Update secrets
aws secretsmanager update-secret \
  --secret-id we-counsel/application/secrets \
  --secret-string '{"JWT_SECRET":"new-secret","OPENAI_API_KEY":"sk-new-key"}' \
  --region eu-west-3

# Trigger App Runner redeployment to load new secrets
aws apprunner start-deployment \
  --service-arn <your-service-arn> \
  --region eu-west-3
```

## Security Considerations

### ✅ Safe to Store as Environment Variables

- **Region names**: Not sensitive
- **Email addresses**: Already public (in sent emails)
- **Frontend URLs**: Public (anyone can see in browser)
- **Service names**: Not sensitive
- **Port numbers**: Standard configuration

### ❌ Must Use Secrets Manager

- **JWT secrets**: Can impersonate any user
- **API keys**: Can cost you money
- **Database passwords**: Direct data access
- **OAuth secrets**: Account takeover
- **Encryption keys**: Data breach

## Best Practices

1. ✅ **Never commit secrets** to git
2. ✅ **Use IAM roles** instead of AWS access keys
3. ✅ **Rotate secrets regularly** (Secrets Manager supports this)
4. ✅ **Monitor Secrets Manager access** (CloudTrail)
5. ✅ **Use least privilege** (IAM policies)
6. ✅ **Separate by environment** (prod/staging/dev)

## Troubleshooting

### "Missing JWT_SECRET"
- Check secrets were deployed: `./deploy-secrets.sh`
- Verify IAM role has Secrets Manager permissions
- Check CloudWatch logs for secret loading errors

### "Wrong email address"
- Update `EMAIL_FROM` in `apprunner.yaml`
- Commit and push to auto-deploy
- Or update via AWS Console

### "CORS error from frontend"
- Update `FRONTEND_URL` in `apprunner.yaml`
- Commit and push
- Verify URL matches exactly (no trailing slash)

## Migration Path

### From: All Environment Variables
```yaml
env:
  - name: JWT_SECRET
    value: my-secret  # ❌ Visible in console!
  - name: OPENAI_API_KEY
    value: sk-...     # ❌ Visible in console!
  - name: AWS_REGION
    value: eu-west-3  # ✅ OK
```

### To: Hybrid Approach
```yaml
env:
  - name: AWS_REGION
    value: eu-west-3  # ✅ Non-sensitive
  # JWT_SECRET and OPENAI_API_KEY loaded from Secrets Manager
```

```bash
# Deploy secrets once
./deploy-secrets.sh

# Secrets are now loaded at runtime
# No longer visible in AWS Console!
```

## Cost Breakdown

| Item | Monthly Cost |
|------|--------------|
| JWT Secret | $0.40 |
| OpenAI Key | $0.40 |
| KMS Key | ~$0.10 |
| API Calls | ~$0.10 |
| **Total** | **~$1.00/month** |

**Compare to:**
- Full Secrets Manager: $3/month
- Savings: **$2/month (65% reduction)**
- Annual savings: **$24/year**

## Recommendation

✅ **Use this hybrid approach!**

**Pros:**
- 65% cheaper than full Secrets Manager
- Still secure for sensitive data
- Easy to update non-sensitive config
- Version control for configuration
- Fast deployments (no secret updates needed)

**Cons:**
- Slightly more complex setup (2 places for config)
- Need to remember what goes where

**Verdict:** The cost savings and convenience make this the ideal approach for production.
