import puppeteer from 'puppeteer-core';
import fs from 'fs';
import path from 'path';

const EDGE_PATH = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const PORT = 5174;
const BASE_URL = `http://localhost:${PORT}`;

const viewports = [
  { name: '1440_light_en', width: 1440, height: 1600, dark: false, lang: 'en' },
  { name: '1440_light_id', width: 1440, height: 1600, dark: false, lang: 'id' },
  { name: '1440_dark_en', width: 1440, height: 1600, dark: true, lang: 'en' },
  { name: '1280_light_en', width: 1280, height: 1600, dark: false, lang: 'en' },
  { name: '1024_light_en', width: 1024, height: 1800, dark: false, lang: 'en' },
  { name: '768_light_en', width: 768, height: 2200, dark: false, lang: 'en' },
  { name: '390_mobile_en', width: 390, height: 2600, dark: false, lang: 'en' },
];

async function run() {
  const browser = await puppeteer.launch({
    executablePath: EDGE_PATH,
    headless: true,
    args: ['--no-sandbox']
  });

  const page = await browser.newPage();

  console.log('Logging in...');
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle0' });
  await page.type('input[type="email"]', 'admin@calora.app');
  await page.type('input[type="password"]', 'admin123');
  await page.click('button[type="submit"]');
  await page.waitForNavigation({ waitUntil: 'networkidle0' }).catch(() => {});
  await page.waitForSelector('main');
  await new Promise(r => setTimeout(r, 1500));

  for (const vp of viewports) {
    console.log(`Capturing ${vp.name} (${vp.width}x${vp.height})...`);
    await page.setViewport({ width: vp.width, height: vp.height, deviceScaleFactor: 2 });

    // Set theme & language in localStorage & DOM
    await page.evaluate(({ dark, lang }) => {
      localStorage.setItem('calora_theme', dark ? 'dark' : 'light');
      localStorage.setItem('calora_lang', lang);
      const root = document.documentElement;
      if (dark) {
        root.classList.add('dark');
      } else {
        root.classList.remove('dark');
      }
    }, { dark: vp.dark, lang: vp.lang });

    // Reload page to apply language & theme cleanly through React context
    await page.reload({ waitUntil: 'networkidle0' });
    await page.waitForSelector('main');
    await new Promise(r => setTimeout(r, 1200));

    const outPath = path.resolve(`screenshots/after_${vp.name}.png`);
    await page.screenshot({ path: outPath, fullPage: true });
    console.log(`✓ Saved ${outPath}`);
  }

  await browser.close();
  console.log('All screenshots captured successfully!');
}

run().catch((err) => {
  console.error('Error during capture:', err);
  process.exit(1);
});
