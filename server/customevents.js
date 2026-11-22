// Custom events (ours; owner, 21 Nov 2026: "I want to be able to add custom events easily").
// One event = one small text file in the folder `custom-events` next to the save (the top folder, like hellobro.db), so every
// server has its own and an update never touches them. Put a file there, or change one, and it is live at once: no restart.
// The rewritten game (server/webclient, custom.js) shows them behind its own Home button; the phone app does not know them.
//
//   {
//     "id": "weekend-gift",                    a short name, never change it once players claimed (it is what "claimed" hangs on)
//     "title": "Weekend gift",
//     "text": "Log in this weekend and take your gift.",
//     "icon": "activity1",                     optional: a picture name of the game (an event icon, an item icon)
//     "from": "2026-11-21", "to": "2026-11-30",   optional: the days it runs, server clock; without them it always runs
//     "repeat": "daily",                       "once" (the default) or "daily"
//     "need": { "level": 10, "vip": 0 },       optional: who may claim
//     "give": { "gold": 50, "silver": 10000, "items": { "11": 2 }, "drop": 320 }
//     "cost": { "gold": 100 },               optional: what it costs (gold, silver, items): then it is an offer / exchange, not a gift
//     "limit": 3                               optional: how many times (per day when daily); 1 without it
//   }                                          items = consumeinfo id -> how many; drop = one of the game's drop packs (dropinfo id)
//
// Requests: rl_x_custom Cmd 1 = the list (<event id title text icon state left give>; state 0 take it, 1 taken, 2 not for you yet),
// Cmd 2 Id=<id> = claim (the usual <award>). Claims are kept in the table custom_claims. A file that is not valid is skipped and
// named in the server log once. docs/CUSTOM-EVENTS.md is the owner's guide; server/custom-events-examples/ holds samples (not loaded).
'use strict';
const fs = require('fs'), path = require('path');
const game = require('./game');

const DIR = () => process.env.HB_CUSTOM_EVENTS || path.join(process.cwd(), 'custom-events'); // asked on every request: the tests point it elsewhere
const esc = (s) => String(s ?? '').replace(/[<>&"]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;' }[c]));
const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);
const cache = new Map(), warned = new Set();

// every valid event file, read again only when it changed
function load(dir = DIR()) {
  let names = [];
  try { names = fs.readdirSync(dir).filter((n) => n.toLowerCase().endsWith('.json')).sort(); } catch (e) { return []; }
  const out = [];
  for (const name of names) {
    const file = path.join(dir, name);
    let stamp = 0;
    try { stamp = fs.statSync(file).mtimeMs; } catch (e) { continue; }
    let c = cache.get(file);
    if (!c || c.stamp !== stamp) {
      c = { stamp, event: null };
      try { c.event = check(JSON.parse(fs.readFileSync(file, 'utf8').replace(/^﻿/, ''))); }
      catch (e) { if (!warned.has(file + stamp)) { warned.add(file + stamp); console.log('custom event ' + name + ' skipped: ' + e.message); } }
      cache.set(file, c);
    }
    if (c.event && !out.some((e) => e.id === c.event.id)) out.push(c.event);
  }
  return out;
}
// a file's content made safe: throws with a plain reason when something is wrong
function check(e) {
  if (!e || typeof e !== 'object') throw new Error('not an event');
  const id = String(e.id || '').trim();
  if (!/^[A-Za-z0-9_-]{1,40}$/.test(id)) throw new Error('"id" must be 1-40 letters, digits, - or _');
  const day = (v, k) => { if (v === undefined || v === null || v === '') return ''; if (!/^\d{4}-\d{2}-\d{2}$/.test(String(v))) throw new Error('"' + k + '" must look like 2026-11-30'); return String(v); };
  const n = (v) => Math.max(0, Math.floor(Number(v) || 0));
  const pack = (g, what) => {
    const items = {};
    for (const [k, v] of Object.entries((g || {}).items || {})) { if (!game.table('consumeinfo').rows.some((r) => r[0] === Number(k))) throw new Error(what + ' item ' + k + ' does not exist'); if (n(v)) items[Number(k)] = Math.min(9999, n(v)); }
    return { gold: Math.min(1e6, n((g || {}).gold)), silver: Math.min(1e9, n((g || {}).silver)), items };
  };
  const g = e.give || {};
  if (g.drop && !game.table('dropinfo').rows.some((r) => r[0] === Number(g.drop))) throw new Error('drop pack ' + g.drop + ' does not exist');
  const give = { ...pack(g, 'give'), drop: n(g.drop) };
  if (!give.gold && !give.silver && !give.drop && !Object.keys(give.items).length) throw new Error('"give" is empty');
  const cost = pack(e.cost, 'cost'); // optional: what the player pays (an offer or an exchange instead of a gift)
  return { id, title: String(e.title || id).slice(0, 60), text: String(e.text || '').slice(0, 400), icon: String(e.icon || '').replace(/[^A-Za-z0-9_./-]/g, '').slice(0, 60),
    from: day(e.from, 'from'), to: day(e.to, 'to'), repeat: e.repeat === 'daily' ? 'daily' : 'once', limit: Math.max(1, Math.min(999, n(e.limit) || 1)),
    need: { level: n((e.need || {}).level), vip: n((e.need || {}).vip) }, give, cost, paid: !!(cost.gold || cost.silver || Object.keys(cost.items).length) };
}
function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS custom_claims (uid INTEGER, server_id INTEGER, id TEXT, day TEXT, PRIMARY KEY(uid, server_id, id, day))');
  try { db.exec('ALTER TABLE custom_claims ADD COLUMN n INTEGER DEFAULT 1'); } catch (err) { /* already there */ }
}
const running = (e, d = today()) => (!e.from || d >= e.from) && (!e.to || d <= e.to);
const claimDay = (e) => (e.repeat === 'daily' ? today() : '');
const taken = (db, pl, e) => { ensure(db); const r = db.prepare('SELECT n FROM custom_claims WHERE uid=? AND server_id=? AND id=? AND day=?').get(pl.uid, pl.server_id, e.id, claimDay(e)); return r ? r.n || 1 : 0; };
const allowed = (db, pl, e) => (pl.level || 1) >= e.need.level && (!e.need.vip || require('./vip').level(db, pl.uid, pl.server_id) >= e.need.vip);
// 0 = can take it, 1 = all taken (for today), 2 = not for you yet
function state(db, pl, e) { return taken(db, pl, e) >= e.limit ? 1 : allowed(db, pl, e) ? 0 : 2; }
// what an event gives, in words (for the list)
function giveText(e, g = e.give) {
  const bits = [];
  if (g.gold) bits.push(g.gold + ' gold');
  if (g.silver) bits.push(g.silver + ' silver');
  for (const [id, n] of Object.entries(g.items)) { const r = game.table('consumeinfo').rows.find((x) => x[0] === Number(id)); bits.push(n + ' x ' + String(r ? r[2] : 'item ' + id).replace(/\0+$/, '')); }
  if (g.drop) { const r = game.table('dropinfo').rows.find((x) => x[0] === g.drop); bits.push(String(r ? r[2] : 'a gift pack').replace(/\0+$/, '')); }
  return bits.join(', ');
}
function listXml(db, pl, dir) {
  const d = today();
  return '<events>' + load(dir).filter((e) => running(e, d)).map((e) => {
    const left = e.to ? Math.max(0, Math.round((Date.parse(e.to + 'T00:00:00Z') - Date.parse(d + 'T00:00:00Z')) / 86400000)) + 1 : -1;
    const need = e.need.level > 1 || e.need.vip ? [e.need.level > 1 ? 'level ' + e.need.level : '', e.need.vip ? 'VIP ' + e.need.vip : ''].filter(Boolean).join(', ') : '';
    return `<event id="${e.id}" title="${esc(e.title)}" text="${esc(e.text)}" icon="${esc(e.icon)}" state="${state(db, pl, e)}" left="${left}" repeat="${e.repeat}" need="${esc(need)}" give="${esc(giveText(e))}" cost="${esc(e.paid ? giveText(e, e.cost) : '')}" times="${e.limit}" taken="${taken(db, pl, e)}"/>`;
  }).join('') + '</events>';
}
function claim(db, pl, id, dir) {
  const e = load(dir).find((x) => x.id === String(id));
  if (!e || !running(e)) return { error: 'this event is not running' };
  const s = state(db, pl, e);
  if (s === 1) return { error: e.repeat === 'daily' ? 'already taken today' : 'already taken' };
  if (s === 2) return { error: 'you need ' + [e.need.level > 1 ? 'level ' + e.need.level : '', e.need.vip ? 'VIP ' + e.need.vip : ''].filter(Boolean).join(' and ') };
  // an offer: the price is checked and taken first, all of it or nothing
  if (e.paid) {
    const have = game.propCounts(db, pl.uid, pl.server_id);
    if ((pl.gold || 0) < e.cost.gold) return { error: 'not enough gold' };
    if ((pl.coin || 0) < e.cost.silver) return { error: 'not enough silver' };
    for (const [prop, n] of Object.entries(e.cost.items)) if ((have[prop] || 0) < n) return { error: 'you do not have what this costs' };
  }
  const before = taken(db, pl, e);
  if (before >= e.limit) return { error: 'already taken' };
  db.prepare('INSERT INTO custom_claims(uid, server_id, id, day, n) VALUES(?,?,?,?,1) ON CONFLICT(uid, server_id, id, day) DO UPDATE SET n=n+1').run(pl.uid, pl.server_id, e.id, claimDay(e));
  if (e.paid) {
    db.prepare('UPDATE players SET gold=gold-?, coin=coin-? WHERE uid=? AND server_id=?').run(e.cost.gold, e.cost.silver, pl.uid, pl.server_id);
    for (const [prop, n] of Object.entries(e.cost.items)) game.propAdd(db, pl.uid, pl.server_id, Number(prop), -n);
  }
  const awards = [];
  if (e.give.drop) { const a = game.grantDrop(db, pl, e.give.drop); if (a) awards.push(a); }
  if (e.give.gold || e.give.silver) db.prepare('UPDATE players SET gold=gold+?, coin=coin+? WHERE uid=? AND server_id=?').run(e.give.gold, e.give.silver, pl.uid, pl.server_id);
  for (const [prop, n] of Object.entries(e.give.items)) game.propAdd(db, pl.uid, pl.server_id, Number(prop), n);
  awards.push(require('./drops').awardXml({ cards: [], props: e.give.items, coin: e.give.silver, cash: e.give.gold }, 0));
  return { xml: game.mergeAwards(awards) };
}
module.exports = { load, check, listXml, claim, DIR };
