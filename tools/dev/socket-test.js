// The real server (server/server.js) must survive connections that are cut before they send anything (browsers open spare
// connections and drop them; scanners do the same). On 4 Nov 2026 such a reset (ECONNRESET) crashed the public server 3 times
// in one night. Starts server.js on a temp save, cuts a few connections, then checks it still answers. Run by check.sh.
const { spawn } = require('child_process');
const net = require('net');
const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hb-sock-'));
const PORT = 18000 + Math.floor(Math.random() * 900);
const srv = spawn(process.execPath, [path.join(__dirname, '..', '..', 'server', 'server.js')], {
  cwd: dir, stdio: ['ignore', 'pipe', 'pipe'],
  env: { ...process.env, PORT: String(PORT), DB: path.join(dir, 'test.db'), HB_BACKUPS: path.join(dir, 'backups'), HB_WATCHDOG: '', HB_MANAGED: '' },
});
let log = '';
srv.stdout.on('data', (d) => { log += d; });
srv.stderr.on('data', (d) => { log += d; });
let exited = null;
srv.on('exit', (code) => { exited = code; });

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const status = () => new Promise((ok) => {
  const q = http.get({ host: '127.0.0.1', port: PORT, path: '/status', timeout: 3000 }, (r) => { r.resume(); ok(r.statusCode === 200); });
  q.on('timeout', () => q.destroy());
  q.on('error', () => ok(false));
});
const cut = (sendFirst) => new Promise((ok) => {
  const s = net.connect(PORT, '127.0.0.1', () => {
    if (sendFirst) s.write('POST /rl_r_mainpage HTTP/1.1\r\nHost: x\r\nContent-Length: 100\r\n\r\nabc');
    setTimeout(() => { s.resetAndDestroy(); ok(); }, 50);
  });
  s.on('error', () => ok());
});
function end(msg, code) {
  console.log(msg);
  srv.kill();
  setTimeout(() => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch (e) {} process.exit(code); }, 300);
}

(async () => {
  for (let i = 0; i < 50 && !(await status()); i++) await wait(200);
  if (!(await status())) return end('SOCKET test: server did not start\n' + log.slice(-1500), 1);
  for (let i = 0; i < 5; i++) { await cut(false); await cut(true); }
  await wait(500);
  if (exited !== null || !(await status())) return end('SOCKET test: server crashed on a cut connection (ECONNRESET)\n' + log.slice(-1500), 1);
  end('socket test: server survived 10 cut connections', 0);
})();
