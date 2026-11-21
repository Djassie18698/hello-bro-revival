// Opens the rewritten game's JavaScript screens (server/webclient) one after another in headless Chrome and saves a picture of
// each in re/js/<tag>/, with what fit.js had to shrink there and every text that still holds Chinese characters.
//   node tools/dev/js-screens.js [filter] [--device=<guest>] [--tag=before|after]      (dev server on :18081 must run)
// A shot = name:<expression run in the page>; the screen opens from Home each time.
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const args = process.argv.slice(2), filter = args.find((a) => !a.startsWith('--')) || '';
const opt = (k, d) => (args.find((a) => a.startsWith('--' + k + '=')) || '--' + k + '=' + d).slice(k.length + 3);
const device = opt('device', 'pol1'), tag = opt('tag', 'shot');
const first = '(HB.data.ofType(1)[0] || {}).seq';
const SHOTS = [
  ['home', 'null'],
  ['shop0', 'HB.screens.shop(0)'], ['shop1', 'HB.screens.shop(1)'], ['shop2', 'HB.screens.shop(2)'], ['viplist', 'HB.screens.viplist()'],
  ['spar', 'HB.screens.spar()'], ['arena0', 'HB.screens.arena(0)'], ['arena1', 'HB.screens.arena(1)'], ['arena2', 'HB.screens.arena(2)'],
  ['tower', 'HB.screens.tower()'], ['plunder', 'HB.screens.plunder()'],
  ['ramen', 'HB.screens.ramen()'], ['moneytree', 'HB.screens.moneytree()'],
  ['growth', `HB.screens.growth(${first})`], ['potential', `HB.screens.potential(${first})`], ['rebirth', `HB.screens.rebirth(${first})`],
  ['upgrade', `HB.screens.upgrade(${first})`],
  ['news0', 'HB.screens.news(0)'], ['news1', 'HB.screens.news(1)'], ['news2', 'HB.screens.news(2)'], ['friends', 'HB.screens.friends()'],
  ['war0', 'HB.screens.war(0)'], ['war1', 'HB.screens.war(1)'], ['war2', 'HB.screens.war(2)'], ['war3', 'HB.screens.war(3)'], ['war4', 'HB.screens.war(4)'],
  ['war1-1', 'HB.screens.war(1,1)'], ['war1-2', 'HB.screens.war(1,2)'], ['war2-1', 'HB.screens.war(2,1)'], ['war3-1', 'HB.screens.war(3,1)'],
  ['treasure', 'HB.screens.treasure()'],
  ['book0', 'HB.screens.ninjabook(0)'], ['book1', 'HB.screens.ninjabook(1)'], ['book2', 'HB.screens.ninjabook(2)'], ['book3', 'HB.screens.ninjabook(3)'],
  ['levelup', 'HB.screens.levelup()'], ['playerinfo', 'HB.screens.playerinfo()'], ['settings', 'HB.screens.settings()'],
  ['custom', 'HB.screens.custom()'],
  ...[1, 2, 3, 4, 5, 6].map((k) => ['card' + k, `(() => { const c = HB.data.ofType(${k})[0]; return c ? HB.screens.details(c) : null; })()`]),
].filter((s) => filter.split(',').some((f) => s[0].includes(f))); // the filter may be a comma list
const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find((p) => fs.existsSync(p));
const port = 9300 + Math.floor(Math.random() * 500), dir = fs.mkdtempSync(path.join(os.tmpdir(), 'jsscr-'));
const ch = spawn(CHROME, ['--headless=new', '--mute-audio', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  let targets = [];
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await wait(200); }
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r));
  let id = 0; const pending = new Map(); let errs = [];
  ws.addEventListener('message', (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
    if (m.method === 'Runtime.exceptionThrown') errs.push('PAGE ERROR ' + ((m.params.exceptionDetails.exception || {}).description || m.params.exceptionDetails.text || '').slice(0, 300));
  });
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const ev = async (expression) => { const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }); return r.result && r.result.result ? r.result.result.value : undefined; };
  await send('Emulation.setDeviceMetricsOverride', { width: 760, height: 1350, deviceScaleFactor: 1, mobile: false });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Page.navigate', { url: `http://127.0.0.1:18081/play/?auto=1&device=${device}&stage=0` });
  await wait(14000);
  const out = 're/js/' + tag; fs.mkdirSync(out, { recursive: true });
  const report = [];
  // every label showing: fit.js shrinks and Chinese leftovers
  const LOOK = `(() => { const zh = []; const walk = (n) => { if (!n || !n.visible) return; if ((n instanceof HB.Label || n instanceof HB.BMLabel) && /[\\u3400-\\u9fff]/.test(String(n.text))) zh.push(String(n.text).slice(0, 40)); if (n instanceof HB.Button) for (const t of Object.values(n.titles || {})) if (/[\\u3400-\\u9fff]/.test(String(t))) zh.push('button ' + String(t).slice(0, 40)); (n.children || []).forEach(walk); }; walk(HB.game.subContent); HB.scene.children.filter((c) => c.z >= 500).forEach(walk); return JSON.stringify({ zh, fit: HB.fit ? HB.fit.report() : [] }); })()`;
  for (const [name, js] of SHOTS) {
    errs = [];
    await ev(`(async () => { try { await Promise.race([${js}, new Promise((r) => setTimeout(r, 4000))]); } catch (e) { console.error('JS ' + (e && e.stack || e)); } })()`);
    await wait(Number(process.env.JS_WAIT) || 2200);
    const look = JSON.parse((await ev(LOOK)) || '{}');
    const shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${out}/${name}.png`, Buffer.from(shot.result.data, 'base64'));
    report.push({ name, ...look, errors: errs });
    console.log(name + (look.zh && look.zh.length ? '\n   Chinese: ' + look.zh.join(' | ') : '') + (look.fit && look.fit.length ? '\n   shrunk: ' + look.fit.map((f) => f[0] + ' ' + f[1] + '%').join(' | ') : '') + (errs.length ? '\n   ' + errs.join('\n   ') : ''));
    await ev('(async () => { try { HB.scene.children.filter((c) => c.z >= 500).forEach((c) => { HB.luaLeave && HB.luaLeave(c); c.removeSelf(); }); HB.loading(false); await HB.game.goHome(); } catch (e) {} })()');
    await wait(700);
  }
  fs.writeFileSync(out + '/report.json', JSON.stringify(report, null, 1));
  ws.close(); ch.kill();
  setTimeout(() => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} process.exit(0); }, 500);
})().catch((e) => { console.error(e); ch.kill(); process.exit(1); });
