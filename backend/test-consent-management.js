const assert = require('assert');
const { spawnSync } = require('child_process');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright-core');

const ROOT_DIR = path.resolve(__dirname, '..');
const TRACKER_HOST_PATTERNS = [
  'googletagmanager.com',
  'google-analytics.com',
  'connect.facebook.net',
  'facebook.net',
  'facebook.com'
];

const MIME_TYPES = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8'
};

function commandPath(command) {
  const result = spawnSync('sh', ['-lc', `command -v ${command}`], {
    encoding: 'utf8'
  });

  return result.status === 0 ? result.stdout.trim() : '';
}

function findChromiumExecutable() {
  if (process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE) {
    return process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE;
  }

  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    commandPath('google-chrome-stable'),
    commandPath('google-chrome'),
    commandPath('chromium'),
    commandPath('chromium-browser')
  ].filter(Boolean);

  return candidates.find(candidate => fs.existsSync(candidate));
}

function startStaticServer(directory) {
  const root = path.resolve(directory);
  const server = http.createServer((req, res) => {
    const requestUrl = new URL(req.url, 'http://127.0.0.1');
    const decodedPath = decodeURIComponent(requestUrl.pathname);
    const relativePath = decodedPath === '/' ? 'index.html' : decodedPath.replace(/^\/+/, '');
    const filePath = path.resolve(root, relativePath);

    if (!filePath.startsWith(root + path.sep) && filePath !== root) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    fs.readFile(filePath, (error, content) => {
      if (error) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Not found');
        return;
      }

      res.writeHead(200, {
        'Cache-Control': 'no-store',
        'Content-Type': MIME_TYPES[path.extname(filePath)] || 'application/octet-stream'
      });
      res.end(content);
    });
  });

  return new Promise(resolve => {
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      resolve({
        close: () => new Promise(done => server.close(done)),
        url: `http://127.0.0.1:${port}`
      });
    });
  });
}

function isTrackerRequest(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch (error) {
    return false;
  }

  return TRACKER_HOST_PATTERNS.some(pattern => parsed.hostname.includes(pattern));
}

function assertNoTrackerRequests(requests, context) {
  const trackerRequests = requests.filter(isTrackerRequest);
  assert.deepStrictEqual(
    trackerRequests,
    [],
    `${context}: tracker requests loaded before consent: ${trackerRequests.join(', ')}`
  );
}

async function waitForConsentReady(page) {
  await page.waitForFunction(() => Boolean(window.WeConnectConsent), null, {
    timeout: 10000
  });
  await page.waitForSelector('#wc-consent-banner', { timeout: 10000 });
  await page.waitForTimeout(250);
}

async function testMarketingConsentFlow(browser, baseUrl) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const requests = [];
  page.on('request', request => requests.push(request.url()));

  await page.goto(`${baseUrl}/?lang=en&utm_source=e2e-consent`, {
    waitUntil: 'domcontentloaded'
  });
  await waitForConsentReady(page);

  assertNoTrackerRequests(requests, 'marketing site');

  const initialConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.deepStrictEqual(initialConsent.categories, {
    necessary: true,
    analytics: false,
    marketing: false
  });
  assert.strictEqual(initialConsent.updatedAt, null);

  await page.evaluate(() => {
    window.__consentTestLoads = 0;
    window.__consentTestCleanups = 0;
    window.WeConnectConsent.register('marketing', () => {
      window.__consentTestLoads += 1;
      return () => {
        window.__consentTestCleanups += 1;
      };
    });
  });
  assert.strictEqual(await page.evaluate(() => window.__consentTestLoads), 0);

  await page.locator('[data-wc-consent="customize"]').click();
  await page.waitForSelector('#wc-consent-overlay');
  await page.evaluate(() => {
    document.querySelector('[data-wc-category="analytics"]').checked = true;
    document.querySelector('[data-wc-category="marketing"]').checked = true;
  });
  await page.locator('#wc-consent-overlay [data-wc-consent="save"]').click();
  await page.waitForSelector('#wc-consent-manage');

  const acceptedConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.strictEqual(acceptedConsent.categories.analytics, true);
  assert.strictEqual(acceptedConsent.categories.marketing, true);
  assert.ok(acceptedConsent.updatedAt, 'accepted consent should have a timestamp');
  assert.strictEqual(await page.evaluate(() => window.__consentTestLoads), 1);

  await page.locator('#privacySettingsButton').click();
  await page.waitForSelector('#wc-consent-overlay');
  await page.evaluate(() => {
    document.querySelector('[data-wc-category="marketing"]').checked = false;
  });
  await page.locator('#wc-consent-overlay [data-wc-consent="save"]').click();
  await page.waitForSelector('#wc-consent-manage');

  const revokedConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.strictEqual(revokedConsent.categories.analytics, true);
  assert.strictEqual(revokedConsent.categories.marketing, false);
  assert.strictEqual(await page.evaluate(() => window.__consentTestCleanups), 1);

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => Boolean(window.WeConnectConsent), null, {
    timeout: 10000
  });
  await page.waitForSelector('#wc-consent-manage', { timeout: 10000 });

  assert.strictEqual(await page.locator('#wc-consent-banner').count(), 0);
  const persistedConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.strictEqual(persistedConsent.categories.analytics, true);
  assert.strictEqual(persistedConsent.categories.marketing, false);

  await context.close();
}

async function testAppShellRejectFlow(browser, baseUrl) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const requests = [];
  page.on('request', request => requests.push(request.url()));

  await page.goto(`${baseUrl}/`, { waitUntil: 'domcontentloaded' });
  await waitForConsentReady(page);

  assertNoTrackerRequests(requests, 'app shell');
  await page.locator('[data-wc-consent="reject"]').click();
  await page.waitForSelector('#wc-consent-manage');

  const rejectedConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.deepStrictEqual(rejectedConsent.categories, {
    necessary: true,
    analytics: false,
    marketing: false
  });
  assert.ok(rejectedConsent.updatedAt, 'rejected consent should have a timestamp');

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => Boolean(window.WeConnectConsent), null, {
    timeout: 10000
  });
  await page.waitForSelector('#wc-consent-manage', { timeout: 10000 });

  assert.strictEqual(await page.locator('#wc-consent-banner').count(), 0);
  const persistedConsent = await page.evaluate(() => window.WeConnectConsent.get());
  assert.strictEqual(persistedConsent.categories.analytics, false);
  assert.strictEqual(persistedConsent.categories.marketing, false);

  await context.close();
}

async function main() {
  const executablePath = findChromiumExecutable();
  if (!executablePath) {
    throw new Error(
      'Chromium/Chrome executable not found. Install Chrome/Chromium or set PLAYWRIGHT_CHROMIUM_EXECUTABLE.'
    );
  }

  console.log('Testing consent management');
  console.log(`   Browser: ${executablePath}`);

  const marketingServer = await startStaticServer(path.join(ROOT_DIR, 'marketing'));
  const appShellServer = await startStaticServer(path.join(ROOT_DIR, 'frontend', 'web'));
  const browser = await chromium.launch({
    executablePath,
    headless: true
  });

  try {
    console.log(`   Marketing shell: ${marketingServer.url}`);
    await testMarketingConsentFlow(browser, marketingServer.url);
    console.log('   [OK] Marketing consent flow passed');

    console.log(`   App shell: ${appShellServer.url}`);
    await testAppShellRejectFlow(browser, appShellServer.url);
    console.log('   [OK] App shell consent flow passed');

    console.log('\n[OK] Consent management tests passed!');
  } finally {
    await browser.close();
    await marketingServer.close();
    await appShellServer.close();
  }
}

main().catch(error => {
  console.error('\nConsent management tests failed');
  console.error(error);
  process.exit(1);
});
