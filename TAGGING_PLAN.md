# Entrelace Tagging Plan

## Tooling

- Google Analytics 4: one web data stream for product and marketing analytics.
- Google tag: loaded directly from the consent-gated first-party loader with measurement ID `G-V84185KVV0`.
- Google Tag Manager: container `GTM-WBVG3S8M` exists for future tag management, but is not active on the site yet.
- Google Ads: add conversion and remarketing tags later, after ad account setup and after GTM is ready or direct Google Ads tags are reviewed.
- Non-Google pixels: add through `marketing/pixels.js` and `frontend/web/pixels.js` only when the Privacy Policy names the provider.

Do not paste vendor snippets directly into HTML or Flutter views. Add IDs and loaders only through `marketing/pixels.js` and `frontend/web/pixels.js`.

GTM note: a first-party Google tag added to the new GTM container was immediately shown by GTM with a malware-scan pause warning, so the GTM workspace was reset to zero unpublished changes and the container was not published. GA4 is therefore activated directly for now under the same consent rules.

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

GA4 is loaded only after `analytics` consent is granted. Future marketing tags are loaded only after `marketing` consent is granted. Consent updates are pushed before loaders run. Advertising data redaction stays enabled when ad storage is denied.

## PII Rules

Never send these values to analytics or ad platforms:

- Email addresses, names, free-text messages, exercise answers, AI prompts, AI responses, partner identifiers, support content, or authentication tokens.
- Stripe customer IDs, payment method details, or backend user IDs unless a dedicated privacy review approves hashed/pseudonymous IDs.

Allowed event parameters:

- Plan tier, billing cadence, currency, price amount, app language, page path, CTA location, UTM fields, anonymous session/campaign metadata, and non-sensitive outcome labels.

## Core Events

| Event | Where | Trigger | Parameters |
| --- | --- | --- | --- |
| `page_view` | Marketing + app shell | Google tag page view after analytics consent | `page_location`, `page_title`, `page_referrer` |
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

## Current And Future Tag Shape

- GA4 Google tag: fires after analytics consent through the first-party loader.
- GA4 events: direct `gtag` events after analytics consent, with matching `dataLayer` events kept for future GTM mapping.
- Conversion Linker: enable only with marketing consent if GTM is later activated.
- Google Ads conversion tags: add after Google Ads account and conversion actions are configured.
- Remarketing tag: add only after privacy copy explicitly names Google Ads remarketing.

## Implementation Notes

- `marketing/consent.js` and `frontend/web/consent.js` own Consent Mode updates.
- `marketing/pixels.js` and `frontend/web/pixels.js` own GA4, GTM, and future pixel loading.
- Use `window.WeConnectTags.event(name, params)` for browser events.
- Keep e2e coverage that no tracker host loads before consent.
