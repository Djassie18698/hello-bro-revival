// Leaderboards shared by several screens. Every ranking is computed live from the database.
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const today = () => new Date().toISOString().slice(0, 10);

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS wheel (uid INTEGER, server_id INTEGER, score INTEGER DEFAULT 0, free_day TEXT DEFAULT "", jackpot INTEGER DEFAULT 0, PRIMARY KEY(uid,server_id));
    CREATE TABLE IF NOT EXISTS rank_claims (uid INTEGER, server_id INTEGER, board TEXT, key TEXT, PRIMARY KEY(uid,server_id,board,key))`);
  try { db.exec('ALTER TABLE wheel ADD COLUMN spent INTEGER NOT NULL DEFAULT 0'); } catch (e) { /* already there */ }
}

// ---- Wheel of Fortune ranking (rl_r_fwheel_rank) + rank / points gifts (rl_w_wheel_gift) ----
// Wheel score only grows; spending points on point-packs adds to `spent`, so current = score - spent.
// Rank gifts come from wheelpackconfig rows 1-4 (type 1): [max rank, row id]; the row's col 5 is the dropinfo id.
const RANK_GIFTS = [[1, 1], [10, 2], [50, 3], [100, 4]];
// Points-gift drops 283/284 are random boxes the client cannot preview; show gold drops instead.
const DROP_FIX = { 283: 371, 284: 372 };
const packDrop = (r) => (r[4] === 1 ? r[5] : DROP_FIX[r[6]] || r[6]);
function wheelBoard(db, sid) {
  ensure(db);
  return db.prepare('SELECT w.uid, w.score, p.nick FROM wheel w JOIN players p ON p.uid=w.uid AND p.server_id=w.server_id WHERE w.server_id=? AND w.score>0 ORDER BY w.score DESC, w.uid LIMIT 100').all(sid);
}
function wheelRankXml(db, pl) {
  const board = wheelBoard(db, pl.server_id);
  const me = db.prepare('SELECT score, spent FROM wheel WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { score: 0, spent: 0 };
  const myRank = board.findIndex((r) => r.uid === pl.uid) + 1;
  // Lua reads xfile:find('rank') as a CONTAINER and iterates its children; same for wheelpackage.
  const rows = '<rank>' + board.map((r, i) => `<item>${el('rank', i + 1)}${el('nick', esc(r.nick))}${el('score', r.score)}</item>`).join('') + '</rank>';
  const packs = '<wheelpackage>' + game.table('wheelpackconfig').rows.map((r) =>
    `<item id="${r[0]}" name="${esc(r[2])}" icon="${r[3]}" type="${r[4]}" desc="${esc(r[4] === 2 ? r[5] + ' points' : r[2])}" quality="4" dropid="${packDrop(r)}"/>`).join('') + '</wheelpackage>';
  return el('myrank', myRank) + el('myscore', me.score) + el('limitscore', 0) + el('jifeng', me.score - me.spent) + rows + packs;
}
function wheelGift(db, pl, cmd, giftId) {
  ensure(db);
  const me = db.prepare('SELECT score, spent FROM wheel WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { score: 0, spent: 0 };
  if (cmd === 1) { // ranking gift, once per day
    const rank = wheelBoard(db, pl.server_id).findIndex((r) => r.uid === pl.uid) + 1;
    const tier = rank > 0 && RANK_GIFTS.find(([max]) => rank <= max);
    if (!tier) return { error: 'not ranked' };
    const done = db.prepare('INSERT OR IGNORE INTO rank_claims VALUES(?,?,?,?)').run(pl.uid, pl.server_id, 'wheel', today());
    if (!done.changes) return { error: 'already claimed today' };
    const row = game.table('wheelpackconfig').rows.find((r) => r[0] === tier[1]);
    return { xml: game.grantDrop(db, pl, packDrop(row)) + el('limitcode', 0) };
  }
  // points gift: package ids 5-8, cost = row[5] points
  const row = game.table('wheelpackconfig').rows.find((r) => r[0] === giftId && r[4] === 2);
  if (!row) return { error: 'bad gift' };
  const cur = me.score - me.spent;
  if (cur < row[5]) return { error: 'not enough points' };
  db.prepare('UPDATE wheel SET spent=spent+? WHERE uid=? AND server_id=?').run(row[5], pl.uid, pl.server_id);
  return { xml: el('jifeng', cur - row[5]) + game.grantDrop(db, pl, packDrop(row)) };
}

module.exports = { wheelRankXml, wheelGift, ensure };
