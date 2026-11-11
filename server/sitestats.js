// Website visitors (owner, 11 Nov 2026: "how can I see how many people visited"): our own counter, no outside service, no cookies.
// The pages of https://ninjaonlinereborn.com (site.js, the wiki's app.js) send GET /api/hit?p=<page>&r=<referrer> once per page view.
// Kept per view: the day, the page, the referring site (only its name), phone or computer, and a visitor code = a hash of the visitor's
// address + browser + the day + a secret salt: it changes every day, so nobody can be followed from day to day and no address is stored.
// Robots (search engines, link previews) are not counted. 120 days are kept. The owner sees it in the control panel tab 🌐 Website
// (/admin/sitestats, admin password; server.js routes it here).
const crypto = require('crypto');
const KEEP_DAYS = 120;
const ROBOT = /bot|crawl|spider|slurp|facebookexternalhit|whatsapp\/|curl|wget|python|node-fetch|headless|lighthouse|monitor/i; // Googlebot, Discordbot, TelegramBot ... all say "bot"
const OWN = /(^|\.)ninjaonlinereborn\.com$|(^|\.)ninjaonline\.duckdns\.org$|^127\.0\.0\.1$|^localhost$/i;

function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS web_hits (t INTEGER NOT NULL, day TEXT NOT NULL, visitor TEXT NOT NULL, path TEXT NOT NULL, ref TEXT NOT NULL, device TEXT NOT NULL)');
  db.exec('CREATE INDEX IF NOT EXISTS web_hits_day ON web_hits(day)');
  db.exec('CREATE TABLE IF NOT EXISTS server_settings (key TEXT PRIMARY KEY, value TEXT)');
}
let salt = null;
function saltOf(db) {
  if (salt) return salt;
  const r = db.prepare("SELECT value FROM server_settings WHERE key='web_salt'").get();
  salt = r ? JSON.parse(r.value) : crypto.randomBytes(16).toString('hex');
  if (!r) db.prepare("INSERT OR REPLACE INTO server_settings (key, value) VALUES ('web_salt', ?)").run(JSON.stringify(salt));
  return salt;
}
const dayOf = (t = Date.now()) => new Date(t).toISOString().slice(0, 10); // UTC day (the cloud machine's clock)
const LOCAL = new Set(['127.0.0.1', '::1', '::ffff:127.0.0.1']);
function addressOf(req) { // Caddy puts the visitor's address last in X-Forwarded-For (only trusted from this machine)
  const ip = (req.socket && req.socket.remoteAddress) || '?';
  const fwd = LOCAL.has(ip) && req.headers && req.headers['x-forwarded-for'];
  return fwd ? String(fwd).split(',').pop().trim() || ip : ip;
}
function cleanPath(p) {
  let s = String(p || '/').slice(0, 200);
  if (!s.startsWith('/')) s = '/' + s;
  s = s.replace(/[?#].*$/, (m) => (m.startsWith('#/') ? m.replace(/\?.*$/, '') : '')); // keep wiki routes (#/shinobi/5), drop queries
  return s.replace(/[^\w\-./#%~:]/g, '').slice(0, 120) || '/';
}
function refOf(r) {
  try { const h = new URL(String(r || '')).hostname.replace(/^www\./, '').toLowerCase(); return !h ? '' : OWN.test(h) ? 'own' : h.slice(0, 60); } catch { return ''; }
}
const seen = new Map(); // visitor|path -> time, so a reload within 30 minutes is not a new view
setInterval(() => { const old = Date.now() - 1800000; for (const [k, t] of seen) if (t < old) seen.delete(k); }, 600000).unref();

// GET /api/hit (webapi.js): one page view. Answers 204 either way.
function record(db, req, q) {
  const ua = String((req.headers && req.headers['user-agent']) || '');
  if (!ua || ROBOT.test(ua)) return false;
  ensure(db);
  const now = Date.now(), day = dayOf(now), path = cleanPath(q.p), ref = refOf(q.r);
  const visitor = crypto.createHash('sha256').update(saltOf(db) + '|' + addressOf(req) + '|' + ua + '|' + day).digest('hex').slice(0, 16);
  const key = visitor + '|' + path;
  if (seen.has(key) && now - seen.get(key) < 1800000) return false;
  seen.set(key, now);
  const device = /Mobi|Android|iPhone|iPad/i.test(ua) ? 'phone' : 'computer';
  db.prepare('INSERT INTO web_hits (t, day, visitor, path, ref, device) VALUES (?, ?, ?, ?, ?, ?)').run(Math.floor(now / 1000), day, visitor, path, ref, device); // ref 'own' = a click inside the website
  if (Math.random() < 0.01) db.prepare('DELETE FROM web_hits WHERE day < ?').run(dayOf(now - KEEP_DAYS * 86400000));
  return true;
}

// the numbers for the panel page
function summary(db, days = 30) {
  ensure(db);
  const since = dayOf(Date.now() - (days - 1) * 86400000), today = dayOf(), yesterday = dayOf(Date.now() - 86400000), week = dayOf(Date.now() - 6 * 86400000);
  const count = (from, to) => db.prepare('SELECT COUNT(DISTINCT day || visitor) v, COUNT(*) n FROM web_hits WHERE day >= ? AND day <= ?').get(from, to);
  const perDay = db.prepare('SELECT day, COUNT(DISTINCT visitor) v, COUNT(*) n FROM web_hits WHERE day >= ? GROUP BY day ORDER BY day').all(since);
  const top = (col, extra = '') => db.prepare(`SELECT ${col} k, COUNT(DISTINCT day || visitor) v, COUNT(*) n FROM web_hits WHERE day >= ? ${extra} GROUP BY ${col} ORDER BY v DESC, n DESC LIMIT 15`).all(since);
  return {
    today: count(today, today), yesterday: count(yesterday, yesterday), week: count(week, today), month: count(since, today), all: count('0000', '9999'),
    perDay, pages: top('path'), sources: top("CASE WHEN ref = '' THEN '(typed in, a bookmark or an app)' ELSE ref END", "AND ref <> 'own'"), devices: top('device'), days,
  };
}

const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const NICE = [[/^\/$/, 'Home page'], [/^\/wiki\/?$/, 'Wiki main page'], [/^\/wiki\/#\/calculator/, 'Team calculator'], [/^\/p\//, 'Player page: '], [/^\/hello-bro-apk/, 'Download page'],
  [/^\/hello-bro-private-server/, 'Private server page'], [/^\/ninja-online-game/, 'About the game page']];
const pageName = (p) => { for (const [re, n] of NICE) if (re.test(p)) return n.endsWith(': ') ? n + decodeURIComponent(p.slice(3)).slice(0, 30) : n; return p; };
function page(req, resp, u, db) {
  const s = summary(db, 30);
  const max = Math.max(1, ...s.perDay.map((d) => d.v));
  const byDay = new Map(s.perDay.map((d) => [d.day, d]));
  const days = [...Array(30).keys()].map((i) => dayOf(Date.now() - (29 - i) * 86400000));
  const bars = days.map((d, i) => { const r = byDay.get(d) || { v: 0, n: 0 }; const h = Math.round(r.v / max * 120);
    return `<g><rect x="${i * 20 + 4}" y="${140 - h}" width="14" height="${Math.max(h, 1)}" rx="2"><title>${d}: ${r.v} visitors, ${r.n} page views</title></rect>${i % 5 === 4 || i === 29 ? `<text x="${i * 20 + 11}" y="156">${d.slice(8)}/${d.slice(5, 7)}</text>` : ''}</g>`; }).join('');
  const list = (rows, name = (k) => esc(k)) => rows.length ? `<table>${rows.map((r) => `<tr><td>${name(r.k)}</td><td class="n">${r.v}</td><td class="n m">${r.n}</td></tr>`).join('')}</table>` : '<p class="m">Nothing yet.</p>';
  const card = (label, c) => `<div class="c"><b>${c.v}</b><span>${label}</span><small>${c.n} page views</small></div>`;
  const html = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Website visitors</title>
<style>body{margin:0;font:15px/1.5 system-ui,sans-serif;color:#e8eefc;background:${u.query.embed ? 'transparent' : '#0b1430'};padding:20px}h1{font-size:22px;margin:0 0 4px}h2{font-size:17px;margin:26px 0 8px}
.m{color:#9fb0d3}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-top:16px}.c{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.12);border-radius:12px;padding:12px 14px}
.c b{display:block;font-size:28px;color:#ffd23f}.c span{display:block;font-weight:700}.c small{color:#9fb0d3}svg{width:100%;max-width:620px;height:auto;display:block}rect{fill:#ffd23f}text{fill:#9fb0d3;font-size:10px;text-anchor:middle}
table{border-collapse:collapse;width:100%;max-width:620px}td{padding:6px 8px;border-bottom:1px solid rgba(255,255,255,.08);vertical-align:top;word-break:break-word}td.n{text-align:right;white-space:nowrap;font-variant-numeric:tabular-nums}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:0 30px}</style></head><body>
<h1>🌐 Website visitors</h1><p class="m">ninjaonlinereborn.com and its wiki. A visitor = one person (one phone or computer) on one day; robots and search engines are not counted. No cookies, no stored addresses. Days in UTC.</p>
<div class="cards">${card('today', s.today)}${card('yesterday', s.yesterday)}${card('last 7 days', s.week)}${card('last 30 days', s.month)}${card('since counting began', s.all)}</div>
<h2>Visitors per day (last 30 days)</h2><svg viewBox="0 0 614 160" role="img" aria-label="Visitors per day">${bars}</svg>
<div class="grid"><div><h2>Most visited pages <small class="m">(visitors · views)</small></h2>${list(s.pages, (k) => esc(pageName(k)))}</div>
<div><h2>Where they came from</h2>${list(s.sources)}<h2>Phone or computer</h2>${list(s.devices)}</div></div>
<p class="m" style="margin-top:24px">Searches on Google: Google Search Console → Prestaties (Performance) shows which search words found the site.</p></body></html>`;
  resp.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  resp.end(html);
}

module.exports = { record, summary, page, ensure, cleanPath, refOf };
