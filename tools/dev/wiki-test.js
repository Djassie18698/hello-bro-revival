// The wiki (server/wiki, served at /wiki/ by server/wikiserve.js): the data file is complete and every link and picture in it points at
// something that exists, and the file server only hands out files from server/wiki (no ../, no encoded ../, GET/HEAD only).
// Also the home page (server/site, https://ninjaonlinereborn.com): home.json matches the wiki data, every picture it uses exists. Run by check.sh.
const http = require('http'), fs = require('fs'), path = require('path');
const serve = require('../../server/wikiserve');
const playServe = serve.dir(path.join(__dirname, '..', '..', 'server', 'webclient'), '/play/'); // the web client (server.js /play/)
const W = path.join(__dirname, '..', '..', 'server', 'wiki');
let bad = 0;
const ck = (ok, what) => { if (!ok) { bad++; console.log('WIKI:', what); } };

// ---- the website's live data (server/webapi.js, /api/* through Caddy) and its site files ----------------------------------------
{
  const { DatabaseSync } = require('node:sqlite');
  const db = new DatabaseSync(':memory:');
  require('../../server/schema')(db);
  const handlers = require('../../server/handlers');
  const game = require('../../server/game');
  const web = require('../../server/webapi');
  const p = (uid, extra) => ({ Uid: String(uid), Session: 'web' + uid, ServerID: '1', GroupID: '2', ...extra });
  handlers.rl_w_login2({ db, params: p(70001), host: 'localhost', method: 'POST', body: '' });
  handlers.rl_w_reg2({ db, params: p(70001, { Nick: 'Webby', Card: 1 }), host: 'localhost', method: 'POST', body: '' });
  require('../../server/specialnames').set(db, 70001, 'Webby', 'ffd23f', 'sparkle');
  const top = web.top(db).top;
  ck(top.length === 1 && top[0].name === 'Webby' && top[0].rank === 1 && top[0].atk[1] > 0, 'api top: ' + JSON.stringify(top));
  ck(top[0] && top[0].glow && top[0].glow.color === 'ffd23f' && top[0].glow.effect === 'sparkle', 'api top: the glowing name is missing');
  const pl = web.player(db, 'webby');
  ck(pl && pl.name === 'Webby' && pl.team.length >= 1 && pl.vip >= 0 && pl.vip <= 18 && pl.rank === 1, 'api player: ' + JSON.stringify(pl));
  ck(web.player(db, '') === null && web.player(db, 'nobody here') === null, 'api player: an unknown name must give nothing');
  // two characters with the same name: each gets its own page (?n=2), the list links them apart
  handlers.rl_w_login2({ db, params: p(70002), host: 'localhost', method: 'POST', body: '' });
  handlers.rl_w_reg2({ db, params: p(70002, { Nick: 'Webby2', Card: 1 }), host: 'localhost', method: 'POST', body: '' });
  db.prepare("UPDATE players SET nick='Twin', level=1 WHERE uid=70002").run();
  handlers.rl_w_login2({ db, params: p(70003), host: 'localhost', method: 'POST', body: '' });
  handlers.rl_w_reg2({ db, params: p(70003, { Nick: 'Twin3', Card: 1 }), host: 'localhost', method: 'POST', body: '' });
  db.prepare("UPDATE players SET nick='twin', level=7 WHERE uid=70003").run();
  const t1 = web.player(db, 'Twin', 1), t2 = web.player(db, 'Twin', 2);
  ck(t1 && t2 && t1.level === 7 && t2.level === 1 && web.player(db, 'Twin', 3) === null, 'api player: same-named characters are mixed up');
  // where the power comes from: the parts add up exactly to the team numbers
  for (const side of ['atk', 'def']) { const sum = (pl.from[side] || []).reduce((a, x) => [a[0] + x.v[0], a[1] + x.v[1]], [0, 0]);
    ck(sum[0] === pl[side][0] && sum[1] === pl[side][1] && !(pl.from[side] || []).some((x) => x.key === 'other'), `api player: the ${side} parts ${sum} do not add up to ${pl[side]}`); }
  const priv = JSON.stringify([web.top(db), pl, web.today(db)]);
  ck(!/"(uid|account|session|device|email|password|ip)"/i.test(priv) && !/70001/.test(priv), 'api: private fields leak: ' + priv.slice(0, 200));
  const t = web.today(db);
  ck(t.god && t.god.id && t.ramen.length && t.energyRefill === 22 && Array.isArray(t.running), 'api today: ' + JSON.stringify(t).slice(0, 200));
  // this week's event rotation on the home page: 7 days, every day has events, Shard Rush on days 4 and 7, the all-week ones listed once
  const wk = t.week;
  ck(wk && wk.days.length === 7 && wk.day >= 1 && wk.day <= 7 && wk.days.every((d) => d.events.length) && wk.allWeek.includes('Month card') &&
    wk.days.filter((d) => d.shardRush).map((d) => d.day).join() === '4,7' && wk.superNinja && wk.superNinja.length === 2, 'api today week: ' + JSON.stringify(wk).slice(0, 300));
  ck(fs.readFileSync(path.join(W, '..', 'site', 'index.html'), 'utf8').includes('id="days"'), 'home page has the week of events');
  // calculator = the game's own team maths for the same picks
  const calc = web.calc('n2106.50.3.6.2,e1.50,m5,j48|n57.40');
  const ref = game.teamSlots([{ seq: 1, ninja_id: 2106, level: 50, breaklvl: 3, starlevel: 6, attri: 2, newlife: 0 }, { seq: 2, ninja_id: 57, level: 40, breaklvl: 0, starlevel: 0, attri: 1, newlife: 0 }],
    [{ slot: 1, seq: 0, ninja_id: 1, type: 2, level: 50, newlife: 0 }, { slot: 1, seq: 0, ninja_id: 5, type: 5 }, { slot: 1, seq: 0, ninja_id: 48, type: 6 }], null);
  ck(calc.slots.length === 2 && calc.slots[0].atk[0] === Math.round(ref[0].al) && calc.slots[1].def[1] === Math.round(ref[1].dh) && calc.total.atk[0] === Math.round(ref[0].al) + Math.round(ref[1].al),
    'api calc differs from game.teamSlots: ' + JSON.stringify(calc.total));
  for (const junk of ['', '|||', 'n999999.50', 'nabc', 'x1,y2', 'n2106.99999.99.99.99.99', Array(60).fill('n57.1').join('|'), 'n57,e1,e1,e1,e1,e1,j48,j48,j48,j48,j48,m5,m5']) {
    let r = null; try { r = web.calc(junk); } catch (e) { r = null; }
    ck(r && r.slots.length <= 26 && r.slots.every((x) => x.level <= game.cardMaxLevel(1)), 'api calc does not cope with ' + junk.slice(0, 40));
  }
  // the HTTP route: GET only, JSON, unknown paths 404
  const call = (method, url) => { let code = 0, body = '', head = {}; const resp = { writeHead: (c, h) => { code = c; head = h; }, end: (b) => { body = b || ''; } };
    web.handle({ method }, resp, require('url').parse(url, true), db); return { code, body, head }; };
  const g = call('GET', '/api/top');
  ck(g.code === 200 && /application\/json/.test(g.head['Content-Type']) && JSON.parse(g.body).top, 'GET /api/top gave ' + g.code);
  ck(call('POST', '/api/top').code === 405, 'POST /api/top must be refused');
  ck(call('GET', '/api/nothing').code === 404 && call('GET', '/api/player?name=zzz').code === 404, '/api unknown should be 404');
  ck(call('GET', '/api/online?days=7').code === 200, 'GET /api/online gave an error');
  // the browser game's start report (webclient/emu/main.js): one log line, control characters and long text cut, nothing private
  { const keep = console.log, lines = []; console.log = (s) => lines.push(String(s));
    try { call('GET', '/api/emulog?k=black&s=running%0Afake&e=' + 'x'.repeat(900) + '&g=Mali-G720&u=Chrome'); call('GET', '/api/emulog?s=no-kind'); } finally { console.log = keep; }
    ck(lines.length === 1 && /^\[emu\] black \| running fake \|/.test(lines[0]) && lines[0].includes('Mali-G720') && !lines[0].includes('\n') && lines[0].length < 900, '/api/emulog: ' + JSON.stringify(lines).slice(0, 200)); }
  // the home page shows the browser game (owner, 13 Nov 2026: "why is the site not updated with the online emulator?")
  ck((fs.readFileSync(path.join(W, '..', 'site', 'index.html'), 'utf8').match(/href="\/play\/emu\/"/g) || []).length >= 3, 'the home page lost its Play in browser buttons');
  db.close();
  // site files: short links in the Caddy script, search-engine files, the player page and live script, the calculator in the wiki
  const site = (n) => fs.readFileSync(path.join(__dirname, '..', '..', 'server', 'site', n), 'utf8');
  const caddy = fs.readFileSync(path.join(__dirname, '..', 'vps', 'wiki-site.sh'), 'utf8');
  for (const l of ['/discord', '/download', '/install', '/play']) ck(new RegExp('@\\w+ path ' + l + ' ').test(caddy), 'short link ' + l + ' is missing in wiki-site.sh');
  ck(/handle \/api\/\* \{\s*reverse_proxy 127\.0\.0\.1:18080/.test(caddy) && /rewrite \* \/p\.html/.test(caddy), 'wiki-site.sh lost the /api or /p/ route');
  ck(/Sitemap: https:\/\/ninjaonlinereborn\.com\/sitemap\.xml/.test(site('robots.txt')) && /Disallow: \/api\//.test(site('robots.txt')), 'robots.txt is incomplete');
  ck(/<loc>https:\/\/ninjaonlinereborn\.com\/wiki\/<\/loc>/.test(site('sitemap.xml')), 'sitemap.xml lacks the wiki');
  ck(!/naruto|konoha/i.test((site('index.html').match(/<title>[^<]*<\/title>/) || [''])[0]), 'the home page title must not say Naruto or Konoha');
  ck(/id="player"/.test(site('p.html')) && /src="\/live\.js"/.test(site('p.html')) && /src="live\.js"/.test(site('index.html')) && /id="top10"/.test(site('index.html')), 'player page or live section is missing');
  for (let n = 0; n <= 18; n++) ck(fs.existsSync(path.join(__dirname, '..', '..', 'server', 'site', 'img', 'ui', 'vip-' + n + '.webp')), 'VIP badge ' + n + ' is missing');
  ck(/calcPage\(q\)/.test(fs.readFileSync(path.join(W, 'app.js'), 'utf8')), 'the wiki lost its team calculator');
  // one real page per entry for search engines (tools/wiki_pages.js): all there, in the sitemap, own title/canonical, no Naruto/Konoha in titles
  const sm = site('sitemap.xml');
  const dirs = ['shinobi', 'gear', 'ninjutsu', 'seals', 'pets', 'items', 'training', 'guide'];
  const files = dirs.flatMap((d) => (fs.existsSync(path.join(W, d)) ? fs.readdirSync(path.join(W, d)).map((x) => d + '/' + x) : []));
  const DD = JSON.parse(fs.readFileSync(path.join(W, 'data.json'), 'utf8'));
  const want = DD.shinobi.length + DD.gear.length + DD.jutsu.length + DD.seals.filter((x) => !x.fragment).length + DD.pets.length + DD.items.length + DD.chapters.length + DD.guides.length;
  ck(files.length === want, 'wiki pages: ' + files.length + ', expected ' + want);
  for (const rel of files) {
    const h = fs.readFileSync(path.join(W, rel), 'utf8');
    const title = (h.match(/<title>([^<]*)<\/title>/) || [])[1] || '', desc = (h.match(/<meta name="description" content="([^"]*)"/) || [])[1] || '';
    ck(title && !/naruto|konoha/i.test(title + desc), rel + ': title or description says Naruto / Konoha: ' + title);
    ck(h.includes('<link rel="canonical" href="https://ninjaonlinereborn.com/wiki/' + rel + '">') && h.includes('<base href="/wiki/">') && /<main id="main"><nav class="crumbs"/.test(h), rel + ': canonical, base or content missing');
    ck(sm.includes('<loc>https://ninjaonlinereborn.com/wiki/' + rel + '</loc>'), rel + ' is not in sitemap.xml');
  }
  ck(fs.readFileSync(path.join(W, 'app.js'), 'utf8').includes("(own ? `${own[1]}/${own[2]}` : '')"), 'app.js no longer opens an entry from its own page address');
  ck(fs.existsSync(path.join(__dirname, '..', '..', 'server', 'site', 'img', 'og.jpg')) && site('index.html').includes('og:image" content="https://ninjaonlinereborn.com/img/og.jpg"'), 'share picture og.jpg missing');
  ck(site('index.html').includes('"@type":"FAQPage"') && site('index.html').includes('id="faq"'), 'home page questions part missing');
  // search pages (tools/site_pages.js): there, own title + canonical, no Naruto/Konoha, in the sitemap, linked from the footer
  for (const d of require('../site_pages').PAGES) {
    const h = site(d + '/index.html');
    const title = (h.match(/<title>([^<]*)<\/title>/) || [])[1] || '';
    ck(title && !/naruto|konoha/i.test(title) && h.includes('<link rel="canonical" href="https://ninjaonlinereborn.com/' + d + '/">'), d + ': title or canonical wrong');
    ck(sm.includes('<loc>https://ninjaonlinereborn.com/' + d + '/</loc>') && site('index.html').includes('href="/' + d + '/"'), d + ' is not in the sitemap or the footer');
    ck(!/<use href="\/#/.test(h) && h.includes('src="/site.js"'), d + ': broken icon or script address');
  }
  ck(!/<use href="\/#/.test(site('p.html')) && site('p.html').includes('src="/live.js"') && site('p.html').includes('noindex'), 'p.html: broken icons, script or robots tag');
  // website visitor counter (server/sitestats.js): robots skipped, reloads not counted twice, no address stored
  {
    const { DatabaseSync } = require('node:sqlite');
    const db2 = new DatabaseSync(':memory:');
    const st = require('../../server/sitestats');
    const req = (ua, ip = '203.0.113.9') => ({ headers: { 'user-agent': ua }, socket: { remoteAddress: ip } });
    ck(st.record(db2, req('Mozilla/5.0 (Linux; Android 14) Mobile'), { p: '/hello-bro-apk/', r: 'https://www.google.com/search?q=x' }) === true, 'sitestats: a real visit was not counted');
    ck(st.record(db2, req('Mozilla/5.0 (Linux; Android 14) Mobile'), { p: '/hello-bro-apk/', r: '' }) === false, 'sitestats: a reload counted twice');
    ck(st.record(db2, req('Mozilla/5.0 (compatible; Googlebot/2.1)'), { p: '/' }) === false && st.record(db2, req(''), { p: '/' }) === false, 'sitestats: robots are counted');
    st.record(db2, req('Mozilla/5.0 (Windows NT 10.0)', '198.51.100.7'), { p: '/wiki/#/shinobi/5', r: 'https://ninjaonlinereborn.com/' });
    const sum = st.summary(db2, 30);
    ck(sum.today.v === 2 && sum.today.n === 2 && sum.sources.some((x) => x.k === 'google.com') && !sum.sources.some((x) => x.k === 'own'), 'sitestats summary: ' + JSON.stringify(sum.today) + ' ' + JSON.stringify(sum.sources));
    const rows = JSON.stringify(db2.prepare('SELECT * FROM web_hits').all());
    ck(!/203\.0\.113|198\.51\.100|Mozilla/.test(rows), 'sitestats stores an address or browser name: ' + rows);
    let out = ''; st.page({}, { writeHead() {}, end(b) { out = b; } }, { query: {} }, db2);
    ck(/Website visitors/.test(out) && /google\.com/.test(out), 'sitestats page does not render');
    db2.close();
  }
}

// ---- the data ----------------------------------------------------------------------------------------------------------------
{
  const r = require('child_process').spawnSync(process.execPath, [path.join(__dirname, '..', 'build_wiki.js'), '--check'], { encoding: 'utf8' });
  ck(r.status === 0, (r.stdout || r.stderr || '').trim() || 'build_wiki.js --check failed');
}
const D = JSON.parse(fs.readFileSync(path.join(W, 'data.json'), 'utf8'));
for (const k of ['shinobi', 'gear', 'jutsu', 'seals', 'pets', 'items', 'sets', 'chapters', 'guides']) ck(Array.isArray(D[k]) && D[k].length > 0, `data.json has no ${k}`);
for (const [k, s] of Object.entries(D.icons.sheets)) ck(fs.existsSync(path.join(W, 'img', s.file.split('?')[0])), `icon sheet ${k} (${s.file}) is missing`);
const ids = Object.fromEntries(['shinobi', 'gear', 'jutsu', 'seals', 'pets', 'items'].map((k) => [k, new Set(D[k].map((e) => e.id))]));
const iconOk = (ref) => !ref || (() => { const [k, n] = ref.split(':'); const s = D.icons.sheets[k]; return s && Number(n) >= 0 && Number(n) < s.count; })();
for (const k of Object.keys(ids)) for (const e of D[k]) ck(iconOk(e.icon), `${k} ${e.id} has a bad icon ${e.icon}`);
for (const c of D.shinobi) {
  for (const ch of c.chains || []) {
    for (const g of ch.partners || []) for (const id of g) ck(ids.shinobi.has(id), `chain of ${c.name} links missing card ${id}`);
    if (ch.gear) ck(ids.gear.has(ch.gear), `chain of ${c.name} links missing gear ${ch.gear}`);
  }
  for (const id of c.partOf || []) ck(ids.shinobi.has(id), `${c.name} partOf missing card ${id}`);
  if (c.jutsu) ck(ids.jutsu.has(c.jutsu), `${c.name} has missing ninjutsu ${c.jutsu}`);
}
for (const s of D.sets) for (const p of s.pieces) ck(ids[p.kind === 'jutsu' ? 'jutsu' : p.kind === 'seal' ? 'seals' : 'gear'].has(p.id), `set ${s.name} lists missing ${p.kind} ${p.id}`);
const WHAT = { card: 'shinobi', gear: 'gear', jutsu: 'jutsu', seal: 'seals', item: 'items', pet: 'pets', fragment: 'shinobi' };
for (const c of D.chapters) for (const p of c.parts) for (const r of p.rounds) {
  if (r.reward) ck(ids[WHAT[r.reward.what]] && ids[WHAT[r.reward.what]].has(r.reward.id), `stage ${r.name} reward ${r.reward.what} ${r.reward.id} is missing`);
  for (const f of r.foes) ck(iconOk(f.icon), `stage ${r.name} enemy ${f.name} has a bad icon`);
}
ck(D.shinobi.find((c) => c.id === 2106 && (c.get || []).some((w) => w.how === 'Fragments')), 'Kyuubi Naruto (God) should list Fragments as a way to get it');
// Development Dan (owner, 11 Nov 2026: the wiki only listed the Shop): the arena shop, sign-in, Akatsuki mall and event gifts too
{
  const dd = D.items.find((i) => i.id === 34), hows = new Set(((dd && dd.get) || []).map((w) => w.how.replace(/ \(x\d+\)$/, '')));
  for (const h of ['Shop', 'Arena shop', 'Monthly sign-in', 'Akatsuki mall', 'Gold spending gift', 'Top-up gift', 'Hot Treasure']) ck(hows.has(h), `Development Dan should list "${h}" as a way to get it`);
  // God evolve (owner, 11 Nov 2026: "cant find anything about evolve on the wiki"): its use on the pill, the way on the god cards, a guide chapter
  ck(hows.has('Used for'), 'Development Dan should say it is used for God evolve');
  const evo = D.shinobi.filter((c) => (c.get || []).some((w) => w.how === 'God evolve'));
  ck(evo.length >= 60 && evo.every((c) => c.stars >= 6), `God evolve should be listed on the god cards (${evo.length})`);
  ck(D.guides.some((g) => /evolve/i.test(g.title)), 'a guide chapter about evolve should exist (the wiki search finds guide titles)');
}

// ---- the home page ------------------------------------------------------------------------------------------------------------
{
  const S = path.join(__dirname, '..', '..', 'server', 'site');
  const H = JSON.parse(fs.readFileSync(path.join(S, 'home.json'), 'utf8')); // up to date with the wiki: build_wiki.js --check above
  ck(H.hero.length === 5 && H.featured.length >= 8 && H.chapters.length === D.chapters.length && H.news.length > 0, 'home.json is missing parts');
  ck(H.counts.shinobi === D.shinobi.length, 'home.json counts differ from the wiki');
  const pics = new Set();
  for (const c of H.hero.concat(H.featured)) { pics.add('img/art/' + c.art + '.webp'); ck(ids.shinobi.has(c.id), `home page card ${c.id} is not in the wiki`); }
  for (const c of H.chapters) pics.add(`img/ch-${c.id}.webp`);
  const html = fs.readFileSync(path.join(S, 'index.html'), 'utf8'), css = fs.readFileSync(path.join(S, 'site.css'), 'utf8');
  for (const m of html.matchAll(/src="(img\/[^"]+)"/g)) pics.add(m[1]);
  for (const m of css.matchAll(/url\((img\/[^)]+)\)/g)) pics.add(m[1]);
  for (const p of pics) ck(fs.existsSync(path.join(S, p)), `home page picture ${p} is missing (python -I tools/build_site_art.py)`);
  const SITES = /^https:\/\/(fonts\.googleapis\.com|fonts\.gstatic\.com|discord\.gg|github\.com|www\.patreon\.com|ninjaonlinereborn\.com)$/;
  for (const m of html.matchAll(/(?:href|src|content)="(https?:\/\/[^"/]+)/g)) ck(SITES.test(m[1]), `home page links to an unexpected site: ${m[1]}`);
  for (const m of html.matchAll(/href="\/wiki\/#\/guides\/([a-z-]+)"/g)) ck(D.guides.some((g) => g.file === m[1]), `home page links a wiki guide that does not exist: ${m[1]}`);
  ck(html.includes("if (location.hash.indexOf('#/') === 0) location.replace('/wiki/' + location.hash);"), 'home page lost the redirect of old wiki links (/#/shinobi/... -> /wiki/#/...)');
}

// ---- the file server ----------------------------------------------------------------------------------------------------------
const srv = http.createServer((req, resp) => {
  const p = req.url.split('?')[0];
  if (p.startsWith('/wiki/')) return serve(req, resp, p);
  if (p.startsWith('/play/')) return playServe(req, resp, p);
  resp.writeHead(404); resp.end();
}).listen(0, '127.0.0.1', async () => {
  const port = srv.address().port;
  const get = (p, opts = {}) => new Promise((ok) => {
    const q = http.request({ host: '127.0.0.1', port, path: p, method: opts.method || 'GET', headers: opts.headers || {} }, (r) => {
      const chunks = []; r.on('data', (d) => chunks.push(d)); r.on('end', () => ok({ code: r.statusCode, h: r.headers, body: Buffer.concat(chunks) }));
    });
    q.on('error', () => ok({ code: 0, h: {}, body: Buffer.alloc(0) }));
    q.end();
  });
  const idx = await get('/wiki/');
  ck(idx.code === 200 && /Ninja Online Wiki/.test(idx.body) && /text\/html/.test(idx.h['content-type']), `/wiki/ gave ${idx.code}`);
  const dz = await get('/wiki/data.json', { headers: { 'Accept-Encoding': 'gzip' } });
  ck(dz.code === 200 && dz.h['content-encoding'] === 'gzip', `/wiki/data.json gzip gave ${dz.code} ${dz.h['content-encoding']}`);
  const again = await get('/wiki/data.json', { headers: { 'If-None-Match': dz.h.etag } });
  ck(again.code === 304, `unchanged data.json should answer 304, got ${again.code}`);
  for (const p of ['/wiki/../server.js', '/wiki/..%2fserver.js', '/wiki/%2e%2e/%2e%2e/server/server.js', '/wiki/..%5cserver.js', '/wiki/img/icons.json', '/wiki/nothing.html', '/wiki/%E0%A4%A']) {
    const r = await get(p);
    ck(r.code === 404 || r.code === 400, `${p} should be refused, got ${r.code}`);
  }
  const post = await get('/wiki/', { method: 'POST' });
  ck(post.code === 405, `POST /wiki/ should be 405, got ${post.code}`);
  // the web client (server/webclient at /play/, the same file server): its page and scripts, nothing outside its folder
  const play = await get('/play/');
  ck(play.code === 200 && /<canvas id="game">/.test(play.body), `/play/ gave ${play.code}`);
  for (const f of ['engine.js', 'lua.js', 'luabind.js', 'gamebind.js', 'net.js', 'data.js', 'bag.js', 'team.js', 'train.js', 'fight.js', 'game.js']) { const r = await get('/play/' + f); ck(r.code === 200 && /javascript/.test(r.h['content-type']), `/play/${f} gave ${r.code}`); }
  // the emulator page keeps the game's screen between 1.5 and 16:9 (taller = a black band on Home: iPhone home-screen app, buva 13 Nov 2026)
  const emuMain = await get('/play/emu/main.js');
  const fitSrc = (/const fit = \(\) => \{.*?return \[w, h\]; \};/.exec(emuMain.body) || [])[0];
  ck(fitSrc, '/play/emu/main.js: fit() not found');
  if (fitSrc) for (const [iw, ih] of [[390, 797], [390, 844], [390, 664], [432, 768], [1440, 900], [768, 1024]]) {
    const [w, h] = new Function('innerWidth', 'innerHeight', 'canvas', fitSrc + ' return fit();')(iw, ih, { style: {} });
    ck(h / w <= 1.79 && h / w >= 1.33 && w <= iw && h <= ih, `emulator screen for a ${iw}x${ih} window is ${w}x${h}`);
  }
  for (const p of ['/play/../server.js', '/play/..%2fhandlers.js', '/play/%2e%2e/wiki/index.html', '/play/..%5cserver.js']) {
    const r = await get(p);
    ck(r.code === 404 || r.code === 400, `${p} should be refused, got ${r.code}`);
  }
  srv.close();
  console.log(bad ? `${bad} wiki problem(s)` : `wiki OK (${D.shinobi.length} shinobi, ${D.gear.length} gear, ${D.guides.length} guides; file server refuses paths outside server/wiki)`);
  process.exit(bad ? 1 : 0);
});
