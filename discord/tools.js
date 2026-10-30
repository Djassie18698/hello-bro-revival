// The tools Claude may use. Everything risky is restricted here, in code, not just in the prompt:
//  - only the bot's OWN messages can be edited/deleted
//  - no @everyone/@role pings (the adapter sends allowedMentions: none)
//  - posts containing secrets or IP addresses are refused
//  - only an allowlist of project docs can be read (never the save file, keystore, .env, ...)
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DOC_OK = /^(README[^/]*|FRIENDS-README\.txt|PROTOCOL-NOTES\.txt|SATURDAY-CHECKLIST\.txt|PLAN\.md|docs\/[^/]+\.md|public-template\/.+\.(md|bat|txt))$/i;
const LIMIT = 2000;

function secretProblem(text) {
  const checks = [
    [/sk-ant-[A-Za-z0-9_-]+/, 'an Anthropic API key'],
    [/[MNO][A-Za-z\d_-]{23,}\.[\w-]{6}\.[\w-]{27,}/, 'a Discord bot token'],
    [/ADMIN_PASSWORD\s*[=:]/i, 'an admin password'],
    [/\bpassword\s*[:=]\s*\S+/i, 'a password'],
  ];
  if (process.env.ALLOW_IP_ADDRESSES !== '1') checks.push([/\b\d{1,3}(\.\d{1,3}){3}\b/, 'an IP address (use a placeholder like <server-address> instead)']);
  for (const [re, what] of checks) if (re.test(text)) return what;
  for (const k of ['DISCORD_TOKEN', 'ANTHROPIC_API_KEY']) if (process.env[k] && process.env[k].length > 8 && text.includes(process.env[k])) return k;
  return null;
}

// Split long text for Discord's 2000 character limit, preferring paragraph / line breaks.
function splitMessage(text, max = 1900) {
  const parts = [];
  let rest = String(text).trim();
  while (rest.length > max) {
    let cut = rest.lastIndexOf('\n\n', max);
    if (cut < max / 2) cut = rest.lastIndexOf('\n', max);
    if (cut < max / 2) cut = rest.lastIndexOf(' ', max);
    if (cut < max / 2) cut = max;
    parts.push(rest.slice(0, cut).trim());
    rest = rest.slice(cut).trim();
  }
  if (rest) parts.push(rest);
  return parts;
}

function listDocs() {
  const out = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const rel = path.relative(ROOT, path.join(dir, e.name)).split(path.sep).join('/');
      if (e.isDirectory()) { if (['docs', 'public-template'].includes(rel.split('/')[0]) && !e.name.startsWith('.')) walk(path.join(dir, e.name)); }
      else if (DOC_OK.test(rel)) out.push(rel);
    }
  };
  walk(ROOT);
  return out.sort();
}

// discord = adapter: { channels(), channel(ref), recent(ch, n), send(ch, text), edit(ch, id, text), remove(ch, id), isOwnMessage(m) }
function makeTools({ discord, log = () => {}, dry = false }) {
  const write = async (label, fn) => { if (dry) { log('DRY-RUN', label); return `(dry run, not done) ${label}`; } return fn(); };
  const T = (name, description, properties, required, run) => ({
    def: { name, description, input_schema: { type: 'object', properties, required, additionalProperties: false } }, run,
  });
  return [
    T('list_channels', 'List the text channels of the Discord server (id, name, category).', {}, [], async () => JSON.stringify(await discord.channels())),
    T('read_channel', 'Read the most recent messages of a channel (newest last). Use it to see what is already posted before adding or editing.',
      { channel: { type: 'string', description: 'channel name (without #) or id' }, limit: { type: 'integer', description: '1-30, default 15' } }, ['channel'],
      async ({ channel, limit }) => {
        const ch = await discord.channel(channel);
        const msgs = await discord.recent(ch, Math.min(Math.max(limit || 15, 1), 30));
        return JSON.stringify(msgs.map((m) => ({ id: m.id, author: m.author, mine: m.mine, content: String(m.content).slice(0, 1500) })));
      }),
    T('post_message', 'Post a message in a channel as the bot. Text over 1900 characters is split into several messages automatically. Discord markdown is supported. Returns the message id(s).',
      { channel: { type: 'string' }, content: { type: 'string' } }, ['channel', 'content'],
      async ({ channel, content }) => {
        const bad = secretProblem(content);
        if (bad) throw new Error(`refused: the text contains ${bad}`);
        const ch = await discord.channel(channel);
        return write(`post in #${ch.name} (${content.length} chars)`, async () => {
          const ids = [];
          for (const part of splitMessage(content)) ids.push(await discord.send(ch, part));
          return 'posted, message ids: ' + ids.join(', ');
        });
      }),
    T('edit_message', 'Edit one of the BOT\'s OWN messages (max 2000 characters). Use this to update a tutorial instead of posting a duplicate.',
      { channel: { type: 'string' }, message_id: { type: 'string' }, content: { type: 'string' } }, ['channel', 'message_id', 'content'],
      async ({ channel, message_id, content }) => {
        if (content.length > LIMIT) throw new Error(`too long for one message (${content.length} > ${LIMIT}); shorten it or delete and re-post`);
        const bad = secretProblem(content);
        if (bad) throw new Error(`refused: the text contains ${bad}`);
        const ch = await discord.channel(channel);
        return write(`edit message ${message_id} in #${ch.name}`, async () => { await discord.edit(ch, message_id, content); return 'edited'; });
      }),
    T('delete_message', 'Delete one of the BOT\'s OWN messages. Other people\'s messages cannot be deleted.',
      { channel: { type: 'string' }, message_id: { type: 'string' } }, ['channel', 'message_id'],
      async ({ channel, message_id }) => {
        const ch = await discord.channel(channel);
        return write(`delete message ${message_id} in #${ch.name}`, async () => { await discord.remove(ch, message_id); return 'deleted'; });
      }),
    T('list_repo_docs', 'List the project documentation files you may read (README, guides, notes). Use these as the source of truth when writing tutorials.', {}, [], async () => JSON.stringify(listDocs())),
    T('read_repo_doc', 'Read one project documentation file listed by list_repo_docs.', { path: { type: 'string', description: 'e.g. README.txt or docs/HOT-UPDATE.md' } }, ['path'],
      async ({ path: p }) => {
        const rel = String(p).replace(/^\/+/, '');
        if (rel.includes('..') || !DOC_OK.test(rel)) throw new Error('that file is not readable (use list_repo_docs)');
        return fs.readFileSync(path.join(ROOT, rel), 'utf8').slice(0, 25000);
      }),
  ];
}

const SYSTEM = `You are the manager bot of the Discord server for "Hello Bro Revival", a fan-made revival of the old mobile game Hello Bro / Ninja Online (Naruto-style card RPG). A private server program lets people play it again with friends. Your owner types instructions in plain English; you carry them out with your tools.

Rules:
- Facts about the game or the server software must come from the project docs (list_repo_docs / read_repo_doc). Never invent features, steps, commands or screens. If the docs do not cover something, say so and ask the owner.
- Before posting or changing anything in a channel, read_channel it first so you do not create duplicates. If a message of yours already covers the topic, edit_message it (or delete and re-post if it no longer fits in 2000 characters).
- Tutorials: friendly, short steps, numbered lists, Discord markdown (**bold**, \`code\`, > quotes). One topic per message. Put a clear title first.
- Never post passwords, keys, tokens or IP addresses; use placeholders like <server-address>. Never ping @everyone or roles.
- You can only change your own messages. Do not claim to have done something your tools did not do.
- When finished, reply with a SHORT summary of what you did (channel names, what changed). If an instruction is unclear or risky, ask one short question instead of guessing.`;

module.exports = { makeTools, SYSTEM, splitMessage, secretProblem, listDocs };
