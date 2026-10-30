// Discord <-> tools adapter. Real one uses discord.js; fake one (no token needed) is used for dry runs and tests.
const NO_PINGS = { parse: [] }; // the bot can never @everyone / @role / @user

function realAdapter(client, guildId) {
  const guild = async () => {
    const g = guildId ? await client.guilds.fetch(guildId) : (await client.guilds.fetch()).first();
    if (!g) throw new Error('the bot is not in any server');
    return g.fetch ? g.fetch() : g;
  };
  const textChannels = async () => {
    const g = await guild();
    const all = await g.channels.fetch();
    return [...all.values()].filter((c) => c && c.isTextBased() && !c.isThread() && !c.isVoiceBased());
  };
  const adapter = {
    async channels() { return (await textChannels()).map((c) => ({ id: c.id, name: c.name, category: c.parent ? c.parent.name : null })); },
    async channel(ref) {
      const list = await textChannels();
      const r = String(ref).replace(/^<#(\d+)>$/, '$1').replace(/^#/, '').toLowerCase();
      const exact = list.filter((c) => c.id === r || c.name.toLowerCase() === r);
      // channel names often carry emoji prefixes ("📚│tutorial"): fall back to "contains"
      const found = exact.length ? exact : list.filter((c) => c.name.toLowerCase().includes(r));
      if (found.length === 1) return found[0];
      throw new Error(found.length ? `"${ref}" matches several channels: ${found.map((c) => c.name).join(', ')}` : `no channel called "${ref}" (use list_channels)`);
    },
    async recent(ch, n) {
      const msgs = [...(await ch.messages.fetch({ limit: n })).values()].reverse();
      return msgs.map((m) => ({ id: m.id, author: m.author.username, mine: m.author.id === client.user.id, content: m.content }));
    },
    async send(ch, text) { return (await ch.send({ content: text, allowedMentions: NO_PINGS })).id; },
    async edit(ch, id, text) {
      const m = await ch.messages.fetch(id);
      if (m.author.id !== client.user.id) throw new Error('that message is not mine, so I cannot edit it');
      await m.edit({ content: text, allowedMentions: NO_PINGS });
    },
    async remove(ch, id) {
      const m = await ch.messages.fetch(id);
      if (m.author.id !== client.user.id) throw new Error('that message is not mine, so I cannot delete it');
      await m.delete();
    },
  };
  return adapter;
}

// In-memory stand-in so the agent can be tried without Discord.
function fakeAdapter(names = ['welcome', 'rules', 'announcements', 'tutorial', 'general']) {
  const chans = names.map((n, i) => ({ id: String(100 + i), name: n, msgs: [] }));
  let next = 1;
  const get = (ref) => { const r = String(ref).replace(/^#/, '').toLowerCase(); const c = chans.find((x) => x.id === r || x.name === r); if (!c) throw new Error(`no channel called "${ref}"`); return c; };
  return {
    chans,
    async channels() { return chans.map((c) => ({ id: c.id, name: c.name, category: null })); },
    async channel(ref) { return get(ref); },
    async recent(ch, n) { return ch.msgs.slice(-n); },
    async send(ch, text) { const m = { id: String(next++), author: 'bot', mine: true, content: text }; ch.msgs.push(m); return m.id; },
    async edit(ch, id, text) { const m = ch.msgs.find((x) => x.id === id); if (!m) throw new Error('no such message'); m.content = text; },
    async remove(ch, id) { const i = ch.msgs.findIndex((x) => x.id === id); if (i < 0) throw new Error('no such message'); ch.msgs.splice(i, 1); },
  };
}

module.exports = { realAdapter, fakeAdapter };
