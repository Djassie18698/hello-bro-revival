// One handler per CGI. Each returns an XML string. Field names come from the client's own parser.
const crypto = require('crypto');
const game = require('./game');

const esc = (s) => String(s).replace(/[<>&]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;' }[c]));
const el = (name, v) => `<${name}>${esc(v)}</${name}>`;

// Public host the client should use for the game servers (set HOST to your LAN IP / domain).
const publicHost = (ctx) => process.env.HOST || ctx.host || 'localhost:18080';

const servers = (ctx) => [
  { id: 1, name: 'Konoha', domain: `http://${publicHost(ctx)}`, busy: 1, para1: 1062, para2: 2, payzoneid: 1 },
];
const serverXml = (s, tag) =>
  `<${tag}>` + Object.entries(s).map(([k, v]) => el(k, v)).join('') + `</${tag}>`;

// Private server: any Uin/Session pair is accepted. Unknown accounts (e.g. the saved id from the
// original game servers) are created on the fly and keep the session the client sent.
function accountBySession(db, p) {
  const uid = Number(p.Uin || p.Uid);
  if (!uid) return null;
  let acc = db.prepare('SELECT * FROM accounts WHERE uid=?').get(uid);
  if (!acc) {
    db.prepare('INSERT INTO accounts(uid,username,password,session) VALUES(?,?,?,?)').run(uid, 'guest' + uid, '', p.Session || '');
    acc = db.prepare('SELECT * FROM accounts WHERE uid=?').get(uid);
  } else if (p.Session && acc.session !== p.Session) {
    db.prepare('UPDATE accounts SET session=? WHERE uid=?').run(p.Session, uid);
    acc.session = p.Session;
  }
  return acc;
}


// Training stage fight: always a win for now; rewards come from roundinfo (cols: 22 energy cost, 23 exp, 24 coins).
function trainingFight(db, pl, chap, stage) {
  const row = game.table('roundinfo').rows.find((r) => r[0] === stage) || [];
  const cost = row[22] || 3, exp = row[23] || 6, coin = row[24] || 15;
  const lv = game.addExp(db, pl, exp);
  db.prepare('UPDATE players SET coin=coin+?, energy=MAX(0,energy-?) WHERE uid=? AND server_id=?').run(coin, cost, pl.uid, pl.server_id);
  game.setStage(db, pl.uid, pl.server_id, chap, stage + 1);
  game.bumpTask(db, pl.uid, pl.server_id, 1); game.bumpTask(db, pl.uid, pl.server_id, 2);
  const energy = Math.max(0, pl.energy - cost);
  const attrs = `curchapter="${chap}" curstage="${stage + 1}" pos="1" pos_time="0" pk_boss_times="0" curaction="${energy}" LastActionUpdatePastTime="0"`;
  return `<root code="0"><pve ${attrs}/><userinfo><LastSPUpdatePastTime>0</LastSPUpdatePastTime></userinfo>` + game.battleXml(db, pl, chap, stage) +
    game.awardFull({ coin, exp }) + '</root>';
}

module.exports = {
  // Server directory: server list + notices
  xk_r_dir: (ctx) =>
    `<root code="0"><way val="0"><val>0</val></way><noticeurl url=""/>` +
    `<serverlist>${servers(ctx).map((s) => serverXml(s, 'server')).join('')}</serverlist>` +
    `<noticelist><notice><id>1</id><display>1</display><title>Hello Bro is back!</title>` +
    `<content>Welcome back, ninja. Private revival server.</content></notice></noticelist></root>`,

  xk_w_dir: (ctx) => module.exports.xk_r_dir(ctx),

  // Account login. Unknown accounts are auto-created (like the old test servers).
  xk_w_login: ({ db, params: p, host, cgi, ...rest }) => {
    const name = p.UserName || p.Machine || p.MachineCheck || `guest${Date.now()}`;
    const pwd = p.Password || '';
    let acc = db.prepare('SELECT * FROM accounts WHERE username=?').get(name);
    if (!acc) {
      db.prepare('INSERT INTO accounts(username,password) VALUES(?,?)').run(name, pwd);
      acc = db.prepare('SELECT * FROM accounts WHERE username=?').get(name);
    } else if (pwd && acc.password && acc.password !== pwd) {
      return '<root code="2"><message>wrong password</message></root>';
    }
    const session = crypto.randomBytes(16).toString('hex').toUpperCase();
    db.prepare('UPDATE accounts SET session=? WHERE uid=?').run(session, acc.uid);
    return (
      `<root code="0"><login_info>${el('userid', acc.uid)}${el('session', session)}${el('username', acc.username)}</login_info>` +
      `<svrlist>${servers({ host }).map((s) => serverXml(s, 'svr')).join('')}</svrlist></root>`
    );
  },

  xk_w_reg: (ctx) => module.exports.xk_w_login(ctx),

  // Version / update check: nothing to update.
  rl_r_version: (ctx) => {
    // val is far below any real client version, so the client never asks for an update.
    const v = '<version val="0.0.1"><cdn>http://' + publicHost(ctx) + '/cdn/</cdn><filelist></filelist></version>';
    return '<root code="0"><updateversion>' + v + '<force>0</force><notice><content></content></notice></updateversion>' + v + '</root>';
  },

  // Activity / event badges (Lua side). Nothing running.
  rl_r_trackpoint: () => '<root code="0"><activity></activity><display>0</display></root>',

  // Client device report (analytics) - accept and ignore.
  rl_w_report: () => '<root code="0"></root>',

  // Enter a game server. hasreg=0 sends the client to character creation.
  rl_w_login2: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const pl = db.prepare('SELECT 1 FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    return (
      `<root code="0"><login_info>${el('hasreg', pl ? 1 : 0)}${el('userid', acc.uid)}${el('session', acc.session)}</login_info>` +
      `${el('first_login', pl ? 0 : 1)}</root>`
    );
  },

  rl_r_randname: () => `<root code="0"><randname>${el('name', 'Ninja' + Math.floor(Math.random() * 99999))}</randname></root>`,

  // Create a character.
  rl_w_reg2: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const sid = Number(p.ServerID || 1);
    db.prepare(
      'INSERT OR IGNORE INTO players(uid,server_id,nick,country,card,created) VALUES(?,?,?,?,?,?)'
    ).run(acc.uid, sid, p.Nick || `Ninja${acc.uid}`, Number(p.Country || 1), Number(p.Card || 1), Date.now());
    game.ensureStarterTeam(db, acc.uid, sid, Number(p.Card || 1));
    return `<root code="0"><login_info>${el('userid', acc.uid)}${el('session', acc.session)}</login_info></root>`;
  },

  // Main page / initial player data. Field names are the ones CPlayerDataMgr reads from <user>.
  rl_r_mainpage: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="4"><message>no character</message></root>';
    game.ensureStarterTeam(db, acc.uid, pl.server_id, 1);
    // Offline server: energy is refilled to the level's maximum on every login.
    const lvRow = game.table('playerlevel').rows.find((r) => r[1] === pl.level);
    if (lvRow && pl.energy < lvRow[4]) { db.prepare('UPDATE players SET energy=? WHERE uid=? AND server_id=?').run(lvRow[4], pl.uid, pl.server_id); pl.energy = lvRow[4]; }
    const gs = game.stateXml(db, acc.uid, pl.server_id);
    const f = { uid: acc.uid, nick: pl.nick, cash: pl.gold, coin: pl.coin, curaction: pl.energy, cursp: 10,
      level: pl.level, country: pl.country, maxteammember: 5, activeTeamId: 0,
      attactlow: gs.totals.al, attacthigh: gs.totals.ah, defenselow: gs.totals.dl, defensehigh: gs.totals.dh, chakralow: gs.totals.cl, chakrahigh: gs.totals.ch,
      caneat: 0, meritlevel: 0, meritscore: 0, warpower: 0, LastActionUpdatePastTime: 0, LastSPUpdatePastTime: 0,
      score: 0, viplevel: 0, soul: 0, totalm: 0 };
    return '<root code="0"><user>' + Object.entries(f).map(([k, v]) => el(k, v)).join('') + '</user>' + gs.cards +
      gs.suitlist + '<defensesuitlist></defensesuitlist><chipbag></chipbag>' +
      gs.ninjalist + '<defenseninjalist></defenseninjalist>' +
      '<chapinfo currentchap="1" currentstage="1"/></root>';
  },

  // Gacha status (free pulls / pity counters). Everything available, nothing to track yet.
  rl_r_recruit: () => '<root code="0"><recruit protect_comming="0" ninjaid="0" cost="0" bagid="0" attr="0"/></root>',

  // Gacha pull. Cmd 1901 = ten-pull, otherwise a single pull. Type = recruitinfo row (1 premium, 2 standard, 3 free).
  rl_w_recruit: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="4"><message>no character</message></root>';
    const count = Number(p.Cmd) === 1901 ? 10 : 1;
    const res = game.pull(db, pl, Number(p.Type || 2), count, Number(p.Free) === 1);
    if (res.error) return '<root code="5"><message>' + res.error + '</message></root>';
    return '<root code="0">' + game.pullXml(res, count) + '</root>';
  },

  // Spar / Plunder opponent lists.
  rl_r_pk: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    return '<root code="0">' + game.rivalsXml(db, pl) + '</root>';
  },

  // Spar fight against a rival (Cmd 2701, ToUid).
  rl_w_pvp: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    const r = game.sparFight(db, pl, Number(p.ToUid));
    game.addExp(db, pl, r.exp);
    db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(r.coin, pl.uid, pl.server_id);
    if (r.win) { game.bumpTask(db, pl.uid, pl.server_id, 6); }
    return '<root code="0"><userinfo><LastSPUpdatePastTime>0</LastSPUpdatePastTime></userinfo>' + r.xml + game.awardFull({ coin: r.coin, exp: r.exp }) + '</root>';
  },

  // Plunder / seal list (no seals yet) and country war status (no war running).
  rl_r_markchip: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT gold FROM players WHERE uid=?').get(acc.uid);
    return `<root code="0"><cash>${pl ? pl.gold : 0}</cash><chiplist></chiplist><markmerge></markmerge></root>`;
  },
  rl_r_warnew: ({ params: p }) =>
    Number(p.Cmd) === 7200 ? '<root code="0"><preview resttime="0" open="0"/></root>' : '<root code="0"><display>0</display></root>',
  rl_r_countrynew: () => '<root code="0"><display>0</display><pack><canget>0</canget><resttime>0</resttime></pack><resttime>0</resttime><officallist></officallist><decllist><has_decl>0</has_decl><allicountry></allicountry><oppecountry></oppecountry></decllist><timeinfo><begin>0</begin><end>0</end></timeinfo></root>',

  // Mailbox / notices (nothing yet), scrolling bulletin, activity list (no events), lucky wheel info.
  rl_r_msg: () => '<root code="0"><msglist></msglist></root>',
  rl_r_bulletin: () => {
    const now = Math.floor(Date.now() / 1000);
    return `<root code="0"><servertime>${now}</servertime><bulletinlist><bulletin><id>1</id><type>1</type><cycle>60</cycle><begintime>${now - 86400}</begintime><endtime>${now + 86400 * 3650}</endtime><content>Welcome back to Hello Bro! Offline revival server - have fun with your friends.</content></bulletin></bulletinlist></root>`;
  },
  rl_r_activity: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    return '<root code="0">' + game.actXml(db, pl) + '</root>';
  },
  rl_w_activity: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    const r = game.actClaim(db, pl, Number(p.ActID), Number(p.SubID));
    if (!r) return '<root code="5"><message>not available</message></root>';
    return '<root code="0">' + game.awardFull(r) + '</root>';
  },
  rl_r_wheel: () => '<root code="0"><info><bigcash>0</bigcash><jifeng>0</jifeng><lasttime>0</lasttime><per_jifeng>0</per_jifeng></info><award_list></award_list></root>',

  // Misc event-center screens with no content yet.
  rl_x_award_msg: () => '<root code="0"><expiry>7</expiry><msglist></msglist></root>',
  rl_r_paypack: () => '<root code="0"><payheaplist></payheaplist></root>',
  // Hall of fame: all real players ranked by level.
  rl_r_ninja_rank: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const all = db.prepare('SELECT uid,nick,country,level FROM players ORDER BY level DESC, uid').all();
    const me = all.findIndex((r) => acc && r.uid === acc.uid) + 1;
    const items = all.map((r, i) => `<item rank="${i + 1}" uid="${r.uid}" nick="${String(r.nick).replace(/[<>&"]/g, '')}" country="${r.country}" level="${r.level}" min_score="${r.level * 10}" max_score="${r.level * 20}"/>`).join('');
    return `<root code="0"><player><rank>${me || 1}</rank><min_score>10</min_score><max_score>20</max_score></player><rank_list>${items}</rank_list></root>`;
  },

  // Eight Gates (Dun) overview - numbers only, no upgrading yet.
  rl_w_eight_gate: () => '<root code="0"><basic><soul>0</soul><gate_level>0</gate_level><cost_soul>100</cost_soul><cost_coin>1000</cost_coin><gate_id id="1"></gate_id></basic><attribute><add_attack>0</add_attack><add_defense>0</add_defense><add_chakala>0</add_chakala><add_attack_per>0</add_attack_per><add_defense_per>0</add_defense_per><add_chakala_per>0</add_chakala_per></attribute></root>',

  // Shop purchase of a consumable (Goodsid, Count).
  rl_w_shopbuy: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    if (Number(p.Cmd) === 1701) {
      const r = game.packBuy(db, pl, Number(p.Packageid));
      if (r.error) return `<root code="5"><message>${r.error}</message></root>`;
      if (r.type !== 1) return `<root code="0"><shopbuy costyb="${r.costG}" costyz="${r.costS}"></shopbuy></root>`; // equipment: client crashes on the reveal dialog; cards show up after re-login
      return `<root code="0"><shopbuy costyb="${r.costG}" costyz="${r.costS}"><retobj type="${r.type}" id="${r.ninja}" count="${r.n}" bagid="${r.seq}" attr="${r.attrs}"/></shopbuy></root>`;
    }
    const cnt = Math.max(1, Math.min(999, Number(p.Count) || 1));
    const r = game.shopBuy(db, pl, Number(p.Goodsid), cnt);
    if (r.error) return `<root code="5"><message>${r.error}</message></root>`;
    return `<root code="0"><shopbuy costyb="${r.costG}" costyz="${r.costS}"><retobj type="2" id="${Number(p.Goodsid)}" count="${cnt}"/></shopbuy></root>`;
  },

  rl_w_propuse: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    const r = game.propUse(db, pl, Number(p.Goodsid));
    if (r.error) return `<root code="5"><message>${r.error}</message></root>`;
    return `<root code="0"><propuse ap="${r.ap}" sp="0" yinzi="${r.coin}" left="${r.left}" rest="0" max="0"/></root>`;
  },

  rl_w_strengthen: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    const eat = String(p.EATCardsBagIDList || '').split('|').map(Number).filter(Boolean);
    const r = game.strengthen(db, pl, Number(p.SRCBagID), eat);
    if (r.error) return `<root code="5"><message>${r.error}</message></root>`;
    return `<root code="0" eatexp="${r.exp}"></root>`;
  },

  // Team editing: Cmd 2301.. = equip card NewID into slot Seq (kind = Cmd - 2300).
  rl_w_ninjalist: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    const kind = Number(p.Cmd) - 2300;
    if (kind >= 1 && kind <= 8) game.equip(db, pl, Number(p.Seq), kind, Number(p.NewID) || 0);
    const gs = game.stateXml(db, pl.uid, pl.server_id);
    return `<root code="0"><teamid>${Number(p.TeamId) || 0}</teamid>${gs.suitlist}${gs.ninjalist}</root>`;
  },

  // Secret (soul) shop: Cmd 1 list, 2 refresh, 4 buy (Soul=row id), 5 soul value of cards.
  rl_x_mystery_shop: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    const pl = acc && db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, Number(p.ServerID || 1));
    if (!pl) return '<root code="3"><message>session expired</message></root>';
    const cmd = Number(p.Cmd);
    if (cmd === 4) {
      const r = game.secretBuy(db, pl, Number(p.Soul));
      if (r.error) return `<root code="5"><message>${r.error}</message></root>`;
      return '<root code="0">' + game.awardXml({ ninja: r.ninja, seq: r.seq }) + '</root>';
    }
    if (cmd === 5) return '<root code="0"><total_val>0</total_val><card_list></card_list></root>';
    return '<root code="0">' + game.secretXml(db, pl) + '</root>';
  },

  rl_r_group_comm: () => '<root code="0"></root>',

  // Daily tasks: Cmd 1 = list, Cmd 2 = claim an award (AwardID).
  rl_r_dailytask: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const sid = Number(p.ServerID || 1);
    if (Number(p.Cmd) === 2) {
      const pl = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, sid);
      const a = game.dailyClaim(db, pl, Number(p.AwardID));
      if (!a) return '<root code="5"><message>bad award</message></root>';
      return '<root code="0">' + game.awardFull({ coin: a.coin, cash: a.cash }) + '</root>';
    }
    return '<root code="0">' + game.dailyXml(db, acc.uid, sid) + '</root>';
  },

  // Training: open a chapter. Cmd 2 / ChapID -> which stages are open.
  rl_w_pve: ({ db, params: p }) => {
    const acc = accountBySession(db, p);
    if (!acc) return '<root code="3"><message>session expired</message></root>';
    const sid = Number(p.ServerID || 1);
    const pl0 = db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(acc.uid, sid);
    if (Number(p.Cmd) === 3) return trainingFight(db, pl0, Number(p.ChapID || 1), Number(p.StageID || 1));
    const cur = game.getStage(db, acc.uid, sid, Number(p.ChapID || 1));
    let stages = '';
    for (let i = 1; i <= cur; i++) stages += `<stage stageid="${i}" pos="1" pos_time="0" pk_boss_times="0"/>`;
    return `<root code="0"><preview currentstage="${cur}" laststage="${cur}"/><stagelist>${stages}</stagelist><expbuf addrate="0" exp_time="0"/></root>`;
  },

  // Shop. Cmd 1600 = gift packs, 1601 = goods. An EMPTY list crashes the client, so always send >= 1 entry.
  rl_r_shoplist: ({ db, params: p }) => {
    const shopOwned = (q) => { const a = accountBySession(db, q); return a ? game.propCounts(db, a.uid, Number(q.ServerID || 1)) : {}; };
    const recruits = [
      { recruit_id: 1, recruit_yuanbao: 300, recruit_time: 0, last_recruit_time: 0, first_yuanbao: 0, free_recruit_time_left: 0, recruit_limit: 0, cur_recruit_count: 0 },
      { recruit_id: 2, recruit_yuanbao: 150, recruit_time: 0, last_recruit_time: 0, first_yuanbao: 0, free_recruit_time_left: 0, recruit_limit: 0, cur_recruit_count: 0 },
      { recruit_id: 3, recruit_yuanbao: 0, recruit_time: 86400, last_recruit_time: 0, first_yuanbao: 0, free_recruit_time_left: 0, recruit_limit: 0, cur_recruit_count: 0 },
    ];
    const rows = (tag, list) => list.map((o) => `<${tag}>` + Object.entries(o).map(([k, v]) => el(k, v)).join('') + `</${tag}>`).join('');
    const esc = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    const n = (v) => Math.round(Number(v) || 0);
    if (Number(p.Cmd) === 1600) {
      const packs = game.table('giftinfo').rows.map((r, k) => ({
        package_id: r[0], package_name: esc(r[2]), package_icon: r[3], package_yuanbao: r[4], package_yinzi: r[5], package_show: 1,
        package_function: r[7], package_function_value1: n(r[8]), package_function_value2: n(r[9]), package_function_value3: n(r[10]), package_function_value4: n(r[11]),
      }));
      return '<root code="0"><shoplist>' + rows('packages', packs) + rows('recruit', recruits) + '</shoplist></root>';
    }
    const owned = shopOwned(p);
    const goods = game.table('consumeinfo').rows.filter((r) => r[4] > 0 || r[5] > 0).map((r, k) => ({
      propid: r[0], prop_name: esc(r[2]), prop_icon: r[3], prop_yuanbao: r[4], prop_yinzi: r[5], prop_show: 1, prop_function: r[7],
      prop_function_value1: n(r[8]), prop_function_value2: n(r[9]), prop_function_value3: n(r[10]), prop_function_value4: n(r[11]), bagnum: owned[r[1]] || 0, prop_order: k + 1,
    }));
    return '<root code="0"><shoplist>' + rows('goods', goods) + rows('recruit', recruits) + '<limit><actiongoods><total>0</total><rest>0</rest></actiongoods><bingliangwan><total>0</total><rest>0</rest></bingliangwan></limit></shoplist></root>';
  },
};
