// Public, read-only data for the website (https://ninjaonlinereborn.com; Caddy passes /api/* to the game server, tools/vps/wiki-site.sh).
// GET only, every answer cached, nothing private: only what the game itself shows other players (name, level, VIP badge, team, power).
// No uid, account, login, device or e-mail ever leaves here. Nothing here changes the save except the online-count log (web_online).
//   /api/top              the No.1 Shinobi list's top 10 by attack (same sort as handlers.rl_r_ninja_rank Cmd 1), glowing names included
//   /api/player?name=X    one player's page: level, VIP badge (at most 18, like the game), team cards, attack / defence
//   /api/today            Limited Super Ninja god card of the hour, free ramen and energy times, events running now
//   /api/online?days=1|7  players online, logged every 5 minutes (also by statuswatch's /status), for the graph
//   /api/calc?s=...       team calculator (wiki): the game's own team maths (game.teamSlots) for cards, gear, seals and ninjutsu you pick
const game = require('./game');
const settings = require('./settings');
const vip = require('./vip');
const names = require('./specialnames');

const WORLD = 1; // Konoha (main): the public server plays everything on world 1 (HB_ONE_WORLD)
const clean = (s) => String(s == null ? '' : s).replace(/[<>&"]/g, '').trim();
const cardName = (id) => String((game.ninjas().get(id) || [])[2] || '').replace(/（/g, ' (').replace(/）/g, ')').replace(/\s+/g, ' ').trim();
const range = (lo, hi) => [Math.round(lo || 0), Math.round(hi || 0)];

// ---- small cache: each answer is worked out at most once per `ms` ----
const memo = new Map();
function cached(key, ms, fn) {
  const hit = memo.get(key);
  if (hit && Date.now() - hit.at < ms) return hit.v;
  const v = fn();
  memo.set(key, { at: Date.now(), v });
  if (memo.size > 500) for (const k of [...memo.keys()].slice(0, 100)) memo.delete(k); // keep it small (calculator queries)
  return v;
}

function glowOf(styles, uid) {
  const s = styles.get(uid);
  return s ? { color: names.hex(s.color) || names.DEFAULT_COLOR, effect: names.fx(s.effect) || '' } : null;
}

// every real character on the world, strongest attack first (handlers.rl_r_ninja_rank, Cmd 1)
function ranked(db) {
  return cached('ranked', 60000, () => db.prepare("SELECT uid, nick, level FROM players WHERE server_id=? AND nick<>''").all(WORLD).map((r) => {
    const t = game.teamStats(db, r.uid, WORLD).total;
    return { ...r, lo: Math.round(t.al), hi: Math.round(t.ah) };
  }).sort((a, b) => b.hi - a.hi || b.lo - a.lo || b.level - a.level || a.uid - b.uid));
}

function top(db) {
  return cached('top', 60000, () => {
    const styles = names.styles(db);
    const nth = sameNameOrder(db);
    return { top: ranked(db).slice(0, 10).map((r, i) => ({ rank: i + 1, name: clean(r.nick), n: nth.get(r.uid) || 1, level: r.level, atk: [r.lo, r.hi], glow: glowOf(styles, r.uid) })) };
  });
}

// Where a team's attack and defence come from (owner, 8 Nov 2026: "where the damage is coming from. Eight gate, beasts, etc"). Walks the
// same steps as game.teamStats (teamSlots per card, then teamTotals for the whole team) and keeps what each step added, so the parts add
// up exactly to the number the game shows. Per card: level stats, rebirth, god breakthrough, sage growth, training points (game.ninjaStats
// with one field switched on at a time), then each worn piece in the order teamSlots applies it (gear adds, seals and ninjutsu multiply),
// gear / ninjutsu sets, chains. Whole team: card sets, Eight Gates, the W.A. title, pets.
const PARTS = [['level', 'Card level and stars'], ['rebirth', 'Rebirth'], ['breakthrough', 'God breakthrough'], ['growth', 'Sage growth'], ['training', 'Training points'],
  ['gear', 'Gear'], ['seals', 'Seals'], ['ninjutsu', 'Ninjutsu'], ['sets', 'Gear and ninjutsu sets'], ['chains', 'Chains'],
  ['cardsets', 'Card sets'], ['gates', 'Eight Gates'], ['title', 'W.A. title'], ['pets', 'Pets'], ['other', 'Other']];
function breakdown(db, uid, sid) {
  const K = game.KEYS || ['al', 'ah', 'dl', 'dh', 'cl', 'ch'];
  const zero = () => Object.fromEntries(K.map((k) => [k, 0]));
  const acc = Object.fromEntries(PARTS.map(([k]) => [k, zero()]));
  const put = (part, before, after) => { for (const k of K) acc[part][k] += (after[k] || 0) - (before[k] || 0); };
  // the same rows as game.teamStats
  const team = db.prepare('SELECT t.slot, c.* FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(uid, sid);
  const eqRows = db.prepare('SELECT e.slot, e.kind, c.* FROM equipped e JOIN cards c ON c.seq=e.seq WHERE e.uid=? AND e.server_id=?').all(uid, sid);
  const owned = new Set(db.prepare('SELECT DISTINCT ninja_id FROM cards WHERE uid=? AND server_id=? AND type=1').all(uid, sid).map((r) => r.ninja_id));
  const slots = game.teamSlots(team, eqRows, owned);
  const chainsOn = [];
  team.forEach((c, i) => {
    const steps = [{ ...c, newlife: 0, breaklvl: 0, starlevel: 0, pot_att: 0, pot_def: 0, pot_ckr: 0 }];
    steps.push({ ...steps[0], newlife: c.newlife }); steps.push({ ...steps[1], breaklvl: c.breaklvl }); steps.push({ ...steps[2], starlevel: c.starlevel }); steps.push(c);
    let st = game.ninjaStats(steps[0]);
    put('level', zero(), st);
    ['rebirth', 'breakthrough', 'growth', 'training'].forEach((part, n) => { const next = game.ninjaStats(steps[n + 1]); put(part, st, next); st = next; });
    const mine = eqRows.filter((x) => x.slot === i + 1);
    for (const e of mine) { // teamSlots' order and maths
      const next = e.type === 5 ? game.sealBonus(st, e.ninja_id) : e.type === 6 ? game.ninjutsuBonus(st, e.ninja_id) : game.addStats(st, game.equipStats(e));
      put(e.type === 5 ? 'seals' : e.type === 6 ? 'ninjutsu' : 'gear', st, next); st = next;
    }
    const next = game.setBonus(st, game.skillSets(mine)); put('sets', st, next); st = next;
    const s = slots[i] || {};
    for (const k of K) acc.chains[k] += (s.chain && s.chain[k]) || 0;
    const after = game.addStats(st, s.chain || {});
    for (const k of K) acc.other[k] += (s[k] || 0) - (after[k] || 0); // 0 unless teamSlots changes
    if ((s.active || []).length) chainsOn.push({ id: s.ninja_id, name: cardName(s.ninja_id), chains: s.active.map((id) => chainText(id)).filter(Boolean) });
  });
  // whole team: the same steps as game.teamTotals
  const tt = game.teamTotals(db, uid, sid, slots);
  let tot = slots.reduce((a, s) => game.addStats(a, s), {});
  const cs = game.addStats(tot, tt.bonus || {}); put('cardsets', tot, cs); tot = cs;
  const gb = game.gateBonus(game.gateLevel(db, uid, sid));
  if (gb.flat) { const g = {}; for (const k of K) g[k] = gb.flat + Math.round((tot[k] || 0) * gb.pct); const t2 = game.addStats(tot, g); put('gates', tot, t2); tot = t2; }
  const medal = game.table('playemedal').rows.find((r) => r[0] === game.meritLevel(db, uid, sid));
  if (medal) { const t2 = game.addStats(tot, { al: medal[3], ah: medal[4], dl: medal[5], dh: medal[6], cl: medal[7], ch: medal[8] }); put('title', tot, t2); tot = t2; }
  const pb = require('./pet').teamBonus(db, uid, sid);
  const t3 = game.addStats(tot, { al: pb.attack, ah: pb.attack, dl: pb.defense, dh: pb.defense, cl: pb.chakala, ch: pb.chakala }); put('pets', tot, t3); tot = t3;
  for (const k of K) acc.other[k] += (tt.total[k] || 0) - (tot[k] || 0); // anything teamTotals adds that this walk does not know (0 today)
  const side = (lo, hi) => PARTS.map(([key, label]) => ({ key, label, v: range(acc[key][lo], acc[key][hi]) })).filter((p) => p.v[0] || p.v[1]);
  return { atk: side('al', 'ah'), def: side('dl', 'dh'), chains: chainsOn, gateLevel: game.gateLevel(db, uid, sid), total: tt.total };
}
let chainTexts = null;
const chainText = (id) => { if (!chainTexts) chainTexts = new Map(game.table('ninjamatch').rows.map((r) => [r[0], String(r[4] || '').trim()])); return chainTexts.get(id) || ''; };

// Names are not unique: two characters can both be called DEAN. n = a character's place among those with the same name (highest level
// first, then the older character), so /p/DEAN?n=2 opens the second one without showing any account number. lower() = SQLite's (A-Z only).
const asciiLower = (s) => String(s).replace(/[A-Z]/g, (c) => c.toLowerCase());
function sameNameOrder(db) {
  return cached('nth', 60000, () => {
    const out = new Map(), seen = new Map();
    for (const r of db.prepare("SELECT uid, nick FROM players WHERE server_id=? AND nick<>'' ORDER BY level DESC, uid ASC").all(WORLD)) {
      const k = asciiLower(r.nick), n = (seen.get(k) || 0) + 1;
      seen.set(k, n); out.set(r.uid, n);
    }
    return out;
  });
}
function player(db, name, nth = 1) {
  const want = clean(name).slice(0, 32);
  if (!want) return null;
  const n = Math.max(1, Math.min(50, Math.floor(Number(nth)) || 1));
  return cached('p:' + n + ':' + want.toLowerCase(), 60000, () => {
    const pl = db.prepare("SELECT uid, nick, level FROM players WHERE server_id=? AND nick<>'' AND lower(nick)=lower(?) ORDER BY level DESC, uid ASC LIMIT 1 OFFSET ?").get(WORLD, want, n - 1);
    if (!pl) return null;
    const ts = game.teamStats(db, pl.uid, WORLD);
    const bd = breakdown(db, pl.uid, WORLD);
    const card = db.prepare('SELECT breaklvl, starlevel, newlife FROM cards WHERE seq=?');
    const team = ts.slots.map((s) => {
      const c = card.get(s.seq) || {};
      const n = game.ninjas().get(s.ninja_id) || [];
      return { id: s.ninja_id, name: cardName(s.ninja_id), stars: n[11] || 0, level: s.level || 1, breakthrough: c.breaklvl || 0, growth: c.starlevel || 0,
        rebirth: c.newlife || 0, atk: range(s.al, s.ah), def: range(s.dl, s.dh), chains: (s.active || []).map(chainText).filter(Boolean) };
    });
    const rank = ranked(db).findIndex((r) => r.uid === pl.uid) + 1;
    return { name: clean(pl.nick), level: pl.level, vip: vip.shown(vip.level(db, pl.uid, WORLD)), rank, glow: glowOf(names.styles(db), pl.uid),
      atk: range(ts.total.al, ts.total.ah), def: range(ts.total.dl, ts.total.dh), gates: bd.gateLevel,
      from: { atk: bd.atk, def: bd.def }, team };
  });
}

// ---- today in the game ----
function today(db) {
  return cached('today', 60000, () => {
    const ls = require('./limitsuper');
    const now = Math.floor(Date.now() / 1000);
    const hourStart = now - (now % 3600);
    const god = ls.featured(now), next = [1, 2, 3].map((h) => ls.featured(hourStart + h * 3600 + 60));
    const running = settings.EVENTS.filter((e) => e.limited && !e.hidden && !e.noconf && settings.eventOn(db, e.id)).map((e) => e.name);
    const off = settings.EVENTS.filter((e) => !e.limited && !e.hidden && !e.noconf && !settings.eventOn(db, e.id)).map((e) => e.name);
    return {
      offset: -new Date().getTimezoneOffset(), // the server clock (all game times below are on it), minutes east of UTC
      god: god ? { id: god.id, name: god.name, until: hourStart + 3600 } : null,
      next: next.filter(Boolean).map((g) => ({ id: g.id, name: g.name })),
      superNinja: settings.eventOn(db, 'superninja'),
      ramen: process.env.RAMEN_ALLDAY ? [[0, 24]] : [[12, 14], [18, 20]], // handlers.rl_w_ramen
      energyRefill: 22, // game.js energy: every day at 22:00 energy refills to the maximum
      running, off,
      week: weekPlan(db, now),
    };
  });
}
// This week's event rotation (rotation.js), day by day, for the home page; null when the rotation is switched off.
const SHORT = { totalgift: 'Total-recharge gift', discount: 'Time-limited GiftPack', groupbuy: 'Group purchase', xmas2: 'Christmas festival' };
function weekPlan(db, now) {
  const rot = require('./rotation');
  const st = rot.status(db, now);
  if (!st.on) return null;
  const c = rot.cfg(db);
  const names = Object.fromEntries(settings.EVENTS.map((e) => [String(e.id), SHORT[e.id] || e.name]));
  const ids = rot.PLAN_IDS.filter((id) => id !== 'superninja' && id !== 'festival');
  const first = rot.midnight(now) - (st.day - 1) * 86400; // day 1 of this week
  const days = [1, 2, 3, 4, 5, 6, 7].map((d) => {
    const start = first + (d - 1) * 86400, t = start + 12 * 3600;
    const on = ids.filter((id) => rot.slot(db, id, t));
    const fest = rot.festivalOf(c, t);
    if (fest && rot.slot(db, fest, t)) on.push(fest);
    return { day: d, start, on };
  });
  const allWeek = days[0].on.filter((id) => id !== 'shardrush' && days.every((x) => x.on.includes(id)));
  const sn = st.events.find((e) => e.id === 'superninja');
  return {
    day: st.day,
    days: days.map((x) => ({ day: x.day, start: x.start, shardRush: x.on.includes('shardrush'),
      events: x.on.filter((id) => id !== 'shardrush' && !allWeek.includes(id)).map((id) => names[id]).filter(Boolean) })),
    allWeek: allWeek.map((id) => names[id]).filter(Boolean),
    superNinja: sn && sn.inRotation ? rot.SN_HOURS.map(([h, n]) => [h, h + n]) : null,
  };
}

// ---- players online, every 5 minutes ----
function ensureOnline(db) { db.exec('CREATE TABLE IF NOT EXISTS web_online (t INTEGER PRIMARY KEY, online INTEGER NOT NULL, players INTEGER)'); }
function record(db, counts) {
  ensureOnline(db);
  const tick = () => {
    try {
      const c = counts() || {};
      if (c.online == null) return;
      const t = Math.floor(Date.now() / 300000) * 300; // one row per 5-minute step
      db.prepare('INSERT OR REPLACE INTO web_online (t, online, players) VALUES (?, ?, ?)').run(t, c.online, c.players || 0);
      db.prepare('DELETE FROM web_online WHERE t < ?').run(t - 31 * 86400); // a month is plenty
    } catch (e) { console.error('web_online', e.message); }
  };
  setTimeout(tick, 20000).unref();
  setInterval(tick, 300000).unref();
}
function online(db, days) {
  const d = days >= 7 ? 7 : 1;
  return cached('online:' + d, 60000, () => {
    ensureOnline(db);
    const since = Math.floor(Date.now() / 1000) - d * 86400;
    const rows = db.prepare('SELECT t, online FROM web_online WHERE t >= ? ORDER BY t').all(since);
    // a week: the highest count per half hour, so the graph stays small
    const step = d === 7 ? 1800 : 300, out = new Map();
    for (const r of rows) { const k = r.t - (r.t % step); out.set(k, Math.max(out.get(k) || 0, r.online)); }
    return { step, points: [...out.entries()] };
  });
}

// ---- team calculator ----
// s = slots joined by "|"; a slot = tokens joined by ",": n<ninja id>.<level>.<breakthrough>.<sage growth>.<element 1-5>.<rebirth>, e<gear id>.<level>,
// m<seal id>, j<ninjutsu id> (up to 4). Example: s=n2106.80.3,e1.60,e33.60,m5,j48|n57.40
const MAX_SLOTS = 26; // newcardinfo: the most team places the game opens
function calc(query) {
  const raw = String(query || '').slice(0, 1500);
  return cached('c:' + raw, 60000, () => {
    const ninjaMax = game.cardMaxLevel(1) || 200, gearMax = game.cardMaxLevel(2) || 200;
    const rebirthMax = Math.max(0, ...game.table('newlifeprop').rows.map((r) => r[3] || 0));
    const gear = new Map(game.table('equipmentinfo').rows.map((r) => [r[0], r]));
    const seals = new Set(game.table('markinfo').rows.map((r) => r[0]));
    const jutsu = new Set(game.table('ninjutsuinfo').rows.map((r) => r[0]));
    const int = (v, lo, hi, d) => { const n = Math.floor(Number(v)); return Number.isFinite(n) ? Math.max(lo, Math.min(hi, n)) : d; };
    const team = [], eq = [];
    for (const part of raw.split('|').slice(0, MAX_SLOTS)) {
      let card = null; const worn = [];
      for (const tok of part.split(',').slice(0, 10)) {
        const k = tok[0], v = tok.slice(1).split('.');
        const id = int(v[0], 0, 1e6, 0);
        if (k === 'n' && game.ninjas().has(id) && !card) card = { ninja_id: id, level: int(v[1], 1, ninjaMax, 1), breaklvl: int(v[2], 0, 10, 0), starlevel: int(v[3], 0, 15, 0), attri: int(v[4], 1, 5, 1), newlife: int(v[5], 0, rebirthMax, 0) };
        else if (k === 'e' && gear.has(id) && worn.filter((w) => w.type >= 2 && w.type <= 4).length < 3) worn.push({ ninja_id: id, type: 2 + (gear.get(id)[3] || 0), level: int(v[1], 1, gearMax, 1), newlife: 0 });
        else if (k === 'm' && seals.has(id) && !worn.some((w) => w.type === 5)) worn.push({ ninja_id: id, type: 5 });
        else if (k === 'j' && jutsu.has(id) && worn.filter((w) => w.type === 6).length < 4) worn.push({ ninja_id: id, type: 6 });
      }
      if (!card) continue;
      const slot = team.length + 1;
      team.push({ seq: slot, ...card });
      for (const w of worn) eq.push({ slot, seq: 0, ...w });
    }
    if (!team.length) return { slots: [], total: { atk: [0, 0], def: [0, 0], ckr: [0, 0] } };
    const slots = game.teamSlots(team, eq, null);
    const chainText = new Map(game.table('ninjamatch').rows.map((r) => [r[0], String(r[4] || '').trim()]));
    const sum = slots.reduce((a, s) => game.addStats(a, s), {});
    return {
      slots: slots.map((s) => ({ id: s.ninja_id, name: cardName(s.ninja_id), level: s.level, atk: range(s.al, s.ah), def: range(s.dl, s.dh), ckr: range(s.cl, s.ch),
        chains: (s.active || []).map((id) => ({ id, text: chainText.get(id) || '' })), sets: s.sets || [] })),
      total: { atk: range(sum.al, sum.ah), def: range(sum.dl, sum.dh), ckr: range(sum.cl, sum.ch) },
    };
  });
}

// ---- the route ----
function send(resp, code, body) {
  resp.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': code === 200 ? 'public, max-age=30' : 'no-store', 'X-Content-Type-Options': 'nosniff' });
  resp.end(JSON.stringify(body));
}
function handle(req, resp, u, db) {
  if (req.method !== 'GET' && req.method !== 'HEAD') return send(resp, 405, { error: 'GET only' });
  const q = u.query || {};
  try {
    switch (u.pathname) {
      case '/api/top': return send(resp, 200, top(db));
      case '/api/player': { const p = player(db, q.name, q.n); return p ? send(resp, 200, p) : send(resp, 404, { error: 'no player with that name' }); }
      case '/api/today': return send(resp, 200, today(db));
      case '/api/online': return send(resp, 200, online(db, Number(q.days) || 1));
      case '/api/calc': return send(resp, 200, calc(q.s));
      default: return send(resp, 404, { error: 'unknown' });
    }
  } catch (e) {
    console.error('webapi', u.pathname, e && e.stack);
    return send(resp, 500, { error: 'something went wrong' });
  }
}

module.exports = { handle, record, top, player, today, online, calc };
