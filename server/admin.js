// Admin panel: http://<server>:18080/admin  (offline hobby server: open to everyone who can reach it, no password unless ADMIN_PASSWORD is set)
// The page itself is admin.html (next to this file); this module serves it and answers its /admin/api/* calls.
const fs = require('fs');
const path = require('path');
const game = require('./game');
const vip = require('./vip');

// Delete one player's character and everything tied to it (the login account stays, so the same device just makes a
// new character). Shared tables that name the player another way are cleaned too. A save backup is written first.
function resetPlayer(db, uid, sid = 1) {
  try {
    const dir = path.join(process.cwd(), process.env.HB_BACKUPS || 'backups'); // next to the save, like the other backups
    fs.mkdirSync(dir, { recursive: true });
    db.exec(`VACUUM INTO '${path.join(dir, `before-reset-${uid}-${Date.now()}.db`).replace(/'/g, "''")}'`);
  } catch (e) { /* backup is best effort */ }
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all().map((r) => r.name);
  for (const t of tables) {
    if (t === 'accounts' || t === 'logins' || t === 'sqlite_sequence' || t === 'special_names' || t.startsWith('track_')) continue; // keep the login (accounts + the app's account window) and a purple name
    const cols = db.prepare(`PRAGMA table_info(${t})`).all().map((c) => c.name);
    if (cols.includes('uid')) { if (cols.includes('server_id')) db.prepare(`DELETE FROM ${t} WHERE uid=? AND server_id=?`).run(uid, sid); else if (sid === 1) db.prepare(`DELETE FROM ${t} WHERE uid=?`).run(uid); }
  }
  if (tables.includes('mail')) db.prepare('DELETE FROM mail WHERE to_uid=?').run(uid);
  if (tables.includes('groups')) db.prepare('DELETE FROM groups WHERE leader_uid=?').run(uid);
  require('./tracker').onReset(db, uid, sid); // progress tracker: a "reset" line, history kept
}

// Admin player key: "uid:server_id" (one login can own a character per server slot); a bare uid means server 1.
function findPlayer(db, key) {
  const [uid, sid] = String(key || '').split(':').map(Number);
  return uid ? db.prepare('SELECT * FROM players WHERE uid=? AND server_id=?').get(uid, sid || 1) : null;
}
const json = (res, o) => { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(o)); };

// Private play: no password. Public server: set ADMIN_PASSWORD; the browser then asks for it (user name is ignored).
function authorized(req) {
  const pw = process.env.ADMIN_PASSWORD;
  if (!pw) return true;
  const m = /^Basic (.+)$/.exec(req.headers.authorization || '');
  if (!m) return false;
  const given = Buffer.from(m[1], 'base64').toString('utf8').split(':').slice(1).join(':');
  return given === pw;
}

// ---- Catalog: everything that can be given, in one list (category, id, name, stars) ----------------------------------
const SLOT = { 0: 'Weapon', 1: 'Armor', 2: 'Trinket' };
let catalogCache = null;
function catalog() {
  if (catalogCache) return catalogCache;
  const out = [];
  const seen = new Set();
  for (const r of game.ninjas().values()) {
    // playable shinobi cards only: col 4 = 1 (card), real stats in col 19; npcs (enemy-only rows) have no stats
    if (r[4] !== 1 || !(r[19] > 0)) continue;
    const key = r[2] + '|' + r[11] + '|' + r[6];
    if (seen.has(key)) continue; // the table repeats some cards with another element; keep one of each
    seen.add(key);
    out.push({ cat: 'ninja', id: r[0], name: r[2], stars: r[11] || 0, sub: r[6] ? 'variant' : '' });
  }
  for (const r of game.table('equipmentinfo').rows) out.push({ cat: 'equip', id: r[0], name: r[2], stars: r[6] || 0, sub: SLOT[r[3]] || '' });
  for (const r of game.table('ninjutsuinfo').rows) out.push({ cat: 'ninjutsu', id: r[0], name: r[2], stars: r[5] || 0, sub: '' });
  for (const r of game.table('markinfo').rows) out.push({ cat: 'seal', id: r[0], name: r[2], stars: r[6] || 0, sub: String(r[7] || '').trim() });
  for (const r of game.table('consumeinfo').rows) out.push({ cat: 'item', id: r[1], name: r[2], stars: 0, sub: '' });
  for (const r of game.table('piece_info').rows) out.push({ cat: 'fragment', id: r[0], name: r[2] + ' fragment', stars: r[5] || 0, sub: `${r[7]} make one` });
  for (const r of game.table('petinfo').rows) out.push({ cat: 'pet', id: r[0], name: r[2], stars: 0, sub: 'pet' });
  catalogCache = out;
  return out;
}

// Card level / rebirth limits: level 1-50 for every card kind (ninjaupgrade/equipupgrade/... have 50 rows), rebirth 0-8 for shinobi
// (game.NEWLIFE_MAX), 0-3 for equipment (equipnewlifeprop), none for ninjutsu and seals. Sage growth 0-15 for shinobi only (game.GROW_MAX).
const LIMITS = { ninja: { lv: 50, nl: 8, gr: game.GROW_MAX }, equip: { lv: 50, nl: 3, gr: 0 }, ninjutsu: { lv: 50, nl: 0, gr: 0 }, seal: { lv: 50, nl: 0, gr: 0 } };
const clamp = (v, lo, hi) => Math.min(Math.max(Math.trunc(v) || lo, lo), hi);
const clampCard = (cat, lv, nl, gr) => {
  const L = LIMITS[cat] || { lv: 1, nl: 0, gr: 0 };
  return { lv: clamp(lv, 1, L.lv), nl: clamp(nl, 0, L.nl), gr: L.gr ? clamp(gr, 0, L.gr) : null };
};
// gr null = leave the card's growth as it is (only shinobi have sage growth)
const setCard = (db, seq, c) => {
  if (seq) db.prepare('UPDATE cards SET level=?, newlife=?, starlevel=COALESCE(?, starlevel) WHERE seq=?').run(c.lv, c.nl, c.gr, seq);
  return seq;
};

// Give one catalog entry n times (cards at the chosen level / rebirth). Returns how many really arrived.
function giveOne(db, pl, cat, id, n, opt = {}) {
  const uid = pl.uid, sid = pl.server_id, c = clampCard(cat, opt.level, opt.newlife, opt.growth);
  if (cat === 'ninja') { for (let i = 0; i < n; i++) setCard(db, game.giveCard(db, uid, sid, id), c); return n; }
  if (cat === 'equip') { let k = 0; for (let i = 0; i < n; i++) if (setCard(db, game.giveEquip(db, uid, sid, id), c)) k++; return k; }
  if (cat === 'ninjutsu') { for (let i = 0; i < n; i++) setCard(db, game.giveCard(db, uid, sid, id, 6), c); return n; }
  if (cat === 'seal') { for (let i = 0; i < n; i++) setCard(db, game.giveCard(db, uid, sid, id, 5), c); return n; }
  if (cat === 'item') { game.propAdd(db, uid, sid, id, n); return n; }
  if (cat === 'fragment') { game.propAdd(db, uid, sid, game.CHIP_BASE + id, n); return n; }
  if (cat === 'pet') { for (let i = 0; i < n; i++) require('./pet').addPet(db, uid, sid, id); return n; }
  return 0;
}

const CARD_TYPES = { 1: 'Shinobi', 2: 'Weapon', 3: 'Armor', 4: 'Trinket', 5: 'Seal', 6: 'Ninjutsu' };
function cardName(type, id) {
  if (type === 1) return (game.ninjas().get(id) || [])[2] || '#' + id;
  if (type >= 2 && type <= 4) return (game.table('equipmentinfo').rows.find((r) => r[0] === id) || [])[2] || '#' + id;
  if (type === 5) return (game.table('markinfo').rows.find((r) => r[0] === id) || [])[2] || '#' + id;
  if (type === 6) return (game.table('ninjutsuinfo').rows.find((r) => r[0] === id) || [])[2] || '#' + id;
  return '#' + id;
}

let pageCache = null;
// ---- Team editor: the whole team (ninjas + their 8 gear slots) in one go ------------------------------------------------
// equipped.kind: 1 weapon (card type 2), 2 armor (3), 3 trinket (4), 4 seal (5), 5-8 ninjutsu (6). equipped.slot = team position + 1.
const KIND_TYPE = { 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 6, 7: 6, 8: 6 };
const TYPE_CAT = { 1: 'ninja', 2: 'equip', 3: 'equip', 4: 'equip', 5: 'seal', 6: 'ninjutsu' };
const cardInfo = (c) => c && { seq: c.seq, type: c.type, id: c.ninja_id, name: cardName(c.type, c.ninja_id), level: c.level, newlife: c.newlife || 0, growth: c.starlevel || 0 };
function teamView(db, pl) {
  game.ensure(db);
  const cards = db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=? ORDER BY level DESC, seq').all(pl.uid, pl.server_id);
  const bySeq = new Map(cards.map((c) => [c.seq, c]));
  const team = db.prepare('SELECT seq FROM team WHERE uid=? AND server_id=? ORDER BY slot').all(pl.uid, pl.server_id);
  const eq = db.prepare('SELECT slot, kind, seq FROM equipped WHERE uid=? AND server_id=?').all(pl.uid, pl.server_id);
  const slots = team.map((t, i) => ({
    ninja: cardInfo(bySeq.get(t.seq)),
    equip: Object.fromEntries([1, 2, 3, 4, 5, 6, 7, 8].map((k) => { const e = eq.find((x) => x.slot === i + 1 && x.kind === k); return [k, e ? cardInfo(bySeq.get(e.seq)) : null]; })),
  }));
  const owned = {};
  for (const c of cards) (owned[c.type] = owned[c.type] || []).push(cardInfo(c));
  const t = game.teamStats(db, pl.uid, pl.server_id).total;
  return { max: game.maxTeam(db, pl), slots, owned, power: { attack: `${t.al}-${t.ah}`, defense: `${t.dl}-${t.dh}` } };
}
// slots: [{ ninja: { seq } | { give: id }, level, newlife, growth, equip: { kind: { seq } | { give: id }, level, newlife } | null }]
function applyTeam(db, pl, slots) {
  game.ensure(db);
  const max = game.maxTeam(db, pl);
  const list = (Array.isArray(slots) ? slots : []).filter((s) => s && s.ninja).slice(0, max);
  const own = (seq, type) => db.prepare('SELECT * FROM cards WHERE seq=? AND uid=? AND server_id=? AND type=?').get(Number(seq), pl.uid, pl.server_id, type);
  const used = new Set();
  const resolve = (pick, type, kindForEquip) => {
    if (!pick) return 0;
    if (pick.seq) { const c = own(pick.seq, type); if (!c) throw new Error('a picked card is not owned any more'); if (used.has(c.seq)) throw new Error(cardName(c.type, c.ninja_id) + ' is picked twice'); return c.seq; }
    const id = Math.trunc(Number(pick.give));
    if (!id) return 0;
    const seq = type === 1 ? game.giveCard(db, pl.uid, pl.server_id, id) : type <= 4 ? game.giveEquip(db, pl.uid, pl.server_id, id) : game.giveCard(db, pl.uid, pl.server_id, id, type);
    if (!seq) throw new Error('could not create card #' + id);
    const got = db.prepare('SELECT type FROM cards WHERE seq=?').get(seq).type;
    if (got !== type) { db.prepare('DELETE FROM cards WHERE seq=?').run(seq); throw new Error('that item does not fit the ' + (['', '', 'weapon', 'armor', 'trinket'][type] || 'chosen') + ' slot'); }
    return seq;
  };
  db.exec('BEGIN');
  try {
    db.prepare('DELETE FROM team WHERE uid=? AND server_id=?').run(pl.uid, pl.server_id);
    db.prepare('DELETE FROM equipped WHERE uid=? AND server_id=?').run(pl.uid, pl.server_id);
    list.forEach((s, i) => {
      const seq = resolve(s.ninja, 1);
      used.add(seq);
      setCard(db, seq, clampCard('ninja', s.level, s.newlife, s.growth));
      db.prepare('INSERT INTO team(uid,server_id,slot,seq) VALUES(?,?,?,?)').run(pl.uid, pl.server_id, i, seq);
      for (const k of [1, 2, 3, 4, 5, 6, 7, 8]) {
        const e = s.equip && s.equip[k];
        if (!e || (!e.seq && !e.give)) continue;
        const type = KIND_TYPE[k], eseq = resolve(e, type);
        if (!eseq) continue;
        used.add(eseq);
        setCard(db, eseq, clampCard(TYPE_CAT[type], e.level, e.newlife, 0));
        db.prepare('INSERT INTO equipped(uid,server_id,slot,kind,seq) VALUES(?,?,?,?,?)').run(pl.uid, pl.server_id, i + 1, k, eseq);
      }
    });
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    return { ok: false, error: e.message };
  }
  return { ok: true, ...teamView(db, pl) };
}

// The control panel (panel.html): one page with tabs (Server / Players & items / Team builder) that embeds /manager and /admin.
function panel(res, start) {
  const page = fs.readFileSync(path.join(__dirname, 'panel.html'), 'utf8').replace('<body>', `<body data-start="${start}">`);
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(page);
}

// ---- Complete chains: read every chain of every ninja in the team and add what is missing ----------------------------------
// Partners join free team slots (the player's own card when they have one, else a new card: the highest-star version with that name);
// "Equip X" chains put that weapon / armor / trinket / ninjutsu on the ninja. Returns a setteam plan + a list of what changes.
function chainPlan(db, pl) {
  const view = teamView(db, pl);
  const slots = view.slots.map((s) => ({ ninja: { seq: s.ninja.seq }, id: s.ninja.id, level: s.ninja.level, newlife: s.ninja.newlife, growth: s.ninja.growth,
    equip: Object.fromEntries(Object.entries(s.equip).filter(([, e]) => e).map(([k, e]) => [k, { seq: e.seq, id: e.id, level: e.level, newlife: e.newlife }])) }));
  const owned = db.prepare('SELECT seq, type, ninja_id, level FROM cards WHERE uid=? AND server_id=? ORDER BY level DESC, seq').all(pl.uid, pl.server_id);
  const used = new Set(slots.flatMap((s) => [s.ninja.seq, ...Object.values(s.equip).map((e) => e.seq)]));
  const ownedFree = (type, id) => owned.find((c) => c.type === type && c.ninja_id === id && !used.has(c.seq));
  const cards = [...game.ninjas().values()].filter((n) => n[4] === 1 && n[19] > 0);
  const nameOf = (id) => (game.ninjas().get(id) || [])[2] || '#' + id;
  const changes = [];
  const teamIds = () => new Set(slots.map((s) => s.id));
  const pickFor = (part, listed) => { // the card to add for one partner name
    const fits = cards.filter((n) => (game.chainKnown(part) ? game.chainFits(part, n[0]) : listed.includes(n[0])));
    const mine = owned.find((c) => c.type === 1 && !used.has(c.seq) && fits.some((n) => n[0] === c.ninja_id));
    if (mine) return { pick: { seq: mine.seq }, id: mine.ninja_id, how: 'your own' };
    const best = fits.sort((x, y) => (y[11] || 0) - (x[11] || 0) || (/god/i.test(y[2]) ? 1 : 0) - (/god/i.test(x[2]) ? 1 : 0))[0];
    return best ? { pick: { give: best[0] }, id: best[0], how: 'new' } : null;
  };
  const satisfied = (part, listed) => [...teamIds()].some((id) => (game.chainKnown(part) ? game.chainFits(part, id) : listed.includes(id)));
  const first = slots.length; // only the ninjas that were in the team (partners added here do not pull in partners of their own)
  for (let i = 0; i < first; i++) {
    const s = slots[i];
    for (const r of game.matchRows(s.id)) {
      if (r[5] === 0) continue; // leader effect: always on
      const text = String(r[4]).trim();
      // equipment / ninjutsu chains
      for (const [col, isJutsu] of [[14, false], [15, true]]) {
        const want = r[col];
        if (!(want > 0)) continue;
        if (Object.values(s.equip).some((e) => e.id === want && (isJutsu ? e.type === 6 || true : true))) continue;
        let kind;
        if (isJutsu) kind = [5, 6, 7, 8].find((k) => !s.equip[k]);
        else { const er = game.table('equipmentinfo').rows.find((x) => x[0] === want); kind = er ? ({ 0: 1, 1: 2, 2: 3 }[er[3]]) : 0; }
        if (!kind) continue;
        const type = isJutsu ? 6 : { 1: 2, 2: 3, 3: 4 }[kind];
        const mine = ownedFree(type, want);
        const old = s.equip[kind];
        s.equip[kind] = mine ? { seq: mine.seq, id: want, level: mine.level } : { give: want, id: want, level: 50 };
        if (mine) used.add(mine.seq);
        const nm = isJutsu ? ((game.table('ninjutsuinfo').rows.find((x) => x[0] === want) || [])[2]) : ((game.table('equipmentinfo').rows.find((x) => x[0] === want) || [])[2]);
        changes.push(`${nameOf(s.id)}: equip ${mine ? 'your' : 'a new'} ${nm || '#' + want}${old ? ' (replaces what was there)' : ''}  [${text}]`);
      }
      // partner chains
      const p = game.chainPartsOf(r);
      const listed = r.slice(6, 14).filter((x) => x > 0);
      if (!p && !listed.length) continue;
      const parts = p ? p.parts : [null];
      const missing = parts.filter((part) => !(part ? satisfied(part, listed) : [...teamIds()].some((id) => listed.includes(id))));
      if (!missing.length || (p && p.any && missing.length < parts.length)) continue;
      const need = p && p.any ? missing.slice(0, 1) : missing;
      if (slots.length + need.length > view.max) { changes.push(`${nameOf(s.id)}: no free team slot for [${text}]`); continue; }
      for (const part of need) {
        const c = part ? pickFor(part, listed) : (() => { const mine = owned.find((o) => o.type === 1 && !used.has(o.seq) && listed.includes(o.ninja_id)); return mine ? { pick: { seq: mine.seq }, id: mine.ninja_id, how: 'your own' } : { pick: { give: listed[0] }, id: listed[0], how: 'new' }; })();
        if (!c) continue;
        if (c.pick.seq) used.add(c.pick.seq);
        slots.push({ ninja: c.pick, id: c.id, level: 50, newlife: 0, growth: 0, equip: {} });
        changes.push(`add ${c.how === 'new' ? 'a new' : 'your'} ${nameOf(c.id)} for ${nameOf(s.id)}  [${text}]`);
      }
    }
  }
  const plan = slots.map((s) => ({ ninja: s.ninja, level: s.level, newlife: s.newlife, growth: s.growth,
    equip: Object.fromEntries(Object.entries(s.equip).map(([k, e]) => [k, e.seq ? { seq: e.seq, level: e.level, newlife: e.newlife || 0 } : { give: e.give, level: e.level || 50, newlife: 0 }])) }));
  return { plan, changes };
}

// ---- Gear calculator: the strongest weapon / armor / trinket / seal / 4 ninjutsu for every ninja in the team ----------------------
// mode 'owned' = only cards the player has and nobody else in the team wears; 'best' = also new cards (level 50, rebirth 3 for equipment).
// The score is that ninja with the team screen's own math (game.teamSlots on the one ninja: gear stats, seal %, ninjutsu, gear and ninjutsu
// SETS, "Equip X" chains), on `keys` (all stats for Best gear, the goal's for Best team). Sets need several pieces at once, so besides the best
// piece per place it also tries every complete set (weapon, armor, trinket, seal of one gear set; the 4 ninjutsu of a ninjutsu set).
// Until 7 Nov 2026 sets did not count here, so DEAN got strong single pieces and no set (Riskeric's full "Armed" set is +45 % attack).
const KTYPE = { 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 6, 7: 6, 8: 6 };
// The 34 ninjutsu with m_rate 1.0 (ids 56-89: "level 1", damage 10-40, some named like the top ones) are special versions no drop gives;
// our team-attack model counts a ninjutsu as rate x 20 %, so these would read as +20 % each and four of them double a team. Gear tools
// leave them out and use the normal ninjutsu (m_rate 0.15).
const realJutsu = (id) => { const r = game.table('ninjutsuinfo').rows.find((x) => x[0] === id); return !!r && Number(r[4]) < 1; };
const ALLSTATS = ['al', 'ah', 'dl', 'dh', 'cl', 'ch'];
function gearSolver(db, pl, mode, keys) {
  const cards = new Map(db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=?').all(pl.uid, pl.server_id).map((c) => [c.seq, c]));
  const equipRows = game.table('equipmentinfo').rows;
  const catalog = (type) => {
    if (type <= 4) return equipRows.filter((r) => r[5] === 1 && ({ 0: 2, 1: 3, 2: 4 }[r[3]]) === type).map((r) => r[0]);
    if (type === 5) return game.table('markinfo').rows.map((r) => r[0]);
    return game.table('ninjutsuinfo').rows.filter((r) => realJutsu(r[0])).map((r) => r[0]);
  };
  const catalogs = {};
  const newPiece = (type, id) => ({ seq: 0, type, ninja_id: id, level: 50, newlife: type <= 4 ? 3 : 0 });
  const value = (ninja, pick) => {
    const eq = Object.entries(pick).filter(([, c]) => c).map(([k, c]) => ({ ...c, slot: 1, kind: Number(k) }));
    const st = game.teamSlots([{ ...ninja, slot: 0 }], eq, null)[0];
    return keys.reduce((t, k) => t + (st[k] || 0), 0);
  };
  const better = (x, y) => (x.level || 0) - (y.level || 0) || (x.newlife || 0) - (y.newlife || 0);
  const memo = new Map(); // 'best' mode: the same card always gets the same gear
  // one ninja: cur = { kind: card } it wears now; free(type) = the owned pieces it may take (not worn by another ninja of the plan)
  function solve(ninja, cur, free) {
    const mkey = mode === 'best' && `${ninja.ninja_id}|${ninja.level}|${ninja.newlife}|${ninja.starlevel}|${ninja.breaklvl || 0}`;
    if (mkey && memo.has(mkey)) { // same pieces again; an owned one another ninja already took -> a free copy of it, else a new one
      const out = {};
      for (const [k, c] of Object.entries(memo.get(mkey))) {
        if (!c.seq) { out[k] = c; continue; }
        const f = free(c.type).filter((x) => x.ninja_id === c.ninja_id).sort((x, y) => better(y, x))[0];
        out[k] = f || newPiece(c.type, c.ninja_id);
      }
      return out;
    }
    // candidates per type: the best owned copy of each id (+ every id new in 'best' mode); own copies win ties
    const cand = {};
    const candOf = (type) => {
      if (cand[type]) return cand[type];
      const byId = new Map();
      for (const c of free(type)) { if (type === 6 && !realJutsu(c.ninja_id)) continue; const o = byId.get(c.ninja_id); if (!o || better(c, o) > 0) byId.set(c.ninja_id, c); }
      if (mode === 'best') for (const id of (catalogs[type] = catalogs[type] || catalog(type))) if (!byId.has(id)) byId.set(id, newPiece(type, id));
      return (cand[type] = byId);
    };
    let pick = { ...cur }, best = value(ninja, pick); // special ninjutsu the ninja already wears stay unless something beats them
    for (const k of [1, 2, 3, 4, 5, 6, 7, 8]) { // the best piece for each place
      const others = new Set([5, 6, 7, 8].filter((x) => x !== k && pick[x]).map((x) => pick[x].ninja_id)); // 4 different ninjutsu
      for (const c of candOf(KTYPE[k]).values()) {
        if (k >= 5 && others.has(c.ninja_id)) continue;
        if (pick[k] && pick[k].seq === c.seq && pick[k].ninja_id === c.ninja_id) continue;
        const v = value(ninja, { ...pick, [k]: c });
        if (v > best) { best = v; pick = { ...pick, [k]: c }; }
      }
    }
    for (const row of game.table('skill_suit_info').rows) { // complete sets
      const ids = row.slice(4, 8);
      const places = row[3] === 2 ? [1, 2, 3, 4] : [5, 6, 7, 8];
      const pieces = places.map((k, i) => candOf(row[3] === 2 ? KTYPE[k] : 6).get(ids[i]));
      if (pieces.some((c) => !c)) continue;
      const t = { ...pick };
      places.forEach((k, i) => { t[k] = pieces[i]; });
      const v = value(ninja, t);
      if (v > best) { best = v; pick = t; }
    }
    if (mkey) memo.set(mkey, { ...pick });
    return pick;
  }
  return { solve, cards };
}
// Best gear for the team as it is (Team editor buttons): every ninja in team order; a piece taken off one ninja may go to a later one.
function gearPlan(db, pl, mode) {
  const view = teamView(db, pl);
  const { solve, cards } = gearSolver(db, pl, mode, ALLSTATS);
  const inUse = new Set(view.slots.flatMap((s) => [s.ninja.seq, ...Object.values(s.equip).filter(Boolean).map((e) => e.seq)]));
  const freed = new Set(), taken = new Set();
  const equipRows = game.table('equipmentinfo').rows;
  const nameOf = (type, id) => (type === 1 ? (game.ninjas().get(id) || [])[2] : type <= 4 ? (equipRows.find((r) => r[0] === id) || [])[2]
    : type === 5 ? (game.table('markinfo').rows.find((r) => r[0] === id) || [])[2] : (game.table('ninjutsuinfo').rows.find((r) => r[0] === id) || [])[2]) || '#' + id;
  const changes = [], plan = [];
  for (const s of view.slots) {
    const ninja = cards.get(s.ninja.seq);
    const cur = {};
    for (const [k, e] of Object.entries(s.equip)) if (e) cur[k] = cards.get(e.seq);
    const mine = new Set(Object.values(cur).map((c) => c.seq));
    const free = (type) => [...cards.values()].filter((c) => c.type === type && !taken.has(c.seq) && (!inUse.has(c.seq) || freed.has(c.seq) || mine.has(c.seq)));
    const before = sum(slotTotal(ninja, cur)), pick = solve(ninja, cur, free), after = sum(slotTotal(ninja, pick));
    for (const k of Object.keys(pick)) {
      const c = pick[k], was = cur[k];
      if (c.seq) taken.add(c.seq);
      if (was && was !== c) freed.add(was.seq);
      if (!was || was.ninja_id !== c.ninja_id || was.seq !== c.seq) {
        const label = ['', 'weapon', 'armor', 'trinket', 'seal', 'ninjutsu', 'ninjutsu', 'ninjutsu', 'ninjutsu'][k];
        changes.push(`${nameOf(1, ninja.ninja_id)}: ${label} ${was ? nameOf(was.type, was.ninja_id) + ' -> ' : ''}${c.seq ? 'your' : 'a new'} ${nameOf(c.type, c.ninja_id)}`);
      }
    }
    if (after > before) changes.push(`   = ${nameOf(1, ninja.ninja_id)} total stats ${before.toLocaleString('en-US')} -> ${after.toLocaleString('en-US')} (+${Math.round((after / Math.max(1, before) - 1) * 100)}%)`);
    plan.push({ ninja: { seq: ninja.seq }, level: ninja.level, newlife: ninja.newlife || 0, growth: ninja.starlevel || 0, equip: gearToPlan(pick) });
  }
  return { plan, changes };
}
// that ninja's stats with this gear (team screen math, the ninja alone), and the plan format setteam takes
const slotTotal = (ninja, pick) => game.teamSlots([{ ...ninja, slot: 0 }], Object.entries(pick).filter(([, c]) => c).map(([k, c]) => ({ ...c, slot: 1, kind: Number(k) })), null)[0];
const sum = (st) => ALLSTATS.reduce((t, k) => t + (st[k] || 0), 0);
const gearToPlan = (pick) => Object.fromEntries(Object.entries(pick).filter(([, c]) => c).map(([k, c]) => [k, c.seq ? { seq: c.seq, level: c.level, newlife: c.newlife || 0 } : { give: c.ninja_id, level: c.level, newlife: c.newlife }]));

// ---- Best team: the line-up with the highest attack (or defence), chains included ------------------------------------------------
// Scores line-ups with the team screen's own math (game.teamSlots: card stats, gear, sets, seals, chains; the team-wide parts like card
// sets, gates, title and pets only multiply that sum, so they don't change which line-up wins). Gear stays with its team slot (press Best gear
// afterwards). Copies of a card may be used (owner, 7 Nov 2026: "the highest possible, copies or not"; the game allows them; whether their
// whole-team chains stack is game.RULES.leaderOnce). mode 'owned' = the player's own ninja cards; 'all' = also NEW cards (level 50, rebirth and
// Sage growth of the player's strongest card) of the strongest / most chain-rich ninjas, as many copies as help. Search: per ninja the next
// card is its strongest unused copy (own first; a new one when 'all' and it is stronger or the own copies are used up); fill free slots, then
// per slot try every ninja and keep the best (repeated until nothing improves), plus "chain groups": an inactive chain that needs several
// partners ("Fight with X and Y") tries all of them at once in place of the weakest slots.
function bestTeam(db, pl, goal, mode) {
  const t0 = Date.now();
  const [k0, k1] = goal === 'defense' ? ['dl', 'dh'] : ['al', 'ah'];
  const max = game.maxTeam(db, pl);
  const cards = db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=?').all(pl.uid, pl.server_id);
  const bySeq = new Map(cards.map((c) => [c.seq, c]));
  const teamSeqs = db.prepare('SELECT seq FROM team WHERE uid=? AND server_id=? ORDER BY slot').all(pl.uid, pl.server_id).map((r) => r.seq);
  const eqRows = db.prepare('SELECT e.slot, e.kind, c.* FROM equipped e JOIN cards c ON c.seq=e.seq WHERE e.uid=? AND e.server_id=?').all(pl.uid, pl.server_id);
  const soloMemo = new Map();
  const solo = (c) => { const k = c.seq; if (k > 0 && soloMemo.has(k)) return soloMemo.get(k); const st = game.ninjaStats(c); const v = (st[k0] + st[k1]) / 2; if (k > 0) soloMemo.set(k, v); return v; };
  // A quick estimate to keep the search small: own stat x (1 + its own chain ratios) + its whole-team chain ratios x a team's worth of stats.
  const ratioCol = goal === 'defense' ? 17 : 16;
  const est = (c, teamWorth) => {
    const m = game.matchRows(c.ninja_id);
    const own = m.filter((r) => r[5] === 1).reduce((t, r) => t + (r[ratioCol] || 0), 0), lead = m.filter((r) => r[5] === 0).reduce((t, r) => t + (r[ratioCol] || 0), 0);
    return solo(c) * (1 + own) + lead * teamWorth;
  };
  // pools: per ninja id the player's copies (strongest first) and, in 'all' mode, a template for new copies
  const pools = new Map();
  const pool = (id) => { if (!pools.has(id)) pools.set(id, { own: [], fresh: null }); return pools.get(id); };
  for (const c of cards) if (c.type === 1) pool(c.ninja_id).own.push(c);
  for (const pp of pools.values()) pp.own.sort((x, y) => solo(y) - solo(x));
  const ownTop = [...pools.values()].map((pp) => pp.own[0]).sort((x, y) => solo(y) - solo(x));
  const worth = (ownTop[0] ? solo(ownTop[0]) : 1000) * max / 2;
  // the ninjas the search looks at: the best 160 owned ones by the estimate (+ the ones in the team now)
  let ids = ownTop.map((c) => [c.ninja_id, est(c, worth)]).sort((x, y) => y[1] - x[1]).slice(0, 160).map(([id]) => id);
  for (const seq of teamSeqs) { const c = bySeq.get(seq); if (c && !ids.includes(c.ninja_id)) ids.push(c.ninja_id); }
  if (mode === 'all') {
    const top = ownTop[0] || {};
    const nl = top.newlife || 0, gr = top.starlevel || 0;
    const tpl = [...game.ninjas().values()].filter((n) => n[4] === 1 && n[19] > 0)
      .map((n) => ({ seq: 0, type: 1, ninja_id: n[0], level: 50, newlife: nl, starlevel: gr, attri: 1, breaklvl: 0 }));
    for (const c of tpl.map((c) => [c, est(c, worth)]).sort((x, y) => y[1] - x[1]).slice(0, 160).map(([c]) => c)) {
      pool(c.ninja_id).fresh = c;
      if (!ids.includes(c.ninja_id)) ids.push(c.ninja_id);
    }
  }
  let freshN = 0;
  const ownEntry = (c) => ({ key: 's' + c.seq, card: c, own: true });
  // the next card of ninja id for a team, slot `skip` left out (its card may be chosen again)
  const nextCard = (id, team, skip) => {
    const pp = pools.get(id);
    if (!pp) return null;
    const used = new Set(team.filter((_, j) => j !== skip).map((x) => x.key));
    const own = pp.own.find((c) => !used.has('s' + c.seq));
    if (pp.fresh && (!own || solo(pp.fresh) > solo(own))) {
      const cur = skip >= 0 && team[skip];
      if (cur && !cur.own && cur.card.ninja_id === id) return cur; // the new copy already there
      freshN++;
      return { key: 'n' + id + '.' + freshN, card: { ...pp.fresh, seq: -freshN }, own: false };
    }
    return own ? ownEntry(own) : null;
  };
  let evals = 0;
  const cache = new Map(); // card + slot gear -> stats (gear stays with its slot, so only the chains change between line-ups)
  const slotsOf = (team) => game.teamSlots(team.map((x, i) => ({ ...x.card, slot: i })), eqRows.filter((e) => e.slot <= team.length), null, cache);
  const score = (team) => { evals++; return slotsOf(team).reduce((t, s) => t + (s[k0] + s[k1]) / 2, 0); };
  const startTeam = teamSeqs.map((seq) => bySeq.get(seq)).filter((c) => c && c.type === 1).map(ownEntry);
  const search = (init) => {
  let team = init;
  while (team.length < max) { // fill free slots
    let best = null, bv = -1;
    for (const id of ids) { const c = nextCard(id, team, -1); if (!c) continue; const v = score([...team, c]); if (v > bv) { bv = v; best = c; } }
    if (!best) break;
    team.push(best);
  }
  let cur = score(team);
  for (let pass = 0; pass < 10; pass++) {
    let changed = false;
    for (let i = 0; i < team.length; i++) { // best card for each slot
      let pick = null;
      for (const id of ids) {
        const c = nextCard(id, team, i);
        if (!c || c.key === team[i].key) continue;
        const t2 = team.slice(); t2[i] = c;
        const v = score(t2);
        if (v > cur + 0.5) { cur = v; pick = c; }
      }
      if (pick) { team[i] = pick; changed = true; }
    }
    // chain groups: an inactive chain of a team ninja that needs several partners -> try them all at once in place of the weakest slots
    const slots = slotsOf(team);
    const contrib = team.map((_, j) => cur - score(team.filter((__, x) => x !== j)));
    for (let i = 0; i < team.length; i++) {
      for (const r of game.matchRows(team[i].card.ninja_id)) {
        if (r[5] !== 1 || slots[i].active.includes(r[0])) continue;
        const p = game.chainPartsOf(r);
        if (!p || p.any || p.parts.length < 2 || p.parts.length >= team.length) continue;
        const want = [];
        for (const part of p.parts) {
          if (!game.chainKnown(part)) { want.length = 0; break; }
          if (team.some((x) => game.chainFits(part, x.card.ninja_id))) continue; // that partner is in already
          const id = ids.filter((x) => game.chainFits(part, x) && !want.includes(x)).sort((x, y) => (pools.get(y).own.length ? 1 : 0) - (pools.get(x).own.length ? 1 : 0))[0];
          if (!id) { want.length = 0; break; }
          want.push(id);
        }
        if (!want.length) continue;
        const weakest = team.map((_, j) => j).filter((j) => j !== i).sort((x, y) => contrib[x] - contrib[y]).slice(0, want.length);
        if (weakest.length < want.length) continue;
        const t2 = team.slice();
        let ok = true;
        weakest.forEach((j, n) => { const c = nextCard(want[n], t2, j); if (c) t2[j] = c; else ok = false; });
        if (!ok) continue;
        const v = score(t2);
        if (v > cur + 0.5) { team = t2; cur = v; changed = true; break; }
      }
    }
    if (!changed) break;
  }
  return { team, cur };
  };
  // from the team as it is and from an empty team (a different line-up may win); the higher one counts
  const runs = [search(startTeam.slice(0, max)), search([])];
  const team = runs[0].cur >= runs[1].cur ? runs[0].team : runs[1].team;
  const cand = ids;
  // report: full totals (card sets, gates, title, pets) before and after, the changes and the chains that switch on
  const nameOf = (id) => (game.ninjas().get(id) || [])[2] || '#' + id;
  const chainText = (id) => String((game.table('ninjamatch').rows.find((r) => r[0] === id) || [])[4] || '').trim();
  // gear: the best gear for every ninja of the new line-up (sets count; own pieces in 'owned', new ones allowed in 'all'). A piece taken off
  // one ninja may go to a later one; no piece is given to two ninjas.
  const solver = gearSolver(db, pl, mode === 'all' ? 'best' : 'owned', [k0, k1]);
  const inUse = new Set(eqRows.map((e) => e.seq)), taken = new Set(), freed = new Set();
  const gearNew = team.map((x, i) => {
    const cur = {};
    eqRows.filter((e) => e.slot === i + 1).forEach((e) => { cur[e.kind] = bySeq.get(e.seq); });
    const mine = new Set(Object.values(cur).map((c) => c.seq));
    const free = (type) => cards.filter((c) => c.type === type && !taken.has(c.seq) && (!inUse.has(c.seq) || freed.has(c.seq) || mine.has(c.seq)));
    const pick = solver.solve(x.card, cur, free);
    for (const k of Object.keys(pick)) { const c = pick[k]; if (c.seq) taken.add(c.seq); if (cur[k] && cur[k].seq !== c.seq) freed.add(cur[k].seq); }
    for (const k of Object.keys(cur)) if (!pick[k]) freed.add(cur[k].seq);
    return pick;
  });
  const eqNew = gearNew.flatMap((pick, i) => Object.entries(pick).map(([k, c]) => ({ ...c, slot: i + 1, kind: Number(k) })));
  const totalOf = (tm, eq) => { const s = game.teamSlots(tm.map((x, i) => ({ ...x.card, slot: i })), eq, null); return { slots: s, total: game.teamTotals(db, pl.uid, pl.server_id, s).total }; };
  const A = totalOf(startTeam.slice(0, max), eqRows), B = totalOf(team, eqNew);
  const fmt = (t) => ({ attack: `${t.al}-${t.ah}`, defense: `${t.dl}-${t.dh}`, atk: Math.round((t.al + t.ah) / 2), def: Math.round((t.dl + t.dh) / 2) });
  const changes = [];
  team.forEach((x, i) => {
    const was = startTeam[i];
    if (!was || was.key !== x.key) changes.push(`slot ${i + 1}: ${was ? nameOf(was.card.ninja_id) + ' -> ' : ''}${x.own ? 'your' : 'a NEW'} ${nameOf(x.card.ninja_id)} (Lv ${x.card.level}${x.card.newlife ? ', rebirth ' + x.card.newlife : ''})`);
  });
  const activeBefore = new Set(A.slots.flatMap((s) => s.active)), activeAfter = B.slots.flatMap((s, i) => s.active.map((id) => ({ id, who: team[i].card.ninja_id })));
  const seen = new Set(), links = activeAfter.filter((a) => !activeBefore.has(a.id) && !seen.has(a.id) && seen.add(a.id)).map((a) => `${nameOf(a.who)}: ${chainText(a.id)}`);
  const lost = [...activeBefore].filter((id) => !activeAfter.some((a) => a.id === id)).map((id) => chainText(id));
  const plan = team.map((x, i) => ({ ninja: x.own ? { seq: x.card.seq } : { give: x.card.ninja_id }, level: x.card.level, newlife: x.card.newlife || 0,
    growth: x.card.starlevel || 0, equip: gearToPlan(gearNew[i]) }));
  // gear in short: pieces that change, new pieces, complete sets before and after
  const setName = (id) => (game.table('skill_suit_info').rows.find((r) => r[0] === id) || [])[2] || '#' + id;
  const fullSets = (slots) => { const m = new Map(); for (const sl of slots) for (const x of sl.sets || []) if (x.num >= 4) m.set(x.id, (m.get(x.id) || 0) + 1); return [...m.entries()].map(([id, n]) => `${setName(id)} x${n}`).join(', ') || 'none'; };
  let moved = 0, fresh = 0;
  gearNew.forEach((pick, i) => { for (const [k, c] of Object.entries(pick)) { const was = eqRows.find((e) => e.slot === i + 1 && e.kind === Number(k)); if (!was || was.seq !== c.seq) moved++; if (!c.seq) fresh++; } });
  if (moved) changes.push(`gear: ${moved} pieces change${fresh ? ` (${fresh} new)` : ''}; complete sets ${fullSets(A.slots)} -> ${fullSets(B.slots)}`);
  // the new team in short: "22x Hokage Naruto (God) (3 new), Mother Kaguya ..."
  const group = new Map();
  for (const x of team) { const g = group.get(x.card.ninja_id) || { n: 0, fresh: 0 }; g.n++; if (!x.own) g.fresh++; group.set(x.card.ninja_id, g); }
  const lineup = [...group.entries()].sort((x, y) => y[1].n - x[1].n).map(([id, g]) => `${g.n > 1 ? g.n + 'x ' : ''}${nameOf(id)}${g.fresh ? ` (${g.fresh} new)` : ''}`);
  return { plan, changes, lineup, links, lost, before: fmt(A.total), after: fmt(B.total), chains: { before: activeBefore.size, after: new Set(activeAfter.map((a) => a.id)).size },
    max, candidates: cand.length, evals, ms: Date.now() - t0, gain: Math.round(((goal === 'defense' ? fmt(B.total).def / Math.max(1, fmt(A.total).def) : fmt(B.total).atk / Math.max(1, fmt(A.total).atk)) - 1) * 1000) / 10 };
}

// The search in a separate process at the lowest CPU priority (bestteam-worker.js), so the game keeps answering players while it runs
// (on the cloud machine Riskeric's team takes ~2 minutes); one at a time, 5 minutes at most. An in-memory save (tests) has no file: it runs here.
let bestTeamBusy = false;
function bestTeamInThread(db, pl, goal, mode) {
  const file = db.location ? db.location() : null;
  if (!file) return Promise.resolve({ ok: true, ...bestTeam(db, pl, goal, mode) });
  if (bestTeamBusy) return Promise.resolve({ ok: false, error: 'a Best team search is already running, try again in a moment' });
  bestTeamBusy = true;
  return new Promise((resolve) => {
    const child = require('child_process').fork(path.join(__dirname, 'bestteam-worker.js'), [], { stdio: ['ignore', 'inherit', 'inherit', 'ipc'] });
    try { require('os').setPriority(child.pid, 19); } catch (e) { /* not allowed here: it still runs */ }
    const done = (r) => { if (!bestTeamBusy) return; bestTeamBusy = false; clearTimeout(timer); resolve(r); };
    const timer = setTimeout(() => { child.kill(); done({ ok: false, error: 'the search took too long' }); }, 300000);
    child.once('message', done);
    child.once('error', (e) => done({ ok: false, error: e.message }));
    child.once('exit', (code) => done({ ok: false, error: 'the search stopped (' + code + ')' }));
    child.send({ dbPath: file, uid: pl.uid, sid: pl.server_id, goal, mode, leaderOnce: game.RULES.leaderOnce });
  });
}

// ---- Fight benchmark: the player's real team against enemy teams with a fixed total defence, played many times with the
// server's fight rule (each ninja rolls its attack low..high, worn ninjutsu fire with their chance and add damage, attack is spent on
// enemy defence in order: game.battleXml). Shows the win chance, how many ninjas a win needs and where that defence sits in the story.
function benchmark(db, pl, targets, runs = 300) {
  const ts = game.teamStats(db, pl.uid, pl.server_id);
  const team = db.prepare('SELECT t.slot, c.* FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot').all(pl.uid, pl.server_id);
  const jRows = db.prepare('SELECT e.slot, c.ninja_id, c.level FROM equipped e JOIN cards c ON c.seq=e.seq WHERE e.uid=? AND e.server_id=? AND e.kind BETWEEN 5 AND 8').all(pl.uid, pl.server_id);
  const jt = game.table('ninjutsuinfo').rows;
  const mine = team.map((t, i) => {
    const q = ts.fight[i] || {}, chakra = Math.round(((q.cl || 0) + (q.ch || 0)) / 2);
    const jutsu = jRows.filter((r) => r.slot === i + 1).map((r) => { const n = jt.find((x) => x[0] === r.ninja_id) || []; return { rate: game.jutsuRate(n), dmg: (n[10] || 0) + (n[18] || 0) * Math.max(0, (r.level || 1) - 1) + Math.round(chakra * 0.2) }; });
    return { name: cardName(1, t.ninja_id), low: q.al || 0, high: q.ah || 0, jutsu };
  });
  const roll = (m) => { let a = m.low + Math.random() * (m.high - m.low); let n = 0; for (const j of m.jutsu) if (n < 2 && Math.random() < j.rate) { a += j.dmg; n++; } return a; };
  const minAtk = mine.reduce((t, m) => t + m.low, 0), maxAtk = mine.reduce((t, m) => t + m.high, 0);
  const results = targets.map((def) => {
    let wins = 0, used = 0;
    for (let r = 0; r < runs; r++) {
      let left = def, k = 0;
      while (k < mine.length && left > 0) { left -= roll(mine[k]); k++; }
      if (left < 0) { wins++; used += k; }
    }
    const st = game.stageForDefence(def);
    return { def, win: Math.round((wins / runs) * 100), ninjas: wins ? Math.round((used / wins) * 10) / 10 : 0,
      where: st ? `story ${st.chap}-${st.stage}` : 'stronger than the last story boss' };
  });
  return { team: mine.map((m) => ({ name: m.name, low: m.low, high: m.high, jutsu: m.jutsu.length })), minAtk, maxAtk, results };
}

// ADMIN_OPEN=1: players may use the item pages (/admin) without the password (owner, 3 Nov 2026: players add resources themselves on
// the public server "for now"; later only their own account). The control panel (/, /manager) and wiping a player stay the owner's.
const OWNER_ONLY = new Set(['/admin/api/reset', '/admin/api/purplename', '/admin/track', '/admin/api/track', '/admin/api/trackuids']);
const openToPlayers = (u) => process.env.ADMIN_OPEN === '1' && !OWNER_ONLY.has(u.pathname);

module.exports = async function admin(req, res, u, db, readBody) {
  if (!authorized(req) && !openToPlayers(u)) {
    res.writeHead(401, { 'WWW-Authenticate': 'Basic realm="Hello Bro admin"' });
    return res.end('password required');
  }
  const owner = authorized(req);
  // players (ADMIN_OPEN) get the item page alone: the control panel around it polls /manager, which would ask them for the password
  if ((u.pathname === '/admin' || u.pathname === '/admin/') && !u.query.embed && owner) return panel(res, 'admin');
  if (u.pathname === '/admin' || u.pathname === '/admin/') {
    if (!pageCache || process.env.HB_DEBUG) pageCache = fs.readFileSync(path.join(__dirname, 'admin.html'), 'utf8');
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    return res.end(owner ? pageCache : pageCache.replace('<body>', '<body class="player"><style>.player [data-v="danger"],.player [data-v="purple"],.player a[href="/manager"]{display:none!important}</style>'));
  }
  game.ensure(db);
  if (u.pathname === '/admin/playerlog') { // progress log per player (playerlog.js), the panel's "Player log" tab
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    return res.end(fs.readFileSync(path.join(__dirname, 'playerlog.html'), 'utf8'));
  }
  if (u.pathname === '/admin/api/playerlog') {
    const pl = findPlayer(db, u.query.uid);
    return json(res, pl ? require('./playerlog').summary(db, pl.uid, pl.server_id) : { rows: [], attack: [], level: [], story: [], logins: 0 });
  }
  if (u.pathname === '/admin/track') { // full progress tracker of chosen accounts (tracker.js), the panel's "Tracker" tab
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    return res.end(fs.readFileSync(path.join(__dirname, 'track.html'), 'utf8'));
  }
  if (u.pathname === '/admin/api/track') {
    const tr = require('./tracker');
    const list = [...tr.uids(db)].map((uid) => db.prepare('SELECT uid, server_id, nick, level FROM players WHERE uid=?').all(uid)).flat();
    const pl = u.query.uid ? findPlayer(db, u.query.uid) : null;
    const who = pl ? { uid: pl.uid, sid: pl.server_id } : list[0] ? { uid: list[0].uid, sid: list[0].server_id } : null;
    const tracked = [...tr.uids(db)];
    if (u.query.drops) return json(res, { tracked, players: list, drops: tr.dropStats(db, u.query.day || '') }); // every player's drops (drop_stats)
    if (!who) return json(res, { tracked, players: list, summary: null, overview: [] });
    return json(res, { tracked, players: list, summary: tr.summary(db, who.uid, who.sid, u.query.day || ''), overview: u.query.overview ? tr.overview(db, who.uid, who.sid) : undefined });
  }
  if (u.pathname === '/admin/api/players') {
    const rows = db.prepare(`SELECT p.uid,p.nick,p.level,p.gold,p.coin,p.energy,p.server_id,
      (SELECT COUNT(*) FROM cards c WHERE c.uid=p.uid AND c.server_id=p.server_id) cards FROM players p ORDER BY p.level DESC, p.uid`).all();
    const purple = require('./specialnames');
    return json(res, rows.map((p) => ({ ...p, key: p.uid + ':' + p.server_id, vip: vip.level(db, p.uid, p.server_id), purple: purple.get(db, p.uid), purplecolor: (purple.info(db, p.uid) || {}).color || '', purplefx: (purple.info(db, p.uid) || {}).effect || '' })));
  }
  if (u.pathname === '/admin/api/catalog') {
    const q = String(u.query.q || '').toLowerCase(), cat = String(u.query.cat || ''), stars = Number(u.query.stars) || 0;
    const list = catalog().filter((x) => (!cat || x.cat === cat) && (!stars || x.stars === stars) && (!q || x.name.toLowerCase().includes(q)));
    return json(res, { total: list.length, items: u.query.all ? list : list.slice(0, 300) });
  }
  if (u.pathname === '/admin/api/team') {
    const pl = findPlayer(db, u.query.uid);
    return json(res, pl ? teamView(db, pl) : { max: 0, slots: [], owned: {} });
  }
  if (u.pathname === '/admin/api/inventory') {
    const pl = findPlayer(db, u.query.uid);
    if (!pl) return json(res, { cards: [], props: [] });
    const cards = db.prepare('SELECT seq, type, ninja_id, level, newlife, starlevel FROM cards WHERE uid=? AND server_id=? ORDER BY type, seq DESC').all(pl.uid, pl.server_id)
      .map((c) => ({ seq: c.seq, kind: CARD_TYPES[c.type] || '?', name: cardName(c.type, c.ninja_id), level: c.level, newlife: c.newlife || 0, growth: c.starlevel || 0, cat: c.type === 1 ? 'ninja' : c.type <= 4 ? 'equip' : c.type === 5 ? 'seal' : 'ninjutsu' }));
    const items = new Map(game.table('consumeinfo').rows.map((r) => [r[1], r[2]]));
    const props = Object.entries(game.propCounts(db, pl.uid, pl.server_id)).filter(([, n]) => n > 0).map(([id, n]) => {
      id = Number(id);
      const name = id >= game.CHIP_BASE ? ((game.table('piece_info').rows.find((r) => r[0] === id - game.CHIP_BASE) || [])[2] || '#') + ' fragment'
        : items.get(id) || { 9999: 'Ninja souls', 9998: 'Gate souls', 9996: 'Arena reputation', 9995: 'Boss reputation', 9994: 'War merit' }[id] || 'Item #' + id;
      return { id, name, count: n };
    });
    return json(res, { cards, props });
  }
  if (req.method === 'POST') {
    let b;
    try { b = JSON.parse(await readBody(req)); } catch { return json(res, { ok: false, error: 'bad json' }); }
    // Award Center mail (awardcenter.js): to one player or (b.all) everyone; the player claims it in the game ("Receive" on Home)
    if (u.pathname === '/admin/api/sendmail') {
      const to = b.all ? 'all' : findPlayer(db, b.uid);
      if (!to) return json(res, { ok: false, error: 'no such player' });
      const r = require('./awardcenter').send(db, to, b.title, b.content, { gold: Number(b.gold) || 0, silver: Number(b.silver) || 0, renown: Number(b.renown) || 0 });
      return json(res, r.error ? { ok: false, error: r.error } : { ok: true, sent: r.sent });
    }
    if (u.pathname === '/admin/api/trackuids') return json(res, { ok: true, tracked: require('./tracker').setUids(db, String(b.uids || '').split(/[ ,]+/)) }); // owner only
    const pl = findPlayer(db, b.uid);
    if (!pl) return json(res, { ok: false, error: 'no such player' });
    if (u.pathname === '/admin/api/give') {
      if (b.field === 'renown' || b.field === 'souls') { game.propAdd(db, pl.uid, pl.server_id, b.field === 'renown' ? 9996 : 9999, Math.trunc(Number(b.amount)) || 0); return json(res, { ok: true }); }
      if (b.field === 'vip') { vip.setLevel(db, pl.uid, pl.server_id, Number(b.amount)); return json(res, { ok: true }); }
      const col = { gold: 'gold', coin: 'coin', energy: 'energy', level: 'level' }[b.field];
      if (!col) return json(res, { ok: false, error: 'bad field' });
      const amt = Math.trunc(Number(b.amount));
      if (!Number.isFinite(amt)) return json(res, { ok: false, error: 'bad amount' });
      const sql = col === 'level' ? 'UPDATE players SET level=? WHERE uid=? AND server_id=?' : `UPDATE players SET ${col}=MAX(0,${col}+?) WHERE uid=? AND server_id=?`;
      db.prepare(sql).run(amt, pl.uid, pl.server_id);
      return json(res, { ok: true });
    }
    if (u.pathname === '/admin/api/givething') { // one catalog entry
      const n = Math.min(Math.max(Math.trunc(b.count) || 1, 1), 999);
      const entry = catalog().find((x) => x.cat === b.cat && x.id === Number(b.id));
      if (!entry) return json(res, { ok: false, error: 'unknown thing' });
      const got = giveOne(db, pl, entry.cat, entry.id, n, { level: b.level, newlife: b.newlife, growth: b.growth });
      return json(res, { ok: got > 0, given: got, name: entry.name, error: got ? '' : 'nothing could be given' });
    }
    if (u.pathname === '/admin/api/bulk') { // every entry of a category (optionally one star level), count each
      const n = Math.min(Math.max(Math.trunc(b.count) || 1, 1), 99);
      const list = catalog().filter((x) => x.cat === b.cat && (!b.stars || x.stars === Number(b.stars)));
      if (!list.length) return json(res, { ok: false, error: 'nothing in that group' });
      if (list.length * n > 5000) return json(res, { ok: false, error: `that is ${list.length * n} things; pick a star level or a smaller count` });
      let got = 0;
      for (const x of list) got += giveOne(db, pl, x.cat, x.id, n, { level: b.level, newlife: b.newlife, growth: b.growth });
      return json(res, { ok: true, given: got, kinds: list.length });
    }
    if (u.pathname === '/admin/api/setcard') { // change level / rebirth of a card the player already owns
      const card = db.prepare('SELECT * FROM cards WHERE uid=? AND server_id=? AND seq=?').get(pl.uid, pl.server_id, b.seq);
      if (!card) return json(res, { ok: false, error: 'no such card' });
      const cat = card.type === 1 ? 'ninja' : card.type <= 4 ? 'equip' : card.type === 5 ? 'seal' : 'ninjutsu';
      const c = clampCard(cat, b.level, b.newlife, b.growth);
      setCard(db, card.seq, c);
      return json(res, { ok: true, level: c.lv, newlife: c.nl, growth: c.gr });
    }
    if (u.pathname === '/admin/api/unlockall') return json(res, { ok: true, ...game.unlockAll(db, pl) });
    if (u.pathname === '/admin/api/bench') {
      const t = (Array.isArray(b.targets) ? b.targets : []).map(Number).filter((x) => x > 0).slice(0, 12);
      return json(res, { ok: true, ...benchmark(db, pl, t.length ? t : [100000, 500000, 1000000, 2000000, 4000000, 8000000]) });
    }
    if (u.pathname === '/admin/api/gearplan') return json(res, { ok: true, ...gearPlan(db, pl, b.mode === 'best' ? 'best' : 'owned') });
    if (u.pathname === '/admin/api/chainplan') return json(res, { ok: true, ...chainPlan(db, pl) });
    if (u.pathname === '/admin/api/bestteam') return json(res, await bestTeamInThread(db, pl, b.goal === 'defense' ? 'defense' : 'attack', b.mode === 'all' ? 'all' : 'owned'));
    if (u.pathname === '/admin/api/setteam') return json(res, applyTeam(db, pl, b.slots));
    if (u.pathname === '/admin/api/setprop') { // set the exact amount of one item / fragment / souls
      const id = Math.trunc(Number(b.id)), n = Math.max(0, Math.min(Math.trunc(Number(b.count)) || 0, 999999999));
      if (!id) return json(res, { ok: false, error: 'bad item' });
      const have = game.propCounts(db, pl.uid, pl.server_id)[id] || 0;
      game.propAdd(db, pl.uid, pl.server_id, id, n - have);
      return json(res, { ok: true, count: n });
    }
    if (u.pathname === '/admin/api/delcard') {
      const inTeam = ['team', 'team_alt'].some((t) => db.prepare(`SELECT 1 FROM ${t} WHERE uid=? AND server_id=? AND seq=?`).get(pl.uid, pl.server_id, b.seq));
      if (inTeam) return json(res, { ok: false, error: 'that card is in a team (Team 1 or 2); take it out first' });
      for (const t of ['equipped', 'equipped_alt']) db.prepare(`DELETE FROM ${t} WHERE uid=? AND server_id=? AND seq=?`).run(pl.uid, pl.server_id, b.seq);
      db.prepare('DELETE FROM cards WHERE uid=? AND server_id=? AND seq=?').run(pl.uid, pl.server_id, b.seq);
      return json(res, { ok: true });
    }
    if (u.pathname === '/admin/api/purplename') { // specialnames.js: the name glows (No.1 Shinobi list + Home top bar), in its colour, and survives a reset
      const sn = require('./specialnames');
      const r = b.on ? sn.set(db, pl.uid, b.nick || pl.nick, b.color, b.effect) : sn.clear(db, pl.uid);
      return json(res, r.error ? { ok: false, error: r.error } : { ok: true, nick: r.nick, color: r.color, effect: r.effect });
    }
    if (u.pathname === '/admin/api/reset') {
      resetPlayer(db, pl.uid, pl.server_id);
      return json(res, { ok: true });
    }
    if (u.pathname === '/admin/api/givecard') { // old page / scripts
      if (!game.ninjas().has(b.ninja)) return json(res, { ok: false, error: 'unknown character' });
      const n = Math.min(Math.max(Math.trunc(b.count) || 1, 1), 100);
      for (let i = 0; i < n; i++) game.giveCard(db, pl.uid, pl.server_id, b.ninja);
      return json(res, { ok: true });
    }
  }
  res.writeHead(404); res.end('not found');
};

module.exports.authorized = authorized;
module.exports.resetPlayer = resetPlayer; // for tools/dev/smoke.js
module.exports.panel = panel;
module.exports.bestTeam = bestTeam; // for tools/dev and smoke
module.exports.bestTeamInThread = bestTeamInThread;
