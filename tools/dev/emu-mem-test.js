// The browser game's memory manager (server/webclient/emu/sys.js malloc / free / realloc): blocks never overlap, keep
// their bytes, and freed memory is used again whatever the size of the next request. Until 16 Nov 2026 a freed big block
// only served a request of exactly its own size and phones stopped with "out of emulated memory". node tools/dev/emu-mem-test.js
'use strict';
const path = require('path');
const E = path.join(__dirname, '..', '..', 'server', 'webclient', 'emu');
const Cpu = require(path.join(E, 'cpu.js')), makeSys = require(path.join(E, 'sys.js'));
let bad = 0;
const ok = (c, m) => { if (!c) { bad++; console.log('FAIL ' + m); } };
const MEM = 64 << 20, START = 0x01000000;
const make = () => { const cpu = new Cpu(MEM); return { cpu, sys: makeSys(cpu, { heapStart: START, heapEnd: MEM - (8 << 20), vfs: { read: () => null, exists: () => false, isDir: () => false, list: () => [], write() {} }, log() {}, extra: {} }) }; };
let seed = 12345;
const rnd = (n) => { seed = (Math.imul(seed, 1103515245) + 12345) >>> 0; return (seed >>> 8) % n; };

// 1. pictures of ever-changing sizes, loaded and dropped: 40 000 of them (about 20 GB in all) must fit in 40 MB
{
  const { cpu, sys } = make();
  const live = [];
  let err = '';
  try {
    for (let i = 0; i < 40000; i++) {
      const n = 5000 + rnd(1 << 20);
      const p = sys.malloc(n);
      cpu.u8[p] = i & 255; cpu.u8[p + n - 1] = (i >> 8) & 255;
      live.push([p, n, i]);
      if (live.length > 12) { const [q, m, j] = live.splice(rnd(live.length), 1)[0]; if (cpu.u8[q] !== (j & 255) || cpu.u8[q + m - 1] !== ((j >> 8) & 255)) { err = 'bytes changed in block ' + j; break; } sys.free(q); }
    }
  } catch (e) { err = e.message; }
  ok(!err, 'changing picture sizes: ' + err);
  ok(sys.heapUsed() < 24 << 20, 'changing picture sizes took ' + (sys.heapUsed() >> 20) + ' MB (at most 12 live blocks of up to 1 MB)');
  for (const [q] of live) sys.free(q);
  ok(sys.heapUsed() < 1 << 20, 'everything freed, still ' + (sys.heapUsed() >> 10) + ' KB taken');
}

// 2. mixed small and big blocks: no two live blocks overlap, every block keeps its bytes, realloc keeps the start
{
  const { cpu, sys } = make();
  const live = new Map();
  let err = '';
  const fill = (p, n, tag) => { for (let i = 0; i < n; i += 97) cpu.u8[p + i] = (tag + i) & 255; cpu.u8[p + n - 1] = tag & 255; };
  const check = (p, n, tag) => { for (let i = 0; i < n - 1; i += 97) if (cpu.u8[p + i] !== ((tag + i) & 255)) return false; return true; };
  try {
    for (let i = 0; i < 60000 && !err; i++) {
      const r = rnd(10);
      if ((r < 5 && live.size < 150) || live.size < 50) {
        const n = 1 + (rnd(4) ? rnd(600) : rnd(4) ? rnd(20000) : rnd(900000));
        const p = sys.malloc(n);
        if (p & 7) err = 'address not a multiple of 8';
        if (p < START || p + n > MEM - (8 << 20)) err = 'block outside the heap';
        fill(p, n, i); live.set(p, [n, i]);
      } else {
        const keys = [...live.keys()], p = keys[rnd(keys.length)], [n, tag] = live.get(p);
        if (!check(p, n, tag)) { err = 'bytes changed in block ' + tag; break; }
        live.delete(p);
        if (r < 8) sys.free(p);
        else { const m = n + 1 + rnd(Math.min(n, 100000) + 100), q = sys.realloc(p, m); if (!check(q, n, tag)) { err = 'realloc lost bytes'; break; } fill(q, m, tag); live.set(q, [m, tag]); }
      }
      if (i % 5000 === 0) { // overlap check
        const s = [...live].map(([p, [n]]) => [p, p + n]).sort((a, b) => a[0] - b[0]);
        for (let k = 1; k < s.length; k++) if (s[k][0] < s[k - 1][1]) { err = 'two blocks overlap'; break; }
        const rg = sys.heapRanges();
        for (let k = 1; k < rg.length; k++) if (rg[k][0] <= rg[k - 1][0] + rg[k - 1][1]) { err = 'freed ranges not joined or out of order'; break; }
        for (const [a, z] of rg) for (const [x, y] of s) if (x < a + z && y > a) { err = 'a live block lies in a freed range'; break; }
      }
    }
  } catch (e) { err = e.message; }
  ok(!err, 'mixed blocks: ' + err);
  for (const p of live.keys()) sys.free(p);
  const p = sys.malloc(100000); sys.free(p); sys.free(p); // freeing twice must not hand the memory out twice
  const a = sys.malloc(100000), b = sys.malloc(100000);
  ok(a !== b, 'a block freed twice was handed out twice');
}

// 3. full is full: a clear message instead of a wrong address
{
  const { sys } = make();
  let msg = '';
  try { for (let i = 0; i < 100; i++) sys.malloc(1 << 20); } catch (e) { msg = e.message; }
  ok(/out of emulated memory/.test(msg), 'no "out of emulated memory" when the memory is full: ' + msg);
  let huge = '';
  try { sys.malloc(0xfffffff0); } catch (e) { huge = e.message; }
  ok(/out of emulated memory/.test(huge), 'an impossible size is refused');
}
console.log(bad ? bad + ' problem(s)' : 'emu memory: ok');
process.exit(bad ? 1 : 0);
