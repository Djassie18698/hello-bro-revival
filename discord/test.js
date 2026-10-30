// Offline tests (no API key, no Discord): node test.js
const assert = require('assert');
const { runAgent } = require('./agent');
const { makeTools, splitMessage, secretProblem, listDocs } = require('./tools');
const { fakeAdapter, realAdapter } = require('./adapter');

(async () => {
  // --- splitting and secret guard
  const long = ('Step text. '.repeat(40) + '\n\n').repeat(10);
  const parts = splitMessage(long);
  assert(parts.length > 1 && parts.every((p) => p.length <= 1900), 'split respects 1900');
  assert(secretProblem('connect to 192.168.1.5:18080'), 'IP blocked');
  assert(secretProblem('key sk-ant-abc123'), 'api key blocked');
  assert(secretProblem('ADMIN_PASSWORD=hunter2'), 'admin pw blocked');
  assert(!secretProblem('Open <server-address> in the game'), 'placeholder ok');

  // --- repo doc allowlist
  const discord = fakeAdapter();
  const tools = makeTools({ discord });
  const run = (name, input) => tools.find((t) => t.def.name === name).run(input);
  assert(JSON.parse(await run('list_repo_docs', {})).includes('README.txt'));
  for (const bad of ['hellobro.db', 'release/revival.keystore', 'CLAUDE.md', '../.git/config', 'discord/.env', 'docs/../hellobro.db'])
    await assert.rejects(() => run('read_repo_doc', { path: bad }), /not readable/, bad);
  assert((await run('read_repo_doc', { path: 'README.txt' })).length > 50);

  // --- refused posts never reach Discord
  await assert.rejects(() => run('post_message', { channel: 'tutorial', content: 'join 10.0.0.1' }), /refused/);
  assert.strictEqual(discord.chans.find((c) => c.name === 'tutorial').msgs.length, 0);

  // --- dry run changes nothing
  const dryTools = makeTools({ discord, dry: true });
  const dryOut = await dryTools.find((t) => t.def.name === 'post_message').run({ channel: 'tutorial', content: 'hi' });
  assert(/dry run/.test(dryOut) && discord.chans.find((c) => c.name === 'tutorial').msgs.length === 0);

  // --- full agent loop with a scripted fake Claude
  const script = [
    { stop_reason: 'tool_use', content: [{ type: 'thinking', thinking: '', signature: 'x' }, { type: 'tool_use', id: 't1', name: 'read_channel', input: { channel: 'tutorial' } }, { type: 'tool_use', id: 't2', name: 'read_repo_doc', input: { path: 'README.txt' } }] },
    { stop_reason: 'tool_use', content: [{ type: 'tool_use', id: 't3', name: 'post_message', input: { channel: '#tutorial', content: '**How to install**\n1. Download the game\n2. Follow README' } }] },
    { stop_reason: 'tool_use', content: [{ type: 'tool_use', id: 't4', name: 'post_message', input: { channel: 'tutorial', content: 'server at 8.8.8.8' } }] },
    { stop_reason: 'end_turn', content: [{ type: 'text', text: 'Posted the install tutorial in #tutorial.' }] },
  ];
  let i = 0; const seen = [];
  const fakeClient = { beta: { messages: { create: async (p) => { seen.push(JSON.parse(JSON.stringify(p.messages))); return script[i++]; } } } };
  const answer = await runAgent({ client: fakeClient, model: 'm', system: 's', tools, userText: 'Add an install tutorial in #tutorial' });
  assert.strictEqual(answer, 'Posted the install tutorial in #tutorial.');
  const posted = discord.chans.find((c) => c.name === 'tutorial').msgs;
  assert.strictEqual(posted.length, 1, 'good post went through, IP post was refused');
  // both results of turn 1 must come back in ONE user message
  const turn2 = seen[1]; const last = turn2[turn2.length - 1];
  assert(last.role === 'user' && last.content.length === 2, 'parallel tool results in one message');
  assert(seen[3][seen[3].length - 1].content[0].is_error, 'refused post is reported as an error result');
  assert(turn2[turn2.length - 2].content[0].type === 'thinking', 'assistant content passed back unchanged');

  // --- loop cap
  const loop = { beta: { messages: { create: async () => ({ stop_reason: 'tool_use', content: [{ type: 'tool_use', id: 'x', name: 'list_channels', input: {} }] }) } } };
  assert(/too many steps/.test(await runAgent({ client: loop, model: 'm', system: 's', tools, userText: 'x', maxTurns: 3 })));

  // --- real adapter refuses to edit/delete other people's messages
  const other = { id: 'm1', author: { id: 'someone' }, edit: async () => { throw new Error('should not edit'); }, delete: async () => { throw new Error('should not delete'); } };
  const ch = { id: 'c1', name: 'tutorial', isTextBased: () => true, isThread: () => false, isVoiceBased: () => false, parent: null, messages: { fetch: async () => other } };
  const guild = { fetch: async () => guild, channels: { fetch: async () => new Map([['c1', ch]]) } };
  const ad = realAdapter({ user: { id: 'bot' }, guilds: { fetch: async () => ({ first: () => guild }) } });
  await assert.rejects(() => ad.edit(ch, 'm1', 'x'), /not mine/);
  await assert.rejects(() => ad.remove(ch, 'm1'), /not mine/);
  assert.strictEqual((await ad.channel('#Tutorial')).id, 'c1');

  console.log('all discord bot tests passed');
})().catch((e) => { console.error('FAIL', e); process.exit(1); });
