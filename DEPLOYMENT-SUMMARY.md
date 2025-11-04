# We Counsel AI - Deployment Summary

## Overview
Complete deployment infrastructure for a couples counselling app with AWS backend and multi-platform Flutter frontend.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud                            │
│                                                         │
│  ┌──────────────────┐       ┌──────────────────┐      │
│  │  AWS Amplify     │       │  App Runner      │      │
│  │  Flutter Web     │◄─────►│  Node.js API     │      │
│  │  (Frontend)      │       │  (Backend)       │      │
│  └──────────────────┘       └────────┬─────────┘      │
│                                       │                 │
│                              ┌────────▼─────────┐      │
│                              │  DynamoDB Tables │      │
│                              │  - Users         │      │
│                              │  - Conversations │      │
│                              │  - Messages      │      │
│                              │  - Couples       │      │
│                              │  - Invitations   │      │
│                              └──────────────────┘      │
│                                       │                 │
│                              ┌────────▼─────────┐      │
│                              │ Secrets Manager  │      │
│                              │ - JWT Secret     │      │
│                              │ - OpenAI Key     │      │
│                              └──────────────────┘      │
│                                                         │
│  ┌──────────────────┐       ┌──────────────────┐      │
│  │  AWS SES         │       │  OpenAI API      │      │
│  │  Email Service   │       │  AI Counselor    │      │
│  └──────────────────┘       └──────────────────┘      │
└─────────────────────────────────────────────────────────┘

          ┌──────────────────────────────┐
          │  Future: Mobile Apps         │
          │  - iOS (App Store)           │
          │  - Android (Play Store)      │
          └──────────────────────────────┘
```

## Deployment Status

### ✅ Backend (App Runner)
- **Status**: Ready to deploy
- **Runtime**: Node.js 22
- **Region**: eu-west-3
- **Features**:
  - JWT authentication
  - OpenAI integration for AI counselor
  - Real-time messaging with SSE
  - Partner invitation system
  - DynamoDB for data persistence
  - SES for email notifications

**Deploy**: `cd backend && ./deploy-apprunner.sh`

### ✅ Frontend (Amplify)
- **Status**: Ready to deploy
- **Framework**: Flutter 3.8+
- **Region**: eu-west-3
- **Platforms**: Web (deployed), iOS (future), Android (future)
- **Features**:
  - Responsive design
  - Real-time updates
  - Secure authentication
  - Partner connection
  - AI counselor chat

**Deploy**: `cd frontend && ./deploy-amplify.sh`

### ✅ Infrastructure (CloudFormation)
- **DynamoDB Tables**: ✅ Ready
- **Secrets Manager**: ✅ Ready
- **App Runner**: ✅ Ready
- **Amplify Hosting**: ✅ Ready

## Deployment Order

1. **Deploy DynamoDB Tables** (if not done)
   ```bash
   cd backend
   aws cloudformation deploy \
     --template-file cloudformation-dynamodb.yaml \
     --stack-name we-counsel-dynamodb \
     --region eu-west-3
   ```

2. **Deploy Secrets** (if not done)
   ```bash
   cd backend
   ./deploy-secrets.sh
   ```

3. **Deploy Backend**
   ```bash
   cd backend
   ./deploy-apprunner.sh
   ```
   Note the App Runner URL from output.

4. **Deploy Frontend**
   ```bash
   cd frontend
   ./deploy-amplify.sh
   ```
   When prompted, paste the App Runner URL.

5. **Update Backend CORS**
   - Edit `backend/apprunner.yaml`
   - Add Amplify URL to `FRONTEND_URL`
   - Push to trigger redeployment

## Configuration Management

### Backend Environment Variables
**Stored in**: Secrets Manager (sensitive) + App Runner Config (non-sensitive)

**Sensitive** (Secrets Manager - $1/month):
- `JWT_SECRET`
- `OPENAI_API_KEY`

**Non-Sensitive** (App Runner env vars - Free):
- `AWS_REGION=eu-west-3`
- `DYNAMODB_REGION=eu-west-3`
- `EMAIL_FROM=noreply@example.com`
- `FRONTEND_URL=https://your-amplify-url.com`
- `NODE_ENV=production`

### Frontend Environment Variables
**Stored in**: Amplify Environment Variables

- `API_BASE_URL=https://your-app-runner-url.awsapprunner.com/api`
- `ENVIRONMENT=production`

## Cost Breakdown

### Monthly AWS Costs (Estimated)

| Service | Cost | Notes |
|---------|------|-------|
| **App Runner** | ~$25-50 | 1 vCPU, 2GB RAM, always on |
| **DynamoDB** | ~$0-5 | Pay-per-request, light usage |
| **Secrets Manager** | $1 | 2 secrets ($0.50 each) |
| **Amplify Hosting** | ~$5-10 | Build + hosting + bandwidth |
| **SES** | ~$0-1 | $0.10/1000 emails |
| **CloudWatch Logs** | ~$1-2 | Log storage |
| **OpenAI API** | Variable | GPT-4 usage-based |
| **Total (AWS)** | **~$33-69/mo** | Excluding OpenAI |

**Cost Optimization:**
- DynamoDB: Pay-per-request (vs provisioned $12/mo per table)
- Secrets Manager: Only 2 secrets ($1 vs $3 for all 5)
- App Runner: Auto-scaling reduces idle costs
- Amplify: Free tier covers initial traffic

## Repository Structure

```
we-counsel-reboot/
├── backend/
│   ├── src/
│   │   ├── server.js                    # Express app with async secret loading
│   │   ├── config/
│   │   │   ├── secrets.js              # AWS Secrets Manager integration
│   │   │   └── database.js             # DynamoDB configuration
│   │   ├── middleware/                 # Auth, error handling
│   │   ├── routes/                     # API endpoints
│   │   └── services/                   # OpenAI, email, streaming
│   ├── scripts/                        # Dev tools, database setup
│   ├── apprunner.yaml                  # App Runner build config
│   ├── cloudformation-dynamodb.yaml    # DynamoDB IaC
│   ├── cloudformation-secrets.yaml     # Secrets Manager IaC
│   ├── cloudformation-apprunner.yaml   # App Runner IaC
│   ├── deploy-secrets.sh               # Deploy secrets
│   └── deploy-apprunner.sh             # Deploy backend
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart                   # App entry point
│   │   ├── config/
│   │   │   └── environment.dart        # Environment config
│   │   ├── screens/                    # UI screens
│   │   ├── services/
│   │   │   └── api_service.dart        # API client with env support
│   │   ├── providers/                  # State management
│   │   └── widgets/                    # Reusable components
│   ├── amplify.yml                     # Amplify build config
│   ├── cloudformation-amplify.yaml     # Amplify IaC
│   ├── deploy-amplify.sh               # Deploy frontend
│   ├── deploy-frontend-manual.sh       # Manual build
│   ├── .env.development                # Dev environment
│   └── .env.production                 # Prod environment
│
├── DEPLOYMENT.md                       # Backend deployment guide
├── FRONTEND-DEPLOYMENT.md              # Frontend deployment guide
├── DEPLOYMENT-SUMMARY.md               # This file
└── README.md                           # Project overview
```

## Security

### Authentication Flow
1. User registers/logs in → Backend issues JWT
2. JWT stored in Flutter secure storage
3. All API requests include JWT in Authorization header
4. Backend validates JWT using secret from Secrets Manager

### Secrets Management
- ✅ No secrets in code or environment files committed to git
- ✅ Backend secrets in AWS Secrets Manager (encrypted with KMS)
- ✅ Development uses local `.env` (not committed)
- ✅ Production loads secrets at runtime from Secrets Manager

### Network Security
- ✅ HTTPS only (App Runner + Amplify)
- ✅ CORS configured with whitelist
- ✅ JWT expiration (7 days)
- ✅ IAM roles for AWS service access (no hardcoded credentials)

## CI/CD Pipeline

### Backend (App Runner)
```
Git Push → GitHub → App Runner detects change → 
Build (npm install) → Deploy → Health check → 
Traffic switched to new version
```

### Frontend (Amplify)
```
Git Push → GitHub → Amplify detects change → 
Build (flutter build web) → Deploy to CDN → 
Live in seconds
```

## Monitoring & Logs

### Backend Logs
```bash
# View logs via AWS CLI
aws logs tail /aws/apprunner/we-counsel-api --follow --region eu-west-3

# Or in AWS Console:
https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#logsV2:log-groups
```

### Frontend Logs
```bash
# View build logs in Amplify Console:
https://eu-west-3.console.aws.amazon.com/amplify/home?region=eu-west-3
```

## Testing Deployment

### Test Backend
```bash
# Health check
curl https://your-app-runner-url.awsapprunner.com/health

# Login
curl -X POST https://your-app-runner-url.awsapprunner.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Test Frontend
1. Visit Amplify URL: `https://main.xxxxxx.amplifyapp.com`
2. Register new account
3. Test login
4. Verify API connection

## Future Enhancements

### Mobile Apps
- [ ] iOS app deployment to TestFlight/App Store
- [ ] Android app deployment to Play Store
- [ ] Push notifications (FCM)
- [ ] Deep linking
- [ ] Biometric authentication

### Infrastructure
- [ ] Custom domain for backend (Route53 + Certificate Manager)
- [ ] Custom domain for frontend
- [ ] Staging environment
- [ ] Database backups (DynamoDB Point-in-Time Recovery)
- [ ] CloudFront CDN for backend (optional)

### Features
- [ ] Video call integration
- [ ] Payment processing (Stripe)
- [ ] Admin dashboard
- [ ] Analytics (Google Analytics)
- [ ] Error tracking (Sentry)

## Troubleshooting

### Backend Won't Start
1. Check CloudWatch logs
2. Verify secrets are set: `aws secretsmanager get-secret-value --secret-id we-counsel/application/secrets --region eu-west-3`
3. Check IAM roles have proper permissions
4. Verify DynamoDB tables exist

### Frontend Build Fails
1. Check Amplify build logs
2. Verify Flutter version in `amplify.yml`
3. Check `pubspec.yaml` dependencies
4. Test build locally: `flutter build web --release`

### CORS Errors
1. Update `backend/src/server.js` with Amplify URL
2. Redeploy backend
3. Clear browser cache

### API Not Connecting
1. Verify `API_BASE_URL` in Amplify environment variables
2. Check App Runner is running
3. Test API directly with curl
4. Check CORS configuration

## Support Contacts

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Flutter Documentation**: https://docs.flutter.dev/
- **OpenAI API Docs**: https://platform.openai.com/docs

## Quick Commands Reference

```bash
# Backend
cd backend
./deploy-secrets.sh          # Deploy secrets
./deploy-apprunner.sh        # Deploy backend
npm run dev                  # Local development
npm run db:reset             # Reset local database

# Frontend  
cd frontend
./deploy-amplify.sh          # Deploy to AWS
./deploy-frontend-manual.sh  # Build locally
flutter run -d chrome        # Local development
flutter build web --release  # Production build

# Infrastructure
aws cloudformation list-stacks --region eu-west-3  # List all stacks
aws apprunner list-services --region eu-west-3     # List App Runner services
aws amplify list-apps --region eu-west-3           # List Amplify apps
```

## Success Checklist

- [ ] Backend deployed to App Runner
- [ ] Frontend deployed to Amplify
- [ ] Can register new account
- [ ] Can log in
- [ ] Can send messages
- [ ] AI counselor responds
- [ ] Partner invitation works
- [ ] Email notifications work
- [ ] Real-time updates work
- [ ] Mobile-responsive design works

## Deployment Complete! 🎉

You now have a production-ready, scalable, multi-platform couples counselling app running on AWS with CI/CD pipelines and proper security.
