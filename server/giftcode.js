// Gift codes (owner, 24 Nov 2026: a player asked about the "Invitation Code" box in Settings; ours). ORIGINAL: v28 has the box and the
// Claim Award button (re/obb ui_gameSettingLayer.lua getAward: sends rl_w_invitecode Code=..., shows the reply's <award> with ShowAward,
// a refusal with ShowErrorTip) and its own tips 280001 "Invitation code has already been used", 280002 "Operation is too frequent",
// 280004 "Invitation code does not exist"; what a code gave lived on the dead server. (server/reference/lua-scripts has an older copy of
// that script whose getAward stops before sending: the game itself sends it.)
//
// The owner makes codes in the control panel (Award Center tab > 🎟️ Gift codes, owner only): the code (letters and digits, 3-20, any case),
// what it gives (gold / silver / arena reputation and/or one of the game's card packs, PACKS), how many players may use it (0 = everyone),
// until when. Each player uses a code once; everything arrives at once and the game shows it (reward window with the card + "got gold" tips).
// A shinobi pack needs room in the backpack (game.BAG_MAX: tip 20004, the code stays unused).
'use strict';

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS gift_codes (code TEXT PRIMARY KEY, title TEXT, gold INTEGER DEFAULT 0, silver INTEGER DEFAULT 0,
    renown INTEGER DEFAULT 0, max_uses INTEGER DEFAULT 0, used INTEGER DEFAULT 0, expires INTEGER DEFAULT 0, created INTEGER DEFAULT 0);
    CREATE TABLE IF NOT EXISTS gift_code_uses (code TEXT, uid INTEGER, server_id INTEGER, ts INTEGER, PRIMARY KEY(code, uid, server_id));`);
  try { db.exec('ALTER TABLE gift_codes ADD COLUMN drop_id INTEGER DEFAULT 0'); } catch (e) { /* already there */ }
}
// the card packs a code can give: the game's own random packs (dropinfo; game.rollPack picks the card)
const PACKS = { 11: 'Random 5-star shinobi', 10: 'Random 4-star shinobi', 1800: 'Random god shinobi (6-star)', 13: 'Random 5-star equipment', 14: 'Random 5-star ninjutsu' };
const norm = (c) => String(c || '').trim().toUpperCase();
const VALID = /^[A-Z0-9]{3,20}$/; // the game's box takes at most 20 characters (setMaxLength(20))
const now = () => Math.floor(Date.now() / 1000);

// too many wrong tries: at most 5 a minute per player (tip 280002), so codes can't be guessed by trying
const tries = new Map();
function tooFast(pl) {
  const k = pl.uid + ':' + pl.server_id, t = Date.now();
  const list = (tries.get(k) || []).filter((x) => t - x < 60000);
  list.push(t); tries.set(k, list);
  if (tries.size > 5000) tries.clear();
  return list.length > 5;
}

// a player types a code: { code } (an error code the game's tip table knows) or { ok, message }
function redeem(db, pl, raw) {
  ensure(db);
  if (tooFast(pl)) return { code: 280002 };
  const c = norm(raw);
  const g = VALID.test(c) && db.prepare('SELECT * FROM gift_codes WHERE code=?').get(c);
  if (!g || (g.expires && g.expires < now())) return { code: 280004 };
  if (db.prepare('SELECT 1 FROM gift_code_uses WHERE code=? AND uid=? AND server_id=?').get(c, pl.uid, pl.server_id)) return { code: 280001 };
  if (g.max_uses && g.used >= g.max_uses) return { code: 280001 };
  const game = require('./game');
  if (g.drop_id && game.bagRoom(db, pl.uid, pl.server_id) < game.dropShinobi(g.drop_id)) return { code: 20004 }; // "Bagpack is full"
  db.prepare('UPDATE players SET gold=gold+?, coin=coin+? WHERE uid=? AND server_id=?').run(g.gold, g.silver, pl.uid, pl.server_id);
  if (g.renown) game.propAdd(db, pl.uid, pl.server_id, 9996, g.renown); // arena reputation
  db.prepare('INSERT INTO gift_code_uses(code, uid, server_id, ts) VALUES(?,?,?,?)').run(c, pl.uid, pl.server_id, now());
  db.prepare('UPDATE gift_codes SET used=used+1 WHERE code=?').run(c);
  const awards = [];
  if (g.drop_id) awards.push(game.grantDrop(db, pl, g.drop_id)); // first: its dropid makes the game read the card list
  if (g.gold || g.silver || !awards.length) awards.push(game.awardFull({ cash: g.gold, coin: g.silver }));
  return { ok: true, xml: awards.length > 1 ? game.mergeAwards(awards.filter(Boolean)) : awards[0] };
}

// control panel
function list(db) {
  ensure(db);
  return db.prepare('SELECT * FROM gift_codes ORDER BY created DESC').all();
}
function add(db, b) {
  ensure(db);
  const c = norm(b.code);
  if (!VALID.test(c)) return { error: 'a code is 3 to 20 letters or digits, no spaces' };
  const gold = Math.max(0, Math.floor(Number(b.gold) || 0)), silver = Math.max(0, Math.floor(Number(b.silver) || 0)), renown = Math.max(0, Math.floor(Number(b.renown) || 0));
  const drop = Math.floor(Number(b.drop) || 0);
  if (drop && !PACKS[drop]) return { error: 'unknown card pack' };
  if (!gold && !silver && !renown && !drop) return { error: 'add gold, silver, arena reputation or a card pack' };
  if (db.prepare('SELECT 1 FROM gift_codes WHERE code=?').get(c)) return { error: 'that code already exists' };
  const days = Number(b.days) || 0;
  db.prepare('INSERT INTO gift_codes(code, title, gold, silver, renown, drop_id, max_uses, expires, created) VALUES(?,?,?,?,?,?,?,?,?)')
    .run(c, String(b.title || '').slice(0, 40), gold, silver, renown, drop, Math.max(0, Math.floor(Number(b.maxUses) || 0)), days > 0 ? now() + Math.round(days * 86400) : 0, now());
  return { ok: true, code: c };
}
function remove(db, code) {
  ensure(db);
  const r = db.prepare('DELETE FROM gift_codes WHERE code=?').run(norm(code));
  return r.changes ? { ok: true } : { error: 'no such code' };
}

module.exports = { redeem, list, add, remove, ensure, PACKS };
