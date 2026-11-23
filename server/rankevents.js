// Level rank + Fight rank ("Level" / "Power" in the Event list; business_proxy/levelRank_business + fightRank_business ->
// ui_levelRankLayer.lua / ui_fightRankLayer.lua, both on the layout activity/LevelRank). The original ran them once, in a new server's
// first week: a race for the highest level and the strongest team, prizes per place, claimed by tapping a prize picture afterwards.
//
// ORIGINAL (Facebook photos 2187 Level and 2189 Power, the same server 1 min apart, "Refreshes in 06:18:35"):
//   Level: No.1 Six Paths Shakujo, No.2 Bashosen, No.3 Thunder god armour, No.4-10 Sage Stone III x50, No.11-30 Sage Stone I x50
//   Power: No.1 Uchiha Obito, No.2 Yakushi Kabuto, No.3 Killer B, No.4-10 500 gold, No.11-30 90 gold
//   The ten prize pictures on the photos are all still in v28's props sheets (props_139 / 074 / 231 / 102 / 063 and 082 / 174 / 071 / 099 / 067).
//   Length: normalconfig row 99 = 604800 s (7 days) of race, row 100 = 86400 s (1 day) to claim.
//   Rule (the game's text ui_level_rank_rule_desc): prizes by place, claim within 24 hours by tapping the prize picture; equal levels
//   rank by attack power.
// (ours): the cards are the Attack versions (the photo shows only faces; drop rows 351 / 959 / 276); "Battle Point" = the team's top
//   attack, the number the No.1 Shinobi list sorts by; the list shows 50 places; the race starts when the owner switches it on (the
//   original started with the server) and every character on the world takes part.
//
// Protocol: rl_r_comm Cmd 2 (both screens ask the same) = <preview type="1 running | 2 claim | 3 over" resttime/>,
//   <levelrank my> rows rank, playerid, name, country, level; <powerrank my mypower> rows rank, playerid, name, level, country, power
//   (read by position), <awardlist> one row per place: rank, type (1 level, 2 power), icon, name, dropid. The screen joins rows with
//   the same icon into one "No.4-10" tile, so every prize step needs its own icon, and the icon must be a props/ sheet (a missing
//   sheet crashes the phone app). rl_w_comm Cmd 3 = claim my level prize, Cmd 2 = my power prize (no other field; any refusal shows
//   the screen's own "already redeemed, or not qualified" tip). The Event list shows them as its entries 9 and 10
//   (activity_config.lua; game.actXml adds both while the race or its claim day runs). The <opentype> field of mainActivity.lua's
//   initRankPowerActivity is a leftover: v28 builds the list from the entries only (opentype 3 would hide 9 and 10).
//   Both screens send the very same request, so the two events can only run together: one switch.
const game = require('./game');
const settings = require('./settings');

const ID = 'rankrace';
const cfg = (id, dflt) => { const r = game.table('normalconfig').rows.find((x) => x[0] === id); return r && r[3] > 0 ? r[3] : dflt; };
const RUN = () => cfg(99, 604800), CLAIM = () => cfg(100, 86400);
const SHOWN = 50, KEPT = 200; // rows on the screen (ours); places kept at the end (the screen says "200+" beyond that)
const STEPS = [[1, 1], [2, 2], [3, 3], [4, 10], [11, 30]];
const PRIZES = {
  1: [[552, 'props_139'], [281, 'props_074'], [1141, 'props_231'], [359, 'props_102'], [360, 'props_063']], // Level
  2: [[351, 'props_082'], [959, 'props_174'], [276, 'props_071'], [290, 'props_099'], [131, 'props_067']],  // Power
};
const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const now = () => Math.floor(Date.now() / 1000);

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS rankrace_final (run INTEGER, kind INTEGER, server_id INTEGER, place INTEGER, uid INTEGER, nick TEXT, country INTEGER, level INTEGER, value INTEGER, PRIMARY KEY(run, kind, server_id, place));
    CREATE TABLE IF NOT EXISTS rankrace_claim (run INTEGER, kind INTEGER, uid INTEGER, server_id INTEGER, PRIMARY KEY(run, kind, uid, server_id))`);
}
// phase 1 = the race runs, 2 = it is over and prizes can be claimed, 3 = closed (the event leaves the Event list)
function state(db) {
  if (!settings.eventOn(db, ID)) return { phase: 3, rest: 0, run: 0 };
  const run = settings.switchedOnAt(db, ID) || now(), t = now() - run;
  if (t < RUN()) return { phase: 1, rest: RUN() - t, run };
  if (t < RUN() + CLAIM()) return { phase: 2, rest: RUN() + CLAIM() - t, run };
  settings.setEvent(db, ID, false); // the claim day is over: the switch in the Server Manager goes back to off
  return { phase: 3, rest: 0, run };
}
const open = (db) => state(db).phase < 3;

// every named character of the world with its level and team attack; kept a minute (the team sums are the slow part)
const cache = new Map();
function live(db, sid) {
  const c = cache.get(sid);
  if (c && c.db === db && Date.now() - c.at < 60000) return c.rows;
  const rows = db.prepare("SELECT uid, nick, country, level, exp FROM players WHERE server_id=? AND nick<>''").all(sid)
    .map((r) => ({ ...r, power: Math.round(game.teamStats(db, r.uid, sid).total.ah) }));
  cache.set(sid, { db, at: Date.now(), rows });
  return rows;
}
const byLevel = (a, b) => b.level - a.level || b.power - a.power || b.exp - a.exp || a.uid - b.uid; // equal levels: attack decides (original rule)
const byPower = (a, b) => b.power - a.power || b.level - a.level || a.uid - b.uid;
// the two lists as { uid, nick, country, level, value }: live while the race runs, the kept end result afterwards
function boards(db, sid, st) {
  if (st.phase === 1) {
    const rows = live(db, sid);
    return { 1: [...rows].sort(byLevel).map((r) => ({ ...r, value: r.level })), 2: [...rows].sort(byPower).map((r) => ({ ...r, value: r.power })) };
  }
  ensure(db);
  if (!db.prepare('SELECT 1 FROM rankrace_final WHERE run=? AND server_id=?').get(st.run, sid)) { // first look after the end: keep the result
    cache.delete(sid);
    const rows = live(db, sid), ins = db.prepare('INSERT OR IGNORE INTO rankrace_final VALUES(?,?,?,?,?,?,?,?,?)');
    [[1, byLevel, 'level'], [2, byPower, 'power']].forEach(([kind, sort, key]) => [...rows].sort(sort).slice(0, KEPT)
      .forEach((r, i) => ins.run(st.run, kind, sid, i + 1, r.uid, r.nick, r.country, r.level, r[key])));
  }
  const get = (kind) => db.prepare('SELECT uid, nick, country, level, value FROM rankrace_final WHERE run=? AND kind=? AND server_id=? ORDER BY place').all(st.run, kind, sid);
  return { 1: get(1), 2: get(2) };
}
const dropName = (id) => String((game.table('dropinfo').rows.find((x) => x[0] === id) || [])[2] || '').trim();
function awardList() {
  return '<awardlist>' + [1, 2].map((kind) => STEPS.map(([from, to], i) => { const [drop, icon] = PRIZES[kind][i]; let s = '';
    for (let r = from; r <= to; r++) s += '<award>' + el('rank', r) + el('type', kind) + el('icon', icon) + el('name', esc(dropName(drop))) + el('dropid', drop) + '</award>';
    return s; }).join('')).join('') + '</awardlist>';
}
function infoXml(db, pl) {
  const st = state(db);
  if (st.phase === 3) return '<preview type="3" resttime="0"/>';
  const b = boards(db, pl.server_id, st);
  const place = (kind) => b[kind].findIndex((r) => r.uid === pl.uid) + 1 || (st.phase === 2 ? KEPT + 1 : 0); // not among the kept places: "200+"
  const mine = b[2].find((r) => r.uid === pl.uid);
  const level = b[1].slice(0, SHOWN).map((r, i) => '<item>' + el('rank', i + 1) + el('playerid', r.uid) + el('name', esc(r.nick)) + el('country', r.country) + el('level', r.level) + '</item>').join('');
  const power = b[2].slice(0, SHOWN).map((r, i) => '<item>' + el('rank', i + 1) + el('playerid', r.uid) + el('name', esc(r.nick)) + el('level', r.level) + el('country', r.country) + el('power', r.value) + '</item>').join('');
  return `<preview type="${st.phase}" resttime="${st.rest}"/><levelrank my="${place(1)}">${level}</levelrank>` +
    `<powerrank my="${place(2)}" mypower="${mine ? mine.value : Math.round(game.teamStats(db, pl.uid, pl.server_id).total.ah)}">${power}</powerrank>` + awardList();
}
// kind 1 = level prize, 2 = power prize; only in the claim day, once, for places 1-30 of the kept end result
function claim(db, pl, kind) {
  const st = state(db);
  if (st.phase !== 2 || !PRIZES[kind]) return { error: 'the prizes cannot be claimed now' };
  const place = boards(db, pl.server_id, st)[kind].findIndex((r) => r.uid === pl.uid) + 1;
  const step = place > 0 ? STEPS.findIndex(([from, to]) => place >= from && place <= to) : -1;
  if (step < 0) return { error: 'no prize for your place' };
  const drop = PRIZES[kind][step][0];
  if (game.dropShinobi(drop) && game.bagRoom(db, pl.uid, pl.server_id) < 1) return { error: game.BAG_FULL };
  if (!db.prepare('INSERT OR IGNORE INTO rankrace_claim VALUES(?,?,?,?)').run(st.run, kind, pl.uid, pl.server_id).changes) return { error: 'already claimed' };
  return { xml: game.grantDrop(db, pl, drop), place, drop };
}
// once a minute (rotation.js's timer): keep the end result as soon as the race is over, so nothing a player does afterwards moves a place
function tick(db) {
  const st = state(db);
  if (st.phase === 2) for (const r of db.prepare('SELECT DISTINCT server_id FROM players').all()) boards(db, r.server_id, st);
}

module.exports = { tick, ID, STEPS, PRIZES, state, open, infoXml, claim, RUN, CLAIM };
