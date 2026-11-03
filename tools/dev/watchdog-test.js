// The watchdog (server/watchdog.js) must stop a server that stopped answering: a fake server answers /status, then freezes its
// event loop; with fast settings the watchdog has to end it within a few seconds. Run by check.sh.
const { spawn } = require('child_process');
const path = require('path');
const fake = `
  const http = require('http');
  http.createServer((q, r) => r.end('{"ok":true}')).listen(0, '127.0.0.1', function () {
    require('child_process').fork(${JSON.stringify(path.join(__dirname, '..', '..', 'server', 'watchdog.js'))}, [], { env: { ...process.env, PORT: String(this.address().port),
      HB_WATCHDOG_EVERY: '0.3', HB_WATCHDOG_TIMEOUT: '0.5', HB_WATCHDOG_FAILS: '2' } });
    setTimeout(() => { const end = Date.now() + 30000; while (Date.now() < end); process.exit(7); }, 1000); // freeze for 30 s
  });`;
const t0 = Date.now();
const p = spawn(process.execPath, ['-e', fake], { stdio: 'ignore' });
const fail = setTimeout(() => { console.log('WATCHDOG did not stop a frozen server within 15 s'); p.kill('SIGKILL'); process.exit(1); }, 15000);
p.on('exit', (code) => {
  clearTimeout(fail);
  if (code === 7) { console.log('WATCHDOG let a frozen server run 30 s'); process.exit(1); }
  console.log(`watchdog stopped a frozen server after ${((Date.now() - t0) / 1000).toFixed(1)} s`);
});
