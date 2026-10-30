// Tiny Discord command line tool (bot token only, no Claude API key). A Claude session on your PC runs these commands for you.
//   node --env-file=.env dc.js channels
//   node --env-file=.env dc.js read <channel> [count]
//   node --env-file=.env dc.js post <channel> <file.md | ->        ("-" = read the text from stdin)
//   node --env-file=.env dc.js edit <channel> <message-id> <file.md | ->
//   node --env-file=.env dc.js delete <channel> <message-id>        (own messages only)
// Same safety rules as the bot: no secrets/IP addresses, no @everyone pings, only own messages are changed.
const fs = require('fs');
const { secretProblem, splitMessage } = require('./tools');

const API = 'https://discord.com/api/v10';
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

async function run(argv, { token, guildId, readText = (p) => (p === '-' ? fs.readFileSync(0, 'utf8') : fs.readFileSync(p, 'utf8')), call = makeApi(token), out = console.log } = {}) {
  const [cmd, chan, a, b] = argv;
  const me = await call('GET', '/users/@me');
  const gid = guildId || (await (async () => { const g = await call('GET', '/users/@me/guilds'); if (g.length !== 1) throw new Error('bot is in ' + g.length + ' servers; set GUILD_ID in .env'); return g[0].id; })());
  const chans = (await call('GET', `/guilds/${gid}/channels`)).filter((c) => [0, 5].includes(c.type)); // text + announcement
  if (cmd === 'channels') return out(chans.map((c) => `${c.id}  #${c.name}`).join('\n'));
  if (!chan) throw new Error('missing channel');
  const r = String(chan).replace(/^<#(\d+)>$/, '$1').replace(/^#/, '').toLowerCase();
  const exact = chans.filter((c) => c.id === r || c.name.toLowerCase() === r);
  const found = exact.length ? exact : chans.filter((c) => c.name.toLowerCase().includes(r));
  if (found.length !== 1) throw new Error(found.length ? `"${chan}" matches several channels: ${found.map((c) => c.name).join(', ')}` : `no channel called "${chan}" (run: channels)`);
  const ch = found[0];
  const guard = (text) => { const bad = secretProblem(text); if (bad) throw new Error(`refused: the text contains ${bad}`); };
  const own = async (id) => { const m = await call('GET', `/channels/${ch.id}/messages/${id}`); if (m.author.id !== me.id) throw new Error('that message is not mine'); return m; };

  if (cmd === 'read') {
    const msgs = (await call('GET', `/channels/${ch.id}/messages?limit=${Math.min(Number(a) || 15, 50)}`)).reverse();
    return out(msgs.map((m) => `[${m.id}] ${m.author.id === me.id ? '(bot)' : m.author.username}: ${m.content}`).join('\n---\n'));
  }
  if (cmd === 'post') {
    const text = readText(a); guard(text);
    for (const part of splitMessage(text)) { const m = await call('POST', `/channels/${ch.id}/messages`, { content: part, allowed_mentions: { parse: [] } }); out(`posted in #${ch.name}: message id ${m.id}`); await sleep(600); }
    return;
  }
  if (cmd === 'edit') {
    const text = readText(b); guard(text);
    if (text.length > 2000) throw new Error('too long for one message (max 2000)');
    await own(a); await call('PATCH', `/channels/${ch.id}/messages/${a}`, { content: text, allowed_mentions: { parse: [] } });
    return out('edited ' + a);
  }
  if (cmd === 'delete') { await own(a); await call('DELETE', `/channels/${ch.id}/messages/${a}`); return out('deleted ' + a); }
  throw new Error('unknown command. Use: channels | read | post | edit | delete');
}

module.exports = { run, makeApi };

if (require.main === module) {
  if (!process.env.DISCORD_TOKEN) { console.error('Missing DISCORD_TOKEN in .env'); process.exit(1); }
  run(process.argv.slice(2), { token: process.env.DISCORD_TOKEN, guildId: process.env.GUILD_ID }).catch((e) => { console.error('Error:', e.message); process.exit(1); });
}
