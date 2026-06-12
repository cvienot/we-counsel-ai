#!/usr/bin/env node

require('dotenv').config({ quiet: true });

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const GOOGLE_OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const GOOGLE_ADS_ENDPOINT = 'https://googleads.googleapis.com';
const SEARCH_CONSOLE_ENDPOINT = 'https://searchconsole.googleapis.com';
const PAGESPEED_ENDPOINT = 'https://www.googleapis.com/pagespeedonline/v5/runPagespeed';

const args = process.argv.slice(2);
const [scope, command, ...commandArgs] = args;

function parseOptions(rawArgs) {
  const options = {};

  for (let i = 0; i < rawArgs.length; i += 1) {
    const arg = rawArgs[i];
    if (!arg.startsWith('--')) continue;

    const [rawKey, inlineValue] = arg.slice(2).split(/=(.*)/s, 2);
    const key = rawKey.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());

    if (inlineValue != null) {
      options[key] = inlineValue;
    } else if (rawArgs[i + 1] && !rawArgs[i + 1].startsWith('--')) {
      options[key] = rawArgs[i + 1];
      i += 1;
    } else {
      options[key] = true;
    }
  }

  return options;
}

const options = parseOptions(commandArgs);

function showHelp() {
  console.log(`
Usage:
  node scripts/marketing-cli.js ads campaigns [--days=7] [--limit=20] [--json]
  node scripts/marketing-cli.js ads search-terms [--days=7] [--limit=50] [--json]
  node scripts/marketing-cli.js ads keywords [--days=7] [--limit=50] [--json]
  node scripts/marketing-cli.js ads query --gaql="SELECT ..." [--json]

  node scripts/marketing-cli.js seo gsc [--days=28] [--dimensions=query,page] [--limit=50] [--json]
  node scripts/marketing-cli.js seo inspect --url=https://we-connect-app.com/fr/
  node scripts/marketing-cli.js seo sitemaps
  node scripts/marketing-cli.js seo submit-sitemap --sitemap=https://we-connect-app.com/sitemap.xml [--yes]
  node scripts/marketing-cli.js seo pagespeed --url=https://we-connect-app.com/fr/ [--strategy=mobile] [--api-key=...]

Required for Google Ads:
  GOOGLE_ADS_DEVELOPER_TOKEN
  GOOGLE_ADS_CUSTOMER_ID
  GOOGLE_ADS_LOGIN_CUSTOMER_ID     Optional manager account ID

Required for Search Console:
  GOOGLE_SEARCH_CONSOLE_SITE_URL   Defaults to https://we-connect-app.com/

Auth options, checked in this order:
  GOOGLE_ACCESS_TOKEN
  GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET + GOOGLE_REFRESH_TOKEN
  GOOGLE_ADS_CLIENT_ID + GOOGLE_ADS_CLIENT_SECRET + GOOGLE_ADS_REFRESH_TOKEN
  GOOGLE_SEARCH_CONSOLE_CLIENT_ID + GOOGLE_SEARCH_CONSOLE_CLIENT_SECRET + GOOGLE_SEARCH_CONSOLE_REFRESH_TOKEN
  gcloud auth application-default print-access-token
  gcloud auth print-access-token
`);
}

function hasFlag(name) {
  return options[name] === true;
}

function getStringOption(name, fallback) {
  const value = options[name];
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function getNumberOption(name, fallback) {
  const value = Number(options[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} must be set.`);
  }
  return value;
}

function adcQuotaProject() {
  try {
    const adcPath = path.join(os.homedir(), '.config/gcloud/application_default_credentials.json');
    const adc = JSON.parse(fs.readFileSync(adcPath, 'utf8'));
    return adc.quota_project_id || null;
  } catch {
    return null;
  }
}

function googleQuotaProject() {
  return process.env.GOOGLE_CLOUD_QUOTA_PROJECT || process.env.GOOGLE_QUOTA_PROJECT || adcQuotaProject();
}

function cleanCustomerId(value) {
  return String(value || '').replace(/-/g, '').trim();
}

function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

function dateWindow(days) {
  const end = new Date();
  const start = new Date();
  start.setDate(end.getDate() - days + 1);
  return {
    startDate: formatDate(start),
    endDate: formatDate(end)
  };
}

function parseCsv(value, fallback) {
  if (!value) return fallback;
  const items = String(value)
    .split(',')
    .map(item => item.trim())
    .filter(Boolean);
  return items.length ? items : fallback;
}

function microsToCurrency(micros) {
  const value = Number(micros || 0) / 1000000;
  return value.toLocaleString('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 2
  });
}

function percent(value) {
  const numeric = Number(value || 0);
  return `${(numeric * 100).toFixed(2)}%`;
}

function number(value, digits = 2) {
  const numeric = Number(value || 0);
  return numeric.toLocaleString('fr-FR', { maximumFractionDigits: digits });
}

function truncate(value, maxLength = 54) {
  const text = value == null ? '' : String(value);
  return text.length > maxLength ? `${text.slice(0, maxLength - 3)}...` : text;
}

function printJson(value) {
  console.log(JSON.stringify(value, null, 2));
}

function printTable(rows, columns) {
  if (!rows.length) {
    console.log('No rows.');
    return;
  }

  const widths = columns.map(column => {
    const values = rows.map(row => String(column.format ? column.format(row[column.key], row) : row[column.key] ?? ''));
    return Math.min(
      column.maxWidth || 60,
      Math.max(column.label.length, ...values.map(value => value.length))
    );
  });

  const renderCell = (value, width) => truncate(value, width).padEnd(width);
  const header = columns.map((column, index) => renderCell(column.label, widths[index])).join('  ');
  const separator = widths.map(width => '-'.repeat(width)).join('  ');

  console.log(header);
  console.log(separator);

  for (const row of rows) {
    console.log(
      columns
        .map((column, index) => {
          const value = column.format ? column.format(row[column.key], row) : row[column.key] ?? '';
          return renderCell(value, widths[index]);
        })
        .join('  ')
    );
  }
}

async function fetchJson(url, { method = 'GET', headers = {}, body, expected = [200] } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Accept: 'application/json',
      ...headers
    },
    body: body == null ? undefined : JSON.stringify(body)
  });

  const text = await response.text();
  let payload = null;

  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = text;
    }
  }

  if (!expected.includes(response.status)) {
    const detail = typeof payload === 'string' ? payload : JSON.stringify(payload, null, 2);
    throw new Error(`HTTP ${response.status} from ${url}\n${detail}`);
  }

  return payload;
}

async function refreshAccessToken(prefix) {
  const clientId = process.env[`${prefix}_CLIENT_ID`] || process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env[`${prefix}_CLIENT_SECRET`] || process.env.GOOGLE_CLIENT_SECRET;
  const refreshToken = process.env[`${prefix}_REFRESH_TOKEN`] || process.env.GOOGLE_REFRESH_TOKEN;

  if (!clientId || !clientSecret || !refreshToken) return null;

  const response = await fetch(GOOGLE_OAUTH_TOKEN_URL, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token'
    })
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(`Could not refresh Google OAuth token: ${JSON.stringify(payload, null, 2)}`);
  }

  return payload.access_token;
}

function tokenFromGcloud(argsForToken) {
  try {
    return execFileSync('gcloud', argsForToken, {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    }).trim();
  } catch {
    return null;
  }
}

async function getGoogleAccessToken(prefix) {
  if (process.env.GOOGLE_ACCESS_TOKEN) return process.env.GOOGLE_ACCESS_TOKEN;

  const refreshed = await refreshAccessToken(prefix);
  if (refreshed) return refreshed;

  const adcToken = tokenFromGcloud(['auth', 'application-default', 'print-access-token']);
  if (adcToken) return adcToken;

  const userToken = tokenFromGcloud(['auth', 'print-access-token']);
  if (userToken) return userToken;

  throw new Error(
    'No Google access token available. Set GOOGLE_ACCESS_TOKEN, configure OAuth refresh-token env vars, or run gcloud auth.'
  );
}

function googleAdsConfig() {
  const customerId = cleanCustomerId(requiredEnv('GOOGLE_ADS_CUSTOMER_ID'));
  const loginCustomerId = cleanCustomerId(process.env.GOOGLE_ADS_LOGIN_CUSTOMER_ID);
  const developerToken = requiredEnv('GOOGLE_ADS_DEVELOPER_TOKEN');
  const apiVersion = process.env.GOOGLE_ADS_API_VERSION || 'v24';

  return {
    apiVersion,
    customerId,
    developerToken,
    loginCustomerId
  };
}

async function googleAdsSearch(gaql) {
  const config = googleAdsConfig();
  const token = await getGoogleAccessToken('GOOGLE_ADS');
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
    'developer-token': config.developerToken
  };

  if (config.loginCustomerId) {
    headers['login-customer-id'] = config.loginCustomerId;
  }

  const payload = await fetchJson(
    `${GOOGLE_ADS_ENDPOINT}/${config.apiVersion}/customers/${config.customerId}/googleAds:searchStream`,
    {
      method: 'POST',
      headers,
      body: { query: gaql }
    }
  );

  if (!Array.isArray(payload)) return [];
  return payload.flatMap(chunk => chunk.results || []);
}

function campaignRows(results) {
  return results.map(result => ({
    campaign: result.campaign?.name,
    status: result.campaign?.status,
    channel: result.campaign?.advertisingChannelType,
    impressions: Number(result.metrics?.impressions || 0),
    clicks: Number(result.metrics?.clicks || 0),
    cost: Number(result.metrics?.costMicros || 0),
    ctr: Number(result.metrics?.ctr || 0),
    avgCpc: Number(result.metrics?.averageCpc || 0),
    conversions: Number(result.metrics?.conversions || 0),
    costPerConversion: Number(result.metrics?.costPerConversion || 0)
  }));
}

function searchTermRows(results) {
  return results.map(result => ({
    campaign: result.campaign?.name,
    adGroup: result.adGroup?.name,
    searchTerm: result.searchTermView?.searchTerm,
    impressions: Number(result.metrics?.impressions || 0),
    clicks: Number(result.metrics?.clicks || 0),
    cost: Number(result.metrics?.costMicros || 0),
    conversions: Number(result.metrics?.conversions || 0)
  }));
}

function keywordRows(results) {
  return results.map(result => ({
    campaign: result.campaign?.name,
    adGroup: result.adGroup?.name,
    keyword: result.adGroupCriterion?.keyword?.text,
    matchType: result.adGroupCriterion?.keyword?.matchType,
    status: result.adGroupCriterion?.status,
    impressions: Number(result.metrics?.impressions || 0),
    clicks: Number(result.metrics?.clicks || 0),
    cost: Number(result.metrics?.costMicros || 0),
    conversions: Number(result.metrics?.conversions || 0)
  }));
}

async function runAdsCommand() {
  const days = getNumberOption('days', 7);
  const limit = Math.min(getNumberOption('limit', command === 'campaigns' ? 20 : 50), 1000);
  const { startDate, endDate } = dateWindow(days);

  if (command === 'query') {
    const gaql = getStringOption('gaql');
    if (!gaql) throw new Error('--gaql is required for ads query.');
    const results = await googleAdsSearch(gaql);
    printJson(results);
    return;
  }

  if (command === 'campaigns' || command === 'report') {
    const results = await googleAdsSearch(`
      SELECT
        campaign.id,
        campaign.name,
        campaign.status,
        campaign.advertising_channel_type,
        metrics.impressions,
        metrics.clicks,
        metrics.cost_micros,
        metrics.ctr,
        metrics.average_cpc,
        metrics.conversions,
        metrics.cost_per_conversion
      FROM campaign
      WHERE segments.date BETWEEN '${startDate}' AND '${endDate}'
      ORDER BY metrics.clicks DESC
      LIMIT ${limit}
    `);
    const rows = campaignRows(results);
    if (hasFlag('json')) return printJson(rows);
    printTable(rows, [
      { key: 'campaign', label: 'Campaign', maxWidth: 42 },
      { key: 'status', label: 'Status' },
      { key: 'channel', label: 'Channel' },
      { key: 'impressions', label: 'Impr.', format: value => number(value, 0) },
      { key: 'clicks', label: 'Clicks', format: value => number(value, 0) },
      { key: 'cost', label: 'Cost', format: microsToCurrency },
      { key: 'ctr', label: 'CTR', format: percent },
      { key: 'avgCpc', label: 'Avg CPC', format: microsToCurrency },
      { key: 'conversions', label: 'Conv.', format: value => number(value, 2) }
    ]);
    return;
  }

  if (command === 'search-terms') {
    const results = await googleAdsSearch(`
      SELECT
        campaign.name,
        ad_group.name,
        search_term_view.search_term,
        metrics.impressions,
        metrics.clicks,
        metrics.cost_micros,
        metrics.conversions
      FROM search_term_view
      WHERE segments.date BETWEEN '${startDate}' AND '${endDate}'
        AND metrics.impressions > 0
      ORDER BY metrics.impressions DESC
      LIMIT ${limit}
    `);
    const rows = searchTermRows(results);
    if (hasFlag('json')) return printJson(rows);
    printTable(rows, [
      { key: 'searchTerm', label: 'Search term', maxWidth: 46 },
      { key: 'campaign', label: 'Campaign', maxWidth: 32 },
      { key: 'impressions', label: 'Impr.', format: value => number(value, 0) },
      { key: 'clicks', label: 'Clicks', format: value => number(value, 0) },
      { key: 'cost', label: 'Cost', format: microsToCurrency },
      { key: 'conversions', label: 'Conv.', format: value => number(value, 2) }
    ]);
    return;
  }

  if (command === 'keywords') {
    const results = await googleAdsSearch(`
      SELECT
        campaign.name,
        ad_group.name,
        ad_group_criterion.keyword.text,
        ad_group_criterion.keyword.match_type,
        ad_group_criterion.status,
        metrics.impressions,
        metrics.clicks,
        metrics.cost_micros,
        metrics.conversions
      FROM keyword_view
      WHERE segments.date BETWEEN '${startDate}' AND '${endDate}'
        AND ad_group_criterion.type = KEYWORD
      ORDER BY metrics.clicks DESC
      LIMIT ${limit}
    `);
    const rows = keywordRows(results);
    if (hasFlag('json')) return printJson(rows);
    printTable(rows, [
      { key: 'keyword', label: 'Keyword', maxWidth: 42 },
      { key: 'matchType', label: 'Match' },
      { key: 'status', label: 'Status' },
      { key: 'impressions', label: 'Impr.', format: value => number(value, 0) },
      { key: 'clicks', label: 'Clicks', format: value => number(value, 0) },
      { key: 'cost', label: 'Cost', format: microsToCurrency },
      { key: 'conversions', label: 'Conv.', format: value => number(value, 2) }
    ]);
    return;
  }

  throw new Error(`Unknown ads command: ${command || '(missing)'}`);
}

function searchConsoleSiteUrl() {
  return getStringOption('site', process.env.GOOGLE_SEARCH_CONSOLE_SITE_URL || 'https://we-connect-app.com/');
}

async function searchConsoleRequest(path, { method = 'GET', body, expected = [200] } = {}) {
  const token = await getGoogleAccessToken('GOOGLE_SEARCH_CONSOLE');
  const quotaProject = googleQuotaProject();
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  if (quotaProject) {
    headers['x-goog-user-project'] = quotaProject;
  }

  return fetchJson(`${SEARCH_CONSOLE_ENDPOINT}${path}`, {
    method,
    headers,
    body,
    expected
  });
}

async function runSearchAnalytics() {
  const days = getNumberOption('days', 28);
  const limit = Math.min(getNumberOption('limit', 50), 25000);
  const { startDate, endDate } = dateWindow(days);
  const dimensions = parseCsv(getStringOption('dimensions'), ['query', 'page']);
  const siteUrl = searchConsoleSiteUrl();
  const body = {
    startDate,
    endDate,
    dimensions,
    rowLimit: limit,
    startRow: 0
  };

  if (options.page) {
    body.dimensionFilterGroups = [
      {
        filters: [
          {
            dimension: 'page',
            operator: 'equals',
            expression: String(options.page)
          }
        ]
      }
    ];
  }

  const payload = await searchConsoleRequest(
    `/webmasters/v3/sites/${encodeURIComponent(siteUrl)}/searchAnalytics/query`,
    {
      method: 'POST',
      body
    }
  );

  const rows = (payload.rows || []).map(row => {
    const result = {
      clicks: Number(row.clicks || 0),
      impressions: Number(row.impressions || 0),
      ctr: Number(row.ctr || 0),
      position: Number(row.position || 0)
    };
    dimensions.forEach((dimension, index) => {
      result[dimension] = row.keys?.[index] || '';
    });
    return result;
  });

  if (hasFlag('json')) return printJson(rows);

  printTable(rows, [
    ...dimensions.map(dimension => ({
      key: dimension,
      label: dimension,
      maxWidth: dimension === 'page' ? 58 : 36
    })),
    { key: 'clicks', label: 'Clicks', format: value => number(value, 0) },
    { key: 'impressions', label: 'Impr.', format: value => number(value, 0) },
    { key: 'ctr', label: 'CTR', format: percent },
    { key: 'position', label: 'Pos.', format: value => number(value, 1) }
  ]);
}

async function runUrlInspection() {
  const url = getStringOption('url');
  if (!url) throw new Error('--url is required for seo inspect.');

  const siteUrl = searchConsoleSiteUrl();
  const payload = await searchConsoleRequest('/v1/urlInspection/index:inspect', {
    method: 'POST',
    body: {
      inspectionUrl: url,
      siteUrl,
      languageCode: 'fr-FR'
    }
  });

  if (hasFlag('json')) return printJson(payload);

  const index = payload.inspectionResult?.indexStatusResult || {};
  const mobile = payload.inspectionResult?.mobileUsabilityResult || {};

  printTable(
    [
      {
        url,
        verdict: index.verdict || '',
        coverage: index.coverageState || '',
        indexingState: index.indexingState || '',
        robotsTxtState: index.robotsTxtState || '',
        pageFetchState: index.pageFetchState || '',
        mobile: mobile.verdict || ''
      }
    ],
    [
      { key: 'url', label: 'URL', maxWidth: 62 },
      { key: 'verdict', label: 'Verdict' },
      { key: 'coverage', label: 'Coverage', maxWidth: 44 },
      { key: 'indexingState', label: 'Indexing' },
      { key: 'robotsTxtState', label: 'Robots' },
      { key: 'pageFetchState', label: 'Fetch' },
      { key: 'mobile', label: 'Mobile' }
    ]
  );
}

async function runSitemapsList() {
  const siteUrl = searchConsoleSiteUrl();
  const payload = await searchConsoleRequest(`/webmasters/v3/sites/${encodeURIComponent(siteUrl)}/sitemaps`);
  const rows = (payload.sitemap || []).map(sitemap => ({
    path: sitemap.path,
    lastSubmitted: sitemap.lastSubmitted,
    lastDownloaded: sitemap.lastDownloaded,
    isPending: sitemap.isPending,
    warnings: sitemap.warnings || 0,
    errors: sitemap.errors || 0
  }));

  if (hasFlag('json')) return printJson(rows);

  printTable(rows, [
    { key: 'path', label: 'Sitemap', maxWidth: 58 },
    { key: 'lastSubmitted', label: 'Submitted' },
    { key: 'lastDownloaded', label: 'Downloaded' },
    { key: 'isPending', label: 'Pending' },
    { key: 'warnings', label: 'Warn.' },
    { key: 'errors', label: 'Errors' }
  ]);
}

async function runSitemapSubmit() {
  const sitemap = getStringOption('sitemap', 'https://we-connect-app.com/sitemap.xml');
  const siteUrl = searchConsoleSiteUrl();

  if (!hasFlag('yes')) {
    console.log(`Dry run: would submit sitemap ${sitemap} for ${siteUrl}.`);
    console.log('Re-run with --yes to submit it to Search Console.');
    return;
  }

  await searchConsoleRequest(
    `/webmasters/v3/sites/${encodeURIComponent(siteUrl)}/sitemaps/${encodeURIComponent(sitemap)}`,
    {
      method: 'PUT',
      expected: [200, 204]
    }
  );
  console.log(`Submitted sitemap ${sitemap} for ${siteUrl}.`);
}

async function runPagespeed() {
  const url = getStringOption('url', 'https://we-connect-app.com/fr/');
  const strategy = getStringOption('strategy', 'mobile');
  const params = new URLSearchParams({
    url,
    strategy,
    category: 'SEO'
  });

  params.append('category', 'PERFORMANCE');
  params.append('category', 'ACCESSIBILITY');
  params.append('category', 'BEST_PRACTICES');

  const apiKey = getStringOption('apiKey', process.env.PAGESPEED_API_KEY);
  if (apiKey) {
    params.set('key', apiKey);
  }

  const payload = await fetchJson(`${PAGESPEED_ENDPOINT}?${params.toString()}`);
  if (hasFlag('json')) return printJson(payload);

  const categories = payload.lighthouseResult?.categories || {};
  const rows = Object.entries(categories).map(([key, category]) => ({
    category: key,
    title: category.title,
    score: Math.round(Number(category.score || 0) * 100)
  }));

  printTable(rows, [
    { key: 'title', label: 'Category' },
    { key: 'score', label: 'Score' }
  ]);
}

async function runSeoCommand() {
  if (command === 'gsc' || command === 'search') return runSearchAnalytics();
  if (command === 'inspect') return runUrlInspection();
  if (command === 'sitemaps') return runSitemapsList();
  if (command === 'submit-sitemap') return runSitemapSubmit();
  if (command === 'pagespeed') return runPagespeed();

  throw new Error(`Unknown seo command: ${command || '(missing)'}`);
}

async function main() {
  if (!scope || scope === 'help' || hasFlag('help')) {
    showHelp();
    return;
  }

  if (scope === 'ads') {
    await runAdsCommand();
    return;
  }

  if (scope === 'seo') {
    await runSeoCommand();
    return;
  }

  throw new Error(`Unknown command scope: ${scope}`);
}

main().catch(error => {
  console.error(error.message);
  process.exit(1);
});
