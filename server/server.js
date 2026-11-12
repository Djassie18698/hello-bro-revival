// Hello Bro revival server. Node 22+ (built-in node:sqlite), no dependencies.
// Protocol (reverse-engineered from libgame.so): HTTP GET/POST to /<cgi>?Cmd=..&Uin=..&Session=..
// Responses are XML: <RENLONG code="0">...</RENLONG>, values are child-element text.
const http = require('http');
const net = require('net');
const url = require('url');
const handlers = require('./handlers');
const admin = require('./admin');
const settings = require('./settings');
const manager = require('./manager');

const PORT = process.env.PORT || 18080;
const STARTED = Math.floor(Date.now() / 1000);
const VERSION = (() => { try { return require('child_process').execSync('git log -1 --format=%h', { cwd: __dirname, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch { return ''; } })(); // '' outside a git clone
// Everything printed also goes to the Server Manager's live log.
for (const k of ['log', 'error']) {
  const orig = console[k].bind(console);
  console[k] = (...a) => { settings.addLog(k === 'error' ? 'error' : 'info', a.map((x) => (x && x.stack) || String(x)).join(' ')); orig(...a); };
}
// The save: SQLite in WAL mode with a health check and backups on start and every 6 h (db.js).
const dbm = require('./db');
const db = dbm.open(process.env.DB || 'hellobro.db');
require('./war').startAuto(db); // country war Auto-Attack for players who are offline
require('./rotation').startTick(db); // weekly event rotation: pays the Super Ninja hours that ended (rotation.js)
require('./schema')(db);
require('./consumption').ensure(db); // gold-spending log (trigger) for the spending event
dbm.indexes(db);

function parseBody(req) {
  return new Promise((res) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => { size += c.length; if (size <= 65536) chunks.push(c); }); // cap bodies at 64 KB
    req.on('end', () => res(Buffer.concat(chunks).toString('utf8')));
  });
}

// Simple flood guard: at most RATE_LIMIT requests per IP per 10 seconds (the game sends a few per screen).
const RATE = Number(process.env.RATE_LIMIT || 300);
const hits = new Map();
setInterval(() => hits.clear(), 10000).unref();
// Requests that come through the web server on the same machine (Caddy in front of the home page, tools/vps/wiki-site.sh) count per visitor:
// Caddy puts the visitor's address last in X-Forwarded-For. Only trusted from this machine itself.
const LOCAL = new Set(['127.0.0.1', '::1', '::ffff:127.0.0.1']);
function clientIp(req) {
  const ip = req.socket.remoteAddress || '?';
  const fwd = LOCAL.has(ip) && req.headers['x-forwarded-for'];
  return fwd ? String(fwd).split(',').pop().trim() || ip : ip;
}
function limited(req) {
  const ip = clientIp(req);
  const n = (hits.get(ip) || 0) + 1;
  hits.set(ip, n);
  return n > RATE;
}

// For the home page (ninjaonlinereborn.com) and /status: how many characters exist and how many played in the last 5 minutes. Counts only, no names.
let counted = { at: 0 };
function playerCounts() {
  if (Date.now() - counted.at < 30000) return counted.v;
  try {
    const has = db.prepare('SELECT 1 FROM players WHERE uid=? LIMIT 1');
    const online = settings.online().filter((o) => has.get(o.uid)).length; // start-up requests use placeholder ids: only real characters
    const players = db.prepare('SELECT COUNT(DISTINCT uid) n FROM players').get().n;
    counted = { at: Date.now(), v: { online, players } };
  } catch { counted = { at: Date.now(), v: {} }; }
  return counted.v;
}

require('./webapi').record(db, playerCounts); // players online every 5 minutes, for the website's graph (/api/online)

// Errors also go to logs/error.log so problems on a public server can be read later.
function logError(...a) {
  console.error(...a);
  try {
    require('fs').mkdirSync('logs', { recursive: true });
    require('fs').appendFileSync('logs/error.log', new Date().toISOString() + ' ' + a.map((x) => (x && x.stack) || String(x)).join(' ') + String.fromCharCode(10));
  } catch {}
}

const httpServer = http.createServer({ insecureHTTPParser: true }, async (req, resp) => {
  if (limited(req)) { resp.writeHead(429); return resp.end('slow down'); }
  const u = url.parse(req.url, true);
  // Hot-update files (see cdn/manifest.json and rl_r_version): plain static files, logged so downloads can be seen.
  if (u.pathname.startsWith('/cdn/')) {
    const fs = require('fs'), path = require('path');
    const file = path.join(__dirname, 'cdn', path.normalize(decodeURIComponent(u.pathname.slice(5))).replace(/^([.][.][\/])+/, ''));
    console.log(`[cdn] ${req.method} ${u.pathname} ${fs.existsSync(file) ? 'found' : 'MISSING'}`);
    if (!file.startsWith(path.join(__dirname, 'cdn')) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { resp.writeHead(404); return resp.end(); }
    resp.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Content-Length': fs.statSync(file).size });
    return fs.createReadStream(file).pipe(resp);
  }
  // The wiki (server/wiki, built by tools/build_wiki.js): static pages for everyone, no password
  if (u.pathname === '/wiki') { resp.writeHead(301, { Location: '/wiki/' }); return resp.end(); }
  if (u.pathname.startsWith('/wiki/')) return require('./wikiserve')(req, resp, u.pathname);
  if (u.pathname.endsWith('.do')) return require('./gumplogin').handle(req, resp, parseBody, db); // the APK's account window (gumplogin.js)
  if (u.pathname === '/status') { // version + start time, for the Discord #server-status watcher (discord/statuswatch.js)
    resp.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    return resp.end(JSON.stringify({ ok: true, version: VERSION, started: STARTED, ...playerCounts() }));
  }
  if (u.pathname.startsWith('/api/')) return require('./webapi').handle(req, resp, u, db); // public read-only data for the website (webapi.js)
  if (u.pathname === '/progress.md') { // the progress page (docs/PROGRESS.md), shown in the control panel's Progress tab
    resp.writeHead(200, { 'Content-Type': 'text/markdown; charset=utf-8', 'Cache-Control': 'no-store' });
    return resp.end(require('fs').readFileSync(require('path').join(__dirname, '..', 'docs', 'PROGRESS.md'), 'utf8'));
  }
  // HB_SITE_URL (cloud, tools/vps/run.sh; owner 10 Nov 2026: "I don't like the duckdns"): a browser opening the control panel or item page straight on
  // ninjaonline.duckdns.org:18080 is sent to the website, which passes them on here over https (tools/vps/wiki-site.sh). The game never asks for these pages.
  if (process.env.HB_SITE_URL && req.method === 'GET' && !LOCAL.has(req.socket.remoteAddress) && /^\/(panel|admin(\/playerlog|\/track)?|manager)?\/?$/.test(u.pathname)) {
    resp.writeHead(302, { Location: process.env.HB_SITE_URL + (u.pathname === '/' ? '/panel' : u.pathname) + (u.search || '') });
    return resp.end();
  }
  // Home-screen app for the control panel (owner, 12 Nov 2026: "an app for iPhone"): Safari > Share > Add to Home Screen opens /panel full screen.
  // Under /admin/ so the website (Caddy, /admin*) passes them on. No password: a picture and a name only.
  if (u.pathname === '/admin/app-icon.png') {
    resp.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=86400' });
    return resp.end(require('fs').readFileSync(require('path').join(__dirname, 'panel-icon.png')));
  }
  if (u.pathname === '/admin/app.webmanifest') {
    resp.writeHead(200, { 'Content-Type': 'application/manifest+json', 'Cache-Control': 'no-cache' });
    return resp.end(JSON.stringify({ name: 'Hello Bro Control Panel', short_name: 'HB Panel', start_url: '/panel', scope: '/', display: 'standalone',
      background_color: '#0b0a14', theme_color: '#0b0a14', icons: [{ src: '/admin/app-icon.png', sizes: '512x512', type: 'image/png', purpose: 'any' }] }));
  }
  if (u.pathname === '/admin/login') return admin.login(req, resp, parseBody); // the password page (admin.js): sets the login cookie
  if (u.pathname === '/' || u.pathname === '/panel') { // the control panel
    if (!admin.authorized(req)) return admin.deny(req, resp);
    return admin.panel(resp, 'server');
  }
  if (u.pathname === '/manager' || u.pathname.startsWith('/manager/')) {
    try { return await manager(req, resp, u, db, parseBody); } catch (e) { logError('manager error', e); resp.writeHead(500); return resp.end('error'); }
  }
  if (u.pathname === '/admin/sitestats') { // website visitors (sitestats.js): the owner only, like the control panel
    if (!admin.authorized(req)) return admin.deny(req, resp);
    try { return require('./sitestats').page(req, resp, u, db); } catch (e) { logError('sitestats error', e); resp.writeHead(500); return resp.end('error'); }
  }
  if (u.pathname.startsWith('/admin')) {
    if (req.method === 'POST') require('./tracker').panelUsed(); // changes the tracker sees next are labelled "item page / control panel"
    try { return await admin(req, resp, u, db, parseBody); } catch (e) { logError('admin error', e); resp.writeHead(500); return resp.end('error'); }
  }
  const body = req.method === 'POST' ? await parseBody(req) : '';
  const params = { ...u.query, ...Object.fromEntries(new URLSearchParams(body)) };
  // one world only (HB_ONE_WORLD=1, see handlers.js servers): a phone that still remembers a starter slot plays on Konoha (main)
  if (process.env.HB_ONE_WORLD === '1' && params.ServerID && params.ServerID !== '1') params.ServerID = '1';
  const cgi = u.pathname.replace(/^\/+/, '');
  const h = handlers[cgi];
  settings.hit(params.Uid, cgi);
  let out;
  const t0 = Date.now();
  const tracker = require('./tracker');
  tracker.begin(db, params, cgi); // progress tracker for the accounts in track_uids (tracker.js): snapshot before, differences after
  try {
    out = h ? h({ db, params, cgi, host: req.headers.host }) : null;
  } catch (e) {
    logError('handler error', cgi, e);
    out = null;
  }
  tracker.end();
  if (out == null) {
    console.log(`\x1b[33m[UNHANDLED] ${req.method} ${req.url} ${body}\x1b[0m`);
    out = '<root code="1"><message>not implemented</message></root>';
  } else {
    console.log(`\x1b[90m[ok] ${cgi} Cmd=${params.Cmd || ''} ${Date.now() - t0} ms ${(out.length / 1024).toFixed(1)} KB\x1b[0m`); // grey: game requests
  }
  out = require('./errcodes').fix(out); // code 5 = "energy level is full" in the game's own texts: use a fitting code
  resp.writeHead(200, { 'Content-Type': 'text/xml; charset=utf-8' });
  // The Lua side looks for a <RENLONG> root; the C++ side accepts any root name.
  out = out.replace(/^<root/, '<RENLONG').replace(/<\/root>$/, '</RENLONG>');
  // Dev aid: HB_REPLY_LOG=<file> keeps every request + full reply (the emulator log cuts long replies at ~4 KB)
  if (process.env.HB_REPLY_LOG) require('fs').appendFile(process.env.HB_REPLY_LOG, `${new Date().toISOString()} ${cgi} ${req.url.split("?")[1] || ""} ${body}\n${out}\n\n`, () => {});
  resp.end('<?xml version="1.0" encoding="UTF-8"?>' + out);
});

// The game's Lua code puts raw spaces in request URLs ("Clinettime=2026/10/29 05:42:45 Thursday"),
// which Node's strict parser rejects. Percent-encode them in the request line before parsing.
net.createServer((sock) => {
  // A connection cut before it sends anything (browsers open spare connections and drop them, scanners too) emits 'error'.
  // Without a listener from the very start that error stopped the whole server (public server, 3 times on 4 Nov 2026).
  sock.on('error', () => {});
  // A connection that never sends anything is closed after 2 minutes instead of being kept open for ever.
  sock.setTimeout(120000, () => sock.destroy());
  sock.once('data', (chunk) => {
    sock.setTimeout(0);
    const eol = chunk.indexOf('\r\n');
    if (eol > 0) {
      const line = chunk.subarray(0, eol).toString('latin1');
      const a = line.indexOf(' ');
      const b = line.lastIndexOf(' ');
      if (a > 0 && b > a) {
        const fixed = line.slice(0, a + 1) + line.slice(a + 1, b).replace(/ /g, '%20') + line.slice(b);
        chunk = Buffer.concat([Buffer.from(fixed, 'latin1'), chunk.subarray(eol)]);
      }
    }
    sock.unshift(chunk);
    httpServer.emit('connection', sock);
  });
}).on('error', (e) => console.error('listen error', e.message)).listen(PORT, '0.0.0.0', () => {
  manager.banner(PORT, db);
  // always-on server (tools/vps/run.sh): a separate process restarts this one when it stops answering (watchdog.js)
  if (process.env.HB_WATCHDOG === '1') require('child_process').fork(require('path').join(__dirname, 'watchdog.js'), [], { env: { ...process.env, PORT: String(PORT) } });
});
