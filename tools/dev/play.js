// Plays the rewritten game (server/webclient) by hand from the command line, in muted headless Chrome: one Chrome stays open
// (serve) and the other commands talk to it, so a feature can be played step by step and looked at.
//   node tools/dev/play.js serve <guest> [port]     start Chrome on /play/?auto=1&device=<guest> and keep it (run in the background)
//     PLAY_ACCOUNT=1 with serve: log in as the emulator's test account instead of a guest (name + password read from tools/dev/emu.account
//     at run time and put into the page's own storage, the same keys the account window's Log in fills)
//   node tools/dev/play.js ui [port]                what is on screen: buttons (index, name, title, place) and texts, topmost window first
//   node tools/dev/play.js tap <index|name> [port]  a real mouse click on that button (name: the first shown button with that name / title)
//   node tools/dev/play.js click <x> <y> [port]     a real mouse click at a place on the page
//   node tools/dev/play.js ev "<javascript>" [port] run JavaScript in the page, print the result
//   node tools/dev/play.js lua "<lua>" [port]       run Lua in the game
//   node tools/dev/play.js log [port]               requests sent since the last "log" (endpoint, Cmd, start of the reply), Lua / page errors, missing C++ names
//   node tools/dev/play.js shot <file> [port]       a picture of the page
//   node tools/dev/play.js reload [port]            load the page again without the browser's kept copies (after changing code or pictures)
//   node tools/dev/play.js home [port]              close windows, back to Home
//   node tools/dev/play.js stop [port]
// The dev server on :18081 must run (bash tools/dev/restart.sh). PLAY_BASE=http://127.0.0.1:<port> with serve = another server
// (a private copy with its clock moved: tools/dev/shift-clock.js).
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const HOOK = `(() => { if (window.__play) return; const P = window.__play = { net: [], err: [] };
  const of = window.fetch; window.fetch = async function (u, o) { const r = await of.apply(this, arguments);
    try { if (o && o.method === 'POST' && typeof u === 'string' && /^\\/(rl_|xk_)/.test(u)) { const c = r.clone(); const t = await c.text(); const q = new URLSearchParams(o.body);
      const skip = new Set(['Uid', 'Session', 'Clinettime', 'Platform', 'Version', 'Pt', 'ServerID', 'GroupID']); const ps = []; q.forEach((v, k) => { if (!skip.has(k)) ps.push(k + '=' + v); });
      P.net.push(u + ' ' + ps.join(' ') + ' -> ' + t.replace(/\\s+/g, ' ').slice(0, P.max || 400)); } } catch (e) {}
    return r; };
  const ce = console.error; console.error = function () { P.err.push([].map.call(arguments, (x) => (x && x.stack) || String(x)).join(' ').slice(0, 700)); return ce.apply(this, arguments); };
  window.addEventListener('error', (e) => P.err.push('PAGE ERROR ' + (e.error && e.error.stack || e.message)));
  window.addEventListener('unhandledrejection', (e) => P.err.push('REJECTED ' + (e.reason && e.reason.stack || e.reason))); })()`;
const UI = `(() => { const r = HB.canvas ? HB.canvas.getBoundingClientRect() : document.querySelector('canvas').getBoundingClientRect();
  const place = (n) => { const m = n.world(); const cx = m[4] + m[0] * n.w / 2 + m[2] * n.h / 2, cy = m[5] + m[1] * n.w / 2 + m[3] * n.h / 2; return [Math.round(r.left + cx / HB.size[0] * r.width), Math.round(r.top + (1 - cy / HB.size[1]) * r.height)]; };
  const btns = [], texts = [];
  const tops = HB.scene.children.slice().sort((a, b) => b.z - a.z);
  const walk = (n, top) => { if (!n.visible) return;
    if (n instanceof HB.Button) { const p = place(n); btns.push({ name: n.name || n.selector || '', title: (n.titles && (n.titles[1] || n.titles[0])) || (n.label && n.label.text) || '', x: p[0], y: p[1], on: n.enabled !== false, top, node: n }); }
    else if ((n instanceof HB.Label || n instanceof HB.BMLabel) && n.text && String(n.text).trim()) { const p = place(n); texts.push({ t: String(n.text).replace(/\\s+/g, ' ').slice(0, 90), name: n.name || '', x: p[0], y: p[1], top }); }
    (n.children || []).slice().sort((a, b) => b.z - a.z).forEach((c) => walk(c, top)); };
  tops.forEach((t, i) => walk(t, t.z));
  window.__playBtns = btns.map((b) => b.node);
  return { btns: btns.map((b, i) => ({ i, name: b.name, title: b.title, x: b.x, y: b.y, on: b.on, top: b.top })), texts }; })()`;

async function connect(port) {
  const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r, j) => { ws.addEventListener('open', r); ws.addEventListener('error', j); });
  let id = 0; const pending = new Map();
  ws.addEventListener('message', (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const ev = async (expression) => { const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (r.result && r.result.exceptionDetails) return 'EXCEPTION ' + ((r.result.exceptionDetails.exception || {}).description || r.result.exceptionDetails.text);
    return r.result && r.result.result ? r.result.result.value : undefined; };
  const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
  const shot = async (file) => { const s = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(file, Buffer.from(s.result.data, 'base64')); };
  const ui = async () => JSON.parse(await ev(`JSON.stringify(${UI})`));
  const log = async () => JSON.parse(await ev(`(() => { const P = window.__play || { net: [], err: [] }; const o = { net: P.net.splice(0), err: P.err.splice(0), lua: (HB.luaErrors || []).splice(0), missing: [...(HB.luaMissing || [])] }; return JSON.stringify(o); })()`));
  const tap = async (what) => { const u = await ui(); const b = /^\d+$/.test(String(what)) ? u.btns[Number(what)] : (u.btns.find((x) => x.on && (x.name === what || x.title === what)) || u.btns.find((x) => x.name === what || x.title === what));
    if (!b) return null; await click(b.x, b.y); return b; };
  const home = async () => { await ev('(async () => { try { HB.scene.children.filter((c) => c.z >= 500).forEach((c) => { HB.luaLeave && HB.luaLeave(c); c.removeSelf(); }); HB.loading(false); await HB.game.goHome(); } catch (e) {} })()'); await wait(700); };
  return { ws, send, ev, click, shot, ui, log, tap, home, close: () => ws.close() };
}
module.exports = { connect, wait };

if (require.main === module) (async () => {
  const [cmd, ...rest] = process.argv.slice(2);
  const portOf = (i) => Number(rest[i]) || Number(process.env.PLAY_PORT) || 9811;
  if (cmd === 'serve') {
    const device = rest[0] || 'play1', port = portOf(1);
    const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find((p) => fs.existsSync(p));
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'play-'));
    const ch = spawn(CHROME, ['--headless=new', '--mute-audio', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
    for (let i = 0; i < 50; i++) { try { await fetch(`http://127.0.0.1:${port}/json`); break; } catch {} await wait(200); }
    const c = await connect(port);
    await c.send('Emulation.setDeviceMetricsOverride', { width: 760, height: 1350, deviceScaleFactor: 1, mobile: false });
    await c.send('Page.enable'); await c.send('Runtime.enable');
    await c.send('Page.addScriptToEvaluateOnNewDocument', { source: HOOK });
    if (process.env.PLAY_ACCOUNT) { const [name, pw] = fs.readFileSync(path.join(__dirname, 'emu.account'), 'utf8').split(/\r?\n/).map((l) => l.trim());
      await c.send('Page.addScriptToEvaluateOnNewDocument', { source: `try { localStorage.setItem('hb.name', ${JSON.stringify(name)}); localStorage.setItem('hb.namepw', ${JSON.stringify(pw)}); } catch (e) {}` }); }
    await c.send('Page.navigate', { url: `${process.env.PLAY_BASE || 'http://127.0.0.1:18081'}/play/?auto=1&device=${device}&stage=0&mute=1&preload=0` });
    console.log('serving ' + device + ' on ' + port);
    c.ws.addEventListener('close', () => { ch.kill(); process.exit(0); });
    process.on('SIGTERM', () => { ch.kill(); process.exit(0) });
    ch.on('exit', () => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} process.exit(0); });
    return;
  }
  const nargs = { ui: 0, log: 0, home: 0, stop: 0, reload: 0, tap: 1, ev: 1, lua: 1, shot: 1, click: 2 }[cmd];
  if (nargs === undefined) { console.log('commands: serve ui tap click ev lua log shot home reload stop'); process.exit(1); }
  const port = portOf(nargs);
  const c = await connect(port);
  const printLog = async () => { const l = await c.log(); l.net.forEach((n) => console.log('  > ' + n)); l.err.forEach((e) => console.log('  ERR ' + e)); l.lua.forEach((e) => console.log('  LUA ' + String(e).slice(0, 600))); if (l.missing.length) console.log('  missing: ' + l.missing.join(', ')); };
  if (cmd === 'ui') { const u = await c.ui(); const top = Math.max(...u.btns.map((b) => b.top), ...u.texts.map((t) => t.top), 0);
    const all = process.env.PLAY_ALL; const sel = (a) => (all ? a : a.filter((x) => x.top === top || top < 500));
    console.log('top layer z=' + top); sel(u.btns).forEach((b) => console.log(`[${b.i}] ${b.on ? '' : '(off) '}${b.name} "${b.title}" @${b.x},${b.y} z${b.top}`)); console.log(sel(u.texts).map((t) => `${t.t}${t.name ? ' <' + t.name + '>' : ''} @${t.x},${t.y}`).join('\n')); }
  else if (cmd === 'tap') { const b = await c.tap(rest[0]); console.log(b ? `tapped ${b.name} "${b.title}" @${b.x},${b.y}` : 'no such button'); await wait(Number(process.env.PLAY_WAIT) || 1500); await printLog(); }
  else if (cmd === 'click') { await c.click(Number(rest[0]), Number(rest[1])); await wait(Number(process.env.PLAY_WAIT) || 1500); await printLog(); }
  else if (cmd === 'ev') { console.log(await c.ev(rest[0])); await wait(Number(process.env.PLAY_WAIT) || 1200); await printLog(); }
  else if (cmd === 'lua') { console.log(await c.ev(`(() => { try { return String(HB.luaCall(HB.L.load(${JSON.stringify(rest[0])}))); } catch (e) { return 'ERR ' + (e && e.stack || e); } })()`)); await wait(Number(process.env.PLAY_WAIT) || 1200); await printLog(); }
  else if (cmd === 'log') await printLog();
  else if (cmd === 'shot') { await c.shot(rest[0]); console.log('saved ' + rest[0]); }
  else if (cmd === 'home') await c.home();
  else if (cmd === 'reload') { await c.send('Network.clearBrowserCache'); await c.send('Page.reload', { ignoreCache: true }); await wait(Number(process.env.PLAY_WAIT) || 14000); }
  else if (cmd === 'stop') { await c.send('Browser.close'); }
  c.close(); process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
