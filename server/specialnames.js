// Purple names (owner, 8 Nov 2026: "me and Riskeric ... when I reset my account, it still shows my name in glowing purple"). (ours)
// A few login accounts keep a fixed character name that glows in the No.1 Shinobi list (the 榜 scroll on Home,
// ui_hallOfFameCell.lua reads glow="1" glowcolor="RRGGBB") and in the Home top bar (util/common.lua PurpleTopBar asks
// rl_r_purplename each time Home opens). Hot update 28.0.45. The colour is picked in the control panel (purple by default), and an
// effect: "sparkle" = diamond twinkles on the name (28.0.46; owner: "effects on the names, like sparks, like diamonds").
// Kept per login account (accounts.uid), so after a reset (admin.js resetPlayer keeps the account and this table) the new
// character gets the same name back. Nobody else can create a character with that name.
// The other leaderboards (Arena, War power, Tower, Wheel) are drawn by the C++ app with one fixed color: the name shows there, not the glow.
const DEFAULT_COLOR = 'af46ff';
const clean = (t) => String(t == null ? '' : t).replace(/[<>&"]/g, '').trim().slice(0, 16);
const key = (t) => clean(t).toLowerCase();
const hex = (c) => { const m = /^#?([0-9a-f]{6})$/i.exec(String(c || '').trim()); return m ? m[1].toLowerCase() : null; };
const EFFECTS = ['', 'sparkle'];
const fx = (e) => (EFFECTS.includes(String(e == null ? '' : e)) ? String(e == null ? '' : e) : null);

function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS special_names (uid INTEGER PRIMARY KEY, nick TEXT NOT NULL)');
  if (!db.prepare('PRAGMA table_info(special_names)').all().some((c) => c.name === 'color'))
    db.exec(`ALTER TABLE special_names ADD COLUMN color TEXT NOT NULL DEFAULT '${DEFAULT_COLOR}'`); // made before the colour choice (28.0.43)
  if (!db.prepare('PRAGMA table_info(special_names)').all().some((c) => c.name === 'effect'))
    db.exec("ALTER TABLE special_names ADD COLUMN effect TEXT NOT NULL DEFAULT ''"); // made before the effects (28.0.45)
}
// { nick, color, effect } or null
function info(db, uid) {
  ensure(db);
  return db.prepare('SELECT nick, color, effect FROM special_names WHERE uid=?').get(Number(uid)) || null;
}
function get(db, uid) {
  const r = info(db, uid);
  return r ? r.nick : null;
}
// Map uid -> { color, effect } of every glowing name
function styles(db) {
  ensure(db);
  return new Map(db.prepare('SELECT uid, color, effect FROM special_names').all().map((r) => [r.uid, { color: hex(r.color) || DEFAULT_COLOR, effect: fx(r.effect) || '' }]));
}
const uids = (db) => new Set(styles(db).keys());
// true when another account owns this name as its purple name (case and spaces ignored)
function takenByOther(db, nick, uid) {
  ensure(db);
  return db.prepare('SELECT uid, nick FROM special_names').all().some((r) => r.uid !== Number(uid) && key(r.nick) === key(nick));
}
// The name a new character of this account gets (character creation, rl_w_reg2): its purple name when it has one;
// someone else's purple name is refused ("name taken": CRegistScene shows the tip and stays on the screen).
function nickFor(db, uid, wanted) {
  const own = get(db, uid);
  if (own) return { nick: own };
  if (wanted && takenByOther(db, wanted, uid)) return { error: 'name taken' };
  return { nick: wanted };
}
// Turn the glowing name on (with this name, colour and effect) for an account; renames its characters in every world.
// A colour or effect left out or not understood keeps the one it had.
function set(db, uid, nick, color, effect) {
  ensure(db);
  const n = clean(nick);
  if (!n) return { error: 'no name' };
  if (takenByOther(db, n, uid)) return { error: 'another account has that purple name' };
  const old = info(db, uid) || {};
  const c = hex(color) || old.color || DEFAULT_COLOR;
  const e = (effect === undefined ? null : fx(effect)) ?? old.effect ?? '';
  db.prepare('INSERT OR REPLACE INTO special_names(uid, nick, color, effect) VALUES(?, ?, ?, ?)').run(Number(uid), n, c, e);
  db.prepare('UPDATE players SET nick=? WHERE uid=?').run(n, Number(uid));
  return { ok: true, nick: n, color: c, effect: e };
}
function clear(db, uid) {
  ensure(db);
  db.prepare('DELETE FROM special_names WHERE uid=?').run(Number(uid));
  return { ok: true };
}

module.exports = { DEFAULT_COLOR, EFFECTS, ensure, info, get, styles, uids, takenByOther, nickFor, set, clear, clean, hex, fx };
