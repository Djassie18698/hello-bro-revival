// Offline test of the #bugs-and-issues helper (bughelper.js): a fake Discord and a fake Claude, nothing is posted anywhere.
//   node discord/test-bughelper.js        (also run by tools/dev/check.sh)
const { createHelper, buildMessages, reportText, SCHEMA } = require('./bughelper');

let bad = 0;
const ok = (cond, what) => { if (!cond) { bad++; console.log('FAIL', what); } };
let nextId = 1000n;
const id = () => String(++nextId);

function fakeDiscord() {
  const ch = { bugs: [], logs: [] }, threads = {}, reactions = [];
  const BOT = { id: 'bot', username: 'HelloBro', bot: true };
  const msg = (author, content, extra = {}) => ({ id: id(), type: 0, author, content, attachments: [], ...extra });
  const call = async (method, p, body) => {
    let m;
    if (p === '/users/@me') return BOT;
    if (p === '/users/@me/guilds') return [{ id: 'g' }];
    if (p === '/guilds/g/channels') return [{ id: 'bugs', name: 'bugs-and-issues', type: 0 }, { id: 'logs', name: 'bot-logs', type: 0 }];
    if ((m = /^\/channels\/(\w+)\/messages\?(.*)$/.exec(p)) && method === 'GET') {
      const q = new URLSearchParams(m[2]); const list = (ch[m[1]] || threads[m[1]] || []).slice();
      const after = q.get('after');
      let out = after ? list.filter((x) => BigInt(x.id) > BigInt(after)) : list;
      out = out.slice().reverse().slice(0, Number(q.get('limit') || 50)); // newest first, like Discord
      return out;
    }
    if ((m = /^\/channels\/(\w+)\/messages\/(\w+)$/.exec(p)) && method === 'GET') return (ch[m[1]] || threads[m[1]]).find((x) => x.id === m[2]);
    if ((m = /^\/channels\/(\w+)\/messages\/(\w+)\/threads$/.exec(p))) { const tid = id(); threads[tid] = []; ch[m[1]].find((x) => x.id === m[2]).thread = { id: tid }; return { id: tid, name: body.name }; }
    if ((m = /^\/channels\/(\w+)\/messages$/.exec(p)) && method === 'POST') { const x = msg(BOT, body.content); x.allowed = body.allowed_mentions; (ch[m[1]] || threads[m[1]]).push(x); return x; }
    if ((m = /^\/channels\/(\w+)\/messages\/(\w+)\/reactions\/([^/]+)\/@me$/.exec(p))) { reactions.push([m[2], decodeURIComponent(m[3])]); return null; }
    throw new Error('unexpected call ' + method + ' ' + p);
  };
  return { ch, threads, reactions, call, msg, BOT };
}

// fake Claude: answers from a script, remembers what it was sent
function fakeClaude(script) {
  const seen = [];
  return {
    seen,
    beta: { messages: { create: async (req) => {
      seen.push(req);
      const next = script.shift();
      if (next instanceof Error) throw next;
      return { stop_reason: 'end_turn', content: [{ type: 'text', text: JSON.stringify(next) }] };
    } } },
  };
}
const rep = (o = {}) => ({ kind: 'bug', title: 'Arena button does nothing', where: 'Arena', what_happened: 'nothing happens', expected: 'the arena opens', steps: 'tap Arena', every_time: 'yes', character: 'Ninja1', server: 'ninjaonline', device: '', notes: '', ...o });

(async () => {
  const P1 = { id: 'p1', username: 'kid', global_name: 'Kid' }, OWNER = { id: 'own', username: 'bakeddean' };

  // 1. a new report: thread, a question, then the player's answer completes it -> report in #bot-logs, 📝 on the post
  {
    const d = fakeDiscord();
    const claude = fakeClaude([{ action: 'ask', reply: '1. Which screen?\n2. Your character name?', report: rep({ where: '', character: '' }) },
      { action: 'complete', reply: 'Thanks! The developer has it now.', report: rep() }]);
    const h = createHelper({ call: d.call, client: claude, env: { OWNER_IDS: 'own' }, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg(OWNER, 'Perfect reports, looking into it!')); // the owner: left alone
    d.ch.bugs.push(d.msg(P1, 'the arena button does nothing @everyone', { attachments: [{ url: 'https://cdn.discordapp.com/a/shot.png', filename: 'shot.png', content_type: 'image/png' }] }));
    await h.tick();
    const tid = Object.keys(d.threads)[0];
    ok(tid && d.threads[tid].length === 1 && /Which screen/.test(d.threads[tid][0].content), 'question posted in a new thread');
    ok(d.threads[tid] && d.threads[tid][0].allowed && d.threads[tid][0].allowed.parse.length === 0, 'no pings allowed');
    ok(Object.keys(d.threads).length === 1, 'owner post got no thread');
    const first = claude.seen[0];
    ok(first && first.output_config.format.type === 'json_schema' && first.model === 'claude-opus-5-5' && first.fallbacks === 'default', 'Claude call: model, JSON format, fallbacks');
    ok(first && first.messages[0].content.some((c) => c.type === 'image'), 'the screenshot is shown to Claude');
    await h.tick(); // nothing new: no second Claude call
    ok(claude.seen.length === 1, 'no call without a new player message');
    d.threads[tid].push(d.msg(P1, 'arena, my name is Ninja1'));
    await h.tick();
    ok(/developer has it/.test(d.threads[tid][d.threads[tid].length - 1].content), 'thanks posted');
    const log = d.ch.logs[0];
    ok(log && /Bug report/.test(log.content) && /Arena button does nothing/.test(log.content) && log.content.includes('report-id: ' + tid) && log.content.includes('shot.png'), 'report in #bot-logs');
    ok(d.reactions.some(([m, e]) => e === '📝'), '📝 on the post');
    ok(claude.seen[1].messages.length === 3 && claude.seen[1].messages[1].role === 'assistant', 'the conversation goes back to Claude');
    d.threads[tid].push(d.msg(P1, 'thanks!'));
    await h.tick();
    ok(claude.seen.length === 2 && d.ch.logs.length === 1, 'finished thread stays quiet');
  }

  // 2. no key / API down: the fixed checklist, then the answer is forwarded as it is
  {
    const d = fakeDiscord();
    const h = createHelper({ call: d.call, client: fakeClaude([new Error('401 invalid key')]), env: {}, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg(P1, 'game crashes when I open the shop'));
    await h.tick();
    const tid = Object.keys(d.threads)[0];
    ok(/Which screen or feature/.test(d.threads[tid][0].content), 'checklist when Claude fails');
    d.threads[tid].push(d.msg(P1, 'shop, Ninja1, ninjaonline'));
    await h.tick();
    ok(d.ch.logs.length === 1 && /crashes when I open the shop/.test(d.ch.logs[0].content) && /Ninja1, ninjaonline/.test(d.ch.logs[0].content), 'raw thread forwarded without Claude');
    const h2 = createHelper({ call: fakeDiscord().call, client: null, env: {}, log: () => {} });
    await h2.init(); // no client at all works too
  }

  // 3. limits: a question round cap, a daily call cap, a day without an answer, chat, replies to other posts
  {
    const d = fakeDiscord();
    let t = 0;
    const asks = Array.from({ length: 10 }, () => ({ action: 'ask', reply: 'more?', report: rep() }));
    const claude = fakeClaude(asks);
    const h = createHelper({ call: d.call, client: claude, env: {}, now: () => t, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg(P1, 'boss 1-2 too hard'));
    d.ch.bugs.push(d.msg(P1, 'also this', { message_reference: { message_id: '1' } })); // a reply: no thread
    await h.tick();
    const tid = Object.keys(d.threads)[0];
    ok(Object.keys(d.threads).length === 1, 'replies to other posts get no thread');
    for (let i = 0; i < 4; i++) { d.threads[tid].push(d.msg(P1, 'answer ' + i)); await h.tick(); }
    ok(d.ch.logs.length === 1, 'forwarded after 4 rounds of questions');
    // idle
    const d2 = fakeDiscord();
    const h2 = createHelper({ call: d2.call, client: fakeClaude([{ action: 'ask', reply: 'which screen?', report: rep() }]), env: {}, now: () => t, log: () => {} });
    await h2.init();
    d2.ch.bugs.push(d2.msg(P1, 'it broke'));
    await h2.tick();
    t += 10 * 60e3; await h2.tick();
    ok(d2.ch.logs.length === 0, "not forwarded after 10 minutes");
    t += 6 * 60e3; await h2.tick();
    ok(d2.ch.logs.length === 1 && /did not answer/.test(d2.ch.logs[0].content), 'forwarded after 15 minutes without an answer');
    // daily cap: no Claude call, checklist instead
    const d3 = fakeDiscord(), c3 = fakeClaude([]);
    const h3 = createHelper({ call: d3.call, client: c3, env: { BUG_DAILY_CALLS: '1' }, now: () => t, log: () => {} });
    await h3.init(); h3.state.day = new Date(t).toISOString().slice(0, 10); h3.state.calls = 1;
    d3.ch.bugs.push(d3.msg(P1, 'help'));
    await h3.tick();
    ok(c3.seen.length === 0 && /Which screen/.test(Object.values(d3.threads)[0][0].content), 'daily limit uses the checklist');
    // chat / a question: pointed elsewhere, nothing forwarded
    const d4 = fakeDiscord();
    const h4 = createHelper({ call: d4.call, client: fakeClaude([{ action: 'not_a_bug', reply: 'Questions are welcome in #support!', report: rep({ kind: 'question' }) }]), env: {}, log: () => {} });
    await h4.init();
    d4.ch.bugs.push(d4.msg(P1, 'how do I get Kakashi?'));
    await h4.tick();
    ok(d4.ch.logs.length === 0 && /#support/.test(Object.values(d4.threads)[0][0].content), 'a question is pointed to #support');
  }

  // 4. safety: a reply with a secret or an IP address is not posted as it is
  {
    const d = fakeDiscord();
    const h = createHelper({ call: d.call, client: fakeClaude([{ action: 'ask', reply: 'connect to 134.98.153.241 please', report: rep() }]), env: {}, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg(P1, 'cannot connect'));
    await h.tick();
    const text = Object.values(d.threads)[0][0].content;
    ok(!/\d+\.\d+\.\d+\.\d+/.test(text), 'no IP address posted');
    ok(buildMessages({ id: '1', author: P1, content: 'x', attachments: [] }, [], 'bot')[0].role === 'user', 'conversation starts with the player');
    ok(SCHEMA.properties.report.required.length === Object.keys(SCHEMA.properties.report.properties).length, 'schema: every report field required (strict JSON)');
    ok(/Wish/.test(reportText({ name: 'Kid', id: '9' }, rep({ kind: 'wish' }), 'x')), 'wishes are labelled');
  }

  // 5. the owner trying it out: a post starting with "test" is handled, its report is marked TEST and has no report-id (the fixer skips it)
  {
    const d = fakeDiscord();
    const h = createHelper({ call: d.call, client: fakeClaude([{ action: 'complete', reply: 'Thanks!', report: rep() }]), env: { OWNER_IDS: 'own' }, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg({ id: 'own', username: 'bakeddean' }, 'Test: the arena button does nothing'));
    await h.tick();
    const log = d.ch.logs[0];
    ok(Object.keys(d.threads).length === 1 && log && /TEST/.test(log.content) && !/report-id/.test(log.content), 'owner test post: thread + TEST report without report-id');
  }

  // 6. claim: the owner types .claim (or /claim) in a thread and the bot stays quiet there until .reclaim; owner messages never get an answer
  {
    const d = fakeDiscord();
    let t = 0;
    const claude = fakeClaude([{ action: 'ask', reply: 'Which screen?', report: rep() }, { action: 'ask', reply: 'And your character?', report: rep() }]);
    const h = createHelper({ call: d.call, client: claude, env: { OWNER_IDS: 'own' }, now: () => t, log: () => {} });
    await h.init();
    d.ch.bugs.push(d.msg(P1, 'my pet does not attack'));
    await h.tick();
    const tid = Object.keys(d.threads)[0], th = d.threads[tid];
    ok(claude.seen.length === 1, 'claim: first question asked');
    th.push(d.msg(OWNER, 'Hey, I am the dev, which pet is it?')); // the owner talks without claiming: no bot answer
    await h.tick();
    ok(claude.seen.length === 1 && th[th.length - 1].author.id === 'own', 'owner message gets no bot answer');
    const cl = d.msg(OWNER, '/claim'); th.push(cl);
    th.push(d.msg(P1, 'the fox one'));
    await h.tick();
    ok(claude.seen.length === 1 && th[th.length - 1].author.id === 'p1', 'claimed: the bot stays quiet when the player answers');
    ok(d.reactions.some(([m, e]) => m === cl.id && e === '🤐'), 'claim gets a 🤐 reaction');
    t += 25 * 3600e3; await h.tick();
    ok(d.ch.logs.length === 0, 'claimed: not forwarded when the player goes quiet');
    const rc = d.msg(OWNER, '.reclaim'); th.push(rc);
    await h.tick();
    ok(claude.seen.length === 1 && d.reactions.some(([m, e]) => m === rc.id && e === '🤖'), 'reclaim: 🤖, no answer to old messages');
    th.push(d.msg(P1, 'still broken'));
    await h.tick();
    ok(claude.seen.length === 2 && /character/.test(th[th.length - 1].content), 'after reclaim the bot answers the player again');
    const sent = claude.seen[1].messages;
    ok(!sent.some((m) => JSON.stringify(m.content).includes('/claim')) && sent.some((m) => JSON.stringify(m.content).includes('(server owner)')), 'commands left out, owner labelled for Claude');
    th.push(d.msg(P1, '.claim')); // a player cannot claim
    await h.tick();
    ok(!h.state.threads[tid].claimed, 'a player cannot claim');
  }

  // 6. #bugs-and-issues as a forum (owner, 10 Nov 2026): every post is a report, the bot answers inside it and sets its tag
  {
    let t = Date.UTC(2026, 10, 10, 22);
    const snow = (ms) => String((BigInt(ms) - 1420070400000n) << 22n);
    const posts = {}, list = [], logs = [], patches = [], reactions = [];
    const BOT = { id: 'bot', username: 'HelloBro', bot: true };
    let n = 0;
    const msg = (author, content, at) => ({ id: snow(at) + String(++n).padStart(0, ''), type: 0, author, content, attachments: [] });
    const newPost = (author, title, content, at) => { const m = { ...msg(author, content, at) }; m.id = snow(at); posts[m.id] = [m]; list.push({ id: m.id, parent_id: 'bugs', name: title }); return m.id; };
    const call = async (method, p, body) => {
      let m;
      if (p === '/users/@me') return BOT;
      if (p === '/users/@me/guilds') return [{ id: 'g' }];
      if (p === '/guilds/g/channels') return [{ id: 'bugs', name: 'bugs-and-issues', type: 15, available_tags: [{ id: 'tn', name: 'Needs info' }, { id: 'tw', name: 'With the developer' }] }, { id: 'logs', name: 'bot-logs', type: 0 }];
      if (p === '/guilds/g/threads/active') return { threads: list };
      if ((m = /^\/channels\/(\d+)$/.exec(p)) && method === 'PATCH') { patches.push([m[1], body.applied_tags]); return {}; }
      if ((m = /^\/channels\/(\w+)\/messages\/(\w+)\/reactions\/([^/]+)\/@me$/.exec(p))) { reactions.push([m[1], m[2], decodeURIComponent(m[3])]); return null; }
      if ((m = /^\/channels\/(\d+)\/messages\/(\d+)$/.exec(p)) && method === 'GET') return (posts[m[1]] || []).find((x) => x.id === m[2]);
      if ((m = /^\/channels\/(\w+)\/messages\?(.*)$/.exec(p)) && method === 'GET') {
        const q = new URLSearchParams(m[2]); const all = (posts[m[1]] || []).slice();
        const after = q.get('after');
        return (after ? all.filter((x) => BigInt(x.id) > BigInt(after)) : all).reverse().slice(0, Number(q.get('limit') || 50));
      }
      if ((m = /^\/channels\/(\w+)\/messages$/.exec(p)) && method === 'POST') { const x = msg(BOT, body.content, t); x.id = String(BigInt(snow(t)) + BigInt(++n)); (m[1] === 'logs' ? logs : posts[m[1]]).push(x); return x; }
      throw new Error('unexpected call ' + method + ' ' + p);
    };
    const claude = fakeClaude([{ action: 'ask', reply: 'Which screen?', report: rep({ where: '' }) }, { action: 'complete', reply: 'Thanks!', report: rep() }]);
    const h = createHelper({ call, client: claude, env: { OWNER_IDS: 'own' }, now: () => t, log: () => {} });
    const old = newPost(P1, 'Old post', 'from before the bot', t - 60000);
    await h.init();
    await h.tick();
    ok(!h.state.threads[old], 'forum: posts from before the bot started are left alone');
    t += 60000;
    newPost(OWNER, 'Owner post', 'looking into the arena', t); // the owner's own post: left alone
    const pid = newPost(P1, 'Arena button does nothing', 'I tap it and nothing happens', t + 1);
    t += 1000; await h.tick();
    ok(Object.keys(h.state.threads).length === 1 && h.state.threads[pid], 'forum: a player post is a report, the owner post is not');
    ok(posts[pid].length === 2 && posts[pid][1].content === 'Which screen?', 'forum: the bot asks inside the post');
    ok(JSON.stringify(claude.seen[0].messages).includes('Arena button does nothing'), "forum: the post's title goes to Claude");
    ok(patches.some(([id, tg]) => id === pid && tg[0] === 'tn'), 'forum: the post gets the tag Needs info');
    posts[pid].push(msg(P1, 'the arena screen, Ninja1, ninjaonline', t + 2000)); posts[pid].at(-1).id = snow(t + 2000);
    t += 3000; await h.tick();
    ok(logs.length === 1 && new RegExp('report-id: ' + pid + ' · post-id: ' + pid).test(logs[0].content), 'forum: complete report in #bot-logs with the post number');
    ok(patches.some(([id, tg]) => id === pid && tg[0] === 'tw'), 'forum: the post gets the tag With the developer');
    ok(reactions.some(([c, m, e]) => c === pid && m === pid && e === '📝'), 'forum: 📝 on the post itself');
  }

  console.log(bad ? bad + ' problem(s) in the bug helper' : 'bug helper OK (threads, questions, reports, fallback, limits, safety, claim, forum)');
  process.exit(bad ? 1 : 0);
})().catch((e) => { console.log('CRASH', e.stack); process.exit(1); });
