// Full progress tracker for chosen accounts (owner, 10 Nov 2026: DEAN, uid 7, played from a reset like a normal player with at most
// $100 of free top-ups a day, to judge whether the game feels fun, too fast or too slow). Switched on per account: the setting
// "track_uids" (control panel > Tracker) or, when that was never set, HB_TRACK_UIDS=7,12 (tools/vps/run.sh). Nothing else is touched.
//
// How it works, without changing any game behaviour: server.js calls begin() before and end() after every game request of a tracked
// account. begin() takes a snapshot of every row the save holds for that account (every table with a uid column), end() takes another
// one and logs the differences, labelled with what the request was (campaign stage, recruit, shop ...). Differences that happened between
// two requests (the item page, Award Center mail being sent, an event paying out) are logged as "outside the game". game.battleXml and
// game.grantDrop add the fight results and the drop packs. Team attack / defence is recomputed after every request that changed something.
// Rows go to track_log (one per fact) and track_time (requests per minute = time played). resetPlayer keeps them and adds a "reset" row.
const game = require('./game');

const now = () => Math.floor(Date.now() / 1000);
function ensure(db) {
  try { db.exec(`CREATE TABLE IF NOT EXISTS track_log (id INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, sid INTEGER, at INTEGER, req INTEGER,
      src TEXT, kind TEXT, key TEXT, delta INTEGER, value INTEGER, detail TEXT);
    CREATE INDEX IF NOT EXISTS track_log_who ON track_log(uid, sid, at);
    CREATE TABLE IF NOT EXISTS track_time (uid INTEGER, sid INTEGER, minute INTEGER, n INTEGER, PRIMARY KEY(uid, sid, minute));
    CREATE TABLE IF NOT EXISTS drop_stats (day TEXT, src TEXT, kind TEXT, key TEXT, name TEXT, times INTEGER, amount INTEGER, PRIMARY KEY(day, src, kind, key));`); } catch { /* a read-only save (tools/dev/track.js): the tables are there or there is nothing to read */ }
}

// ---- which accounts --------------------------------------------------------------------------------------------------------
let cache = { at: 0, set: new Set() };
function uids(db) {
  if (Date.now() - cache.at < 5000) return cache.set;
  let list = null;
  try { list = require('./settings').get(db, 'track_uids', null); } catch {}
  if (list == null) list = String(process.env.HB_TRACK_UIDS || '').split(/[ ,]+/);
  cache = { at: Date.now(), set: new Set([].concat(list).map(Number).filter((n) => n > 0)) };
  return cache.set;
}
function setUids(db, list) {
  const clean = [...new Set([].concat(list).map(Number).filter((n) => n > 0))];
  require('./settings').set(db, 'track_uids', clean);
  cache.at = 0;
  return clean;
}
const tracked = (db, uid) => uids(db).has(Number(uid));

// ---- snapshots -------------------------------------------------------------------------------------------------------------
// Tables left out: logins and passwords, logs that only grow (ours and others'), and things the account does not own.
const SKIP = new Set(['accounts', 'logins', 'player_log', 'track_log', 'track_time', 'drop_stats', 'web_online', 'gold_spent', 'meta', 'server_settings']);
const QUIET = { players: new Set(['energy_t', 'sp_t']) }; // timers that move on every request: not worth a line
let tableCache = { at: 0, list: [] };
function tables(db) {
  if (Date.now() - tableCache.at < 60000) return tableCache.list; // modules create their tables on first use
  const list = [];
  for (const { name } of db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").all()) {
    if (SKIP.has(name)) continue;
    const cols = db.prepare(`PRAGMA table_info("${name}")`).all();
    if (!cols.some((c) => c.name === 'uid')) continue;
    const pk = cols.filter((c) => c.pk).sort((a, b) => a.pk - b.pk).map((c) => c.name);
    list.push({ name, pk, cols: cols.map((c) => c.name), stmt: db.prepare(`SELECT * FROM "${name}" WHERE uid=?`) });
  }
  tableCache = { at: Date.now(), list };
  return list;
}
function snapshot(db, uid) {
  const out = {};
  for (const t of tables(db)) {
    const m = new Map();
    for (const r of t.stmt.all(uid)) m.set(t.pk.length ? t.pk.map((k) => r[k]).join('|') : JSON.stringify(r), r);
    out[t.name] = m;
  }
  return out;
}
// raw differences: [{table, key, before, after}]
function diff(a, b) {
  const out = [];
  for (const name of new Set([...Object.keys(a), ...Object.keys(b)])) {
    if (name === 'at') continue; // when the snapshot was taken, not a table
    const x = a[name] || new Map(), y = b[name] || new Map();
    for (const [k, r] of y) {
      const o = x.get(k);
      if (!o) out.push({ table: name, key: k, before: null, after: r });
      else {
        const q = QUIET[name];
        if (Object.keys(r).some((c) => r[c] !== o[c] && !(q && q.has(c)))) out.push({ table: name, key: k, before: o, after: r });
      }
    }
    for (const [k, o] of x) if (!y.has(k)) out.push({ table: name, key: k, before: o, after: null });
  }
  return out;
}

// ---- names -------------------------------------------------------------------------------------------------------------------
const KIND = { 1: 'Shinobi', 2: 'Weapon', 3: 'Armor', 4: 'Trinket', 5: 'Seal', 6: 'Ninjutsu' };
const rowOf = (tbl, id, col = 0) => game.table(tbl).rows.find((r) => r[col] === id) || [];
function cardInfo(type, id) {
  if (type === 1) { const r = game.ninjas().get(id) || []; return { name: r[2] || '#' + id, stars: r[11] || 0 }; }
  if (type >= 2 && type <= 4) { const r = rowOf('equipmentinfo', id); return { name: r[2] || '#' + id, stars: r[6] || 0 }; }
  if (type === 5) { const r = rowOf('markinfo', id); return { name: r[2] || '#' + id, stars: r[6] || 0 }; }
  if (type === 6) { const r = rowOf('ninjutsuinfo', id); return { name: r[2] || '#' + id, stars: r[5] || 0 }; }
  return { name: '#' + id, stars: 0 };
}
const PROP = { 9999: 'Ninja souls', 9998: 'Gate souls', 9997: 'Eight Gates level', 9996: 'Arena reputation', 9995: 'Boss reputation', 9994: 'War merit' };
function propName(id) {
  if (PROP[id]) return PROP[id];
  if (id >= 20000 && id < game.CHIP_BASE) return (rowOf('markinfo', id - 20000)[2] || '#' + (id - 20000)) + ' seal fragment';
  if (id >= game.CHIP_BASE) return (rowOf('piece_info', id - game.CHIP_BASE)[2] || '#' + id) + ' fragment';
  return rowOf('consumeinfo', id, 1)[2] || 'Item #' + id;
}

// What a request was, in plain words (the "source" of everything it changed).
const LABEL = {
  rl_w_pve: 'Campaign', rl_w_dup: 'Tower', rl_w_sport: 'Arena', rl_x_sport_ext: 'Arena', rl_w_sportpack: 'Arena shop', rl_w_pvp: 'Spar',
  rl_w_recruit: 'Recruit', rl_x_free_topup: 'Top-up', rl_w_ky_payorder: 'Top-up', rl_w_notify_gp: 'Top-up', rl_got: 'Top-up',
  rl_w_shopbuy: 'Shop', rl_x_mystery_shop: 'Secret shop', rl_w_vipshopbuy: 'VIP shop', rl_w_paypack: 'Pay pack', rl_x_award_msg: 'Award Center / border war',
  rl_w_strengthen: 'Upgrade', rl_x_develop: 'Develop / god card', rl_w_newlife: 'Rebirth', rl_x_breakthrough: 'Breakthrough', rl_w_star: 'Sage growth',
  rl_w_ninjalist: 'Team / gear change', rl_r_ninjalist: 'Team screen', rl_x_pet: 'Pets', rl_x_exam: 'Ninja Test', rl_w_eight_gate: 'Eight Gates',
  rl_w_ramen: 'Free ramen', rl_w_propuse: 'Use item', rl_w_comm: 'Backpack / events', rl_r_comm: 'Backpack / events', rl_w_activity: 'Event reward',
  rl_r_activity: 'Events screen', rl_x_small_activity: 'Event', rl_w_wheel: 'Lucky Wheel', rl_w_wheel_gift: 'Lucky Wheel', rl_w_lottery: 'Lottery',
  rl_w_monopoly_roll: 'Millionaire', rl_w_monopoly_receive: 'Millionaire', rl_w_sudoku: 'Ninja Treasure', rl_w_tear: 'National treasure',
  rl_w_tearcountry: 'National treasure', rl_w_tearguard: 'National treasure', rl_w_warnew: 'Country war', rl_w_warresultnew: 'Country war',
  rl_w_countrynew: 'Country officials', rl_w_cwar: 'Cross-server battle', rl_w_cwar_war: 'Cross-server battle', rl_w_cross_war: 'Cross-server battle',
  rl_w_markchip: 'Seals / plunder', rl_r_markchip: 'Seals / plunder', rl_w_guaguale: 'Scratch card', rl_w_mtree: 'Money tree', rl_w_xiao: 'Akatsuki',
  rl_w_xiao_war: 'Akatsuki war', rl_w_group_admin: 'Akatsuki', rl_w_friend: 'Friends', rl_w_msg: 'Messages', rl_w_invitecode: 'Invite code',
  rl_w_dailycost: 'Daily spending gift', rl_r_dailytask: 'Daily tasks', rl_w_adventure: 'Adventure', rl_r_adventure: 'Adventure',
  rl_r_mainpage: 'Home', rl_w_login2: 'Login', rl_w_reg2: 'New character', rl_r_recruit: 'Recruit screen', rl_r_shoplist: 'Shop / backpack',
  rl_r_savetime: 'Save time', rl_r_newbie_pay: 'Newbie gift', rl_r_pay_cumula: 'Total top-up gift', rl_r_lottery: 'Lottery', rl_r_wheel: 'Lucky Wheel', rl_r_vipshop: 'VIP shop', rl_r_paypack: 'Pay pack', rl_r_monopoly_info: 'Millionaire', rl_r_sudoku: 'Ninja Treasure', rl_r_mtree: 'Money tree', rl_r_sport: 'Arena', rl_r_dup: 'Tower', rl_r_tear: 'National treasure', rl_r_boss: 'World boss', rl_r_frontiers_war_attack: 'Border war', rl_r_frontiers_war_recv_award: 'Border war', rl_r_frontiers_war_clear: 'Border war',
};
// endpoints that do many different things: the Cmd number is kept in the label so they can be told apart
const BY_CMD = new Set(['rl_w_comm', 'rl_r_comm', 'rl_x_small_activity', 'rl_w_activity', 'rl_x_award_msg', 'rl_x_pet', 'rl_x_develop', 'rl_w_ninjalist', 'rl_r_shoplist']);
function label(cgi, p = {}) {
  const cmd = p.Cmd;
  if (cgi === 'rl_w_recruit') return Number(cmd) === 1902 || (Number(p.Type) === 1 && Number(p.Free) !== 1 && Number(p.IsSuperAct) === 1) ? 'Recruit: Super Ninja'
    : Number(p.Free) === 1 ? 'Recruit: free' : Number(cmd) === 1901 ? 'Recruit: 10 pulls' : 'Recruit';
  if (cgi === 'rl_w_pve' && Number(cmd) === 3) return 'Campaign';
  return (LABEL[cgi] || cgi) + (!LABEL[cgi] || BY_CMD.has(cgi) ? (cmd !== undefined && cmd !== '' ? ` #${cmd}` : '') : '');
}
const fightKind = (cgi, chap, stage) => {
  if (cgi === 'rl_w_pve') return (game.stageRow(chap, stage) || [])[38] ? 'boss' : 'stage';
  return { rl_w_dup: 'tower', rl_w_sport: 'arena', rl_x_sport_ext: 'arena', rl_w_pvp: 'spar', rl_x_exam: 'ninja test' }[cgi] || 'other';
};
const OUTSIDE = 'Outside the game (event payout, server)';
const PANEL = 'Item page / control panel';

// ---- the request context -------------------------------------------------------------------------------------------------------
const last = new Map(); // uid -> snapshot after its last request (memory only: after a restart the first request starts a new baseline)
let ctx = null, reqNo = 0, panelAt = 0;
function power(db, uid, sid) {
  try { const t = game.teamStats(db, uid, sid).total; return { atk: Math.round((t.al + t.ah) / 2), def: Math.round((t.dl + t.dh) / 2) }; } catch { return null; }
}
function write(db, uid, sid, src, rows) {
  if (!rows.length) return;
  const st = db.prepare('INSERT INTO track_log(uid,sid,at,req,src,kind,key,delta,value,detail) VALUES(?,?,?,?,?,?,?,?,?,?)');
  const at = now(), rq = reqNo = Math.max(reqNo + 1, Date.now()); // one number per request, unique across restarts
  for (const r of rows) st.run(uid, sid, at, rq, r.src || src, r.kind, r.key == null ? null : String(r.key), r.delta ?? null, r.value ?? null, r.detail == null ? null : String(r.detail));
}
function lastPower(db, uid, sid) { // since the last reset
  return db.prepare("SELECT value, detail FROM track_log WHERE uid=? AND sid=? AND kind IN ('power','baseline') AND value IS NOT NULL AND id > (SELECT COALESCE(MAX(id), 0) FROM track_log WHERE uid=? AND sid=? AND kind='reset') ORDER BY id DESC LIMIT 1").get(uid, sid, uid, sid);
}
// Energy that came by itself (game.energyTick: the 22:00 refill and 1 point per 180 s; game.addExp: a level-up refill) gets its own source,
// so the request that happened to notice it is only charged for what it really gave or cost.
const REFILL = { 22: 'Energy: 22:00 refill', time: 'Energy: refills over time', level: 'Energy: level-up refill' };
const REFILL_SRC = new Set(Object.values(REFILL));
function splitEnergy(rows, c) {
  const i = rows.findIndex((r) => r.kind === 'energy' && !r.src);
  const parts = Object.entries((c && c.refill) || {}).filter(([, n]) => n > 0);
  if (!parts.length) return rows;
  const total = i >= 0 ? rows[i].delta : 0, value = i >= 0 ? rows[i].value : null;
  const out = rows.filter((r, k) => k !== i);
  let rest = total;
  for (const [k, n] of parts) { out.push({ kind: 'energy', src: REFILL[k], delta: n, value }); rest -= n; }
  if (rest) out.push({ kind: 'energy', delta: rest, value });
  return out;
}

// Turn raw differences into facts: gold / silver / energy, cards gained, items, levels, stages, top-ups, other changes.
function facts(d, sid, c, snaps) {
  const out = [];
  const why = [];
  const arena = { from: null, to: null };
  for (const ch of d) {
    const a = ch.before, b = ch.after;
    if ((a && a.server_id !== undefined && a.server_id !== sid) || (b && b.server_id !== undefined && b.server_id !== sid)) continue; // other world
    if (ch.table === 'players' && a && b) {
      for (const [col, kind] of [['gold', 'gold'], ['coin', 'silver'], ['energy', 'energy']]) {
        if (a[col] !== b[col] && b[col] !== undefined) out.push({ kind, delta: b[col] - a[col], value: b[col] });
      }
      // exp: the save keeps only the exp inside the current level; game.addExp tells how much was really gained
      const gained = c && c.exp ? c.exp : (b.level === a.level ? b.exp - a.exp : 0);
      if (gained) out.push({ kind: 'exp', delta: gained, value: b.exp, detail: `level ${b.level}` });
      if (a.sp !== b.sp && a.sp >= 0 && b.sp >= 0) out.push({ kind: 'stamina', delta: b.sp - a.sp, value: b.sp }); // -1 = full
      if (b.level !== a.level) { out.push({ kind: 'level', delta: b.level - a.level, value: b.level }); why.push('level ' + b.level); }
      if (b.active_team !== a.active_team) why.push('team switch');
      const KNOWN = new Set(['gold', 'coin', 'energy', 'exp', 'sp', 'level', 'energy_t', 'sp_t']);
      const rest = Object.keys(b).filter((k) => !KNOWN.has(k) && a[k] !== b[k]).map((k) => `${k} ${a[k]}→${b[k]}`);
      if (rest.length) out.push({ kind: 'change', key: 'players', detail: rest.join(', ') });
      continue;
    }
    if (ch.table === 'players') { out.push({ kind: 'change', key: 'players', detail: b ? 'character made: ' + b.nick : 'character deleted' }); continue; }
    if (ch.table === 'vipstate') {
      const lv0 = a ? a.level : 0, lv1 = b ? b.level : 0, e0 = a ? a.exp : 0, e1 = b ? b.exp : 0;
      if (e1 !== e0) out.push({ kind: 'vipexp', delta: e1 - e0, value: e1 });
      if (lv1 !== lv0) { out.push({ kind: 'vip', delta: lv1 - lv0, value: lv1 }); why.push('VIP ' + lv1); }
      continue;
    }
    if (ch.table === 'topup_log' && b && !a) { out.push({ kind: 'topup', delta: b.cents || 0, value: b.gold || 0, detail: `$${((b.cents || 0) / 100).toFixed(2)} -> ${b.gold || 0} gold` }); continue; }
    if (ch.table === 'arena') { if (a && !b) arena.from = a.rank; if (b && !a) arena.to = b.rank; continue; } // the ladder is keyed by rank
    if (ch.table === 'cards') {
      const r = b || a, info = cardInfo(r.type, r.ninja_id), nm = `${info.name}${info.stars ? ' ' + info.stars + '★' : ''}`;
      if (!a) { out.push({ kind: 'card+', key: `${r.type}:${r.ninja_id}`, value: info.stars, detail: `${KIND[r.type] || '?'}: ${nm}` }); why.push('new ' + nm); continue; }
      if (!b) { out.push({ kind: 'card-', key: `${r.type}:${r.ninja_id}`, value: info.stars, detail: `${KIND[r.type] || '?'}: ${nm} Lv ${a.level}` }); continue; }
      const cl = [];
      if (a.level !== b.level) cl.push(`Lv ${a.level}→${b.level}`);
      if (a.exp !== b.exp && a.level === b.level) cl.push(`exp ${a.exp}→${b.exp}`);
      if (a.starlevel !== b.starlevel) cl.push(`growth ${a.starlevel}→${b.starlevel}`);
      if (a.breaklvl !== b.breaklvl) cl.push(`breakthrough +${a.breaklvl || 0}→+${b.breaklvl || 0}`);
      if (a.newlife !== b.newlife) cl.push(`rebirth ${a.newlife || 0}→${b.newlife || 0}`);
      if (a.pot_att !== b.pot_att || a.pot_def !== b.pot_def || a.pot_ckr !== b.pot_ckr) cl.push(`potential ${a.pot_att || 0}/${a.pot_def || 0}/${a.pot_ckr || 0}→${b.pot_att || 0}/${b.pot_def || 0}/${b.pot_ckr || 0}`);
      if (a.pills_used !== b.pills_used) cl.push(`pills ${a.pills_used || 0}→${b.pills_used || 0}`);
      if (a.attri !== b.attri) cl.push('element');
      if (a.ninja_id !== b.ninja_id) cl.push('became ' + cardInfo(b.type, b.ninja_id).name);
      if (cl.length) { out.push({ kind: 'card~', key: `${r.type}:${r.ninja_id}`, value: b.level, detail: `${nm}: ${cl.join(', ')}` }); why.push(`${info.name} ${cl.join(', ')}`); }
      continue;
    }
    if (ch.table === 'props') {
      const r = b || a, n0 = a ? a.count : 0, n1 = b ? b.count : 0;
      if (n0 !== n1) { out.push({ kind: 'item', key: r.prop_id, delta: n1 - n0, value: n1, detail: propName(r.prop_id) }); if (r.prop_id === 9997) why.push(`Eight Gates level ${n0}→${n1}`); if (r.prop_id === 9994) why.push('war merit (title)'); }
      continue;
    }
    if (ch.table === 'pets') {
      const r = b || a, nm = rowOf('petinfo', r.pet_id)[2] || '#' + r.pet_id;
      if (!a) { out.push({ kind: 'card+', key: `pet:${r.pet_id}`, value: 0, detail: 'Pet: ' + nm }); why.push('new pet ' + nm); }
      else if (!b) out.push({ kind: 'card-', key: `pet:${r.pet_id}`, value: 0, detail: 'Pet: ' + nm });
      else { out.push({ kind: 'card~', key: `pet:${r.pet_id}`, value: b.level, detail: `Pet ${nm}: Lv ${a.level}→${b.level}, rank ${a.rank}→${b.rank}, star ${a.star}→${b.star}, train ${a.train}→${b.train}, slot ${a.slot}→${b.slot}` }); why.push('pet ' + nm); }
      continue;
    }
    if (ch.table === 'progress') {
      const r = b || a;
      if (b && (!a || b.stage > a.stage)) {
        const what = r.chap >= 100000 ? null : r.chap >= 1000 ? `Tower ${r.chap - 1000}, next round ${b.stage}` : `Chapter ${r.chap}, next stage ${b.stage}`;
        if (what) out.push({ kind: 'reach', key: r.chap, value: b.stage, detail: what });
      }
      continue;
    }
    if (['team', 'team_alt', 'equipped', 'equipped_alt'].includes(ch.table)) {
      // what went where: "Team slot 2: Sakura Haruno 4★ Lv 5 → Itachi 6★ Lv 1", "Slot 1 weapon: - → Kusanagi 5★ Lv 3"
      const r = b || a, t2 = ch.table.endsWith('_alt') ? 'Team 2 ' : '';
      const was = cardText(snaps && snaps.a, a && a.seq), now = cardText(snaps && snaps.b, b && b.seq);
      const where = ch.table.startsWith('team') ? `${t2}team slot ${r.slot + 1}` : `${t2}slot ${r.slot} ${SLOT_KIND[r.kind] || 'kind ' + r.kind}`;
      if (was !== now) { const t = `${where}: ${was} → ${now}`; out.push({ kind: 'team', key: ch.table, detail: t }); why.push(t); }
      continue;
    }
    // anything else: one compact line per changed row
    const cols = a && b ? Object.keys(b).filter((k) => a[k] !== b[k]).map((k) => `${k} ${a[k]}→${b[k]}`).join(', ') : '';
    out.push({ kind: 'change', key: ch.table, detail: (a && b ? cols : (b ? 'added ' : 'removed ') + JSON.stringify(b || a)).slice(0, 300) });
  }
  if (arena.from !== null || arena.to !== null) out.push({ kind: 'rank', key: 'arena', delta: arena.from && arena.to ? arena.from - arena.to : null, value: arena.to, detail: `Arena rank ${arena.from ?? '-'} → ${arena.to ?? '-'}` });
  return { out, why };
}

function record(db, uid, sid, src, d, extra = [], c = null, snaps = null) {
  const { out, why } = facts(d, sid, c, snaps);
  const rows = splitEnergy([...extra, ...out], c);
  // power after anything that could move it, with the parts of it that moved (the website's "where the power comes from": card level,
  // rebirth, breakthrough, growth, training, gear, seals, ninjutsu, sets, chains, card sets, Eight Gates, title, pets)
  if (out.length) {
    const p = power(db, uid, sid), was = lastPower(db, uid, sid);
    if (p) {
      const wasDef = was ? (JSON.parse(was.detail || '{}').def || 0) : 0;
      if (!was || p.atk !== was.value || p.def !== wasDef) {
        const now = parts(db, uid, sid), before = lastParts.get(uid);
        lastParts.set(uid, now);
        const moved = before && now ? partDiff(before, now) : [];
        rows.push({ kind: 'power', delta: was ? p.atk - was.value : 0, value: p.atk, detail: JSON.stringify({ def: p.def, ddef: p.def - wasDef, why: why.slice(0, 12).join('; '), parts: moved }) });
      }
    }
  }
  write(db, uid, sid, src, rows);
}
// the power split into its parts (webapi.breakdown, the same maths as the team screen): { key: { label, atk, def } } with the middle of each range
const lastParts = new Map();
function parts(db, uid, sid) {
  try {
    const bd = require('./webapi').breakdown(db, uid, sid), out = {};
    for (const [side, list] of [['atk', bd.atk], ['def', bd.def]]) for (const x of list) { out[x.key] = out[x.key] || { label: x.label, atk: 0, def: 0 }; out[x.key][side] = Math.round((x.v[0] + x.v[1]) / 2); }
    return out;
  } catch { return null; }
}
function partDiff(a, b) {
  const out = [];
  for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
    const x = a[k] || { atk: 0, def: 0 }, y = b[k] || { atk: 0, def: 0 };
    const da = y.atk - x.atk, dd = y.def - x.def;
    if (da || dd) out.push({ part: (y.label || x.label), atk: da, def: dd });
  }
  return out.sort((p, q) => Math.abs(q.atk) + Math.abs(q.def) - Math.abs(p.atk) - Math.abs(p.def));
}
const SLOT_KIND = { 1: 'weapon', 2: 'armor', 3: 'trinket', 4: 'seal', 5: 'ninjutsu 1', 6: 'ninjutsu 2', 7: 'ninjutsu 3', 8: 'ninjutsu 4' };
function cardText(snap, seq) {
  if (!seq) return '-';
  const c = snap && snap.cards && snap.cards.get(String(seq));
  if (!c) return 'card #' + seq;
  const info = cardInfo(c.type, c.ninja_id);
  return `${info.name}${info.stars ? ' ' + info.stars + '★' : ''} Lv ${c.level}${c.breaklvl ? ' +' + c.breaklvl : ''}`;
}

function baseline(db, uid, sid, snap) {
  const pl = (snap.players || new Map()).get(`${uid}|${sid}`);
  if (!pl) return;
  const p = power(db, uid, sid) || { atk: 0, def: 0 };
  const cards = [...(snap.cards || new Map()).values()].filter((c) => c.server_id === sid).length;
  const vipRow = (snap.vipstate || new Map()).get(`${uid}|${sid}`);
  const again = db.prepare("SELECT 1 FROM track_log WHERE uid=? AND sid=? AND kind<>'reset' LIMIT 1").get(uid, sid); // seen before: the server restarted (or the character was reset)
  lastParts.set(uid, parts(db, uid, sid));
  write(db, uid, sid, again ? 'New snapshot (server restart or reset)' : 'Tracker start', [{ kind: 'baseline', value: p.atk, detail: JSON.stringify({ def: p.def, level: pl.level, exp: pl.exp, gold: pl.gold, silver: pl.coin, energy: pl.energy, vip: vipRow ? vipRow.level : 0, cards, nick: pl.nick }) }]);
}

// Label for changes found between two requests of a tracked account
function betweenLabel(d, made, prev) {
  if (made) return 'New character';
  if (panelAt >= (prev.at || 0)) return PANEL;
  if (d.every((x) => x.table === 'award_mail')) return 'Award Center mail arrived';
  return OUTSIDE;
}
const isNew = (a, b, uid, sid) => !(a.players || new Map()).has(`${uid}|${sid}`) && (b.players || new Map()).has(`${uid}|${sid}`);
const changes = (db) => { try { return db.prepare('SELECT total_changes() n').get().n; } catch { return 0; } };

// ---- drop statistics for every player (table drop_stats: one row per day x source x thing; tab "Tracker" > Drops in the whole game) ----
// A light snapshot (the player's row, items, newest card and pet) before and after every game request of every player, so drop rates
// (what a campaign fight, a tower round, a recruit ... gives) come from everyone's play, not just one account. Setting drop_stats=false stops it.
function statsOn(db) { try { return require('./settings').get(db, 'drop_stats', true) !== false; } catch { return true; } }
function light(db, uid, sid) {
  const pl = db.prepare('SELECT gold, coin, energy, level, exp FROM players WHERE uid=? AND server_id=?').get(uid, sid);
  if (!pl) return null;
  let props = new Map(), seq = 0, pet = 0;
  try { props = new Map(db.prepare('SELECT prop_id, count FROM props WHERE uid=? AND server_id=?').all(uid, sid).map((r) => [r.prop_id, r.count])); } catch {}
  try { seq = (db.prepare('SELECT MAX(seq) m FROM cards WHERE uid=? AND server_id=?').get(uid, sid) || {}).m || 0; } catch {}
  try { pet = (db.prepare('SELECT MAX(id) m FROM pets WHERE uid=? AND server_id=?').get(uid, sid) || {}).m || 0; } catch {}
  return { pl, props, seq, pet };
}
function stats(c) {
  const db = c.db, a = c.light, b = light(db, c.uid, c.sid);
  if (!a || !b) return;
  const rows = [];
  const add = (kind, key, name, amount) => rows.push([kind, String(key), name, amount]);
  for (const f of c.fights) add('fight', `${f.kind}:${f.win ? 'won' : 'lost'}`, f.kind, 1);
  const dg = b.pl.gold - a.pl.gold, ds = b.pl.coin - a.pl.coin, de = b.pl.energy - a.pl.energy - Object.values(c.refill).reduce((t, n) => t + n, 0);
  if (dg) add(dg > 0 ? 'gold+' : 'gold-', '', 'gold', Math.abs(dg));
  if (ds) add(ds > 0 ? 'silver+' : 'silver-', '', 'silver', Math.abs(ds));
  if (de) add(de > 0 ? 'energy+' : 'energy-', '', 'energy', Math.abs(de));
  if (c.exp) add('exp', '', 'exp', c.exp);
  if (b.pl.level > a.pl.level) add('level', '', 'level-ups', b.pl.level - a.pl.level);
  for (const [id, n] of b.props) { const d = n - (a.props.get(id) || 0); if (d > 0) add('item', id, propName(id), d); }
  if (b.seq > a.seq) for (const r of db.prepare('SELECT type, ninja_id FROM cards WHERE uid=? AND server_id=? AND seq>?').all(c.uid, c.sid, a.seq)) {
    const info = cardInfo(r.type, r.ninja_id);
    add('card', `${r.type}:${r.ninja_id}`, `${KIND[r.type] || '?'}: ${info.name}${info.stars ? ' ' + info.stars + '★' : ''}`, 1);
  }
  if (b.pet > a.pet) for (const r of db.prepare('SELECT pet_id FROM pets WHERE uid=? AND server_id=? AND id>?').all(c.uid, c.sid, a.pet)) add('card', `pet:${r.pet_id}`, 'Pet: ' + (rowOf('petinfo', r.pet_id)[2] || '#' + r.pet_id), 1);
  for (const d of c.drops) add('drop', d.id, d.name, 1);
  if (!rows.length) return;
  add('req', '', 'requests', 1);
  add('who', c.uid, 'player', 1);
  const day = dayKey(now()), src = label(c.cgi, c.params);
  const st = db.prepare(`INSERT INTO drop_stats(day,src,kind,key,name,times,amount) VALUES(?,?,?,?,?,1,?)
    ON CONFLICT(day,src,kind,key) DO UPDATE SET times=times+1, amount=amount+excluded.amount`);
  for (const [kind, key, name, amount] of rows) st.run(day, src, kind, key, name, amount);
}

// server.js, around each game request
function begin(db, params, cgi) {
  ctx = null;
  try {
    const uid = Number(params.Uin || params.Uid); // the game sends Uin on some requests (as handlers.accountBySession reads it)
    if (!(uid > 0)) return;
    ensure(db);
    const sid = Number(params.ServerID || 1);
    const full = tracked(db, uid);
    const c = { db, uid, sid, cgi, params, fights: [], drops: [], exp: 0, refill: {}, full, light: statsOn(db) ? light(db, uid, sid) : null };
    // another player's request may change a tracked account (spar, plunder, a message, the arena ladder): watched when it writes anything
    if (!full && last.size) c.changes = changes(db);
    if (full) {
      const snap = snapshot(db, uid);
      db.prepare('INSERT INTO track_time(uid,sid,minute,n) VALUES(?,?,?,1) ON CONFLICT(uid,sid,minute) DO UPDATE SET n=n+1').run(uid, sid, Math.floor(now() / 60));
      const prev = last.get(uid);
      if (!prev) baseline(db, uid, sid, snap);
      else {
        const d = diff(prev, snap);
        // the character is made by a request that does not carry its uid yet (rl_w_reg2): that shows here, between two requests
        const made = isNew(prev, snap, uid, sid);
        if (d.length) record(db, uid, sid, betweenLabel(d, made, prev), d, [], null, { a: prev, b: snap });
        if (made) baseline(db, uid, sid, snap);
      }
      snap.at = Date.now();
      c.snap = snap;
    }
    ctx = c;
  } catch (e) { ctx = null; if (process.env.HB_DEBUG) console.error('tracker', e); }
}
function end() {
  const c = ctx;
  ctx = null;
  if (!c) return;
  try { if (c.light) stats(c); } catch (e) { if (process.env.HB_DEBUG) console.error('tracker stats', e); }
  try {
    if (c.full) {
      const after = snapshot(c.db, c.uid);
      after.at = Date.now();
      last.set(c.uid, after);
      const extra = [];
      for (const f of c.fights) extra.push({ kind: 'fight', key: f.kind, value: f.win ? 1 : 0, detail: f.text });
      for (const d of c.drops) extra.push({ kind: 'drop', key: d.id, detail: d.name });
      const d = diff(c.snap, after);
      if (d.length || extra.length) record(c.db, c.uid, c.sid, label(c.cgi, c.params), d, extra, c, { a: c.snap, b: after });
      if (isNew(c.snap, after, c.uid, c.sid)) baseline(c.db, c.uid, c.sid, after); // a new character (after a reset): its starting point
    } else if (c.changes !== undefined && changes(c.db) !== c.changes) {
      // someone else's request wrote something: did it touch a tracked account?
      const who = c.db.prepare('SELECT nick FROM players WHERE uid=? AND server_id=?').get(c.uid, c.sid);
      for (const [uid, prev] of last) {
        const own = prev.players ? [...prev.players.values()].find((r) => r.server_id === 1) || [...prev.players.values()][0] : null;
        const sid = own ? own.server_id : 1;
        const snap = snapshot(c.db, uid);
        const d = diff(prev, snap);
        if (!d.length) continue;
        snap.at = prev.at;
        last.set(uid, snap);
        record(c.db, uid, sid, `Other player ${who ? who.nick : 'uid ' + c.uid}: ${label(c.cgi, c.params)}`, d, [], null, { a: prev, b: snap });
      }
    }
  } catch (e) { if (process.env.HB_DEBUG) console.error('tracker', e); } // the tracker must never break the game
}
// game.battleXml: one fight in the current request (n = my total attack and their total defence as the fight used them)
function fight(chap, stage, opt, won, n = {}) {
  if (!ctx) return;
  try {
    const kind = fightKind(ctx.cgi, chap, stage);
    const where = ctx.cgi === 'rl_w_pve' ? `${chap}-${stage} ` : ctx.cgi === 'rl_w_dup' ? `tower ${chap} round ${Math.round(stage / 5)} ` : '';
    ctx.fights.push({ kind, win: !!won, text: `${where}vs ${opt.enemyName || '?'}${opt.enemyLevel ? ' Lv ' + opt.enemyLevel : ''} · my attack ${Number(n.atk || 0).toLocaleString('en-US')} vs their defence ${Number(n.def || 0).toLocaleString('en-US')}` });
  } catch {}
}
// game.grantDrop: a drop pack opened in the current request
function drop(dropId, name) {
  if (!ctx) return;
  ctx.drops.push({ id: dropId, name: String(name || '#' + dropId) });
}
// game.addExp / game.energyTick: exp really gained, energy that came by itself
function exp(n) { if (ctx && n > 0) ctx.exp += n; }
function energyRefill(kind, n) { if (ctx && n > 0) ctx.refill[kind] = (ctx.refill[kind] || 0) + n; }
// admin.js: the item page / control panel was used (changes seen at the next game request are labelled with it)
function panelUsed() { panelAt = Date.now(); }
// admin.js resetPlayer: keep the history, start a new baseline at the next request
function onReset(db, uid, sid) {
  try {
    if (!tracked(db, uid)) return;
    ensure(db);
    write(db, uid, sid, 'Control panel', [{ kind: 'reset', detail: 'character reset' }]);
    last.delete(Number(uid));
  } catch {}
}

// ---- reading it back (control panel tab "Tracker", tools/dev/track.js) ----------------------------------------------------------
// Days are the server's own days (the same midnight the game's daily things reset at).
function dayKey(at) { const d = new Date(at * 1000); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; }
function dayRange(day) { const [y, m, d] = day.split('-').map(Number); const a = new Date(y, m - 1, d).getTime() / 1000; return [a, new Date(y, m - 1, d + 1).getTime() / 1000]; }
function days(db, uid, sid) {
  ensure(db);
  const r = db.prepare('SELECT MIN(at) a, MAX(at) b FROM track_log WHERE uid=? AND sid=?').get(uid, sid);
  if (!r || !r.a) return [];
  const out = [];
  for (let t = r.a; dayKey(t) <= dayKey(r.b); t += 86400) if (!out.includes(dayKey(t))) out.push(dayKey(t));
  if (!out.includes(dayKey(r.b))) out.push(dayKey(r.b));
  return out;
}
function add(m, k, n) { m[k] = (m[k] || 0) + n; }
function summary(db, uid, sid, day) {
  ensure(db);
  uid = Number(uid); sid = Number(sid || 1);
  const all = days(db, uid, sid);
  day = day || all[all.length - 1] || dayKey(now());
  const [a, b] = dayRange(day);
  let rows = db.prepare('SELECT * FROM track_log WHERE uid=? AND sid=? AND at>=? AND at<? ORDER BY id').all(uid, sid, a, b);
  const resets = rows.filter((r) => r.kind === 'reset');
  const reset = resets[resets.length - 1];
  if (reset) rows = rows.filter((r) => r.id >= reset.id); // a reset this day: the day starts again from the new character
  const before = (kind) => reset ? null : db.prepare('SELECT * FROM track_log WHERE uid=? AND sid=? AND at<? AND kind=? ORDER BY id DESC LIMIT 1').get(uid, sid, a, kind);
  const startOf = (kind, field) => { // value at the start of the day
    const f = rows.find((r) => r.kind === kind);
    if (f) return f.value - (f.delta || 0);
    const p = before(kind); if (p) return p.value;
    const base = rows.find((r) => r.kind === 'baseline') || before('baseline');
    return base && field ? JSON.parse(base.detail || '{}')[field] : null;
  };
  const endOf = (kind, field) => { const l = [...rows].reverse().find((r) => r.kind === kind); return l ? l.value : startOf(kind, field); };
  const flow = (kind) => { // income and spending by source
    const inc = {}, out = {};
    for (const r of rows) if (r.kind === kind && r.delta) (r.delta > 0 ? add(inc, r.src, r.delta) : add(out, r.src, -r.delta));
    return { in: inc, out, totalIn: Object.values(inc).reduce((t, x) => t + x, 0), totalOut: Object.values(out).reduce((t, x) => t + x, 0), start: startOf(kind, kind === 'silver' ? 'silver' : kind), end: endOf(kind, kind === 'silver' ? 'silver' : kind) };
  };
  // power curve: baseline + every change, starting from yesterday's last value
  const pw = rows.filter((r) => r.kind === 'power' || r.kind === 'baseline').map((r) => { const d = JSON.parse(r.detail || '{}'); return { at: r.at, atk: r.value, def: d.def || 0, datk: r.delta || 0, ddef: d.ddef || 0, why: d.why || (r.kind === 'baseline' ? 'tracker start' : '') + '', parts: d.parts || [], src: r.src }; });
  // which parts of the power grew over the day (sum of every change's parts)
  const partsDay = {};
  for (const x of pw) for (const q of x.parts || []) { const o = partsDay[q.part] = partsDay[q.part] || { atk: 0, def: 0 }; o.atk += q.atk; o.def += q.def; }
  const p0 = before('power') || before('baseline');
  if (p0 && !resets.length) pw.unshift({ at: a, atk: p0.value, def: JSON.parse(p0.detail || '{}').def || 0, datk: 0, ddef: 0, why: 'start of the day', parts: [], src: '' });
  // cards gained by source
  const gained = {}, gainedList = [];
  for (const r of rows) if (r.kind === 'card+') { add(gained, r.src, 1); gainedList.push({ at: r.at, src: r.src, what: r.detail, stars: r.value }); }
  const items = {};
  for (const r of rows) if (r.kind === 'item') { const k = r.detail; items[k] = items[k] || { in: 0, out: 0, by: {} }; if (r.delta > 0) { items[k].in += r.delta; add(items[k].by, r.src, r.delta); } else items[k].out -= r.delta; }
  const fights = {};
  for (const r of rows) if (r.kind === 'fight') { const f = fights[r.key] = fights[r.key] || { won: 0, lost: 0 }; r.value ? f.won++ : f.lost++; }
  const reach = {};
  for (const r of rows) if (r.kind === 'reach') reach[r.key] = r.detail;
  const minutes = db.prepare('SELECT minute, n FROM track_time WHERE uid=? AND sid=? AND minute>=? AND minute<? ORDER BY minute').all(uid, sid, Math.floor((reset ? reset.at : a) / 60), Math.floor(b / 60));
  // play sessions: requests with less than 5 minutes between them belong together
  const sessions = [];
  for (const m of minutes) { const s = sessions[sessions.length - 1]; if (s && m.minute - s.to <= 5) s.to = m.minute; else sessions.push({ from: m.minute, to: m.minute }); }
  const topups = rows.filter((r) => r.kind === 'topup');
  // levelling: when each level came, how long the one before took, and the exp still needed for the next
  const prevUp = reset ? null : db.prepare("SELECT at FROM track_log WHERE uid=? AND sid=? AND at<? AND kind IN ('level','baseline') ORDER BY id DESC LIMIT 1").get(uid, sid, a);
  let lastUp = prevUp ? prevUp.at : (rows.find((r) => r.kind === 'baseline') || {}).at || null;
  const lvl = rows.filter((r) => r.kind === 'level').map((r) => { const o = { at: r.at, level: r.value, src: r.src, took: lastUp ? r.at - lastUp : null }; lastUp = r.at; return o; });
  const lastExp = [...rows].reverse().find((r) => r.kind === 'exp');
  const base = [...rows].reverse().find((r) => r.kind === 'baseline');
  const curLevel = endOf('level', 'level');
  const curExp = lastExp ? lastExp.value : base ? JSON.parse(base.detail || '{}').exp : null;
  const need = curLevel ? (game.table('playerlevel').rows.find((x) => x[1] === curLevel) || [])[2] || null : null;
  // what every fight gave: all lines of the request that held the fight (silver, exp, items, cards, drop packs)
  const byReq = new Map();
  for (const r of rows) { if (!byReq.has(r.req)) byReq.set(r.req, []); byReq.get(r.req).push(r); }
  const loot = {}, fightList = [];
  for (const list of byReq.values()) {
    const fs = list.filter((r) => r.kind === 'fight');
    if (!fs.length) continue;
    const kind = fs[0].key, L = loot[kind] = loot[kind] || { fights: 0, won: 0, gold: 0, silver: 0, exp: 0, energy: 0, items: {}, cards: {}, drops: {} };
    L.fights += fs.length; L.won += fs.filter((r) => r.value).length;
    const got = [];
    for (const r of list) {
      if (r.kind === 'gold' || r.kind === 'silver' || r.kind === 'exp') { L[r.kind] += r.delta; got.push(`${r.kind} ${r.delta > 0 ? '+' : ''}${r.delta}`); }
      if (r.kind === 'energy' && !REFILL_SRC.has(r.src)) { L.energy += r.delta; got.push(`energy ${r.delta}`); }
      if (r.kind === 'item' && r.delta > 0) { add(L.items, r.detail, r.delta); got.push(`${r.detail} +${r.delta}`); }
      if (r.kind === 'card+') { add(L.cards, r.detail, 1); got.push(r.detail); }
      if (r.kind === 'drop') add(L.drops, r.detail, 1);
    }
    for (const f of fs) fightList.push({ at: f.at, kind, win: !!f.value, src: f.src, what: f.detail, got: got.join(', ') });
  }
  const ranks = rows.filter((r) => r.kind === 'rank').map((r) => ({ at: r.at, src: r.src, what: r.detail, rank: r.value }));
  const others = rows.filter((r) => /^Other player/.test(r.src)).map((r) => ({ at: r.at, src: r.src, kind: r.kind, delta: r.delta, detail: r.detail }));
  const vipUps = rows.filter((r) => r.kind === 'vip').map((r) => ({ at: r.at, vip: r.value }));
  const pl = db.prepare('SELECT nick, level FROM players WHERE uid=? AND server_id=?').get(uid, sid);
  return {
    uid, sid, nick: pl ? pl.nick : '', day, days: all, tz: Intl.DateTimeFormat().resolvedOptions().timeZone, resets: resets.map((r) => r.at),
    level: { start: startOf('level', 'level'), end: curLevel, ups: lvl, exp: curExp, need },
    vip: { start: startOf('vip', 'vip'), end: endOf('vip', 'vip'), ups: vipUps, expIn: rows.filter((r) => r.kind === 'vipexp' && r.delta > 0).reduce((t, r) => t + r.delta, 0) },
    topup: { count: topups.length, dollars: topups.reduce((t, r) => t + (r.delta || 0), 0) / 100, gold: topups.reduce((t, r) => t + (r.value || 0), 0) },
    gold: flow('gold'), silver: flow('silver'), energy: flow('energy'), exp: flow('exp'),
    power: pw, powerParts: partsDay, cardsBySource: gained, cards: gainedList, items, fights, reach, loot, fightList: fightList.slice(-500), ranks, others: others.slice(-300),
    played: { minutes: minutes.length, requests: minutes.reduce((t, m) => t + m.n, 0), sessions: sessions.map((s) => ({ from: s.from * 60, to: s.to * 60 + 59, minutes: s.to - s.from + 1 })) },
    events: rows.slice(-3000).map((r) => ({ at: r.at, req: r.req, src: r.src, kind: r.kind, key: r.key, delta: r.delta, value: r.value, detail: r.detail })),
  };
}
// Drops in the whole game on one day (drop_stats, every player): per source the requests, players, fights won / lost, gold / silver / exp /
// energy and every item, card and drop pack, with how often per fight.
function dropDays(db) { ensure(db); return db.prepare('SELECT DISTINCT day FROM drop_stats ORDER BY day').all().map((r) => r.day); }
function dropStats(db, day) {
  ensure(db);
  const all = dropDays(db);
  day = day || all[all.length - 1] || dayKey(now());
  const by = {};
  for (const r of db.prepare('SELECT * FROM drop_stats WHERE day=?').all(day)) {
    const S = by[r.src] = by[r.src] || { src: r.src, requests: 0, players: 0, fights: {}, gold: 0, goldOut: 0, silver: 0, silverOut: 0, exp: 0, energy: 0, energyOut: 0, levels: 0, items: [], cards: [], drops: [] };
    if (r.kind === 'req') S.requests = r.amount;
    else if (r.kind === 'who') S.players++;
    else if (r.kind === 'fight') { const [k, w] = r.key.split(':'); S.fights[k] = S.fights[k] || { won: 0, lost: 0 }; S.fights[k][w] += r.amount; }
    else if (r.kind === 'gold+') S.gold += r.amount; else if (r.kind === 'gold-') S.goldOut += r.amount;
    else if (r.kind === 'silver+') S.silver += r.amount; else if (r.kind === 'silver-') S.silverOut += r.amount;
    else if (r.kind === 'energy+') S.energy += r.amount; else if (r.kind === 'energy-') S.energyOut += r.amount;
    else if (r.kind === 'exp') S.exp += r.amount; else if (r.kind === 'level') S.levels += r.amount;
    else if (r.kind === 'item') S.items.push({ name: r.name, times: r.times, amount: r.amount });
    else if (r.kind === 'card') S.cards.push({ name: r.name, times: r.times, amount: r.amount });
    else if (r.kind === 'drop') S.drops.push({ name: r.name, times: r.times, amount: r.amount });
  }
  const list = Object.values(by).map((S) => {
    const fights = Object.values(S.fights).reduce((t, f) => t + f.won + f.lost, 0);
    for (const k of ['items', 'cards', 'drops']) S[k].sort((x, y) => y.amount - x.amount);
    return { ...S, fightsTotal: fights };
  }).sort((x, y) => y.requests - x.requests);
  return { day, days: all, tz: Intl.DateTimeFormat().resolvedOptions().timeZone, sources: list };
}

// the whole run, one line per day (the page's overview and track.js "all")
function overview(db, uid, sid) {
  return days(db, Number(uid), Number(sid || 1)).map((d) => {
    const s = summary(db, uid, sid, d);
    const p = s.power, f = Object.values(s.fights);
    return { day: d, level: s.level.end, vip: s.vip.end, atk: p.length ? p[p.length - 1].atk : null, def: p.length ? p[p.length - 1].def : null, minutes: s.played.minutes,
      topup: s.topup.dollars, goldIn: s.gold.totalIn, goldOut: s.gold.totalOut, silverIn: s.silver.totalIn, silverOut: s.silver.totalOut, cards: s.cards.length,
      won: f.reduce((t, x) => t + x.won, 0), lost: f.reduce((t, x) => t + x.lost, 0), reach: Object.values(s.reach) };
  });
}

module.exports = { ensure, uids, setUids, tracked, begin, end, fight, drop, exp, energyRefill, panelUsed, onReset, summary, overview, dropStats, dropDays, days, dayKey, label, snapshot, diff };
