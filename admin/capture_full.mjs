import puppeteer from 'puppeteer-core';
import fs from 'fs';
import path from 'path';

const EDGE_PATH = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const PORT = 5174;
const BASE_URL = `http://localhost:${PORT}`;

async function run() {
  const browser = await puppeteer.launch({
    executablePath: EDGE_PATH,
    headless: true,
    args: ['--no-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 1600, deviceScaleFactor: 2 });

  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle0' });
  await page.type('input[type="email"]', 'admin@calora.app');
  await page.type('input[type="password"]', 'admin123');
  await page.click('button[type="submit"]');

  await page.waitForNavigation({ waitUntil: 'networkidle0' }).catch(() => {});
  await page.waitForSelector('main');
  await new Promise(r => setTimeout(r, 2000));

  await page.screenshot({ path: 'screenshots/before_full_1440.png', fullPage: true });
  console.log('Saved before_full_1440.png');
  await browser.close();
}

run().catch(console.error);
