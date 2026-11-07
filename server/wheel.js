// Lucky wheel (ui_rouletteLayer.lua). rl_r_wheel Cmd 1401 = load info + 12 wheel slots, rl_w_wheel Cmd 1400/1401 = spin once / ten times.
const game = require('./game');
const el = (n, v) => `<${n}>${v}</${n}>`;
// ORIGINAL (normalconfig 64-68, photos 1725 / 2975 / 3055 "100 Gold draw ... 1st try is free daily"): a spin costs 100 gold and gives 10
// points, 1 free spin a day, the pot starts at 1000 gold and grows 10 gold a spin. Until 7 Nov 2026: 50 gold, pot 5000 + half the gold.
const COST = 100, SCORE = 10, JACKPOT_START = 1000, JACKPOT_ADD = 10;
const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);

let migrated = new WeakSet();
function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS wheel (uid INTEGER, server_id INTEGER, score INTEGER DEFAULT 0, free_day TEXT DEFAULT "", jackpot INTEGER DEFAULT 0, PRIMARY KEY(uid,server_id))');
  if (migrated.has(db)) return;
  migrated.add(db);
  // once (7 Nov 2026): pots made by the old rule (start 5000 + half the gold spent) go back to the original start
  try { db.exec('ALTER TABLE wheel ADD COLUMN v INTEGER DEFAULT 0'); } catch (e) { /* already there */ }
  db.prepare('UPDATE wheel SET jackpot=?, v=1 WHERE v=0').run(JACKPOT_START);
}
function state(db, pl) {
  ensure(db);
  let s = db.prepare('SELECT * FROM wheel WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  if (!s) { db.prepare('INSERT INTO wheel(uid,server_id,jackpot,v) VALUES(?,?,?,1)').run(pl.uid, pl.server_id, JACKPOT_START); s = { score: 0, free_day: '', jackpot: JACKPOT_START }; }
  return s;
}
// The wheel's countdown runs to next Monday 00:00 and starts over (ours): the screen shows only 4 digits of hours, so the old 10 years read "3649:23:59".
const weekLeft = () => { const d = new Date(), end = new Date(d.getFullYear(), d.getMonth(), d.getDate() + ((8 - d.getDay()) % 7 || 7)); return Math.max(1, Math.floor((end - d) / 1000)); };
const infoXml = (s, free) => `<info>${el('lasttime', weekLeft())}${el('per_jifeng', SCORE)}${el('bigcash', s.jackpot)}${el('freetimes', free)}${el('jifeng', s.score)}${el('costsingle', COST)}</info>`;

function loadXml(db, pl) {
  const s = state(db, pl);
  const conf = game.table('wheelconfig').rows.map((r) => `<wheelitem id="${r[0]}" icon="${r[2]}" dropid="${r[4]}"></wheelitem>`).join('');
  return infoXml(s, s.free_day === today() ? 0 : 1) + `<wheelconf>${conf}</wheelconf>`;
}

function spin(db, pl, times) {
  const s = state(db, pl);
  const freeAvail = s.free_day !== today();
  const cost = (times - (freeAvail ? 1 : 0)) * COST;
  if (pl.gold < cost) return { error: 'not enough gold' };
  const rows = game.table('wheelconfig').rows;
  const total = rows.reduce((a, r) => a + r[5], 0);
  let jackpot = s.jackpot + JACKPOT_ADD * times;
  const awards = [];
  for (let i = 0; i < times; i++) {
    let x = Math.random() * total, row = rows[rows.length - 1];
    for (const r of rows) { if ((x -= r[5]) < 0) { row = r; break; } }
    let award = game.grantDrop(db, pl, row[4]); // every kind, like the rest of the game (the old drops.js paid ninjutsu / seals as silver)
    if (!award) { // "super prize" slot: pays the pot
      db.prepare('UPDATE players SET gold=gold+? WHERE uid=? AND server_id=?').run(jackpot, pl.uid, pl.server_id);
      award = game.awardFull({ cash: jackpot }); jackpot = JACKPOT_START;
    }
    awards.push(`<award_item item_id="${row[0]}">${award}</award_item>`);
  }
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(Math.max(0, cost), pl.uid, pl.server_id);
  const score = s.score + SCORE * times;
  db.prepare('UPDATE wheel SET score=?, free_day=?, jackpot=? WHERE uid=? AND server_id=?').run(score, today(), jackpot, pl.uid, pl.server_id);
  return { xml: infoXml({ score, jackpot }, 0) + `<award_list>${awards.join('')}</award_list>` };
}

module.exports = { loadXml, spin };
