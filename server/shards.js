// God card fragments ("shards") from fights (owner, 9 Nov 2026: "add the shards ... so all god cards get breakthrough, in a way that's
// good and easily obtainable for now, so we can buff or nerf droprates"). (ours: the original's fragment sources are lost; only 18 of the
// 83 god cards have a fragment pack in the game's drop table, so most god cards could never break through)
// A won fight can drop fragments of ONE of the player's own god cards (picked at random among the god cards they own that are not at
// Breakthrough +10 yet), so the fragments always go to cards that can use them. Every god card has its own fragment item (piece_info
// type 3, kept as prop CHIP_BASE + piece id), so the backpack and the Breakthrough screen show them as usual.
// The chances and amounts are the owner's to tune in the Server Manager (stored in server_settings 'shards'); Shard Rush (an event in the
// weekly rotation, days 4 and 7) multiplies the amount.
const game = require('./game');
const settings = require('./settings');

// source -> { chance (percent), min, max (fragments) }
const DEFAULTS = {
  stage: { chance: 25, min: 1, max: 2 }, // a won training stage
  boss: { chance: 60, min: 2, max: 4 }, // a won boss stage (3 free tries a day per boss)
  spar: { chance: 20, min: 1, max: 2 },
  arena: { chance: 30, min: 1, max: 3 },
  rush: 2, // Shard Rush: amounts times this
};
const SOURCES = { stage: 'Training stage won', boss: 'Boss stage won', spar: 'Spar won', arena: 'Arena won' };
const MAX_BREAK = 10;
const pieceOf = (ninjaId) => game.table('piece_info').rows.find((r) => r[4] === 3 && r[6] === ninjaId);

function rates(db) {
  const saved = settings.get(db, 'shards', {}) || {};
  const out = { rush: Number(saved.rush) > 0 ? Number(saved.rush) : DEFAULTS.rush };
  for (const k of Object.keys(SOURCES)) {
    const s = { ...DEFAULTS[k], ...(saved[k] || {}) };
    const chance = Math.max(0, Math.min(100, Number(s.chance) || 0));
    const min = Math.max(0, Math.floor(Number(s.min) || 0)), max = Math.max(min, Math.floor(Number(s.max) || 0));
    out[k] = { chance, min, max };
  }
  return out;
}
// the owner's new numbers (anything left out keeps its value); returns the rates in use
function setRates(db, body) {
  const cur = rates(db), next = { rush: Number(body.rush) > 0 ? Math.min(10, Number(body.rush)) : cur.rush };
  for (const k of Object.keys(SOURCES)) {
    const b = body[k] || {};
    const pick = (f, lo, hi) => (b[f] === undefined || b[f] === '' ? cur[k][f] : Math.max(lo, Math.min(hi, Number(b[f]) || 0)));
    next[k] = { chance: pick('chance', 0, 100), min: Math.floor(pick('min', 0, 50)), max: Math.floor(pick('max', 0, 50)) };
    if (next[k].max < next[k].min) next[k].max = next[k].min;
  }
  settings.set(db, 'shards', next);
  return rates(db);
}

// the god cards this player owns that can still break through, as [ninja id, piece id]
function targets(db, pl) {
  game.ensure(db);
  const seen = new Set(), out = [];
  for (const c of db.prepare('SELECT ninja_id, breaklvl FROM cards WHERE uid=? AND server_id=? AND type=1').all(pl.uid, pl.server_id)) {
    const n = game.ninjas().get(c.ninja_id);
    if (!n || n[11] !== 6 || (c.breaklvl || 0) >= MAX_BREAK || seen.has(c.ninja_id)) continue;
    const p = pieceOf(c.ninja_id);
    if (p) { seen.add(c.ninja_id); out.push([c.ninja_id, p[0]]); }
  }
  return out;
}

// A won fight from `source`: maybe fragments. Returns { piece, n, ninja } (already in the backpack) or null.
function drop(db, pl, source, rnd = Math.random) {
  const r = rates(db)[source];
  if (!r || !(rnd() * 100 < r.chance)) return null;
  const list = targets(db, pl);
  if (!list.length) return null;
  const [ninja, piece] = list[Math.floor(rnd() * list.length)];
  let n = r.min + Math.floor(rnd() * (r.max - r.min + 1));
  if (settings.eventOn(db, 'shardrush')) n *= rates(db).rush;
  n = Math.floor(n);
  if (n <= 0) return null;
  game.propAdd(db, pl.uid, pl.server_id, game.CHIP_BASE + piece, n);
  return { piece, n, ninja };
}
// put the fragments into a fight's <award> (the reward screens count one fragment per <chipitem>, like the game's own drops)
function addToAward(award, got) {
  if (!got) return award;
  const chips = `<chipitem id="${got.piece}" num="1"/>`.repeat(got.n);
  if (/<chipbag>/.test(award)) return award.replace(/<chipbag>(.*?)<\/chipbag>/, (m, inner) => `<chipbag>${inner}${chips}</chipbag>`);
  return award.replace(/<coin>/, `<chipbag>${chips}</chipbag><coin>`);
}

module.exports = { DEFAULTS, SOURCES, rates, setRates, drop, addToAward, targets };
