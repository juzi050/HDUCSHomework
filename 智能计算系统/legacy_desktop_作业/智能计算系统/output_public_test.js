const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({headless: true, executablePath: 'C:/Users/86136/AppData/Local/ms-playwright/chromium-1219/chrome-win64/chrome.exe'});
  const page = await browser.newPage();
  await page.goto('http://8.136.192.200/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);
  console.log('PUBLIC_START');
  console.log((await page.locator('body').innerText()).slice(0, 3000));
  console.log('PUBLIC_END');
  await browser.close();
})();
