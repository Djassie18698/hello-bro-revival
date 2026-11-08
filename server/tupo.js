// Breakthrough (Base > Breakthrough, ui_tupoLayer.lua; rl_x_breakthrough). Only god cards (quality 6) can break through:
// each level costs that card's own fragments (piece_info type 3) plus silver and adds +4% to the stats of the card's element
// (game.ninjaStats, ours; the help text ui_tupo_desc names the stats per element) plus 1% ninjutsu trigger and 2% element restrain.
// ORIGINAL (photos 0365 Kyuubi Naruto (God), 1706 Six Paths Sasuke (God), both 0 -> +1): 10 fragments, ninjutsu trigger +1%,
// five-line restrain +2%, silver 60 000 (Kyuubi Naruto) / 250 000 (Six Paths Sasuke), so the price depends on the card.
// (ours): +5 fragments per further level; the price tier by the card's base max attack (ninjainfo [20]: the god cards split at
// 630 | 695, Kyuubi 615 below, Six Paths Sasuke 730 above), times (level + 1) for the further levels.
// Cmd 1 = info for BagIndex, Cmd 2 = break through one level.
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const MAX = 10;
const TRIGGER = 1, RESTRAIN = 2; // % per level (original)
const needChips = (lvl) => 10 + lvl * 5; // fragments for level lvl -> lvl+1 (+1 = 10 original, +5 a level ours)
const TOP_TIER_ATK = 690; // base max attack from which a god card is in the Six Paths price tier (ours)
const firstPrice = (ninjaId) => (((game.ninjas().get(ninjaId) || [])[20] || 0) >= TOP_TIER_ATK ? 250000 : 60000);
const needCoin = (card, lvl) => firstPrice(card.ninja_id) * (lvl + 1);

function godCard(db, pl, seq) {
  game.ensure(db);
  const c = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(seq, pl.uid, pl.server_id);
  const n = c && game.ninjas().get(c.ninja_id);
  return n && n[11] === 6 ? c : null;
}
const pieceOf = (ninjaId) => game.table('piece_info').rows.find((r) => r[4] === 3 && r[6] === ninjaId);
// Flat bonus the client adds to the card (difference made by the break levels).
function bonus(card, lvl) {
  const a = game.ninjaStats({ ...card, breaklvl: lvl }), b = game.ninjaStats({ ...card, breaklvl: 0 });
  return { att: a.al - b.al, def: a.dl - b.dl, ckr: a.cl - b.cl, skill: lvl * TRIGGER, kezhi: lvl * RESTRAIN };
}
const attrXml = (tag, x) => `<${tag}>` + el('add_attack', x.att) + el('add_defense', x.def) + el('add_chakela', x.ckr) + el('add_skill', x.skill) + el('add_kezhi', x.kezhi) + `</${tag}>`;

function infoXml(db, pl, card) {
  const lvl = card.breaklvl || 0;
  const piece = pieceOf(card.ninja_id);
  const pid = piece ? piece[0] : 0;
  // attr_before comes first: the client also reads the card's current flat bonus from the first add_attack it finds.
  return attrXml('attr_before', bonus(card, lvl)) + attrXml('attr_after', bonus(card, Math.min(MAX, lvl + 1))) +
    el('max_break_level', MAX) + el('need_chip_num', lvl >= MAX ? 0 : needChips(lvl)) + el('cost_coin', lvl >= MAX ? 0 : needCoin(card, lvl)) +
    el('chip_num', pid ? game.chipCount(db, pl.uid, pl.server_id, pid) : 0) + el('break_level', lvl) + el('chip_id', pid);
}
function info(db, pl, seq) {
  const card = godCard(db, pl, seq);
  if (!card) return { error: 'only god cards can break through' };
  return { xml: infoXml(db, pl, card) };
}
function breakThrough(db, pl, seq) {
  const card = godCard(db, pl, seq);
  if (!card) return { error: 'only god cards can break through' };
  const lvl = card.breaklvl || 0;
  if (lvl >= MAX) return { error: 'already at the highest level' };
  const piece = pieceOf(card.ninja_id);
  if (!piece) return { error: 'this card has no fragments' };
  const have = game.chipCount(db, pl.uid, pl.server_id, piece[0]);
  if (have < needChips(lvl)) return { error: 'not enough fragments' };
  const p = db.prepare('SELECT coin FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  const coin = needCoin(card, lvl);
  if (p.coin < coin) return { error: 'not enough silver' };
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(coin, pl.uid, pl.server_id);
  game.propAdd(db, pl.uid, pl.server_id, game.CHIP_BASE + piece[0], -needChips(lvl));
  db.prepare('UPDATE cards SET breaklvl=? WHERE seq=?').run(lvl + 1, seq);
  return { xml: infoXml(db, pl, { ...card, breaklvl: lvl + 1 }) };
}
// Fragment drop (dropinfo col 8 = piece id) for the player's best god card that the game's tables have a fragment drop for
// (only 18 of the 83 god cards do), for shops: the oldest such card not yet at Breakthrough 10 (before 8 Nov 2026 only the oldest god
// card was looked at, so a first card without a drop hid the others); the biggest bundle.
function fragmentDropFor(db, pl) {
  game.ensure(db);
  const cards = db.prepare('SELECT ninja_id FROM cards WHERE uid=? AND server_id=? AND type=1 AND breaklvl < ? ORDER BY seq')
    .all(pl.uid, pl.server_id, MAX);
  for (const c of cards) {
    const piece = pieceOf(c.ninja_id);
    if (!piece) continue;
    const drops = game.table('dropinfo').rows.filter((r) => r[8] === piece[0] && r[12] !== 1).sort((a, b) => (b[13] || 1) - (a[13] || 1));
    if (drops.length) return drops[0][0];
  }
  return 0;
}

module.exports = { info, breakThrough, fragmentDropFor, needChips, needCoin, MAX };
