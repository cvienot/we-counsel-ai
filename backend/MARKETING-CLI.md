# Marketing CLI

Small internal CLI for Google Ads reporting and SEO checks.

The Ads commands are read-only. The only SEO command that changes remote state is sitemap submission, and it requires `--yes`.

## Setup

Run commands from `backend/`.

```bash
npm install
```

Auth is resolved in this order:

1. `GOOGLE_ACCESS_TOKEN`
2. OAuth refresh-token env vars
3. `gcloud auth application-default print-access-token`
4. `gcloud auth print-access-token`

When using local Application Default Credentials, Search Console may require a quota project. The CLI reads it from ADC automatically after:

```bash
gcloud auth application-default set-quota-project your-project-id
```

You can also set it explicitly:

```env
GOOGLE_CLOUD_QUOTA_PROJECT=your-project-id
```

For refresh-token auth, set either shared values:

```env
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
```

or service-specific values:

```env
GOOGLE_ADS_CLIENT_ID=...
GOOGLE_ADS_CLIENT_SECRET=...
GOOGLE_ADS_REFRESH_TOKEN=...
GOOGLE_SEARCH_CONSOLE_CLIENT_ID=...
GOOGLE_SEARCH_CONSOLE_CLIENT_SECRET=...
GOOGLE_SEARCH_CONSOLE_REFRESH_TOKEN=...
```

Useful OAuth scopes:

```text
https://www.googleapis.com/auth/adwords
https://www.googleapis.com/auth/webmasters.readonly
https://www.googleapis.com/auth/webmasters
```

Search Console reads can use `webmasters.readonly`; sitemap submission needs `webmasters`.

## Google Ads

Required env:

```env
GOOGLE_ADS_API_VERSION=v24
GOOGLE_ADS_DEVELOPER_TOKEN=...
GOOGLE_ADS_CUSTOMER_ID=...
GOOGLE_ADS_LOGIN_CUSTOMER_ID=...
```

Examples:

```bash
npm run ads:report -- --days=7
npm run ads:campaigns -- --days=30 --json
npm run ads:search-terms -- --days=14 --limit=100
npm run ads:keywords -- --days=14
npm run ads:query -- --gaql="SELECT campaign.name, metrics.clicks FROM campaign LIMIT 10"
```

The customer IDs can be written with or without dashes.

## Search Console

Default site:

```env
GOOGLE_SEARCH_CONSOLE_SITE_URL=https://entrelace.app/
```

Examples:

```bash
npm run seo:gsc -- --days=28 --dimensions=query,page --limit=50
npm run seo:gsc -- --days=28 --dimensions=page --json
npm run seo:inspect -- --url=https://entrelace.app/fr/
npm run seo:sitemaps
npm run seo:submit-sitemap -- --sitemap=https://entrelace.app/sitemap.xml
npm run seo:submit-sitemap -- --sitemap=https://entrelace.app/sitemap.xml --yes
```

`seo:submit-sitemap` is a dry run unless `--yes` is present.

Google does not expose a general Search Console API to request indexing for arbitrary pages. The CLI can inspect URL index status and submit sitemaps; manual re-indexing still belongs in Search Console UI when needed.

## PageSpeed

No OAuth is required. Use `PAGESPEED_API_KEY` or `--api-key=...` if the anonymous/default project quota is exhausted.

```bash
npm run seo:pagespeed -- --url=https://entrelace.app/fr/ --strategy=mobile
npm run seo:pagespeed -- --url=https://entrelace.app/fr/ --strategy=mobile --api-key=...
npm run seo:pagespeed -- --url=https://entrelace.app/fr/ --strategy=desktop --json
```
