// Offline test for dc.js forum commands (#bug-fixer, owner 10 Nov 2026): node test-forum.js
const assert = require('assert');
const { run } = require('./dc');
(async () => {
  const sent = [];
  const tags = [{ id: 't1', name: 'Question for you' }, { id: 't2', name: 'Fixed, not live yet' }];
  const threads = { '111111111111111111': { id: '111111111111111111', parent_id: 'f1', name: 'Pet training', applied_tags: ['t1'], last_message_id: '20' }, '222222222222222222': { id: '222222222222222222', parent_id: 'f1', name: 'Old one', applied_tags: [], last_message_id: '10', thread_metadata: { archived: true } } };
  const last = { '111111111111111111': { id: '20', author: { id: '1234567', username: 'boss' }, timestamp: '2026-11-10T22:00:00Z' }, '222222222222222222': { id: '10', author: { id: 'bot' }, timestamp: '2026-11-09T10:00:00Z' } };
  const call = async (method, path, body) => {
    if (path === '/users/@me') return { id: 'bot' };
    if (path === '/users/@me/guilds') return [{ id: 'g' }];
    if (path === '/guilds/g/channels') return [{ id: 'f1', name: 'bug-fixer', type: 15, available_tags: tags }, { id: 'c2', name: 'general', type: 0 }];
    if (path === '/channels/f1') return { id: 'f1', available_tags: tags };
    if (path === '/channels/f1/threads' && method === 'POST') { sent.push([method, path, body]); return { id: 'p9' }; }
    if (path === '/guilds/g/threads/active') return { threads: [threads['111111111111111111']] };
    if (path.startsWith('/channels/f1/threads/archived/public')) return { threads: [threads['222222222222222222']] };
    let m;
    if ((m = path.match(/^\/channels\/(\d{18})\/messages\?limit=10$/))) return m[1] === '111111111111111111' ? [{ id: '21', author: { id: 'bot' }, content: '👀 Got it. The bug fixer picks this up', timestamp: '2026-11-10T22:01:00Z' }, last[m[1]]] : [last[m[1]]];
    if ((m = path.match(/^\/channels\/(\d{18})$/))) { if (method === 'PATCH') { sent.push([method, path, body]); return {}; } return threads[m[1]]; }
    if ((m = path.match(/^\/channels\/(\d{18})\/messages$/)) && method === 'POST') { sent.push([method, path, body]); return { id: 'm' }; }
    throw new Error('unexpected ' + method + ' ' + path);
  };
  const out = []; const go = (argv, text = '') => run(argv, { call, out: (s) => out.push(s), readText: () => text, ownerId: '1234567' });
  // a new post: title, tags by name, owner tagged only when asked
  await go(['forum', 'bug-fixer', 'Double EXP pills', 'x.md', '--tag', 'Question for you', '--ping-owner'], 'Which one?');
  const b = sent.at(-1)[2];
  assert.strictEqual(b.name, 'Double EXP pills'); assert.deepStrictEqual(b.applied_tags, ['t1']);
  assert.strictEqual(b.message.content, '<@1234567> Which one?'); assert.deepStrictEqual(b.message.allowed_mentions, { parse: [], users: ['1234567'] });
  await go(['forum', 'bug-fixer', 'Plain', 'x.md'], 'News'); assert.deepStrictEqual(sent.at(-1)[2].message.allowed_mentions, { parse: [] });
  await assert.rejects(() => go(['forum', 'bug-fixer', 'T', 'x.md', '--tag', 'Nope'], 'a'), /no tag "Nope"/);
  await assert.rejects(() => go(['forum', 'general', 'T', 'x.md'], 'a'), /not a forum/);
  await assert.rejects(() => go(['forum', 'bug-fixer', 'T', 'x.md'], 'server 192.168.1.2'), /refused/);
  // the list: newest first, OWNER marks a post that waits for the fixer, archived ones included
  out.length = 0; await go(['posts', 'bug-fixer']);
  const lines = out[0].split('\n');
  assert(/^\[111111111111111111\] Pet training · Question for you · last: OWNER/.test(lines[0]), lines[0]);
  assert(/^\[222222222222222222\] Old one · no tag · last: bot .* · archived$/.test(lines[1]), lines[1]);
  // tags of a post, an archived post is opened again
  await go(['tag', '222222222222222222', 'Fixed, not live yet']);
  assert.deepStrictEqual(sent.at(-1)[2], { applied_tags: ['t2'], archived: false });
  console.log('dc.js forum tests passed');
})().catch((e) => { console.error('FAIL', e); process.exit(1); });
