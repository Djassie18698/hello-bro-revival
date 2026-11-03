// Tailed-beast seals (Plunder screen). Each seal (markmerge row) has up to 6 fragment ids (cols 3-8).
// Fragments are stored as props 20000+fragmentId. Plundering a fragment = a fight against a rival; a win
// usually takes the fragment. Synthesis turns one of each fragment into a seal card (cards.type 5, ninja_id = mark id).
// ORIGINAL synthesis flow (CMarkCardView, rl_w_markchip): Claim on a seal with every fragment starts a synthesis (Cmd 2800 MarkID): the
// fragments are used and the seal is ready after normalconfig 2 = 1800 s; Synthesis pays normalconfig 180 = 30 gold to finish at once
// (Cmd 2800 MarkID UseCash=1, also on one already running, then the app fetches it straight away); Claim on a finished one fetches the
// seal card (Cmd 2801 MarkID -> <markchip bagid>). The list's <markmerge><mark id resttime> rows are the running/finished syntheses only:
// a row tells the card "running" (resttime > 0) or "finished" (0). Before 3 Nov 2026 every seal had a row with resttime 0, so every seal
// looked finished: Claim made it at once and Synthesis did nothing (and ended the level-10 tutorial).
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const FRAG = 20000;
const merges = () => game.table('markmerge').rows;
const fragIds = (row) => row.slice(3, 9).filter((x) => x > 0);
const conf = (id, dflt) => { const r = game.table('normalconfig').rows.find((x) => x[0] === id); return r ? Number(r[3]) : dflt; };
const now = () => Math.floor(Date.now() / 1000);
function ensure(db) { db.exec('CREATE TABLE IF NOT EXISTS seal_merge (uid INTEGER, server_id INTEGER, mark_id INTEGER, ready_at INTEGER, PRIMARY KEY(uid,server_id,mark_id))'); }
const running = (db, pl, markId) => (ensure(db), db.prepare('SELECT ready_at FROM seal_merge WHERE uid=? AND server_id=? AND mark_id=?').get(pl.uid, pl.server_id, markId));

function listXml(db, pl) {
  const have = game.propCounts(db, pl.uid, pl.server_id);
  const chips = [];
  for (const row of merges()) for (const f of fragIds(row)) chips.push(`<chip>${el('id', f)}${el('count', have[FRAG + f] || 0)}</chip>`);
  ensure(db);
  const marks = db.prepare('SELECT mark_id, ready_at FROM seal_merge WHERE uid=? AND server_id=? ORDER BY mark_id').all(pl.uid, pl.server_id)
    .map((m) => `<mark>${el('id', m.mark_id)}${el('resttime', Math.max(0, m.ready_at - now()))}</mark>`).join('');
  // <cash> is the price of finishing a synthesis at once (the Synthesis dialog: 'spend N gold'), not the player's gold
  return `${el('cash', conf(180, 30))}<chiplist>${chips.join('')}</chiplist><markmerge>${marks}</markmerge>`;
}
// Cmd 2800: start a synthesis, or (useCash) pay to have it ready now. The app reads the reply root's message attribute (a missing one
// crashes it): "usecash" = paid, it then fetches the seal at once (Cmd 2801); anything else = it reloads the list.
function merge(db, pl, markId, useCash) {
  const row = merges().find((r) => r[0] === markId);
  if (!row) return { error: 'unknown seal' };
  const cost = conf(180, 30), run = running(db, pl, markId);
  if (run && (!useCash || run.ready_at <= now())) return { xml: '', message: run.ready_at <= now() ? 'usecash' : 'started' }; // nothing to pay
  if (useCash && (pl.gold || 0) < cost) return { error: 'not enough gold' };
  if (!run) {
    const have = game.propCounts(db, pl.uid, pl.server_id);
    if (fragIds(row).some((f) => !(have[FRAG + f] > 0))) return { error: 'collect all fragments first' };
    for (const f of fragIds(row)) game.propAdd(db, pl.uid, pl.server_id, FRAG + f, -1);
  }
  if (useCash) db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('INSERT OR REPLACE INTO seal_merge(uid,server_id,mark_id,ready_at) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, markId, useCash ? now() : now() + conf(2, 1800));
  return { xml: '', message: useCash ? 'usecash' : 'started' };
}
// Cmd 2801: take a finished seal.
function fetch(db, pl, markId) {
  const run = running(db, pl, markId);
  if (!run) return { error: 'collect all fragments first' };
  if (run.ready_at > now()) return { error: 'still synthesising, try again later' };
  db.prepare('DELETE FROM seal_merge WHERE uid=? AND server_id=? AND mark_id=?').run(pl.uid, pl.server_id, markId);
  const seq = Number(db.prepare('INSERT INTO cards(uid,server_id,type,ninja_id) VALUES(?,?,5,?)').run(pl.uid, pl.server_id, markId).lastInsertRowid);
  return { xml: `<markchip bagid="${seq}"/>` };
}
// Plunder a fragment: the fight must be won, then the fragment is taken with the ORIGINAL chance from the game's plunderinfo table, picked
// by level difference exactly like the client's "Plunder success rate" label (CPlunderCardView::InitUI: key = rival level - my level;
// 0 -> 1, negative -> 300 - diff): e.g. a rival 1-10 levels higher 40 %, 21-30 higher 60 %, 91+ higher 100 % ("Shall"); 1-10 lower 50 %,
// 21-30 lower 20 %, 41-50 lower 5 %, 81+ lower 0 % ("No"). Was a flat 70 % (ours) before 2 Nov 2026.
function plunderChance(myLevel, rivalLevel) {
  let key = rivalLevel - myLevel;
  key = key === 0 ? 1 : key < 0 ? 300 - key : key;
  const row = game.table('plunderinfo').rows.find((r) => r[0] === key);
  return row ? Number(row[3]) : 0;
}
function plunder(db, pl, fragId, win, rivalLevel) {
  if (!merges().some((r) => fragIds(r).includes(fragId))) return false;
  if (win && Math.random() < plunderChance(pl.level, rivalLevel == null ? pl.level : rivalLevel)) { game.propAdd(db, pl.uid, pl.server_id, FRAG + fragId, 1); return true; }
  return false;
}

module.exports = { listXml, merge, fetch, plunder, plunderChance, FRAG };
