// Runs the admin page's Best team search (admin.bestTeam) in a separate low-priority process: on the small cloud machine it can take a
// minute or two, and the game must keep answering players meanwhile (the server sets this process to the lowest CPU priority).
// Opens its own connection to the save (WAL: it only reads while the game writes). Gets { dbPath, uid, sid, goal, mode, leaderOnce } as
// its first message and sends the result back.
const { DatabaseSync } = require('node:sqlite');
process.once('message', ({ dbPath, uid, sid, goal, mode, leaderOnce }) => {
  const game = require('./game');
  game.RULES.leaderOnce = !!leaderOnce;
  const admin = require('./admin');
  let db, out;
  try {
    db = new DatabaseSync(dbPath);
    db.exec('PRAGMA busy_timeout = 5000;');
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(uid, sid);
    out = pl ? { ok: true, ...admin.bestTeam(db, pl, goal, mode) } : { ok: false, error: 'no such player' };
  } catch (e) {
    out = { ok: false, error: e.message };
  } finally {
    try { db && db.close(); } catch (e) { /* closing anyway */ }
  }
  process.send(out, () => process.exit(0));
});
