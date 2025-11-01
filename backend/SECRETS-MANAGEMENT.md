# AWS Secrets Management Guide

## Why Use AWS Secrets Manager?

### Problems with Environment Variables:
- ❌ **Visible in console** to anyone with AWS access
- ❌ **No encryption at rest** (stored as plain text)
- ❌ **No audit trail** (who accessed what, when?)
- ❌ **No rotation** (changing secrets requires redeployment)
- ❌ **Hard to manage** across multiple environments

### Benefits of AWS Secrets Manager:
- ✅ **Encrypted** with AWS KMS
- ✅ **Automatic rotation** for secrets
- ✅ **Audit logging** (CloudTrail integration)
- ✅ **Fine-grained access control** (IAM policies)
- ✅ **Versioning** (rollback to previous values)
- ✅ **Cross-region replication** (disaster recovery)
- ✅ **No application restart** needed to update secrets

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Account                          │
│                                                           │
│  ┌─────────────────┐         ┌──────────────────┐      │
│  │  KMS Key        │────────▶│  Secrets Manager │      │
│  │  (Encryption)   │         │                  │      │
│  └─────────────────┘         │  • JWT Secret    │      │
│                               │  • OpenAI Key    │      │
│                               │  • AWS Creds     │      │
│                               │  • Email Config  │      │
│                               └──────────────────┘      │
│                                        │                 │
│                                        ▼                 │
│                               ┌──────────────────┐      │
│                               │  App Runner      │      │
│                               │  (IAM Role)      │      │
│                               │                  │      │
│                               │  Reads secrets   │      │
│                               │  at startup      │      │
│                               └──────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## Cost Comparison

### Option 1: Environment Variables
- **Cost**: Free
- **Security**: Low
- **Maintenance**: High effort

### Option 2: Secrets Manager
- **Cost**: ~$2-3/month
  - $0.40/secret/month × 4 secrets = $1.60
  - $0.05/10,000 API calls ≈ $0.50
  - KMS: $1/month
- **Security**: High
- **Maintenance**: Low effort
- **ROI**: Worth it for production apps

### Option 3: Systems Manager Parameter Store (Free Tier)
- **Cost**: Free (standard parameters)
- **Security**: Medium
- **Maintenance**: Medium effort
- **Limitation**: No automatic rotation

## Quick Start: Deploy Secrets

### Step 1: Store Secrets in AWS

```bash
cd backend
./deploy-secrets.sh
```

This will:
1. Create KMS encryption key
2. Create 4 secrets in Secrets Manager:
   - `we-counsel/application/secrets` (all secrets)
   - `we-counsel/jwt-secret` (just JWT, rotatable)
   - `we-counsel/openai-api-key` (just OpenAI key)
   - `we-counsel/database/credentials` (AWS credentials)
3. Create IAM policy for reading secrets
4. Output secret ARNs

### Step 2: Update Your Code

The code has already been created in `src/config/secrets.js`. You just need to add it to your server startup:

```javascript
// In src/server.js - add at the top, before other imports
const { loadSecrets, validateSecrets } = require('./config/secrets');

// Make server startup async
(async () => {
  try {
    // Load secrets from AWS Secrets Manager (production only)
    await loadSecrets();
    
    // Validate all required secrets are present
    validateSecrets();
    
    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 We Counsel API server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
})();
```

### Step 3: Deploy App Runner

```bash
./deploy-apprunner.sh
```

The App Runner service will automatically have access to secrets via the IAM role.

## Manual Secrets Management

### View Secrets

```bash
# List all secrets
aws secretsmanager list-secrets --region eu-west-3

# Get specific secret value
aws secretsmanager get-secret-value \
  --secret-id we-counsel/application/secrets \
  --region eu-west-3 \
  --query SecretString \
  --output text | jq
```

### Update Secrets

```bash
# Update a single secret
aws secretsmanager update-secret \
  --secret-id we-counsel/openai-api-key \
  --secret-string '{"OPENAI_API_KEY":"sk-new-key-here"}' \
  --region eu-west-3

# Update entire bundle
aws secretsmanager update-secret \
  --secret-id we-counsel/application/secrets \
  --secret-string '{
    "JWT_SECRET": "new-jwt-secret",
    "OPENAI_API_KEY": "sk-new-key",
    "AWS_REGION": "eu-west-3",
    "DYNAMODB_REGION": "eu-west-3",
    "EMAIL_FROM": "noreply@example.com",
    "FRONTEND_URL": "https://app.example.com",
    "NODE_ENV": "production"
  }' \
  --region eu-west-3
```

### Rotate Secrets

```bash
# Enable automatic rotation (requires Lambda function)
aws secretsmanager rotate-secret \
  --secret-id we-counsel/jwt-secret \
  --rotation-lambda-arn arn:aws:lambda:eu-west-3:123456:function:rotate \
  --region eu-west-3

# Or manually rotate
NEW_JWT=$(openssl rand -base64 32)
aws secretsmanager update-secret \
  --secret-id we-counsel/jwt-secret \
  --secret-string "{\"JWT_SECRET\":\"$NEW_JWT\"}" \
  --region eu-west-3
```

## Secret Organization Strategy

### Strategy 1: Single Bundle (Recommended for small apps)
All secrets in one JSON object:
```json
{
  "JWT_SECRET": "...",
  "OPENAI_API_KEY": "...",
  "AWS_REGION": "...",
  ...
}
```
**Pros**: Simple, one API call
**Cons**: Rotating one secret requires updating entire bundle

### Strategy 2: Separate Secrets (Recommended for large apps)
Each secret stored separately:
- `we-counsel/jwt-secret`
- `we-counsel/openai-api-key`
- `we-counsel/aws-credentials`

**Pros**: Granular access control, easier rotation
**Cons**: Multiple API calls (more cost)

### Strategy 3: Hierarchical (Recommended for multi-environment)
```
we-counsel/production/secrets
we-counsel/staging/secrets
we-counsel/development/secrets
```

## Security Best Practices

### 1. Use IAM Roles Instead of Access Keys
```yaml
# Don't do this:
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Do this instead:
# Attach IAM role to App Runner with DynamoDB/SES permissions
```

### 2. Principle of Least Privilege
Only grant access to specific secrets:
```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "arn:aws:secretsmanager:*:*:secret:we-counsel/*"
}
```

### 3. Enable CloudTrail Logging
Monitor who accessed secrets:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=we-counsel/jwt-secret \
  --region eu-west-3
```

### 4. Enable Secret Rotation
Automatically rotate secrets every 30/60/90 days

### 5. Use KMS Customer Managed Keys
More control over encryption:
- Set key rotation policy
- Define key usage policies
- Audit key usage

## Migration from Environment Variables

### Current (Environment Variables):
```yaml
# apprunner.yaml
env:
  - name: JWT_SECRET
    value: "my-secret-key"
  - name: OPENAI_API_KEY
    value: "sk-..."
```

### New (Secrets Manager):
```yaml
# apprunner.yaml
env:
  - name: NODE_ENV
    value: "production"
  - name: AWS_REGION
    value: "eu-west-3"
# Secrets loaded at runtime via IAM role
```

## Troubleshooting

### "Access Denied" when reading secrets
1. Check IAM role has `secretsmanager:GetSecretValue` permission
2. Check KMS key policy allows decryption
3. Verify secret ARN is correct

### "Secret not found"
1. Check region matches (`eu-west-3`)
2. Verify secret name is correct (case-sensitive)
3. Check secret wasn't deleted

### App fails to start
1. Check CloudWatch logs for secret loading errors
2. Verify all required secrets exist
3. Check IAM role is attached to App Runner

## Comparison Table

| Feature | Env Vars | Secrets Manager | Parameter Store |
|---------|----------|-----------------|-----------------|
| **Cost** | Free | ~$2/month | Free |
| **Encryption** | ❌ No | ✅ KMS | ✅ KMS |
| **Rotation** | ❌ Manual | ✅ Automatic | ❌ Manual |
| **Audit** | ❌ No | ✅ CloudTrail | ✅ CloudTrail |
| **Versioning** | ❌ No | ✅ Yes | ✅ Yes |
| **Access Control** | ⚠️ Basic | ✅ Granular | ✅ Granular |
| **Replication** | ❌ No | ✅ Multi-region | ❌ No |
| **API Calls** | Free | $0.05/10k | Free |

## Recommendation

For **We Counsel AI**:
- **Development**: Use `.env` file (free, simple)
- **Production**: Use **Secrets Manager** ($2-3/month, secure, professional)

The extra $2-3/month is worth it for:
- Peace of mind (encrypted, audited)
- Professional security posture
- Easy secret rotation
- No downtime when updating secrets

## Next Steps

1. ✅ Deploy secrets: `./deploy-secrets.sh`
2. Update `server.js` to load secrets at startup
3. Deploy App Runner: `./deploy-apprunner.sh`
4. Test accessing secrets
5. Set up secret rotation (optional)
