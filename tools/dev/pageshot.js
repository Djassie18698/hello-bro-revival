// Full-size screenshots of a web page with headless Chrome (or Edge) over the DevTools protocol (Node 24 has WebSocket built in).
// The app's browser pane is small, so its screenshots are blurry: use this to judge a page's design (home page, wiki).
//   node tools/dev/pageshot.js <url> <out.png> [width=1440] [height=900] [full=1] [still=1]
//     full=1   the whole page (scrolls through it first so lazy pictures load; reports a page wider than the window)
//     still=1  "reduced motion" (no animations, fade-ins already shown); 0 = as a visitor sees it
//   e.g. node tools/dev/pageshot.js http://127.0.0.1:18090/ re/home.png 390 844 0 0     (phone size, top of the page)
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
// HB_UA=<browser name> pretends to be another browser (the iPhone app: HB_UA=NinjaPanelApp)
const [url, out, W = '1440', Hh = '900', full = '1', still = '1'] = process.argv.slice(2);
if (!url || !out) { console.log('usage: node tools/dev/pageshot.js <url> <out.png> [width] [height] [full=1] [still=1]'); process.exit(1); }
const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome', '/usr/bin/chromium'].find((p) => fs.existsSync(p));
if (!CHROME) { console.log('no Chrome or Edge found'); process.exit(1); }
const port = 9300 + Math.floor(Math.random() * 500);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pshot-'));
const ch = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  let targets = [];
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await wait(200); }
  const page = targets.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r));
  let id = 0; const pending = new Map(); const logs = [];
  ws.addEventListener('message', (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
    if (m.method === 'Runtime.exceptionThrown') logs.push('PAGE ERROR ' + JSON.stringify(m.params.exceptionDetails).slice(0, 300));
    if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') logs.push('CONSOLE ERROR ' + JSON.stringify(m.params.args).slice(0, 300));
  });
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const w = Number(W), h = Number(Hh);
  await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: w < 700 });
  if (process.env.HB_UA) await send('Emulation.setUserAgentOverride', { userAgent: process.env.HB_UA }); // e.g. the iPhone app's name (NinjaPanelApp)
  await send('Emulation.setEmulatedMedia', { features: still === '1' ? [{ name: 'prefers-reduced-motion', value: 'reduce' }] : [] });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Page.navigate', { url });
  await wait(3500);
  let clip;
  if (full === '1') {
    for (let y = 0; y < 20000; y += 600) { await send('Runtime.evaluate', { expression: `scrollTo(0, ${y})` }); await wait(120); }
    await send('Runtime.evaluate', { expression: 'scrollTo(0, 0)' }); await wait(1200);
    const r = await send('Runtime.evaluate', { expression: 'JSON.stringify([document.documentElement.scrollWidth, document.documentElement.scrollHeight])', returnByValue: true });
    const [sw, sh] = JSON.parse(r.result.result.value);
    if (sw > w) logs.push(`HORIZONTAL OVERFLOW: the page is ${sw}px wide in a ${w}px window`);
    clip = { x: 0, y: 0, width: w, height: Math.min(sh, 16000), scale: 1 };
  }
  const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: full === '1', ...(clip ? { clip } : {}) });
  fs.writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
  console.log('saved', out, clip ? `${clip.width}x${clip.height}` : `${w}x${h}`, logs.length ? '\n' + logs.join('\n') : '');
  ws.close(); ch.kill();
  setTimeout(() => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} process.exit(0); }, 500);
})().catch((e) => { console.error(e); ch.kill(); process.exit(1); });
