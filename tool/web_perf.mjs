// Measures dart_code_3D in a browser: how long a .dc3d takes to open and how
// many frames per second the world renders while the camera flies forward.
// Software WebGL (SwiftShader), so the numbers are a lower bound.
//
// Needs `playwright-core` (and a Chromium it can launch) and a web build served
// over HTTP:
//   (cd apps/dart_code_3d && flutter build web --release -t lib/main_production.dart)
//   python3 -m http.server 8099 --directory apps/dart_code_3d/build/web &
//   node tool/web_perf.mjs http://localhost:8099 apps/dart_code_3d/build/e2e/AltMe.dc3d
//
// Prints one JSON object.
import { chromium } from 'playwright-core';

const t0 = Date.now();
/** Progress on stderr, so a stuck run says where. */
const step = (message) => console.error(`[${((Date.now() - t0) / 1000).toFixed(1)} s] ${message}`);
const [url, mapPath] = process.argv.slice(2);
if (!url || !mapPath) {
  console.error('usage: node tool/web_perf.mjs <app url> <map.dc3d>');
  process.exit(2);
}

const browser = await chromium.launch({
  args: [
    '--use-angle=swiftshader',
    '--enable-unsafe-swiftshader',
    '--ignore-gpu-blocklist',
    '--enable-webgl',
  ],
});
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
page.on('pageerror', (e) => errors.push(String(e).slice(0, 300)));
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text().slice(0, 300));
});

// Every animation frame the page gets, to read the cadence while flying.
await page.addInitScript(() => {
  window.__frames = [];
  const loop = (t) => {
    window.__frames.push(t);
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
});

const result = { url, map: mapPath };
const started = Date.now();
step('loading the app');
await page.goto(url, { waitUntil: 'load' });
step('loaded; waiting for Flutter');
// Flutter draws to a canvas: turn its semantics on to find the buttons.
await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 120000 });
await page.evaluate(() => document.querySelector('flt-semantics-placeholder').click());
step('semantics on');
const openFile = page.getByRole('button', { name: 'Open file' });
await openFile.waitFor({ timeout: 120000 });
result.appReadySeconds = (Date.now() - started) / 1000;
step('home screen ready');

const chooser = page.waitForEvent('filechooser');
await openFile.click();
(await chooser).setFiles(mapPath);
const opening = Date.now();
step('map chosen; waiting for the viewer');
// The Search button is the viewer's, whatever the map.
await page.getByRole('button', { name: /^Search/ }).waitFor({ timeout: 300000 });
step('viewer open');
result.mapOpenSeconds = (Date.now() - opening) / 1000;

// Let the first frames settle, then fly forward and read the frame cadence.
// The first frames compile shaders and upload meshes: leave them out.
await page.waitForTimeout(Number(process.env.SETTLE_MS || 20000));
await page.mouse.click(720, 450);
await page.evaluate(() => (window.__frames.length = 0));
await page.keyboard.down('ArrowUp');
const flyMs = Number(process.env.FLY_MS || 10000);
await page.waitForTimeout(flyMs);
await page.keyboard.up('ArrowUp');
const frames = await page.evaluate(() => window.__frames.slice());
const deltas = frames.slice(1).map((t, i) => t - frames[i]).sort((a, b) => a - b);
const at = (q) => (deltas.length ? deltas[Math.min(deltas.length - 1, Math.floor(deltas.length * q))] : 0);
result.flying = {
  frames: frames.length,
  fps: +(frames.length / (flyMs / 1000)).toFixed(1),
  medianFrameMs: +at(0.5).toFixed(1),
  p90FrameMs: +at(0.9).toFixed(1),
};
result.errors = errors.slice(0, 5);
console.log(JSON.stringify(result, null, 2));
await page.screenshot({ path: process.env.SCREENSHOT || 'web_perf.png' });
await browser.close();
