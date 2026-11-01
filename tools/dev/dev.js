// Dev shortcuts for the test account on the dev server (port 18081), through the admin API. The game reads most of this at login:
// run `node tools/dev/dev.js relog` afterwards (restarts the game on the Claude emulator and taps START).
//   node tools/dev/dev.js level 80 | vip 5 | gold 1000 | coin 50000 | energy 50 | souls 1000 | renown 500   (gold/coin/energy/souls/renown ADD)
//   node tools/dev/dev.js item <prop_id> <count>     set the exact amount of an item (consumeinfo id, 9999 souls, 30000+ fragments)
//   node tools/dev/dev.js thing <cat> <id> [count]    give one admin-catalog entry (cat as `find` shows: ninja, equip, seal, ninjutsu, item ...)
//   node tools/dev/dev.js find <text> [cat]           search the admin catalog by name (cat: ninja, equip, ...)
//   node tools/dev/dev.js unlockall                   max level + every story stage cleared
//   node tools/dev/dev.js show                        the account's cards and items
//   node tools/dev/dev.js sql "UPDATE exam SET grade=5 WHERE uid=$UID"   one SQL statement on the dev save ($UID / $SID = test account)
//   node tools/dev/dev.js relog                       restart the game on the emulator and press START
// Account: HB_DEV_UID (uid:server) or the uid the dev server knows for tools/dev/emu.account (default 55501235:1).
const http = require('http');
const { execSync } = require('child_process');
const PORT = Number(process.env.PORT) || 18081;
const UID = process.env.HB_DEV_UID || '55501235:1';

function call(path, body) {
  return new Promise((ok, bad) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request({ host: '127.0.0.1', port: PORT, path, method: body ? 'POST' : 'GET', headers: data ? { 'Content-Type': 'application/json' } : {} }, (r) => {
      let s = ''; r.on('data', (c) => s += c); r.on('end', () => { try { ok(JSON.parse(s)); } catch { ok(s); } });
    });
    req.on('error', bad);
    if (data) req.write(data);
    req.end();
  });
}
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const [cmd, a, b] = process.argv.slice(2);
  const give = { level: 'level', vip: 'vip', gold: 'gold', coin: 'coin', silver: 'coin', energy: 'energy', souls: 'souls', renown: 'renown' };
  let out;
  if (give[cmd]) out = await call('/admin/api/give', { uid: UID, field: give[cmd], amount: Number(a) });
  else if (cmd === 'item') out = await call('/admin/api/setprop', { uid: UID, id: Number(a), count: Number(b) });
  else if (cmd === 'thing') out = await call('/admin/api/givething', { uid: UID, cat: a, id: Number(b), count: Number(process.argv[5]) || 1 });
  else if (cmd === 'unlockall') out = await call('/admin/api/unlockall', { uid: UID });
  else if (cmd === 'sql') { // dev save only: one statement, $UID / $SID replaced by the test account
    const { DatabaseSync } = require('node:sqlite');
    const db = new DatabaseSync(require('path').join(__dirname, '..', '..', process.env.DB || 'hellobro.db'));
    const [u, s] = UID.split(':');
    const q = a.replace(/\$UID/g, u).replace(/\$SID/g, s || '1');
    out = /^\s*select/i.test(q) ? db.prepare(q).all() : db.prepare(q).run();
  } else if (cmd === 'show') out = await call('/admin/api/inventory?uid=' + encodeURIComponent(UID));
  else if (cmd === 'find') {
    const cat = await call('/admin/api/catalog?q=' + encodeURIComponent(a || '') + (b ? '&cat=' + encodeURIComponent(b) : '')); // find <name> [cat]
    out = cat.items.slice(0, 30);
  } else if (cmd === 'relog') {
    const sh = (s) => execSync(s, { cwd: require('path').join(__dirname, '..', '..'), stdio: 'inherit' });
    sh('sh tools/dev/emu.sh restart'); await wait(22000);
    sh('sh tools/dev/emu.sh tap 540 1270'); await wait(10000);
    sh('sh tools/dev/emu.sh shot');
    return;
  } else { console.log(require('fs').readFileSync(__filename, 'utf8').split('\n').slice(0, 10).join('\n')); return; }
  console.log(typeof out === 'string' ? out.slice(0, 2000) : JSON.stringify(out, null, 1).slice(0, 4000));
})().catch((e) => { console.error('dev server not reachable on port ' + PORT + ' (bash tools/dev/restart.sh):', e.message); process.exit(1); });
