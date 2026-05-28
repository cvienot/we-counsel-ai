# We Connect Tagging Plan

## Tooling

- Google Tag Manager: one web container for `we-connect-app.com` and `app.we-connect-app.com`.
- Google Analytics 4: one web data stream for product and marketing analytics.
- Google Ads: add conversion and remarketing tags later in the same GTM container, after ad account setup.
- Non-Google pixels: add through `marketing/pixels.js` and `frontend/web/pixels.js` only when the Privacy Policy names the provider.

Use GTM as the single browser tag entry point. Do not paste vendor snippets directly into HTML or Flutter views.

## Consent Model

The site uses a first-party consent manager with two optional categories:

- `analytics`: enables GA4 measurement and product analytics.
- `marketing`: enables Google Ads, remarketing, conversion linker, and advertising pixels.

Default state before user choice:

- `analytics_storage`: denied
- `ad_storage`: denied
- `ad_user_data`: denied
- `ad_personalization`: denied
- `functionality_storage`: granted
- `security_storage`: granted

Google tags are loaded only after either `analytics` or `marketing` consent is granted. Consent updates are pushed before loaders run. Advertising data redaction stays enabled when ad storage is denied.

## PII Rules

Never send these values to analytics or ad platforms:

- Email addresses, names, free-text messages, exercise answers, AI prompts, AI responses, partner identifiers, support content, or authentication tokens.
- Stripe customer IDs, payment method details, or backend user IDs unless a dedicated privacy review approves hashed/pseudonymous IDs.

Allowed event parameters:

- Plan tier, billing cadence, currency, price amount, app language, page path, CTA location, UTM fields, anonymous session/campaign metadata, and non-sensitive outcome labels.

## Core Events

| Event | Where | Trigger | Parameters |
| --- | --- | --- | --- |
| `page_view` | Marketing + app shell | GA4 enhanced measurement or GTM history trigger | `page_location`, `page_title`, `page_referrer` |
| `cta_click` | Marketing | User clicks Open App, pricing CTA, or footer CTA | `cta_location`, `cta_label`, `target_path` |
| `app_open` | App shell | Flutter web app loaded | `language`, `entry_path` |
| `sign_up_start` | App | Registration screen shown from an anonymous session | `source`, `language` |
| `sign_up_complete` | App/backend success | Account creation succeeds | `method`, `language` |
| `invite_partner_start` | App | Invite flow opens | `source` |
| `invite_partner_sent` | App/backend success | Partner invitation succeeds | `method` |
| `subscription_checkout_start` | App/backend success | Stripe Checkout session is created | `plan_tier`, `billing_period`, `currency`, `value` |
| `subscription_purchase` | Stripe success page or webhook-confirmed success | Paid subscription succeeds | `plan_tier`, `billing_period`, `currency`, `value` |
| `exercise_start` | App | User starts a guided exercise | `exercise_type`, `source` |
| `exercise_complete` | App | Guided exercise is completed | `exercise_type`, `duration_bucket` |

## Marketing Conversions

Start with these conversion goals:

- Primary: `subscription_purchase`
- Secondary: `sign_up_complete`
- Secondary: `subscription_checkout_start`

Do not optimize ad campaigns on relationship content, free-text behavior, or sensitive in-app conversation events.

## GTM Container Shape

- Consent Initialization tag: no vendor network call; consent state is set by the first-party banner before GTM loads.
- GA4 Google tag: fires on all pages with built-in consent checks.
- GA4 event tags: map the core events above from `dataLayer` events.
- Conversion Linker: enabled only with marketing consent.
- Google Ads conversion tags: add after Google Ads account and conversion actions are configured.
- Remarketing tag: add only after privacy copy explicitly names Google Ads remarketing.

## Implementation Notes

- `marketing/consent.js` and `frontend/web/consent.js` own Consent Mode updates.
- `marketing/pixels.js` and `frontend/web/pixels.js` own GTM and future pixel loading.
- Use `window.WeConnectTags.event(name, params)` for browser events.
- Keep e2e coverage that no tracker host loads before consent.
