// Tiny Discord command line tool (bot token only, no Claude API key). A Claude session on your PC runs these commands for you.
//   node --env-file=.env dc.js channels
//   node --env-file=.env dc.js read <channel> [count]
//   node --env-file=.env dc.js post <channel> <file.md | ->        ("-" = read the text from stdin)
//   node --env-file=.env dc.js post <channel> <file.md | -> --ping-owner   (tags the owner: for a question only they can answer; owner, 10 Nov 2026)
//   node --env-file=.env dc.js edit <channel> <message-id> <file.md | ->
//   node --env-file=.env dc.js delete <channel> <message-id>        (own messages only)
//   node --env-file=.env dc.js reply <channel> <message-id> <file.md | ->   (answer one message, e.g. a bug report: what got fixed)
//   node --env-file=.env dc.js react <channel> <message-id> [emoji]         (default ✅ = the report is handled)
//   node --env-file=.env dc.js pin <channel> <message-id>                   (pin a message, e.g. the bot's info post)
// The bug fixer's forum (#bug-fixer, owner 10 Nov 2026: one post per report or question, its state as a tag):
//   node --env-file=.env dc.js forum <forum> "<title>" <file.md | -> [--ping-owner] [--tag "<tag>"]...   new post; prints its number
//   node --env-file=.env dc.js posts <forum>                 every post: number, title, tags, who wrote last ("OWNER" = waits for the fixer)
//   node --env-file=.env dc.js tag <post> "<tag>" ["<tag>" ...]   set a post's tags (replaces them; names as the forum has them)
//   node --env-file=.env dc.js pinpost <post>               pin a post at the top of the forum (the fixer's "Waiting to go live" list)
//   a post is a thread: read / post / reply / react work on its number
// <channel> may also be a thread number (the bug report threads of bughelper.js: "Thread: .../<guild>/<thread>" in #bot-logs).
// Same safety rules as the bot: no secrets/IP addresses, no @everyone pings (the only ping is --ping-owner: the first OWNER_IDS user), only own messages are changed.
const fs = require('fs');
const { secretProblem, splitMessage } = require('./tools');

const API = 'https://discord.com/api/v10';
// The owner's Bug fixer app (tools/fixer-viewer) writes in #bug-fixer posts with the bot's account; these messages start with APP_OWNER
// and count as the owner's (owner, 11 Nov 2026). Only the app writes them: bughelper.js never starts a message with it.
const APP_OWNER = /^\u{1F4F1} \*\*Owner\*\* \(Bug fixer app\):/u;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function makeApi(token, fetchFn = fetch) {
  const call = async (method, path, body) => {
    for (let attempt = 0; attempt < 4; attempt++) {
      const res = await fetchFn(API + path, {
        method, headers: { Authorization: `Bot ${token}`, 'Content-Type': 'application/json', 'User-Agent': 'HelloBroBot (local, 1.0)' },
        body: body ? JSON.stringify(body) : undefined,
      });
      if (res.status === 429) { await sleep(((await res.json()).retry_after || 1) * 1000 + 200); continue; }
      if (res.status === 204) return null;
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(`Discord ${res.status}: ${data.message || JSON.stringify(data)}`);
      return data;
    }
    throw new Error('Discord rate limit, try again in a minute');
  };
  return call;
}

async function run(argv, { token, guildId, ownerId = String(process.env.OWNER_IDS || '').split(',')[0].trim(), readText = (p) => (p === '-' ? fs.readFileSync(0, 'utf8') : fs.readFileSync(p, 'utf8')), call = makeApi(token), out = console.log } = {}) {
  const [cmd, chan, a, b] = argv;
  const me = await call('GET', '/users/@me');
  const gid = guildId || (await (async () => { const g = await call('GET', '/users/@me/guilds'); if (g.length !== 1) throw new Error('bot is in ' + g.length + ' servers; set GUILD_ID in .env'); return g[0].id; })());
  const chans = (await call('GET', `/guilds/${gid}/channels`)).filter((c) => [0, 5, 15].includes(c.type)); // text + announcement + forum
  if (cmd === 'channels') return out(chans.map((c) => `${c.id}  #${c.name}`).join('\n'));
  if (!chan) throw new Error('missing channel');
  const r = String(chan).replace(/^<#(\d+)>$/, '$1').replace(/^#/, '').toLowerCase();
  const exact = chans.filter((c) => c.id === r || c.name.toLowerCase() === r);
  // a thread (e.g. a bug report thread of bughelper.js) is not in the channel list: its number is used as it is
  const found = exact.length ? exact : /^\d{17,20}$/.test(r) ? [{ id: r, name: 'thread ' + r }] : chans.filter((c) => c.name.toLowerCase().includes(r));
  if (found.length !== 1) throw new Error(found.length ? `"${chan}" matches several channels: ${found.map((c) => c.name).join(', ')}` : `no channel called "${chan}" (run: channels)`);
  const ch = found[0];
  const guard = (text) => { const bad = secretProblem(text); if (bad) throw new Error(`refused: the text contains ${bad}`); };
  const own = async (id) => { const m = await call('GET', `/channels/${ch.id}/messages/${id}`); if (m.author.id !== me.id) throw new Error('that message is not mine'); return m; };

  if (cmd === 'read') {
    const msgs = (await call('GET', `/channels/${ch.id}/messages?limit=${Math.min(Number(a) || 15, 50)}`)).reverse();
    return out(msgs.map((m) => `[${m.id}] ${m.timestamp ? m.timestamp.slice(0, 16).replace('T', ' ') + ' ' : ''}${m.author.id === me.id ? (APP_OWNER.test(m.content || '') ? 'owner via the Bug fixer app (OWNER)' : '(bot)') : m.author.id === ownerId ? m.author.username + ' (OWNER)' : m.author.username}` +
      `${m.message_reference ? ' (reply to ' + m.message_reference.message_id + ')' : ''}: ${m.content}` +
      (m.attachments || []).map((x) => `\n  [attachment] ${x.url}`).join('') +
      ((m.reactions || []).length ? '\n  [reactions] ' + m.reactions.map((x) => x.emoji.name + x.count).join(' ') : '')).join('\n---\n'));
  }
  if (cmd === 'post') {
    const text = readText(a); guard(text);
    const ping = b === '--ping-owner';
    if (ping && !/^\d{5,25}$/.test(ownerId)) throw new Error('--ping-owner needs OWNER_IDS in discord/.env');
    let first = true;
    for (const part of splitMessage(text)) {
      const tag = ping && first;
      const m = await call('POST', `/channels/${ch.id}/messages`, { content: (tag ? `<@${ownerId}> ` : '') + part, allowed_mentions: tag ? { parse: [], users: [ownerId] } : { parse: [] } });
      out(`posted in #${ch.name}: message id ${m.id}${tag ? ' (owner tagged)' : ''}`); first = false; await sleep(600);
    }
    return;
  }
  if (cmd === 'edit') {
    const text = readText(b); guard(text);
    if (text.length > 2000) throw new Error('too long for one message (max 2000)');
    await own(a); await call('PATCH', `/channels/${ch.id}/messages/${a}`, { content: text, allowed_mentions: { parse: [] } });
    return out('edited ' + a);
  }
  if (cmd === 'delete') { await own(a); await call('DELETE', `/channels/${ch.id}/messages/${a}`); return out('deleted ' + a); }
  if (cmd === 'reply') {
    const text = readText(b); guard(text);
    for (const part of splitMessage(text)) { const m = await call('POST', `/channels/${ch.id}/messages`, { content: part, message_reference: { message_id: a, fail_if_not_exists: true }, allowed_mentions: { parse: [], replied_user: false } }); out(`replied in #${ch.name}: message id ${m.id}`); await sleep(600); }
    return;
  }
  const forumTags = async (forumId, names) => {
    const forum = await call('GET', `/channels/${forumId}`);
    const have = forum.available_tags || [];
    return names.map((n) => { const t = have.find((x) => x.name.toLowerCase() === String(n).toLowerCase()); if (!t) throw new Error(`no tag "${n}" (tags: ${have.map((x) => x.name).join(', ')})`); return t.id; });
  };
  if (cmd === 'forum') {
    if (ch.type !== 15) throw new Error(`#${ch.name} is not a forum`);
    const rest = argv.slice(3), file = rest.find((x, i) => !x.startsWith('--') && (i === 0 || rest[i - 1] !== '--tag'));
    const tags = rest.map((x, i) => (rest[i - 1] === '--tag' ? x : null)).filter(Boolean), ping = rest.includes('--ping-owner');
    const title = String(a || '').trim().slice(0, 100);
    if (!title) throw new Error('missing title');
    const text = readText(file); guard(text); guard(title);
    if (ping && !/^[0-9]{5,25}$/.test(ownerId)) throw new Error('--ping-owner needs OWNER_IDS in discord/.env');
    const parts = splitMessage(text);
    const t = await call('POST', `/channels/${ch.id}/threads`, { name: title, applied_tags: await forumTags(ch.id, tags),
      message: { content: (ping ? `<@${ownerId}> ` : '') + parts[0], allowed_mentions: ping ? { parse: [], users: [ownerId] } : { parse: [] } } });
    for (const part of parts.slice(1)) { await sleep(600); await call('POST', `/channels/${t.id}/messages`, { content: part, allowed_mentions: { parse: [] } }); }
    return out(`new post in #${ch.name}: ${t.id} "${title}"${tags.length ? ' [' + tags.join(', ') + ']' : ''}${ping ? ' (owner tagged)' : ''}`);
  }
  if (cmd === 'posts') {
    if (ch.type !== 15) throw new Error(`#${ch.name} is not a forum`);
    const names = Object.fromEntries((ch.available_tags || []).map((t) => [t.id, t.name]));
    const active = (await call('GET', `/guilds/${gid}/threads/active`)).threads.filter((t) => t.parent_id === ch.id);
    const old = (await call('GET', `/channels/${ch.id}/threads/archived/public?limit=50`).catch(() => ({ threads: [] }))).threads || [];
    const all = [...active, ...old.filter((t) => !active.some((x) => x.id === t.id))].sort((x, y) => (BigInt(y.last_message_id || y.id) > BigInt(x.last_message_id || x.id) ? 1 : -1));
    const lines = [];
    for (const t of all) {
      // the bug helper's quick "👀 Got it" after an owner message doesn't count: the owner's message still waits for the fixer
      const last = (await call('GET', `/channels/${t.id}/messages?limit=10`).catch(() => [])).find((m) => !(m.author.id === me.id && /^👀 Got it/.test(m.content || '')));
      const who = !last ? '?' : last.author.id === me.id ? (APP_OWNER.test(last.content || '') ? 'OWNER' : 'bot') : last.author.id === ownerId ? 'OWNER' : last.author.username;
      lines.push(`[${t.id}] ${t.name} · ${(t.applied_tags || []).map((x) => names[x] || x).join(', ') || 'no tag'} · last: ${who}${last ? ' ' + last.timestamp.slice(0, 16).replace('T', ' ') : ''}${t.thread_metadata && t.thread_metadata.archived ? ' · archived' : ''}`);
    }
    return out(lines.join(String.fromCharCode(10)) || '(no posts)');
  }
  if (cmd === 'pinpost') { // pin a forum post at the top of its forum (Discord allows one pinned post per forum)
    const t = await call('GET', `/channels/${ch.id}`);
    if (!t.parent_id) throw new Error('not a forum post');
    await call('PATCH', `/channels/${ch.id}`, { flags: 2, ...(t.thread_metadata && t.thread_metadata.archived ? { archived: false } : {}) });
    return out('pinned post ' + ch.id);
  }
  if (cmd === 'tag') {
    const t = await call('GET', `/channels/${ch.id}`);
    if (!t.parent_id) throw new Error('not a forum post');
    await call('PATCH', `/channels/${ch.id}`, { applied_tags: await forumTags(t.parent_id, argv.slice(2)), ...(t.thread_metadata && t.thread_metadata.archived ? { archived: false } : {}) });
    return out(`tags of ${ch.id}: ${argv.slice(2).join(', ') || '(none)'}`);
  }
  if (cmd === 'react') { await call('PUT', `/channels/${ch.id}/messages/${a}/reactions/${encodeURIComponent(b || '✅')}/@me`); return out(`reacted ${b || '✅'} on ${a}`); }
  if (cmd === 'pin') { await call('PUT', `/channels/${ch.id}/pins/${a}`); return out('pinned ' + a); }
  throw new Error('unknown command. Use: channels | read | post | edit | delete | reply | react | pin | forum | posts | tag | pinpost');
}

module.exports = { run, makeApi };

if (require.main === module) {
  if (!process.env.DISCORD_TOKEN) { console.error('Missing DISCORD_TOKEN in .env'); process.exit(1); }
  run(process.argv.slice(2), { token: process.env.DISCORD_TOKEN, guildId: process.env.GUILD_ID }).catch((e) => { console.error('Error:', e.message); process.exit(1); });
}
