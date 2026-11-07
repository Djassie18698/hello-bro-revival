// Runs the admin page's Best team search (admin.bestTeam) in its own thread: it can take several seconds on the small cloud machine,
// and the game must keep answering players meanwhile. Opens its own connection to the save (WAL: it only reads while the game writes).
const { parentPort, workerData } = require('node:worker_threads');
const { DatabaseSync } = require('node:sqlite');
const game = require('./game');
const { dbPath, uid, sid, goal, mode, leaderOnce } = workerData;
game.RULES.leaderOnce = !!leaderOnce;
const admin = require('./admin');
let db;
try {
  db = new DatabaseSync(dbPath);
  db.exec('PRAGMA busy_timeout = 5000;');
  const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(uid, sid);
  parentPort.postMessage(pl ? { ok: true, ...admin.bestTeam(db, pl, goal, mode) } : { ok: false, error: 'no such player' });
} catch (e) {
  parentPort.postMessage({ ok: false, error: e.message });
} finally {
  try { db && db.close(); } catch (e) { /* closing anyway */ }
}
