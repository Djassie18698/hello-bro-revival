// #server-status (owner request 3 Nov 2026): checks the public server every minute and posts when it goes offline, comes back,
// gets updated (new version) or restarts. Runs inside online.js (START-BOT-ONLINE.bat), so it only watches while the owner's PC is on.
// The server answers /status with { version, started } (server/server.js). Last state is kept in status-state.json (git-ignored),
// so restarting the bot does not post twice.
//   node --env-file=.env statuswatch.js once     one check, prints what it would post (posts nothing)
const fs = require('fs');
const path = require('path');
const { makeApi } = require('./dc.js');

const URL = process.env.STATUS_URL || 'http://ninjaonline.duckdns.org:18080/status';
const CHANNEL = process.env.STATUS_CHANNEL || 'server-status';
const EVERY = 60 * 1000, DOWN_AFTER = 2; // two failed checks in a row (a minute or more) = offline; a single blip is ignored
const STATE = path.join(__dirname, 'status-state.json');
const UPDATES = '<#1565697769874919515>';

const load = () => { try { return JSON.parse(fs.readFileSync(STATE, 'utf8')); } catch { return {}; } };
const save = (s) => { try { fs.writeFileSync(STATE, JSON.stringify(s)); } catch { /* next check tries again */ } };
const mins = (sec) => Math.max(1, Math.round(sec / 60));

async function probe(url) {
  try {
    const r = await fetch(url, { signal: AbortSignal.timeout(15000), cache: 'no-store' });
    return await r.json().catch(() => ({})); // any answer = online (a server from before /status existed has no version to compare)
  } catch { return null; }
}

// One check: returns the message to post (or null) and the new state.
async function check(st, url = URL, now = Math.floor(Date.now() / 1000)) {
  const s = { ...st };
  const got = await probe(url);
  if (!got) {
    // our own internet down? then we can't tell (and can't post either)
    if (!(await fetch('https://discord.com/api/v10/gateway', { signal: AbortSignal.timeout(15000) }).then((r) => r.ok, () => false))) return { msg: null, st };
    s.fails = (s.fails || 0) + 1;
    if (s.fails === 1) s.firstFail = now;
    if (s.fails >= DOWN_AFTER && s.state !== 'down') {
      s.state = 'down'; s.downSince = s.firstFail;
      return { st: s, msg: '🔴 **The public server is offline.** It usually comes back by itself within a few minutes. This channel says when it is back.' };
    }
    return { msg: null, st: s };
  }
  s.fails = 0;
  let msg = null;
  if (s.state === 'down') {
    msg = `🟢 **The public server is back online** (it was offline for about ${mins(now - (s.downSince || now))} minute${mins(now - (s.downSince || now)) === 1 ? '' : 's'}).`;
    if (s.version && got.version && got.version !== s.version) msg += ` It was also updated: see ${UPDATES} for what's new.`;
  } else if (s.version && got.version && got.version !== s.version) {
    msg = `🔄 **The public server was updated** (version ${got.version}). See ${UPDATES} for what's new. If you were playing, log in again.`;
  } else if (s.started && got.started && got.started !== s.started) {
    msg = '🔄 **The public server restarted.** It was only away for a moment; if the game says network error, log in again.';
  }
  Object.assign(s, { state: 'up', version: got.version || s.version, started: got.started || s.started });
  delete s.downSince; delete s.firstFail;
  return { msg, st: s };
}

function start(token) {
  const call = makeApi(token);
  let channelId = null, st = load();
  const log = (m) => console.log(new Date().toLocaleTimeString() + '  [status] ' + m);
  const find = async () => {
    const guilds = await call('GET', '/users/@me/guilds');
    for (const g of guilds) {
      const c = (await call('GET', `/guilds/${g.id}/channels`)).find((x) => x.name === CHANNEL);
      if (c) return c.id;
    }
    throw new Error(`no #${CHANNEL} channel`);
  };
  const tick = async () => {
    try {
      const r = await check(st);
      if (r.msg) {
        channelId = channelId || await find();
        await call('POST', `/channels/${channelId}/messages`, { content: r.msg, allowed_mentions: { parse: [] } });
        log('posted: ' + r.msg.replace(/\*/g, '').slice(0, 80));
      }
      st = r.st; save(st); // only after a successful post, so a failed post is tried again next minute
    } catch (e) { log('could not post: ' + e.message); }
  };
  log(`watching ${URL} every ${EVERY / 1000} s (posts in #${CHANNEL})`);
  tick();
  return setInterval(tick, EVERY);
}

module.exports = { start, check };

if (require.main === module && process.argv[2] === 'once') {
  check(load()).then((r) => console.log(JSON.stringify(r, null, 1)));
}
