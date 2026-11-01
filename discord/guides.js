// Rebuilds a read-only guide channel from discord/guides/<channel>.md: a contents message with jump links on top, then one message per
// chapter ("## " heading = a new chapter; the "# " title + text before the first chapter go into the contents message).
//   node --env-file=.env guides.js install-help         (dry run: prints the chapters)
//   node --env-file=.env guides.js install-help apply   (removes the bot's old messages in that channel, posts the new ones)
// Only the bot's own messages are removed; other bots' / people's messages stay (e.g. Carl-bot's reaction-role message in #rules).
const fs = require('fs'), path = require('path');
const { makeApi } = require('./dc.js');
const GUILD = '1565691956561060014';

(async () => {
  const [name, mode] = process.argv.slice(2);
  const file = path.join(__dirname, 'guides', name + '.md');
  const text = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n').trim();
  const parts = text.split(/\n(?=## )/);
  const head = parts.shift().trim(), chapters = parts.map((p) => p.trim());
  const titleOf = (c) => c.split('\n')[0].replace(/^##\s*/, '');
  for (const c of chapters) if (c.length > 1990) throw new Error(`chapter "${titleOf(c)}" is ${c.length} characters (max 1990)`);
  if (mode !== 'apply') { console.log(head + '\n'); chapters.forEach((c, i) => console.log(`${i + 1}. ${titleOf(c)} (${c.length} chars)`)); return; }

  const call = makeApi(process.env.DISCORD_TOKEN);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const me = await call('GET', '/users/@me');
  const ch = (await call('GET', `/guilds/${GUILD}/channels`)).find((c) => c.name === name);
  if (!ch) throw new Error('no channel #' + name);
  const old = (await call('GET', `/channels/${ch.id}/messages?limit=100`)).filter((m) => m.author.id === me.id);
  for (const m of old) { await call('DELETE', `/channels/${ch.id}/messages/${m.id}`); await sleep(350); }
  const post = async (content) => { const m = await call('POST', `/channels/${ch.id}/messages`, { content, allowed_mentions: { parse: [] } }); await sleep(600); return m; };
  if (!chapters.length) { const m = await post(head); await call('PUT', `/channels/${ch.id}/pins/${m.id}`); console.log(`#${name}: removed ${old.length} old, posted and pinned 1 message`); return; }
  const contents = await post(head + '\n\n*(contents follow)*');
  const ids = [];
  for (const c of chapters) ids.push((await post(c)).id);
  const link = (id) => `https://discord.com/channels/${GUILD}/${ch.id}/${id}`;
  const toc = head + '\n\n**Chapters**\n' + chapters.map((c, i) => `${i + 1}. [${titleOf(c).replace(/^\d+\.\s*/, '')}](${link(ids[i])})`).join('\n');
  if (toc.length > 2000) throw new Error('contents too long');
  await call('PATCH', `/channels/${ch.id}/messages/${contents.id}`, { content: toc, allowed_mentions: { parse: [] } });
  console.log(`#${name}: removed ${old.length} old, posted contents + ${chapters.length} chapters`);
})().catch((e) => { console.error('Error:', e.message); process.exit(1); });
