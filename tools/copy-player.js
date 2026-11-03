// Copies one player's own progress onto another character (owner's request, 3 Nov 2026: his 8M-damage local account onto his account
// on the public server). The target keeps its login (accounts), its uid and its place in shared things (arena ladder, war, mail,
// guild, rankings of events); everything personal is replaced: player stats, cards (new card numbers), both teams and their gear,
// items, story progress and clears, VIP, pets and other personal states.
//   node tools/copy-player.js <source.db> <uid:server> <target.db> <uid:server> [new name]
// Run it while the target's game is closed; the target's game shows the new state after logging in again.
const { DatabaseSync } = require('node:sqlite');

const [srcFile, srcKey, dstFile, dstKey, newNick] = process.argv.slice(2);
if (!dstKey) { console.log('usage: node tools/copy-player.js <source.db> <uid:server> <target.db> <uid:server> [new name]'); process.exit(1); }
const key = (k) => { const [u, s] = String(k).split(':').map(Number); return { uid: u, sid: s || 1 }; };
const S = key(srcKey), D = key(dstKey);
const src = new DatabaseSync(srcFile, { readOnly: true }), dst = new DatabaseSync(dstFile);
dst.exec('PRAGMA busy_timeout = 10000'); // a running server may be writing: wait for it instead of failing

// Personal tables keyed by (uid, server_id). Card tables are handled apart (new seq numbers).
const PERSONAL = ['progress', 'props', 'stage_clears', 'vipstate', 'vipbought', 'stagegift', 'actclaim', 'recruit_state', 'godrecruit',
  'sevenday', 'growthfund', 'growthfund_claim', 'savetime', 'mtree', 'keeplogin', 'boxopen', 'monthsign', 'prop_uses', 'superninja_me',
  'pet_train', 'monopoly'];
const CARD_LINKED = ['team', 'team_alt', 'equipped', 'equipped_alt']; // rows that point at a card by seq
const PLAYER_COLS = ['country', 'card', 'level', 'exp', 'gold', 'coin', 'energy', 'vip', 'vipexp', 'sp', 'sp_t', 'energy_t', 'active_team'];

const has = (db, t) => !!db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?").get(t);
const cols = (db, t) => db.prepare(`PRAGMA table_info(${t})`).all().map((c) => c.name);
const ensureTable = (t) => { if (!has(dst, t)) dst.exec(src.prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name=?").get(t).sql); };
const srcRows = (t) => (has(src, t) ? src.prepare(`SELECT * FROM ${t} WHERE uid=? AND server_id=?`).all(S.uid, S.sid) : []);
function copyRows(t, rows, map = (r) => r, skip = []) {
  ensureTable(t);
  dst.prepare(`DELETE FROM ${t} WHERE uid=? AND server_id=?`).run(D.uid, D.sid);
  const common = cols(dst, t).filter((c) => cols(src, t).includes(c) && !skip.includes(c));
  const ins = dst.prepare(`INSERT INTO ${t} (${common.join(',')}) VALUES (${common.map(() => '?').join(',')})`);
  for (const r0 of rows) { const r = map({ ...r0, uid: D.uid, server_id: D.sid }); if (r) ins.run(...common.map((c) => r[c])); }
  return rows.length;
}

const sp = src.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(S.uid, S.sid);
const dp = dst.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(D.uid, D.sid);
if (!sp) throw new Error('source player not found: ' + srcKey);
if (!dp) throw new Error('target player not found: ' + dstKey);

dst.exec('BEGIN');
try {
  const report = {};
  const pc = PLAYER_COLS.filter((c) => cols(dst, 'players').includes(c) && c in sp);
  dst.prepare(`UPDATE players SET ${pc.map((c) => c + '=?').join(',')}${newNick ? ', nick=?' : ''} WHERE uid=? AND server_id=?`)
    .run(...pc.map((c) => sp[c]), ...(newNick ? [newNick] : []), D.uid, D.sid);
  // cards: the target's old cards go, the source's come in with new seq numbers
  const seqMap = new Map();
  for (const t of CARD_LINKED) if (has(dst, t)) dst.prepare(`DELETE FROM ${t} WHERE uid=? AND server_id=?`).run(D.uid, D.sid);
  dst.prepare('DELETE FROM cards WHERE uid=? AND server_id=?').run(D.uid, D.sid);
  const cardCols = cols(dst, 'cards').filter((c) => c !== 'seq' && cols(src, 'cards').includes(c));
  const insCard = dst.prepare(`INSERT INTO cards (${cardCols.join(',')}) VALUES (${cardCols.map(() => '?').join(',')})`);
  for (const c of srcRows('cards')) {
    const r = { ...c, uid: D.uid, server_id: D.sid };
    seqMap.set(c.seq, Number(insCard.run(...cardCols.map((k) => r[k])).lastInsertRowid));
  }
  report.cards = seqMap.size;
  for (const t of CARD_LINKED) report[t] = copyRows(t, srcRows(t), (r) => (seqMap.has(r.seq) ? { ...r, seq: seqMap.get(r.seq) } : null));
  for (const t of PERSONAL) if (has(src, t)) report[t] = copyRows(t, srcRows(t));
  // pets: own ids (AUTOINCREMENT), nothing points at them
  if (has(src, 'pets')) report.pets = copyRows('pets', srcRows('pets'), (r) => r, ['id']);
  dst.exec('COMMIT');
  console.log(`copied ${sp.nick} (${srcKey}) onto ${dp.nick} (${dstKey})${newNick ? ' as ' + newNick : ''}:`, JSON.stringify(report));
} catch (e) { dst.exec('ROLLBACK'); throw e; }
