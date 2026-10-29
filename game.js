// Game-state helpers: cards (characters), teams, starter grants. Data tables live in ./data/*.json
const fs = require('fs');
const path = require('path');

const table = (name) => JSON.parse(fs.readFileSync(path.join(__dirname, 'data', name + '.json'), 'utf8'));
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
  `);
  ready.add(db);
}

// Starter characters: the one picked at character creation first, then the rest of Team 7-ish.
const STARTERS = { 1: 57, 2: 56, 3: 55 }; // Shikamaru, Sakura, Neji (the 3 choices on the create screen)
const BASE_TEAM = [5, 35, 9]; // Naruto, Kakashi, Sasuke

function giveCard(db, uid, sid, ninjaId, type = 1) {
  const r = db.prepare('INSERT INTO cards(uid,server_id,type,ninja_id) VALUES(?,?,?,?)').run(uid, sid, type, ninjaId);
  return Number(r.lastInsertRowid);
}

function ensureStarterTeam(db, uid, sid, pick) {
  ensure(db);
  const have = db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=? AND server_id=?').get(uid, sid).n;
  if (have > 0) return;
  const ids = [STARTERS[pick] || 57, ...BASE_TEAM];
  ids.forEach((nid, i) => {
    const seq = giveCard(db, uid, sid, nid);
    db.prepare('INSERT OR REPLACE INTO team(uid,server_id,slot,seq) VALUES(?,?,?,?)').run(uid, sid, i, seq);
  });
}

// ---- Equipment (cards of type 2 weapon / 3 armor / 4 accessory; id = equipmentinfo id) -------
const equipRows = () => table('equipmentinfo').rows;
const SLOT_TYPE = { 0: 2, 1: 3, 2: 4 }; // equipmentinfo col3 slot -> card type
function giveEquip(db, uid, sid, equipId) {
  const e = equipRows().find((r) => r[0] === equipId);
  if (!e) return 0;
  return giveCard(db, uid, sid, equipId, SLOT_TYPE[e[3]] || 2);
}
function randomEquip(slot, minStar = 3) {
  const pool = equipRows().filter((r) => r[3] === slot && r[5] === 1 && r[6] >= minStar);
  return pool[Math.floor(Math.random() * pool.length)][0];
}

const el = (n, v) => `<${n}>${v}</${n}>`;
function cardXml(c) {
  const f = {
    type: c.type, id: c.ninja_id, exp: c.exp, seq: c.seq, level: c.level, attri: 0, starlevel: c.starlevel,
    newlife: 0, tupo_level: 0, cha_tupo: 0, defence_tupo: 0, attack_tupo: 0, attackadd: 0, defenseadd: 0,
    attack_add: 0, defence_add: 0, cha_add: 0, status: 0,
  };
  return '<card>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') + '</card>';
}

// One team slot as CTeamCard::firefly_InitFromXml reads it (ninjaid = the card's seq).
function slotXml(seq, slot, eq = {}) {
  const f = { seq: slot + 1, ninjaid: seq, weaponid: eq[1] || 0, armorid: eq[2] || 0, decoratorid: eq[3] || 0, markid: eq[4] || 0,
    ninjintsu1seq: eq[5] || 0, ninjintsu2seq: eq[6] || 0, ninjintsu3seq: eq[7] || 0, ninjintsu4seq: eq[8] || 0,
    attacklow: 10, attackhigh: 20, defenselow: 5, defensehigh: 10, chakralow: 10, chakrahigh: 20, skillsuit: 0 };
  return '<ninja>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') +
    '<combinlist></combinlist><readycombinlist></readycombinlist></ninja>';
}

// Equip (kind 1 weapon, 2 armor, 3 trinket, 4 seal, 5-8 ninjutsu slots) a card onto the ninja in team slot (1-based).
function equip(db, pl, slot, kind, newSeq) {
  ensure(db);
  db.prepare('DELETE FROM equipped WHERE uid=? AND server_id=? AND kind=? AND seq=?').run(pl.uid, pl.server_id, kind, newSeq);
  if (!newSeq) db.prepare('DELETE FROM equipped WHERE uid=? AND server_id=? AND slot=? AND kind=?').run(pl.uid, pl.server_id, slot, kind);
  else db.prepare('INSERT OR REPLACE INTO equipped(uid,server_id,slot,kind,seq) VALUES(?,?,?,?,?)').run(pl.uid, pl.server_id, slot, kind, newSeq);
}

function stateXml(db, uid, sid) {
  ensure(db);
  const cards = db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=? ORDER BY seq').all(uid, sid);
  let team = db.prepare('SELECT seq FROM team WHERE uid=? AND server_id=? ORDER BY slot').all(uid, sid);
  if (process.env.HB_TEAM_SLOTS !== undefined) team = team.slice(0, Number(process.env.HB_TEAM_SLOTS)); // debugging aid
  const eqRows = db.prepare('SELECT slot, kind, seq FROM equipped WHERE uid=? AND server_id=?').all(uid, sid);
  const eqOf = (slot) => Object.fromEntries(eqRows.filter((r) => r.slot === slot).map((r) => [r.kind, r.seq]));
  return {
    cards: cards.map(cardXml).join(''),
    ninjalist: '<ninjalist>' + team.map((t, i) => slotXml(t.seq, i, eqOf(i + 1))).join('') + '</ninjalist>',
  };
}

// ---- Gacha ("recruit") -----------------------------------------------------------------
// Pull types follow recruitinfo.dbf rows: 1 = premium (300 gold), 2 = standard (150 gold), 3 = free.
// Star weights are a hobby-server design choice (the original rates lived on the old server).
const RATES = {
  1: { 6: 2, 5: 12, 4: 36, 3: 50 },
  2: { 5: 4, 4: 20, 3: 46, 2: 30 },
  3: { 4: 5, 3: 25, 2: 40, 1: 30 },
};
const COST = { 1: 300, 2: 150, 3: 0 };
const TEN_COST = { 1: 2800, 2: 1400, 3: 0 };
let byStar = null;
function pools() {
  if (!byStar) {
    byStar = {};
    for (const r of ninjas().values()) if (r[4] === 1) (byStar[r[11]] = byStar[r[11]] || []).push(r[0]);
  }
  return byStar;
}
function rollOne(type) {
  try { const f = Number(fs.readFileSync(path.join(__dirname, 'force_ninja.txt'), 'utf8')); if (f) return f; } catch {} // debugging aid
  const rates = RATES[type] || RATES[2];
  const total = Object.values(rates).reduce((a, b) => a + b, 0);
  let x = Math.random() * total;
  let star = Number(Object.keys(rates)[0]);
  for (const [s, w] of Object.entries(rates)) { if ((x -= w) < 0) { star = Number(s); break; } }
  const pool = pools()[star] || pools()[3];
  return pool[Math.floor(Math.random() * pool.length)];
}
function pull(db, pl, type, count, free) {
  const cost = free ? 0 : count === 10 ? (TEN_COST[type] ?? 1400) : (COST[type] ?? 150) * count; // ten-pull prices are the ones the client shows
  if (pl.gold < cost) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  const got = [];
  for (let i = 0; i < count; i++) {
    const nid = rollOne(type);
    got.push({ ninja: nid, seq: giveCard(db, pl.uid, pl.server_id, nid) });
  }
  return { cost, got };
}
function awardXml(c) {
  return '<award dropid="0"><cardlist><card>' + el('id', c.ninja) + el('type', 1) + el('num', 1) + el('attri', 0) + el('bagIndex', c.seq) +
    '</card></cardlist><proplist></proplist><chipbag></chipbag><coin>0</coin><cash>0</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>';
}
// Cmd 1900 (one pull): <recruit .../> attributes + <award>. Cmd 1901 (ten pulls): <recruit_list> of exactly 10 <item><award>.
function pullXml(res, count) {
  if (count === 1) {
    const c = res.got[0];
    return `<recruit ninjaid="${c.ninja}" cost="${res.cost}" bagid="${c.seq}" attr="0" costprop="0"/>` + awardXml(c);
  }
  return '<recruit_list>' + res.got.map((c) => '<item>' + awardXml(c) + '</item>').join('') + '</recruit_list>';
}


// ---- Training battles -----------------------------------------------------------------------
// The client replays whatever fight we describe: <fight><preview/><guard>(enemies)<killer>(my team)<roundlist>.
function ninjaXml(n) {
  const f = { id: n.id, bagid: n.bagid, low: n.low, high: n.high, end: n.end, level: n.level, attri: 0, starlevel: n.star, newlife: 0 };
  return '<ninja>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') + '</ninja>';
}
function battleXml(db, pl, chap, stage, opt = {}) {
  const team = db.prepare('SELECT t.slot, c.seq, c.ninja_id, c.level, c.starlevel FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(pl.uid, pl.server_id);
  const mine = team.map((t) => ({ id: t.ninja_id, bagid: t.seq, low: 40 + stage * 2, high: 60 + stage * 3, end: 500, level: t.level, star: t.starlevel }));
  const foes = (opt.enemyIds || [21, 22, 23]).map((id, i) => ({ id, bagid: 1000 + i, low: 10, high: 20, end: 60 + stage * 10, level: opt.enemyLevel || 1, star: 0 }));
  const rounds = [];
  foes.forEach((foe, i) => {
    const me = mine[i % mine.length];
    rounds.push({ AttackNinja: me.bagid, Attack: me.high, AttackAttri: 0, DefenseNinja: foe.bagid, Defense: 0, DefenseAttri: 0,
      CauseLimit: 0, LimitVal: 0, FinalAttack: me.high, FinalDefense: 0, AttPetAttack: 0, AttPetDefense: 0, DefPetAttack: 0, DefPetDefense: 0,
      AttPetSkillHurt: 0, DefpetSkillHurt: 0, AttGateAttack: 0, AttGateDefense: 0, DefGateAttack: 0, DefGateDefense: 0 });
  });
  const roundXml = rounds.map((r) => '<round>' + Object.entries(r).map(([k, v]) => el(k, v)).join('') + '<skills></skills><defense_skills></defense_skills></round>').join('');
  const win = opt.win === false ? 0 : 1;
  const nick = (opt.enemyName || 'Enemy').replace(/[<>&"]/g, '');
  return `<fight><preview type="0" result="${win}" defensenick="${nick}" defenseuid="${opt.enemyUid || 0}" defensecountry="1" defenselevel="${opt.enemyLevel || 1}" defenseviplevel="0"/>` +
    '<guard><ninjalist>' + foes.map(ninjaXml).join('') + '</ninjalist></guard>' +
    '<killer><ninjalist>' + mine.map(ninjaXml).join('') + '</ninjalist></killer>' +
    '<roundlist>' + roundXml + '</roundlist></fight>';
}

// Spar fight against rival ToUid (a real player or a bot). Strength = level + stars of the team; a little luck.
function sparFight(db, pl, toUid) {
  const rv = rivals(db, pl, 12).find((r) => r.id === toUid) || { id: toUid, level: pl.level, nick: 'Rival', ninja: 5 };
  const power = (lv, star) => lv * 2 + star * 10 + 10;
  const cards = db.prepare('SELECT c.level, c.ninja_id FROM cards c JOIN team t ON t.seq=c.seq WHERE t.uid=? AND t.server_id=?').all(pl.uid, pl.server_id);
  const mine = cards.reduce((a, c) => a + power(c.level + Math.floor(pl.level / 3), (ninjas().get(c.ninja_id) || [])[11] || 3), 0) || 10;
  const theirs = 3 * power(rv.level, rv.star || 3);
  const win = mine * (0.7 + Math.random() * 0.6) >= theirs;
  const xml = battleXml(db, pl, 0, 1, { enemyIds: [rv.ninja, rv.ninja, rv.ninja], enemyName: rv.nick, enemyUid: rv.id, enemyLevel: rv.level, win });
  const coin = win ? 3 + rv.level : 0, exp = win ? 14 : 2;
  return { win, xml, coin, exp };
}

// Player exp -> level (playerlevel.dbf col 2 = exp needed to leave that level).
function addExp(db, pl, exp) {
  const rows = table('playerlevel').rows;
  let level = pl.level, cur = (pl.exp || 0) + exp;
  for (;;) {
    const r = rows.find((x) => x[1] === level);
    if (!r || cur < r[2]) break;
    cur -= r[2]; level++;
  }
  db.prepare('UPDATE players SET level=?, exp=? WHERE uid=? AND server_id=?').run(level, cur, pl.uid, pl.server_id);
  return level;
}

// ---- Daily tasks -----------------------------------------------------------------------------
const today = () => new Date().toISOString().slice(0, 10);
const DAILY_AWARDS = [ // id, points needed, reward
  { id: 1, cost: 20, coin: 5000, cash: 0 }, { id: 2, cost: 40, coin: 0, cash: 20 }, { id: 3, cost: 60, coin: 10000, cash: 0 },
  { id: 4, cost: 80, coin: 0, cash: 50 }, { id: 5, cost: 100, coin: 0, cash: 100 },
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
  score = Math.min(score, 100);
  const awards = DAILY_AWARDS.map((a) => `<award id="${a.id}" status="${claimed.has(a.id) ? 2 : score >= a.cost ? 1 : 0}" cost="${a.cost}"><drop_list></drop_list></award>`).join('');
  return `<player><total>100</total><current>${score}</current></player><task_list>${tasks}</task_list><award_list>${awards}</award_list>`;
}
function dailyClaim(db, pl, awardId) {
  dailyEnsure(db);
  const a = DAILY_AWARDS.find((x) => x.id === awardId);
  if (!a) return null;
  db.prepare('INSERT OR IGNORE INTO dailyaward(uid,server_id,day,award_id) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, today(), awardId);
  db.prepare('UPDATE players SET coin=coin+?, gold=gold+? WHERE uid=? AND server_id=?').run(a.coin, a.cash, pl.uid, pl.server_id);
  return a;
}
// Complete <award> element (Lua requires every child to exist).
function awardFull({ coin = 0, cash = 0, exp = 0 } = {}) {
  return `<award dropid="0" coin="${coin}"><coin>${coin}</coin><cash>${cash}</cash><exp>${exp}</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>`;
}

// ---- Spar / rivals --------------------------------------------------------------------------
const BOT_NAMES = ['Iron Fist Lee', 'Shadow Hana', 'Rogue Kaito', 'Silent Ren', 'Blaze Mika', 'Sand Gaku', 'Mist Yuna', 'Thunder Ryo', 'Frost Aoi', 'Wind Sora'];
// Rival list: other real players first (friends on the same server), then bots near the player's level.
function rivals(db, pl, count = 8) {
  const real = db.prepare('SELECT * FROM players WHERE server_id=? AND uid!=? ORDER BY ABS(level-?) LIMIT ?').all(pl.server_id, pl.uid, pl.level, count);
  const out = real.map((r) => ({ id: r.uid, level: r.level, nick: r.nick, country: r.country, ninja: firstNinja(db, r) }));
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
      chakralow: a, chakrahigh: a + 20, firstninja: r.ninja, firstninjastar: r.star || 3, newlife: 0, country: r.country, coin: 100 + lv * 20 };
    return '<user>' + Object.entries(o).map(([k, v]) => el(k, v)).join('') + '</user>';
  };
  return '<userlist page="1" addrate="0" resttime="0">' + rivals(db, pl).map(f).join('') + '</userlist>';
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
  const c = actClaimable(db, pl);
  const subs = (a) => a.map((i) => `<subitem subid="${i}"></subitem>`).join('');
  return `<activity type="1" loginallnum="${c.days}"><item actid="1">${subs(c.login)}</item></activity>` +
    `<activity type="2"><item actid="2">${subs(c.up)}</item></activity><activity type="3"><item actid="3" pos="-1"></item></activity><activity type="4"><item actid="4"></item></activity>` +
    '<conf><items>' + [[1, 1], [2, 2]].map(([id, pos]) => `<item><id>${id}</id><pos>${pos}</pos><status>1</status><onoff>1</onoff><type>2</type></item>`).join('') + '</items></conf>';
}
function actClaim(db, pl, actid, subid) {
  const c = actClaimable(db, pl);
  const ok = (actid === 1 ? c.login : actid === 2 ? c.up : []).includes(subid);
  if (!ok) return null;
  const P = table('activity_packs');
  db.prepare('INSERT OR IGNORE INTO actclaim(uid,server_id,actid,subid) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, actid, subid);
  const coin = (actid === 1 ? P.login_q : P.upgrade_q)[subid - 1] || 1000, cash = 20 + subid * 5;
  db.prepare('UPDATE players SET coin=coin+?, gold=gold+? WHERE uid=? AND server_id=?').run(coin, cash, pl.uid, pl.server_id);
  return { coin, cash };
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
}
// Buy: kind 'good' (consumeinfo) or 'pack' (giftinfo, opened immediately for coins/gold).
function shopBuy(db, pl, goodsId, count) {
  const row = table('consumeinfo').rows.find((r) => r[1] === goodsId);
  if (!row) return { error: 'no such item' };
  const costG = row[4] * count, costS = row[5] * count;
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
  propAdd(db, pl.uid, pl.server_id, goodsId, -1);
  let coin = 0, ap = 0;
  if (row[7] === 3) { coin = Math.round(row[8]); db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(coin, pl.uid, pl.server_id); }
  if (row[7] === 1) { ap = Math.round(row[8]); db.prepare('UPDATE players SET energy=energy+? WHERE uid=? AND server_id=?').run(ap, pl.uid, pl.server_id); }
  const now = db.prepare('SELECT energy, coin FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  return { ap, coin, left: have - 1 }; // deltas: the client adds them to its own totals
}

// Gift packs: only packs whose drop row gives ninja cards work (equipment/ninjutsu cards are not implemented yet).
function packBuy(db, pl, packId) {
  const g = table('giftinfo').rows.find((r) => r[0] === packId);
  if (!g) return { error: 'no such pack' };
  const drop = table('dropinfo').rows.find((r) => r[0] === Math.round(g[8]));
  if (!drop) return { error: 'this pack is not available on the revival server yet' };
  const name = String(g[2]).toLowerCase();
  const costG = g[4], costS = g[5];
  if (pl.gold < costG || pl.coin < costS) return { error: 'not enough gold' };
  let give; // () => [type, id, seq]
  if (drop[3] && ninjas().has(drop[3])) give = () => [1, drop[3], giveCard(db, pl.uid, pl.server_id, drop[3])];
  else if (drop[4] && equipRows().some((r) => r[0] === drop[4] && r[5] === 3)) give = () => [2, drop[4], giveEquip(db, pl.uid, pl.server_id, drop[4])];
  else if (/weapon|armor|trinket/.test(name)) {
    const slot = /weapon/.test(name) ? 0 : /armor/.test(name) ? 1 : 2;
    const minStar = /4☆/.test(name) ? 3 : 2;
    give = () => { const id = randomEquip(slot, minStar); return [SLOT_TYPE[slot], id, giveEquip(db, pl.uid, pl.server_id, id)]; };
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
  const eat = eatSeqs.filter((q) => q !== srcSeq && !db.prepare('SELECT 1 FROM team WHERE seq=?').get(q))
    .map((q) => db.prepare('SELECT seq FROM cards WHERE seq=? AND uid=? AND server_id=?').get(q, pl.uid, pl.server_id)).filter(Boolean);
  const exp = eat.length * 75, cost = exp * 2;
  if (pl.coin < cost) return { error: 'not enough silver' };
  const rows = table('ninjaupgrade').rows;
  let level = src.level, cur = src.exp + exp;
  for (;;) { const r = rows.find((x) => x[1] === level); if (!r || level >= Math.min(pl.level * 2 + 10, 99) || cur < r[2]) break; cur -= r[2]; level++; }
  db.prepare('UPDATE players SET coin=coin-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE cards SET level=?, exp=? WHERE seq=?').run(level, cur, srcSeq);
  for (const e of eat) db.prepare('DELETE FROM cards WHERE seq=?').run(e.seq);
  bumpTask(db, pl.uid, pl.server_id, 20);
  return { exp, cost };
}

// ---- Secret (soul) shop ----------------------------------------------------------------------
const SOUL = 9999; // props id used for ninja souls
function soulOf(db, pl) {
  const c = propCounts(db, pl.uid, pl.server_id);
  if (c[SOUL] === undefined) { propAdd(db, pl.uid, pl.server_id, SOUL, 30000); return 30000; } // starter souls for the offline server
  return c[SOUL];
}
function secretPicks(pl) {
  const rows = table('secret_shop').rows.filter((r) => ninjas().has(r[5]));
  const day = Math.floor(Date.now() / 86400000), picks = [];
  let seed = (pl.uid * 31 + day + (pl.shopseed || 0)) >>> 0;
  const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296;
  while (picks.length < 6 && picks.length < rows.length) { const r = rows[Math.floor(rnd() * rows.length)]; if (!picks.includes(r)) picks.push(r); }
  return picks;
}
function secretXml(db, pl) {
  const soul = soulOf(db, pl);
  const cards = secretPicks(pl).map((r) => { const n = ninjas().get(r[5]); return `<item><card>${el('id', r[0])}${el('type', 1)}${el('subtype', 1)}${el('name', String(n[2]).replace(/[<>&]/g, ''))}${el('icon', r[5])}${el('num', 1)}${el('cost', r[8])}${el('costtype', 1)}${el('status', 0)}${el('itemid', r[5])}${el('attacktype', 0)}</card></item>`; }).join('');
  return `<user>${el('cursoul', soul)}${el('updatenum', 99)}${el('gold', pl.gold)}${el('refreshcost', 0)}${el('totalrefresh', 99)}${el('dayrefreshleft', 99)}${el('lefttime', 86400)}</user><cardlist>${cards}</cardlist>`;
}
function secretBuy(db, pl, rowId) {
  const r = secretPicks(pl).find((x) => x[0] === rowId);
  if (!r) return { error: 'not in shop' };
  if (soulOf(db, pl) < r[8]) return { error: 'not enough souls' };
  propAdd(db, pl.uid, pl.server_id, SOUL, -r[8]);
  const seq = giveCard(db, pl.uid, pl.server_id, r[5]);
  return { ninja: r[5], seq };
}

function getStage(db, uid, sid, chap) {
  ensure(db);
  const r = db.prepare('SELECT stage FROM progress WHERE uid=? AND server_id=? AND chap=?').get(uid, sid, chap);
  return r ? r.stage : 1;
}
function setStage(db, uid, sid, chap, stage) {
  ensure(db);
  db.prepare('INSERT INTO progress(uid,server_id,chap,stage) VALUES(?,?,?,?) ON CONFLICT(uid,server_id,chap) DO UPDATE SET stage=MAX(stage,excluded.stage)').run(uid, sid, chap, stage);
}

module.exports = { awardXml, secretXml, secretBuy, soulOf, equip, strengthen, packBuy, propUse, propCounts, propAdd, shopBuy, actXml, actClaim, sparFight, rivalsXml, rivals, bumpTask, dailyXml, dailyClaim, awardFull, addExp, battleXml, getStage, setStage, pull, pullXml, table, ninjas, ensure, giveCard, ensureStarterTeam, stateXml, cardXml };
