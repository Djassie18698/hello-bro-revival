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
    return { top: ranked(db).slice(0, 10).map((r, i) => ({ rank: i + 1, name: clean(r.nick), level: r.level, atk: [r.lo, r.hi], glow: glowOf(styles, r.uid) })) };
  });
}

function player(db, name) {
  const want = clean(name).slice(0, 32);
  if (!want) return null;
  return cached('p:' + want.toLowerCase(), 60000, () => {
    const pl = db.prepare("SELECT uid, nick, level FROM players WHERE server_id=? AND nick<>'' AND lower(nick)=lower(?) ORDER BY level DESC LIMIT 1").get(WORLD, want);
    if (!pl) return null;
    const ts = game.teamStats(db, pl.uid, WORLD);
    const card = db.prepare('SELECT breaklvl, starlevel, newlife FROM cards WHERE seq=?');
    const team = ts.slots.map((s) => {
      const c = card.get(s.seq) || {};
      const n = game.ninjas().get(s.ninja_id) || [];
      return { id: s.ninja_id, name: cardName(s.ninja_id), stars: n[11] || 0, level: s.level || 1, breakthrough: c.breaklvl || 0, growth: c.starlevel || 0,
        rebirth: c.newlife || 0, atk: range(s.al, s.ah), def: range(s.dl, s.dh) };
    });
    const rank = ranked(db).findIndex((r) => r.uid === pl.uid) + 1;
    return { name: clean(pl.nick), level: pl.level, vip: vip.shown(vip.level(db, pl.uid, WORLD)), rank, glow: glowOf(names.styles(db), pl.uid),
      atk: range(ts.total.al, ts.total.ah), def: range(ts.total.dl, ts.total.dh), team };
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
    };
  });
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
      case '/api/player': { const p = player(db, q.name); return p ? send(resp, 200, p) : send(resp, 404, { error: 'no player with that name' }); }
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
