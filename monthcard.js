// Month card (Event menu tile "monthCardActivity", activity id 3, monthCardActivity.lua). ORIGINAL (the game's monthCardData.lua):
// card 1 = $4.99, 60 gold a day for 30 days; card 2 = $9.99, 120 gold a day for 30 days; one claim a day. The client reads the state from
// rl_r_activity <activity type="4"><item actid="4"> (<canget subid="n"/> = claim today, <ing><card subid="n"/></ing> = claimed today,
// neither = not bought) and claims with rl_w_activity Cmd 9100 ActType 4 ActID 4 SubID n (code 0 = "Successful redemption").
// (ours): the Android game has no buy button for it, so topping up exactly $4.99 / $9.99 (the cards' own prices) activates the card;
// buying again while it runs restarts the 30 days. Off until the owner switches it on (switch `monthcard`): top-ups are free here, so it
// means free gold every day.
const settings = require('./settings');

const CARDS = { 1: { cents: 499, gold: 60, days: 30 }, 2: { cents: 999, gold: 120, days: 30 } };
const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
const dayNo = (d) => Math.floor(Date.parse(d + 'T00:00:00Z') / 86400000);
function ensure(db) {
  db.exec("CREATE TABLE IF NOT EXISTS monthcard (uid INTEGER, server_id INTEGER, card INTEGER, start TEXT, last TEXT DEFAULT '', PRIMARY KEY(uid, server_id, card))");
}
const on = (db) => settings.eventOn(db, 'monthcard');
function active(db, pl, card) {
  ensure(db);
  const r = db.prepare('SELECT * FROM monthcard WHERE uid=? AND server_id=? AND card=?').get(pl.uid, pl.server_id, card);
  if (!r || dayNo(today()) - dayNo(r.start) >= CARDS[card].days) return null;
  return r;
}
function onTopup(db, pl, cents) {
  if (!on(db)) return;
  const card = Object.keys(CARDS).find((k) => CARDS[k].cents === cents);
  if (!card) return;
  ensure(db);
  db.prepare("INSERT INTO monthcard(uid, server_id, card, start, last) VALUES(?,?,?,?,'') ON CONFLICT(uid, server_id, card) DO UPDATE SET start=excluded.start")
    .run(pl.uid, pl.server_id, Number(card), today());
}
function itemXml(db, pl) {
  if (!on(db)) return '<item actid="4"></item>';
  let can = '', ing = '';
  for (const k of Object.keys(CARDS)) {
    const r = active(db, pl, Number(k));
    if (!r) continue;
    if (r.last === today()) ing += `<card subid="${k}"/>`; else can += `<canget subid="${k}"/>`;
  }
  return `<item actid="4">${can}${ing ? `<ing>${ing}</ing>` : ''}</item>`;
}
function claim(db, pl, card) {
  if (!on(db)) return { error: 'the month card is not available' };
  const r = CARDS[card] && active(db, pl, card);
  if (!r) return { error: 'buy the month card first' };
  if (r.last === today()) return { error: 'you have already claimed it today' };
  db.prepare('UPDATE monthcard SET last=? WHERE uid=? AND server_id=? AND card=?').run(today(), pl.uid, pl.server_id, card);
  db.prepare('UPDATE players SET gold=gold+? WHERE uid=? AND server_id=?').run(CARDS[card].gold, pl.uid, pl.server_id);
  return { xml: `<month recash="${CARDS[card].gold}"/>` }; // hot update 28.0.31 makes the screen add it to the top bar
}

module.exports = { onTopup, itemXml, claim };
