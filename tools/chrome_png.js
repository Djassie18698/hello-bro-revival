// Renders an HTML snippet to a PNG with a see-through background, using headless Chrome (or Edge) over the DevTools protocol
// (Node 24 has WebSocket and fetch built in). Used for game pictures we draw ourselves: tools/make_login_logo.js, tools/make_name_sparkle.js.
//   await renderPng(html, out, width, height, check)   check: optional JS expression that must be true before the shot (fonts, images)
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');

async function renderPng(html, out, W, H, check) {
  const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    '/usr/bin/google-chrome', '/usr/bin/chromium'].find((p) => fs.existsSync(p));
  if (!CHROME) throw new Error('no Chrome or Edge found');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cpng-'));
  const page = path.join(dir, 'page.html');
  fs.writeFileSync(page, html);
  const port = 9300 + Math.floor(Math.random() * 500);
  const ch = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run',
    '--allow-file-access-from-files', 'about:blank'], { stdio: 'ignore' });
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  try {
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
    if (check) {
      const ok = await send('Runtime.evaluate', { expression: check, returnByValue: true });
      if (!ok.result.result.value) throw new Error('the page was not ready (fonts or pictures did not load)');
    }
    const shot = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: W, height: H, scale: 1 } });
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
    ws.close();
  } finally {
    ch.kill();
    await wait(500);
    try { fs.rmSync(dir, { recursive: true, force: true }); } catch {}
  }
}

module.exports = { renderPng };
