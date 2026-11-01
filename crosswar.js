// Cross-server battle ("celestial ladder"; Lua ui_layer/multi_battle/*, opened from the Base). The game sends it to MULTI_BATTLE_CGI_IP,
// which hot update 28.0.22 (cdn/src/script/util/common.lua) points at this server.
// Endpoints: rl_r_cross_war (Cmd 0 / 1 + Page: state + list), rl_w_cwar (Cmd 1 ticket, 2 inspire, 3 exchange ExchId, 4 top-10 reward),
// rl_w_cwar_war (Cmd 1 Pos: fight for a ladder position), rl_r_crosswar_rank (Cmd 1 present / 2 server / 3 nation / 4 history).
// ORIGINAL (the game's own help text ui_multi_description + photos 1422, 3238, 0476, 3015):
//   arena top 20 enter for free, others buy a 500-gold ticket; the list is made Friday 8 pm, the battle is Saturday 8-9 pm;
//   holding a ladder position earns points every second (positions 44-45 +5, 46-49 +3, no position +0); morale boost 200 gold = +10 %
//   attack and defence for 300 s; exchange prices 24 000 / 100 000 / 300 000 / 600 000 / 850 000 points (points add up across weeks).
// (ours): 50 positions (the photos show 49 and a 0 = "no position"), the points of positions 1-43, bots holding the ladder at the start,
//   their strength, the swap rule, 5 boosts per battle, the exchange items and the top-10 rewards.
const game = require('./game');
const el = (n, v) => `<${n}>${String(v).replace(/[<>&"]/g, '')}</${n}>`;

const SLOTS = 50, TICKET = 500, INSPIRE_COST = 200, INSPIRE_PCT = 10, INSPIRE_SECS = 300, INSPIRE_MAX = 5, ARENA_FREE = 20;
// points a second by position (44-45 = 5 and 46-49 = 3 are original; the rest ours)
const rate = (pos) => (pos <= 0 ? 0 : pos === 1 ? 50 : pos === 2 ? 40 : pos === 3 ? 35 : pos <= 5 ? 30 : pos <= 10 ? 20 : pos <= 20 ? 15 : pos <= 30 ? 10 : pos <= 45 ? 5 : 3);
const BOT_NAMES = ['ShadowKage', 'Narutokage', 'SilentRen', 'BlazeMika', 'RogueKaito', 'UchihaRyu', 'SandStorm', 'MistBlade', 'IronLeaf', 'StormFang'];
const NATION = ['Wind', 'Thunder', 'Water', 'Fire', 'Earth'];
const EXCHANGE = [ // id, cost (original), what you get (ours), icon from props/
  { id: 1, cost: 24000, icon: 'props_170', desc: 'A 4 or 5-star shinobi card (like the 1-in-10000 recruit)', drop: 11 },
  { id: 2, cost: 100000, icon: 'props_035', desc: '10 Sage Stone III', props: [[8, 10]] },
  { id: 3, cost: 300000, icon: 'props_028', desc: 'A 5-star ninjutsu card', drop: 14 },
  { id: 4, cost: 600000, icon: 'props_029', desc: 'A 5-star weapon card', drop: 125 },
  { id: 5, cost: 850000, icon: 'props_010', desc: 'Kaguya (God) shinobi card', ninja: 2085 },
];
const TOP10 = (rank) => (rank === 1 ? { cash: 1000, ss: 30 } : rank === 2 ? { cash: 800, ss: 20 } : rank === 3 ? { cash: 600, ss: 15 } : { cash: 300, ss: 10 });

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS cwar_entry (week INTEGER, uid INTEGER, sid INTEGER, paid INTEGER DEFAULT 0, score INTEGER DEFAULT 0, pos INTEGER DEFAULT 0, PRIMARY KEY(week, uid, sid));
    CREATE TABLE IF NOT EXISTS cwar_pos (week INTEGER, pos INTEGER, holder TEXT, since INTEGER, PRIMARY KEY(week, pos));
    CREATE TABLE IF NOT EXISTS cwar_bot (week INTEGER, id INTEGER, score INTEGER DEFAULT 0, PRIMARY KEY(week, id));
    CREATE TABLE IF NOT EXISTS cwar_inspire (week INTEGER, uid INTEGER, sid INTEGER, t INTEGER);
    CREATE TABLE IF NOT EXISTS cwar_bank (uid INTEGER, sid INTEGER, points INTEGER DEFAULT 0, PRIMARY KEY(uid, sid));
    CREATE TABLE IF NOT EXISTS cwar_claim (week INTEGER, uid INTEGER, sid INTEGER, PRIMARY KEY(week, uid, sid));`);
}

// The week ends Saturday 21:00 (server time). Registration until Friday 20:00 (status 1), list made / waiting (status 3) until Saturday 20:00,
// battle (status 2) until 21:00. week = that Saturday-21:00 in unix seconds. HB_CWAR_PHASE=1|2|3 forces a phase (testing).
function phase(nowMs = Date.now()) {
  const d = new Date(nowMs);
  const end = new Date(d.getFullYear(), d.getMonth(), d.getDate() + ((6 - d.getDay() + 7) % 7), 21, 0, 0);
  if (end.getTime() <= nowMs) end.setDate(end.getDate() + 7);
  const E = end.getTime(), S = E - 3600e3, F = E - 25 * 3600e3;
  const week = Math.floor(E / 1000);
  const forced = Number(process.env.HB_CWAR_PHASE) || 0;
  if (forced) {
    const fs = Math.floor(nowMs / 1000);
    return { status: forced, left: 3600, week, start: forced === 2 ? fs - 60 : Math.floor(S / 1000), end: forced === 2 ? fs + 3600 : Math.floor(E / 1000) };
  }
  const status = nowMs < F ? 1 : nowMs < S ? 3 : 2;
  const until = status === 1 ? F : status === 3 ? S : E;
  return { status, left: Math.max(1, Math.ceil((until - nowMs) / 1000)), week, start: Math.floor(S / 1000), end: Math.floor(E / 1000) };
}
const prevWeek = (w) => w - 7 * 86400;

function arenaRank(db, uid) { try { const r = db.prepare('SELECT rank FROM arena WHERE uid=?').get(uid); return r ? r.rank : 0; } catch (e) { return 0; } }
function entry(db, week, pl) { return db.prepare('SELECT * FROM cwar_entry WHERE week=? AND uid=? AND sid=?').get(week, pl.uid, pl.server_id); }
// in = bought a ticket, or arena top 20 (frozen into cwar_entry when the list is made)
function isIn(db, ph, pl) {
  const e = entry(db, ph.week, pl);
  if (e) return true;
  if (ph.status === 1) { const r = arenaRank(db, pl.uid); return r > 0 && r <= ARENA_FREE; }
  return false;
}
// Make the list once per week (first request after Friday 20:00): arena top 20 join for free; bots hold all 50 positions.
function buildList(db, ph) {
  if (ph.status === 1) return;
  if (db.prepare('SELECT 1 FROM cwar_pos WHERE week=? LIMIT 1').get(ph.week)) return;
  const put = db.prepare('INSERT OR IGNORE INTO cwar_entry(week,uid,sid,paid) VALUES(?,?,?,2)');
  try {
    for (const r of db.prepare('SELECT uid FROM arena WHERE rank BETWEEN 1 AND ? AND uid > 0').all(ARENA_FREE)) {
      const p = db.prepare('SELECT uid, server_id FROM players WHERE uid=?').get(r.uid);
      if (p) put.run(ph.week, p.uid, p.server_id);
    }
  } catch (e) { /* no arena yet */ }
  const pos = db.prepare('INSERT INTO cwar_pos(week,pos,holder,since) VALUES(?,?,?,?)'), bot = db.prepare('INSERT OR IGNORE INTO cwar_bot(week,id) VALUES(?,?)');
  for (let p = 1; p <= SLOTS; p++) { pos.run(ph.week, p, 'b:' + p, ph.start); bot.run(ph.week, p); }
}
// Pay the points earned since the last look: rate(position) for every second inside the battle hour.
function settle(db, ph) {
  if (ph.status !== 2) return;
  const now = Math.min(Math.floor(Date.now() / 1000), ph.end);
  for (const r of db.prepare('SELECT * FROM cwar_pos WHERE week=?').all(ph.week)) {
    const from = Math.max(r.since, ph.start), secs = now - from;
    if (secs <= 0) continue;
    const pts = rate(r.pos) * secs;
    if (r.holder.startsWith('b:')) db.prepare('UPDATE cwar_bot SET score=score+? WHERE week=? AND id=?').run(pts, ph.week, Number(r.holder.slice(2)));
    else {
      const [, uid, sid] = r.holder.split(':').map(Number);
      db.prepare('UPDATE cwar_entry SET score=score+? WHERE week=? AND uid=? AND sid=?').run(pts, ph.week, uid, sid);
      db.prepare('INSERT INTO cwar_bank(uid,sid,points) VALUES(?,?,?) ON CONFLICT DO UPDATE SET points=points+excluded.points').run(uid, sid, pts);
    }
    db.prepare('UPDATE cwar_pos SET since=? WHERE week=? AND pos=?').run(now, ph.week, r.pos);
  }
}
function prepare(db) { ensure(db); const ph = phase(); buildList(db, ph); settle(db, ph); return ph; }

// Everyone of a week with their score, best first (players and bots) -> ranks.
function standings(db, week) {
  const rows = db.prepare('SELECT e.uid, e.sid, e.score, p.nick, p.country, p.level FROM cwar_entry e LEFT JOIN players p ON p.uid=e.uid AND p.server_id=e.sid WHERE e.week=?').all(week)
    .map((r) => ({ key: `p:${r.uid}:${r.sid}`, uid: r.uid, zone: r.sid, name: r.nick || 'Ninja', score: r.score, country: r.country || 1, level: r.level || 1 }));
  for (const b of db.prepare('SELECT * FROM cwar_bot WHERE week=?').all(week)) rows.push({ key: 'b:' + b.id, uid: 9300000 + b.id, zone: botZone(b.id), name: botName(b.id), score: b.score, country: b.id % 5, level: botLevel(b.id), bot: true });
  rows.sort((a, b) => b.score - a.score || (a.bot ? 1 : 0) - (b.bot ? 1 : 0));
  rows.forEach((r, i) => { r.rank = i + 1; });
  return rows;
}
const botName = (id) => BOT_NAMES[id % BOT_NAMES.length] + id;
const botZone = (id) => 1 + ((id * 37) % 79);
const botLevel = (id) => 150 + ((id * 53) % 200);
const botNinja = (id) => { const pool = Array.from(game.ninjas().values()).filter((r) => r[4] === 1 && r[11] >= 5); return pool[(id * 31) % pool.length][0]; };

function holderInfo(db, holder) {
  if (holder.startsWith('b:')) { const id = Number(holder.slice(2)); return { uid: 9300000 + id, zone: botZone(id), name: botName(id), level: botLevel(id), vip: id % 13, card: { id: botNinja(id), life: id % 4, strength: 3 + (id % 4) } }; }
  const [, uid, sid] = holder.split(':').map(Number);
  const p = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(uid, sid) || { nick: 'Ninja', level: 1 };
  return { uid, zone: sid, name: p.nick, level: p.level, vip: require('./vip').level(db, uid, sid), card: myCard(db, uid, sid) };
}
function myCard(db, uid, sid) {
  const c = db.prepare('SELECT c.ninja_id, c.newlife, c.starlevel FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot LIMIT 1').get(uid, sid);
  return c ? { id: c.ninja_id, life: c.newlife || 0, strength: c.starlevel || 0 } : { id: 57, life: 0, strength: 0 };
}
const cardXml = (c) => `<card>${el('id', c.id)}${el('life', c.life)}${el('strength', c.strength)}</card>`;

function inspires(db, ph, pl) {
  const now = Math.floor(Date.now() / 1000);
  return db.prepare('SELECT t FROM cwar_inspire WHERE week=? AND uid=? AND sid=?').all(ph.week, pl.uid, pl.server_id).map((r) => r.t + INSPIRE_SECS - now);
}
function userXml(db, ph, pl, stand) {
  const e = entry(db, ph.week, pl), inn = isIn(db, ph, pl), pos = e ? e.pos : 0;
  const me = stand.find((s) => s.key === `p:${pl.uid}:${pl.server_id}`);
  const ins = inspires(db, ph, pl), live = ins.filter((x) => x > 0);
  const lastWeek = standings(db, prevWeek(ph.week)).find((s) => s.key === `p:${pl.uid}:${pl.server_id}`);
  const rank = ph.status === 2 ? (me ? me.rank : 0) : (lastWeek ? lastWeek.rank : 0);
  const score = ph.status === 2 ? (me ? me.score : 0) : (lastWeek ? lastWeek.score : 0);
  return `<user>${el('uid', pl.uid)}${el('isin', inn ? 1 : 0)}${el('posid', pos)}${el('pf', 1)}${el('zone', pl.server_id)}${el('rank', rank)}${el('score', score)}` +
    `${el('extra', live.length * INSPIRE_PCT)}${el('extra_timeleft', live.length ? Math.max(...live) : 0)}${el('keep_left', 0)}${el('timeval', 1)}${el('addscore', rate(pos))}` +
    `${el('viplevel', require('./vip').level(db, pl.uid, pl.server_id))}${el('playerlevel', pl.level)}${el('extra_times_lmt', INSPIRE_MAX)}` +
    `<extra_time_lefts>${live.map((x) => `<item>${el('timeleft', x)}</item>`).join('')}</extra_time_lefts>${cardXml(myCard(db, pl.uid, pl.server_id))}</user>`;
}
function rowXml(o) {
  return `<item>${el('uid', o.uid)}${el('posid', o.pos)}${el('pf', 1)}${el('zone', o.zone)}${el('rank', o.rank)}${el('score', o.score)}${el('keep_left', 0)}${el('timeval', 1)}` +
    `${el('addscore', rate(o.pos))}${el('viplevel', o.vip)}${el('name', o.name)}${el('playerlevel', o.level)}${cardXml(o.card)}</item>`;
}
// The list: battle = the positions just above mine (no position: the lowest 10); before the battle = who is in, 10 a page.
function listXml(db, ph, pl, page, stand) {
  let rows = [];
  if (ph.status === 2) {
    const e = entry(db, ph.week, pl), pos = e ? e.pos : 0;
    const lo = pos === 0 ? SLOTS - 9 : pos === 1 ? 2 : Math.max(1, pos - 6), hi = pos === 0 ? SLOTS : pos === 1 ? 7 : pos - 1;
    for (const r of db.prepare('SELECT * FROM cwar_pos WHERE week=? AND pos BETWEEN ? AND ? ORDER BY pos').all(ph.week, lo, hi)) {
      const h = holderInfo(db, r.holder), s = stand.find((x) => x.key === r.holder) || { rank: 0, score: 0 };
      rows.push({ ...h, pos: r.pos, rank: s.rank, score: s.score });
    }
  } else {
    const week = ph.week, last = standings(db, prevWeek(week));
    let keys = db.prepare('SELECT uid, sid FROM cwar_entry WHERE week=?').all(week).map((r) => `p:${r.uid}:${r.sid}`);
    if (ph.status === 1) { try { for (const r of db.prepare('SELECT uid FROM arena WHERE rank BETWEEN 1 AND ? AND uid > 0').all(ARENA_FREE)) { const p = db.prepare('SELECT server_id FROM players WHERE uid=?').get(r.uid); if (p && !keys.includes(`p:${r.uid}:${p.server_id}`)) keys.push(`p:${r.uid}:${p.server_id}`); } } catch (e) { /* no arena */ } }
    if (!keys.length) keys = last.slice(0, 10).map((s) => s.key); // nobody in yet: show last week's best
    rows = keys.map((k) => { const h = holderInfo(db, k), s = last.find((x) => x.key === k) || { rank: 0, score: 0 }; return { ...h, rank: s.rank, score: s.score }; })
      .sort((a, b) => (a.rank || 999) - (b.rank || 999));
    rows.forEach((r, i) => { r.pos = i + 1; });
    const p = Math.max(1, Number(page) || 1);
    rows = rows.slice((p - 1) * 10, p * 10);
  }
  return `<positionlist>${rows.map(rowXml).join('')}</positionlist>`;
}
function stateXml(db, pl, page) {
  const ph = prepare(db);
  const stand = ph.status === 2 ? standings(db, ph.week) : [];
  return `${el('warlefttime', ph.left)}${el('curwarid', ph.week)}${el('status', ph.status)}${userXml(db, ph, pl, stand)}${listXml(db, ph, pl, page, stand)}`;
}

// ---- actions --------------------------------------------------------------------------------------------------------------------
function buyTicket(db, pl) {
  const ph = prepare(db);
  if (ph.status !== 1) return { error: 'registration is closed' };
  if (isIn(db, ph, pl)) return { error: 'you are already in' };
  const p = db.prepare('SELECT gold FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  if (p.gold < TICKET) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(TICKET, pl.uid, pl.server_id);
  db.prepare('INSERT OR IGNORE INTO cwar_entry(week,uid,sid,paid) VALUES(?,?,?,1)').run(ph.week, pl.uid, pl.server_id);
  return { xml: '' };
}
function inspire(db, pl) {
  const ph = prepare(db);
  if (ph.status !== 2 || !entry(db, ph.week, pl)) return { error: 'only during the battle' };
  if (inspires(db, ph, pl).length >= INSPIRE_MAX) return { error: 'no more morale boosts this battle' };
  const p = db.prepare('SELECT gold FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  if (p.gold < INSPIRE_COST) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(INSPIRE_COST, pl.uid, pl.server_id);
  db.prepare('INSERT INTO cwar_inspire VALUES(?,?,?,?)').run(ph.week, pl.uid, pl.server_id, Math.floor(Date.now() / 1000));
  const live = inspires(db, ph, pl).filter((x) => x > 0);
  return { xml: `${el('extra', live.length * INSPIRE_PCT)}${el('extra_left', Math.max(...live))}<extra_time_lefts>${live.map((x) => `<item>${el('timeleft', x)}</item>`).join('')}</extra_time_lefts>` };
}
function bank(db, pl) { const r = db.prepare('SELECT points FROM cwar_bank WHERE uid=? AND sid=?').get(pl.uid, pl.server_id); return r ? r.points : 0; }
function rewardXml(db, pl, r) {
  if (r.drop) return game.grantDrop(db, pl, r.drop);
  if (r.ninja) return game.awardXml({ ninja: r.ninja, seq: game.giveCard(db, pl.uid, pl.server_id, r.ninja) });
  const props = r.props || [];
  for (const [id, n] of props) game.propAdd(db, pl.uid, pl.server_id, id, n);
  if (r.cash) db.prepare('UPDATE players SET gold=gold+? WHERE uid=? AND server_id=?').run(r.cash, pl.uid, pl.server_id);
  return `<award dropid="1"><cardlist></cardlist><proplist>${props.map(([id, n]) => `<prop>${el('id', id)}${el('num', n)}</prop>`).join('')}</proplist><chipbag></chipbag>` +
    `<coin>0</coin><cash>${r.cash || 0}</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>`;
}
function exchange(db, pl, id) {
  ensure(db);
  const x = EXCHANGE.find((e) => e.id === Number(id));
  if (!x) return { error: 'no such reward' };
  if (bank(db, pl) < x.cost) return { error: 'not enough points' };
  db.prepare('UPDATE cwar_bank SET points=points-? WHERE uid=? AND sid=?').run(x.cost, pl.uid, pl.server_id);
  const award = rewardXml(db, pl, x);
  return { xml: el('myscore_left', bank(db, pl)) + award };
}
function topTen(db, pl) {
  const ph = prepare(db);
  if (ph.status !== 3) return { error: 'rewards can be claimed after the list is made (Friday 8 pm) until the battle' };
  const w = prevWeek(ph.week), me = standings(db, w).find((s) => s.key === `p:${pl.uid}:${pl.server_id}`);
  if (!me || me.rank > 10) return { error: 'you are not in last week\'s top 10' };
  if (db.prepare('SELECT 1 FROM cwar_claim WHERE week=? AND uid=? AND sid=?').get(w, pl.uid, pl.server_id)) return { error: 'already claimed' };
  db.prepare('INSERT INTO cwar_claim VALUES(?,?,?)').run(w, pl.uid, pl.server_id);
  const t = TOP10(me.rank);
  return { xml: rewardXml(db, pl, { cash: t.cash, props: [[8, t.ss]] }) };
}
// Fight the holder of a position above mine (the result is decided like the arena: my average attack x luck against theirs; bots scale
// with the challenger: position 50 = 60 % of my strength, position 1 = 140 % (ours)). A win swaps the two positions.
function fight(db, pl, pos) {
  const ph = prepare(db);
  pos = Number(pos);
  if (ph.status !== 2) return { error: 'the battle is Saturday 8-9 pm' };
  const e = entry(db, ph.week, pl);
  if (!e) return { error: 'you are not in this battle' };
  const target = db.prepare('SELECT * FROM cwar_pos WHERE week=? AND pos=?').get(ph.week, pos);
  if (!target || (e.pos && pos >= e.pos)) return { error: 'challenge a position above yours' };
  if (target.holder === `p:${pl.uid}:${pl.server_id}`) return { error: 'that is you' };
  const ts = game.teamStats(db, pl.uid, pl.server_id);
  const boost = 1 + inspires(db, ph, pl).filter((x) => x > 0).length * INSPIRE_PCT / 100;
  const mine = (ts.total.al + ts.total.ah) / 2 / Math.max(1, ts.slots.length) * boost;
  let theirs, foeIds;
  if (target.holder.startsWith('b:')) {
    theirs = mine / boost * (0.6 + 0.8 * (SLOTS - pos) / (SLOTS - 1));
    const id = Number(target.holder.slice(2));
    foeIds = game.foeTeam(db, 9300000 + id, pl.server_id, botNinja(id), botLevel(id), 0, ts.slots.length);
  } else {
    const [, uid, sid] = target.holder.split(':').map(Number);
    const t2 = game.teamStats(db, uid, sid);
    theirs = (t2.total.al + t2.total.ah) / 2 / Math.max(1, t2.slots.length);
    const op = db.prepare('SELECT level FROM players WHERE uid=? AND server_id=?').get(uid, sid);
    foeIds = game.foeTeam(db, uid, sid, myCard(db, uid, sid).id, op ? op.level : 1);
  }
  const win = process.env.HB_CWAR ? process.env.HB_CWAR === 'win' : mine * (0.75 + Math.random() * 0.5) >= theirs;
  const h = holderInfo(db, target.holder);
  const xml = game.battleXml(db, pl, 0, 1, { enemyIds: foeIds, ratio: theirs / Math.max(1, mine), enemyName: h.name, enemyUid: h.uid, enemyLevel: h.level, win });
  if (win) {
    const now = Math.floor(Date.now() / 1000), mineKey = `p:${pl.uid}:${pl.server_id}`;
    settle(db, ph); // pay both sides up to now before the positions change
    db.prepare('UPDATE cwar_pos SET holder=?, since=? WHERE week=? AND pos=?').run(mineKey, now, ph.week, pos);
    if (e.pos) db.prepare('UPDATE cwar_pos SET holder=?, since=? WHERE week=? AND pos=?').run(target.holder, now, ph.week, e.pos);
    db.prepare('UPDATE cwar_entry SET pos=? WHERE week=? AND uid=? AND sid=?').run(pos, ph.week, pl.uid, pl.server_id);
    if (!target.holder.startsWith('b:')) { const [, uid, sid] = target.holder.split(':').map(Number); db.prepare('UPDATE cwar_entry SET pos=? WHERE week=? AND uid=? AND sid=?').run(e.pos || 0, ph.week, uid, sid); }
  }
  const stand = standings(db, ph.week);
  return { win, xml: '<userinfo><LastSPUpdatePastTime>0</LastSPUpdatePastTime></userinfo>' + xml + game.awardFull({}) +
    `<newlist>${userXml(db, ph, pl, stand)}${listXml(db, ph, pl, 1, stand)}</newlist>` };
}

// ---- rankings -------------------------------------------------------------------------------------------------------------------
function rankXml(db, pl, tab) {
  const ph = prepare(db);
  const week = ph.status === 2 ? ph.week : prevWeek(ph.week);
  const stand = standings(db, week);
  let rows = [];
  tab = Number(tab) || 1;
  if (tab === 1) rows = stand.slice(0, 50).map((s) => [s.uid, s.rank, s.zone, s.name, s.score]);
  else if (tab === 2 || tab === 3) {
    const by = new Map();
    for (const s of stand) { const k = tab === 2 ? s.zone : s.country; by.set(k, (by.get(k) || 0) + s.score); }
    rows = [...by.entries()].sort((a, b) => b[1] - a[1]).map(([k, v], i) => [0, i + 1, tab === 2 ? k : 1, tab === 2 ? 'Area ' + k : NATION[((k % 5) + 5) % 5], v]);
  } else {
    const weeks = db.prepare('SELECT DISTINCT week FROM cwar_bot WHERE week < ? ORDER BY week DESC LIMIT 20').all(ph.status === 2 ? ph.week : ph.week + 1).map((r) => r.week);
    rows = weeks.map((w, i) => { const top = standings(db, w)[0]; return top ? [top.uid, i + 1, top.zone, top.name, top.score] : null; }).filter(Boolean);
  }
  const me = stand.find((s) => s.key === `p:${pl.uid}:${pl.server_id}`);
  // <player> must come first: the Lua reads item:find("score" / "rank" / "zone" / "uid") from the root
  const player = `<player>${el('score', me ? me.score : 0)}${el('rank', me ? me.rank : 0)}${el('zone', pl.server_id)}${el('uid', pl.uid)}${el('score_left', bank(db, pl))}</player>`;
  const list = `<rank_list>${rows.map((r) => `<item col0="${r[0]}" col1="${r[1]}" col2="${r[2]}" col3="${String(r[3]).replace(/[<>&"]/g, '')}" col4="${r[4]}"/>`).join('')}</rank_list>`;
  const pk = `<score_package>${EXCHANGE.map((x) => `<item>${el('id', x.id)}${el('icon', x.icon)}${el('cost', x.cost)}${el('desc', x.desc + ' (' + x.cost + ' points)')}</item>`).join('')}</score_package>`;
  const top = `<topten_award>${Array.from({ length: 10 }, (_, i) => { const t = TOP10(i + 1); return `<item>${el('id', i + 1)}${el('rank', i + 1)}${el('desc', `Rank ${i + 1}: ${t.cash} gold + ${t.ss} Sage Stone III`)}</item>`; }).join('')}</topten_award>`;
  return player + list + pk + top;
}

module.exports = { phase, rate, stateXml, buyTicket, inspire, exchange, topTen, fight, rankXml, standings, prepare };
