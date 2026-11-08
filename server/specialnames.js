// Purple names (owner, 8 Nov 2026: "me and Riskeric ... when I reset my account, it still shows my name in glowing purple"). (ours)
// A few login accounts keep a fixed character name that glows purple in the No.1 Shinobi list (the 榜 scroll on Home,
// ui_hallOfFameCell.lua, hot update 28.0.42 reads glow="1"). Kept per login account (accounts.uid), so after a reset
// (admin.js resetPlayer keeps the account) the new character gets the same name back. Nobody else can create a character
// with that name. Set in the control panel (Players & items > player > Purple name).
// The other leaderboards (Arena, War power, Tower, Wheel) are drawn by the C++ app with one fixed color: the name shows there, not the glow.
const clean = (t) => String(t == null ? '' : t).replace(/[<>&"]/g, '').trim().slice(0, 16);
const key = (t) => clean(t).toLowerCase();

function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS special_names (uid INTEGER PRIMARY KEY, nick TEXT NOT NULL)');
}
function get(db, uid) {
  ensure(db);
  const r = db.prepare('SELECT nick FROM special_names WHERE uid=?').get(Number(uid));
  return r ? r.nick : null;
}
function uids(db) {
  ensure(db);
  return new Set(db.prepare('SELECT uid FROM special_names').all().map((r) => r.uid));
}
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
// Turn the purple name on (with this name) for an account; renames its characters in every world.
function set(db, uid, nick) {
  ensure(db);
  const n = clean(nick);
  if (!n) return { error: 'no name' };
  if (takenByOther(db, n, uid)) return { error: 'another account has that purple name' };
  db.prepare('INSERT OR REPLACE INTO special_names(uid, nick) VALUES(?, ?)').run(Number(uid), n);
  db.prepare('UPDATE players SET nick=? WHERE uid=?').run(n, Number(uid));
  return { ok: true, nick: n };
}
function clear(db, uid) {
  ensure(db);
  db.prepare('DELETE FROM special_names WHERE uid=?').run(Number(uid));
  return { ok: true };
}

module.exports = { ensure, get, uids, takenByOther, nickFor, set, clear, clean };
