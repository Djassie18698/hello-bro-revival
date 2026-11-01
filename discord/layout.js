// Discord server layout (owner request 1 Nov 2026): one place per kind of thing, read-only info channels, empty extras removed.
//   node --env-file=.env layout.js          show what would change
//   node --env-file=.env layout.js apply    do it (a channel is only deleted when it has no messages at all)
// Edit LAYOUT / REMOVE below and run again to keep the server tidy; it only changes what differs.
const { makeApi } = require('./dc.js');
const GUILD = '1565691956561060014';
const SEND = 2048n, VIEW = 1024n; // permission bits
const STAFF_ROLE = 'Master Shinobi';

const LAYOUT = [
  { cat: '📌 START HERE', readOnly: true, channels: [
    { name: 'welcome', topic: 'New here? Read #rules, then #install-help to get the game running.' },
    { name: 'rules', topic: 'Server rules. React to the message below to get your role.' },
    { name: 'announcements', topic: 'Server updates and new game updates. Hosting your own server? Run UPDATE.bat after each one.' },
    { name: 'faq', topic: 'Common questions: can\'t connect, how to update, accounts.' },
  ] },
  { cat: '📚 GUIDES & HELP', was: '📚 GUIDES & SUPPORT', channels: [
    { name: 'install-help', readOnly: true, topic: 'How to install and update Hello Bro (public server, phone, your own server). Questions go in #support.' },
    { name: 'how-to-play', readOnly: true, topic: 'Game guide: training, team, recruit, spar, arena, base buildings, events, cross-server battle.' },
    { name: 'support', topic: 'Ask for help here. Say: public server or your own, BlueStacks or phone, and what you see on screen.' },
    { name: 'bugs-and-issues', topic: 'Found a bug? Post what you did, what happened and a screenshot. Also on GitHub: github.com/Djassie18698/hello-bro-revival/issues' },
  ] },
  { cat: '💬 COMMUNITY', channels: [
    { name: 'general', topic: 'Chat about Hello Bro / Ninja Online. Help questions go in #support, bugs in #bugs-and-issues.' },
    { name: 'screenshots', topic: 'Your teams, pulls, clips, fan art and memes.' },
    { name: 'General • Voice', voice: true },
  ] },
  { cat: '🔧 DEV & STAFF', staff: true, channels: [
    { name: 'dev-chat', topic: 'Staff and development talk.' },
    { name: 'patch-testing', topic: 'Test new server and game updates before they go out.' },
    { name: 'bot-logs', topic: 'Bot logs.' },
    { name: 'Staff VC', voice: true },
  ] },
];
// empty extras to remove (channel names; categories that end up empty are removed too)
const REMOVE = ['showcase', 'memes', 'introductions', 'guides', 'clips', 'fan-art', 'nostalgia-archive', 'Chill • Lounge',
  'dev-announcements', 'bug-reports', 'mod-chat', 'Dev Test VC', 'bots'];
const REMOVE_CATS = ['🎨 MEDIA & ARCHIVES', '❗BUG REPORTS HERE!!!❗', '🤖 BOTS'];

(async () => {
  const apply = process.argv[2] === 'apply';
  const call = makeApi(process.env.DISCORD_TOKEN);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const roles = await call('GET', `/guilds/${GUILD}/roles`);
  const everyone = roles.find((r) => r.name === '@everyone').id, staff = (roles.find((r) => r.name === STAFF_ROLE) || {}).id;
  const me = await call('GET', '/users/@me');
  const botRole = (await call('GET', `/guilds/${GUILD}/members/${me.id}`)).roles[0];
  let chans = await call('GET', `/guilds/${GUILD}/channels`);
  const find = (name, type) => chans.find((c) => c.name.toLowerCase() === name.toLowerCase() && (type === undefined || (type === 'cat' ? c.type === 4 : c.type !== 4)));
  const say = (s) => console.log((apply ? '' : '[dry] ') + s);

  // 1. remove the empty extras
  for (const n of REMOVE) {
    const c = find(n, 'ch');
    if (!c) continue;
    if ([0, 5].includes(c.type)) { const m = await call('GET', `/channels/${c.id}/messages?limit=1`); if (m.length) { say(`KEEP #${n}: it has messages`); continue; } }
    say(`delete ${c.type === 2 ? 'voice' : '#'}${n}`);
    if (apply) { await call('DELETE', `/channels/${c.id}`); await sleep(400); }
  }
  // 2. categories, channels, order, topics, permissions
  let catPos = 0;
  for (const group of LAYOUT) {
    let cat = find(group.cat, 'cat');
    if (!cat && group.was && find(group.was, 'cat')) { cat = find(group.was, 'cat'); say(`rename category ${group.was} -> ${group.cat}`); if (apply) await call('PATCH', `/channels/${cat.id}`, { name: group.cat }); }
    if (!cat) { say(`create category ${group.cat}`); if (apply) { cat = await call('POST', `/guilds/${GUILD}/channels`, { name: group.cat, type: 4 }); chans.push(cat); } }
    if (cat && apply) await call('PATCH', `/channels/${cat.id}`, { position: catPos });
    catPos++;
    let pos = 0;
    for (const ch of group.channels) {
      let c = find(ch.name, 'ch');
      if (!c) { say(`create ${ch.voice ? 'voice' : '#'}${ch.name}`); if (apply) { c = await call('POST', `/guilds/${GUILD}/channels`, { name: ch.name, type: ch.voice ? 2 : 0, parent_id: cat.id }); chans.push(c); } else continue; }
      const patch = {};
      if (cat && c.parent_id !== cat.id) { patch.parent_id = cat.id; say(`move ${ch.name} -> ${group.cat}`); }
      if (c.position !== pos) patch.position = pos;
      if (!ch.voice && (c.topic || '') !== (ch.topic || '')) { patch.topic = ch.topic || ''; say(`topic #${ch.name}`); }
      // permissions: staff = hidden from everyone; read-only = nobody but staff/bots can post (reactions stay allowed)
      const ow = [];
      if (group.staff) { ow.push({ id: everyone, type: 0, allow: '0', deny: String(VIEW) }); if (staff) ow.push({ id: staff, type: 0, allow: String(VIEW), deny: '0' }); ow.push({ id: botRole, type: 0, allow: String(VIEW | SEND), deny: '0' }); }
      else if (group.readOnly || ch.readOnly) { ow.push({ id: everyone, type: 0, allow: '0', deny: String(SEND) }); if (staff) ow.push({ id: staff, type: 0, allow: String(SEND), deny: '0' }); ow.push({ id: botRole, type: 0, allow: String(SEND), deny: '0' }); }
      else if (ch.name === 'bugs-and-issues') ow.push({ id: everyone, type: 0, allow: String(VIEW | SEND), deny: '0' });
      const keep = (c.permission_overwrites || []).filter((o) => ![everyone, staff, botRole].includes(o.id)); // other roles (Carl-bot's reaction role etc.) stay
      const want = [...keep, ...ow];
      const norm = (l) => JSON.stringify(l.map((o) => [o.id, String(o.allow), String(o.deny)]).sort());
      if (norm(want) !== norm(c.permission_overwrites || [])) { patch.permission_overwrites = want; say(`permissions ${ch.name}${group.staff ? ' (staff only)' : group.readOnly || ch.readOnly ? ' (read-only)' : ''}`); }
      if (Object.keys(patch).length && apply) { await call('PATCH', `/channels/${c.id}`, patch); await sleep(400); }
      pos++;
    }
    if (cat && apply && group.staff) await call('PATCH', `/channels/${cat.id}`, { permission_overwrites: [{ id: everyone, type: 0, allow: '0', deny: String(VIEW) }, ...(staff ? [{ id: staff, type: 0, allow: String(VIEW), deny: '0' }] : []), { id: botRole, type: 0, allow: String(VIEW | SEND), deny: '0' }] });
  }
  // 3. categories left empty
  if (apply) chans = await call('GET', `/guilds/${GUILD}/channels`);
  for (const n of REMOVE_CATS) {
    const cat = find(n, 'cat');
    if (!cat) continue;
    if (chans.some((c) => c.parent_id === cat.id)) { say(`KEEP category ${n}: not empty`); continue; }
    say(`delete category ${n}`);
    if (apply) { await call('DELETE', `/channels/${cat.id}`); await sleep(400); }
  }
  console.log(apply ? 'done' : '(dry run: add "apply" to do it)');
})().catch((e) => { console.error('Error:', e.message); process.exit(1); });
