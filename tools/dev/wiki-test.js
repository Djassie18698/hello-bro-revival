// The wiki (server/wiki, served at /wiki/ by server/wikiserve.js): the data file is complete and every link and picture in it points at
// something that exists, and the file server only hands out files from server/wiki (no ../, no encoded ../, GET/HEAD only).
// Also the home page (server/site, https://ninjaonlinereborn.com): home.json matches the wiki data, every picture it uses exists. Run by check.sh.
const http = require('http'), fs = require('fs'), path = require('path');
const serve = require('../../server/wikiserve');
const W = path.join(__dirname, '..', '..', 'server', 'wiki');
let bad = 0;
const ck = (ok, what) => { if (!ok) { bad++; console.log('WIKI:', what); } };

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
  const SITES = /^https:\/\/(fonts\.googleapis\.com|fonts\.gstatic\.com|discord\.gg|github\.com|ninjaonlinereborn\.com)$/;
  for (const m of html.matchAll(/(?:href|src|content)="(https?:\/\/[^"/]+)/g)) ck(SITES.test(m[1]), `home page links to an unexpected site: ${m[1]}`);
  for (const m of html.matchAll(/href="\/wiki\/#\/guides\/([a-z-]+)"/g)) ck(D.guides.some((g) => g.file === m[1]), `home page links a wiki guide that does not exist: ${m[1]}`);
  ck(html.includes("if (location.hash.indexOf('#/') === 0) location.replace('/wiki/' + location.hash);"), 'home page lost the redirect of old wiki links (/#/shinobi/... -> /wiki/#/...)');
}

// ---- the file server ----------------------------------------------------------------------------------------------------------
const srv = http.createServer((req, resp) => {
  const p = req.url.split('?')[0];
  if (p.startsWith('/wiki/')) return serve(req, resp, p);
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
  srv.close();
  console.log(bad ? `${bad} wiki problem(s)` : `wiki OK (${D.shinobi.length} shinobi, ${D.gear.length} gear, ${D.guides.length} guides; file server refuses paths outside server/wiki)`);
  process.exit(bad ? 1 : 0);
});
