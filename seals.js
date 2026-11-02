// Tailed-beast seals (Plunder screen). Each seal (markmerge row) has up to 6 fragment ids (cols 3-8).
// Fragments are stored as props 20000+fragmentId. Plundering a fragment = a fight against a rival; a win
// usually takes the fragment. Synthesis turns one of each fragment into a seal card (cards.type 5, ninja_id = mark id).
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const FRAG = 20000;
const merges = () => game.table('markmerge').rows;
const fragIds = (row) => row.slice(3, 9).filter((x) => x > 0);

function listXml(db, pl) {
  const have = game.propCounts(db, pl.uid, pl.server_id);
  const chips = [];
  for (const row of merges()) for (const f of fragIds(row)) chips.push(`<chip>${el('id', f)}${el('count', have[FRAG + f] || 0)}</chip>`);
  const marks = merges().map((row) => `<mark>${el('id', row[0])}${el('resttime', 0)}</mark>`).join('');
  return `${el('cash', pl.gold)}<chiplist>${chips.join('')}</chiplist><markmerge>${marks}</markmerge>`;
}
function merge(db, pl, markId) {
  const row = merges().find((r) => r[0] === markId);
  if (!row) return { error: 'unknown seal' };
  const have = game.propCounts(db, pl.uid, pl.server_id);
  if (fragIds(row).some((f) => !(have[FRAG + f] > 0))) return { error: 'collect all fragments first' };
  for (const f of fragIds(row)) game.propAdd(db, pl.uid, pl.server_id, FRAG + f, -1);
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

module.exports = { listXml, merge, plunder, plunderChance, FRAG };
