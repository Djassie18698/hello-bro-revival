// Limited Super Ninja (Event menu id 18 = home button, activitySubmenHelper ShowSuperNinjaView -> ui_limitSuperNinjaLayer.lua).
// ORIGINAL protocol (the client's Lua + CCommonPrayDialogView in libgame.so):
//  - rl_r_comm Cmd 6 = open: <preview resttime nexttime protect gold status actstatus limitscore/>, <ninjalist> rows (name ninjiaid attr
//    dropid; tapping the card shows the drop), <ranklist> rows (rank nick score), <myrank rank score/>, <rewardlist> rows (rankrange dropinfo).
//    Lua shows protect - 1 and "The MINIMUM for 1st prise is <limitscore>."
//  - rl_r_comm Cmd 7 = refresh after a pull: <preview nextfreetime protect status actstatus rank score/> + <ranklist>.
//  - Free pull: rl_w_recruit Cmd 1902 Type 1 Free 1 (Lua) -> any <award>.
//  - Gold pulls go through the game's own pray dialog, the SAME request as the premium recruit (rl_w_recruit Cmd 1900 / 1901 Type 1,
//    IsSuperAct 0: the Lua can't set it), and its open call rl_r_recruit Cmd 2900 Type 1. So the server remembers who has this screen
//    open (Cmd 6 / 7) and treats their pulls as event pulls until they go Home or to the Shop (rl_r_mainpage / rl_r_shoplist).
//  - rl_w_comm Cmd 11 = claim the rank prize after the event (actstatus 2). Not used: rounds run back to back and the prizes are mailed
//    to the Awards chest when a round ends.
// The draws follow the ORIGINAL rules from the owner's Facebook photos (FINDINGS-PHOTOS: S-shinobi draw rows): 300 gold a draw, the free
// draw once a day (timer 23:58:38), "Recruit N more will get one" a Five-Star Purple Card with N 0-9 (= every 10th draw), 10 points a draw
// (photo 1625; others show 20 or 30), the headline card ONLY as the 1st prize, a 10x draw showing 3-4 five-star cards (photos 2469 / 2470:
// FIVE_PCT is (ours) from those two). The rest is the owner's choice for now (2 Nov 2026), not the original 3-day event with a 240-480
// minimum and prize cards down to rank 10:
//  - every god card of the game (82) takes a turn as the headline card, a new one every ROTATE_HOURS (1 for now) on the hour;
//  - draws give premium-recruit cards (4-5 star), never the headline card;
//  - the ranking is per featured card (one round = ROTATE_HOURS): when it ends, 1st place wins that god card; every prize needs
//    LIMIT_SCORE points (so a free pull alone never pays gold), below it there is no prize.
const game = require('./game');
const settings = require('./settings');

const ROTATE_HOURS = 1;
const FIVE_PCT = 25, PITY = 10;
const FREE_EVERY = 24 * 3600;
const SCORE = 10;
const LIMIT_SCORE = 50;
const RANK_SHOWN = 20;
// [from rank, to rank, label, gold, god card of the round] (the reward list cuts text after ~12 letters)
const PRIZES = [
  [1, 1, '1st', 0, true],
  [2, 3, '2nd-3rd', 300, false],
  [4, 10, '4th-10th', 100, false],
];

const now = () => Math.floor(Date.now() / 1000);
const local = (t = now()) => t - new Date(t * 1000).getTimezoneOffset() * 60; // seconds on the local clock
const slotOf = (t = now()) => Math.floor(local(t) / (ROTATE_HOURS * 3600));
const roundOf = slotOf; // one ranking round per featured card
const roundEnd = (r) => { const end = (r + 1) * ROTATE_HOURS * 3600; return end + new Date(end * 1000).getTimezoneOffset() * 60; };
const esc = (s) => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

let gods = null;
// every god card ([4] 1 = a player card, [6] 0 = the attack version, [11] 6 stars, "God" in the name) with the drop that gives just that card
function godList() {
  if (!gods) {
    const drops = game.table('dropinfo').rows;
    gods = [...game.ninjas().values()].filter((r) => r[4] === 1 && r[6] === 0 && r[11] === 6 && /God/.test(r[2])).map((r) => {
      const d = drops.find((x) => x[3] === r[0] && x[12] !== 1 && [4, 5, 6, 7, 8, 9, 10, 11].every((i) => !x[i]));
      return { id: r[0], name: String(r[2]).replace(/（/g, ' (').replace(/）/g, ')').replace(/\s+/g, ' ').trim(), drop: d ? d[0] : 0 };
    }).filter((g) => g.drop).sort((a, b) => a.id - b.id);
  }
  return gods;
}
const godOf = (slot) => { const g = godList(); return g[slot % g.length]; };
const featured = (t = now()) => godOf(slotOf(t));

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS superninja (uid INTEGER, server_id INTEGER, round INTEGER, score INTEGER DEFAULT 0, at INTEGER DEFAULT 0,
      PRIMARY KEY(uid, server_id, round));
    CREATE TABLE IF NOT EXISTS superninja_me (uid INTEGER, server_id INTEGER, pity INTEGER DEFAULT 0, last_free INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id));
    CREATE TABLE IF NOT EXISTS superninja_paid (round INTEGER PRIMARY KEY, at INTEGER)`);
}
const on = (db) => settings.eventOn(db, 'superninja');
function me(db, pl) {
  ensure(db);
  return db.prepare('SELECT pity, last_free FROM superninja_me WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { pity: 0, last_free: 0 };
}
// (savepoints, not BEGIN: they also work inside a caller's transaction)
const toGo = (db, pl) => Math.max(1, PITY - me(db, pl).pity); // pulls until the sure five-star card; the screen and the pray dialog both show the number sent - 1
const freeLeft = (db, pl) => Math.max(0, me(db, pl).last_free + FREE_EVERY - now());
function board(db, sid, round = roundOf()) {
  ensure(db);
  return db.prepare(`SELECT s.uid, s.score, p.nick FROM superninja s JOIN players p ON p.uid=s.uid AND p.server_id=s.server_id
    WHERE s.server_id=? AND s.round=? AND s.score>0 ORDER BY s.score DESC, s.at ASC`).all(sid, round);
}
function prizeFor(rank, score) {
  if (score < LIMIT_SCORE) return null; // "The MINIMUM for 1st prise is ..." (for every prize here)
  return PRIZES.find(([a, b]) => rank >= a && rank <= b);
}

// Rounds that ended: mail their prizes to the Awards chest, once.
function settle(db) {
  ensure(db);
  const cur = roundOf();
  const rounds = db.prepare('SELECT DISTINCT round FROM superninja WHERE round<? AND round NOT IN (SELECT round FROM superninja_paid)').all(cur).map((r) => r.round);
  for (const round of rounds) {
    db.exec('SAVEPOINT superninja');
    try {
      db.prepare('INSERT INTO superninja_paid(round, at) VALUES(?,?)').run(round, now());
      for (const { server_id: sid } of db.prepare('SELECT DISTINCT server_id FROM superninja WHERE round=?').all(round)) {
        board(db, sid, round).forEach((r, i) => {
          const p = prizeFor(i + 1, r.score);
          const god = godOf(round);
          if (p) require('./awardcenter').send(db, { uid: r.uid, server_id: sid }, 'Limited Super Ninja', `You finished #${i + 1} with ${r.score} points in the ${god.name} hour. Your prize: ${p[4] ? god.name : p[3] + ' gold'}.`, { gold: p[3], drops: p[4] ? [god.drop] : [] });
        });
      }
      db.exec('RELEASE superninja');
    } catch (e) { db.exec('ROLLBACK TO superninja'); db.exec('RELEASE superninja'); throw e; }
  }
}

function myRank(db, pl) {
  const b = board(db, pl.server_id);
  const i = b.findIndex((r) => r.uid === pl.uid);
  return { rank: i >= 0 ? i + 1 : 0, score: i >= 0 ? b[i].score : 0, board: b };
}
const rankRows = (b) => '<ranklist>' + b.slice(0, RANK_SHOWN).map((r, i) => `<item rank="${i + 1}" nick="${esc(r.nick)}" score="${r.score}"/>`).join('') + '</ranklist>';

// screen state: who has the event open (so their premium-recruit requests are event pulls)
const open = new Map();
const key = (pl) => pl.uid + ':' + pl.server_id;
const OPEN_FOR = 30 * 60;
const isOpen = (db, pl) => on(db) && (open.get(key(pl)) || 0) > now() - OPEN_FOR;
const leave = (uid, sid) => open.delete(uid + ':' + sid);

function infoXml(db, pl) {
  if (!on(db)) return null;
  settle(db);
  open.set(key(pl), now());
  const m = myRank(db, pl), t = now();
  const hhmm = (s) => String(Math.floor((((slotOf(t) + s) * ROTATE_HOURS * 3600) % 86400) / 3600)).padStart(2, '0') + ':00';
  const next = [0, 1, 2, 3, 4].map((s) => ({ g: featured(t + s * ROTATE_HOURS * 3600), s }));
  return `<preview resttime="${roundEnd(roundOf()) - t}" nexttime="${freeLeft(db, pl)}" protect="${toGo(db, pl) + 1}" gold="${game.COST[1]}" status="0" actstatus="1" limitscore="${LIMIT_SCORE}"/>` +
    '<ninjalist>' + next.map(({ g, s }) => `<item name="${esc(s ? `At ${hhmm(s)}: ${g.name}` : `Prize: ${g.name}`)}" ninjiaid="${g.id}" attr="3" dropid="${g.drop}"/>`).join('') + '</ninjalist>' +
    rankRows(m.board) + `<myrank rank="${m.rank || '-'}" score="${m.score}"/>` +
    // one row per prize, like the original list (the card itself is named above: "Prize: ..."; the 50-point minimum is the screen's own line)
    '<rewardlist>' + PRIZES.map((p) => `<item rankrange="${esc(p[2])}" dropinfo="${esc(p[4] ? 'God card' : `${p[3]} gold`)}"/>`).join('') + '</rewardlist>';
}
function refreshXml(db, pl) {
  if (!on(db)) return null;
  settle(db);
  open.set(key(pl), now());
  const m = myRank(db, pl);
  return `<preview nextfreetime="${freeLeft(db, pl)}" protect="${toGo(db, pl) + 1}" status="0" actstatus="1" rank="${m.rank || '-'}" score="${m.score}"/>` + rankRows(m.board);
}

// count 1 or 10; free = the Lua's free pull. Returns { cost, got, toGo } like game.pull (for game.pullXml) or { error } / { code }.
function pull(db, pl, count, free) {
  if (!on(db)) return { code: 312000 }; // "the event is over"
  settle(db);
  if (free && (count !== 1 || freeLeft(db, pl) > 0)) return { code: 80003 }; // free pull not ready
  const cost = free ? 0 : count === 10 ? game.TEN_COST[1] : game.COST[1];
  const gold = db.prepare('SELECT gold FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id).gold;
  if (gold < cost) return { error: 'not enough gold' };
  let { pity } = me(db, pl);
  const got = [];
  db.exec('SAVEPOINT superninja');
  try {
    db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
    for (let i = 0; i < count; i++) {
      const nid = game.rollOne(1, pity >= PITY - 1 || Math.random() * 100 < FIVE_PCT ? 5 : 0);
      pity = ((game.ninjas().get(nid) || [])[11] || 0) >= 5 ? 0 : pity + 1;
      got.push({ ninja: nid, seq: game.giveCard(db, pl.uid, pl.server_id, nid) });
    }
    db.prepare(`INSERT INTO superninja_me(uid, server_id, pity, last_free) VALUES(?,?,?,?)
      ON CONFLICT(uid, server_id) DO UPDATE SET pity=excluded.pity, last_free=excluded.last_free`).run(pl.uid, pl.server_id, pity, free ? now() : me(db, pl).last_free);
    db.prepare(`INSERT INTO superninja(uid, server_id, round, score, at) VALUES(?,?,?,?,?)
      ON CONFLICT(uid, server_id, round) DO UPDATE SET score=score+excluded.score, at=excluded.at`).run(pl.uid, pl.server_id, roundOf(), SCORE * count, now());
    db.exec('RELEASE superninja');
  } catch (e) { db.exec('ROLLBACK TO superninja'); db.exec('RELEASE superninja'); throw e; }
  open.set(key(pl), now());
  return { cost, got, toGo: Math.max(1, PITY - pity) + 1 }; // the pray dialog shows protect_comming - 1 (like the screen's own label)
}

module.exports = { infoXml, refreshXml, pull, isOpen, leave, toGo, settle, godList, featured, LIMIT_SCORE, PITY };
