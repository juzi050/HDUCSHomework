const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({headless: true, executablePath: 'C:/Users/86136/AppData/Local/ms-playwright/chromium-1219/chrome-win64/chrome.exe'});
  const page = await browser.newPage();
  await page.goto('http://8.136.192.200:3001/login', { waitUntil: 'networkidle' });
  await page.fill('input[type="email"]', '2195232218@qq.com');
  await page.fill('input[type="password"]', 'juzi0505');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(2000);
  console.log('CMS_START');
  console.log((await page.locator('body').innerText()).slice(0, 3000));
  console.log('CMS_END');
  await browser.close();
})();
