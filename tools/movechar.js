// Move one character to another world (server id) of the same login, e.g. a level-350 character that was made on "Starter slot 1"
// by accident to Konoha (main). Every table with a uid + server_id column is moved. It refuses when the login already has a
// character (or any row) in the target world, so nothing is ever overwritten.
// Usage: node tools/movechar.js <save.db> <uid> <from server id> <to server id>          (dry run: shows what would move)
//        node tools/movechar.js <save.db> <uid> <from> <to> apply                         (does it, in one transaction)
// Run it with the server stopped, or right after a backup; the server reads the save on every request, so no restart is needed.
const { DatabaseSync } = require('node:sqlite');
const [file, uidArg, fromArg, toArg, mode] = process.argv.slice(2);
const uid = Number(uidArg), from = Number(fromArg), to = Number(toArg);
if (!file || !(uid > 0) || !(from > 0) || !(to > 0) || from === to) { console.log('usage: node tools/movechar.js <save.db> <uid> <from> <to> [apply]'); process.exit(2); }
const db = new DatabaseSync(file);
db.exec('PRAGMA busy_timeout=5000');
// player column + world column: most tables use uid + server_id; cross-server uses sid, battle reports to_uid
const PAIRS = [['uid', 'server_id'], ['uid', 'sid'], ['to_uid', 'server_id']];
const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all().map((t) => t.name).flatMap((t) => {
  const c = db.prepare(`PRAGMA table_info("${t}")`).all().map((x) => x.name);
  return PAIRS.filter(([u, w]) => c.includes(u) && c.includes(w)).map(([u, w]) => ({ t, u, w }));
});
const count = (x, sid) => db.prepare(`SELECT COUNT(*) n FROM "${x.t}" WHERE ${x.u}=? AND ${x.w}=?`).get(uid, sid).n;
const pl = db.prepare('SELECT nick, level FROM players WHERE uid=? AND server_id=?').get(uid, from);
if (!pl) { console.log(`no character for login ${uid} in world ${from}`); process.exit(1); }
const moving = tables.map((x) => ({ ...x, n: count(x, from), there: count(x, to) })).filter((r) => r.n || r.there);
const clash = moving.filter((r) => r.there && r.u === 'uid');
console.log(`${pl.nick} (level ${pl.level}), login ${uid}: world ${from} -> ${to}`);
for (const r of moving) console.log(`  ${r.t}: ${r.n} rows${r.there ? `   (already ${r.there} in world ${to}!)` : ''}`);
if (clash.length) { console.log(`refused: login ${uid} already has rows in world ${to} (${clash.map((r) => r.t).join(', ')})`); process.exit(1); }
// Akatsuki groups belong to one world: a group whose ONLY member is this character moves along (its buildings and log are keyed
// by group id); any other group membership is refused (leave or hand it over first).
const hasGroups = db.prepare("SELECT name FROM sqlite_master WHERE name='group_members'").get();
const mine = hasGroups && db.prepare('SELECT g.id, g.name, (SELECT COUNT(*) FROM group_members m WHERE m.group_id=g.id) n FROM group_members gm JOIN groups g ON g.id=gm.group_id WHERE gm.uid=? AND gm.server_id=?').get(uid, from);
const ledOther = hasGroups && db.prepare('SELECT name FROM groups WHERE leader_uid=? AND server_id=? AND id<>?').get(uid, from, mine ? mine.id : -1);
if (ledOther || (mine && mine.n > 1)) { console.log(`refused: ${pl.nick} is in the Akatsuki group "${(ledOther || mine).name}" with other players in world ${from}; leave it or hand it over first`); process.exit(1); }
if (mine && db.prepare('SELECT 1 FROM groups WHERE server_id=? AND name=?').get(to, mine.name)) { console.log(`refused: world ${to} already has a group named "${mine.name}"`); process.exit(1); }
if (mine) console.log(`  (the Akatsuki group "${mine.name}" moves along: ${pl.nick} is its only member)`);
// an official seat belongs to that world's country: given up, not moved (it could clash with a seat holder in the new world)
const seatOff = moving.find((r) => r.t === 'officials' && r.n);
if (seatOff) console.log('  (the official seat is given up, not moved)');
if (mode !== 'apply') { console.log('dry run: add "apply" to move it'); process.exit(0); }
db.exec('BEGIN IMMEDIATE');
try {
  if (mine) db.prepare('UPDATE groups SET server_id=? WHERE id=?').run(to, mine.id);
  if (seatOff) db.prepare('DELETE FROM officials WHERE uid=? AND server_id=?').run(uid, from);
  for (const r of moving) db.prepare(`UPDATE "${r.t}" SET ${r.w}=? WHERE ${r.u}=? AND ${r.w}=?`).run(to, uid, from);
  db.exec('COMMIT');
} catch (e) { db.exec('ROLLBACK'); console.log('failed, nothing changed:', e.message); process.exit(1); }
console.log('moved');
