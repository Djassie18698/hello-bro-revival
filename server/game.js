// Game-state helpers: cards (characters), teams, starter grants. Data tables live in ./data/*.json
const fs = require('fs');
const settings = require('./settings');
const path = require('path');

// Read once and kept: this re-read and re-parsed the file on EVERY call, and a stat calculation makes many calls, so a player with
// 2000 cards pressing "Best gear" froze the cloud server for ~10 minutes (3 Nov 2026). Frozen, so a stray write can't change the cache
// (a write was lost before too: every call got a fresh copy).
const tableCache = new Map();
const freeze = (o) => { if (o && typeof o === 'object' && !Object.isFrozen(o)) { Object.freeze(o); for (const v of Object.values(o)) freeze(v); } return o; };
const table = (name) => {
  if (!tableCache.has(name)) tableCache.set(name, freeze(JSON.parse(fs.readFileSync(path.join(__dirname, 'data', name + '.json'), 'utf8'))));
  return tableCache.get(name);
};
let ninjaById = null;
const ninjas = () => {
  if (!ninjaById) {
    ninjaById = new Map();
    for (const r of table('ninjainfo').rows) ninjaById.set(r[0], r);
  }
  return ninjaById;
};

let ready = new WeakSet();
function ensure(db) {
  if (ready.has(db)) return;
  db.exec(`
    CREATE TABLE IF NOT EXISTS cards (
      seq INTEGER PRIMARY KEY AUTOINCREMENT,
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL,
      type INTEGER NOT NULL DEFAULT 1, ninja_id INTEGER NOT NULL,
      level INTEGER NOT NULL DEFAULT 1, exp INTEGER NOT NULL DEFAULT 0, starlevel INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE IF NOT EXISTS team (
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL, slot INTEGER NOT NULL, seq INTEGER NOT NULL,
      PRIMARY KEY (uid, server_id, slot)
    );
    CREATE TABLE IF NOT EXISTS progress (
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL, chap INTEGER NOT NULL, stage INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (uid, server_id, chap)
    );
    CREATE TABLE IF NOT EXISTS equipped (
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL, slot INTEGER NOT NULL, kind INTEGER NOT NULL, seq INTEGER NOT NULL,
      PRIMARY KEY (uid, server_id, slot, kind)
    );
    CREATE INDEX IF NOT EXISTS cards_owner ON cards(uid, server_id);
    CREATE TABLE IF NOT EXISTS team_alt (
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL, slot INTEGER NOT NULL, seq INTEGER NOT NULL,
      PRIMARY KEY (uid, server_id, slot)
    );
    CREATE TABLE IF NOT EXISTS equipped_alt (
      uid INTEGER NOT NULL, server_id INTEGER NOT NULL, slot INTEGER NOT NULL, kind INTEGER NOT NULL, seq INTEGER NOT NULL,
      PRIMARY KEY (uid, server_id, slot, kind)
    );
  `);
  try { db.exec('ALTER TABLE players ADD COLUMN active_team INTEGER NOT NULL DEFAULT 0'); } catch {}
  try { db.exec('ALTER TABLE players ADD COLUMN sp INTEGER NOT NULL DEFAULT -1'); } catch {}
  try { db.exec('ALTER TABLE players ADD COLUMN energy_t INTEGER NOT NULL DEFAULT 0'); } catch {}
  try { db.exec('ALTER TABLE players ADD COLUMN sp_t INTEGER NOT NULL DEFAULT 0'); } catch {}
  try { db.exec('ALTER TABLE players ADD COLUMN vip INTEGER NOT NULL DEFAULT 0'); } catch {}
  try { db.exec('ALTER TABLE players ADD COLUMN vipexp INTEGER NOT NULL DEFAULT 0'); } catch {}
  try { db.exec('ALTER TABLE cards ADD COLUMN newlife INTEGER NOT NULL DEFAULT 0'); } catch (e) { /* already there */ }
  for (const c of ['pot_att', 'pot_def', 'pot_ckr', 'pend_att', 'pend_def', 'pend_ckr', 'breaklvl', 'attri']) { try { db.exec(`ALTER TABLE cards ADD COLUMN ${c} INTEGER NOT NULL DEFAULT 0`); } catch (e) { /* already there */ } }
  ready.add(db);
}

// Starter characters: the one picked at character creation first, then the rest of Team 7-ish.
const STARTERS = { 1: 57, 2: 56, 3: 55 }; // Shikamaru, Sakura, Neji (the 3 choices on the create screen)
// Original start (normalconfig 38-42): only the chosen ninja, with its own starting ninjutsu equipped,
// plus 50 gold and 18000 silver (see rl_w_reg2).
const STARTER_JUTSU = { 55: 12, 57: 54, 56: 14 }; // Neji Gentle Fist, Shikamaru Shadow technique, Sakura Strength

// Ninjutsu (card type 6, ninjutsuinfo): in the original a ninjutsu triggers in battle with chance [4] for extra damage.
// Fights here are worked out from team stats, so an equipped ninjutsu adds its expected value: chance x 20% to attack (ours).
function ninjutsuBonus(st, id) {
  const r = table('ninjutsuinfo').rows.find((x) => x[0] === id);
  const pct = r ? (Number(r[4]) || 0) * 0.2 : 0;
  return { ...st, al: Math.round(st.al * (1 + pct)), ah: Math.round(st.ah * (1 + pct)) };
}
function giveCard(db, uid, sid, ninjaId, type = 1) {
  const r = db.prepare('INSERT INTO cards(uid,server_id,type,ninja_id) VALUES(?,?,?,?)').run(uid, sid, type, ninjaId);
  return Number(r.lastInsertRowid);
}

function ensureStarterTeam(db, uid, sid, pick) {
  ensure(db);
  const have = db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=? AND server_id=?').get(uid, sid).n;
  if (have > 0) return;
  const nid = STARTER_JUTSU[pick] ? pick : STARTERS[pick] || 57; // the create screen sends the ninja id itself (55/56/57)
  const seq = giveCard(db, uid, sid, nid);
  db.prepare('INSERT OR REPLACE INTO team(uid,server_id,slot,seq) VALUES(?,?,?,?)').run(uid, sid, 0, seq);
  const jutsu = giveCard(db, uid, sid, STARTER_JUTSU[nid], 6);
  db.prepare('INSERT OR REPLACE INTO equipped(uid,server_id,slot,kind,seq) VALUES(?,?,?,?,?)').run(uid, sid, 1, 5, jutsu);
}

// ---- Equipment (cards of type 2 weapon / 3 armor / 4 accessory; id = equipmentinfo id) -------
const equipRows = () => table('equipmentinfo').rows;
const SLOT_TYPE = { 0: 2, 1: 3, 2: 4 }; // equipmentinfo col3 slot -> card type
function giveEquip(db, uid, sid, equipId) {
  const e = equipRows().find((r) => r[0] === equipId);
  if (!e) return 0;
  return giveCard(db, uid, sid, equipId, SLOT_TYPE[e[3]] || 2);
}
function randomEquip(slot, minStar = 3, maxStar = 5) {
  let pool = equipRows().filter((r) => r[3] === slot && r[5] === 1 && r[6] >= minStar && r[6] <= maxStar);
  if (!pool.length) pool = equipRows().filter((r) => r[5] === 1 && r[6] >= minStar && r[6] <= maxStar);
  return pool[Math.floor(Math.random() * pool.length)][0];
}

const el = (n, v) => `<${n}>${v}</${n}>`;
function cardXml(c) {
  const f = {
    // attri 0 (never changed) is sent as 1 = water: the client names only 1-5 (Change Element showed "nil")
    type: c.type, id: c.ninja_id, exp: c.exp, seq: c.seq, level: c.level, attri: c.attri || 1, starlevel: c.starlevel,
    newlife: c.newlife || 0, tupo_level: c.breaklvl || 0, cha_tupo: 0, defence_tupo: 0, attack_tupo: 0, attackadd: 0, defenseadd: 0,
    attack_add: c.pot_att || 0, defence_add: c.pot_def || 0, cha_add: c.pot_ckr || 0, status: 0,
  };
  return '<card>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') + '</card>';
}

// One team slot as CTeamCard::firefly_InitFromXml reads it (ninjaid = the card's seq).
function slotXml(seq, slot, eq = {}, st = {}) {
  const f = { seq: slot + 1, ninjaid: seq, weaponid: eq[1] || 0, armorid: eq[2] || 0, decoratorid: eq[3] || 0, markid: eq[4] || 0,
    ninjintsu1seq: eq[5] || 0, ninjintsu2seq: eq[6] || 0, ninjintsu3seq: eq[7] || 0, ninjintsu4seq: eq[8] || 0,
    attacklow: st.al || 10, attackhigh: st.ah || 20, defenselow: st.dl || 5, defensehigh: st.dh || 10, chakralow: st.cl || 10, chakrahigh: st.ch || 20 };
  return '<ninja>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') +
    // gear / ninjutsu sets on this ninja (CTeamCard reads <skillsuit><item id num/>): the team card shows the set's icon
    `<skillsuit>${(st.sets || []).map((x) => `<item id="${x.id}" num="${x.num}"/>`).join('')}</skillsuit>` +
    // the card detail screen paints a chain red when its id is in <combinlist> (CNinjaDetailView::SetCombin); readycombinlist = a partner is owned but not in the team
    `<combinlist>${(st.active || []).map((id) => `<combin><combinid>${id}</combinid></combin>`).join('')}</combinlist>` +
    `<readycombinlist>${(st.ready || []).map((id) => `<combin><combinid>${id}</combinid></combin>`).join('')}</readycombinlist></ninja>`;
}

// ---- Second team line-up ("Team 2" tab on the team screen) -------------------------------------------------------------------
// ORIGINAL (the screen's own Detail text, normalconfig 211 = 100): "When the second team line-up has reached level 100, it is activated";
// it can use every shinobi, ninjutsu and equipment, also ones in Team 1; "activate team" picks the line-up that is used, only one at a
// time, the used one has a tick. The client: team index 0 = Team 1 (<ninjalist>/<suitlist>), 1 = Team 2 (<defenseninjalist>/
// <defensesuitlist>), activeTeamId = the used one; every edit sends TeamId, Activate sends rl_w_ninjalist 2310 ActiveId.
// Here the tables team / equipped always hold the USED line-up (fights, stats and every other screen read them), the other one waits in
// team_alt / equipped_alt; activating swaps the two.
const TEAM2_LEVEL = 100;
const USED = { team: 'team', equipped: 'equipped' }, WAITING = { team: 'team_alt', equipped: 'equipped_alt' };
const activeTeam = (db, uid, sid) => { ensure(db); return (db.prepare('SELECT active_team FROM players WHERE uid=? AND server_id=?').get(uid, sid) || {}).active_team || 0; };
const lineup = (db, uid, sid, idx) => ((Number(idx) === 1) === (activeTeam(db, uid, sid) === 1) ? USED : WAITING);
// a card in use: in either team, or worn by a ninja of either team (feeding, refining, succession and donating skip these)
const inLineup = (db, seq) => ['team', 'team_alt', 'equipped', 'equipped_alt'].some((t) => db.prepare(`SELECT 1 FROM ${t} WHERE seq=?`).get(seq));
function activateTeam(db, pl, idx) {
  ensure(db);
  idx = Number(idx) === 1 ? 1 : 0;
  if (idx === 1 && pl.level < TEAM2_LEVEL) return { error: `the second team opens at level ${TEAM2_LEVEL}` };
  if (idx === activeTeam(db, pl.uid, pl.server_id)) return {};
  if (!db.prepare('SELECT 1 FROM team_alt WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id)) return { error: 'put a shinobi in that team first' };
  db.exec('BEGIN');
  try {
    for (const [a, b] of [['team', 'team_alt'], ['equipped', 'equipped_alt']]) {
      db.exec(`CREATE TEMP TABLE IF NOT EXISTS swap_${a} AS SELECT * FROM ${a} WHERE 0`);
      db.prepare(`INSERT INTO swap_${a} SELECT * FROM ${a} WHERE uid=? AND server_id=?`).run(pl.uid, pl.server_id);
      db.prepare(`DELETE FROM ${a} WHERE uid=? AND server_id=?`).run(pl.uid, pl.server_id);
      db.prepare(`INSERT INTO ${a} SELECT * FROM ${b} WHERE uid=? AND server_id=?`).run(pl.uid, pl.server_id);
      db.prepare(`DELETE FROM ${b} WHERE uid=? AND server_id=?`).run(pl.uid, pl.server_id);
      db.prepare(`INSERT INTO ${b} SELECT * FROM swap_${a}`).run();
      db.exec(`DELETE FROM swap_${a}`);
    }
    db.prepare('UPDATE players SET active_team=? WHERE uid=? AND server_id=?').run(idx, pl.uid, pl.server_id);
    db.exec('COMMIT');
  } catch (e) { db.exec('ROLLBACK'); throw e; }
  return {};
}

// Equip (kind 1 weapon, 2 armor, 3 trinket, 4 seal, 5-8 ninjutsu slots) a card onto the ninja in team slot (1-based) of line-up t.
function equip(db, pl, slot, kind, newSeq, t = USED) {
  ensure(db);
  db.prepare(`DELETE FROM ${t.equipped} WHERE uid=? AND server_id=? AND kind=? AND seq=?`).run(pl.uid, pl.server_id, kind, newSeq);
  if (!newSeq) db.prepare(`DELETE FROM ${t.equipped} WHERE uid=? AND server_id=? AND slot=? AND kind=?`).run(pl.uid, pl.server_id, slot, kind);
  else db.prepare(`INSERT OR REPLACE INTO ${t.equipped}(uid,server_id,slot,kind,seq) VALUES(?,?,?,?,?)`).run(pl.uid, pl.server_id, slot, kind, newSeq);
}

// Team slots open like the original (newcardinfo row N = slot N): a player level from the text ("reach level 6",
// "Lv. 30 and customs clearance 1 Round 12") and, for some, a cleared training stage ([7] chapter, [8] stage).
function maxTeam(db, pl) {
  let n = 0;
  for (const r of table('newcardinfo').rows) {
    const m = /(?:level|Lv\.)\s*(\d+)/i.exec(String(r[2]));
    const need = m ? Number(m[1]) : 999;
    if (pl.level < need) break;
    if (r[7] > 0 && getStage(db, pl.uid, pl.server_id, r[7]) <= r[8]) break;
    n++;
  }
  return Math.max(1, n);
}
// Team > card > Change (rl_w_ninjalist Cmd 2300): OldID = card leaving (0 for an empty slot), NewID = card joining.
// A card already in the team trades places with the old one. Team slots are 0-based, at most maxTeam ninjas.
function teamSwap(db, pl, oldSeq, newSeq, t = USED) {
  ensure(db);
  const card = db.prepare('SELECT seq FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(newSeq, pl.uid, pl.server_id);
  if (!card) return 'no such ninja';
  const team = db.prepare(`SELECT slot, seq FROM ${t.team} WHERE uid=? AND server_id=? ORDER BY slot`).all(pl.uid, pl.server_id);
  const set = (slot, seq) => db.prepare(`INSERT OR REPLACE INTO ${t.team}(uid,server_id,slot,seq) VALUES(?,?,?,?)`).run(pl.uid, pl.server_id, slot, seq);
  const from = team.find((t) => t.seq === oldSeq), there = team.find((t) => t.seq === newSeq);
  if (from) { set(from.slot, newSeq); if (there) set(there.slot, oldSeq); return null; }
  if (there) return null; // already in the team
  if (team.length >= maxTeam(db, pl)) return 'no free team slot yet';
  set(team.length ? Math.max(...team.map((t) => t.slot)) + 1 : 0, newSeq);
  return null;
}
// One line-up as the client reads it: suits = <item id type/> list, slots = <ninja> list (t = USED or WAITING tables)
function lineupXml(db, uid, sid, t) {
  let team = db.prepare(`SELECT seq FROM ${t.team} WHERE uid=? AND server_id=? ORDER BY slot`).all(uid, sid);
  if (process.env.HB_TEAM_SLOTS !== undefined) team = team.slice(0, Number(process.env.HB_TEAM_SLOTS)); // debugging aid
  const ts = teamStats(db, uid, sid, t);
  const eqRows = db.prepare(`SELECT slot, kind, seq FROM ${t.equipped} WHERE uid=? AND server_id=?`).all(uid, sid);
  const eqOf = (slot) => Object.fromEntries(eqRows.filter((r) => r.slot === slot).map((r) => [r.kind, r.seq]));
  return { ts, suits: ts.suits.map((r) => `<item id="${r[0]}" type="${r[2]}"/>`).join(''), slots: team.map((x, i) => slotXml(x.seq, i, eqOf(i + 1), (ts.slots[i] || {}))).join('') };
}
// The team-edit reply for line-up idx (CMyGroupCardView reads <teamid> and loads <suitlist>/<ninjalist> into that team)
// For the USED line-up it also carries <usernum><AttackLow/>..<ChakraHigh/></usernum> (children of usernum): CMyGroupView then updates the
// player's attack / defense / chakra at once (only when <usernum> is there and teamid is the active team; flat siblings crash at 0x18).
function teamReplyXml(db, uid, sid, idx) {
  const t = lineup(db, uid, sid, idx), l = lineupXml(db, uid, sid, t);
  const tot = t === USED ? l.ts.total : null;
  const stats = tot ? el('usernum', el('AttackLow', tot.al) + el('AttackHigh', tot.ah) + el('DefenseLow', tot.dl) +
    el('DefenseHigh', tot.dh) + el('ChakraLow', tot.cl) + el('ChakraHigh', tot.ch)) : '';
  return `<teamid>${Number(idx) === 1 ? 1 : 0}</teamid>${stats}<suitlist>${l.suits}</suitlist><ninjalist>${l.slots}</ninjalist>`;
}
function stateXml(db, uid, sid) {
  ensure(db);
  const cards = db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=? ORDER BY seq').all(uid, sid);
  const used = lineupXml(db, uid, sid, USED), waiting = lineupXml(db, uid, sid, WAITING), active = activeTeam(db, uid, sid);
  const t1 = active === 1 ? waiting : used, t2 = active === 1 ? used : waiting;
  return {
    active,
    suitlist: '<suitlist>' + t1.suits + '</suitlist>',
    totals: used.ts.total, // the used line-up's attack / defense (top bar, rankings)
    cards: cards.map(cardXml).join(''),
    ninjalist: '<ninjalist>' + t1.slots + '</ninjalist>',
    defensesuitlist: '<defensesuitlist>' + t2.suits + '</defensesuitlist>',
    defenseninjalist: '<defenseninjalist>' + t2.slots + '</defenseninjalist>',
  };
}

// ---- Gacha ("recruit") -----------------------------------------------------------------
// Pull types follow recruitinfo.dbf rows: 1 = premium (300 gold), 2 = standard (150 gold), 3 = free.
// Star weights are a hobby-server design choice (the original rates lived on the old server).
const RATES = { // star weights per banner; the stars must stay inside what each banner promises (purple 4-5, blue 3-5, green 2-5). Weights (ours).
  1: { 5: 12, 4: 88 },
  2: { 5: 4, 4: 26, 3: 70 },
  3: { 5: 1, 4: 5, 3: 30, 2: 64 },
};
const COST = { 1: 300, 2: 150, 3: 0 };
const TEN_COST = { 1: 2800, 2: 1400, 3: 0 };
let byStar = null;
function pools() {
  if (!byStar) {
    byStar = {};
    for (const r of ninjas().values()) if (r[4] === 1 && r[6] === 0) (byStar[r[11]] = byStar[r[11]] || []).push(r[0]);
  }
  return byStar;
}
// Recruit pools (owner, 2 Nov 2026): only the classic cards, both the ATK and the DEF version (ninjainfo [6] 0 / 1). The later premium cards
// (ids 2000+: Teenager Naruto, Goddess Sakura, Susa ..., the ones that also have a God version) come from events, not from recruiting.
let recruitByStar = null;
function recruitPools() {
  if (!recruitByStar) {
    recruitByStar = {};
    for (const r of ninjas().values()) if (r[4] === 1 && r[0] < 2000 && (r[6] === 0 || r[6] === 1)) (recruitByStar[r[11]] = recruitByStar[r[11]] || []).push(r[0]);
  }
  return recruitByStar;
}
function rollOne(type, forceStar) {
  try { const f = Number(fs.readFileSync(path.join(__dirname, 'force_ninja.txt'), 'utf8')); if (f) return f; } catch {} // debugging aid
  const rates = RATES[type] || RATES[2];
  const total = Object.values(rates).reduce((a, b) => a + b, 0);
  let x = Math.random() * total;
  let star = Number(Object.keys(rates)[0]);
  for (const [s, w] of Object.entries(rates)) { if ((x -= w) < 0) { star = Number(s); break; } }
  if (forceStar) star = Math.max(star, forceStar);
  const pool = recruitPools()[star] || recruitPools()[3];
  return pool[Math.floor(Math.random() * pool.length)];
}
// Free recruits (owner/friend: in the original the blue 150-gold recruit was free once every 8 hours and the purple 300-gold one once every 24).
const FREE_EVERY = { 1: 24 * 3600, 2: 8 * 3600 };
// Pity counter ("recruit N more times and you are sure to get a 5-star"): the original number is lost, so (ours) = 20 pulls.
const PITY = 20;
// The 300-gold recruit can also give gold. ORIGINAL (Facebook photos 2339-2348): "Gold*210", "Gold*500", "Gold*1000", "Gold*2000" on the
// Rewards card (the game's own dropinfo rows 137, 290, 295, 298). (ours): the chances, % a pull: 4 / 1.5 / 0.4 / 0.1 (about 22 gold back
// per 300-gold pull on average). A gold result does not count toward the 5-star pity.
// OFF for now: the single-recruit reveal (CDialogShowBox) shows a blank card for a gold result (it draws <recruit ninjaid>); the gold itself
// is given. Turn on (the chances below) once the reveal can show the gold picture. HB_GOLD=<drop id> forces one for testing.
const GOLD_PRIZES = [[137, 0], [290, 0], [295, 0], [298, 0]]; // (ours) when on: 4 / 1.5 / 0.4 / 0.1
function rollGold() {
  if (process.env.HB_GOLD) return Number(process.env.HB_GOLD);
  let x = Math.random() * 100;
  for (const [drop, pct] of GOLD_PRIZES) if ((x -= pct) < 0) return drop;
  return 0;
}
function recruitEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS recruit_state (uid INTEGER, server_id INTEGER, type INTEGER, last_free INTEGER DEFAULT 0, pity INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id, type))');
  try { db.exec("ALTER TABLE recruit_state ADD COLUMN day TEXT DEFAULT ''"); } catch (e) { /* already there */ }
  try { db.exec('ALTER TABLE recruit_state ADD COLUMN used INTEGER DEFAULT 0'); } catch (e) { /* already there */ }
}
function recruitState(db, pl, type) {
  recruitEnsure(db);
  const r = db.prepare('SELECT * FROM recruit_state WHERE uid=? AND server_id=? AND type=?').get(pl.uid, pl.server_id, type) || { last_free: 0, pity: 0 };
  const every = FREE_EVERY[type] || 0, now = Math.floor(Date.now() / 1000);
  return { every, last: r.last_free, left: every ? Math.max(0, r.last_free + every - now) : 0, pity: r.pity, toGo: Math.max(1, PITY - r.pity) };
}
// The "1 in 100" recruit (type 3) costs recruitment orders (prop 30), one per card, at most recruitinfo [5] = 5 cards a day.
const ORDER_PROP = 30, ORDER_DAILY = 5;
function orderUsedToday(db, pl) {
  recruitEnsure(db);
  const r = db.prepare('SELECT day, used FROM recruit_state WHERE uid=? AND server_id=? AND type=3').get(pl.uid, pl.server_id);
  return r && r.day === today() ? r.used : 0;
}
function pull(db, pl, type, count, free) {
  if (type === 3) {
    if (orderUsedToday(db, pl) + count > ORDER_DAILY) return { error: 'no recruits left today' };
    if ((propCounts(db, pl.uid, pl.server_id)[ORDER_PROP] || 0) < count) return { error: 'not enough recruitment orders' };
    propAdd(db, pl.uid, pl.server_id, ORDER_PROP, -count);
    db.prepare(`INSERT INTO recruit_state(uid,server_id,type,day,used) VALUES(?,?,3,?,?)
      ON CONFLICT(uid,server_id,type) DO UPDATE SET day=excluded.day, used=excluded.used`).run(pl.uid, pl.server_id, today(), orderUsedToday(db, pl) + count);
    free = false;
  }
  const st = recruitState(db, pl, type);
  if (free && st.left > 0) return { error: 'free recruit not ready yet' };
  const cost = free ? 0 : count === 10 ? (TEN_COST[type] ?? 1400) : (COST[type] ?? 150) * count; // ten-pull prices are the ones the client shows
  if (pl.gold < cost) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  let pity = st.pity;
  const got = [];
  for (let i = 0; i < count; i++) {
    const gold = type === 1 && !(FREE_EVERY[type] && pity >= PITY - 1) ? rollGold() : 0;
    if (gold) { got.push({ gold, award: grantDrop(db, pl, gold) }); continue; }
    const sure = FREE_EVERY[type] && pity >= PITY - 1;
    const nid = process.env.HB_FORCE ? Number(process.env.HB_FORCE) : rollOne(type, sure ? 5 : 0);
    const star = (ninjas().get(nid) || [])[11] || 0;
    pity = star >= 5 ? 0 : pity + 1;
    got.push({ ninja: nid, seq: giveCard(db, pl.uid, pl.server_id, nid) });
  }
  db.prepare(`INSERT INTO recruit_state(uid,server_id,type,last_free,pity) VALUES(?,?,?,?,?)
    ON CONFLICT(uid,server_id,type) DO UPDATE SET last_free=excluded.last_free, pity=excluded.pity`).run(pl.uid, pl.server_id, type, free ? Math.floor(Date.now() / 1000) : st.last, pity);
  if (type === 1) bumpTask(db, pl.uid, pl.server_id, 14, count); // daily task: 1-in-10000 recruit
  return { cost, got, toGo: FREE_EVERY[type] ? Math.max(1, PITY - pity) : 0 };
}
function awardXml(c) {
  if (c.award) return c.award; // a gold prize: the game's own drop row (its Rewards card shows the gold picture and "Gold*500")
  return '<award dropid="1"><cardlist><card>' + el('id', c.ninja) + el('type', 1) + el('num', 1) + el('attri', 0) + el('bagIndex', c.seq) + el('level', 1) + el('newlife', c.newlife || 0) + el('starlevel', c.starlevel || 0) +
    '</card></cardlist><proplist></proplist><chipbag></chipbag><coin>0</coin><cash>0</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>';
}
// ---- Real game drops (dropinfo.dbf): [3] ninja, [4] equipment, [5] ninjutsu, [6] mark, [7] prop, [8] equip piece,
// [10] gold, [11] silver, [12] drop type (1 = random pack), [13] count. Grants the reward and returns a full <award>.
// Random packs (type 1, no fixed item) are resolved from their description: shinobi packs roll a ninja,
// equipment packs a piece of gear, gift packs a card or gold.
// Gear packs follow their own description (dropinfo text). "Has a chance to get X-Star, higher chance of Y-Star, at least Z-Star" ->
// X 10 % / Y 60 % / Z 30 % (ours: the original rates are lost); "chance of X, at least Y" -> 25 / 75 (ours); "Five-Star weapon Card" = exactly
// that star; "One, Two-Star" = 1-2. The slot is the one the text names (weapon / armor / trinket), else random. null = not a gear pack text.
const STAR_WORD = { One: 1, Two: 2, Three: 3, Four: 4, Five: 5 };
function equipFromText(t) {
  if (!/equipment|weapon|armou?r|trinket/i.test(t)) return null; // shinobi / ninjutsu / seal pack texts use the same "chance of X-Star" words
  const slotOf = /weapon/i.test(t) ? 0 : /armor/i.test(t) ? 1 : /trinket/i.test(t) ? 2 : Math.floor(Math.random() * 3);
  const w = (re) => { const m = re.exec(t); return m ? STAR_WORD[m[1][0].toUpperCase() + m[1].slice(1).toLowerCase()] : 0; };
  const top = w(/chance (?:to get|to grant|of) (One|Two|Three|Four|Five)-Star/i), mid = w(/(?:higher|great) chance (?:to win |to grant |of )?(One|Two|Three|Four|Five)-Star/i);
  const low = w(/at least (?:gets? |get )?(?:a )?(One|Two|Three|Four|Five)-Star/i);
  let star;
  if (top && mid && low) { const x = Math.random(); star = x < 0.1 ? top : x < 0.7 ? mid : low; }
  else if (top && low) star = Math.random() < 0.25 ? top : low;
  else if (/^One,s*Two-Star|^One-Star Equipment Card, Two-Star/i.test(t)) star = 1 + Math.floor(Math.random() * 2);
  else { const m = /^(One|Two|Three|Four|Five)-Star (?:Equipment|Weapon|Armor|Trinket) Card$/i.exec(t.trim()); star = m ? STAR_WORD[m[1]] : 0; }
  if (!star) return null;
  return randomEquip(slotOf, star, star);
}
function rollPack(r) {
  const t = String(r[2]);
  // Arena ladder packs 159-165 (ladderdesc): "You will get one of these 4 rewards: Five-Star Equipment, Four-Star Equipment, Full Seal, and
  // 300 gold." = exactly one of the listed prizes; equal chances (ours, the real ones were on the server).
  const list = t.match(/one of these \d+ rewards:\s*(.*?)\.?$/i);
  if (list) {
    const opts = list[1].split(/,\s*(?:and\s+)?/), o = opts[Math.floor(Math.random() * opts.length)];
    const st = /Five-Star/.test(o) ? 5 : /Four-Star/.test(o) ? 4 : /Three-Star/.test(o) ? 3 : 0;
    if (st) return { equip: randomEquip(Math.floor(Math.random() * 3), st, st) };
    if (/Seal/i.test(o)) { const seals = table('markmerge').rows.map((m) => m[0]).filter((id) => id >= 1 && id <= 9); return { seal: seals[Math.floor(Math.random() * seals.length)] }; }
    const n = Number((o.match(/(\d+)/) || [0, 0])[1]);
    return /gold/i.test(o) ? { cash: n } : { coin: n };
  }
  const star = /Five-Star Shinobi Card|Sage of the Six/.test(t) ? (Math.random() < 0.35 ? 5 : 4) : /Pack III/.test(t) ? (Math.random() < 0.2 ? 5 : 4) : /Pack II/.test(t) ? (Math.random() < 0.15 ? 4 : 3) : (Math.random() < 0.08 ? 5 : 3);
  // "One, Two-Star ..." and "Three-Star ..." packs are exactly those stars (slot 0-2 = weapon / armor / trinket)
  const low = /One,\s*Two-Star/.test(t), three = /^Three-Star/.test(t);
  const exact = equipFromText(t);
  if (exact) return { equip: exact };
  // Tailed-beast seal packs ("Seal fragments", "Tailed Beast Seal Fragment" in the treasure chests, "Complete Tail-Beast Seal", "Tail
  // Beast Seal"): a random fragment of any seal (markmerge), or a random complete tailed-beast seal 1-9 (ours: equal chances; the
  // Ten-Tails Seal only comes from its own fixed drops). Before 2 Nov 2026 these gave a random shinobi.
  if (/seal/i.test(t) && !/card|shinobi|ninj[ui]tsu|equipment|weapon|armou?r|trinket|gold/i.test(t)) {
    const merges = table('markmerge').rows;
    if (/fragment/i.test(t)) { const frags = merges.flatMap((m) => m.slice(3, 9).filter((x) => x > 0)); return { sealFrag: frags[Math.floor(Math.random() * frags.length)] }; }
    const seals = merges.map((m) => m[0]).filter((id) => id >= 1 && id <= 9);
    return { seal: seals[Math.floor(Math.random() * seals.length)] };
  }
  // Spar win draws (handlers rl_w_pvp): dropinfo 397 "Equipment and Ninjutsu before Lv.20" and 27 "Drop from Equipment, Seal". The real
  // chances were server-side and are lost; (ours): mostly 2-3 star gear or ninjutsu (397) / 3-star gear (27), rarely 4, very rarely 5 stars.
  if (r[0] === 397 || r[0] === 27) {
    const x = Math.random() * 100, st = r[0] === 397 ? (x < 60 ? 2 : x < 95 ? 3 : 4) : (x < 80 ? 3 : x < 98 ? 4 : 5);
    if (r[0] === 397 && Math.random() < 0.3) { const pool = table('ninjutsuinfo').rows.filter((q) => q[5] === st && q[6] === 1); if (pool.length) return { ninjutsu: pool[Math.floor(Math.random() * pool.length)][0] }; }
    return { equip: randomEquip(Math.floor(Math.random() * 3), st, st) };
  }
  const gearSlot = /Weapon/.test(t) ? 0 : /Armou?r/.test(t) ? 1 : /Trinket|Accessor|Ornament/.test(t) ? 2 : -1; // "One, Two-Star Weapon Card" etc.
  if (gearSlot >= 0 && !/Equipment/.test(t)) return { equip: low ? randomEquip(gearSlot, 1, 2) : three ? randomEquip(gearSlot, 3, 3) : randomEquip(gearSlot, 3, /Five-Star/.test(t) ? 5 : 4) };
  if (/Equipment/.test(t)) return low ? { equip: randomEquip(Math.floor(Math.random() * 3), 1, 2) } : three ? { equip: randomEquip(Math.floor(Math.random() * 3), 3, 3) } : { equip: randomEquip(Math.floor(Math.random() * 3), star) };
  if (low && !/Ninj[ui]tsu/i.test(t)) { const pool = pools()[1 + Math.floor(Math.random() * 2)]; if (pool && pool.length) return { ninja: pool[Math.floor(Math.random() * pool.length)] }; }
  if (three && !/Ninj[ui]tsu/i.test(t)) { const pool = pools()[3]; if (pool && pool.length) return { ninja: pool[Math.floor(Math.random() * pool.length)] }; }
  if (/Gold/.test(t) && Math.random() < 0.3) return { cash: Number((t.match(/(\d+) Gold/) || [0, 300])[1]) };
  if (/Ninj[ui]tsu/i.test(t)) { // a real ninjutsu card of the star the pack names (was a 30000 silver placeholder)
    const want = /Five-Star/.test(t) ? [5] : /Four-Star/.test(t) ? [4] : /Three-Star/.test(t) ? [3] : /One,\s*Two/.test(t) ? [1, 2] : [3, 4];
    const pool = table('ninjutsuinfo').rows.filter((x) => want.includes(x[5]) && x[6] === 1);
    if (pool.length) return { ninjutsu: pool[Math.floor(Math.random() * pool.length)][0] };
    return { coin: 30000 };
  }
  if (/2-5/.test(t)) { // "2~5S Shinobi" packs (e.g. dropinfo 1508): a 2 to 5-star shinobi; weights 40 / 30 / 20 / 10 % (ours)
    const p = pools()[[2, 2, 2, 2, 3, 3, 3, 4, 4, 5][Math.floor(Math.random() * 10)]];
    if (p && p.length) return { ninja: p[Math.floor(Math.random() * p.length)] };
  }
  const pool = pools()[star] || pools()[4];
  return { ninja: pool[Math.floor(Math.random() * pool.length)] };
}
// Shinobi card fragments (piece_info ids) are kept as props CHIP_BASE + pieceId; the login sends them as <chipbag><chipitem/>.
const CHIP_BASE = 30000;
function chipCount(db, uid, sid, pieceId) { return propCounts(db, uid, sid)[CHIP_BASE + pieceId] || 0; }
function chipbagXml(db, uid, sid) {
  return '<chipbag>' + Object.entries(propCounts(db, uid, sid)).filter(([id, n]) => id > CHIP_BASE && id < CHIP_BASE + 10000 && n > 0)
    .map(([id, n]) => `<chipitem id="${id - CHIP_BASE}" num="${n}"/>`).join('') + '</chipbag>';
}
// Backpack > fragments > Merge (rl_w_comm Cmd 10, ChipBagID = piece_info id): piece [7] fragments become drop [8].
function mergeChips(db, pl, pieceId) {
  const r = table('piece_info').rows.find((x) => x[0] === pieceId);
  if (!r) return { error: 'no such fragment' };
  if (chipCount(db, pl.uid, pl.server_id, pieceId) < r[7]) return { error: 'not enough fragments' };
  propAdd(db, pl.uid, pl.server_id, CHIP_BASE + pieceId, -r[7]);
  return { xml: grantDrop(db, pl, r[8]) };
}
function grantDrop(db, pl, dropId) {
  const r = table('dropinfo').rows.find((x) => x[0] === dropId);
  if (!r) return null;
  const n = r[13] || 1;
  const cards = [], props = [];
  let coin = 0, cash = 0, soul = 0, chips = 0;
  const sealFrags = [];
  // drop type 1 = random pack. "X-Star ... Card" packs carry one example card in col 3/4; roll a random card of that kind instead
  // of always giving the example (Aburame Torune every time, GitHub #4).
  const pack = r[12] === 1 && !(r[7] > 0) && (!(r[3] > 0) || /Star/.test(String(r[2]))) ? rollPack(r) : null;
  const ninja = pack ? pack.ninja : r[3], equip = pack ? pack.equip : (r[3] > 0 ? 0 : r[4]);
  if (ninja > 0) for (let i = 0; i < n; i++) cards.push({ type: 1, id: ninja, seq: giveCard(db, pl.uid, pl.server_id, ninja) });
  else if (equip > 0) for (let i = 0; i < n; i++) { const seq = giveEquip(db, pl.uid, pl.server_id, equip); if (seq) cards.push({ type: db.prepare('SELECT type FROM cards WHERE seq=?').get(seq).type, id: equip, seq }); }
  else if (pack && pack.ninjutsu) cards.push({ type: 6, id: pack.ninjutsu, seq: giveCard(db, pl.uid, pl.server_id, pack.ninjutsu, 6) });
  else if (pack && pack.seal) for (let i = 0; i < n; i++) cards.push({ type: 5, id: pack.seal, seq: giveCard(db, pl.uid, pl.server_id, pack.seal, 5) });
  else if (pack && pack.sealFrag) { propAdd(db, pl.uid, pl.server_id, 20000 + pack.sealFrag, n); sealFrags.push({ id: pack.sealFrag, num: n }); } // seals.js FRAG
  else if (pack) { cash = pack.cash || 0; coin = pack.coin || 0; }
  else if (r[7] > 0) { propAdd(db, pl.uid, pl.server_id, r[7], n); props.push({ id: r[7], num: n }); }
  else if (r[10] > 0) cash = r[10] * n;
  else if (r[11] > 0) coin = r[11] * n;
  else if (r[8] > 0) { propAdd(db, pl.uid, pl.server_id, CHIP_BASE + r[8], n); chips = n; }
  else if (r[9] > 0) { soul = r[9] * n; propAdd(db, pl.uid, pl.server_id, SOUL, soul); }
  else if (r[14] > 0) for (let i = 0; i < n; i++) require('./pet').addPet(db, pl.uid, pl.server_id, r[14]); // pet (shown in the pet screens)
  else if (r[5] > 0) for (let i = 0; i < n; i++) cards.push({ type: 6, id: r[5], seq: giveCard(db, pl.uid, pl.server_id, r[5], 6) });
  else if (r[6] > 0) for (let i = 0; i < n; i++) cards.push({ type: 5, id: r[6], seq: giveCard(db, pl.uid, pl.server_id, r[6], 5) });
  if (coin || cash) db.prepare('UPDATE players SET coin=coin+?, gold=gold+? WHERE uid=? AND server_id=?').run(coin, cash, pl.uid, pl.server_id);
  // In an <award> the client reads <type> as the reward kind (CGameObjElement::firefly_GetInfoFromDropId): 1 shinobi, 2 ANY equipment,
  // 4 ninjutsu, 5 seal. Our card table uses 2/3/4 for weapon/armor/trinket and 6 for ninjutsu; sending those drew ninjutsu as the
  // "beast" placeholder card (GitHub #4) and armor/trinkets as the wrong kind.
  const AWARD_TYPE = { 1: 1, 2: 2, 3: 2, 4: 2, 5: 5, 6: 4 };
  const cardXml = cards.map((c) => '<card>' + el('id', c.id) + el('type', AWARD_TYPE[c.type] || c.type) + el('num', 1) + el('attri', 0) + el('bagIndex', c.seq) + el('level', 1) + el('newlife', 0) + el('starlevel', 0) + '</card>').join('');
  const propXml = props.map((x) => '<prop>' + el('id', x.id) + el('num', x.num) + '</prop>').join('');
  // seal fragments are shown as seal cards with the fragment's markinfo id (picture + name "Shukaku Seal Fragment 1"); they are kept as
  // props 20000 + id, which the seal screens read from the server
  const fragXml = sealFrags.map((x) => '<card>' + el('id', x.id) + el('type', 5) + el('num', x.num) + el('attri', 0) + el('bagIndex', 0) + el('level', 1) + el('newlife', 0) + el('starlevel', 0) + '</card>').join('');
  // Lua award screens count one fragment per <chipitem>, so repeat it n times with num="1".
  const chipXml = `<chipitem id="${r[8]}" num="1"/>`.repeat(chips);
  return `<award dropid="${dropId}" coin="${coin}"><cardlist>${cardXml}${fragXml}</cardlist><proplist>${propXml}</proplist><chipbag>${chipXml}</chipbag>` +
    `${el('coin', coin)}${el('cash', cash)}<exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action>${el('soul', soul)}</award>`;
}
// (conf item 31 = stage gift stays off: its button icon ccbResources/activity_icon_11.png is not in the v28 OBB,
// and the missing sprite makes the whole left column of event buttons fail.)
// One <award> holding several grantDrop results (Lua screens read only the first <award>).
function mergeAwards(list) {
  const pick = (re) => list.map((a) => (a.match(re) || ['', ''])[1]).join('');
  const sum = (tag) => list.reduce((s, a) => s + Number((a.match(new RegExp(`<${tag}>(\\d+)</${tag}>`)) || [0, 0])[1]), 0);
  const coin = sum('coin');
  return `<award dropid="${list.length ? (list[0].match(/dropid="(\d+)"/) || [0, 1])[1] : 1}" coin="${coin}"><cardlist>${pick(/<cardlist>(.*?)<\/cardlist>/)}</cardlist>` +
    `<proplist>${pick(/<proplist>(.*?)<\/proplist>/)}</proplist><chipbag>${pick(/<chipbag>(.*?)<\/chipbag>/)}</chipbag>${el('coin', coin)}${el('cash', sum('cash'))}` +
    '<exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action>' + el('soul', sum('soul')) + '</award>';
}
// Cmd 1900 (one pull): <recruit .../> attributes + <award>. Cmd 1901 (ten pulls): <recruit_list> of exactly 10 <item><award>.
function pullXml(res, count, type = 0) {
  if (count === 1) {
    const c = res.got[0];
    // costprop = recruitment orders used (CItemView takes it off item 30, so the "orders left" count updates without leaving the shop)
    // The new "Recruit N more" count: CCommonPrayDialogView reads root > protect_comming > protect_comming (a NESTED tag of the same name,
    // text) and only then redraws itself (InitUI): the count and "Free recruitment this time" -> the gold price. The open-window request
    // (rl_r_recruit) reads it as <recruit protect_comming="">, so it goes on <recruit> too. Without it the window kept the old count and
    // the free label, and looked like every pull was free (the server did charge).
    return `<recruit ninjaid="${c.ninja || 0}" cost="${res.cost}" bagid="${c.seq || 0}" attr="0" costprop="${type === 3 ? 1 : 0}"${res.toGo ? ` protect_comming="${res.toGo}"` : ''}/>` +
      (res.toGo ? `<protect_comming><protect_comming>${res.toGo}</protect_comming></protect_comming>` : '') + awardXml(c); // <award> is a SIBLING of <recruit> (children of the root)
  }
  return '<recruit_list>' + res.got.map((c) => '<item>' + awardXml(c) + '</item>').join('') + '</recruit_list>';
}


// ---- Training battles -----------------------------------------------------------------------
// The client replays whatever fight we describe: <fight><preview/><guard>(enemies)<killer>(my team)<roundlist>.
function ninjaXml(n) {
  const f = { id: n.id, bagid: n.bagid, low: n.low, high: n.high, end: n.end, level: n.level, attri: n.attri || 0, starlevel: n.star, newlife: 0 };
  return '<ninja>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') + '</ninja>';
}
// <master_pet> in a fight: CFightResultData::AddMyNinja reads BOTH <id> and <pet_id> (a missing one = SIGSEGV),
// so only send it when the player really has a master pet.
function masterPetXml(db, pl) {
  const p = require('./pet').masterPet(db, pl.uid, pl.server_id);
  return p ? `<master_pet>${el('id', p.id)}${el('pet_id', p.pet_id)}</master_pet>` : '';
}
// The 3 enemy cards shown in a spar / arena / war fight: a real player's own team (first 3 slots); a bot shows its own ninja plus
// 2 other base ninjas of the same stars, picked by its id so the same rival always shows the same team (was 3 copies of one ninja).
// Team size by level, from the game's own slot table (newcardinfo: level 1, 2, 6, 15, 30, 50 ...; the stage conditions are left out for bots).
function teamSizeAt(level) {
  let n = 0;
  for (const r of table('newcardinfo').rows) { const m = /(?:level|Lv\.)\s*(\d+)/i.exec(String(r[2])); if (!m || Number(m[1]) > level) break; n++; }
  return Math.max(1, Math.min(12, n)); // (ours) at most 12 enemy cards
}
// The enemy cards of a spar / arena / war / border / cross-server fight. A real player: their WHOLE team with each card's own element, level,
// growth and attack range (teamStats). A bot: as many cards as a player of its level has (teamSizeAt; 3 when the level is unknown), its own
// ninja first and others of the same stars picked by its id, so the same rival always shows the same team. .cards = per-card details.
// Bot cards' defence = BOT_DEF x their attack (ours, tuned so spar / arena win rates stay where they were when fights were decided by
// average attack; real players' cards have defence ~55 % of attack).
const BOT_DEF = Number(process.env.HB_BOT_DEF) || 1;
function foeTeam(db, uid, sid, first, level, botAtk, around) {
  if (uid) { // a bot / guard has no team rows, so it falls through to the made-up team below
    const rows = db.prepare('SELECT c.ninja_id, c.attri, c.level, c.starlevel FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(uid, sid);
    if (rows.length) {
      const fsx = teamStats(db, uid, sid).fight;
      const t = rows.map((r) => r.ninja_id);
      t.attris = rows.map((r) => r.attri || 1); // a real player's cards keep their own element in the fight
      t.cards = rows.map((r, i) => ({ id: r.ninja_id, attri: r.attri || 1, level: r.level, star: r.starlevel || 0, al: (fsx[i] || {}).al, ah: (fsx[i] || {}).ah, dl: (fsx[i] || {}).dl, dh: (fsx[i] || {}).dh }));
      return t;
    }
  }
  const star = (ninjas().get(first) || [])[11] || 4;
  const pool = Array.from(ninjas().values()).filter((r) => r[4] === 1 && r[11] === star && r[0] !== first).map((r) => r[0]);
  const seed = Math.abs(Number(uid) || first || 1);
  // around = the challenger's own team size: a bot brings about as many cards (that many, one more or one fewer, fixed per bot), never more
  // than its level allows (ours: bots have no story progress holding their slots back like real players)
  const size = level ? (around ? Math.max(1, Math.min(teamSizeAt(level), around + ((seed % 3) - 1))) : teamSizeAt(level)) : 3;
  const out = [first || pool[0]];
  for (let k = 0; out.length < size && k < pool.length * 3; k++) { const id = pool[(seed * 7919 + k * 104729) % pool.length]; if (!out.includes(id)) out.push(id); }
  out.cards = out.map((id, i) => {
    const w = 0.85 + ((seed * 31 + i * 17) % 31) / 100, c = { id, attri: foeAttri(id), level: level || 1, star: 0, w };
    if (botAtk > 0) { const a = botAtk * w, d = a * BOT_DEF; Object.assign(c, { al: Math.round(a * 0.93), ah: Math.round(a * 1.07), dl: Math.round(d * 0.93), dh: Math.round(d * 1.07) }); } // +-7 % (ours)
    return c;
  });
  return out;
}
// Element restrain (ninjafiveprop: [1] element beats [3], [6] = +15%): water > fire > wind > thunder > earth > water.
function restrainTable() {
  if (!restrainTable.m) { restrainTable.m = new Map(); for (const r of table('ninjafiveprop').rows) restrainTable.m.set(r[1], { beats: r[3], rate: Number(r[6]) || 0 }); }
  return restrainTable.m;
}
// Enemy NPCs have no element in the game data: a fixed one from the ninja id, so a stage always shows the same elements (ours).
const foeAttri = (id) => ((Math.abs(Number(id) || 0) * 7) % 5) + 1;
function battleXml(db, pl, chap, stage, opt = {}) {
  const team = db.prepare('SELECT t.slot, c.seq, c.ninja_id, c.level, c.starlevel, c.attri FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(pl.uid, pl.server_id);
  const ts = teamStats(db, pl.uid, pl.server_id);
  // ninjutsu worn (equipped kinds 5-8) by each team ninja: they can fire when that ninja starts attacking
  const jRows = db.prepare('SELECT e.slot, c.seq, c.ninja_id, c.level FROM equipped e JOIN cards c ON c.seq=e.seq WHERE e.uid=? AND e.server_id=? AND e.kind BETWEEN 5 AND 8')
    .all(pl.uid, pl.server_id);
  const petSkill = require('./pet').skillHurt(db, pl.uid, pl.server_id);
  const mine = team.map((t, i) => { const q = ts.fight[i] || {}; return { jutsu: jRows.filter((r) => r.slot === i + 1), chakra: Math.round(((q.cl || 0) + (q.ch || 0)) / 2), id: t.ninja_id, bagid: t.seq, low: q.al || 40, high: q.ah || 60, end: Math.round(((q.al || 40) + (q.ah || 60)) / 2), def: Math.round(((q.dl || 0) + (q.dh || 0)) / 2) || 60, level: t.level, star: t.starlevel, attri: t.attri || 1 }; });
  // Every enemy card has a defence RANGE (dl-dh, the value is rolled each fight): +-7 % around its value (ours; like a team that hits 7-8 M).
  const VAR = 0.07, spread = (f) => ({ ...f, dl: f.dl || Math.max(1, Math.round(f.def * (1 - VAR))), dh: f.dh || Math.max(1, Math.round(f.def * (1 + VAR))) });
  const given = opt.foes ? opt.foes.map((f, i) => spread({ ...f, bagid: 1000 + i })) : null; // real stage enemies (game.stageFoes)
  // Opponents: the cards foeTeam gives (whole team / level-sized). Their total defence scales with how strong they are next to me:
  // opt.ratio = their strength / mine, as the fight's own decision measures it (spar, arena, war ...), times my average total attack, so the
  // replay with true ranges ends the way the decision went. Each card's share follows its own defence (a real player) or a fixed weight (a bot);
  // attack shown = the card's real attack (a real player) or defence / 0.55 (a bot; ours: players' cards have defence ~55 % of attack).
  const mkFoes = (fallback) => {
    if (given) return given.map((f) => ({ ...f }));
    const ids = opt.enemyIds || [21, 22, 23];
    const cards = ids.cards || ids.map((id, i) => ({ id, attri: ids.attris ? ids.attris[i] : 0, level: opt.enemyLevel || 1, star: 0, w: 1 }));
    if (!(opt.ratio > 0) && cards.length && cards.every((c) => c.dl !== undefined && c.al !== undefined)) { // true stats: the replay decides
      return cards.map((c, i) => { const def = Math.round((c.dl + c.dh) / 2); return { id: c.id, bagid: 1000 + i, low: c.al, high: c.ah, def, end: def, dl: c.dl, dh: c.dh, level: c.level || 1, star: c.star || 0, attri: c.attri || 0 }; });
    }
    const myAtk = mine.reduce((t, m) => t + (m.low + m.high) / 2, 0);
    const ratio = opt.ratio > 0 ? opt.ratio : fallback;
    const total = Math.max(cards.length, myAtk * ratio);
    const w = cards.map((c) => (c.dl !== undefined ? Math.max(1, (c.dl + c.dh) / 2) : c.w || 1)), sw = w.reduce((t, x) => t + x, 0);
    return cards.map((c, i) => {
      const def = Math.max(1, Math.round((total * w[i]) / sw));
      const low = c.al !== undefined ? c.al : Math.round((def / 0.55) * (1 - VAR)), high = c.ah !== undefined ? c.ah : Math.round((def / 0.55) * (1 + VAR));
      return { id: c.id, bagid: 1000 + i, low, high, def, end: def, dl: Math.max(1, Math.round(def * (1 - VAR))), dh: Math.max(1, Math.round(def * (1 + VAR))), level: c.level || opt.enemyLevel || 1, star: c.star || 0, attri: c.attri || 0 };
    });
  };
  // The original fight (owner's video of v28, Mizuki 1-2): only my side attacks. My first ninja hits the first standing enemy with its attack;
  // the enemy's defence is taken off that attack. Attack left over -> the SAME ninja hits the next enemy (291+72 vs 140+20 -> 203 left, then
  // vs 125 -> 78 left, both enemies down). Defence left over -> that enemy keeps the rest and my next ninja carries on. All enemy defence
  // used up = win; all my attack used up first = loss. Each round: Attack/Defense = what the two cards show before the hit, FinalAttack /
  // FinalDefense the values that meet (CNewFightCardView: the attacker keeps Final - FinalDefense, the defender FinalDefense - FinalAttack).
  const play = (foes, want) => {
    const rollAtk = () => mine.map((m) => Math.max(1, Math.round(m.low + Math.random() * (m.high - m.low))));
    let atk = rollAtk();
    const rollDef = () => foes.map((f) => Math.max(1, f.dl && f.dh ? Math.round(f.dl + Math.random() * (f.dh - f.dl)) : f.def || 1));
    const def = rollDef();
    // Ninjutsu (owner's video: "Shadow technique, Skill damage increase: 72 (Chakra increase: 32)" = its attack value 40 + 32): when a ninja
    // starts attacking, each worn ninjutsu fires with its own chance (ninjutsuinfo m_rate, 15%); the damage (m_attackvalue + m_attackvalue_up per
    // card level above 1 + a chakra bonus) is added to that ninja's attack for the rest of its chain. At most 2 per hit (the client reads 2).
    // Chakra bonus = 20% of the ninja's average chakra (ours: the original formula is lost; the video fits it roughly).
    const rollSkills = () => mine.map((m) => {
      const skills = [];
      if (want === false && !process.env.HB_SKILLS) return skills;
      for (const r of m.jutsu) {
        if (skills.length >= 2) break;
        const n = table('ninjutsuinfo').rows.find((x) => x[0] === r.ninja_id);
        if (!n || !(process.env.HB_SKILLS || Math.random() < (Number(n[4]) || 0))) continue;
        const chakra = Math.round(m.chakra * 0.2), dmg = (n[10] || 0) + (n[18] || 0) * Math.max(0, (r.level || 1) - 1) + chakra;
        skills.push({ cardid: r.ninja_id, chakraattack: dmg, chakra }); // cardid = the ninjutsu's id (the client shows that ninjutsu's name)
      }
      return skills;
    });
    let skillsOf = rollSkills();
    // My master pet (pet.skillHurt): when a ninja of mine starts attacking, the pet's skill fires with its own chance (1/3) and its damage is
    // added to that ninja's attack like a ninjutsu; the round's AttPetSkillHurt makes the client show the pet clawing. Rolling it at each
    // ninja's first hit is (ours): the original timing is lost (players' video: the toad jumps in early in the fight). Not in a round where a
    // ninjutsu fires: the client then plays only the pet and the ninjutsu cut-in is lost.
    const rollPet = () => mine.map(() => (petSkill && (want !== false || process.env.HB_SKILLS) && (process.env.HB_SKILLS || Math.random() < petSkill.rate) ? petSkill.hurt : 0));
    let petOf = rollPet();
    foes.forEach((f) => { if (!f.attri) f.attri = foeAttri(f.id); });
    const rt = restrainTable();
    // Restrain (CFightResultData::firefly_CalcAttackVal: CauseLimit -1 adds LimitVal to "my restrain", 1 to "enemy restrain"): my element beats
    // theirs -> my hit +15% of its attack; theirs beats mine -> their defence +15% for that hit.
    const sim = (def0) => {
      const at = atk.slice(), df = def0.slice(), rolled = [];
      let i = 0, j = 0, started = -1;
      while (i < mine.length && j < foes.length && rolled.length < 60) {
        let skills = [], petHurt = 0;
        if (started !== i) { started = i; skills = skillsOf[i]; petHurt = skills.length ? 0 : petOf[i]; at[i] += skills.reduce((t, s) => t + s.chakraattack, 0) + petHurt; }
        const a = at[i], d = df[j], base = a - skills.reduce((t, s) => t + s.chakraattack, 0) - petHurt;
        const ma = mine[i].attri || 1, fa = foes[j].attri || 1, mr = rt.get(ma), fr = rt.get(fa);
        let cause = 0, limit = 0, finA = a, finD = d;
        if (mr && mr.beats === fa) { cause = -1; limit = Math.floor(a * mr.rate); finA = a + limit; }
        else if (fr && fr.beats === ma) { cause = 1; limit = Math.floor(d * fr.rate); finD = d + limit; }
        // AttackNinja / DefenseNinja = the NINJA id, not the card: the skill cut-in (CRoundTeamFightView::initMySkillData) finds its ninja by
        // comparing AttackNinja with each <ninja><id> and shows that ninja's picture and words; with the card number it found nothing and drew
        // the "update the full package" silhouette (Discord report, 3 Nov 2026). The cards themselves are played in order, not looked up.
        rolled.push({ AttackNinja: mine[i].id, Attack: base, AttackAttri: ma, DefenseNinja: foes[j].id, Defense: d, DefenseAttri: fa,
          CauseLimit: cause, LimitVal: limit, FinalAttack: finA, FinalDefense: finD, AttPetAttack: 0, AttPetDefense: 0, DefPetAttack: 0, DefPetDefense: 0,
          AttPetSkillHurt: petHurt, DefpetSkillHurt: 0, AttGateAttack: 0, AttGateDefense: 0, DefGateAttack: 0, DefGateDefense: 0, _skills: skills });
        if (finA > finD) { at[i] = finA - finD; df[j] = 0; j++; }
        else if (finA < finD) { df[j] = finD - finA; at[i] = 0; i++; }
        else { at[i] = 0; df[j] = 0; i++; j++; }
      }
      return { rounds: rolled, won: j >= foes.length };
    };
    // The server decided the result already. Keep the enemy's real stats and re-roll only my luck (attack inside my real range, ninjutsu
    // chances) until the replay ends that way, so watching and skipping show the same fight with true numbers. Only if no roll fits
    // (the decision's luck range is wider than the cards' range) the enemy defence is nudged as a last resort.
    let out = sim(def);
    for (let k = 0; k < 400 && typeof want === 'boolean' && out.won !== want; k++) { atk = rollAtk(); skillsOf = rollSkills(); petOf = rollPet(); const d = rollDef(); for (let j = 0; j < def.length; j++) def[j] = d[j]; out = sim(def); }
    for (let k = 0; k < 30 && typeof want === 'boolean' && out.won !== want; k++) {
      for (let j = 0; j < def.length; j++) def[j] = want ? Math.max(1, Math.floor(def[j] * 0.9)) : Math.ceil(def[j] * 1.15);
      out = sim(def);
    }
    foes.forEach((f, j) => { f.def = def[j]; });
    return out;
  };
  let foes, fight;
  if (opt.real) { foes = mkFoes(); fight = play(foes, 'real'); }
  else if (opt.win === undefined) { foes = mkFoes(0.6); fight = play(foes, true); } // no decision given: a win
  else { foes = mkFoes(opt.win ? 0.75 : 1.3); fight = play(foes, !!opt.win); }
  foes.forEach((f) => { f.end = f.def; }); // the victory screen adds up <end>: enemies = their defence (video: "total defence 285"), mine = attack
  const rounds = fight.rounds;
  const roundXml = rounds.map((r) => '<round>' + Object.entries(r).filter(([k]) => k !== '_skills').map(([k, v]) => el(k, v)).join('') +
    '<skills>' + (r._skills || []).map((s) => `<skill>${el('cardid', s.cardid)}${el('chakraattack', s.chakraattack)}${el('chakra', s.chakra)}</skill>`).join('') + '</skills><defense_skills></defense_skills></round>').join('');
  const win = fight.won ? 1 : 0;
  if (opt.out) opt.out.win = fight.won;
  const nick = (opt.enemyName || 'Enemy').replace(/[<>&"]/g, '');
  return `<fight><preview type="0" result="${win}" defensenick="${nick}" defenseuid="${opt.enemyUid || 0}" defensecountry="${opt.enemyCountry || 1}" defenselevel="${opt.enemyLevel || 1}" defenseviplevel="0"/>` +
    '<guard><ninjalist>' + foes.map(ninjaXml).join('') + '</ninjalist></guard>' +
    '<killer><ninjalist>' + mine.map(ninjaXml).join('') + '</ninjalist>' +
    masterPetXml(db, pl) + '</killer>' +
    '<roundlist>' + roundXml + '</roundlist></fight>';
}

// Spar fight against rival ToUid (a real player or a bot). Strength = level + stars of the team; a little luck.
// Spar the same player at most 5 times a day (normalconfig 44)
const SPAR_SAME = 5;
function sparCount(db, pl, toUid) {
  db.exec('CREATE TABLE IF NOT EXISTS spar_pairs (uid INTEGER, server_id INTEGER, day TEXT, to_uid INTEGER, n INTEGER, PRIMARY KEY(uid, server_id, day, to_uid))');
  return (db.prepare('SELECT n FROM spar_pairs WHERE uid=? AND server_id=? AND day=? AND to_uid=?').get(pl.uid, pl.server_id, today(), toUid) || { n: 0 }).n;
}
function sparTooOften(db, pl, toUid) { return sparCount(db, pl, toUid) >= SPAR_SAME; }
function sparFight(db, pl, toUid) {
  sparCount(db, pl, toUid);
  db.prepare('INSERT INTO spar_pairs VALUES(?,?,?,?,1) ON CONFLICT(uid, server_id, day, to_uid) DO UPDATE SET n=n+1').run(pl.uid, pl.server_id, today(), toUid);
  const rv = rivals(db, pl, 12).find((r) => r.id === toUid) || { id: toUid, level: pl.level, nick: 'Rival', ninja: 5 };
  // bot strength in the same units as a ninja's attack (level 1 shinobi ~ 210): about even at equal level (ours)
  const botAtk = (lv, star) => 60 + lv * 30 + star * 30;
  const ts = teamStats(db, pl.uid, pl.server_id);
  const mine = (ts.total.al + ts.total.ah) / 2 / Math.max(1, ts.slots.length);
  let theirs;
  // real players have uids of 22 000 000+ (the old test `< 9000000` treated every real rival as a bot); bots are 9000001+ and not in players
  const o = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(rv.id, pl.server_id);
  if (o) { const t2 = o ? teamStats(db, o.uid, o.server_id) : null; theirs = t2 ? (t2.total.al + t2.total.ah) / 2 / Math.max(1, t2.slots.length) : botAtk(rv.level, 3); }
  else theirs = botAtk(rv.level, rv.star || 3);
  // Decided by average card strength with luck (the odds the owner kept). Deciding by the whole-team replay was tried: team totals barely
  // vary, so one card more or less made spar all-or-nothing. The replay shows both whole teams and ends the same way. HB_SPAR = test aid.
  const win = process.env.HB_SPAR ? process.env.HB_SPAR === 'win' : mine * (0.7 + Math.random() * 0.6) >= theirs;
  const xml = battleXml(db, pl, 0, 1, { enemyIds: foeTeam(db, rv.id, pl.server_id, rv.ninja, rv.level, 0, ts.slots.length), ratio: theirs / Math.max(1, mine), win, enemyName: rv.nick, enemyUid: rv.id, enemyLevel: rv.level, enemyCountry: o ? o.country : rv.country });
  // ORIGINAL: the game's own duelinfo table, the same one its Spar Preview (CFightPreView) shows, picked by the RIVAL's level:
  // [5] win EXP, [6] lose EXP, [7] / [8] W.A. for a win / loss, [3] share of the rival's silver won, [4] share of your silver lost
  // (photo 0078: a level-224 player vs a level-340 rival = 228 / 76 EXP, 15 / 5 W.A., -542 silver). The bot's silver is the list's coin.
  const rows = table('duelinfo').rows.filter((r) => r[0] === r[2]);
  const d = rows.find((r) => r[0] === rv.level) || rows[rows.length - 1];
  const theirCoin = o ? (o.coin || 0) : 100 + rv.level * 20;
  // a loss costs at most 1000 silver (normalconfig 89)
  const coin = win ? Math.round(theirCoin * d[3]) : -Math.min(1000, Math.round((pl.coin || 0) * d[4])), exp = win ? d[5] : d[6];
  const merit = (win ? d[7] : d[8]) * (buffOn(db, pl, BUFF_WA) ? 2 : 1); // War Achievements Increase Pill running: double
  propAdd(db, pl.uid, pl.server_id, 9994, merit); // W.A. (war achievements)
  return { win, xml, coin, exp, merit, rivalLevel: rv.level };
}

// Player exp -> level (playerlevel.dbf col 2 = exp needed to leave that level).
function addExp(db, pl, exp) {
  const rows = table('playerlevel').rows;
  let level = pl.level, cur = (pl.exp || 0) + exp;
  for (;;) {
    const r = rows.find((x) => x[1] === level);
    if (!r || cur < r[2] || !rows.some((x) => x[1] === level + 1)) break; // the table ends at 350: no level past it
    cur -= r[2]; level++;
  }
  db.prepare('UPDATE players SET level=?, exp=? WHERE uid=? AND server_id=?').run(level, cur, pl.uid, pl.server_id);
  if (level > pl.level) require('./playerlog').note(db, pl.uid, pl.server_id, 'level', level); // progress log (admin > Player log)
  if (level > pl.level) { // a level-up fills energy and grudge to the new level's maximum (the original "LEVEL UP!" pop-up shows
    // "Energy ↑ Grudge ↑", Facebook photo 2156; owner: "leveling should refill")
    const max = (rows.find((x) => x[1] === level) || [])[4] || 0;
    db.prepare('UPDATE players SET energy=MAX(energy,?), energy_t=?, sp=-1 WHERE uid=? AND server_id=?').run(max, Math.floor(Date.now() / 1000), pl.uid, pl.server_id);
  }
  return level;
}

// ---- Daily tasks -----------------------------------------------------------------------------
// "today" everywhere = the server PC's local date, so daily things reset at local midnight like the game says ("reset at 00:00") (was UTC = 01:00 in NL)
const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
// Daily task chests. ORIGINAL (Facebook photos 0175, 1328, 4107, 4211): a 250-point bar with exactly 6 chests at 30 / 80 / 120 / 160 / 210 / 250;
// the 250 chest = 30 000 silver + 100 gold + 10 Reincarnation Pills + 1 Killer B fragment. The contents of the other chests are (ours). dropinfo ids.
const DAILY_TOTAL = 250;
const DAILY_AWARDS = [
  { id: 1, cost: 30, drops: [46] }, { id: 2, cost: 80, drops: [97] }, { id: 3, cost: 120, drops: [100] },
  { id: 4, cost: 160, drops: [56, 97] }, { id: 5, cost: 210, drops: [260] }, { id: 6, cost: 250, drops: [226, 260, 108, 1166] },
];
function dailyEnsure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS dailytask (uid INTEGER, server_id INTEGER, day TEXT, task_id INTEGER, process INTEGER DEFAULT 0, PRIMARY KEY(uid,server_id,day,task_id));
    CREATE TABLE IF NOT EXISTS dailyaward (uid INTEGER, server_id INTEGER, day TEXT, award_id INTEGER, PRIMARY KEY(uid,server_id,day,award_id));`);
}
const dailyRows = () => table('dailytask_info').rows.filter((r) => r[7] === 1 && r[0] <= 21);
function bumpTask(db, uid, sid, taskId, n = 1) {
  dailyEnsure(db);
  db.prepare('INSERT INTO dailytask(uid,server_id,day,task_id,process) VALUES(?,?,?,?,?) ON CONFLICT(uid,server_id,day,task_id) DO UPDATE SET process=process+excluded.process').run(uid, sid, today(), taskId, n);
}
function dailyXml(db, uid, sid) {
  dailyEnsure(db);
  const done = Object.fromEntries(db.prepare('SELECT task_id, process FROM dailytask WHERE uid=? AND server_id=? AND day=?').all(uid, sid, today()).map((r) => [r.task_id, r.process]));
  const claimed = new Set(db.prepare('SELECT award_id FROM dailyaward WHERE uid=? AND server_id=? AND day=?').all(uid, sid, today()).map((r) => r.award_id));
  let score = 0;
  const tasks = dailyRows().map((r) => {
    const p = Math.min(done[r[0]] || 0, r[5]);
    if (p >= r[5]) score += r[6];
    return `<task id="${r[0]}" process="${p}"/>`;
  }).join('');
  score = Math.min(score, DAILY_TOTAL);
  const awards = DAILY_AWARDS.map((a) => `<award id="${a.id}" status="${claimed.has(a.id) ? 2 : score >= a.cost ? 1 : 0}" cost="${a.cost}"><drop_list>${a.drops.map((d) => `<item>${d}</item>`).join('')}</drop_list></award>`).join('');
  return `<player><total>${DAILY_TOTAL}</total><current>${score}</current></player><task_list>${tasks}</task_list><award_list>${awards}</award_list>`;
}
function dailyClaim(db, pl, awardId) {
  dailyEnsure(db);
  const a = DAILY_AWARDS.find((x) => x.id === awardId);
  if (!a) return null;
  if (db.prepare('SELECT 1 FROM dailyaward WHERE uid=? AND server_id=? AND day=? AND award_id=?').get(pl.uid, pl.server_id, today(), awardId)) return { error: 'already claimed' };
  // the client greys the box until the day's points reach its cost; check the same thing here
  const m = dailyXml(db, pl.uid, pl.server_id).match(new RegExp(`<award id="${awardId}" status="(\\d)"`));
  if (!m || m[1] !== '1') return { error: 'points not reached' };
  db.prepare('INSERT OR IGNORE INTO dailyaward(uid,server_id,day,award_id) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, today(), awardId);
  return { xml: mergeAwards(a.drops.map((id) => grantDrop(db, pl, id)).filter(Boolean)) };
}
// Complete <award> element (Lua requires every child to exist).
function awardFull({ coin = 0, cash = 0, exp = 0, merit = 0 } = {}) {
  return `<award dropid="0" coin="${coin}"><coin>${coin}</coin><cash>${cash}</cash><exp>${exp}</exp><chip>0</chip><action>0</action><merit>${merit}</merit><pk_action>0</pk_action><soul>0</soul></award>`;
}

// ---- Spar / rivals --------------------------------------------------------------------------
const BOT_NAMES = ['Iron Fist Lee', 'Shadow Hana', 'Rogue Kaito', 'Silent Ren', 'Blaze Mika', 'Sand Gaku', 'Mist Yuna', 'Thunder Ryo', 'Frost Aoi', 'Wind Sora'];
// Rival list: other real players first (friends on the same server), then bots near the player's level.
// Benchmark rivals (Server Manager switch "Benchmark rivals in Spar"): computer teams with a fixed total defence, top of the Spar list.
// Fighting them is free (no grudge), pays nothing, and the result is the real replay (no decided outcome).
const BENCH = [100000, 500000, 1000000, 2000000, 4000000, 8000000];
const benchId = (i) => 8000001 + i;
const shortNum = (n) => (n >= 1e6 ? n / 1e6 + 'M' : n / 1e3 + 'K');
function benchRivals(db) {
  if (!settings.eventOn(db, 'bench')) return [];
  const ids = [2085, 5037, 2029, 2070, 5070, 5040]; // god cards as the shown face (ours)
  return BENCH.map((d, i) => ({ id: benchId(i), level: 350, nick: 'Benchmark ' + shortNum(d), country: 1, ninja: ids[i % ids.length], star: 6, bench: d }));
}
function benchFight(db, pl, toUid) {
  const b = benchRivals(db).find((r) => r.id === toUid);
  if (!b) return null;
  const foes = spreadFoes([b.ninja, b.ninja, b.ninja, b.ninja, b.ninja], b.bench, 350);
  const out = {};
  const xml = battleXml(db, pl, 0, 1, { foes, real: true, enemyName: b.nick, enemyUid: b.id, enemyLevel: 350, out });
  return { win: out.win, xml, coin: 0, exp: 0 };
}
function rivals(db, pl, count = 8) {
  const real = db.prepare('SELECT * FROM players WHERE server_id=? AND uid!=? ORDER BY ABS(level-?) LIMIT ?').all(pl.server_id, pl.uid, pl.level, count);
  const out = real.map((r) => ({ id: r.uid, level: r.level, nick: r.nick, country: r.country, ninja: firstNinja(db, r), coin: r.coin || 0 }));
  const pool = Array.from(ninjas().values()).filter((r) => r[4] === 1);
  for (let i = 0; out.length < count; i++) {
    const n = pool[(pl.level * 7 + i * 13) % pool.length];
    out.push({ id: 9000001 + i, level: Math.max(1, pl.level + (i % 5) - 2), nick: BOT_NAMES[i % BOT_NAMES.length], country: 1 + (i % 3), ninja: n[0], star: n[11] });
  }
  return out;
}
function firstNinja(db, p) {
  const c = db.prepare('SELECT ninja_id FROM cards WHERE uid=? AND server_id=? ORDER BY starlevel DESC, seq LIMIT 1').get(p.uid, p.server_id);
  return c ? c.ninja_id : 5;
}
function rivalsXml(db, pl) {
  const f = (r) => {
    const lv = r.level, a = 20 + lv * 12;
    const o = { id: r.id, level: lv, nick: r.nick, attacklow: a, attackhigh: a + 20, defenselow: Math.floor(a / 2), defenseHigh: Math.floor(a / 2) + 10,
      chakralow: a, chakrahigh: a + 20, firstninja: r.ninja, firstninjastar: r.star || 3, newlife: 0, country: r.country, coin: r.coin !== undefined ? r.coin : 100 + lv * 20 }; // the preview's silver = coin x duelinfo share, so a real rival shows his real silver (sparFight pays from it)
    return '<user>' + Object.entries(o).map(([k, v]) => el(k, v)).join('') + '</user>';
  };
  const bench = benchRivals(db).map((r) => '<user>' + Object.entries({ id: r.id, level: r.level, nick: r.nick, attacklow: r.bench, attackhigh: r.bench, defenselow: r.bench, defenseHigh: r.bench,
    chakralow: 0, chakrahigh: 0, firstninja: r.ninja, firstninjastar: 6, newlife: 0, country: 1, coin: 0 }).map(([k, v]) => el(k, v)).join('') + '</user>').join('');
  return '<userlist page="1" addrate="0" resttime="0">' + bench + rivals(db, pl).map(f).join('') + '</userlist>';
}

// ---- Event packs (login days / level-up gifts) ------------------------------------------------
function actEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS actclaim (uid INTEGER, server_id INTEGER, actid INTEGER, subid INTEGER, PRIMARY KEY(uid,server_id,actid,subid))');
}
function actClaimable(db, pl) {
  actEnsure(db);
  const P = table('activity_packs');
  const days = Math.max(1, Math.min(30, Math.floor((Date.now() - (pl.created || Date.now())) / 86400000) + 1));
  const done = (a) => new Set(db.prepare('SELECT subid FROM actclaim WHERE uid=? AND server_id=? AND actid=?').all(pl.uid, pl.server_id, a).map((r) => r.subid));
  const d1 = done(1), d2 = done(2);
  const login = [], up = [];
  for (let i = 1; i <= Math.min(days, P.login_q.length); i++) if (!d1.has(i)) login.push(i);
  P.upgrade_levels.forEach((l, k) => { if (pl.level >= l && !d2.has(k + 1)) up.push(k + 1); });
  return { days, login, up };
}
function actXml(db, pl) {
  require('./stagegift').ensure(db);
  const c = actClaimable(db, pl);
  const subs = (a) => a.map((i) => `<subitem subid="${i}"></subitem>`).join('');
  return `<activity type="1" loginallnum="${c.days}"><item actid="1">${subs(c.login)}</item></activity>` +
    `<activity type="2"><item actid="2">${subs(c.up)}</item></activity><activity type="3"><item actid="3" pos="${require('./caishen').step(db, pl)}"></item></activity><activity type="4">${require('./monthcard').itemXml(db, pl)}</activity>${require('./keeplogin').xml(db, pl)}` +
    // Events switched off in the Server Manager are left out of the list, so their button / Event menu line disappears.
    '<conf><items>' + [...new Map(settings.EVENTS.filter((e) => e.id !== 31 && !e.noconf && settings.eventOn(db, e.id)).map((e) => [e.screen || e.id, { ...e, id: e.screen || e.id }])).values()].map(({ id, pos, type }) => `<item><id>${id}</id><pos>${pos}</pos><status>1</status><onoff>1</onoff><type>${type}</type></item>`).join('') +
    `<item><id>31</id><pos>10</pos><status>1</status><onoff>0</onoff><type>1</type><timeleft>${!settings.eventOn(db, 31) || db.prepare('SELECT 1 FROM stagegift WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) ? 0 : 315360000}</timeleft></item>` + '</items><xiaoopen>1</xiaoopen><gambletype>1</gambletype></conf>';
}
// What the pack screens show comes from the client's own Lua tables (loginPackData / upgradePackData, 1-4 dropinfo ids each):
// pay exactly those drops, so the dialog and the backpack match the icons on the button.
let packLua = null;
function actPackDrops(actid, subid) {
  if (!packLua) {
    packLua = { 1: [], 2: [] };
    const dir = require('path').join(__dirname, 'reference', 'lua-scripts');
    for (const [a, file] of [[1, 'loginActivityData.lua'], [2, 'upgradeActivityData.lua']]) {
      let txt = '';
      try { txt = require('fs').readFileSync(require('path').join(dir, file), 'utf8'); } catch (e) { continue; }
      for (const m of txt.matchAll(/PackData\[(\d+)\]\s*=\s*\{([^}]*)\}/g)) {
        packLua[a][Number(m[1]) - 1] = [...m[2].matchAll(/_drop(\d)id=(\d+)/g)].map((x) => Number(x[2])).filter((id) => id > 0);
      }
    }
  }
  return (packLua[actid] || [])[subid - 1] || [];
}
// Cumulative top-up rewards (the "49$ gift" / pay history list): payhistorydropData.lua has month_dayback = dollars topped up in total and up to 4
// dropinfo ids per step. The client wants <payheaplist><payheap><id/><state/></payheap>...</payheaplist>: state 0 = can claim, 250011 = not yet, 2 = claimed.
let heapRows = null;
function payHeapRows() {
  if (!heapRows) {
    heapRows = [];
    let txt = '';
    try { txt = fs.readFileSync(path.join(__dirname, 'reference', 'lua-scripts', 'payhistorydropData.lua'), 'utf8'); } catch (e) { /* none */ }
    for (const m of txt.matchAll(/pay_history_drop\[(\d+)\]\s*=\s*\{([^}]*)\}/g)) {
      const f = m[2], num = (k) => Number((f.match(new RegExp(k + '=(\\d+)')) || [0, 0])[1]);
      heapRows[Number(m[1])] = { id: Number(m[1]), dollars: num('month_dayback'), drops: [1, 2, 3, 4].map((i) => num('drop' + i + 'id')).filter((x) => x > 0) };
    }
  }
  return heapRows.filter(Boolean);
}
function payHeapState(db, pl, topped) {
  actEnsure(db);
  const done = new Set(db.prepare('SELECT subid FROM actclaim WHERE uid=? AND server_id=? AND actid=9028').all(pl.uid, pl.server_id).map((r) => r.subid));
  return payHeapRows().map((r) => ({ id: r.id, state: done.has(r.id) ? 2 : topped >= r.dollars ? 0 : 250011 }));
}
function payHeapXml(db, pl, topped) {
  return '<payheaplist>' + payHeapState(db, pl, topped).map((x) => `<payheap><id>${x.id}</id><state>${x.state}</state></payheap>`).join('') + '</payheaplist>';
}
function payHeapClaim(db, pl, topped, heapId) {
  const st = payHeapState(db, pl, topped).find((x) => x.id === heapId);
  if (!st) return { code: 5, msg: 'no such reward' };
  if (st.state === 2) return { code: 250010, msg: 'already claimed' };
  if (st.state !== 0) return { code: 250011, msg: 'not reached yet' };
  db.prepare('INSERT OR IGNORE INTO actclaim(uid,server_id,actid,subid) VALUES(?,?,9028,?)').run(pl.uid, pl.server_id, heapId);
  return { code: 0, xml: mergeAwards(payHeapRows().find((r) => r.id === heapId).drops.map((id) => grantDrop(db, pl, id)).filter(Boolean)) };
}
function actClaim(db, pl, actid, subid) {
  const c = actClaimable(db, pl);
  const ok = (actid === 1 ? c.login : actid === 2 ? c.up : []).includes(subid);
  if (!ok) return null;
  db.prepare('INSERT OR IGNORE INTO actclaim(uid,server_id,actid,subid) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, actid, subid);
  const got = actPackDrops(actid, subid).map((id) => grantDrop(db, pl, id)).filter(Boolean);
  return { xml: mergeAwards(got) };
}

// ---- Consumables / shop ---------------------------------------------------------------------
function propEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS props (uid INTEGER, server_id INTEGER, prop_id INTEGER, count INTEGER DEFAULT 0, PRIMARY KEY(uid,server_id,prop_id))');
}
function propCounts(db, uid, sid) {
  propEnsure(db);
  return Object.fromEntries(db.prepare('SELECT prop_id, count FROM props WHERE uid=? AND server_id=?').all(uid, sid).map((r) => [r.prop_id, r.count]));
}
function propAdd(db, uid, sid, id, n) {
  propEnsure(db);
  db.prepare('INSERT INTO props(uid,server_id,prop_id,count) VALUES(?,?,?,?) ON CONFLICT(uid,server_id,prop_id) DO UPDATE SET count=MAX(0,count+excluded.count)').run(uid, sid, id, n);
  if (id === 9996 && n > 0) bumpTask(db, uid, sid, 19, n); // daily task: get 1000 arena reputation
  if (id === 9994 && n > 0) propAdd(db, uid, sid, WA_TOTAL, n); // W.A. ever earned (the title does not drop when W.A. is spent)
}
// W.A. title ("Junior Genin" ... "Supreme Gaiden"): ORIGINAL table playemedal: [9] W.A. needed, [3]-[8] flat attack / defense / chakra added to
// the team (the client's CPlayerDataMgr::firefly_GetPlayerAttack adds the same). Login sends it as <meritlevel> (was always 0 before
// 2 Nov 2026, so no title and no bonus). The total counts every W.A. ever earned; older players start from their current W.A. (ours).
const WA_TOTAL = 9993;
function meritLevel(db, uid, sid) {
  const have = propCounts(db, uid, sid);
  const total = have[WA_TOTAL] || have[9994] || 0;
  let lv = 0;
  for (const r of table('playemedal').rows) if (total >= r[9]) lv = r[0];
  return lv;
}
// Buy: kind 'good' (consumeinfo) or 'pack' (giftinfo, opened immediately for coins/gold).
// Gold prices the original shop showed that differ from consumeinfo (Facebook photos 0080, 0082, 1011, 1757, 2964): Reincarnation Pill 120
// (table 180), Development Dan 120 (table 200); Element Change Pill "Currently not for sale" (photos 1425, 1494; table 200): 0 = not sold.
const SHOP_GOLD = { 11: 120, 34: 120, 33: 0 };
const shopGold = (row) => SHOP_GOLD[row[1]] ?? row[4];
function shopBuy(db, pl, goodsId, count) {
  const row = table('consumeinfo').rows.find((r) => r[1] === goodsId);
  if (!row) return { error: 'no such item' };
  if (!shopGold(row) && !row[5]) return { error: 'not available' }; // "Currently not for sale"
  const costG = shopGold(row) * count, costS = row[5] * count;
  if (pl.gold < costG || pl.coin < costS) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-?, coin=coin-? WHERE uid=? AND server_id=?').run(costG, costS, pl.uid, pl.server_id);
  propAdd(db, pl.uid, pl.server_id, goodsId, count);
  bumpTask(db, pl.uid, pl.server_id, 18);
  return { costG, costS };
}

// Use a consumable. Effects: type 3 = silver, type 1 = energy; other types are only consumed.
function propUse(db, pl, goodsId) {
  const row = table('consumeinfo').rows.find((r) => r[1] === goodsId);
  const have = propCounts(db, pl.uid, pl.server_id)[goodsId] || 0;
  if (!row || have < 1) return { error: 'none left' };
  if (row[7] === 6 || row[7] === 9) { // card fragments (type 6) and ninja souls (type 9): ORIGINAL item text "Every 50 (40) ... can synthesise to ..."
    const need = Math.round(row[8]) || 50;        // [8] = 50 (Sage Naruto souls 40)
    if (have < need) return { error: `not enough fragments (${need} needed)` };
    const star = /Five-Star/.test(row[2]) ? 5 : 4, pick = (a) => a[Math.floor(Math.random() * a.length)]; // exactly the card the text names
    const drop = table('dropinfo').rows.find((x) => x[0] === row[9]) || []; // [9] = the drop: a fixed card (The Fourth Sage 531, Sage Naruto 337 ...) or a random pack (10-15)
    const roll = drop[12] !== 1 && drop[3] > 0 ? { ninja: drop[3] }
      : /Shinobi/.test(row[2]) ? { ninja: pick(pools()[star]) } : /Equipment/.test(row[2]) ? { equip: randomEquip(Math.floor(Math.random() * 3), star, star) }
      : { ninjutsu: pick(table('ninjutsuinfo').rows.filter((x) => x[5] === star && x[6] === 1))[0] };
    propAdd(db, pl.uid, pl.server_id, goodsId, -need);
    let card = null; // CItemView reads the new card from <propuse> attributes: ninjaid / equipid / skillid + their bag ids
    if (roll.ninja) card = { attr: `ninjaid="${roll.ninja}" ninjabagid="${giveCard(db, pl.uid, pl.server_id, roll.ninja)}" ninjaattr="0"` };
    else if (roll.equip) card = { attr: `equipid="${roll.equip}" equipbagid="${giveEquip(db, pl.uid, pl.server_id, roll.equip)}"` };
    else if (roll.ninjutsu) card = { attr: `skillid="${roll.ninjutsu}" skillbagid="${giveCard(db, pl.uid, pl.server_id, roll.ninjutsu, 6)}"` };
    return { ap: 0, coin: 0, left: have - need, card };
  }
  const lim = USE_COL[row[7]] ? useLimit(db, pl, row[7]) : null;
  if (lim && lim.rest <= 0) return { error: 'no uses left today (a higher VIP level gives more)' };
  const s = row[7] === 2 ? spState(db, pl) : null;
  if (s && s.sp >= s.max) return { error: 'your grudge is already full' };
  propAdd(db, pl.uid, pl.server_id, goodsId, -1);
  if (lim) db.prepare('INSERT INTO prop_uses(uid, server_id, kind, day, used) VALUES(?,?,?,?,?) ON CONFLICT(uid, server_id, kind) DO UPDATE SET day=excluded.day, used=excluded.used')
    .run(pl.uid, pl.server_id, row[7], today(), lim.used + 1);
  let coin = 0, ap = 0, sp = 0;
  if (row[7] === 3) { coin = Math.round(row[8]); db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(coin, pl.uid, pl.server_id); }
  if (row[7] === 1) { energyTick(db, pl); db.prepare('UPDATE players SET energy=energy+? WHERE uid=? AND server_id=?').run(Math.round(row[8]), pl.uid, pl.server_id); }
  if (row[7] === 10 || row[7] === 15) buffAdd(db, pl, row[7], Math.round(row[8]) || 300);
  if (row[7] === 18) propAdd(db, pl.uid, pl.server_id, GATE_SOUL, (propCounts(db, pl.uid, pl.server_id)[GATE_SOUL] === undefined ? 5000 : 0) + 1000); // Souls Dan: "receive 1000 souls per dan for eight gates"
  if (s) { // Hyourou-gan: [8] = 0.5 / 1 of the maximum grudge (duel points), up to the maximum
    sp = Math.min(s.max, s.sp + Math.max(1, Math.round(s.max * row[8])));
    db.prepare('UPDATE players SET sp=?, sp_t=? WHERE uid=? AND server_id=?').run(sp, sp >= s.max ? Math.floor(Date.now() / 1000) : s.t, pl.uid, pl.server_id);
  }
  const now = db.prepare('SELECT energy, coin FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  if (row[7] === 1) ap = now.energy; // the ramen dialog SETS the energy to <propuse ap> (BuyRemenDlg: SetBodyValue(ap)): send the new total
  // the client (CTradeMgr::UseConsumeItemByID) sets energy = ap and duel points = sp when they are not 0
  return { ap, sp, coin, left: have - 1, limit: lim && { rest: lim.rest - 1, max: lim.max } };
}
// Timed pills, ORIGINAL item texts: War Achievements Increase Pill (consumeinfo type 10) "Sparring players can earn double the battle
// achievements for 5 minutes", Double Exp Pill (type 15) "receiving X2 exp during training in 5 min"; [8] = 300 s. Another pill adds 5 minutes.
function buffAdd(db, pl, kind, secs) {
  db.exec('CREATE TABLE IF NOT EXISTS buffs (uid INTEGER, server_id INTEGER, kind INTEGER, until INTEGER, PRIMARY KEY(uid, server_id, kind))');
  const now = Math.floor(Date.now() / 1000), until = Math.max(now, buffUntil(db, pl, kind)) + secs;
  db.prepare('INSERT INTO buffs(uid, server_id, kind, until) VALUES(?,?,?,?) ON CONFLICT(uid, server_id, kind) DO UPDATE SET until=excluded.until').run(pl.uid, pl.server_id, kind, until);
}
function buffUntil(db, pl, kind) {
  db.exec('CREATE TABLE IF NOT EXISTS buffs (uid INTEGER, server_id INTEGER, kind INTEGER, until INTEGER, PRIMARY KEY(uid, server_id, kind))');
  const r = db.prepare('SELECT until FROM buffs WHERE uid=? AND server_id=? AND kind=?').get(pl.uid, pl.server_id, kind);
  return r ? r.until : 0;
}
const buffOn = (db, pl, kind) => buffUntil(db, pl, kind) > Date.now() / 1000;
const BUFF_WA = 10, BUFF_EXP = 15;
// Daily uses of ramen (consumeinfo type 1) and Hyourou-gan (type 2): ORIGINAL vipinfo [6] "use 20 ramen daily" and [7] "use 30 Hyourou-gan
// daily" (row = VIP level + 1, +2 / +3 a VIP level). The item window shows what is left (CTradeMgr rest/max: <propuse rest max>, shoplist <limit>).
const USE_COL = { 1: 6, 2: 7 };
// The vipinfo row of a player: VIP level + 1, like every screen of the game reads it (ui_vipRightInfoView shows VIP L from row L + 1;
// CommonBuyItemDialog, boxOpenActivityView, ui_secretShopLayer use viplevel + 1). So VIP0 = row 1 ("open gold chest 25 times" ...).
const vipRow = (db, pl, next = 0) => { const v = require('./vip').level(db, pl.uid, pl.server_id) + next; return table('vipinfo').rows.find((r) => r[0] === v + 1) || table('vipinfo').rows[table('vipinfo').rows.length - 1]; }; // next 1 = the next VIP level
function useLimit(db, pl, kind) {
  db.exec('CREATE TABLE IF NOT EXISTS prop_uses (uid INTEGER, server_id INTEGER, kind INTEGER, day TEXT, used INTEGER, PRIMARY KEY(uid, server_id, kind))');
  const max = vipRow(db, pl)[USE_COL[kind]] || 0;
  const r = db.prepare('SELECT day, used FROM prop_uses WHERE uid=? AND server_id=? AND kind=?').get(pl.uid, pl.server_id, kind);
  const used = r && r.day === today() ? r.used : 0;
  return { max, used, rest: Math.max(0, max - used) };
}

// Small EXP-card bags: ORIGINAL (Facebook photo 2695) Ninja Bag (S) and Weapon Bag (S) cost 2000 silver (the game's table says 2800); the
// armor / trinket / skill bags (ours) the same. The rest keeps the giftinfo price (Ninja Bag (L) 13 000 and SageStone bags match the photos).
const PACK_SILVER = { 1: 2000, 3: 2000, 4: 2000, 5: 2000, 6: 2000 };
const packSilver = (r) => PACK_SILVER[r[0]] ?? r[5];
// Gift packs (Shop > Giftpack): item bags give their items, card bags shinobi / gear; ninjutsu bags stay refused (the client crashes on them).
function packBuy(db, pl, packId) {
  const g = table('giftinfo').rows.find((r) => r[0] === packId);
  if (!g) return { error: 'no such pack' };
  // giftinfo [7] = 2: a bag of items, [8] = the item (consumeinfo id), [9] = how many (Rāmen Bag 10 / 50 Rāmen (L), Tael Bag 10 taels,
  // SageStone Bag 100 stones). ORIGINAL (the bags' own texts). The client adds them itself from <retobj type="1" id count>.
  // Before 2 Nov 2026 [8] was read as a drop id: a Rāmen Bag gave 10 Chōji cards, a Tael Bag a random ninja.
  if (g[7] === 2) {
    const item = Math.round(g[8]), count = Math.max(1, Math.round(g[9]) || 1);
    if (!table('consumeinfo').rows.some((r) => r[1] === item)) return { error: 'this pack is not available on the revival server yet' };
    const costG = g[4], costS = packSilver(g);
    if (pl.gold < costG || pl.coin < costS) return { error: 'not enough gold' };
    db.prepare('UPDATE players SET gold=gold-?, coin=coin-? WHERE uid=? AND server_id=?').run(costG, costS, pl.uid, pl.server_id);
    propAdd(db, pl.uid, pl.server_id, item, count);
    return { costG, costS, item, n: count };
  }
  const drop = table('dropinfo').rows.find((r) => r[0] === Math.round(g[8]));
  if (!drop) return { error: 'this pack is not available on the revival server yet' };
  const name = String(g[2]).toLowerCase();
  const costG = g[4], costS = packSilver(g);
  if (pl.gold < costG || pl.coin < costS) return { error: 'not enough gold' };
  let give; // () => [type, id, seq]
  if (drop[3] && ninjas().has(drop[3])) give = () => [1, drop[3], giveCard(db, pl.uid, pl.server_id, drop[3])];
  else if (drop[4] && equipRows().some((r) => r[0] === drop[4] && r[5] === 3)) give = () => [2, drop[4], giveEquip(db, pl.uid, pl.server_id, drop[4])];
  // Ninjutsu / Skill bags stay closed: the client's package code (CTradeMgr::UseGiftPackItem) only knows items, shinobi and gear
  // (retobj type 1-5); any ninjutsu reply crashed the game (checked 2 Nov 2026), so a buyer would pay without seeing the card.
  else if (drop[5] && /ninjutsu|ninjitsu|skill/.test(name)) return { error: 'this pack is not available on the revival server yet' };
  else if (/weapon|armor|trinket/.test(name)) {
    const slot = /weapon/.test(name) ? 0 : /armor/.test(name) ? 1 : 2;
    const minStar = /4☆/.test(name) ? 3 : 2;
    give = () => { const id = equipFromText(String(drop[2])) || randomEquip(slot, minStar); return [SLOT_TYPE[slot], id, giveEquip(db, pl.uid, pl.server_id, id)]; }; // the bag's own text (3☆ bag: 2-4 stars, never 5)
  } else return { error: 'this pack is not available on the revival server yet' };
  db.prepare('UPDATE players SET gold=gold-?, coin=coin-? WHERE uid=? AND server_id=?').run(costG, costS, pl.uid, pl.server_id);
  const n = Math.max(1, drop[13] || 1);
  let first = null; const seqs = [];
  for (let i = 0; i < n; i++) { const r = give(); if (!first) first = r; seqs.push(r[2]); }
  return { costG, costS, type: first[0], ninja: first[1], n, seq: seqs.join('|'), attrs: seqs.map(() => 0).join('|') };
}

// Card level-up: eat material cards (75 exp each), cost 2 silver per exp. Level thresholds = ninjaupgrade col 2.
function strengthen(db, pl, srcSeq, eatSeqs) {
  const src = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(srcSeq, pl.uid, pl.server_id);
  if (!src) return { error: 'card not found' };
  const eat = eatSeqs.filter((q) => q !== srcSeq && !inLineup(db, q))
    .map((q) => db.prepare('SELECT seq, type, level FROM cards WHERE seq=? AND uid=? AND server_id=?').get(q, pl.uid, pl.server_id)).filter(Boolean);
  // ORIGINAL (the client's CPlayerNinja/CPlayerWeapon/...::firefly_ExpCost and GetNeedSilver): every eaten card gives [3] EXP and costs
  // [4] silver from its OWN kind's upgrade table at its level (ninjaupgrade, equipupgrade, markupgrade, ninjutsuupgrade); the card that
  // grows needs [2] EXP per level from its own kind's table. Was a flat 75 EXP / 150 silver a card and the ninja table for every kind.
  // (ours): the ninja EXP-card bonus multiplier the client has for special cards is not applied.
  const up = (type) => table(type === 1 ? 'ninjaupgrade' : type === 5 ? 'markupgrade' : type === 6 ? 'ninjutsuupgrade' : 'equipupgrade').rows;
  let exp = 0, cost = 0;
  for (const e of eat) { const r = up(e.type).find((x) => x[1] === (e.level || 1)) || []; exp += r[3] || 0; cost += r[4] || 0; }
  if (pl.coin < cost) return { error: 'not enough silver' };
  const rows = up(src.type);
  let level = src.level, cur = src.exp + exp;
  for (;;) { const r = rows.find((x) => x[1] === level); if (!r || level >= Math.min(pl.level * 2 + 10, 99) || cur < r[2]) break; cur -= r[2]; level++; }
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE cards SET level=?, exp=? WHERE seq=?').run(level, cur, srcSeq);
  for (const e of eat) db.prepare('DELETE FROM cards WHERE seq=?').run(e.seq);
  bumpTask(db, pl.uid, pl.server_id, 20);
  return { exp, cost };
}

// ---- Element change (ui_attributeDanLayer: rl_w_newlife Cmd 5 ReadyCard = price, Cmd 6 = change) ---------------------------------
// ORIGINAL (Facebook photos 1425, 1494): a 5-star God card costs 12 Element Change Pills (item 33) + 2000 silver, the new element is random,
// "Higher quality needs more pills". (ours): 3 pills a star below that (3-star 6, 4-star 9, 5-star 10), 2000 silver for every card.
const ELEMENT_COIN = 2000;
const elementPills = (c) => { const s = (ninjas().get(c.ninja_id) || [])[11] || 3; return s >= 6 ? 12 : s >= 5 ? 10 : s >= 4 ? 9 : 6; };
function elementPrice(db, pl, seq) {
  const c = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(seq, pl.uid, pl.server_id);
  return c ? { coin: ELEMENT_COIN, pills: elementPills(c), card: c } : null;
}
function elementChange(db, pl, seq) {
  const p = elementPrice(db, pl, seq);
  if (!p) return { error: 'choose a shinobi card' };
  if (pl.coin < p.coin) return { error: 'not enough silver' };
  if ((propCounts(db, pl.uid, pl.server_id)[33] || 0) < p.pills) return { error: 'not enough Element Change Pills' };
  const now = p.card.attri || 1, choices = [1, 2, 3, 4, 5].filter((x) => x !== now);
  const next = choices[Math.floor(Math.random() * choices.length)];
  propAdd(db, pl.uid, pl.server_id, 33, -p.pills);
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(p.coin, pl.uid, pl.server_id);
  db.prepare('UPDATE cards SET attri=? WHERE seq=?').run(next, seq);
  return { attri: next };
}

// ---- Reincarnation / equipment advance (rl_w_newlife Cmd 7): ReadyCard gains +1 grade, EatCard (same item id) is consumed.
const NEWLIFE_MAX = (type) => (type === 1 ? 8 : table('equipnewlifeprop').rows.length); // shinobi: 8 (v28 draws rebirth outlines 1-8 only, GetTopInlayFrame; the card lists 8 bonuses)
// equipment advance: ORIGINAL (Facebook photos 0683, 0684, 0751, 0752) 50 000 silver, at most 3 times ("Available of reinforce three times")
const NEWLIFE_COST = () => 50000;
function newlife(db, pl, readySeq, eatSeq, grade) {
  ensure(db);
  const a = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(readySeq, pl.uid, pl.server_id);
  const b = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(eatSeq, pl.uid, pl.server_id);
  if (!a) return { error: 'cards missing' };
  // The material is either another copy of the same card (consumed) or a reincarnation pill (free on this server).
  if (b) {
    if (a.seq === b.seq || a.type !== b.type || a.ninja_id !== b.ninja_id) return { error: 'cards must match' };
    if (inLineup(db, b.seq)) return { error: 'material card is in use' };
  }
  if ((a.newlife || 0) >= NEWLIFE_MAX(a.type)) return { error: 'already at the highest rebirth' };
  const next = (a.newlife || 0) + 1;
  // The original cost (the screen): ONE copy of the same card, OR newlifeconfig[grade][star] reincarnation pills (prop 11). No silver.
  const star = (ninjas().get(a.ninja_id) || [])[11] || 5;
  const pills = (table('newlifeconfig').rows.find((r) => r[2] === next && r[3] === star) || [])[4] || 0;
  if (!b && (propCounts(db, pl.uid, pl.server_id)[11] || 0) < pills) return { error: 'not enough reincarnation pills' };
  const cost = a.type === 1 ? 0 : NEWLIFE_COST(); // shinobi reincarnation takes no silver; equipment advance does
  if (pl.coin < cost) return { error: 'not enough silver' };
  if (cost) db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE cards SET newlife=?, level=1, exp=0 WHERE seq=?').run(next, a.seq);
  if (b) db.prepare('DELETE FROM cards WHERE seq=?').run(b.seq);
  else propAdd(db, pl.uid, pl.server_id, 11, -pills);
  const gain = Math.round(((ninjaStats({ ...a, newlife: next }).ah) - ninjaStats(a).ah) / 2) || 0;
  bumpTask(db, pl.uid, pl.server_id, 21); // daily task: reincarnation
  return { grade: next, cost, gain };
}

// ---- Potential training ("Train" screen, rl_x_develop): roll gains, then save them. Free here (no pills needed).
// Shinobi training cost, ORIGINAL (Facebook photos 1835, 1839, 1840, 1347): "foster once" = 2 Super Ninja Pills, or "gold advance" =
// 1 pill + 10 gold; five at once = 10 pills, or 5 pills + 40 gold. The 10-times rows scale that (ours): 20 pills, or 10 pills + 80 gold.
const NINJA_PILL = 28;
const POT_COST = [{ id: 1, name: '1 time', type: 1, pills: 2, gold: 0 }, { id: 2, name: '1 time', type: 2, pills: 1, gold: 10 },
  { id: 3, name: '10 times', type: 1, pills: 20, gold: 0 }, { id: 4, name: '10 times', type: 2, pills: 10, gold: 80 }];
const potLimit = (c) => 100 + 40 * (c.starlevel || 0) + 10 * (c.level || 1) + 100 * (c.newlife || 0);
function potentialXml(db, pl, seq) {
  const c = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(seq, pl.uid, pl.server_id);
  if (!c) return null;
  const lim = potLimit(c);
  return `<attack limit_att="${lim}" add_att="${c.pot_att}"/><defense limit_def="${lim}" add_def="${c.pot_def}"/><chakra limit_ckr="${lim}" add_ckr="${c.pot_ckr}"/>` +
    // CPotentialView keeps these rows in one list: even index = pill row, odd = gold row; the dropdown (onClickMode) jumps 2 rows, so it
    // needs the "10 times" pair too (with only 2 rows it read past the list and crashed).
    '<cost_list>' + POT_COST.map((k) => `<cost cost_id="${k.id}" name="${k.name}" type="${k.type}" need_miyao="${k.pills}" need_golden="${k.gold}"/>`).join('') + '</cost_list>';
}
function potentialRoll(db, pl, seq, costId) {
  const c = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(seq, pl.uid, pl.server_id);
  if (!c) return { error: 'no such card' };
  const gold = costId % 2 === 0, times = costId > 2 ? 10 : 1;
  const k = POT_COST.find((x) => x.id === costId) || POT_COST[0];
  if ((propCounts(db, pl.uid, pl.server_id)[NINJA_PILL] || 0) < k.pills) return { error: 'not enough Super Ninja Pills' };
  if (pl.gold < k.gold) return { error: 'not enough gold' };
  propAdd(db, pl.uid, pl.server_id, NINJA_PILL, -k.pills);
  if (k.gold) db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(k.gold, pl.uid, pl.server_id);
  bumpTask(db, pl.uid, pl.server_id, 12, times); // daily task: training shinobi
  const lim = potLimit(c), hi = gold ? 14 : 8, lo = gold ? 3 : -2;
  const roll = () => { let s = 0; for (let i = 0; i < times; i++) s += Math.floor(Math.random() * (hi - lo + 1)) + lo; return s; };
  const d = { att: roll(), def: roll(), ckr: roll() };
  // never push a stat outside 0..limit
  d.att = Math.max(-c.pot_att, Math.min(lim - c.pot_att, d.att)); d.def = Math.max(-c.pot_def, Math.min(lim - c.pot_def, d.def)); d.ckr = Math.max(-c.pot_ckr, Math.min(lim - c.pot_ckr, d.ckr));
  db.prepare('UPDATE cards SET pend_att=?, pend_def=?, pend_ckr=? WHERE seq=?').run(d.att, d.def, d.ckr, seq);
  return { ...d, pills: k.pills, gold: k.gold };
}
function potentialSave(db, pl, seq) {
  const c = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=?').get(seq, pl.uid, pl.server_id);
  if (!c) return false;
  db.prepare('UPDATE cards SET pot_att=pot_att+pend_att, pot_def=pot_def+pend_def, pot_ckr=pot_ckr+pend_ckr, pend_att=0, pend_def=0, pend_ckr=0 WHERE seq=?').run(seq);
  return true;
}

// ---- Succession (inherit) -------------------------------------------------------------------
// ui_ninjaInheritLayer (Backpack card > Succession). ORIGINAL rule (the screen's own text, photo 2016): "Succession card level,
// reincarnation, and growth points will be completely transferred to the inheritance card"; only cards of the same quality; "after
// succession is complete, succession card will become a level 0 foundation card". Price = cost_cash + trained attack + trained defense
// (ORIGINAL: the client's own sum, "gold + training values"). cost_cash (ours) = 50 x (level - 1): fits the only photo (4440: level 50,
// growth 9, 1 rebirth, training 0/0 -> 2450 gold).
const inheritBase = (c) => 50 * Math.max(0, (c.level || 1) - 1);
const inheritCost = (c) => inheritBase(c) + (c.pot_att || 0) + (c.pot_def || 0);
function inheritInfoXml(c) {
  return `<basic>${el('cost_cash', c ? inheritBase(c) : 0)}${el('level', c ? c.level : 1)}${el('star', c ? c.starlevel || 0 : 0)}${el('newlife', c ? c.newlife || 0 : 0)}${el('add_attack', c ? c.pot_att || 0 : 0)}${el('add_defense', c ? c.pot_def || 0 : 0)}</basic>`;
}
function inheritCardAward(c) {
  return `<award dropid="1" coin="0"><cardlist><card>${el('id', c.ninja_id)}${el('type', 1)}${el('num', 1)}${el('attri', c.attri || 1)}${el('bagIndex', c.seq)}${el('level', c.level)}${el('newlife', c.newlife || 0)}${el('starlevel', c.starlevel || 0)}</card></cardlist><proplist></proplist><chipbag></chipbag><coin>0</coin><cash>0</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>`;
}
function inherit(db, pl, srcSeq, dstSeq) {
  const get = (s) => db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(s, pl.uid, pl.server_id);
  const a = get(srcSeq), b = get(dstSeq);
  if (!a || !b || a.seq === b.seq) return { error: 'choose two cards' };
  const qa = (ninjas().get(a.ninja_id) || [])[11], qb = (ninjas().get(b.ninja_id) || [])[11];
  if (qa !== qb) return { error: 'the cards must have the same quality' };
  const cost = inheritCost(a);
  if (pl.gold < cost) return { code: 329018 };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE cards SET level=?, exp=?, starlevel=?, newlife=?, pot_att=?, pot_def=?, pot_ckr=? WHERE seq=?')
    .run(a.level, a.exp, a.starlevel, a.newlife, a.pot_att, a.pot_def, a.pot_ckr, b.seq);
  db.prepare('UPDATE cards SET level=1, exp=0, starlevel=0, newlife=0, pot_att=0, pot_def=0, pot_ckr=0, pend_att=0, pend_def=0, pend_ckr=0 WHERE seq=?').run(a.seq);
  const na = get(a.seq), nb = get(b.seq);
  return { xml: inheritInfoXml(na) + `<src_card>${inheritCardAward(na)}</src_card><dst_card>${inheritCardAward(nb)}</dst_card>` };
}

// ---- Secret (soul) shop ----------------------------------------------------------------------
const SOUL = 9999; // props id used for ninja souls
function soulOf(db, pl) {
  const c = propCounts(db, pl.uid, pl.server_id);
  // Owner, 2 Nov 2026: no starter souls (we gave 30 000; no photo shows any). Souls come from Soul Disenchant; players who already got them keep them.
  return c[SOUL] || 0;
}
// Mystery shop (secret_shop rows: [id, id, name, type, subtype, itemid, num, costtype, cost, weight, dropid]): 6 rows picked by weight
// from everything the original sold - ninjas, ninja fragments, pet fragments, grain, nostrum, sage stones, reincarnation pills.
// Rules from the Facebook photos of the original (FINDINGS.md): the goods change by themselves every 2 h (countdown 1:58:xx); Refresh
// costs a Refresh Order (prop 31) or 20 gold; refreshes a day = 75 + 5 x VIP ("Number of refresh today 61/95, VIP4 +5"). Each row can
// be bought once per board.
const SECRET_EVERY = 2 * 3600, SECRET_GOLD = 20, REFRESH_ORDER = 31;
const secretSlot = () => Math.floor(Date.now() / 1000 / SECRET_EVERY);
function secretState(db, pl) {
  db.exec('CREATE TABLE IF NOT EXISTS secret_state (uid INTEGER, server_id INTEGER, day TEXT, used INTEGER, seed INTEGER, PRIMARY KEY(uid, server_id))');
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  const r = db.prepare('SELECT * FROM secret_state WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { day: today, used: 0, seed: 0 };
  if (r.day !== today) { r.day = today; r.used = 0; }
  return r;
}
function secretPicks(db, pl) {
  // rows 233-241 are untranslated duplicates from the Chinese server
  const rows = table('secret_shop').rows.filter((r) => r[9] > 0 && r[10] > 0 && /^[ -~]*$/.test(r[2]));
  const picks = [];
  let seed = (pl.uid * 31 + secretSlot() * 7919 + secretState(db, pl).seed * 104729) >>> 0;
  const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296;
  const total = rows.reduce((a, r) => a + r[9], 0);
  for (let guard = 0; picks.length < 6 && guard < 500; guard++) {
    let x = rnd() * total;
    const r = rows.find((q) => (x -= q[9]) < 0) || rows[rows.length - 1];
    if (!picks.includes(r)) picks.push(r);
  }
  return picks;
}
const secretBoard = (db, pl) => secretSlot() * 1000 + secretState(db, pl).seed % 1000; // bought rows are kept per board
function secretBought(db, pl) {
  db.exec('CREATE TABLE IF NOT EXISTS secret_bought (uid INTEGER, server_id INTEGER, day INTEGER, row INTEGER, PRIMARY KEY(uid, server_id, day, row))');
  return new Set(db.prepare('SELECT row FROM secret_bought WHERE uid=? AND server_id=? AND day=?').all(pl.uid, pl.server_id, secretBoard(db, pl)).map((r) => r.row));
}
function secretXml(db, pl) {
  const soul = soulOf(db, pl), bought = secretBought(db, pl), st = secretState(db, pl);
  const total = vipRow(db, pl)[22] || 80; // shown refreshes a day, same as secretRefresh
  const esc = (t) => String(t).replace(/[<>&]/g, '');
  const cards = secretPicks(db, pl).map((r) => `<item><card>${el('id', r[0])}${el('type', r[3])}${el('subtype', r[4])}${el('name', esc(r[2]))}${el('icon', r[5])}${el('num', r[6])}${el('cost', r[8])}${el('costtype', r[7])}${el('status', bought.has(r[0]) ? 1 : 0)}${el('itemid', r[5])}${el('attacktype', 0)}</card></item>`).join('');
  const left = SECRET_EVERY - (Math.floor(Date.now() / 1000) % SECRET_EVERY);
  return `<user>${el('cursoul', soul)}${el('updatenum', propCounts(db, pl.uid, pl.server_id)[REFRESH_ORDER] || 0)}${el('gold', pl.gold)}${el('refreshcost', SECRET_GOLD)}${el('totalrefresh', total)}${el('dayrefreshleft', Math.max(0, total - st.used))}${el('lefttime', left)}</user><cardlist>${cards}</cardlist>`;
}
// Refresh button: a Refresh Order if the player has one, else 20 gold. Code 325006 = the client's "only N refreshes a day" tip.
function secretRefresh(db, pl) {
  const st = secretState(db, pl), total = vipRow(db, pl)[22] || 80; // ORIGINAL vipinfo [22] "refresh the mystery shop 80 times daily" at VIP0, +5 a level
  if (st.used >= total) return { code: 325006 };
  if ((propCounts(db, pl.uid, pl.server_id)[REFRESH_ORDER] || 0) > 0) propAdd(db, pl.uid, pl.server_id, REFRESH_ORDER, -1);
  else if (pl.gold < SECRET_GOLD) return { error: 'not enough gold' };
  else db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(SECRET_GOLD, pl.uid, pl.server_id);
  db.prepare('INSERT OR REPLACE INTO secret_state VALUES (?,?,?,?,?)').run(pl.uid, pl.server_id, st.day, st.used + 1, (st.seed || 0) + 1);
  pl.gold = db.prepare('SELECT gold FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id).gold;
  return { xml: secretXml(db, pl) };
}
function secretBuy(db, pl, rowId) {
  const r = secretPicks(db, pl).find((x) => x[0] === rowId);
  if (!r) return { error: 'not in shop' };
  if (secretBought(db, pl).has(r[0])) return { error: 'already bought' };
  if (r[7] === 1) { if (soulOf(db, pl) < r[8]) return { error: 'not enough souls' }; propAdd(db, pl.uid, pl.server_id, SOUL, -r[8]); }
  else { if (pl.gold < r[8]) return { error: 'not enough gold' }; db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(r[8], pl.uid, pl.server_id); }
  db.prepare('INSERT INTO secret_bought VALUES(?,?,?,?)').run(pl.uid, pl.server_id, secretBoard(db, pl), r[0]);
  return { xml: grantDrop(db, pl, r[10]) };
}

// ---- Stats: ninja level growth + gear + set bonuses ------------------------------------------
// ninjainfo cols 19-24 = base atk lo/hi, def lo/hi, chakra lo/hi; 25-30 = growth per level. equipmentinfo: 7-12 base, 13-18 growth.
const KEYS = ['al', 'ah', 'dl', 'dh', 'cl', 'ch'];
// A shinobi card's own stats, exactly as the game draws them on its detail screen (CPlayerNinja::firefly_GetAttackMin and
// CNinjaDetailView::InitUI in libgame.so, checked digit for digit against the screen):
//   base  = (1 + basis) * level-1 stat + (1 + grow) * per-level stat * (level - 1)   (basis/grow: newlifeprop row of the rebirth grade, 0 without rebirth)
//   bonus = (min + max) / 2 * ninjastrengthconfig[growth level]   added to min and max (the "+" on the detail screen), then + training points.
// God breakthrough: +4% per level on the stats of the card's element (ui_tupo_desc): fire ATK+chakra, water chakra, wind DEF+chakra,
// earth DEF, thunder ATK; element = cards.attri (1 water, 2 fire, 3 wind, 4 earth, 5 thunder; 0 shows as water).
function ninjaStats(card) {
  const n = ninjas().get(card.ninja_id);
  const o = {};
  if (!n) { KEYS.forEach((k) => { o[k] = 0; }); return o; }
  const nl = (card.newlife || 0) > 0 ? table('newlifeprop').rows.find((r) => r[3] === card.newlife) : null;
  const basis = nl ? nl[4] : 0, grow = nl ? nl[5] : 0;
  const lvl = Math.max(1, card.level || 1);
  const BREAK = { 1: 'c', 2: 'ac', 3: 'dc', 4: 'd', 5: 'a' }[card.attri || 1] || 'c';
  const bk = (k) => (BREAK.includes(k[0]) ? 0.04 * (card.breaklvl || 0) : 0);
  KEYS.forEach((k, i) => { o[k] = Math.floor(((1 + basis) * (n[19 + i] || 0) + (1 + grow) * (n[25 + i] || 0) * (lvl - 1)) * (1 + bk(k))); });
  const add = (table('ninjastrengthconfig').rows.find((r) => r[1] === (card.starlevel || 0)) || [])[2] || 0;
  const pot = { a: card.pot_att || 0, d: card.pot_def || 0, c: card.pot_ckr || 0 };
  for (const s of ['a', 'd', 'c']) {
    const lo = s + 'l', hi = s + 'h';
    const bonus = Math.trunc(Math.fround(Math.fround(o[lo] + o[hi]) * Math.fround(add)) * 0.5) + pot[s];
    o[lo] += bonus; o[hi] += bonus;
  }
  return o;
}
function equipStats(card) {
  const e = equipRows().find((r) => r[0] === card.ninja_id);
  const o = {};
  const row = table('equipnewlifeprop').rows.find((r) => r[3] === (card.newlife || 0));
  const mult = 1 + (row ? row[4] : 0); // reincarnation grade grows the whole stat block
  KEYS.forEach((k, i) => { o[k] = e ? Math.floor(((e[7 + i] || 0) + (e[13 + i] || 0) * (card.level - 1)) * mult) : 0; }); // CPlayerWeapon::firefly_GetAttackMin: (1+basis)*base + (1+grow)*per-level*(level-1), basis = grow, rounded down
  return o;
}
const addStats = (a, b) => { const o = {}; KEYS.forEach((k) => { o[k] = (a[k] || 0) + (b[k] || 0); }); return o; };
// Set bonuses: type 1 = N cards of >= X stars, type 2 = N cards of level >= X (counted over all owned ninja cards).
function activeSuits(db, uid, sid) {
  // type 1 = N cards with at least X stars (a god card counts as 6 stars, so also for 4 and 5); type 2 = N cards with Sage GROWTH level >= X
  // ("Six-/Nine-/Twelve-Level Cards" = growth 6/9/12, cards.starlevel). Per type the set with the biggest bonus wins (21 five-star beats 21 four-star;
  // rows 49-56 repeat 41-48 with Chinese names, so on a tie the lower id).
  const cards = db.prepare('SELECT ninja_id, level, starlevel FROM cards WHERE uid=? AND server_id=? AND type=1').all(uid, sid);
  const best = {};
  for (const r of table('suit_info').rows) {
    const [, , type, need, count] = r;
    const have = cards.filter((c) => (type === 1 ? ((ninjas().get(c.ninja_id) || [])[11] || 0) >= need : (c.starlevel || 0) >= need)).length;
    const b = best[type];
    if (have >= count && (!b || r[5] > b[5] || (r[5] === b[5] && r[6] > b[6]))) best[type] = r;
  }
  return Object.values(best);
}
// Seal (markinfo col 7, e.g. "ATK +35%"): multiplies that stat of the ninja wearing it.
// The text can name several stats: "DEF and ATK +40%", "DEF ATK +60% and skill +3%", "DEF ATK Cha +80% ..." -> every named stat gets the %
// (only the stat right before the number got it until 3 Nov 2026, Discord report). "skill +3%" counts like a ninjutsu's chance (x 20 % attack, ours).
function sealBonus(st, markId) {
  const m = table('markinfo').rows.find((r) => r[0] === markId);
  const mm = m && /^([A-Za-z ]*?)\s*\+(\d+)%/.exec(String(m[7]).trim());
  if (!mm) return st;
  const pct = Number(mm[2]) / 100, keys = [];
  if (/\bATK\b/i.test(mm[1])) keys.push('al', 'ah');
  if (/\bDEF\b/i.test(mm[1])) keys.push('dl', 'dh');
  if (/\bCHA/i.test(mm[1])) keys.push('cl', 'ch');
  const o = { ...st };
  for (const k of keys) o[k] = Math.round(o[k] * (1 + pct));
  const skill = /skill\s*\+(\d+)%/i.exec(String(m[7]));
  if (skill) { const c = Number(skill[1]) / 100 * 0.2; o.al = Math.round(o.al * (1 + c)); o.ah = Math.round(o.ah * (1 + c)); }
  return o;
}
let matchIndex = null;
function matchRows(ninjaId) {
  if (!matchIndex) { matchIndex = new Map(); for (const r of table('ninjamatch').rows) { if (!matchIndex.has(r[3])) matchIndex.set(r[3], []); matchIndex.get(r[3]).push(r); } }
  return matchIndex.get(ninjaId) || [];
}
// ---- chain text helpers (also used by the admin team builder) ----
const words = (s) => String(s).toLowerCase().replace(/[（(][^)）]*[)）]/g, ' ').split(/[^a-z]+/).filter((w) => w && !['of', 'the', 'and'].includes(w)).map((w) => (w.length > 3 ? w.replace(/s$/, '') : w));
const cardWords = (id) => new Set(words((ninjas().get(id) || [])[2] || ''));
const ALIAS = [[/raikagand/gi, 'Raikage and'], [/itachiand/gi, 'Itachi and'], [/fukasakun/gi, 'Fukasaku'], [/\bforth\b/gi, 'Fourth'], [/sasu sasuke/gi, 'Susa Sasuke'],
  [/\bkyubi\b/gi, 'Kurama'], [/eight tails/gi, 'Gyūki'], [/mei tsunade onoki/gi, 'Mei, Tsunade, Onoki'], [/fourth sage minato/gi, 'Fourth Sage, Minato']];
const chainParts = new Map(); // row id -> { any, parts: [[words]...] } | null
const partsOf = (r) => {
  if (chainParts.has(r[0])) return chainParts.get(r[0]);
  const m = /fight\s+(?:together\s+)?(?:with\s+)?(.+?)(?:\s*\+|\s+to\s+raise)/i.exec(String(r[4] || '')); // "Fight with X +", "Fight X +", "Fight together with X to raise"
  let v = null;
  if (m) {
    let t = m[1];
    for (const [re, to] of ALIAS) t = t.replace(re, to);
    const any = /\bor\b/i.test(t);
    const parts = t.split(/[,，]|\band\b|\bor\b/i).map(words).filter((w) => w.length);
    v = parts.length ? { any, parts } : null;
  }
  chainParts.set(r[0], v);
  return v;
};
const allCards = () => [...ninjas().values()].filter((n) => n[4] === 1 && n[19] > 0).map((n) => n[0]);
const fits = (part, id) => { const c = cardWords(id); return part.every((w) => c.has(w)); };
const knownPart = new Map(); // part text -> does any card have that name
const isKnown = (part) => { const k = part.join(' '); if (!knownPart.has(k)) knownPart.set(k, allCards().some((id) => fits(part, id))); return knownPart.get(k); };

// Gear and ninjutsu sets, ORIGINAL table skill_suit_info (the game's "Equip 2 / 3 / 4 pieces" set screen, EquipSuitSubView): type 2 = gear
// (weapon, armour, trinket, seal ids in [4]-[7]), type 1 = ninjutsu (4 ninjutsu ids). [8]-[25] = attack, defense, chakra, each for 2 / 3 / 4
// pieces as (flat, share) pairs; [26]-[28] = "Chance of skill +%" for 2 / 3 / 4 pieces (the set screen shows exactly these). Gear sets add
// their stats to the ninja. Ninjutsu sets: the game adds their values only when a ninjutsu fires in battle; fights here use expected values,
// so a ninjutsu set adds its skill chance the way an equipped ninjutsu does (chance x 20 % attack, ours). Not applied before 2 Nov 2026.
function skillSets(equipped) {
  const out = [];
  for (const row of table('skill_suit_info').rows) {
    // gear sets list weapon, armour, trinket, seal in that order: each id only counts as its own kind (seal 10 is not weapon 10)
    const want = row.slice(4, 8);
    const has = (id, i) => equipped.some((e) => e.ninja_id === id && e.type === (row[3] === 1 ? 6 : 2 + i));
    const num = want.filter(has).length;
    if (num >= 2) out.push({ row, num });
  }
  return out;
}
// The tiers ADD UP, like the original set screen: with 3 pieces it lights the 2- and 3-piece lines, with 4 pieces all three
// (CEquipDetailView: num 4 -> setEquipSuitActiveStateNum_2, _3 and _4 in the active colour). Until 3 Nov 2026 only the highest line
// counted, so for sets like Armed (+15 % on every line) 4 pieces gave no more than 2 (Discord report).
function setBonus(st, sets) {
  const o = { ...st };
  for (const { row, num } of sets) {
    const tiers = [...Array(num - 1).keys()]; // 2 pieces -> [0], 3 -> [0, 1], 4 -> [0, 1, 2]
    const part = (stat) => tiers.reduce(([f, s], t) => [f + (Number(row[8 + stat * 6 + t * 2]) || 0), s + (Number(row[9 + stat * 6 + t * 2]) || 0)], [0, 0]); // [flat, share]
    if (row[3] === 2) [['al', 'ah', 0], ['dl', 'dh', 1], ['cl', 'ch', 2]].forEach(([lo, hi, stat]) => {
      const [flat, share] = part(stat);
      o[lo] = Math.round((o[lo] || 0) * (1 + share) + flat); o[hi] = Math.round((o[hi] || 0) * (1 + share) + flat);
    });
    const chance = tiers.reduce((a, t) => a + (Number(row[26 + t]) || 0), 0) * 0.2;
    if (chance) { o.al = Math.round(o.al * (1 + chance)); o.ah = Math.round(o.ah * (1 + chance)); }
  }
  return o;
}
function teamStats(db, uid, sid, t = USED) {
  ensure(db);
  const team = db.prepare(`SELECT t.slot, c.* FROM ${t.team} t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot`).all(uid, sid);
  const eqRows = db.prepare(`SELECT e.slot, e.kind, c.* FROM ${t.equipped} e JOIN cards c ON c.seq=e.seq WHERE e.uid=? AND e.server_id=?`).all(uid, sid);
  const slots = team.map((c, i) => {
    let st = ninjaStats(c);
    const mine = eqRows.filter((x) => x.slot === i + 1);
    for (const e of mine) {
      if (e.type === 5) { st = sealBonus(st, e.ninja_id); continue; } // tailed-beast seal: percentage bonus
      if (e.type === 6) { st = ninjutsuBonus(st, e.ninja_id); continue; } // ninjutsu: chance of an extra hit
      st = addStats(st, equipStats(e));
    }
    const sets = skillSets(mine);
    st = setBonus(st, sets);
    return { seq: c.seq, ninja_id: c.ninja_id, level: c.level, ...st, sets: sets.map((x) => ({ id: x.row[0], num: x.num })) };
  });
  // Chains (ninjamatch.json; a card's "Chains" list on its detail screen): cols 3 ninja it belongs to, 5 type, 6-13 partner ninja ids, 14 equipment id,
  // 15 ninjutsu id, 16-18 attack/defence/chakra ratio. Type 1 = the card's own stats grow when ANY partner is in the team, or the equipment / ninjutsu is worn
  // by it; type 0 = a leader effect: while the card is in the team every ninja gets the ratio. Each chain adds ratio x the slot's stats (after gear).
  // Chain partners match by CHARACTER, not by card id: the table has 8 partner places and often lists only some variants
  // (Kaguya "Fight with Susa Kakashi" lists 5026 but not 5027 or Susa Kakashi (God) 5028; GitHub #5).
  const who = (id) => String((ninjas().get(id) || [])[2] || id).toLowerCase().replace(/\(god\)/g, '').replace(/[^a-z]/g, '');
  // The partner lists also miss whole variants (Six Paths Madara (God) "Fight with Six Paths Obito" lists only plain Obito; Hokage Naruto
  // "Fight with Madara" misses Six Paths Madara; GitHub #5), so the names written in the chain text count too: every word of a name must be in
  // the card's name ("Madara" = every Madara, "Six Paths Obito" = every Six Paths Obito, "Sage Six Path" = Sage of the Six Paths).
  // Chains with several partners: "X and Y" / "X, Y" need ALL of them in the team, "X or Y" needs one. A name that matches no card at all
  // (a typo in the table) falls back to the listed partner ids.
  // is the chain's partner condition met by these card ids (the card itself excluded by the caller)?
  const partnersIn = (r, ids, whoSet) => {
    const listed = r.slice(6, 14).filter((id) => id > 0);
    const listedHit = listed.some((id) => ids.has(id) || whoSet.has(who(id)));
    const p = partsOf(r);
    if (!p) return listedHit;
    const ok = (part) => (isKnown(part) ? [...ids].some((id) => fits(part, id)) : listedHit);
    if (p.parts.length === 1) return listedHit || ok(p.parts[0]);
    return p.any ? p.parts.some(ok) || listedHit : p.parts.every(ok);
  };
  const inTeam = new Set(slots.map((s) => s.ninja_id));
  const teamWho = slots.map((s) => who(s.ninja_id));
  const owned = new Set(db.prepare('SELECT DISTINCT ninja_id FROM cards WHERE uid=? AND server_id=? AND type=1').all(uid, sid).map((r) => r.ninja_id));
  const ownedWho = new Set([...owned].map((id) => String((ninjas().get(id) || [])[2] || id).toLowerCase().replace(/\(god\)/g, '').replace(/[^a-z]/g, '')));
  const chain = slots.map(() => ({}));
  const add = (i, r) => { const s = slots[i]; [['al', 'ah', 16], ['dl', 'dh', 17], ['cl', 'ch', 18]].forEach(([lo, hi, col]) => { if (r[col] > 0) { chain[i][lo] = (chain[i][lo] || 0) + Math.round(s[lo] * r[col]); chain[i][hi] = (chain[i][hi] || 0) + Math.round(s[hi] * r[col]); } }); };
  slots.forEach((s, i) => {
    const worn = eqRows.filter((x) => x.slot === i + 1).map((x) => x.ninja_id);
    s.active = []; s.ready = [];
    for (const r of matchRows(s.ninja_id)) {
      if (r[5] === 0) { slots.forEach((_, j) => add(j, r)); s.active.push(r[0]); continue; }
      const others = slots.filter((_, j) => j !== i).map((o) => o.ninja_id);
      const partner = partnersIn(r, new Set(others), new Set(others.map(who)));
      if (partner || (r[14] > 0 && worn.includes(r[14])) || (r[15] > 0 && worn.includes(r[15]))) { add(i, r); s.active.push(r[0]); }
      else if (partnersIn(r, new Set([...owned].filter((id) => id !== s.ninja_id)), ownedWho)) s.ready.push(r[0]); // the partners are owned but not all in the team yet
    }
  });
  slots.forEach((s, i) => { Object.assign(s, addStats(s, chain[i])); s.chain = chain[i]; });
  let tot = slots.reduce((a, s) => addStats(a, s), {});
  const suits = activeSuits(db, uid, sid);
  let bonus = {};
  for (const r of suits) {
    bonus = addStats(bonus, { al: r[5], ah: r[5], dl: r[7], dh: r[7], cl: r[9], ch: r[9] });
    const pct = { al: r[6], ah: r[6], dl: r[8], dh: r[8], cl: r[10], ch: r[10] };
    KEYS.forEach((k) => { bonus[k] += Math.round((tot[k] || 0) * pct[k]); });
  }
  tot = addStats(tot, bonus);
  const gb = gateBonus(gateLevel(db, uid, sid));
  if (gb.flat) { const g = {}; KEYS.forEach((k) => { g[k] = gb.flat + Math.round((tot[k] || 0) * gb.pct); }); tot = addStats(tot, g); }
  const medal = table('playemedal').rows.find((r) => r[0] === meritLevel(db, uid, sid));
  if (medal) tot = addStats(tot, { al: medal[3], ah: medal[4], dl: medal[5], dh: medal[6], cl: medal[7], ch: medal[8] });
  const pb = require('./pet').teamBonus(db, uid, sid); // master + helper pets (required here: pet.js requires this file)
  tot = addStats(tot, { al: pb.attack, ah: pb.attack, dl: pb.defense, dh: pb.defense, cl: pb.chakala, ch: pb.chakala });
  // Sets, Eight Gates, the W.A. title and pets are team-wide: in fights each ninja gets its share (in proportion to its own stats), so the fight
  // numbers add up to the team total shown on the Team screen.
  const sum = slots.reduce((t, s) => addStats(t, s), {});
  const fight = slots.map((s) => { const o = { ...s }; KEYS.forEach((k) => { o[k] = sum[k] ? Math.round((s[k] || 0) * (tot[k] || 0) / sum[k]) : s[k]; }); return o; });
  return { slots, fight, total: tot, suits, bonus };
}

// Sage growth (rl_w_star Cmd 1): spend sage stones on a card for a chance at +1 sage level (stored in cards.starlevel).
// Sage growth (CStrengthView, rl_w_star). The original chances are the game's own ninjastrength table:
// [id, id, level now, chance with 1/2/3/4 stones, chance to keep the level on a failure, lowest level a failure can drop to, silver].
// Rows 1-15 are for Sage Stone I (prop 7), rows 16-30 for Sage Stone III (prop 8). Max growth level 15.
// Extra stones (StarStoneExtID/Num) add stone_added_percent each, up to max_percent: both numbers lived on the dead server, so
// (ours) +1% per Sage Stone I, +2% per Sage Stone III, capped at what 4 Sage Stone III give at that level.
const GROW_MAX = 15;
const growRow = (lv, stoneId) => table('ninjastrength').rows.find((r) => r[2] === lv && (stoneId === 8 ? r[0] > 15 : r[0] <= 15));
const GROW_EXTRA = { 7: 1, 8: 2 };
const growMaxPercent = (lv) => (growRow(lv, 8) || [])[6] || 0;
function growStarList() {
  let items = '';
  for (let i = 0; i < GROW_MAX; i++) for (const s of [7, 8]) items += `<item star_now="${i}" max_percent="${growMaxPercent(i)}" stone_level="${s}" stone_added_percent="${GROW_EXTRA[s]}"/>`;
  return items;
}
function sageGrow(db, pl, seq, stoneId, stoneNum, extId = 0, extNum = 0) {
  const card = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(seq, pl.uid, pl.server_id);
  if (!card) return { error: 'card not found' };
  const lv0 = card.starlevel || 0;
  if (lv0 >= GROW_MAX) return { error: 'growth is at the maximum' };
  const row = growRow(lv0, stoneId);
  if (!row) return { error: 'bad stone' };
  stoneNum = Math.min(4, Math.max(1, stoneNum || 1));
  extNum = GROW_EXTRA[extId] ? Math.max(0, extNum || 0) : 0;
  const counts = propCounts(db, pl.uid, pl.server_id);
  const need = { [stoneId]: stoneNum };
  if (extNum) need[extId] = (need[extId] || 0) + extNum;
  for (const [id, n] of Object.entries(need)) if ((counts[id] || 0) < n) return { error: 'not enough stones' };
  const cost = row[9];
  if (pl.coin < cost) return { error: 'not enough silver' };
  for (const [id, n] of Object.entries(need)) propAdd(db, pl.uid, pl.server_id, Number(id), -n);
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  const base = row[2 + stoneNum];
  const chance = extNum ? Math.max(base, Math.min(growMaxPercent(lv0), base + extNum * GROW_EXTRA[extId])) : base;
  const win = Math.random() * 100 < chance;
  let lv = lv0, drop = 0;
  if (win) lv++;
  else if (lv > row[8] && Math.random() * 100 >= row[7]) { lv = Math.max(row[8], lv - 1); drop = 1; } // (ours) a failure drops one level
  db.prepare('UPDATE cards SET starlevel=? WHERE seq=?').run(lv, seq);
  bumpTask(db, pl.uid, pl.server_id, 5);
  const left = propCounts(db, pl.uid, pl.server_id);
  return { win, drop, lv, left: left[stoneId] || 0, extLeft: extNum ? left[extId] || 0 : 0, chance };
}

// Friends: on this offline server every other registered player is automatically your friend.
function friendsXml(db, pl, nick) {
  const real = nick
    ? db.prepare('SELECT * FROM players WHERE server_id=? AND uid!=? AND nick LIKE ? ORDER BY level DESC').all(pl.server_id, pl.uid, '%' + nick + '%')
    : db.prepare('SELECT * FROM players WHERE server_id=? AND uid!=? ORDER BY level DESC').all(pl.server_id, pl.uid);
  const f = (r) => {
    const t = teamStats(db, r.uid, r.server_id);
    const o = { id: r.uid, level: r.level, nick: String(r.nick).replace(/[<>&"]/g, ''), attacklow: t.total.al, attackhigh: t.total.ah, defenselow: t.total.dl, defenseHigh: t.total.dh,
      firstninja: firstNinja(db, r), country: r.country, firstninjastar: 5, newlife: 0 };
    return '<user>' + Object.entries(o).map(([k, v]) => el(k, v)).join('') + '</user>';
  };
  return '<userlist page="1">' + real.map(f).join('') + '</userlist>';
}

// ---- Eight Inner Gates (Dun) -----------------------------------------------------------------
// Eight Inner Gates. prop 9997 = points opened (8 points = one gate level; old saves keep their 0-8 points = level 1-2).
// ORIGINAL (Facebook photos, FINDINGS.md): the screen shows LV:N and the 8 gate points of that level; a point costs souls (prop 9998)
// + 15 x those souls in silver ("1018 souls + 15 270 silver" ... "7120 + 106 800"); levels seen up to 150. Fitted to the photos:
// souls a point = 80 x level (LV1 80, LV45 3600 vs 3514, LV53 4240 vs 4403, LV100 8000 vs 7120); team bonus after n points
// (x = n / 8 levels): flat = 340 x x^1.5 to attack, defence and chakra (LV10 10 750 vs 10 312, LV25 42 500 vs 41 939, LV100 340 000
// vs 334 236) and percent = 0.006 x^2 + 0.2 x (LV45 21% seen 21%, LV53 27.5% vs 28-31%, LV100 80% vs 81%). The client shows the
// percent in tenths (add_attack_per 210 = 21%).
const GATE_SOUL = 9998, GATE_MAX = 150 * 8;
function gateLevel(db, uid, sid) { return Math.min(GATE_MAX, propCounts(db, uid, sid)[9997] || 0); } // points opened
function gateBonus(n) { const x = n / 8; return { flat: Math.round(340 * x ** 1.5), pct: (0.006 * x * x + 0.2 * x) / 100 }; }
const gateCost = (n) => { const soul = 80 * (Math.floor(n / 8) + 1); return { soul, coin: 15 * soul }; };
function gateXml(db, pl) {
  const c = propCounts(db, pl.uid, pl.server_id);
  if (c[GATE_SOUL] === undefined) { propAdd(db, pl.uid, pl.server_id, GATE_SOUL, 5000); c[GATE_SOUL] = 5000; }
  const n = gateLevel(db, pl.uid, pl.server_id), b = gateBonus(n), nx = gateBonus(Math.min(GATE_MAX, n + 1)), cost = gateCost(n);
  const kinds = [1, 2, 3].map((t) => `<gate type="${t}" value="${nx.flat - b.flat}"/>`).join('');
  const per = Math.round(b.pct * 1000);
  return `<basic>${el('soul', c[GATE_SOUL])}${el('gate_level', Math.floor(n / 8) + 1)}${el('cost_soul', cost.soul)}${el('cost_coin', cost.coin)}<gate_id id="${(n % 8) + 1}">${kinds}</gate_id></basic>` +
    `<attribute>${el('add_attack', b.flat)}${el('add_defense', b.flat)}${el('add_chakala', b.flat)}${el('add_attack_per', per)}${el('add_defense_per', per)}${el('add_chakala_per', per)}</attribute>`;
}
function gateOpen(db, pl) {
  const n = gateLevel(db, pl.uid, pl.server_id);
  if (n >= GATE_MAX) return { error: 'all gates open' };
  const c = propCounts(db, pl.uid, pl.server_id), soul = c[GATE_SOUL] === undefined ? 5000 : c[GATE_SOUL], cost = gateCost(n);
  if (soul < cost.soul) return { error: 'not enough souls', code: 400006 };
  if (pl.coin < cost.coin) return { error: 'not enough silver' };
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(cost.coin, pl.uid, pl.server_id);
  propAdd(db, pl.uid, pl.server_id, GATE_SOUL, c[GATE_SOUL] === undefined ? 5000 - cost.soul : -cost.soul);
  propAdd(db, pl.uid, pl.server_id, 9997, 1);
  return {};
}

// ---- Arena (ranked ladder) --------------------------------------------------------------------
// Ladder = persistent order of "slots": real players (uid) and bots (ids 9100001+). Rank 1 is best. A win over a higher rank swaps places.
const ARENA_BOTS = 20;
function arenaEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS arena (rank INTEGER PRIMARY KEY, uid INTEGER NOT NULL UNIQUE)');
  if (!db.prepare('SELECT COUNT(*) n FROM arena').get().n) {
    const ins = db.prepare('INSERT INTO arena(rank,uid) VALUES(?,?)');
    for (let i = 1; i <= ARENA_BOTS; i++) ins.run(i, 9100000 + i);
  }
}
function arenaJoin(db, pl) {
  arenaEnsure(db);
  if (!db.prepare('SELECT 1 FROM arena WHERE uid=?').get(pl.uid)) {
    const n = db.prepare('SELECT COUNT(*) n FROM arena').get().n;
    db.prepare('INSERT INTO arena(rank,uid) VALUES(?,?)').run(n + 1, pl.uid);
  }
  return db.prepare('SELECT rank FROM arena WHERE uid=?').get(pl.uid).rank;
}
function arenaInfo(db, uid) {
  if (uid >= 9100001 && uid <= 9100000 + ARENA_BOTS) {
    const i = uid - 9100000, pool = Array.from(ninjas().values()).filter((r) => r[4] === 1 && r[11] >= 4);
    const n = pool[(i * 37) % pool.length];
    return { uid, nick: BOT_NAMES[i % BOT_NAMES.length] + ' ' + i, level: 20 + i * 3, ninja: n[0], star: n[11], country: 1 + (i % 3), power: 1500 - i * 60 };
  }
  const p = db.prepare('SELECT * FROM players WHERE uid=?').get(uid);
  if (!p) return null;
  const t = teamStats(db, p.uid, p.server_id);
  return { uid, nick: p.nick, level: p.level, ninja: firstNinja(db, p), star: 5, country: p.country, power: (t.total.al + t.total.ah) / 2 / Math.max(1, t.slots.length) };
}
// Arena daily rank reward, from the Facebook photos of the original (FINDINGS.md): rank 1 25 000 silver + 5000 reputation, -1000 / -200 a rank
// to rank 10 (16 000 + 3200), ranks 23-26 15 200 + 3040, ranks 1253-1953 2000 + 400; reputation is always silver / 5. Between rank 10 and
// the 2000 floor it drops 60 a rank (ours, fits rank 23-26).
const arenaCoin = (rank) => (rank <= 10 ? 26000 - rank * 1000 : Math.max(2000, 16000 - (rank - 10) * 60));
const arenaReward = (rank) => ({ coin: arenaCoin(rank), renown: arenaCoin(rank) / 5 });
// Arena rival's teammates next to the first ninja (CArenaListView::AddOpponentData: <teammate><mate><ninja/><firstninjastar/></mate>...):
// the same cards the fight shows (foeTeam), so a real player's team slots 2-4 and a bot's 2 picked partners (was empty = purple slots).
function teammateXml(db, uid, sid, first, withFirst, level) { // withFirst: the Rank tab fills ALL its slots from this list
  let ids;
  const p = db.prepare('SELECT server_id FROM players WHERE uid=?' + (sid ? ' AND server_id=?' : '')).get(...(sid ? [uid, sid] : [uid]));
  if (p) {
    sid = p.server_id;
    ids = db.prepare('SELECT c.ninja_id FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(uid, sid).map((r) => r.ninja_id).slice(withFirst ? 0 : 1);
  }
  if (!ids || !ids.length) ids = foeTeam(db, uid, sid, first, level).slice(withFirst ? 0 : 1);
  // both cell layouts have only node_icon1-4; Battle puts mate i in node_icon(i+2), so more than 3 mates (4 with the first) crash
  ids = ids.slice(0, withFirst ? 4 : 3);
  return '<teammate>' + ids.map((id) => `<mate>${el('ninja', id)}${el('firstninjastar', (ninjas().get(id) || [])[11] || 1)}</mate>`).join('') + '</teammate>';
}
// Daily rank reward state on the player's own row: rewardtimeleft > 0 shows a countdown, then dayrewardstat 0 = the claim button (with
// timeleft = time left to claim), 1 = "already claimed". Before 2 Nov 2026 we always sent a 1-hour countdown, so the button never showed.
// Claimable once a day, any time (ours: the original's claim window time is not known for sure).
const arenaToday = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
function arenaClaimed(db, pl) {
  db.exec('CREATE TABLE IF NOT EXISTS rank_claims (uid INTEGER, server_id INTEGER, board TEXT, key TEXT, PRIMARY KEY(uid,server_id,board,key))');
  return !!db.prepare("SELECT 1 FROM rank_claims WHERE uid=? AND server_id=? AND board='arena' AND key=?").get(pl.uid, pl.server_id, arenaToday());
}
const arenaClaimLeft = () => { const n = new Date(), m = new Date(n); m.setHours(24, 0, 0, 0); return Math.max(1, Math.round((m - n) / 1000)); };
function arenaListXml(db, pl) {
  const my = arenaJoin(db, pl), use = arenaUse(db, pl);
  const rows = db.prepare('SELECT rank, uid FROM arena ORDER BY rank').all();
  const idx = rows.findIndex((r) => r.uid === pl.uid);
  // the player's own row goes in the list too, marked <host>1 (COpponentCardView::initArena): it carries the daily reward button
  const targets = rows.slice(Math.max(0, idx - 6), idx + 4);
  const esc = (t) => String(t).replace(/[<>&"]/g, '');
  const opp = targets.map((r) => {
    const o = arenaInfo(db, r.uid), rw = arenaReward(r.rank);
    return `<user>${el('id', r.uid)}${el('rank', r.rank)}${el('nick', esc(o.nick))}${el('level', o.level)}${el('ninja', o.ninja)}${el('country', o.country)}${el('firstninjastar', o.star)}${el('newlife', 0)}${el('winexp', 20)}${el('wincoin', 300)}${el('rewardcoin', rw.coin)}${el('rewardrenown', rw.renown)}${el('failexp', 5)}${el('failcoin', 50)}${el('host', r.uid === pl.uid ? 1 : 0)}${teammateXml(db, r.uid, pl.server_id, o.ninja, false, o.level)}</user>`;
  }).join('');
  const renown = propCounts(db, pl.uid, pl.server_id)[9996] || 0;
  return `<sport><my>${el('rank', my)}${el('renown', renown)}${el('rewardtimeleft', 0)}${el('timeleft', arenaClaimLeft())}${el('dayrewardstat', arenaClaimed(db, pl) ? 1 : 0)}${el('todayresttime', arenaPerDay(db, pl) - use.fights)}${el('todayall', arenaPerDay(db, pl))}${el('resttime', use.rest)}${el('restbatter', ARENA.perBatch - use.batch)}${el('restpack', 0)}</my></sport><oppe>${opp}</oppe>`;
}
function arenaRankXml(db) {
  const rows = db.prepare('SELECT rank, uid FROM arena ORDER BY rank LIMIT 50').all();
  const items = rows.map((r) => { const o = arenaInfo(db, r.uid), rw = arenaReward(r.rank); return `<item>${el('nick', String(o.nick).replace(/[<>&"]/g, ''))}${el('rank', r.rank)}${el('level', o.level)}${el('host', 0)}${el('rewardcoin', rw.coin)}${el('rewardrenown', rw.renown)}${el('ninja', o.ninja)}${el('firstninjastar', o.star)}${teammateXml(db, r.uid, 0, o.ninja, true, o.level)}</item>`; }).join('');
  return `<sportrank>${items}</sportrank>`;
}
// Arena limits, ORIGINAL (the game's own normalconfig: row 18 a cooldown after 3 attacks, row 19 25 attacks a day, row 20 cooldown 600 s,
// row 22 clearing the cooldown costs 30 gold; player guide photo 3924 "3 hits and a cool down of 10 minutes"). VIP adds attacks: the arena screen
// says "VIP2 +1 times" and vipinfo [21] is 20 at VIP0, +1 a level, so a day = 25 + vipinfo[21] - 20. Buying extra attacks is not built.
const ARENA = { perBatch: 3, perDay: 25, cd: 600, cdCost: 30 };
const arenaPerDay = (db, pl) => ARENA.perDay + Math.max(0, (vipRow(db, pl)[21] || 20) - 20);
function arenaUse(db, pl) {
  db.exec('CREATE TABLE IF NOT EXISTS arena_use (uid INTEGER, server_id INTEGER, day TEXT, fights INTEGER DEFAULT 0, batch INTEGER DEFAULT 0, cd_until INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id, day))');
  db.prepare('INSERT OR IGNORE INTO arena_use(uid, server_id, day) VALUES(?,?,?)').run(pl.uid, pl.server_id, today());
  const u = db.prepare('SELECT * FROM arena_use WHERE uid=? AND server_id=? AND day=?').get(pl.uid, pl.server_id, today());
  return { ...u, rest: Math.max(0, u.cd_until - Math.floor(Date.now() / 1000)) };
}
function arenaClearCd(db, pl) {
  const u = arenaUse(db, pl);
  if (!u.rest) return {};
  if (pl.gold < ARENA.cdCost) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(ARENA.cdCost, pl.uid, pl.server_id);
  db.prepare('UPDATE arena_use SET cd_until=0 WHERE uid=? AND server_id=? AND day=?').run(pl.uid, pl.server_id, today());
  return {};
}
function arenaFight(db, pl, toRank) {
  const use = arenaUse(db, pl);
  if (use.fights >= arenaPerDay(db, pl)) return { error: 'no arena challenges left today' };
  if (use.rest) return { error: 'the arena is cooling down' };
  db.prepare('UPDATE arena_use SET fights=fights+1, batch=?, cd_until=? WHERE uid=? AND server_id=? AND day=?')
    .run((use.batch + 1) % ARENA.perBatch, use.batch + 1 >= ARENA.perBatch ? Math.floor(Date.now() / 1000) + ARENA.cd : 0, pl.uid, pl.server_id, today());
  const my = arenaJoin(db, pl);
  const t = db.prepare('SELECT * FROM arena WHERE rank=?').get(toRank);
  if (!t || t.uid === pl.uid) return { error: 'bad target' };
  const o = arenaInfo(db, t.uid);
  const ts = teamStats(db, pl.uid, pl.server_id);
  const mine = (ts.total.al + ts.total.ah) / 2 / Math.max(1, ts.slots.length);
  const win = mine * (0.75 + Math.random() * 0.5) >= o.power;
  const xml = battleXml(db, pl, 0, 1, { enemyIds: foeTeam(db, o.uid, pl.server_id, o.ninja, o.level, 0, ts.slots.length), ratio: o.power / Math.max(1, mine), win, enemyName: o.nick, enemyUid: o.uid, enemyLevel: o.level, enemyCountry: o.country });
  let from = my, to = my, renown = 0;
  if (win) {
    if (toRank < my) { db.prepare('UPDATE arena SET uid=-1 WHERE rank=?').run(my); db.prepare('UPDATE arena SET uid=? WHERE rank=?').run(my === 0 ? 0 : pl.uid, toRank); db.prepare('UPDATE arena SET uid=? WHERE rank=?').run(t.uid, my); to = toRank; }
    renown = arenaReward(to).renown;
    propAdd(db, pl.uid, pl.server_id, 9996, renown);
    db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(300, pl.uid, pl.server_id);
  }
  bumpTask(db, pl.uid, pl.server_id, 4);
  return { win, xml, from, to, renown };
}

// Grudge (SP, the spar stamina shown "10/3" in the top bar): max = playerlevel column 3, one point back every 2 hours (the client's own
// timer shows "next grudge 01:59:55" at pass time 0; ORIGINAL normalconfig 10 "seconds to recover one spar point" = 7200), a spar costs 1.
// players.sp = -1 means full.
const SP_EVERY = 2 * 3600;
function spState(db, pl) {
  ensure(db);
  const row = table('playerlevel').rows.find((r) => r[1] === pl.level) || [];
  const max = row[3] || 3, now = Math.floor(Date.now() / 1000);
  const r = db.prepare('SELECT sp, sp_t FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { sp: -1, sp_t: 0 };
  let sp = r.sp < 0 ? max : Math.min(r.sp, max), t = r.sp_t || now;
  if (sp < max) { const ticks = Math.floor((now - t) / SP_EVERY); if (ticks > 0) { sp = Math.min(max, sp + ticks); t = sp >= max ? now : t + ticks * SP_EVERY; } } else t = now;
  return { sp, max, pass: sp >= max ? 0 : now - t, t };
}
// Energy (stamina for training): the original rule from normalconfig row 9 = one point every 180 s up to the level's maximum
// (playerlevel col 4); the client counts the same timer from LastActionUpdatePastTime. Ramen etc. may push it above the maximum.
const ENERGY_EVERY = 180;
function energyTick(db, pl) {
  ensure(db);
  const row = table('playerlevel').rows.find((r) => r[1] === pl.level) || [];
  const max = row[4] || 50, now = Math.floor(Date.now() / 1000);
  const r = db.prepare('SELECT energy, energy_t FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id) || { energy: max, energy_t: 0 };
  let e = r.energy, t = r.energy_t || now;
  // ORIGINAL normalconfig 87: every day at 22:00 (server PC time) energy refills to the maximum
  const d22 = new Date(); d22.setHours(22, 0, 0, 0); let last22 = Math.floor(d22.getTime() / 1000); if (last22 > now) last22 -= 86400;
  if (e < max && t < last22) { e = max; t = now; }
  if (e < max) { const ticks = Math.floor((now - t) / ENERGY_EVERY); if (ticks > 0) { e = Math.min(max, e + ticks); t = e >= max ? now : t + ticks * ENERGY_EVERY; } } else t = now;
  db.prepare('UPDATE players SET energy=?, energy_t=? WHERE uid=? AND server_id=?').run(e, t, pl.uid, pl.server_id);
  return { energy: e, max, pass: e >= max ? 0 : now - t };
}
function spUse(db, pl) {
  const s = spState(db, pl);
  if (s.sp <= 0) return false;
  db.prepare('UPDATE players SET sp=?, sp_t=? WHERE uid=? AND server_id=?').run(s.sp - 1, s.sp >= s.max ? Math.floor(Date.now() / 1000) : s.t, pl.uid, pl.server_id);
  return true;
}
// ---- Training enemies (GitHub #4 "full scaling through the whole campaign") -----------------------------------------------
// Boss rows of roundinfo list their enemies in cols 7-21 (npc ninjainfo ids). An npc row has its level in col 7 and its star in col 11
// but no stats (they lived on the dead server), so (ours) an npc gets the AVERAGE stats of the game's own playable cards of the same star
// at that level: base (cols 19-24) + growth (cols 25-30) x (level - 1). A normal stage fights the followers of its part's boss
// (without the leader, at most 3) at the boss's level. At most 5 enemies are sent (the fight screen has 5 places; (ours)).
// ENEMY_SCALE (ours): enemies get this share of an average card's stats. 0.6 keeps the first boss (1-2) winnable with the starter card;
// raise it to make the whole campaign harder, lower it for easier. One number, so the owner can tune it after playtesting.
const ENEMY_SCALE = Number(process.env.HB_ENEMY_SCALE) || 0.6;
let starAvg = null;
function npcStats(star, level) {
  if (!starAvg) {
    starAvg = {};
    for (const r of ninjas().values()) {
      if (r[4] !== 1 || r[6] !== 0 || !(r[19] > 0)) continue;
      const a = (starAvg[r[11]] = starAvg[r[11]] || { n: 0, v: new Array(12).fill(0) });
      a.n++; for (let i = 0; i < 12; i++) a.v[i] += r[19 + i] || 0;
    }
  }
  const a = starAvg[star] || starAvg[Math.min(6, Math.max(1, star || 2))] || starAvg[3];
  const v = (i) => Math.round((a.v[i] / a.n + (a.v[i + 6] / a.n) * Math.max(0, level - 1)) * ENEMY_SCALE);
  return { al: v(0), ah: v(1), dl: v(2), dh: v(3), cl: v(4), ch: v(5) };
}
// Enemy strength (the originals lived on the dead server). In a fight only my side attacks and every enemy's defence is taken off my attack,
// so what matters is the enemy team's TOTAL defence. Anchors: stage 1-2 = 285 (the owner's video of the original game: Mizuki 140 +
// Iruka 125... "total defence 285"); the last story boss (chapter 19, last stage) = 2 500 000 (owner's choice: a strong late build).
// In between it grows by the same factor every stage (ours). The named / first enemy carries a bit more than the others (video 140 vs 125).
const CURVE = { first: 285, last: 2500000 };
let storyIndex = null;
function storyPos(chap, stage) { // 0 = stage 1-1 ... N-1 = the last stage of chapter 19
  if (!storyIndex) { storyIndex = [0]; for (let c = 1; c <= 19; c++) storyIndex[c] = storyIndex[c - 1] + chapterStages(c); }
  return { at: (storyIndex[chap - 1] || 0) + stage - 1, of: storyIndex[19] };
}
// Where a given enemy team defence sits in the story (inverse of teamDefence): { chap, stage } or null when above the last boss.
function stageForDefence(d) {
  storyPos(1, 1);
  const n = storyIndex[19], frac = Math.log(Math.max(d, CURVE.first) / CURVE.first) / Math.log(CURVE.last / CURVE.first);
  if (frac > 1) return null;
  const at = Math.round(frac * (n - 2)) + 1;
  for (let c = 1; c <= 19; c++) if (at < storyIndex[c]) return { chap: c, stage: at - storyIndex[c - 1] + 1 };
  return { chap: 19, stage: chapterStages(19) };
}
function teamDefence(frac) { return Math.round(CURVE.first * Math.pow(CURVE.last / CURVE.first, frac)); }
function spreadFoes(ids, total, level) { // split a total defence over the enemies (first one x1.12) and give each a matching look
  const w = ids.map((_, i) => (i === 0 ? 1.12 : 1)), sw = w.reduce((t, x) => t + x, 0);
  return ids.map((id, i) => {
    const n = ninjas().get(id) || [], def = Math.max(1, Math.round((total * w[i]) / sw));
    return { id, low: Math.round(def * 1.3), high: Math.round(def * 1.6), def, end: def, level, star: n[11] || 2, power: def };
  });
}
function stageFoes(chap, stage) {
  const parts = chapterParts(chap), sp = stagePart(chap, stage), part = parts[sp.part - 1];
  if (!part) return [];
  const own = stageRow(chap, stage) || [], boss = stageRow(chap, part.first + part.count - 1) || [];
  const ids = (r) => r.slice(7, 22).filter((x) => x > 0);
  let list = own[38] ? ids(own) : ids(boss).slice(1, 4);
  if (!list.length) list = ids(boss).slice(0, 1);
  const pos = storyPos(chap, stage), frac = Math.max(0, (pos.at - 1) / Math.max(1, pos.of - 2)); // stage 1-2 = the 285 anchor
  return spreadFoes(list.slice(0, 5), teamDefence(frac), chap * 5 + Math.ceil(stage / 4));
}
// Battles ("dup", rushtower chapters 1-25): towerfloor rows with [2] = chapter, 7 rounds each in id order (the map: 6 shinobi then the boss);
// [4..8] the five enemies (the first is the named one), [20] exp, [21] silver (the reward the round's popup shows).
function towerRow(chap, round) { return table('towerfloor').rows.filter((r) => r[2] === chap).sort((a, b) => a[0] - b[0])[round - 1] || null; }
function towerFoes(chap, round) {
  const row = towerRow(chap, round);
  if (!row) return null;
  // Battles: 25 chapters x 7 rounds on the same curve as the story (round 1 = 285, the last = 2.5 million) (ours)
  const k = (chap - 1) * 7 + (round - 1);
  return spreadFoes(row.slice(4, 9).filter((x) => x > 0), teamDefence(k / 174), chap * 10 + round);
}
function getStage(db, uid, sid, chap) {
  ensure(db);
  const r = db.prepare('SELECT stage FROM progress WHERE uid=? AND server_id=? AND chap=?').get(uid, sid, chap);
  return r ? r.stage : 1;
}
// Training chapters: roundinfo [4] = chapter (1-19), [2] = stage number inside it.
const stageRow = (chap, stage) => table('roundinfo').rows.find((r) => r[4] === chap && r[2] === stage);
function stageEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS stage_clears (uid INTEGER, server_id INTEGER, chap INTEGER, stage INTEGER, clears INTEGER DEFAULT 0, boss_day TEXT, boss_used INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id, chap, stage))');
}
// Boss stages: 3 free fights a day, a 4th and later cost BOSS_COST gold (the client shows a gold button when 0 are left).
// Owner: "in the original you only got 3 per boss fight" (roundinfo [43] says 10-20, which the owner says is not what the game did).
const BOSS_FREE = 3, BOSS_COST = 10;
// Clears a stage needs before the next one opens. roundinfo [42] says 3 for every boss, but the owner says the original needed ONE boss win.
const clearsNeeded = (row) => (row[38] ? 1 : row[42] || 1);
// clears so far (capped at what the stage needs, like the screen) and boss tries left today
function stageState(db, pl, chap, stage) {
  stageEnsure(db);
  const row = stageRow(chap, stage) || [];
  const r = db.prepare('SELECT * FROM stage_clears WHERE uid=? AND server_id=? AND chap=? AND stage=?').get(pl.uid, pl.server_id, chap, stage);
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  // stages opened before clears were counted are already done
  const done = !r && getStage(db, pl.uid, pl.server_id, chap) > stage ? clearsNeeded(row) : 0;
  const used = r && r.boss_day === today ? r.boss_used : 0;
  return { clears: Math.min(clearsNeeded(row), r ? r.clears : done), bossLeft: row[38] ? Math.max(0, BOSS_FREE - used) : 0 };
}
function stageCleared(db, pl, chap, stage) {
  stageEnsure(db);
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  const prev = stageState(db, pl, chap, stage);
  const row = stageRow(chap, stage) || [];
  const used = row[38] ? BOSS_FREE - prev.bossLeft + 1 : 0;
  db.prepare(`INSERT INTO stage_clears(uid,server_id,chap,stage,clears,boss_day,boss_used) VALUES(?,?,?,?,?,?,?)
    ON CONFLICT DO UPDATE SET clears=excluded.clears, boss_day=excluded.boss_day, boss_used=excluded.boss_used`).run(pl.uid, pl.server_id, chap, stage, prev.clears + 1, today, used);
  return stageState(db, pl, chap, stage);
}
// A lost boss fight still uses one of the day's tries (clears stay as they were).
function stageTried(db, pl, chap, stage) {
  stageEnsure(db);
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  const prev = stageState(db, pl, chap, stage);
  const row = stageRow(chap, stage) || [];
  if (!row[38]) return prev;
  const r = db.prepare('SELECT clears FROM stage_clears WHERE uid=? AND server_id=? AND chap=? AND stage=?').get(pl.uid, pl.server_id, chap, stage);
  db.prepare(`INSERT INTO stage_clears(uid,server_id,chap,stage,clears,boss_day,boss_used) VALUES(?,?,?,?,?,?,?)
    ON CONFLICT DO UPDATE SET boss_day=excluded.boss_day, boss_used=excluded.boss_used`).run(pl.uid, pl.server_id, chap, stage, r ? r.clears : 0, today, BOSS_FREE - prev.bossLeft + 1);
  return stageState(db, pl, chap, stage);
}
// The client counts PARTS, not single stages: roundinfo [3] restarts at 1 for every part and the last stage of a part is its
// boss. It sends StageID = part and Pos = row inside the part, and reads currentstage / stageid as part numbers.
function chapterParts(chap) {
  const parts = [];
  for (const r of table('roundinfo').rows.filter((x) => x[4] === chap).sort((a, b) => a[2] - b[2])) {
    if (!parts.length || r[3] === 1) parts.push({ first: r[2], count: 0 });
    parts[parts.length - 1].count++;
  }
  return parts;
}
// global stage (progress.stage = next open stage, may be one past the chapter's end) -> { part, pos } (1-based)
function stagePart(chap, g) {
  const parts = chapterParts(chap);
  const i = parts.findIndex((p) => g >= p.first && g < p.first + p.count);
  if (i < 0) return { part: Math.max(1, parts.length), pos: parts.length ? parts[parts.length - 1].count : 1 };
  return { part: i + 1, pos: g - parts[i].first + 1 };
}
function globalStage(chap, part, pos) {
  const p = chapterParts(chap)[part - 1];
  return p ? p.first + Math.min(Math.max(1, pos), p.count) - 1 : 0;
}
// What the client shows for one part: finished parts are fully open, the current part is open up to `pos`.
function partEntry(db, pl, chap, part) {
  const parts = chapterParts(chap), p = parts[part - 1], cur = stagePart(chap, getStage(db, pl.uid, pl.server_id, chap));
  const pos = part < cur.part ? p.count : cur.pos;
  const st = stageState(db, pl, chap, p.first + pos - 1);
  // the tries are the part's BOSS tries (its last row): taking them from the row at `pos` sent 0 after every normal stage,
  // so winning a story stage looked like it used up the boss's tries (Discord report, 3 Nov 2026)
  return { pos, pos_time: st.clears, pk_boss_times: stageState(db, pl, chap, p.first + p.count - 1).bossLeft };
}
function chapterStages(chap) { return table('roundinfo').rows.filter((r) => r[4] === chap).reduce((m, r) => Math.max(m, r[2]), 1); }
function furthestChapter(db, uid, sid) {
  ensure(db);
  return db.prepare('SELECT chap, stage FROM progress WHERE uid=? AND server_id=? AND chap<1000 ORDER BY chap DESC LIMIT 1').get(uid, sid) || { chap: 1, stage: 1 };
}
// <normal> = where the player is now, <chaplist> = every opened chapter (roundinfo [3] = chapter).
function roundInfoXml(db, pl) {
  ensure(db);
  const per = {};
  for (let c = 1; c <= 19; c++) per[c] = chapterStages(c);
  const open = db.prepare('SELECT chap, stage FROM progress WHERE uid=? AND server_id=? AND chap<1000 ORDER BY chap').all(pl.uid, pl.server_id);
  if (!open.length) open.push({ chap: 1, stage: 1 });
  const cur = open[open.length - 1];
  const chap = (o) => '<chap>' + el('id', o.chap) + el('hardLevel', 0) + el('roundid', o.stage) + el('subroundid', 1) + el('maxround', per[o.chap] || 1) + '</chap>';
  return '<normal>' + el('chapid', cur.chap) + el('roundid', cur.stage) + el('subroundid', 1) + el('restback', 3) + el('maxround', per[cur.chap] || 1) + '</normal>' +
    `<chaplist>${open.map(chap).join('')}</chaplist>`;
}
// Admin "Unlock everything": top player level (playerlevel table), every training chapter and stage cleared (so every team slot and
// chapter opens: slots follow level + cleared stages, game.maxTeam), every Battles round cleared, energy full.
function unlockAll(db, pl) {
  ensure(db); stageEnsure(db);
  const lv = table('playerlevel').rows;
  const top = lv[lv.length - 1];
  db.prepare('UPDATE players SET level=?, exp=0, energy=MAX(energy,?) WHERE uid=? AND server_id=?').run(top[1], top[4] || 0, pl.uid, pl.server_id);
  const today = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  const put = db.prepare(`INSERT INTO stage_clears(uid,server_id,chap,stage,clears,boss_day,boss_used) VALUES(?,?,?,?,?,?,0)
    ON CONFLICT DO UPDATE SET clears=MAX(clears, excluded.clears)`);
  for (let chap = 1; chap <= 19; chap++) {
    const n = chapterStages(chap);
    for (let s = 1; s <= n; s++) put.run(pl.uid, pl.server_id, chap, s, clearsNeeded(stageRow(chap, s) || []), today);
    setStage(db, pl.uid, pl.server_id, chap, n + 1);
  }
  for (let c = 1; c <= 3; c++) setStage(db, pl.uid, pl.server_id, 1000 + c, 7); // Battles: 3 chapters x 6 rounds
  const after = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  return { level: after.level, slots: maxTeam(db, after) };
}
function setStage(db, uid, sid, chap, stage) {
  ensure(db);
  if (chap < 1000) { // progress log: every new story stage, and a separate line when a new chapter opens (admin > Player log)
    const was = db.prepare('SELECT stage FROM progress WHERE uid=? AND server_id=? AND chap=?').get(uid, sid, chap);
    const log = require('./playerlog');
    if (!was) log.note(db, uid, sid, 'chapter', chap, `chapter ${chap}`);
    if (!was || stage > was.stage) log.note(db, uid, sid, 'stage', chap * 1000 + stage, `${chap}-${stage}`);
  }
  db.prepare('INSERT INTO progress(uid,server_id,chap,stage) VALUES(?,?,?,?) ON CONFLICT(uid,server_id,chap) DO UPDATE SET stage=MAX(stage,excluded.stage)').run(uid, sid, chap, stage);
}


// ---- God-card synthesis ("evolve"): two matching cards -> the 6-star version of that character (same npc icon family).
function godOf(ninjaId) {
  const n = ninjas().get(ninjaId); if (!n) return null;
  const fam = String(n[3]);
  const cand = [...ninjas().values()].find((r) => r[4] === 1 && r[11] === 6 && String(r[3]) === fam && r[0] !== ninjaId);
  if (cand) return cand[0];
  const gods = [...ninjas().values()].filter((r) => r[4] === 1 && r[6] === 0 && r[11] === 6 && /God/.test(r[2]));
  return gods.length ? gods[ninjaId % gods.length][0] : null; // no same-character god card: pick a god card deterministically
}
// God evolve: ORIGINAL (Facebook photos 2065, 2066, 2169) 100 evolution pills (Development Dan, item 34) plus the attack and defense card.
const GOD_COST = 100;
function godSynth(db, pl, attSeq, defSeq) {
  ensure(db);
  const a = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(attSeq, pl.uid, pl.server_id);
  const b = db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=1').get(defSeq, pl.uid, pl.server_id);
  if (!a || !b || a.seq === b.seq) return { error: 'cards missing' };
  const god = godOf(b.ninja_id) || godOf(a.ninja_id); if (!god) return { error: 'no evolution for this card' };
  for (const c of [a, b]) if (inLineup(db, c.seq)) return { error: 'remove cards from the team first' };
  if ((propCounts(db, pl.uid, pl.server_id)[34] || 0) < GOD_COST) return { error: 'Insufficient evolution pills' };
  propAdd(db, pl.uid, pl.server_id, 34, -GOD_COST);
  db.prepare('DELETE FROM cards WHERE seq IN (?,?)').run(a.seq, b.seq);
  const seq = giveCard(db, pl.uid, pl.server_id, god);
  // "Reincarnation and growth will be retained" (the evolve screen): the best rebirth and sage growth of the two cards carry over
  const newlife = Math.max(a.newlife || 0, b.newlife || 0), starlevel = Math.max(a.starlevel || 0, b.starlevel || 0);
  db.prepare('UPDATE cards SET newlife=?, starlevel=? WHERE seq=?').run(newlife, starlevel, seq);
  return { ninja: god, seq, newlife, starlevel };
}

module.exports = { COST, TEN_COST, rollOne, payHeapState, TEAM2_LEVEL, lineup, inLineup, activateTeam, teamReplyXml, arenaEnsure, vipRow, buffOn, BUFF_EXP, useLimit, meritLevel, foeAttri, foeTeam, teamSizeAt, GOD_COST, packSilver, elementPrice, elementChange, inherit, inheritInfoXml, shopGold, secretRefresh, arenaReward, benchFight, stageForDefence, teamDefence, equipStats, sealBonus, setBonus, skillSets, ninjutsuBonus, addStats, chainPartsOf: (r) => partsOf(r), chainFits: (part, id) => fits(part, id), chainKnown: (part) => isKnown(part), matchRows, towerRow, towerFoes, unlockAll, growStarList, GROW_MAX, energyTick, stageTried, stageFoes, npcStats, orderUsedToday, ORDER_DAILY, spState, spUse, clearsNeeded, payHeapXml, payHeapClaim, actEnsure, recruitState, FREE_EVERY, BOSS_COST, chapterParts, stagePart, globalStage, partEntry, maxTeam, stageRow, stageState, stageCleared, chapterStages, furthestChapter, roundInfoXml, teamSwap, grantDrop, mergeChips, mergeAwards, ninjaStats, CHIP_BASE, chipCount, chipbagXml, godSynth, potentialXml, potentialRoll, potentialSave, newlife, NEWLIFE_MAX, NEWLIFE_COST, arenaListXml, arenaRankXml, arenaFight, arenaClearCd, gateXml, gateOpen, gateLevel, gateBonus, friendsXml, sageGrow, giveEquip, teamStats, awardXml, secretXml, secretBuy, soulOf, equip, strengthen, packBuy, propUse, propCounts, propAdd, shopBuy, actXml, actClaim, sparFight, sparTooOften, rivalsXml, rivals, bumpTask, dailyXml, dailyClaim, awardFull, addExp, battleXml, getStage, setStage, pull, pullXml, table, ninjas, ensure, giveCard, ensureStarterTeam, stateXml, cardXml };
