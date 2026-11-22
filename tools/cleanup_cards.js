// One-time clean-up of spare shinobi card copies (owner, 22 Nov 2026: "remove all the lvl 1 copies from all the backpacks").
// Free top-ups let players buy 10-pull recruits and card bags without end (Zeraora held 87 000 shinobi cards, nine more players
// 5 000 - 15 000), and the app walks every card for the Team > Level Up screen and the login card list: minutes of loading.
// game.js BAG_MAX (5 000) stops it from growing again; this removes what piled up before.
//
// Removed: a shinobi card that is still exactly as it came (starting level, 0 exp, no rebirth, no sage growth, no potential,
// no breakthrough, no pills trained in) and is a SPARE: the player has another card of the same shinobi. Per shinobi one plain copy
// stays when the player has no other card of it. Never removed: cards in Team 1 / Team 2 or worn as gear slots, god cards
// (ninjainfo [11] = 6), EXP material cards ("(Material)", e.g. Golden Choji). Rebirth needs no copies (pills are free here).
// Nothing is given back (the original had no way to sell cards; owner's choice).
//
//   node tools/cleanup_cards.js <save.db>            dry run: what would go, per player
//   node tools/cleanup_cards.js <save.db> --apply    remove (make a backup first: tools/vps/snapshot.sh on the cloud)
'use strict';
const path = require('path');
const { DatabaseSync } = require('node:sqlite');
const file = process.argv[2], apply = process.argv.includes('--apply');
if (!file) { console.log('usage: node tools/cleanup_cards.js <save.db> [--apply]'); process.exit(1); }
const ninjainfo = require(path.join(__dirname, '..', 'server', 'data', 'ninjainfo.json')).rows;
const info = new Map(ninjainfo.map((r) => [r[0], r]));
const db = new DatabaseSync(file);
db.exec('PRAGMA busy_timeout = 10000');

function plan(db) {
  const used = new Set();
  for (const t of ['team', 'team_alt', 'equipped', 'equipped_alt']) {
    try { for (const r of db.prepare(`SELECT seq FROM ${t}`).all()) used.add(r.seq); } catch (e) { /* table not made yet */ }
  }
  const cols = new Set(db.prepare('PRAGMA table_info(cards)').all().map((c) => c.name));
  const z = (c) => (cols.has(c) ? ` AND IFNULL(${c},0)=0` : '');
  const plainSql = 'exp=0' + ['starlevel', 'newlife', 'pot_att', 'pot_def', 'pot_ckr', 'pend_att', 'pend_def', 'pend_ckr', 'breaklvl', 'pills_used'].map(z).join('');
  const rows = db.prepare(`SELECT seq, uid, server_id, ninja_id, level, (${plainSql}) plain FROM cards WHERE type=1 ORDER BY seq`).all();
  const groups = new Map(); // uid:sid:ninja -> { keepers: n, plain: [seq] }
  const total = new Map();
  for (const c of rows) {
    const who = c.uid + ':' + c.server_id;
    total.set(who, (total.get(who) || 0) + 1);
    const r = info.get(c.ninja_id) || [];
    const start = Math.max(1, Math.round(Number(r[7]) || 1));
    const protectedCard = r[11] === 6 || /\(Material\)/.test(String(r[1] || '')) || used.has(c.seq);
    const isPlain = !protectedCard && c.plain && c.level <= start;
    const k = who + ':' + c.ninja_id;
    let g = groups.get(k); if (!g) groups.set(k, g = { who, keepers: 0, plain: [] });
    if (isPlain) g.plain.push(c.seq); else g.keepers++;
  }
  const drop = new Map(); // who -> [seq]
  for (const g of groups.values()) {
    const spare = g.keepers > 0 ? g.plain : g.plain.slice(1); // keep the oldest plain copy when it is the only card of that shinobi
    if (spare.length) { if (!drop.has(g.who)) drop.set(g.who, []); drop.get(g.who).push(...spare); }
  }
  return { drop, total };
}

const { drop, total } = plan(db);
const nick = (who) => { const [uid, sid] = who.split(':').map(Number); try { return (db.prepare('SELECT nick FROM players WHERE uid=? AND server_id=?').get(uid, sid) || {}).nick || '?'; } catch (e) { return '?'; } };
const list = [...drop.entries()].sort((a, b) => b[1].length - a[1].length);
let sum = 0;
for (const [who, seqs] of list) {
  sum += seqs.length;
  if (seqs.length >= 50 || total.get(who) > 3000) console.log(`${who.padEnd(8)} ${nick(who).padEnd(16)} shinobi ${String(total.get(who)).padStart(6)}  remove ${String(seqs.length).padStart(6)}  left ${total.get(who) - seqs.length}`);
}
console.log(`${list.length} players, ${sum} spare copies ${apply ? 'removed' : 'would be removed (dry run; add --apply)'}`);
if (apply && sum) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const del = db.prepare('DELETE FROM cards WHERE seq=? AND type=1');
    for (const seqs of drop.values()) for (const s of seqs) del.run(s);
    db.exec('COMMIT');
  } catch (e) { db.exec('ROLLBACK'); throw e; }
  console.log('done');
}
module.exports = { plan };
