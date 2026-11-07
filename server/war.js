// Country war (War > War tab, CWarInfoView). On this server the war is always open (owner decision 1 Nov 2026; the original ran
// 19:30-20:30, normalconfig rows 7/8, which hot update 28.0.27 sets to 0-86400 so the client clock counts down to midnight): your country fights the other
// two. Every attack is a fight against a member (or a guard bot) of an enemy country; wins earn merit score and kills.
// Each player has "alive" points (lives) that refill daily.
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const day = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
const MAX_ALIVE = 10;
const now = () => Math.floor(Date.now() / 1000);
const nc = (id, d) => { const r = game.table('normalconfig').rows.find((x) => x[0] === id); return r && r[3] != null ? r[3] : d; };
// ORIGINAL attack cooldown (owner chose the original, 7 Nov 2026; normalconfig 18 / 20 / 22): after every 3 attacks a 600 s wait, which
// 30 gold clears (Cmd 4104). The screen counts it down from <preview fightlefttime> and shows the price from curintercost. Was no wait.
const CD_AFTER = nc(18, 3), CD_SECS = nc(20, 600), CD_CLEAR = nc(22, 30);
// Auto-Attack (Cmd 4103 AutoType 1-3, CDlgAutoFightBuy: "You can auto-attack in the country war, cost N gold to auto-attack? (still work
// if offline)"). ORIGINAL price 50 gold (normalconfig 97 "country war auto attack gold"), for the rest of the day (our war resets at
// midnight). AutoType 2 / 3 also clear the cooldown by themselves N times: (ours) 5 clears for 150 gold, 10 for 300 (= the 30-gold hand
// price; the layout's placeholder 180 / 380 gold and 20 times are not the server's). While the game is open it attacks by itself every
// few seconds (CCountryWarFightDataMgr sends Cmd 4102); autoTick attacks for players who are offline. Was not built (7 Nov, Discord report).
const AUTO_COST = nc(97, 50), AUTO_EXTRA = { 1: [0, 0], 2: [150, 5], 3: [300, 10] };
// the code that makes the game's auto-attacker stop (CCountryWarFightDataMgr::onHttpRequestCompleted: 149494 = Inactivate; any other
// refusal, like the cooldown, keeps it trying every few seconds)
const AUTO_STOP = 149494;
const toMidnight = () => { const m = new Date(); m.setHours(24, 0, 0, 0); return Math.round((m - Date.now()) / 1000); };

const ensured = new WeakSet();
function ensure(db) {
  if (ensured.has(db)) return;
  db.exec(`CREATE TABLE IF NOT EXISTS war (server_id INTEGER, day TEXT, uid INTEGER, country INTEGER, alive INTEGER DEFAULT ${MAX_ALIVE},
    score INTEGER DEFAULT 0, kills INTEGER DEFAULT 0, beattack INTEGER DEFAULT 0, PRIMARY KEY(server_id, day, uid));
    CREATE TABLE IF NOT EXISTS war_log (id INTEGER PRIMARY KEY AUTOINCREMENT, server_id INTEGER, uid INTEGER, tuid INTEGER, fromnick TEXT, tonick TEXT,
      fromcountry INTEGER, tocountry INTEGER, win INTEGER, score INTEGER)`);
  // streak = attacks since the last cooldown, cd_until = cooldown end, auto / clears = today's Auto-Attack and its cooldown clears left
  for (const c of ['streak', 'cd_until', 'auto', 'clears', 'last_attack']) { try { db.exec(`ALTER TABLE war ADD COLUMN ${c} INTEGER DEFAULT 0`); } catch (e) { /* already there */ } }
  ensured.add(db);
}
const cdLeft = (m) => Math.max(0, (m.cd_until || 0) - now());
function me(db, pl) {
  ensure(db);
  db.prepare('INSERT OR IGNORE INTO war(server_id,day,uid,country) VALUES(?,?,?,?)').run(pl.server_id, day(), pl.uid, pl.country);
  return db.prepare('SELECT * FROM war WHERE server_id=? AND day=? AND uid=?').get(pl.server_id, day(), pl.uid);
}
const enemies = (c) => [1, 2, 3].filter((x) => x !== c);
// War progress windows (the "?" next to killing number / casualty on the War screen: CWarAttackProgressDialog, rl_r_countryranknew
// Cmd 4201 kills / 4204 casualties, Country = the side shown; CCountryWarProgressDialog Cmd 4203): today's players of that country by
// kills (or times attacked), <user><rank/><uid/><nick/><realval/><countryid/></user>; my own kills, rank and merit as <userrank> attributes.
function progressXml(db, pl, cmd, country) {
  ensure(db);
  const col = cmd === 4204 ? 'beattack' : 'kills', c = country || pl.country;
  const rows = db.prepare(`SELECT w.uid, w.${col} val, p.nick FROM war w JOIN players p ON p.uid=w.uid AND p.server_id=w.server_id
    WHERE w.server_id=? AND w.day=? AND w.country=? ORDER BY w.${col} DESC, w.score DESC LIMIT 50`).all(pl.server_id, day(), c);
  const mine = db.prepare('SELECT * FROM war WHERE server_id=? AND day=? AND uid=?').get(pl.server_id, day(), pl.uid) || { kills: 0, beattack: 0, score: 0 };
  const all = db.prepare(`SELECT uid FROM war WHERE server_id=? AND day=? AND country=? ORDER BY ${col} DESC, score DESC`).all(pl.server_id, day(), pl.country);
  const users = rows.map((r, i) => `<user>${el('rank', i + 1)}${el('uid', r.uid)}${el('nick', String(r.nick).replace(/[<>&]/g, ''))}${el('realval', r.val)}${el('countryid', c)}</user>`).join('');
  return `<userrank myscorecount="${mine[col] || 0}" myrank="${all.findIndex((r) => r.uid === pl.uid) + 1}" myscore="${mine.score || 0}"><userlist>${users}</userlist></userrank>`;
}
function countryKills(db, sid, c) {
  return (db.prepare('SELECT SUM(kills) n FROM war WHERE server_id=? AND day=? AND country=?').get(sid, day(), c).n) || 0;
}
function power(db, uid, sid) { const t = game.teamStats(db, uid, sid).total; return Math.round((t.al + t.ah + t.dl + t.dh) / 2); }

function infoXml(db, pl) {
  const m = me(db, pl), props = game.propCounts(db, pl.uid, pl.server_id);
  const rank = db.prepare('SELECT COUNT(*)+1 n FROM war WHERE server_id=? AND day=? AND score>?').get(pl.server_id, day(), m.score).n;
  const midnight = (() => { const m = new Date(); m.setHours(24, 0, 0, 0); return Math.round((m - Date.now()) / 1000); })();
  const opp = enemies(pl.country);
  const allies = `<allicountry><allicountryid>${pl.country}</allicountryid></allicountry>`;
  const opps = `<oppecountry>${opp.map((c) => `<oppecountryid>${c}</oppecountryid>`).join('')}</oppecountry>`;
  return `<preview resttime="0" open="1" myCountryID="${pl.country}" fightlefttime="${cdLeft(m)}" curintercost="${CD_CLEAR}">${allies}${opps}</preview>` + allies + opps +
    // "war exploit" on this screen and "own score" in the exploit shop (CScoreShopView) are <curpower>: the exploit to spend (prop 9994,
    // what war.exchange charges). It held the team power until 3 Nov 2026, so the shop looked affordable and refused every exchange.
    '<user>' + el('maxalive', MAX_ALIVE) + el('restalive', m.alive) + el('totlepower', props[9993] || props[9994] || 0) + el('curpower', props[9994] || 0) + el('thistimepowe', props[9994] || 0) +
    el('score', m.score) + el('scorerank', rank) + el('killnum', m.kills) + el('rank', rank) + el('beattack', m.beattack) + el('beattackrank', 0) +
    el('beattackmerit', 0) + el('autowar', m.auto ? 1 : 0) + '</user>' +
    `<country><my killnum="${countryKills(db, pl.server_id, pl.country)}"/><he killnum="${opp.reduce((a, c) => a + countryKills(db, pl.server_id, c), 0)}"/></country>` +
    '<autoinfo>' + el('auto_cost1', AUTO_COST) + el('auto_cost2', AUTO_EXTRA[2][0]) + el('auto_cost3', AUTO_EXTRA[3][0]) + el('auto_times2', AUTO_EXTRA[2][1]) + el('auto_times3', AUTO_EXTRA[3][1]) + '</autoinfo>';
}
function attack(db, pl) {
  const m = me(db, pl);
  if (m.alive <= 0) return m.auto ? { code: AUTO_STOP } : { error: 'no lives left, revive or wait until tomorrow' };
  if (cdLeft(m) > 0) {
    if (!(m.auto && m.clears > 0)) return { error: 'cooling down, try again later' };
    db.prepare('UPDATE war SET cd_until=0, clears=clears-1 WHERE server_id=? AND day=? AND uid=?').run(pl.server_id, day(), pl.uid); // Auto-Attack's paid clear
  }
  // every attack counts toward the cooldown; the 3rd starts the wait
  const streak = (m.streak || 0) + 1;
  db.prepare('UPDATE war SET streak=?, cd_until=CASE WHEN ? THEN ? ELSE cd_until END, last_attack=? WHERE server_id=? AND day=? AND uid=?')
    .run(streak >= CD_AFTER ? 0 : streak, streak >= CD_AFTER ? 1 : 0, now() + CD_SECS, now(), pl.server_id, day(), pl.uid);
  const opp = enemies(pl.country);
  const foe = db.prepare(`SELECT * FROM players WHERE server_id=? AND country IN (${opp.join(',')}) ORDER BY RANDOM() LIMIT 1`).get(pl.server_id);
  const mine = power(db, pl.uid, pl.server_id);
  const theirs = foe ? power(db, foe.uid, pl.server_id) : Math.round(mine * (0.6 + Math.random() * 0.6)); // guard bot when nobody is there
  const win = mine * (0.8 + Math.random() * 0.4) >= theirs;
  // ORIGINAL (Facebook photos 1307, 2315): a win (kill) = 10 points + 10 exploit (W.A.), EXP +36, silver +36; when an attacker fails,
  // the player they attacked gets 2 points + 2 exploit. (ours): a failed attack gives the attacker nothing.
  const score = win ? 10 : 0;
  if (win) game.propAdd(db, pl.uid, pl.server_id, 9994, 10); // war exploit for the Reward shop
  db.prepare('UPDATE war SET score=score+?, kills=kills+?, alive=alive-? WHERE server_id=? AND day=? AND uid=?')
    .run(score, win ? 1 : 0, win ? 0 : 1, pl.server_id, day(), pl.uid);
  if (foe && win) { me(db, foe); db.prepare('UPDATE war SET beattack=beattack+1 WHERE server_id=? AND day=? AND uid=?').run(pl.server_id, day(), foe.uid); }
  if (foe && !win) { // the defender held: 2 points + 2 exploit to them
    me(db, foe);
    db.prepare('UPDATE war SET score=score+2 WHERE server_id=? AND day=? AND uid=?').run(pl.server_id, day(), foe.uid);
    game.propAdd(db, foe.uid, pl.server_id, 9994, 2);
  }
  db.prepare('INSERT INTO war_log(server_id,uid,tuid,fromnick,tonick,fromcountry,tocountry,win,score) VALUES(?,?,?,?,?,?,?,?,?)')
    .run(pl.server_id, pl.uid, foe ? foe.uid : 0, pl.nick, foe ? foe.nick : 'Country Guard', pl.country, foe ? foe.country : opp[0], win ? 1 : 0, score);
  const coin = win ? 36 : 0, exp = win ? 36 : 0;
  db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(coin, pl.uid, pl.server_id);
  if (exp) game.addExp(db, db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id), exp);
  const guard = 1 + Math.floor(Math.random() * 400); // a guard bot: a random base ninja of the player's country's foes
  const gid = foe ? 0 : (Array.from(game.ninjas().values()).filter((r) => r[4] === 1 && r[11] >= 4)[guard % 200] || [21])[0];
  const fight = game.battleXml(db, pl, 1, 1, { enemyIds: game.foeTeam(db, foe ? foe.uid : 9000000 + guard, pl.server_id, foe ? 0 : gid, foe ? foe.level : pl.level, 0, game.teamStats(db, pl.uid, pl.server_id).slots.length), ratio: theirs / Math.max(1, mine), win, enemyName: foe ? foe.nick : 'Country Guard', enemyUid: foe ? foe.uid : 0, enemyLevel: foe ? foe.level : pl.level, enemyCountry: foe ? foe.country : undefined });
  game.bumpTask(db, pl.uid, pl.server_id, 10); // daily task: join today's war
  // CWarInfoView reads only batter= from <CountryWar>; InitFromXML takes the ROOT, so userinfo/fight/award are root children.
  // resttime = war time left (the auto-attacker stops at 0); our war runs until midnight
  return { xml: `<CountryWar batter="${win ? 1 : 0}" resttime="${toMidnight()}"/><userinfo><LastSPUpdatePastTime>0</LastSPUpdatePastTime></userinfo>${fight}${game.awardFull({ coin, exp })}` };
}
// buying 10 revives costs 30 gold (normalconfig 15 / 17)
function revive(db, pl, cost = 30) {
  if (pl.gold < cost) return { error: 'not enough gold' };
  me(db, pl);
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE war SET alive=? WHERE server_id=? AND day=? AND uid=?').run(MAX_ALIVE, pl.server_id, day(), pl.uid);
  return { xml: '' };
}

// Cmd 4104: clear the attack cooldown for 30 gold (normalconfig 22); the client reads <preview cost_cash> and takes that gold off.
function clearCd(db, pl) {
  const m = me(db, pl);
  if (cdLeft(m) <= 0) return { xml: '<preview cost_cash="0"/>' };
  if (pl.gold < CD_CLEAR) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(CD_CLEAR, pl.uid, pl.server_id);
  db.prepare('UPDATE war SET cd_until=0, streak=0 WHERE server_id=? AND day=? AND uid=?').run(pl.server_id, day(), pl.uid);
  return { xml: `<preview cost_cash="${CD_CLEAR}"/>` };
}
// Cmd 4103 AutoType 1-3: buy today's Auto-Attack (see AUTO_COST). The client reads <preview cost_cash>, takes that gold off and turns
// its auto-attacker on.
function buyAuto(db, pl, type) {
  const t = AUTO_EXTRA[type] ? type : 1;
  const m = me(db, pl);
  if (m.auto) return { error: 'already bought today' };
  if (m.alive <= 0) return { error: 'no lives left, revive or wait until tomorrow' };
  const cost = AUTO_COST + AUTO_EXTRA[t][0];
  if (pl.gold < cost) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  db.prepare('UPDATE war SET auto=?, clears=? WHERE server_id=? AND day=? AND uid=?').run(t, AUTO_EXTRA[t][1], pl.server_id, day(), pl.uid);
  return { xml: `<preview cost_cash="${cost}"/>` };
}
// Offline Auto-Attack ("still work if offline"): every 20 s, one attack for each of today's Auto-Attack players who has lives, is not
// cooling down (or has a paid clear left) and has not attacked for 30 s (so not while the game itself is attacking for them).
function autoTick(db) {
  ensure(db);
  const t = now();
  const rows = db.prepare('SELECT * FROM war WHERE day=? AND auto>0 AND alive>0 AND last_attack<? AND (cd_until<=? OR clears>0)').all(day(), t - 30, t);
  for (const w of rows) {
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(w.uid, w.server_id);
    if (!pl) continue;
    try { attack(db, pl); } catch (e) { console.error('auto war:', e.message); }
  }
  return rows.length;
}
function startAuto(db) { setInterval(() => { try { autoTick(db); } catch (e) { console.error('auto war tick:', e.message); } }, 20000).unref(); }

function resultXml(db, pl) {
  // <lastres><open>1</open> would pop yesterday's result dialog; there is no nightly war here, so keep it closed.
  const opp = enemies(pl.country);
  return '<winpace>' + el('canrequire', 0) + '</winpace><lastres>' + el('open', 0) + el('mycountrykill', countryKills(db, pl.server_id, pl.country)) +
    el('oppecountrykill', opp.reduce((a, c) => a + countryKills(db, pl.server_id, c), 0)) + '</lastres>' +
    `<allicountry><allicountryid>${pl.country}</allicountryid></allicountry><oppecountry>${opp.map((c) => `<oppecountryid>${c}</oppecountryid>`).join('')}</oppecountry>`;
}

// Scrolling war news (Cmd 7700, everyone) and my own fights (Cmd 7701). Children are text elements.
// <powernum> is the exploit in "get N points and N exploit" (CCountryWarDescTable::AddMessageFromXML): a win gives 10 (see attack), was always 0.
function msgXml(db, pl, mine) {
  ensure(db);
  const rows = mine
    ? db.prepare('SELECT * FROM war_log WHERE server_id=? AND (uid=? OR tuid=?) ORDER BY id DESC LIMIT 20').all(pl.server_id, pl.uid, pl.uid)
    : db.prepare('SELECT * FROM war_log WHERE server_id=? ORDER BY id DESC LIMIT 20').all(pl.server_id);
  const esc = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const items = rows.map((r) => '<warmsg>' + el('id', r.id) + el('fromnick', esc(r.fromnick)) + el('tonick', esc(r.tonick)) + el('fromcountry', r.fromcountry) +
    el('tocountry', r.tocountry) + el('killnum', r.win) + el('fromofficer', 0) + el('toofficer', 0) + el('msgtype', 1) + el('iswin', r.win) +
    el('score', r.score) + el('powernum', r.win ? 10 : 0) + '</warmsg>').join('');
  return mine ? `<usermsglist>${items}</usermsglist>` : `<warmsglist>${items}</warmsglist>`;
}

// War exploit shop (Reward tab): warconfig rows of type 2 = [id, id, name, 2, slot, cost, dropid]. Exploit = players.meritscore (prop 9994).
function exchange(db, pl, packId) {
  const row = game.table('warconfig').rows.find((r) => r[0] === packId && r[3] === 2);
  if (!row) return { error: 'bad pack' };
  const have = game.propCounts(db, pl.uid, pl.server_id)[9994] || 0;
  if (have < row[5]) return { error: 'not enough exploit' };
  game.propAdd(db, pl.uid, pl.server_id, 9994, -row[5]);
  return { xml: game.grantDrop(db, pl, row[6]) };
}

module.exports = { progressXml, ensure, exchange, msgXml, resultXml, infoXml, attack, revive, clearCd, buyAuto, autoTick, startAuto, AUTO_STOP, CD_AFTER, CD_SECS, CD_CLEAR, AUTO_COST };
