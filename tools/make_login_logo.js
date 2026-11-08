// The game's login logo as "NINJA ONLINE / REBORN" (owner, 8 Nov 2026), the same look as the website's hero logo:
// the owner's NINJA ONLINE picture (server/site/img/logo-ninjaonline.webp) with REBORN under it (Lilita One, gold gradient,
// thick brown outline). Rendered by headless Chrome on a see-through background at the original logo's size (562x328), into
// server/cdn/src/ccbResources/logo.png (hot update; LoginView.ccbi and LogoScene.ccbi show ccbResources/logo.png).
//   node tools/make_login_logo.js [out.png]      then python -I tools/build_cdn.py 28.0.N
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const ROOT = path.join(__dirname, '..');
const out = process.argv[2] || path.join(ROOT, 'server/cdn/src/ccbResources/logo.png');
const W = 562, H = 328;
const img = 'file:///' + path.join(ROOT, 'server/site/img/logo-ninjaonline.webp').replace(/\\/g, '/');
const html = `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Lilita+One&display=swap" rel="stylesheet">
<style>
html, body { margin: 0; width: ${W}px; height: ${H}px; background: transparent; overflow: hidden; }
.logo { width: ${W}px; height: ${H}px; display: flex; flex-direction: column; align-items: center; justify-content: center;
  filter: drop-shadow(0 5px 6px rgba(0, 0, 0, .55)); }
img { display: block; width: 486px; height: auto; }
span { position: relative; display: block; margin-top: -10px; font: 400 64px/0.9 'Lilita One', sans-serif; letter-spacing: .02em; white-space: nowrap;
  color: #3a1405; -webkit-text-stroke: .16em #3a1405; text-shadow: 0 .09em 0 #230a02; }
span::after { content: attr(data-t); position: absolute; left: 0; top: 0; -webkit-text-stroke: 0; text-shadow: none;
  background: linear-gradient(180deg, #fff8b8 6%, #ffd640 34%, #ff9b1f 60%, #f2541a 92%);
  -webkit-background-clip: text; background-clip: text; color: transparent; -webkit-text-fill-color: transparent; }
</style></head><body><div class="logo"><img src="${img}" alt=""><span data-t="REBORN">REBORN</span></div></body></html>`;
const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome', '/usr/bin/chromium'].find((p) => fs.existsSync(p));
if (!CHROME) { console.log('no Chrome or Edge found'); process.exit(1); }
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'logo-'));
const page = path.join(dir, 'logo.html');
fs.writeFileSync(page, html);
const port = 9300 + Math.floor(Math.random() * 500);
const ch = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run',
  '--allow-file-access-from-files', 'about:blank'], { stdio: 'ignore' });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  let targets = [];
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await wait(200); }
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r));
  let id = 0; const pending = new Map();
  ws.addEventListener('message', (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  await send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });
  await send('Page.enable');
  await send('Page.navigate', { url: 'file:///' + page.replace(/\\/g, '/') });
  await wait(2500);
  const ok = await send('Runtime.evaluate', { expression: "document.fonts.check('64px \"Lilita One\"') && document.images[0].complete && document.images[0].naturalWidth > 0", returnByValue: true });
  if (!ok.result.result.value) throw new Error('the font or the logo picture did not load');
  const shot = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: W, height: H, scale: 1 } });
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
  console.log('saved', out, `${W}x${H}`);
  ws.close(); ch.kill();
  setTimeout(() => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} process.exit(0); }, 500);
})().catch((e) => { console.error(e.message || e); ch.kill(); process.exit(1); });
