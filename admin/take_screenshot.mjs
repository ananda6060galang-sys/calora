import puppeteer from 'puppeteer-core';
import fs from 'fs';
import path from 'path';

const EDGE_PATH = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const PORT = 5174;
const BASE_URL = `http://localhost:${PORT}`;

async function run() {
  const outDir = path.resolve('screenshots');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const browser = await puppeteer.launch({
    executablePath: EDGE_PATH,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });

  console.log('Navigating to login...');
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle0' });

  // Fill in login credentials
  await page.type('input[type="email"]', 'admin@calora.app');
  await page.type('input[type="password"]', 'admin123');
  await page.click('button[type="submit"]');

  console.log('Waiting for navigation to dashboard...');
  await page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 15000 }).catch(() => {});

  // Ensure on /dashboard
  await page.waitForSelector('main', { timeout: 10000 });
  await new Promise((r) => setTimeout(r, 2000)); // wait for animations and fonts

  const filename = process.argv[2] || 'before_dashboard_1440.png';
  const outPath = path.join(outDir, filename);
  await page.screenshot({ path: outPath, fullPage: false });
  console.log(`Screenshot saved to ${outPath}`);

  await browser.close();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
