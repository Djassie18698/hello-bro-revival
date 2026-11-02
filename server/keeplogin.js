// Login streak ("keep login", Event menu activity id 14, keepLoginView.lua). ORIGINAL rewards: the client's own keeplogin_info.lua
// (day 1: 2 small ramen + 2 small Hyourou-gan + 500 silver ... day 7 and 8+: 20 gold + 2 big ramen + 3 big Hyourou-gan). The client finds
// the state in the rl_r_activity reply as the activity element with desc="conlogin": condays = days in a row (8 = day 8 and later),
// got = today's reward claimed (1) or not (0). Claim = rl_w_activity ActType 5 ActID 1 SubID day -> <award>. A missed day starts the
// streak again at day 1 (ours: the usual rule; the original was server-side). Never built before 2 Nov 2026.
const game = require('./game');
const settings = require('./settings');

const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
const dayNo = (d) => Math.floor(Date.parse(d + 'T00:00:00Z') / 86400000);
const DROPS = { 1: [481, 487, 492], 2: [331, 479, 493], 3: [331, 479, 490], 4: [32, 488, 39], 5: [32, 489, 40], 6: [32, 489, 41], 7: [97, 32, 489], 8: [97, 32, 489] };
function ensure(db) {
  db.exec("CREATE TABLE IF NOT EXISTS keeplogin (uid INTEGER, server_id INTEGER, last TEXT, days INTEGER, got TEXT DEFAULT '', PRIMARY KEY(uid, server_id))");
}
// today's streak, counting today as a login
function state(db, pl) {
  ensure(db);
  let r = db.prepare('SELECT * FROM keeplogin WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  const t = today();
  if (!r) { r = { last: t, days: 1, got: '' }; db.prepare("INSERT INTO keeplogin(uid, server_id, last, days, got) VALUES(?,?,?,1,'')").run(pl.uid, pl.server_id, t); }
  else if (r.last !== t) {
    r.days = dayNo(t) - dayNo(r.last) === 1 ? r.days + 1 : 1;
    r.last = t;
    db.prepare('UPDATE keeplogin SET last=?, days=? WHERE uid=? AND server_id=?').run(t, r.days, pl.uid, pl.server_id);
  }
  return { days: Math.min(8, r.days), got: r.got === t ? 1 : 0 };
}
function xml(db, pl) {
  if (!settings.eventOn(db, 14)) return '';
  const s = state(db, pl);
  return `<activity type="5" desc="conlogin" condays="${s.days}" got="${s.got}"><item actid="1"></item></activity>`;
}
function claim(db, pl, subId) {
  if (!settings.eventOn(db, 14)) return { error: 'the event is over' };
  const s = state(db, pl);
  if (s.got) return { error: 'you have already claimed it today' };
  if (subId !== s.days) return { error: 'please reopen the event' };
  db.prepare('UPDATE keeplogin SET got=? WHERE uid=? AND server_id=?').run(today(), pl.uid, pl.server_id);
  return { xml: game.mergeAwards(DROPS[s.days].map((id) => game.grantDrop(db, pl, id)).filter(Boolean)) };
}

module.exports = { xml, claim };
