// What the dev save holds for a guest of tools/dev/play.js: one line to compare before and after a play step.
//   node tools/dev/play-save.js <uid> [sql ...]     (extra arguments: SQL statements to run first, $UID = that uid; dev save hellobro.db only)
const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync(process.env.PLAY_DB || require('path').join(__dirname, '..', '..', 'hellobro.db')); // PLAY_DB = another save (a private server copy)
const uid = Number(process.argv[2]);
for (const q of process.argv.slice(3)) { const s = q.replace(/\$UID/g, uid); if (/^\s*select/i.test(s)) console.log(JSON.stringify(db.prepare(s).all())); else console.log('changed ' + db.prepare(s).run().changes); }
const p = db.prepare('SELECT level, exp, gold, coin, energy, vip, vipexp FROM players WHERE uid=? AND server_id=1').get(uid);
const props = db.prepare('SELECT prop_id, count FROM props WHERE uid=? AND count>0 ORDER BY prop_id').all(uid).map((r) => r.prop_id + ':' + r.count).join(' ');
const cards = db.prepare('SELECT type, COUNT(*) n FROM cards WHERE uid=? GROUP BY type').all(uid).map((r) => 't' + r.type + 'x' + r.n).join(' ');
let pets = ''; try { pets = ' pets ' + db.prepare('SELECT COUNT(*) n FROM pets WHERE uid=?').get(uid).n; } catch {}
console.log(JSON.stringify(p) + ' props ' + props + ' cards ' + cards + pets);
