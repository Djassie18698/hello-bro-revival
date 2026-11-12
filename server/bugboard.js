// Bug fixer board for the control panel (owner, 12 Nov 2026: "make it work in combination with bug fixer", in the iPhone app).
// The phone version of the PC app Bug Fixer (tools/fixer-viewer): "For you" (the fixer's questions, fixes waiting to go live) and the
// Board (every report from the player's post to Live). Read only. Reads the two Discord forums (#bugs-and-issues, #bug-fixer) with the
// bot token from discord/.env (read here on the server, never sent to the page), at most every 30 s and only while someone looks.
// The stages follow tools/fixer-viewer/Store.cs MakeCard exactly, so the phone and the PC app agree.
//   /admin/bugs            the page (admin password, server.js)
//   /admin/bugs/api        the board as JSON
//   /admin/bugs/api/post   ?id=<player post>&fx=<fixer post>  the messages of one report
const fs = require('fs');
const path = require('path');

const API = 'https://discord.com/api/v10';
const APP_MARK = '📱 **Owner** (Bug fixer app):';
const REFRESH_MS = 30000;

function env() {
  const d = {};
  try {
    for (const l of fs.readFileSync(path.join(__dirname, '..', 'discord', '.env'), 'utf8').split(/\r?\n/)) {
      const m = /^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/.exec(l);
      if (m) d[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch (e) {}
  return d;
}

const st = { botId: '', guildId: '', ownerId: '', bugs: '', fixer: '', posts: new Map(), board: null, fetched: 0, error: '', busy: null, msgCache: new Map() };
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function call(p) {
  const token = env().DISCORD_TOKEN;
  if (!token) throw new Error('No bot token in discord/.env, so Discord cannot be read here.');
  for (let i = 0; i < 4; i++) {
    const r = await fetch(API + p, { headers: { Authorization: 'Bot ' + token, 'User-Agent': 'HelloBroPanel (bug board, 1.0)' }, signal: AbortSignal.timeout(20000) });
    if (r.status === 429) { let w = 1; try { w = (await r.json()).retry_after || 1; } catch (e) {} await wait(w * 1000 + 250); continue; }
    if (r.status === 401) throw new Error('the bot token in discord/.env does not work');
    if (!r.ok) throw new Error('Discord said ' + r.status);
    return r.status === 204 ? null : r.json();
  }
  throw new Error('Discord asked to slow down; try again in a minute');
}

const snowMs = (id) => { try { return Number((BigInt(id) >> 22n) + 1420070400000n); } catch (e) { return 0; } };
const oneLine = (s, n) => { s = String(s || '').replace(/[*_`~>#|]/g, '').replace(/<@!?\d+>/g, '@you').replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 1) + '…' : s; };
function whoOf(author, content, forum) {
  const id = author && author.id;
  if (id === st.ownerId) return 'you';
  if (id === st.botId) return String(content || '').startsWith(APP_MARK) ? 'you' : forum === 'fixer' ? 'fixer' : 'helper';
  return (author && (author.global_name || author.username)) || 'player';
}

async function pool(items, n, fn) { const q = items.slice(); await Promise.all(Array.from({ length: n }, async () => { while (q.length) await fn(q.shift()); })); }

async function refresh() {
  const e = env();
  st.ownerId = String(e.OWNER_IDS || '').split(',')[0].trim();
  if (!st.botId) {
    st.botId = (await call('/users/@me')).id;
    st.guildId = e.GUILD_ID || (await call('/users/@me/guilds'))[0].id;
  }
  const chans = (await call('/guilds/' + st.guildId + '/channels')) || [];
  const tagNames = {};
  st.bugs = st.fixer = '';
  for (const c of chans) {
    if (c.type !== 15) continue;
    if (c.name === 'bugs-and-issues') st.bugs = c.id; else if (c.name === 'bug-fixer') st.fixer = c.id; else continue;
    for (const t of c.available_tags || []) tagNames[t.id] = t.name;
  }
  const forums = [st.bugs, st.fixer].filter(Boolean);
  const threads = [];
  const act = await call('/guilds/' + st.guildId + '/threads/active');
  for (const t of (act && act.threads) || []) if (forums.includes(t.parent_id)) threads.push(t);
  for (const f of forums) { try { threads.push(...(((await call('/channels/' + f + '/threads/archived/public?limit=40')) || {}).threads || [])); } catch (x) {} }
  const seen = new Set(), list = [];
  await pool(threads.filter((t) => t.id && !seen.has(t.id) && seen.add(t.id)), 4, async (t) => {
    let p = st.posts.get(t.id);
    if (!p) { p = { id: t.id, starter: '', lastId: '', reportId: '', lastWho: '', lastText: '', lastTime: 0, author: '' }; st.posts.set(t.id, p); }
    p.forum = t.parent_id === st.fixer ? 'fixer' : 'bugs';
    p.title = t.name || '';
    p.created = snowMs(t.id);
    p.pinned = ((t.flags || 0) & 2) !== 0;
    p.tags = (t.applied_tags || []).map((x) => tagNames[x]).filter(Boolean);
    if (!p.starter) {
      try {
        const m = await call('/channels/' + t.id + '/messages/' + t.id);
        p.starter = m.content || ' ';
        const a = m.author || {};
        p.author = a.id === st.ownerId ? 'you' : a.id === st.botId ? (p.forum === 'fixer' ? 'fixer' : 'helper') : (a.global_name || a.username || '');
        const rm = /report-id:\s*(\d{17,20})/.exec(p.starter);
        if (rm) p.reportId = rm[1];
      } catch (x) {}
    }
    const lastId = t.last_message_id || '';
    if (lastId !== p.lastId) {
      try {
        const msgs = (await call('/channels/' + t.id + '/messages?limit=10')) || [];
        const last = msgs.find((m) => !(m.author && m.author.id === st.botId && String(m.content || '').startsWith('👀 Got it')));
        if (last) {
          let txt = last.content || '';
          p.lastWho = whoOf(last.author, txt, p.forum);
          p.lastTime = Date.parse(last.timestamp) || 0;
          if (txt.startsWith(APP_MARK)) txt = txt.slice(APP_MARK.length);
          if (!txt.trim() && (last.attachments || []).length) txt = '(a picture)';
          p.lastText = oneLine(txt, 220);
        }
        p.lastId = lastId;
      } catch (x) {}
    }
    list.push(p);
  });
  let pinned = list.find((x) => x.forum === 'fixer' && x.pinned) || list.find((x) => x.forum === 'fixer' && x.title.startsWith('📦'));
  if (pinned) { try { pinned.starter = (await call('/channels/' + pinned.id + '/messages/' + pinned.id)).content || ''; } catch (x) {} }
  st.board = build(list, pinned);
  st.fetched = Date.now();
  st.error = '';
}

const CLOSED = ['Not possible', 'Not a bug'];
function card(pl, fx) {
  const tp = pl ? pl.tags : [], tf = fx ? fx.tags : [], has = (n) => tp.includes(n) || tf.includes(n);
  const c = { playerId: pl ? pl.id : null, fixerId: fx ? fx.id : null, tags: [...new Set([...tf, ...tp])] };
  c.id = c.fixerId || c.playerId;
  c.stopped = tf.includes('Stopped');
  if (c.stopped) c.stage = 'closed';
  else if (has('Live')) c.stage = 'live';
  else if (tf.includes('Fixed, not live yet') || tp.includes('Fixed')) c.stage = 'ready';
  else if (tf.includes('Question for you')) c.stage = fx.lastWho === 'you' ? 'fixer' : 'you';
  else if (CLOSED.some(has)) c.stage = 'closed';
  else if (has('Wish')) c.stage = fx && fx.lastWho === 'fixer' ? 'you' : 'closed';
  else if (fx || tp.includes('With the developer')) c.stage = 'fixer';
  else c.stage = 'player';
  const last = [pl, fx].filter(Boolean).sort((a, b) => b.lastTime - a.lastTime)[0];
  const title = pl ? pl.title : fx.title;
  c.title = oneLine(title.replace('🧪', ''), 140);
  c.test = /^\s*(🧪\s*)?test\b/i.test(title) || (fx && fx.title.includes('🧪'));
  c.player = pl ? pl.author : (fx.author === 'you' || fx.starter.startsWith(APP_MARK) ? 'you' : '');
  c.request = !pl && fx && !fx.reportId;
  c.created = Math.min(pl ? pl.created : Infinity, fx ? fx.created : Infinity);
  c.lastTime = last.lastTime || c.created; c.lastWho = last.lastWho; c.lastText = last.lastText;
  c.why = c.stage === 'you' ? (has('Wish') ? 'A wish: should it be built?' : 'The fixer asked you something')
    : c.stage === 'fixer' && fx && fx.lastWho === 'you' ? 'You answered: the fixer picks it up on its next check' : c.stopped ? 'Stopped by you' : '';
  c.link = 'https://discord.com/channels/' + st.guildId + '/' + (c.fixerId || c.playerId);
  return c;
}
function build(list, pinned) {
  const byReport = new Map();
  for (const p of list) if (p.forum === 'fixer' && p.reportId && !byReport.has(p.reportId)) byReport.set(p.reportId, p);
  const used = new Set(), cards = [];
  for (const pl of list.filter((p) => p.forum === 'bugs')) { const fx = byReport.get(pl.id); if (fx) used.add(fx.id); cards.push(card(pl, fx)); }
  for (const fx of list.filter((p) => p.forum === 'fixer' && p !== pinned && !used.has(p.id))) cards.push(card(null, fx));
  cards.sort((a, b) => b.lastTime - a.lastTime);
  const goLive = [];
  let behind = '';
  if (pinned && !/nothing waiting/i.test(pinned.starter)) {
    for (const l of pinned.starter.split('\n')) {
      const t = l.trim();
      if (/^([-•*]|\d+\.)\s+/.test(t)) goLive.push(oneLine(t.replace(/^([-•*]|\d+\.)\s+/, ''), 220));
      else if (/^behind the scenes/i.test(t)) behind = oneLine(t, 140);
    }
  }
  return { cards, goLive, goLiveBehind: behind, goLiveKnown: !!pinned, goLiveLink: pinned ? 'https://discord.com/channels/' + st.guildId + '/' + pinned.id : '' };
}

// refresh in the background; the page gets what is there now
function ensureFresh() {
  if (st.busy || Date.now() - st.fetched < REFRESH_MS) return;
  st.busy = refresh().catch((e) => { st.error = e.message || String(e); }).finally(() => { st.busy = null; });
}

async function messages(id, forum) {
  const c = st.msgCache.get(id);
  if (c && Date.now() - c.t < 20000) return c.list;
  const arr = ((await call('/channels/' + id + '/messages?limit=60')) || []).slice().reverse();
  const list = [];
  for (const m of arr) {
    if (m.type !== 0 && m.type !== 19) continue;
    let txt = m.content || '';
    const mine = m.author && m.author.id === st.botId;
    if (mine && txt.startsWith('👀 Got it')) continue;
    if (mine && txt.startsWith(APP_MARK)) txt = txt.slice(APP_MARK.length).trimStart();
    const images = (m.attachments || []).filter((a) => /^image\//.test(a.content_type || '') || /\.(png|jpe?g|webp|gif)(\?|$)/i.test(a.url || '')).map((a) => a.url);
    list.push({ who: whoOf(m.author, m.content, forum), time: Date.parse(m.timestamp) || 0, text: txt.replace(/<@!?(\d+)>/g, (x, i) => (i === st.ownerId ? '@you' : '@someone')), images });
  }
  st.msgCache.set(id, { t: Date.now(), list });
  return list;
}

// the same sample cards as the PC app's --demo (Store.cs DemoData)
function demo() {
  const n = Date.now(), h = 3600000;
  const mk = (stage, title, player, tags, who, text, age, why) => ({ id: title, title, player, stage, tags, lastWho: who, lastText: text, created: n - age * h, lastTime: n - age * h / 3, why: why || '', link: 'https://discord.com/channels/@me' });
  return { ok: true, demo: true, fetched: n, error: '', goLiveKnown: true, goLiveLink: 'https://discord.com/channels/@me', goLiveBehind: 'Behind the scenes: 3 other changes',
    goLive: ['Double EXP Pill now doubles the EXP on screen too (buva)', 'Secret Shop grain x10 costs 400 souls again (buva)'],
    cards: [
      mk('player', 'Arena rewards not arriving after rank 50', 'buva', ['Needs info'], 'helper', 'Thanks! Which screen shows the reward, and is it every day?', 0.3),
      mk('fixer', 'Pet does not attack in boss fights', 'Ronin', ['Working on it', 'With the developer'], 'fixer', 'Found it: the boss fight skips the pet. Fixing now.', 2),
      mk('fixer', 'Shop shows 0 gold after a top-up', 'polterslave', ['New report', 'With the developer'], 'helper', 'Report passed on to the developer.', 1),
      mk('you', 'Extra stones in Sage Growth: which numbers?', 'buva', ['Question for you', 'With the developer'], 'fixer', 'Option 1: the photo numbers (+0.2 % a stone). Option 2: ours. I would pick 1.', 5, 'The fixer asked you something'),
      mk('you', 'Wish: a daily login calendar', 'Goat', ['Wish'], 'fixer', 'Should this be built?', 3, 'A wish: should it be built?'),
      mk('ready', 'Double EXP Pill gave normal EXP', 'buva', ['Fixed, not live yet', 'Fixed'], 'fixer', 'Fixed. It goes live with the next update.', 9),
      mk('live', 'Golden Choji EXP card gives far less EXP', 'Ronin', ['Live'], 'fixer', 'Live now on the public server.', 26),
      mk('closed', 'Add a dark mode to the shop', 'kid', ['Wish', 'Stopped'], 'you', 'Not now.', 30, 'Stopped by you'),
    ] };
}

function json(res, code, o) { res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(o)); }

async function handle(req, res) {
  const u = new URL(req.url, 'http://x');
  if (u.pathname === '/admin/bugs/api' && u.searchParams.get('demo')) return json(res, 200, demo()); // sample cards for screenshots (?demo=1 on the page)
  if (u.pathname === '/admin/bugs/api') {
    ensureFresh();
    if (!st.board && st.busy && u.searchParams.get('wait')) await Promise.race([st.busy, wait(25000)]);
    return json(res, 200, { ok: !!st.board, loading: !st.board && !!st.busy, error: st.error, fetched: st.fetched, ...(st.board || { cards: [], goLive: [] }) });
  }
  if (u.pathname === '/admin/bugs/api/post') {
    const ids = [['bugs', u.searchParams.get('id')], ['fixer', u.searchParams.get('fx')]].filter(([, i]) => /^\d{17,20}$/.test(i || ''));
    try {
      if (!st.botId) await (st.busy || refresh());
      const out = {};
      for (const [f, i] of ids) out[f] = await messages(i, f);
      return json(res, 200, out);
    } catch (e) { return json(res, 502, { error: e.message || String(e) }); }
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-cache' });
  return res.end(fs.readFileSync(path.join(__dirname, 'bugboard.html')));
}

module.exports = { handle, _card: card, _build: build };
