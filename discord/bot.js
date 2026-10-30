// Owner-only Discord manager bot. Start:  node --env-file=.env bot.js
// Talk to it by @mentioning it, by DM, or in CONTROL_CHANNEL. Only users in OWNER_IDS are obeyed.
const { Client, GatewayIntentBits, Partials, ChannelType } = require('discord.js');
const Anthropic = require('@anthropic-ai/sdk');
const { runAgent } = require('./agent');
const { makeTools, SYSTEM, splitMessage } = require('./tools');
const { realAdapter } = require('./adapter');

const need = (k) => { if (!process.env[k]) { console.error(`Missing ${k}. See discord/README.md`); process.exit(1); } return process.env[k]; };
const TOKEN = need('DISCORD_TOKEN');
need('ANTHROPIC_API_KEY');
const OWNERS = new Set(need('OWNER_IDS').split(',').map((s) => s.trim()).filter(Boolean));
const CONTROL = (process.env.CONTROL_CHANNEL || '').replace(/^#/, '').toLowerCase();
const MODEL = process.env.CLAUDE_MODEL || 'claude-opus-5-5';

const anthropic = new (Anthropic.default || Anthropic)();
const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent, GatewayIntentBits.DirectMessages],
  partials: [Partials.Channel],
});
const history = new Map(); // channel id -> [{role, content}] (plain text only), so "make it shorter" works
let busy = Promise.resolve();

client.once('clientReady', () => console.log(`Logged in as ${client.user.tag}; obeying ${OWNERS.size} owner(s); model ${MODEL}`));

client.on('messageCreate', (msg) => {
  if (msg.author.bot || !OWNERS.has(msg.author.id)) return;
  const isDM = msg.channel.type === ChannelType.DM;
  const mentioned = msg.mentions.users.has(client.user.id);
  const inControl = CONTROL && (msg.channel.id === CONTROL || (msg.channel.name || '').toLowerCase() === CONTROL);
  if (!isDM && !mentioned && !inControl) return;
  const text = msg.content.replace(new RegExp(`<@!?${client.user.id}>`, 'g'), '').trim();
  if (!text) return;
  busy = busy.then(() => handle(msg, text)).catch((e) => console.error('handler failed', e));
});

async function handle(msg, text) {
  const typing = setInterval(() => msg.channel.sendTyping().catch(() => {}), 8000);
  msg.channel.sendTyping().catch(() => {});
  try {
    const tools = makeTools({ discord: realAdapter(client, process.env.GUILD_ID), log: (...a) => console.log('[tool]', ...a) });
    const past = history.get(msg.channel.id) || [];
    const answer = await runAgent({ client: anthropic, model: MODEL, system: SYSTEM, tools, history: past, userText: text, log: (...a) => console.log('[agent]', ...a) });
    history.set(msg.channel.id, [...past, { role: 'user', content: text }, { role: 'assistant', content: answer }].slice(-12));
    for (const part of splitMessage(answer)) await msg.reply({ content: part, allowedMentions: { parse: [], repliedUser: false } });
  } catch (e) {
    console.error(e);
    await msg.reply({ content: 'Something went wrong: ' + String(e.message).slice(0, 300), allowedMentions: { parse: [] } }).catch(() => {});
  } finally { clearInterval(typing); }
}

client.login(TOKEN);
