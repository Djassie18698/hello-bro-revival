// Keeps the Hello Bro bot shown as "online" (green dot, "Playing Hello Bro") in the Discord member list.
// Discord only shows a bot online while it holds a gateway connection, so this stays connected and does nothing else:
// no intents, it reads no messages and posts nothing. No npm install needed (Node 24 has WebSocket built in).
//   node --env-file=.env online.js        (START-BOT-ONLINE.bat runs it and restarts it if it stops)
const GATEWAY = 'wss://gateway.discord.gg/?v=10&encoding=json';
const ACTIVITY = process.env.BOT_ACTIVITY || 'Hello Bro';
const FATAL = { 4004: 'the bot token in .env is wrong (reset it in the Discord developer page)', 4013: 'bad intents', 4014: 'intents not allowed' };

const token = process.env.DISCORD_TOKEN;
if (!token) { console.error('No DISCORD_TOKEN in discord/.env'); process.exit(2); }

const log = (m) => console.log(new Date().toLocaleTimeString() + '  ' + m);
let seq = null, beat = null, acked = true, wait = 1000;

function connect() {
  const ws = new WebSocket(GATEWAY);
  const send = (op, d) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ op, d })); };
  ws.onmessage = (ev) => {
    const { op, d, s, t } = JSON.parse(ev.data);
    if (s != null) seq = s;
    if (op === 10) { // hello: start the heartbeat, then log in with the "online" presence
      clearInterval(beat); acked = true;
      beat = setInterval(() => {
        if (!acked) { log('Discord stopped answering, reconnecting'); return ws.close(4000); }
        acked = false; send(1, seq);
      }, d.heartbeat_interval);
      send(2, {
        token, intents: 0, properties: { os: 'windows', browser: 'hellobro', device: 'hellobro' },
        presence: { since: null, activities: [{ name: ACTIVITY, type: 0 }], status: 'online', afk: false },
      });
    } else if (op === 11) acked = true;
    else if (op === 1) send(1, seq);
    else if (op === 7 || op === 9) ws.close(4000); // Discord asks for a reconnect / a fresh login
    else if (op === 0 && t === 'READY') { wait = 1000; log(`Online as ${d.user.username} (Playing ${ACTIVITY}). Leave this window open.`); }
  };
  ws.onclose = (ev) => {
    clearInterval(beat);
    if (FATAL[ev.code]) { console.error('Stopped: ' + FATAL[ev.code]); process.exit(2); }
    log(`Connection closed (${ev.code}), reconnecting in ${Math.round(wait / 1000)} s`);
    setTimeout(connect, wait); wait = Math.min(wait * 2, 60000);
  };
  ws.onerror = () => {}; // onclose follows and reconnects
}
connect();
