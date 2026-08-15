# Entrelace Production Launch Checklist

Created: 2026-05-06

Repo audited: `/Users/c.vienot/projects/we-counsel-reboot`

Assumption: this is the `we-connect-app` production repo because it contains the Entrelace marketing site, `entrelace.app` domains, App Runner backend config, Amplify frontend config, Stripe payment code, and launch/legal docs.

This is not legal advice. The legal/privacy section should be reviewed by counsel before public launch, especially because the product handles relationship and mental-health-adjacent content.

## Blockers

- [x] Resolve the privacy/legal mismatch before sending traffic.
  - Added standalone privacy policy content in `PRIVACY_POLICY.md` and localized app assets under `frontend/assets/privacy/`.
  - Added public app routes `/terms` and `/privacy`.
  - Updated the marketing footer so Privacy Policy points to `https://app.entrelace.app/privacy`.
  - Aligned user-facing launch surfaces from "We Coach" to "Entrelace".

- [x] Confirm governing law and venue before public launch.
  - Terms now use French law with consumer-safe jurisdiction wording and no mandatory consumer arbitration.
  - Updated section 11 and consumer mediation wording in `TERMS_OF_SERVICE.md` and all localized files under `frontend/assets/terms/`.
  - Legal counsel review is still recommended before scaling paid traffic.

- [x] Fix or substantiate the marketing encryption claim.
  - Updated `marketing/index.html` and `marketing/i18n.js` to avoid message-level or end-to-end encryption claims.
  - Current wording references HTTPS in transit, secure cloud storage, access controls, and not selling personal data.

- [x] Do not extract or paste live Stripe secrets into the repo, tests, chat, screenshots, or markdown.
  - Live `sk_live_*`, `rk_live_*`, and `whsec_*` values belong in AWS Secrets Manager or an equivalent secret store.
  - Test setup must keep using test keys or `MOCK_STRIPE=true`; production setup must use live keys.
  - For live smoke testing, use a real low-value payment and refund it; do not treat live Stripe keys as test fixtures.

- [x] Wire Stripe live credentials through production secrets before launch.
  - `backend/src/config/secrets.js` loads `we-counsel/application/secrets` in production.
  - Production validation now requires `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ESSENTIAL_MONTHLY`, `STRIPE_PRICE_ESSENTIAL_ANNUAL`, `STRIPE_PRICE_PREMIUM_MONTHLY`, and `STRIPE_PRICE_PREMIUM_ANNUAL`.
  - `backend/cloudformation-secrets.yaml` and `backend/deploy-secrets.sh` now collect and store Stripe live configuration in Secrets Manager.
  - `backend/apprunner.yaml` keeps only non-sensitive config.

- [x] Disable launch-only unsafe settings.
  - Production startup now rejects `ENABLE_TEST_ENDPOINTS=true`, `MOCK_STRIPE=true`, `MOCK_EMAIL=true`, `MOCK_AI=true`, `USE_MOCK_EMAIL=true`, and `USE_MOCK_AI=true`.
  - Production startup now rejects missing or localhost `FRONTEND_URL`.
  - Production startup now validates live Stripe key, webhook secret, and price ID formats.
  - Production CORS now uses only `FRONTEND_URL`; localhost origins are kept for non-production only.

## Stripe Live Readiness

- [ ] Use Playwright/Stripe Dashboard only for visual verification and non-secret configuration checks.
  - Safe to inspect: account live status, business profile, payout status, products, prices, webhook endpoint URL, enabled events, customer portal settings, tax settings, branding, logs, webhook delivery status.
  - Do not reveal or copy secret key values through Playwright output. If a live key must be created, the account owner should paste it directly into AWS Secrets Manager.

- [ ] Verify Stripe account live readiness.
  - Account activated for live payments.
  - Business profile, public descriptor, support email, support URL, and payout bank account configured.
  - Customer emails/receipts configured as desired.
  - Branding and checkout domain look production-ready.
  - Tax/VAT behavior decided for EU customers.

- [ ] Recreate required Products and Prices in live mode.
  - `essential_monthly` -> `STRIPE_PRICE_ESSENTIAL_MONTHLY`.
  - `essential_annual` -> `STRIPE_PRICE_ESSENTIAL_ANNUAL`.
  - `premium_monthly` -> `STRIPE_PRICE_PREMIUM_MONTHLY`.
  - `premium_annual` -> `STRIPE_PRICE_PREMIUM_ANNUAL`.
  - Confirm live price IDs match the marketing site pricing: Free, Essential EUR 9.99/month or EUR 7.99/month annually, Premium EUR 19.99/month or EUR 15.99/month annually.

- [ ] Configure production webhook endpoint.
  - URL: `https://<production-api-domain>/api/payments/webhook`.
  - Required events for current code: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_succeeded`, `invoice.payment_failed`.
  - Store the live endpoint signing secret as `STRIPE_WEBHOOK_SECRET`.
  - Confirm the endpoint uses HTTPS and receives raw request bodies before JSON parsing. Current `backend/src/server.js` does this for `/api/payments/webhook`.

- [ ] Verify live payment flows end to end.
  - Register a production test account.
  - Connect a partner or create a couple.
  - Start Essential monthly checkout.
  - Complete a real low-value payment if possible; otherwise use the actual configured price and immediately refund/cancel.
  - Confirm webhook updates the couple: `subscriptionTier`, `subscriptionStatus`, `stripeSubscriptionId`, `billingPeriod`, `subscriptionStartDate`, `subscriptionEndDate`.
  - Open Billing Portal and confirm update/cancel flows.
  - Confirm failed payment logs and user experience.

## Monitoring

- [ ] Create one CloudWatch dashboard for launch day.
  - Added `backend/cloudformation-monitoring.yaml` to provision the launch dashboard after App Runner is deployed.
  - Added `backend/deploy-monitoring.sh` to validate App Runner exports/log groups and deploy monitoring.
  - Backend/App Runner: request count, 4xx, 5xx, latency, instance count, CPU, memory.
  - DynamoDB: read/write throttles, consumed capacity, system errors, user errors for all app tables.
  - SES: sends, bounces, complaints, rejects.
  - Stripe webhooks: use application logs plus Stripe Dashboard webhook delivery view.
  - Frontend: add CloudWatch RUM or another browser monitoring tool for page load, JS errors, and failed API calls.

- [ ] Add CloudWatch Logs metric filters and alarms.
  - Monitoring template includes log metric filters for backend server errors, Stripe checkout/webhook/payment failures, missing configuration, message retrieval/summary errors, OpenAI summary/streaming errors, auth 401 spikes, and App Runner service failures.
  - `Server error`
  - `Webhook signature verification failed`
  - `Webhook error`
  - `Failed to create checkout session`
  - `Payment failed`
  - `Missing required configuration`
  - `Error generating summary`
  - `Get messages error`
  - `OpenAI summary error`
  - OpenAI API `429`, `401`, `403`, and `5xx` responses
  - `Authentication failed` or repeated `401` spikes

- [ ] Set up launch alerting before sharing campaign links.
  - Monitoring template creates SNS topic `we-connect-prod-alerts`, email subscription, App Runner alarms, DynamoDB throttle alarms, SES bounce/complaint/reject alarms, and an AWS monthly budget alert.
  - Deployment still requires confirming the SNS email subscription and triggering one test alarm.
  - Create an SNS topic such as `we-connect-prod-alerts`.
  - Subscribe at least one monitored email address; add Slack/PagerDuty later if not available today.
  - Add CloudWatch alarms for App Runner 5xx, high 4xx, high latency, unhealthy service state, CPU/memory saturation, and deployment failures.
  - Add CloudWatch alarms from log metric filters for backend exceptions, Stripe checkout/webhook failures, auth spikes, AI failures, and missing configuration.
  - Add DynamoDB alarms for throttled requests and system errors on all production tables.
  - Add SES alarms or notifications for bounces, complaints, rejects, and sending pauses.
  - Add AWS Budget alarm for unexpected launch spend.
  - Add OpenAI project usage/budget alerting for remaining budget and daily spend spikes.
  - Trigger one test alarm and confirm the alert reaches the launch owner.
  - Document who watches alerts during the first 24 hours and what action to take for payment, signup, messaging, AI, and email failures.

- [ ] Add synthetic checks.
  - Public marketing home page returns 200.
  - App home/sign-in page loads.
  - Backend `/health` returns 200.
  - Optional authenticated canary for login and conversation load using a non-human synthetic account.

- [ ] Decide launch-day alert destinations.
  - Email or Slack target for CloudWatch alarms.
  - Stripe Dashboard notifications for failed payments and webhook failures.
  - AWS Budget alarm for unexpected spend.
  - OpenAI budget/usage alerts to the same monitored inbox or Slack channel.

## Launch Metrics Script

I added a read-only metrics script:

```bash
cd backend
npm run metrics:launch
```

Production usage:

```bash
cd backend
NODE_ENV=production DYNAMODB_REGION=eu-west-3 npm run metrics:launch -- --days=7
```

JSON output:

```bash
cd backend
NODE_ENV=production DYNAMODB_REGION=eu-west-3 npm --silent run metrics:launch -- --days=7 --json
```

Safety notes:

- The script refuses to query remote DynamoDB unless `NODE_ENV=production` is set.
- For local data, set `DYNAMODB_ENDPOINT`.
- The script scans tables, so use it for launch/ops snapshots, not high-frequency analytics.
- It reports aggregate counts only; it does not print user emails or message content.

Metrics currently reported:

- Users: total, new in window, partner/couple linkage, terms acceptance, language split, new users by day.
- Couples: total, active, connected, active paid, subscription tier/status, AI messages used.
- Invitations: total, status split, expired pending.
- Conversations/messages: totals, window counts, sender type, recipient type, daily message volume.
- Subscriptions: tier/status/billing/payment provider splits.
- Exercise sessions: total, window count, status split.

## Campaign Tags

- [ ] Use a consistent UTM taxonomy for every launch link.
  - `utm_source`: `google`, `meta`, `linkedin`, `tiktok`, `reddit`, `newsletter`, `influencer_<name>`, `direct_partner`.
  - `utm_medium`: `cpc`, `paid_social`, `organic_social`, `email`, `referral`, `creator`.
  - `utm_campaign`: `launch_2026_05`.
  - `utm_content`: creative/ad/audience variant, for example `hero_video_v1` or `couples_fr_v2`.
  - `utm_term`: paid-search keyword only.

- [x] Preserve campaign tags across marketing-to-app navigation.
  - `marketing/script.js` appends current `utm_*` query params to app-entry links that point to `https://app.entrelace.app/`.
  - Legal links such as `/terms` and `/privacy` are intentionally left unchanged.

- [x] Store attribution at signup.
  - Added app startup capture for `utm_*` params in `frontend/lib/services/attribution_service.dart`.
  - Registration now sends optional attribution through `frontend/lib/services/api_service.dart` and `frontend/lib/providers/auth_provider.dart`.
  - Backend registration sanitizes and stores `firstTouchUtm`, `lastTouchUtm`, `landingPage`, optional `referrer`, and `campaignCapturedAt`.
  - Privacy policy already discloses marketing attribution when implemented; retention still needs counsel/product confirmation before paid traffic.

- [x] Consent requirement for marketing tags.
  - Added a standalone consent manager to the marketing site and Flutter web shell: `marketing/consent.js` and `frontend/web/consent.js`.
  - Non-essential analytics and advertising/retargeting categories default to off; users can accept all, reject all, customize, and reopen Privacy Settings.
  - Added empty gated pixel loaders in `marketing/pixels.js` and `frontend/web/pixels.js`. Future Meta Pixel, Google Ads, or similar tags must be added there, not directly in HTML.
  - App signup attribution still stores first-party `utm_*` parameters; privacy policy now discloses consent choices, optional pixels, and withdrawal behavior.
  - Before enabling real pixel IDs, update the Privacy Policy with the named providers and verify no vendor script loads before consent.

## Legal And Privacy

- [x] Create a standalone Privacy Policy in English, French, and Spanish, or publish one canonical language with a clear translation plan.
  - Include controller identity, contact email, processed data categories, purpose/legal basis, processors, AI processing, Stripe, OpenAI, AWS, SES, retention, deletion/export rights, international transfers, cookies/analytics, security measures, and complaint rights.

- [x] Request consumer mediation registration for B2C launch.
  - Submitted/processed on 2026-05-06 through La Mediation Professionnelle.
  - Used SIREN `104281621` and Date d'immatriculation au RNE `28/04/2026`.

- [x] Review whether relationship messages and AI coaching content need special handling.
  - The product is not a therapist, but users may disclose sensitive personal data.
  - GDPR still treats encrypted or pseudonymized re-identifiable data as personal data.
  - Privacy policy now warns users not to share unnecessary sensitive information and documents account-active retention plus legal/security/billing exceptions.

- [x] Update Terms of Service.
  - [x] Align "We Coach" vs "Entrelace".
  - [x] Fill governing law and dispute venue.
  - [x] Add paid subscription, renewal, cancellation, refunds, trials, taxes, and chargeback terms.
  - [x] Add clear AI limitations and crisis/emergency disclaimer.
  - [x] Add age gate and account deletion flow references.
  - [x] Add consumer mediation contact details after the mediation contract was signed.

- [x] Confirm consent capture.
  - Registration requires terms acceptance and stores `termsAcceptedAt` and `termsAcceptedVersion`.
  - Current backend uses `1.0.3-<language>` in `backend/src/routes/auth.js`.
  - Registration copy now links to both Terms of Service and Privacy Policy before account creation.
  - Website/app consent manager stores optional analytics and advertising choices locally under `we-connect-consent-v1`.
  - Add a future terms/privacy re-consent mechanism for version changes.

## Production Readiness

- [ ] Run backend and frontend release verification.
  - Backend install and syntax check.
  - DynamoDB schema validation against production tables.
  - Flutter web build with production `API_BASE_URL`.
  - E2E signup, invite, login, messaging, AI response, checkout, portal, cancel, password reset.

- [ ] Confirm data operations.
  - Backup/export plan for DynamoDB.
  - Account deletion process.
  - Data export process.
  - Retention policy for messages, AI summaries, logs, payment metadata, and marketing attribution.

- [ ] Confirm security basics.
  - JWT secret is high entropy and not reused across environments.
  - Rate limiting exists or is added for auth, password reset, AI messages, and invite endpoints.
  - App Runner instance role uses least privilege for DynamoDB, SES, Secrets Manager, and KMS.
  - Production logs do not print message content, tokens, passwords, Stripe secrets, or payment details.
  - Dependency audit reviewed.

- [ ] Confirm operational rollback.
  - Known good backend revision or App Runner deployment to roll back to.
  - Known good frontend/Amplify build to redeploy.
  - Stripe rollback plan: disable live checkout CTA or switch plans to hidden if payment flow fails.
  - Customer support response template for payment, account, and deletion requests.

## AI Model Selection And Cost

Current backend usage in `backend/src/services/aiService.js`:

- Main streaming coach response: `gpt-5.2`.
- Conversation summarization: `gpt-5-mini`.

- [ ] Decide whether to update the launch models before production.
  - Recommended default: keep `gpt-5.2` for launch if the current prompt quality has been tested; avoid a last-minute model behavior change unless there is a clear product issue.
  - Stronger but more expensive option: evaluate `gpt-5.4` or `gpt-5.5` on a fixed set of real conversation examples before switching the coaching path.
  - Cost optimization option: evaluate `gpt-5.4 mini` for the coaching path if quality remains acceptable, and `gpt-5.4 nano` for summarization.
  - Add a weekly OpenAI spend budget and alert before launching paid traffic.

- [ ] Add OpenAI budget and usage controls.
  - Set an OpenAI project monthly budget and a lower launch-week soft threshold.
  - Configure alerts for remaining budget, daily spend spikes, and unusually high token usage per request.
  - Decide the behavior when the OpenAI budget is nearly exhausted: disable AI coach temporarily, downgrade to a cheaper model, or return a graceful "try again later" message.
  - Record baseline token usage per AI coach response and per summary before paid traffic starts.
  - Add internal logging for model, input tokens, output tokens, total tokens, latency, request outcome, and error class, without logging conversation content.

- [ ] Cover AI launch risks beyond budget.
  - Rate limits: alert on OpenAI `429` and add user-friendly retry/backoff behavior.
  - Auth/config: alert on OpenAI `401` or `403`; this probably means a bad key, missing billing, wrong project, or disabled model.
  - Latency: alert if AI response time exceeds an acceptable threshold for streaming startup or total completion.
  - Output safety: verify crisis/self-harm handling, non-therapy disclaimers, and escalation resources on representative examples.
  - Quality regression: keep a small eval set of launch-critical conversations and compare current model vs candidate model before switching.
  - Abuse/spam: add per-user and per-couple AI message rate limits so a single user cannot burn the budget.
  - Fallback UX: if OpenAI is down or quota is exhausted, preserve partner messaging and clearly degrade only AI features.
  - Data privacy: confirm OpenAI data retention/settings match the privacy policy before launch.

| Model | Suggested use | Input / 1M tokens | Cached input / 1M tokens | Output / 1M tokens | Notes |
| --- | --- | ---: | ---: | ---: | --- |
| `gpt-5.5` | Highest-quality coach fallback, complex cases | $5.00 | $0.50 | $30.00 | Latest frontier model; likely too expensive as the default for every message without eval proof. |
| `gpt-5.4` | Higher-quality coach candidate | $2.50 | $0.25 | $15.00 | More recent than `gpt-5.2`; 1.05M context. |
| `gpt-5.2` | Current coach model | $1.75 | $0.175 | $14.00 | Previous frontier model; current production candidate in this repo. |
| `gpt-5.4 mini` | Cost/performance coach candidate | $0.75 | $0.075 | $4.50 | Good model to benchmark for default coaching replies if quality holds. |
| `gpt-5-mini` | Current summarization model | $0.25 | $0.025 | $2.00 | Current summary model; older/cheaper. |
| `gpt-5.4 nano` | Cheap summarization/classification candidate | $0.20 | $0.02 | $1.25 | Better launch candidate than `gpt-5-nano` for cheap summaries. |
| `gpt-5-nano` | Cheapest summary/classification fallback | $0.05 | $0.005 | $0.40 | Cheapest, but older; only use if summary quality is acceptable. |

## References Checked

- Stripe API keys and live-mode key handling: https://docs.stripe.com/keys
- Stripe go-live checklist: https://docs.stripe.com/get-started/checklist/go-live
- Stripe webhooks and live HTTPS/signing secrets: https://docs.stripe.com/webhooks
- AWS CloudWatch monitoring capabilities: https://aws.amazon.com/documentation-overview/cloudwatch/
- European Commission GDPR personal data overview: https://commission.europa.eu/law/law-topic/data-protection/data-protection-explained_en
- European Commission GDPR individual rights overview: https://commission.europa.eu/law/law-topic/data-protection/information-individuals_en
- OpenAI API pricing: https://openai.com/api/pricing/
- OpenAI GPT-5.5 guide: https://developers.openai.com/api/docs/guides/latest-model
