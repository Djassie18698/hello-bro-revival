// Watchdog for the always-on server (HB_WATCHDOG=1, set by tools/vps/run.sh). server.js starts this as a child process: it has its own
// event loop, so it keeps running when the server's is stuck. Every minute it asks the server's own /status; when the server has not
// answered for 3 minutes in a row it stops the server, and the service (Restart=always) starts it again within seconds.
// Why: on 3 Nov 2026 a 10-minute freeze (a slow "Best gear") kept the process alive but deaf, so nothing restarted it.
// A local run (START-SERVER.bat) does not use it: that .bat only restarts on exit code 3.
const http = require('http');

const PORT = Number(process.env.PORT || 18080);
const EVERY = Number(process.env.HB_WATCHDOG_EVERY || 60) * 1000; // seconds between checks
const LIMIT = Number(process.env.HB_WATCHDOG_FAILS || 3); // failed checks in a row before a restart
const WAIT = Number(process.env.HB_WATCHDOG_TIMEOUT || 20) * 1000; // how long one check waits for an answer
const parent = process.ppid;
const log = (m) => console.log(`[watchdog] ${m}`);

let fails = 0;
const check = () => new Promise((done) => {
  const req = http.get({ host: '127.0.0.1', port: PORT, path: '/status', timeout: WAIT }, (res) => { res.resume(); done(res.statusCode === 200); });
  req.on('timeout', () => req.destroy());
  req.on('error', () => done(false));
});

setInterval(async () => {
  if (await check()) { if (fails) log('the server answers again'); fails = 0; return; }
  fails++;
  log(`the server did not answer (${fails}/${LIMIT})`);
  if (fails < LIMIT) return;
  log(`no answer for ${fails} checks in a row: stopping it so the service starts it again`);
  try { process.kill(parent, 'SIGTERM'); } catch { /* already gone */ }
  setTimeout(() => { try { process.kill(parent, 'SIGKILL'); } catch { /* stopped */ } process.exit(0); }, 10000);
}, EVERY);

process.on('disconnect', () => process.exit(0)); // the server stopped: this one goes too
