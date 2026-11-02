// God of Wealth (财神, Event menu tile "lotteryActivity", activity id 4, CLotteryView). Invest gold step by step and get more back.
// ORIGINAL (the game's own tables): wealthactivity rows 1-8 = invest [3] gold, get back between [4] and [5] (25 -> 30-40 ... 7500 -> 8000-8500);
// opens at level 10 (normalconfig 183) and runs 7 days (normalconfig 298). The client reads the current step from rl_r_activity
// <activity type="3"><item actid="3" pos="step"> (-1 = finished) and invests with rl_w_activity Cmd 9100 ActType 3 ActID 3 SubID step;
// the reply <caishen recash="N"/> is the gold returned (the client adds N - invest to its gold display). (ours): the return is uniform
// between [4] and [5]; one round per event run.
const game = require('./game');
const settings = require('./settings');

const LEVEL = 10, DAYS = 7;
const rows = () => game.table('wealthactivity').rows;
function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS caishen (uid INTEGER, server_id INTEGER, run INTEGER, step INTEGER DEFAULT 1, PRIMARY KEY(uid, server_id, run))');
}
const run = (db) => settings.switchedOnAt(db, 'caishen') || 0;
const open = (db) => settings.eventOn(db, 'caishen') && Date.now() / 1000 < run(db) + DAYS * 86400;
function step(db, pl) {
  if (!open(db) || pl.level < LEVEL) return -1;
  ensure(db);
  const r = db.prepare('SELECT step FROM caishen WHERE uid=? AND server_id=? AND run=?').get(pl.uid, pl.server_id, run(db));
  const s = r ? r.step : 1;
  return s > rows().length ? -1 : s;
}
function invest(db, pl, subId) {
  const s = step(db, pl);
  if (s < 0) return { error: 'the God of Wealth event is over' };
  if (subId !== s) return { error: 'please reopen the event' };
  const row = rows().find((x) => x[0] === s);
  if (!row) return { error: 'the God of Wealth event is over' };
  const cost = row[3];
  if (pl.gold < cost) return { error: 'not enough gold' };
  const back = row[4] + Math.floor(Math.random() * (row[5] - row[4] + 1));
  db.prepare('UPDATE players SET gold=gold-?+? WHERE uid=? AND server_id=?').run(cost, back, pl.uid, pl.server_id);
  db.prepare('INSERT INTO caishen(uid, server_id, run, step) VALUES(?,?,?,?) ON CONFLICT(uid, server_id, run) DO UPDATE SET step=excluded.step')
    .run(pl.uid, pl.server_id, run(db), s + 1);
  return { xml: `<caishen recash="${back}"/>` };
}

module.exports = { step, invest };
