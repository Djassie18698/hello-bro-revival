// Offline test for dc.js with a fake Discord API: node test-dc.js
const assert = require('assert');
const { run } = require('./dc');
(async () => {
  const sent = []; const msgs = { m1: { id: 'm1', author: { id: 'bot' }, content: 'old' }, m2: { id: 'm2', author: { id: 'human' }, content: 'hi' } };
  const call = async (method, path, body) => {
    if (path === '/users/@me') return { id: 'bot' };
    if (path === '/users/@me/guilds') return [{ id: 'g' }];
    if (path === '/guilds/g/channels') return [{ id: 'c1', name: '📚│tutorial', type: 0 }, { id: 'c2', name: 'general', type: 0 }, { id: 'c3', name: 'Voice', type: 2 }];
    let m;
    if ((m = path.match(/^\/channels\/c1\/messages\/(\w+)$/))) { if (method === 'GET') return msgs[m[1]]; sent.push([method, path, body]); return null; }
    if (path === '/channels/c1/messages' && method === 'POST') { sent.push([method, path, body]); return { id: 'new' }; }
    throw new Error('unexpected ' + method + path);
  };
  const out = []; const go = (argv, text) => run(argv, { call, out: (s) => out.push(s), readText: () => text });
  await go(['channels']); assert(/tutorial/.test(out[0]) && !/Voice/.test(out[0]));
  await go(['post', 'tutorial', 'x'], '**Install**\n1. Download'); assert.strictEqual(sent[0][2].content, '**Install**\n1. Download'); assert.deepStrictEqual(sent[0][2].allowed_mentions, { parse: [] });
  await assert.rejects(() => go(['post', 'tutorial', 'x'], 'server 192.168.1.2'), /refused/);
  await assert.rejects(() => go(['edit', 'tutorial', 'm2', 'x'], 'new'), /not mine/);
  await go(['edit', 'tutorial', 'm1', 'x'], 'new'); assert.strictEqual(sent.at(-1)[0], 'PATCH');
  await assert.rejects(() => go(['delete', 'tutorial', 'm2']), /not mine/);
  await assert.rejects(() => go(['post', 'nope', 'x'], 'a'), /no channel/);
  assert.strictEqual(sent.length, 2);
  console.log('dc.js tests passed');
})().catch((e) => { console.error('FAIL', e); process.exit(1); });
