// Talk to the same agent from a terminal.
//   node --env-file=.env cli.js "Add a tutorial on how to install the project in #tutorial"
//   node --env-file=.env cli.js --dry "..."     (shows what it WOULD post; nothing is changed)
//   node --env-file=.env cli.js --fake "..."    (no Discord token needed: uses an in-memory fake server and prints the result)
const Anthropic = require('@anthropic-ai/sdk');
const { runAgent } = require('./agent');
const { makeTools, SYSTEM } = require('./tools');
const { realAdapter, fakeAdapter } = require('./adapter');

(async () => {
  const args = process.argv.slice(2);
  const dry = args.includes('--dry'), fake = args.includes('--fake');
  const userText = args.filter((a) => !a.startsWith('--')).join(' ').trim();
  if (!userText) { console.error('Usage: node cli.js [--dry|--fake] "what you want done"'); process.exit(1); }
  if (!process.env.ANTHROPIC_API_KEY) { console.error('Missing ANTHROPIC_API_KEY'); process.exit(1); }
  let discord, client;
  if (fake) discord = fakeAdapter();
  else {
    if (!process.env.DISCORD_TOKEN) { console.error('Missing DISCORD_TOKEN (or use --fake)'); process.exit(1); }
    const { Client, GatewayIntentBits } = require('discord.js');
    client = new Client({ intents: [GatewayIntentBits.Guilds] });
    await client.login(process.env.DISCORD_TOKEN);
    await new Promise((r) => (client.isReady() ? r() : client.once('clientReady', r)));
    discord = realAdapter(client, process.env.GUILD_ID);
  }
  const tools = makeTools({ discord, dry, log: (...a) => console.log('[tool]', ...a) });
  const answer = await runAgent({ client: new (Anthropic.default || Anthropic)(), model: process.env.CLAUDE_MODEL || 'claude-opus-5-5', system: SYSTEM, tools, userText, log: (...a) => console.log('[agent]', ...a) });
  console.log('\n' + answer);
  if (fake) for (const c of discord.chans) for (const m of c.msgs) console.log(`\n--- #${c.name} ---\n${m.content}`);
  if (client) await client.destroy();
})().catch((e) => { console.error(e); process.exit(1); });
