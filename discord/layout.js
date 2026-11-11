// Discord server layout (owner request 1 Nov 2026): one place per kind of thing, read-only info channels, empty extras removed.
//   node --env-file=.env layout.js          show what would change
//   node --env-file=.env layout.js apply    do it (a channel is only deleted when it has no messages at all)
// Edit LAYOUT / REMOVE below and run again to keep the server tidy; it only changes what differs.
const { makeApi } = require('./dc.js');
const GUILD = '1565691956561060014';
const SEND = 2048n, VIEW = 1024n; // permission bits
const FORUM_BOT = (1n << 34n) | (1n << 35n) | (1n << 38n); // manage threads (set a post's tags), create posts, write in posts
const STAFF_ROLE = 'Master Shinobi'; // = Administrator: only the owner's trusted admins, never a supporter tier
// Extra roles the script keeps (created when missing, colour/permissions kept as set here), highest first, all below the bot's role.
// Moderator (owner, 9 Nov 2026: "just a discord mod, nothing crazy"): delete messages, timeout, kick/ban, voice mute/move, nicknames, threads;
// NOT admin, server settings, roles, channels, webhooks or @everyone. Supporter roles (Patreon tiers €1/€3/€5) are cosmetic (no permissions);
// the Patreon bot hands them out once the owner connects Patreon to Discord.
const P = { KICK: 2n, BAN: 4n, MANAGE_MESSAGES: 8192n, MUTE: 4194304n, DEAFEN: 8388608n, MOVE: 16777216n, NICKS: 134217728n, THREADS: 1n << 34n, TIMEOUT: 1n << 40n };
const ROLES = [
  { name: 'Moderator', color: 0x2ecc71, perms: P.KICK | P.BAN | P.MANAGE_MESSAGES | P.MUTE | P.DEAFEN | P.MOVE | P.NICKS | P.THREADS | P.TIMEOUT },
  { name: 'Shinobi Elder', color: 0xf1c40f, perms: 0n }, // Patreon €5
  { name: 'Shadow Ninja', color: 0x9b59b6, perms: 0n }, // Patreon €3
  { name: 'Shinobi Recruit', color: 0xcd7f32, perms: 0n }, // Patreon €1
];
const SUPPORTERS = ['Shinobi Recruit', 'Shadow Ninja', 'Shinobi Elder'];

const LAYOUT = [
  { cat: '📌 START HERE', readOnly: true, channels: [
    { name: 'welcome', topic: 'New here? Read #rules, then #install-help to get the game running.' },
    { name: 'rules', topic: 'Server rules. React to the message below to get your role.' },
    { name: 'announcement', topic: 'Only the big news: a new game app to install, new releases, important changes for everyone.' },
    { name: 'updates', was: 'announcements', topic: 'Every server and game update. Hosting your own server? Run UPDATE.bat after each one.' },
    { name: 'server-status', topic: 'Is the public server (ninjaonline) up? The bot posts here when it goes offline, comes back or gets updated. Pinned: how to connect + the item page.' },
    { name: 'faq', topic: 'Common questions: can\'t connect, how to update, accounts.' },
  ] },
  { cat: '📚 GUIDES & HELP', was: '📚 GUIDES & SUPPORT', channels: [
    { name: 'install-help', readOnly: true, topic: 'How to install and update Hello Bro (public server, phone, your own server). Questions go in #support.' },
    { name: 'how-to-play', readOnly: true, topic: 'Game guide: training, team, recruit, spar, arena, base buildings, events, cross-server battle.' },
    { name: 'support', topic: 'Ask for help here. Say: public server or your own, BlueStacks or phone, and what you see on screen.' },
    // a forum since 10 Nov 2026 (owner: "easier to track than posts that become threads"): one post per report; the bug helper (bughelper.js)
    // answers inside it and sets the tags (moderated: players can't set them), the bug fixer sets Fixed / Live / Not possible
    { name: 'bugs-and-issues', forum: true, open: true, topic: 'Found a bug? Make a New Post: a short title, then what you did, what happened, and a screenshot. The bot asks for anything missing; the tag shows where your report stands. Also on GitHub: github.com/Djassie18698/hello-bro-revival/issues',
      tags: [['Needs info', '❔'], ['With the developer', '🔧'], ['Fixed', '✅'], ['Live', '🚀'], ['Not possible', '🚫'], ['Wish', '💡'], ['Not a bug', '💬']].map(([n, e]) => [n, e, true]) },
    { name: 'bugs-and-issues-old', was: 'bugs-and-issues', readOnly: true, topic: 'The bug reports from before 10 Nov 2026 (read-only). New reports: #bugs-and-issues.' },
  ] },
  { cat: '💬 COMMUNITY', channels: [
    { name: 'general', topic: 'Chat about Hello Bro / Ninja Online. Help questions go in #support, bugs in #bugs-and-issues.' },
    { name: 'screenshots', topic: 'Your teams, pulls, clips, fan art and memes.' },
    // owner, 11 Nov 2026: players post old pictures of the original game so the numbers lost with the dead server can come back
    { name: 'old-screenshots', topic: 'Old screenshots or videos of the ORIGINAL Hello Bro / Ninja Online (before 2026)? Post them here: they help bring back the original numbers. See the pinned list of what we look for.' },
    { name: 'General • Voice', voice: true },
  ] },
  { cat: '💎 SUPPORTERS', staff: true, alsoRoles: SUPPORTERS, channels: [
    { name: 'supporters', topic: 'Thank you for supporting Ninja Online Reborn on Patreon! Sneak peeks, votes on what comes next, and a place to chat.' },
  ] },
  { cat: '🔧 DEV & STAFF', staff: true, channels: [
    { name: 'dev-chat', topic: 'Staff and development talk.' },
    // the bug fixer's desk (owner, 10 Nov 2026: "a forum, a new post per thing that's needed"): one post per report or question, the state as a tag;
    // the owner answers inside a post (or starts a post with a request) and the next fixer run acts on it (scheduled task hellobro-bug-fixer)
    { name: 'bug-fixer', forum: true, topic: 'The bug fixer: one post per bug report or question. The tag shows where it stands. Answer inside a post, or start a new post to ask the fixer something; it reads them on every run (every 2 hours).',
      tags: [['New report', '🆕'], ['Question for you', '❓'], ['Working on it', '🔧'], ['Fixed, not live yet', '✅'], ['Live', '🚀'], ['Not possible', '🚫'], ['Wish', '💡'], ['Request', '📝'], ['Stopped', '⏸️']] },
    { name: 'patch-testing', topic: 'Test new server and game updates before they go out.', alsoRoles: ['Shinobi Elder'] }, // €5 perk: early access to test updates
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
  let roles = await call('GET', `/guilds/${GUILD}/roles`);
  const everyone = roles.find((r) => r.name === '@everyone').id, staff = (roles.find((r) => r.name === STAFF_ROLE) || {}).id;
  const me = await call('GET', '/users/@me');
  const botRole = (await call('GET', `/guilds/${GUILD}/members/${me.id}`)).roles[0];
  const say = (s) => console.log((apply ? '' : '[dry] ') + s);
  // 0. the extra roles: create when missing, keep colour / permissions / shown separately, order them just below the bot
  for (const want of ROLES) {
    const r = roles.find((x) => x.name === want.name);
    const body = { name: want.name, color: want.color, permissions: String(want.perms), hoist: true, mentionable: false };
    if (!r) { say(`create role ${want.name}`); if (apply) roles.push(await call('POST', `/guilds/${GUILD}/roles`, body)); }
    else if (r.color !== want.color || String(r.permissions) !== String(want.perms) || !r.hoist) { say(`role ${want.name}: colour/permissions`); if (apply) await call('PATCH', `/guilds/${GUILD}/roles/${r.id}`, body); }
  }
  if (apply) {
    roles = await call('GET', `/guilds/${GUILD}/roles`);
    const botPos = roles.find((r) => r.id === botRole).position;
    const below = roles.filter((r) => r.position < botPos && r.id !== everyone).sort((a, b) => b.position - a.position);
    const mine = ROLES.map((w) => below.find((r) => r.name === w.name)).filter(Boolean);
    // ours right below the bot, above the member role "Training Shinobi" (else its gold colour wins). Move only our own roles: Discord
    // refuses a bulk move that touches another bot's managed role. If the member role ends up above them, move it down by hand in Discord.
    if (mine.some((r, i) => r.position !== botPos - 1 - i)) { say('role order'); await call('PATCH', `/guilds/${GUILD}/roles`, mine.map((r, i) => ({ id: r.id, position: botPos - 1 - i }))); }
  }
  const roleId = (n) => (roles.find((r) => r.name === n) || {}).id;
  const extraIds = ROLES.map((w) => roleId(w.name)).filter(Boolean);
  let chans = await call('GET', `/guilds/${GUILD}/channels`);
  const find = (name, type) => chans.find((c) => c.name.toLowerCase() === name.toLowerCase() && (type === undefined || (type === 'cat' ? c.type === 4 : c.type !== 4)));

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
      let c = ch.forum ? chans.find((x) => x.name.toLowerCase() === ch.name.toLowerCase() && x.type === 15) : find(ch.name, 'ch');
      if (!c && ch.forum && find(ch.name, 'ch')) { say(`#${ch.name} is a text channel: rename it first (it can't become a forum)`); continue; }
      if (!c && ch.was && find(ch.was, 'ch')) { c = find(ch.was, 'ch'); say(`rename #${ch.was} -> #${ch.name}`); if (apply) { await call('PATCH', `/channels/${c.id}`, { name: ch.name }); c.name = ch.name; } }
      if (!c) { say(`create ${ch.voice ? 'voice' : '#'}${ch.name}`); if (apply) { c = await call('POST', `/guilds/${GUILD}/channels`, { name: ch.name, type: ch.voice ? 2 : ch.forum ? 15 : 0, parent_id: cat.id, ...(ch.forum ? { default_forum_layout: 1 } : {}) }); chans.push(c); } else continue; }
      const patch = {};
      if (cat && c.parent_id !== cat.id) { patch.parent_id = cat.id; say(`move ${ch.name} -> ${group.cat}`); }
      if (c.position !== pos) patch.position = pos;
      if (!ch.voice && (c.topic || '') !== (ch.topic || '')) { patch.topic = ch.topic || ''; say(`topic #${ch.name}`); }
      if (ch.forum) { // forum tags (the post states): add the missing ones, keep the ids of those that exist
        const have = c.available_tags || [];
        if (ch.tags.some(([n]) => !have.some((t) => t.name === n))) {
          patch.available_tags = [...have, ...ch.tags.filter(([n]) => !have.some((t) => t.name === n)).map(([name, emoji_name, moderated]) => ({ name, emoji_name, moderated: !!moderated }))];
          say(`tags #${ch.name}`);
        }
      }
      // permissions: staff = hidden from everyone; read-only = nobody but staff/bots can post (reactions stay allowed)
      const ow = [];
      if (group.staff) { ow.push({ id: everyone, type: 0, allow: '0', deny: String(VIEW) }); if (staff) ow.push({ id: staff, type: 0, allow: String(VIEW), deny: '0' }); ow.push({ id: botRole, type: 0, allow: String(ch.forum ? VIEW | SEND | FORUM_BOT : VIEW | SEND), deny: '0' });
        for (const n of [...(group.alsoRoles || []), ...(ch.alsoRoles || [])]) if (roleId(n)) ow.push({ id: roleId(n), type: 0, allow: String(VIEW | SEND), deny: '0' }); }
      else if (group.readOnly || ch.readOnly) { ow.push({ id: everyone, type: 0, allow: '0', deny: String(SEND) }); if (staff) ow.push({ id: staff, type: 0, allow: String(SEND), deny: '0' }); ow.push({ id: botRole, type: 0, allow: String(SEND), deny: '0' }); }
      else if (ch.open) { ow.push({ id: everyone, type: 0, allow: String(VIEW | SEND | (1n << 38n)), deny: '0' }); ow.push({ id: botRole, type: 0, allow: String(VIEW | SEND | FORUM_BOT), deny: '0' }); } // a forum anyone can post in
      const keep = (c.permission_overwrites || []).filter((o) => ![everyone, staff, botRole, ...extraIds].includes(o.id)); // other roles (Carl-bot's reaction role etc.) stay
      const want = [...keep, ...ow];
      const norm = (l) => JSON.stringify(l.map((o) => [o.id, String(o.allow), String(o.deny)]).sort());
      if (norm(want) !== norm(c.permission_overwrites || [])) { patch.permission_overwrites = want; say(`permissions ${ch.name}${group.staff ? ' (staff only)' : group.readOnly || ch.readOnly ? ' (read-only)' : ''}`); }
      if (Object.keys(patch).length && apply) { await call('PATCH', `/channels/${c.id}`, patch); await sleep(400); }
      pos++;
    }
    if (cat && apply && group.staff) await call('PATCH', `/channels/${cat.id}`, { permission_overwrites: [{ id: everyone, type: 0, allow: '0', deny: String(VIEW) }, ...(staff ? [{ id: staff, type: 0, allow: String(VIEW), deny: '0' }] : []), { id: botRole, type: 0, allow: String(VIEW | SEND), deny: '0' },
      ...(group.alsoRoles || []).filter(roleId).map((n) => ({ id: roleId(n), type: 0, allow: String(VIEW | SEND), deny: '0' }))] });
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
