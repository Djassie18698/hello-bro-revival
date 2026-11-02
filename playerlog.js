// Progress log per player (owner's request): when a player levels up, when their team attack changes, when they reach a new story stage,
// a new VIP level, and the first login of each day. The admin page's "Player log" (/admin/playerlog) shows it as a timeline with how long
// a player stayed at each attack / chapter. Rows are small (one per change); attack is logged only when it moves at least 2 %.
function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS player_log (id INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, server_id INTEGER, at INTEGER,
      kind TEXT, value INTEGER, detail TEXT);
    CREATE INDEX IF NOT EXISTS player_log_who ON player_log(uid, server_id, kind, at);`);
}
const now = () => Math.floor(Date.now() / 1000);
function note(db, uid, sid, kind, value, detail = '') {
  try {
    ensure(db);
    db.prepare('INSERT INTO player_log(uid,server_id,at,kind,value,detail) VALUES(?,?,?,?,?,?)').run(uid, sid, now(), kind, value, String(detail));
  } catch (e) { /* the log must never break the game */ }
}
const last = (db, uid, sid, kind) => { ensure(db); return db.prepare('SELECT * FROM player_log WHERE uid=? AND server_id=? AND kind=? ORDER BY id DESC LIMIT 1').get(uid, sid, kind); };

// Team attack: called when the home screen loads (login and every return to Home).
function attack(db, uid, sid) {
  try {
    const t = require('./game').teamStats(db, uid, sid).total;
    const atk = Math.round((t.al + t.ah) / 2);
    const prev = last(db, uid, sid, 'attack');
    if (!prev || Math.abs(atk - prev.value) >= Math.max(1, prev.value * 0.02)) note(db, uid, sid, 'attack', atk);
  } catch (e) { /* ignore */ }
}
// First request of the day = a login day.
function day(db, uid, sid) {
  const prev = last(db, uid, sid, 'login');
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  if (!prev || prev.detail !== today) note(db, uid, sid, 'login', 0, today);
}

// The page: timeline + "how long at each step" for one player.
function summary(db, uid, sid) {
  ensure(db);
  const rows = db.prepare('SELECT at, kind, value, detail FROM player_log WHERE uid=? AND server_id=? ORDER BY at, id').all(uid, sid);
  const spans = (kind) => {
    const l = rows.filter((r) => r.kind === kind);
    return l.map((r, i) => ({ from: r.at, value: r.value, detail: r.detail, seconds: (i + 1 < l.length ? l[i + 1].at : now()) - r.at }));
  };
  return { rows: rows.slice(-500), attack: spans('attack'), level: spans('level'), story: spans('chapter'), logins: rows.filter((r) => r.kind === 'login').length };
}

module.exports = { ensure, note, attack, day, summary };
