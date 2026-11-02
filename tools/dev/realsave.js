// Real-save check: every handler x Cmd for every player of a save, on a throwaway COPY (old data, column migrations).
// Usage: node tools/dev/realsave.js [save.db]   (default hellobro.db; the copy is deleted afterwards, the save is never written)
const fs = require('fs'), path = require('path'), { DatabaseSync } = require('node:sqlite');
const handlers = require('../../handlers');
const root = path.join(__dirname, '..', '..'), lua = path.join(root, 'reference', 'lua-scripts'), cmds = {};
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.lua') ? [path.join(d, e.name)] : []);
for (const f of walk(lua)) { const t = fs.readFileSync(f, 'utf8'); for (const m of t.matchAll(/GetUrlNormalHeader\([^,]*,\s*(\d+)\s*,\s*"([a-z_0-9]+)"\s*\)/g)) (cmds[m[2]] = cmds[m[2]] || new Set()).add(Number(m[1])); }
const os = require('os'), src = process.argv[2] || path.join(root, 'hellobro.db'), tmp = path.join(os.tmpdir(), 'hb-realsave-' + process.pid + '.db');
{ const live = new DatabaseSync(src, { readOnly: true }); live.exec(`VACUUM INTO '${tmp.replace(/'/g, "''")}'`); live.close(); } // a consistent copy, WAL included
const db = new DatabaseSync(tmp);
require('../../schema')(db);
const players = db.prepare('SELECT p.uid, p.server_id, a.session FROM players p JOIN accounts a ON a.uid=p.uid').all();
let bad = 0, n = 0; const seen = new Set();
const SAFE_SKIP = /^rl_w_(reg2|reset)|^xk_w_|admin/;
for (const pl of players) for (const name of Object.keys(handlers)) {
  if (SAFE_SKIP.test(name)) continue;
  for (const c of new Set([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...(cmds[name] || [])])) {
    n++;
    try { handlers[name]({ db, params: { Uid: String(pl.uid), Session: pl.session || 'x', ServerID: String(pl.server_id), GroupID: '2', Cmd: String(c), ToUid: String(players[0].uid), Id: '1' }, host: 'localhost', method: 'POST', body: '' }); }
    catch (e) { const k = name + ' ' + e.message.slice(0, 50); if (!seen.has(k)) { seen.add(k); bad++; console.log('CRASH', name, 'Cmd', c, 'uid', pl.uid, '->', e.message.split('\n')[0]); } }
  }
}
db.close(); try { fs.unlinkSync(tmp); } catch {}
console.log(players.length, 'players,', bad ? bad + ' crashes in ' + n : 'no crashes in ' + n + ' calls');
