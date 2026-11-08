// Builds the wiki's data (server/wiki/data.json) from the game's own tables (server/data) and the server's event lists, so the wiki
// always shows what the game and this server really do. The page itself is server/wiki/index.html + app.js + style.css; the game server
// serves it at /wiki/ (server.js). Icons: python -I tools/build_wiki_icons.py first (needs re/obb), it writes server/wiki/img/.
// usage: node tools/build_wiki.js
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..');
const game = require('../server/game');
const T = (n) => game.table(n).rows;
const OUT = path.join(ROOT, 'server', 'wiki');

const icons = JSON.parse(fs.readFileSync(path.join(OUT, 'img', 'icons.json'), 'utf8'));
const ic = (kind, name) => (name && icons.names[kind + '/' + name] !== undefined ? kind + ':' + icons.names[kind + '/' + name] : '');
const cjk = (s) => /[　-鿿＀-￯]/.test(String(s || ''));
const clean = (s) => String(s == null ? '' : s).replace(/\s+/g, ' ').replace(/[（]/g, ' (').replace(/[）]/g, ')').replace(/\s+\)/g, ')').trim();
const pct = (v) => Math.round(Number(v || 0) * 1000) / 10;

// ---- entities -------------------------------------------------------------------------------------------------------------
const consume = new Map(T('consumeinfo').map((r) => [r[1], r]));
const itemName = (id) => clean((consume.get(id) || [])[2] || `Item ${id}`);

// Shinobi cards: the admin catalog's rule (ninjainfo [4] = 1 and real stats), one row per name + stars + attack type.
const shinobi = [], cardIds = new Set();
{
  const seen = new Set();
  for (const r of game.ninjas().values()) {
    if (r[4] !== 1 || !(r[19] > 0)) continue;
    const key = r[2] + '|' + r[11] + '|' + r[6];
    if (seen.has(key)) continue;
    seen.add(key);
    cardIds.add(r[0]);
    const kind = r[20] > r[22] ? 'Attack' : r[22] > r[20] ? 'Defence' : 'Balanced';
    shinobi.push({
      id: r[0], name: clean(r[2]), stars: r[11] || 0, kind, icon: ic('n', r[3]),
      atk: [r[19], r[20]], def: [r[21], r[22]], ckr: [r[23], r[24]], grow: { atk: [r[25], r[26]], def: [r[27], r[28]], ckr: [r[29], r[30]] },
      desc: clean(r[16]), quote: clean(r[17]), jutsu: r[12] || 0,
      temper: [r[37], r[38], r[39], r[40]].map(clean).filter(Boolean), rebirth: [r[41], r[42], r[43]].map(clean).filter(Boolean),
      chains: [], partOf: [], get: [],
    });
  }
}
const byCard = new Map(shinobi.map((c) => [c.id, c]));
// any id of a card (also the element duplicates the list leaves out) -> the listed card with that name, stars and type
const cardFor = (id) => {
  if (byCard.has(id)) return byCard.get(id);
  const r = game.ninjas().get(id);
  if (!r) return null;
  return shinobi.find((c) => c.name === clean(r[2]) && c.stars === (r[11] || 0) && (c.kind === (r[20] > r[22] ? 'Attack' : r[22] > r[20] ? 'Defence' : 'Balanced'))) ||
    shinobi.find((c) => c.name === clean(r[2]) && c.stars === (r[11] || 0)) || null;
};

const SLOT = { 0: 'Weapon', 1: 'Armour', 2: 'Trinket' };
const gear = T('equipmentinfo').map((r) => ({
  id: r[0], name: clean(r[2]), slot: SLOT[r[3]] || 'Gear', stars: r[6] || 0, icon: ic('e', r[4]),
  atk: [r[7], r[8]], def: [r[9], r[10]], ckr: [r[11], r[12]], grow: { atk: [r[13], r[14]], def: [r[15], r[16]], ckr: [r[17], r[18]] },
  desc: clean(r[19]), sell: r[20] || 0, chains: [], sets: [], get: [],
}));
const byGear = new Map(gear.map((g) => [g.id, g]));

const jutsu = T('ninjutsuinfo').filter((r) => !cjk(r[2])).map((r) => ({
  id: r[0], name: clean(r[2]), stars: r[5] || 0, rate: pct(r[4]), special: Number(r[4]) >= 1, level: r[6] || 0, targets: r[8] || 0,
  damage: r[10] || 0, add: { atk: pct(r[11]), def: pct(r[12]), ckr: pct(r[13]) }, price: r[26] || 0, desc: clean(r[27]), icon: ic('j', r[28]),
  chains: [], sets: [], owners: [], get: [],
}));
const byJutsu = new Map(jutsu.map((j) => [j.id, j]));

const seals = T('markinfo').filter((r) => !cjk(r[2]) && !/material/i.test(r[2])).map((r) => ({
  id: r[0], name: clean(r[2]), fragment: r[3] === 1, stars: r[6] || 0, icon: ic('s', r[4]), effect: clean(r[7]), sell: r[8] || 0, sets: [], get: [],
}));
const bySeal = new Map(seals.map((s) => [s.id, s]));

const pets = T('petinfo').map((r) => ({
  id: r[0], name: clean(r[2]), icon: ic('n', r[3]), skill: clean(r[5]), skillDesc: clean(r[6]).replace('%d', String(r[12] || '')), stars: r[8] || 0,
  atk: r[9], def: r[10], ckr: r[11], skillAtk: r[12], perLevel: { atk: r[13], def: r[14], ckr: r[15], skill: r[16] }, desc: clean(r[28]), get: [],
}));
const byPet = new Map(pets.map((p) => [p.id, p]));

const items = T('consumeinfo').filter((r) => !cjk(r[2])).map((r) => ({
  id: r[1], name: clean(r[2]), icon: ic('p', r[3]), gold: game.shopGold(r) || 0, silver: r[5] || 0, desc: clean(r[6]),
  festival: require('../server/festival').isItem(r[1]), get: [],
}));
const byItem = new Map(items.map((i) => [i.id, i]));

const pieces = new Map(T('piece_info').map((r) => [r[0], r]));
// piece_info [3]: 1 shinobi, 2 gear, 4 ninjutsu, 5 pet; [6] the card it makes, [7] how many make one
const pieceTarget = (pid) => {
  const r = pieces.get(pid);
  if (!r) return null;
  if (r[3] === 1) return cardFor(r[6]);
  if (r[3] === 2) return byGear.get(r[6]);
  if (r[3] === 4) return byJutsu.get(r[6]);
  if (r[3] === 5) return byPet.get(r[6]);
  return null;
};

// ---- what a drop gives (dropinfo: [3] ninja, [4] gear, [5] ninjutsu, [6] seal, [7] item, [8] fragment, [9] souls, [10] gold,
// [11] silver, [12] = 1 random pack, [13] amount, [14] pet) ------------------------------------------------------------------
const drops = new Map(T('dropinfo').map((r) => [r[0], r]));
function dropGives(id) {
  const d = drops.get(id);
  if (!d) return null;
  const n = d[13] || 1;
  if (d[12] === 1) return { what: 'pack', n, name: clean(d[2]) };
  if (d[3]) { const c = cardFor(d[3]); return c && { what: 'card', ent: c, n }; }
  if (d[4]) { const g = byGear.get(d[4]); return g && { what: 'gear', ent: g, n }; }
  if (d[5]) { const j = byJutsu.get(d[5]); return j && { what: 'jutsu', ent: j, n }; }
  if (d[6]) { const s = bySeal.get(d[6]); return s && { what: 'seal', ent: s, n }; }
  if (d[7]) { const i = byItem.get(d[7]); return i && { what: 'item', ent: i, n }; }
  if (d[8]) { const t = pieceTarget(d[8]); return t && { what: 'fragment', ent: t, n, piece: d[8] }; }
  if (d[14]) { const p = byPet.get(d[14]); return p && { what: 'pet', ent: p, n }; }
  return null;
}
// a "how to get it" line on the entity a drop gives (fragments go on the card they make, as "fragments")
function source(id, how, where) {
  const g = dropGives(id);
  if (!g || !g.ent) return;
  const line = { how: g.what === 'fragment' ? `${how} (${g.n} fragment${g.n > 1 ? 's' : ''})` : g.n > 1 ? `${how} (x${g.n})` : how, where };
  if (!g.ent.get.some((x) => x.how === line.how && x.where === line.where)) g.ent.get.push(line);
}

// ---- where things come from (what this server really hands out) ------------------------------------------------------------
// New player: the three starter choices (game.ensureStarterTeam / rl_w_reg2)
for (const id of [55, 57, 56]) { const c = cardFor(id); if (c) c.get.push({ how: 'Starter', where: 'One of the three cards you can pick when you make a character (Neji, Shikamaru or Sakura)' }); }
// Recruit (Shop): game.recruitPools by stars, banners by the stars they can give (game.js RATES)
{
  const banners = [['Purple recruit', '300 gold, free every 3 days', [4, 5]], ['Blue recruit', '150 gold, free every 2 days', [3, 4, 5]], ['Recruitment Order', 'one Recruitment Order a pull', [2, 3, 4, 5]]];
  for (const r of game.ninjas().values()) {
    if (!(r[4] === 1 && r[0] < 2000 && (r[6] === 0 || r[6] === 1))) continue;
    const c = cardFor(r[0]);
    if (!c) continue;
    for (const [name, cost, stars] of banners) if (stars.includes(r[11]) && !c.get.some((x) => x.how === name)) c.get.push({ how: name, where: `Shop > Recruit (${cost})` });
  }
}
// Mystery shop (game.secretPicks: rows with a weight and a drop, English names; costs ninja souls)
for (const r of T('secret_shop')) {
  if (!(r[9] > 0 && r[10] > 0 && /^[ -~]*$/.test(r[2]))) continue;
  source(r[10], 'Mystery shop', `Shop > Mystery shop, ${r[8]} souls (it shows 6 random offers, new ones every few hours)`);
}
// Story bosses: the named reward on the boss row (game.bossNamedDrop, BOSS_NAMED_CHANCE)
const chapterName = new Map(T('storyinfo').map((r) => [r[1], clean(r[2])]));
for (const r of T('roundinfo')) {
  if (!r[38]) continue;
  const d = game.bossNamedDrop(r);
  if (d) source(d, 'Story boss', `${chapterName.get(r[4]) || 'Chapter ' + r[4]}: ${clean(r[5])} (${Math.round(game.BOSS_NAMED_CHANCE * 100)} % chance a win)|round:${r[0]}`);
}
// Festivals (festival.js THEMES trades: [id, cost A, cost B, limit, {drop} | {prop, n}])
{
  const fest = require('../server/festival');
  for (const th of Object.values(fest.THEMES)) {
    const a = itemName(th.a), b = itemName(th.b);
    for (const t of th.trades) {
      const cost = [t[1] ? `${t[1]} ${a}` : '', t[2] ? `${t[2]} ${b}` : ''].filter(Boolean).join(' + ');
      const where = `${th.name} event trade: ${cost}`;
      if (t[4].drop) source(t[4].drop, 'Festival', where);
      else if (t[4].prop && byItem.get(t[4].prop)) byItem.get(t[4].prop).get.push({ how: `Festival (x${t[4].n || 1})`, where });
    }
    for (const id of [th.a, th.b]) if (byItem.get(id)) byItem.get(id).get.push({ how: 'Festival', where: `${th.name}: drops from fights while the event runs, also in the Shop then` });
  }
}
// Limited Super Ninja: 1st place of each hour wins that hour's god card (limitsuper.js)
for (const g of require('../server/limitsuper').godList()) {
  const c = cardFor(g.id);
  if (c) c.get.push({ how: 'Limited Super Ninja', where: 'Home > Super Ninja: every god card has its own hour; 1st place in that hour\'s points ranking wins it' });
}
// God Recruit (godrecruit.js CARDS [slot, ninja id, drop, ...])
for (const r of require('../server/godrecruit').CARDS) {
  const c = cardFor(r[1]);
  if (c && !c.get.some((x) => x.how === 'God Recruit')) c.get.push({ how: 'God Recruit', where: 'The God Recruit event wheel' });
}
// Ninja Test score shop: fragments of your own god card, for god cards the game has a fragment pack for (tupo.fragmentDropFor)
for (const [pid, r] of pieces) {
  if (r[3] !== 1 || r[4] !== 3) continue;
  const d = T('dropinfo').filter((x) => x[8] === pid && x[12] !== 1).sort((x, y) => (y[13] || 1) - (x[13] || 1))[0];
  if (d) source(d[0], 'Ninja Test shop', 'Base > Ninja Test > score shop, 100 score (only when you own this god card)');
}
// Fragments merge into the card (Backpack > Fragments > Synthesis)
for (const [pid, r] of pieces) {
  const t = pieceTarget(pid);
  if (t && !t.get.some((x) => x.how === 'Fragments')) t.get.push({ how: 'Fragments', where: `Collect ${r[7]} of its fragments, then Backpack > Fragments > Synthesis` });
}
// Story training chest (the reward wheel after a win, dropinfo 25: a random 1-2 star shinobi among other things, game.js)
for (const c of shinobi) if (c.stars <= 2) c.get.push({ how: 'Training chest', where: 'Training: the chest on the reward wheel after a won stage can hold a random 1-2 star shinobi' });
// Shop gift bags (giftinfo; game.packBuy): gear bags give random gear of the stars in the bag's text, fixed packs their one thing
for (const g of gear) {
  if (g.stars >= 2 && g.stars <= 4) g.get.push({ how: 'Shop gift bag', where: `Shop > Gift bags: a 3-star ${g.slot.toLowerCase()} bag gives 2-4 stars` });
  if (g.stars >= 3 && g.stars <= 5) g.get.push({ how: 'Shop gift bag', where: `Shop > Gift bags: a 4-star ${g.slot.toLowerCase()} bag gives 3-5 stars` });
}
for (const r of T('giftinfo')) if (r[7] === 1 && !/bag/i.test(r[2])) source(Math.round(r[8]), 'Shop pack', `Shop > Gift bags: ${clean(r[2])}`);
// Shop items and their prices (rl_r_shoplist: consumeinfo with a gold or silver price; festival items only during their festival)
for (const i of items) {
  if (i.gold > 0 || i.silver > 0) i.get.unshift({ how: 'Shop', where: `Shop > Items, ${i.gold ? i.gold + ' gold' : i.silver + ' silver'}${i.festival ? ' (only while its festival runs)' : ''}` });
}
// Seals: fragments from Plunder, 8 fragments make the seal
for (const s of seals) {
  if (s.fragment) s.get.unshift({ how: 'Plunder', where: 'Spar > Plunder: win against a player who has it (the chance depends on the level difference)' });
  else s.get.unshift({ how: 'Synthesis', where: 'Collect all 8 of its fragments (Plunder), then Synthesis in the seal screen (30 minutes, or 30 gold to finish now)' });
}

// ---- chains (ninjamatch: [3] card, [4] text, [5] effect type, [14] gear, [15] ninjutsu, [16]-[18] ATK/DEF/chakra) ---------------
for (const r of T('ninjamatch')) {
  const c = byCard.get(r[3]);
  if (!c) continue;
  const parts = game.chainPartsOf(r);
  const partners = [];
  if (parts) {
    for (const part of parts.parts) {
      const fits = shinobi.filter((x) => game.chainFits(part, x.id));
      const names = [...new Set(fits.map((x) => x.name))];
      partners.push(names.map((n) => fits.find((x) => x.name === n).id).slice(0, 12));
      for (const x of fits) if (x.id !== c.id && !x.partOf.includes(c.id)) x.partOf.push(c.id);
    }
  }
  const chain = { text: clean(r[4]), team: !r[5], any: !!(parts && parts.any), partners, gear: r[14] || 0, jutsu: r[15] || 0, atk: pct(r[16]), def: pct(r[17]), ckr: pct(r[18]) };
  c.chains.push(chain);
  if (chain.gear && byGear.get(chain.gear)) byGear.get(chain.gear).chains.push(c.id);
  if (chain.jutsu && byJutsu.get(chain.jutsu)) byJutsu.get(chain.jutsu).chains.push(c.id);
}
for (const c of shinobi) if (c.jutsu && byJutsu.get(c.jutsu)) byJutsu.get(c.jutsu).owners.push(c.id);

// ---- gear and ninjutsu sets (skill_suit_info: [3] 2 gear (weapon, armour, trinket, seal in [4]-[7]) / 1 ninjutsu; [8]-[25] flat,
// share pairs for ATK/DEF/chakra at 2/3/4 pieces; [26]-[28] skill chance) ----------------------------------------------------------
const sets = T('skill_suit_info').map((r) => {
  const isJutsu = r[3] === 1;
  const ids = r.slice(4, 8);
  const piecesOf = ids.map((id, i) => (isJutsu ? { kind: 'jutsu', id } : i === 3 ? { kind: 'seal', id } : { kind: 'gear', id })).filter((p) => p.id);
  const bonus = [2, 3, 4].map((n, k) => ({
    n, atk: r[8 + k * 2] || 0, atkPct: pct(r[9 + k * 2]), def: r[14 + k * 2] || 0, defPct: pct(r[15 + k * 2]), ckr: r[20 + k * 2] || 0, ckrPct: pct(r[21 + k * 2]), skill: pct(r[26 + k]),
  }));
  const set = { id: r[0], name: clean(r[2]), type: isJutsu ? 'Ninjutsu set' : 'Gear set', pieces: piecesOf, bonus };
  for (const p of piecesOf) {
    const e = p.kind === 'jutsu' ? byJutsu.get(p.id) : p.kind === 'seal' ? bySeal.get(p.id) : byGear.get(p.id);
    if (e) e.sets.push(set.id);
  }
  return set;
});

// ---- Training: chapters > parts > rounds (roundinfo [4] chapter, [5] name, [7]-[21] enemies, [22] energy, [23] EXP, [24] silver,
// [38] boss, [39]/[40] part, [41] advised level, [42] clears needed / boss tries) ---------------------------------------------------
const chapters = [];
{
  const byChap = new Map();
  for (const r of T('roundinfo')) {
    if (!byChap.has(r[4])) byChap.set(r[4], new Map());
    const parts = byChap.get(r[4]);
    if (!parts.has(r[39])) parts.set(r[39], { id: r[39], name: clean(r[40]), rounds: [] });
    const foes = r.slice(7, 22).filter(Boolean).map((id) => { const n = game.ninjas().get(id); return n ? { name: clean(n[2]), level: n[7] || 0, icon: ic('n', n[3]) } : null; }).filter(Boolean);
    const bd = r[38] ? game.bossNamedDrop(r) : 0, g = bd ? dropGives(bd) : null;
    parts.get(r[39]).rounds.push({
      id: r[0], name: clean(r[5]), boss: !!r[38], energy: r[22] || 0, exp: r[23] || 0, silver: r[24] || 0, level: r[41] || 0,
      clears: game.clearsNeeded(r), foes, reward: g && g.ent ? { what: g.what, id: g.ent.id, name: g.ent.name, icon: g.ent.icon } : null, desc: clean(r[37]),
    });
  }
  for (const [id, parts] of [...byChap].sort((a, b) => a[0] - b[0])) chapters.push({ id, name: chapterName.get(id) || `Chapter ${id}`, parts: [...parts.values()] });
}

// ---- guides (discord/guides: "## " = one chapter) and news (README "What changed recently") --------------------------------------
const CHANNELS = { 1565697833150058507: 'g:install-help', 1565697772986834974: 'g:how-to-play', 1565697836006375542: 'g:faq' };
const DC_NAMES = { 1565697767370653857: 'welcome', 1565697768356319262: 'rules', 1565697769874919515: 'updates', 1565697775549546526: 'general',
  1565697834571927694: 'support', 1565697850376065024: 'screenshots', 1566415215220752444: 'bugs-and-issues', 1566653903972339902: 'announcement', 1567213033456013535: 'server-status' };
const GROUP = { 'how-to-play': 'How to play', 'install-help': 'Install and connect', faq: 'Questions' };
const guides = [];
for (const file of ['how-to-play', 'install-help', 'faq']) {
  const md = fs.readFileSync(path.join(ROOT, 'discord', 'guides', file + '.md'), 'utf8').replace(/\r/g, '');
  const parts = md.split(/^## /m).slice(1);
  for (const p of parts) {
    const nl = p.indexOf('\n');
    const title = p.slice(0, nl).replace(/^\d+\.\s*/, '').trim();
    const body = p.slice(nl + 1).trim().replace(/<#(\d+)>/g, (m, id) => (CHANNELS[id] ? `[[${CHANNELS[id]}]]` : `#${DC_NAMES[id] || 'discord'} on Discord`));
    const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    guides.push({ slug: `${file}--${slug}`, group: GROUP[file], file, title, body });
  }
}
const news = [];
{
  const readme = fs.readFileSync(path.join(ROOT, 'README.md'), 'utf8').replace(/\r/g, '');
  const sec = readme.split(/^## .*What changed recently.*$/m)[1] || '';
  for (const line of sec.split('\n')) {
    const m = /^\|\s*\*\*(.+?)\*\*\s*\|\s*(.+?)\s*\|\s*$/.exec(line);
    if (m) news.push({ day: m[1], text: m[2].replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1').replace(/\*\*|`/g, '').replace(/\s*Full list\s*$/, '').trim() });
    if (/^Every fix/.test(line)) break;
  }
}

// ---- write ----------------------------------------------------------------------------------------------------------------------
const strip = (list) => list.map((e) => { const o = {}; for (const [k, v] of Object.entries(e)) if (!(Array.isArray(v) && !v.length) && v !== '' && v !== 0 && v !== false) o[k] = v; return o; });
const data = {
  built: new Date().toISOString().slice(0, 10),
  icons: { cell: icons.cell, cols: icons.cols, sheets: icons.sheets },
  shinobi: strip(shinobi), gear: strip(gear), jutsu: strip(jutsu), seals: strip(seals), pets: strip(pets), items: strip(items), sets,
  chapters, guides, news,
};
// ---- the home page (server/site, https://ninjaonlinereborn.com): a small file with the numbers, the line-up and the news ----------
// Pictures: python -I tools/build_site_art.py cuts every "art" below out of re/obb (npc/<art>.pvr.ccz = the card's big picture).
const SITE = path.join(ROOT, 'server', 'site');
const HERO = [2091, 2082, 2106, 5010, 2097]; // (ours) the line-up on top, left to right: Itachi, Kakashi, Kyuubi Naruto, Sasuke, Sakura
const FEATURED = [2106, 5010, 2091, 2082, 2029, 2085, 2097, 2103, 2100, 2030, 2039, 2112, 2078, 2088]; // (ours) the shinobi row
const pictureOf = new Map(JSON.parse(fs.readFileSync(path.join(ROOT, 'server', 'data', 'ninjainfo.json'), 'utf8')).rows.map((r) => [r[0], r[3]]));
const card = (id) => {
  const c = shinobi.find((x) => x.id === id);
  if (!c || !pictureOf.get(id)) throw new Error('home page card ' + id + ' is not in the wiki or has no picture');
  return { id, name: c.name, stars: c.stars, kind: c.kind, art: pictureOf.get(id), get: (c.get || []).map((g) => g.how).filter((v, i, a) => a.indexOf(v) === i).slice(0, 3) };
};
const home = {
  counts: { shinobi: shinobi.length, gear: gear.length, jutsu: jutsu.length, seals: seals.length, pets: pets.length, chapters: chapters.length,
    stages: chapters.reduce((n, c) => n + c.parts.reduce((m, p) => m + p.rounds.length, 0), 0) },
  hero: HERO.map(card), featured: FEATURED.map(card),
  chapters: chapters.map((c) => ({ id: c.id, name: c.name })),
  news: news.slice(0, 4),
};

if (process.argv.includes('--check')) { // check.sh (wiki-test.js): the committed data.json + home.json must match the tables, guides and README
  const old = (() => { try { return JSON.parse(fs.readFileSync(path.join(OUT, 'data.json'), 'utf8')); } catch { return {}; } })();
  const oldHome = (() => { try { return fs.readFileSync(path.join(SITE, 'home.json'), 'utf8'); } catch { return ''; } })();
  const same = JSON.stringify({ ...old, built: '' }) === JSON.stringify({ ...data, built: '' }) && oldHome === JSON.stringify(home);
  console.log(same ? 'wiki data is up to date' : 'wiki data is OUT OF DATE: run node tools/build_wiki.js');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(path.join(OUT, 'data.json'), JSON.stringify(data));
fs.mkdirSync(SITE, { recursive: true });
fs.writeFileSync(path.join(SITE, 'home.json'), JSON.stringify(home));
const counts = Object.fromEntries(['shinobi', 'gear', 'jutsu', 'seals', 'pets', 'items', 'sets', 'chapters', 'guides'].map((k) => [k, data[k].length]));
const noGet = shinobi.filter((c) => !c.get.length).length;
console.log('wiki data:', JSON.stringify(counts), `${Math.round(fs.statSync(path.join(OUT, 'data.json')).size / 1024)} KB;`, `${noGet} cards with no known source`);
