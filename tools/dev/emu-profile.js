// Used by emu-boot.js with HB_PROFILE=1: counts the emulated instructions per 64-byte block of the app's code and prints the
// functions (names from re/all.txt) that take the most, when the run ends.
'use strict';
const fs = require('fs'), path = require('path');
module.exports = function profile(cpu, BASE, ROOT) {
  const counts = new Map();
  const t = cpu.thumb.bind(cpu), a = cpu.arm.bind(cpu);
  cpu.thumb = (pc) => { const k = pc >>> 6; counts.set(k, (counts.get(k) || 0) + 1); t(pc); };
  cpu.arm = (pc) => { const k = pc >>> 6; counts.set(k, (counts.get(k) || 0) + 1); a(pc); };
  process.on('exit', () => {
    const funcs = [];
    for (const line of fs.readFileSync(path.join(ROOT, 're', 'all.txt'), 'utf8').split('\n')) {
      const m = /^===== (\S+) 0x([0-9a-f]+) (\d+)/.exec(line);
      if (m) funcs.push([parseInt(m[2], 16) + BASE, Number(m[3]), m[1]]);
    }
    funcs.sort((x, y) => x[0] - y[0]);
    const byFn = new Map();
    let total = 0;
    for (const [k, n] of counts) {
      total += n;
      const addr = k << 6;
      let lo = 0, hi = funcs.length - 1, f = null;
      while (lo <= hi) { const mid = (lo + hi) >> 1; if (funcs[mid][0] <= addr) { f = funcs[mid]; lo = mid + 1; } else hi = mid - 1; }
      const name = f && addr < f[0] + f[1] + 64 ? f[2] : '?' + (addr - BASE).toString(16);
      byFn.set(name, (byFn.get(name) || 0) + n);
    }
    console.log('PROFILE: top functions of ' + (total / 1e6).toFixed(0) + ' M instructions');
    for (const [nm, n] of [...byFn].sort((x, y) => y[1] - x[1]).slice(0, 25)) console.log('  ' + (n / total * 100).toFixed(1).padStart(5) + '%  ' + nm.slice(0, 100));
  });
};
