# Domain Setup Summary - entrelace.app

## ✅ Completed Steps

### 1. Route 53 Hosted Zone
- **Domain**: entrelace.app
- **Hosted Zone ID**: Z0180041362VEUE7TM637
- **Status**: Created
- **Cost**: $0.50/month

### 2. AWS Nameservers (IMPORTANT - Update in OVHcloud!)
Update these in your OVHcloud control panel:

```
ns-1031.awsdns-00.org
ns-1756.awsdns-27.co.uk
ns-902.awsdns-48.net
ns-378.awsdns-47.com
```

**How to update in OVHcloud:**
1. Go to: https://www.ovh.com/manager/
2. Navigate to: Web Cloud → Domain names → we-counsel.com
3. Click: DNS servers (or "Serveurs DNS")
4. Replace with the 4 AWS nameservers above
5. Save changes

**⚠️ DNS propagation takes 15 minutes to 48 hours (usually ~1 hour)**

### 3. SSL Certificate (FREE!)
- **Certificate ARN**: `arn:aws:acm:eu-west-3:345594605141:certificate/604b8d2e-d823-431e-8a0d-1d145b9f976c`
- **Domains**: we-counsel.com, *.we-counsel.com (wildcard)
- **Status**: Pending validation (will auto-validate once DNS propagates)
- **Cost**: FREE
- **Validation**: DNS validation record added to Route 53 ✅

### 4. SES Email Domain Verification
- **Domain**: we-counsel.com
- **DKIM Records**: Added to Route 53 ✅
- **Status**: Pending verification (will auto-verify once DNS propagates)
- **Will enable**: Sending emails from noreply@we-counsel.com

## 🎯 Next Steps

### Step 1: Update OVHcloud Nameservers (DO THIS NOW!)
Follow the instructions in section 2 above to point your domain to AWS.

### Step 2: Wait for DNS Propagation (15 min - 48 hours)
Check propagation status:
```bash
dig we-counsel.com NS
```

Expected result: Should show AWS nameservers

### Step 3: Verify SSL Certificate Status
```bash
aws acm describe-certificate \
  --certificate-arn "arn:aws:acm:eu-west-3:345594605141:certificate/604b8d2e-d823-431e-8a0d-1d145b9f976c" \
  --region eu-west-3 \
  --query 'Certificate.Status'
```

Expected: `"ISSUED"` (after DNS propagates)

### Step 4: Verify SES Domain Status
```bash
aws sesv2 get-email-identity \
  --email-identity we-counsel.com \
  --region eu-west-3 \
  --query 'DkimAttributes.Status'
```

Expected: `"SUCCESS"` (after DNS propagates)

### Step 5: Update Frontend Amplify URL
Once DNS is working, update Amplify to use custom domain:
```bash
aws amplify create-domain-association \
  --app-id d3ct6eeeltgvfr \
  --domain-name we-counsel.com \
  --sub-domain-settings prefix=www,branchName=main \
  --region eu-west-3
```

### Step 6: Update SES Production Access Request
Reply to AWS Support case with:
- ✅ Domain verified: we-counsel.com
- ✅ DKIM configured
- ✅ Ready for production access

## 📊 DNS Records Created

| Type | Name | Value | Purpose |
|------|------|-------|---------|
| CNAME | _e50b94baa4b0394e8a7412c87c01a7b4 | _737246b90815233496939413b4cc759a.jkddzztszm.acm-validations.aws. | SSL validation |
| CNAME | szo6crylptxtm54ymj4qwojsqo5jsbf4._domainkey | szo6crylptxtm54ymj4qwojsqo5jsbf4.dkim.amazonses.com | DKIM 1/3 |
| CNAME | frqhk6scp5boqpnq6f2ogshcnauapfhp._domainkey | frqhk6scp5boqpnq6f2ogshcnauapfhp.dkim.amazonses.com | DKIM 2/3 |
| CNAME | 6jggwrdbyfd6j2a35efbuewcfzi2o2go._domainkey | 6jggwrdbyfd6j2a35efbuewcfzi2o2go.dkim.amazonses.com | DKIM 3/3 |

## 💰 Cost Summary

| Item | Cost |
|------|------|
| Domain (OVHcloud) | Your purchase price |
| Route 53 Hosted Zone | $0.50/month |
| SSL Certificate (ACM) | **FREE** |
| DNS Queries (Route 53) | ~$0.40/month (first million free) |
| **Monthly Total** | **~$0.90/month** |

## 🔍 Troubleshooting

### Check DNS Propagation
```bash
# Check if nameservers updated
dig we-counsel.com NS +short

# Check SSL validation record
dig _e50b94baa4b0394e8a7412c87c01a7b4.we-counsel.com CNAME +short

# Check DKIM records
dig szo6crylptxtm54ymj4qwojsqo5jsbf4._domainkey.we-counsel.com CNAME +short
```

### If SSL Certificate Doesn't Validate
1. Verify DNS propagation completed
2. Check validation record exists in Route 53
3. Wait up to 30 minutes after DNS propagation

### If SES Domain Doesn't Verify
1. Verify all 3 DKIM records exist
2. Check DNS propagation completed
3. Wait up to 72 hours for verification

## 📞 Support

If you encounter issues:
- **Route 53**: https://console.aws.amazon.com/route53
- **ACM**: https://console.aws.amazon.com/acm
- **SES**: https://console.aws.amazon.com/ses
- **OVHcloud**: https://www.ovh.com/manager/

---

**Created**: 2025-11-20
**Domain**: we-counsel.com
**Region**: eu-west-3
