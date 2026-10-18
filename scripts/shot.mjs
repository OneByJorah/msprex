import { chromium } from "playwright";
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, colorScheme: "dark" });
await page.goto("http://127.0.0.1:8080/", { waitUntil: "networkidle" });
await page.waitForTimeout(1500);
await page.screenshot({ path: "docs/screenshots/dashboard.png", fullPage: true });
console.log("saved docs/screenshots/dashboard.png");
await browser.close();
