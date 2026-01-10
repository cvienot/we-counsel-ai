# AWS SES Production Access - Detailed Response

**Case ID**: 176341378000953

---

## Application Overview

**Application Name**: We Coach  
**Website URL**: https://main.d3ct6eeeltgvfr.amplifyapp.com  
**Purpose**: Couples coaching platform facilitating communication between partners through AI-assisted conversations

---

## Email Sending Frequency and Volume

- **Expected Volume**: 100-500 emails per day initially, scaling to ~1,000 emails/day within 6 months
- **Sending Frequency**: 
  - Partner invitations: Sent immediately when a user invites their partner
  - Notifications: Sent when new messages arrive in conversations
  - Account verification: Sent immediately upon registration
  - Password resets: Sent on-demand when requested
- **Peak Times**: Evening hours (6pm-10pm local time) when users are most active
- **Email Types**: 100% transactional (no marketing or promotional emails)

---

## Email Types with Examples

### 1. Partner Invitation Email
**Trigger**: When a user invites their partner to join the platform  
**Frequency**: Once per couple relationship  
**Example Content**:
```
Subject: [Partner Name] has invited you to We Coach

Hi [Recipient Name],

[Partner Name] has invited you to join them on We Coach, a private platform 
for couples to improve their communication through AI-assisted conversations.

Click here to accept the invitation and create your account:
[Invitation Link - expires in 7 days]

We Coach provides a safe, private space for couples to:
- Have structured conversations about important topics
- Get AI-powered insights to improve communication
- Track relationship progress over time

If you didn't expect this invitation, you can safely ignore this email.

Best regards,
We Coach Team
```

### 2. New Message Notification
**Trigger**: When a partner sends a new message (with user-controlled frequency preferences)  
**Frequency**: Configurable per user (immediately, daily digest, or disabled)  
**Example Content**:
```
Subject: New message from [Partner Name]

Hi [User Name],

[Partner Name] has sent you a new message in your conversation "[Conversation Topic]"

View and respond: [Link to conversation]

You can manage your notification preferences at any time in your profile settings.

Unsubscribe from notifications: [Unsubscribe Link]
```

### 3. Account Verification Email
**Trigger**: User registration  
**Frequency**: Once per user account  
**Example Content**:
```
Subject: Verify your We Coach account

Hi [User Name],

Welcome to We Coach! Please verify your email address to complete your registration.

Verify your email: [Verification Link - expires in 24 hours]

If you didn't create this account, you can safely ignore this email.
```

### 4. Password Reset Email
**Trigger**: User requests password reset  
**Frequency**: On-demand (rate-limited to prevent abuse)  
**Example Content**:
```
Subject: Reset your We Coach password

Hi [User Name],

You requested a password reset for your We Coach account.

Reset your password: [Reset Link - expires in 1 hour]

If you didn't request this, please ignore this email. Your password will remain unchanged.
```

---

## Recipient List Management

### How We Build Our Lists
- **Opt-In Only**: All users explicitly create accounts and verify their email addresses
- **Partner Invitations**: Users can only invite one partner at a time (couples platform)
- **No Purchased Lists**: We never use purchased, rented, or third-party email lists
- **Double Opt-In**: Email verification required before any account activation

### List Maintenance
- **Regular Cleanup**: Unverified accounts deleted after 30 days
- **Inactive Users**: Accounts inactive for 12+ months are archived and removed from mailing lists
- **Invalid Emails**: Automatically removed upon bounce detection
- **Database Validation**: Email format validation at registration

---

## Bounce Management

### Hard Bounces
- **Automatic Removal**: Hard bounce emails are immediately flagged and removed from our database
- **SNS Integration**: We have configured SNS topics to receive SES bounce notifications
- **Automated Process**: 
  1. SES sends bounce notification to our SNS topic
  2. Backend Lambda/API endpoint processes the notification
  3. Email marked as invalid in DynamoDB
  4. User notified to update their email address
  5. Future emails to that address blocked

### Soft Bounces
- **Retry Logic**: Soft bounces trigger automatic retries (3 attempts over 24 hours)
- **Conversion Tracking**: If soft bounces persist for 5+ days, treated as hard bounce
- **Monitoring**: Daily review of soft bounce rates

### Implementation
```javascript
// Example bounce handling in our backend
async function handleBounce(bounceNotification) {
  const email = bounceNotification.mail.destination[0];
  const bounceType = bounceNotification.bounce.bounceType;
  
  if (bounceType === 'Permanent') {
    // Hard bounce - remove immediately
    await markEmailAsInvalid(email);
    await notifyUserToUpdateEmail(email);
  } else if (bounceType === 'Transient') {
    // Soft bounce - track and retry
    await incrementBounceCounter(email);
  }
}
```

---

## Complaint Management

### Complaint Handling Process
1. **SNS Notifications**: SES complaint notifications sent to our SNS topic
2. **Immediate Action**: User automatically unsubscribed from all non-essential emails
3. **Database Update**: Complaint flag added to user record
4. **Review Process**: Manual review of complaint to identify issues
5. **Content Improvement**: Adjust email content if patterns emerge

### Complaint Prevention
- **Clear Unsubscribe**: Every notification email includes prominent unsubscribe link
- **Frequency Controls**: Users control notification frequency (immediate, daily, off)
- **Relevant Content**: Only transactional emails related to user activity
- **Quality Standards**: Professional, clear, concise email content
- **No Spam Tactics**: No misleading subject lines or deceptive content

### Target Metrics
- **Complaint Rate**: < 0.1% (industry best practice)
- **Current Rate**: 0% (new application)
- **Monitoring**: Daily complaint rate tracking via CloudWatch

---

## Unsubscribe Management

### User Control
- **Preference Center**: Users can manage notification preferences in their profile
- **Granular Options**:
  - Partner invitation emails: Cannot disable (essential for platform function)
  - New message notifications: Can disable or set to daily digest
  - Account security emails: Cannot disable (password resets, verification)
  
### Unsubscribe Process
1. **One-Click**: All notification emails include unsubscribe link in footer
2. **Immediate Processing**: Unsubscribe requests processed in real-time
3. **Confirmation**: User shown confirmation page after unsubscribing
4. **Database Update**: Preference stored in DynamoDB immediately
5. **Honoring Requests**: All future emails respect unsubscribe status (except critical security emails)

### Implementation Example
```
Email Footer:
---
You're receiving this because you have an active We Coach account.
Manage your notification preferences: [Settings Link]
Unsubscribe from notifications: [One-Click Unsubscribe]

We Coach | Privacy Policy | Support
```

---

## Email Quality Assurance

### Content Standards
- **Professional Tone**: All emails professionally written and reviewed
- **Clear Purpose**: Subject lines accurately reflect email content
- **No Misleading Content**: No clickbait, no deceptive practices
- **Mobile Optimized**: All emails tested on mobile devices
- **Plain Text Alternative**: HTML emails include plain text version

### Technical Implementation
- **SPF Record**: Configured for our domain
- **DKIM Signing**: All emails DKIM signed by SES
- **DMARC Policy**: Will implement after domain verification
- **Return-Path**: Properly configured for bounce handling
- **List-Unsubscribe Header**: Included in all notification emails

### Testing Process
- **Staging Environment**: All emails tested before production deployment
- **Spam Score Testing**: Run through spam checkers before sending
- **Deliverability Monitoring**: Track open rates and engagement metrics

---

## Domain Verification Status

**Current Status**: Using verified email address (camille.vienot@gmail.com)  
**Next Step**: Will verify domain once production access is granted

**Planned Domain Verification**:
- Domain: wecounsel.ai (or similar - to be purchased)
- Will configure DNS records (DKIM, SPF, DMARC) upon domain purchase
- Plan to complete domain verification within 48 hours of production access approval

**Question**: Should we complete domain verification before production access, or can we proceed with verified email address initially and add domain verification afterward?

---

## Infrastructure and Monitoring

### AWS Services Used
- **SES**: Email sending
- **SNS**: Bounce/complaint notifications
- **DynamoDB**: User and email preference storage
- **CloudWatch**: Metrics and monitoring
- **App Runner**: Backend API hosting
- **Secrets Manager**: SMTP credentials (if needed)

### Monitoring and Alerting
- **Bounce Rate**: CloudWatch alarm if > 5%
- **Complaint Rate**: CloudWatch alarm if > 0.1%
- **Send Errors**: Immediate notification to dev team
- **Daily Reports**: Email sending metrics reviewed daily

### Compliance
- **GDPR**: User data stored securely, deletion requests honored
- **CAN-SPAM**: All emails include physical address and unsubscribe
- **Privacy**: Clear privacy policy explaining email usage

---

## Sending Limits Request

**Current Sandbox Limits**: 200 emails/day, 1 email/second  
**Requested Limits**: 10,000 emails/day, 10 emails/second

**Justification**: 
- Initial user base: ~200-300 couples (400-600 users)
- Expected email volume: 100-500/day initially
- Buffer for growth: Planning for 1,000+ couples within 6 months
- Requesting headroom to avoid service disruption during growth

---

## Additional Information

### Reputation Management
- **Warm-Up Plan**: Will gradually increase sending volume over first 2 weeks
- **Engagement Tracking**: Monitor open rates and user engagement
- **Feedback Loop**: User feedback form for email preferences and issues

### Support Contact
- **Primary Contact**: camille.vienot@gmail.com
- **Response Time**: Monitoring support case daily
- **Availability**: Can provide additional information within 24 hours

---

## Summary

We Coach is a legitimate couples coaching platform sending only transactional emails to opted-in users. We have:

✅ Clear use case (couples communication platform)  
✅ Defined email types (invitations, notifications, account management)  
✅ Robust bounce/complaint handling (automated SNS processing)  
✅ User-controlled preferences (unsubscribe and frequency options)  
✅ Quality content (professional, clear, relevant)  
✅ Monitoring infrastructure (CloudWatch, daily metrics)  
✅ Compliance measures (GDPR, CAN-SPAM)  

We are committed to maintaining email best practices and high deliverability standards. We will verify our domain immediately upon production access approval.

**Next Steps We're Ready For**:
1. Verify domain (need guidance on timing)
2. Configure SNS bounce/complaint topics (can do now)
3. Implement warm-up sending schedule
4. Monitor metrics daily

Please let us know if you need any additional information or clarification.

Thank you for reviewing our request.

Best regards,
Camille Vienot
We Coach
