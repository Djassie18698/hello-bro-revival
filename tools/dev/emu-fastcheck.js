// Used by emu-boot.js with HB_FASTCHECK=1: every call of a fast.js function also runs the app's original code on the same
// input, and the registers and memory each one wrote are compared. Stops at the first difference.
'use strict';
module.exports = function fastcheck(cpu, lib) {
  const R = (a) => cpu.r32(a) >>> 0;
  // the memory each function may change: [start, length] pieces
  const areas = {
    crc32: () => [], adler32: () => [], __aeabi_uldivmod: () => [],
    png_read_filter_row: (r) => [[r[2] >>> 0, R((r[1] >>> 0) + 4)]],
    inflate_fast: (r) => { const s = r[0] >>> 0, st = R(s + 28); return [[s, 56], [st, 96], [R(s + 12), R(s + 16)]]; },
  };
  const counts = {};
  process.on('exit', () => console.log('FASTCHECK: same result in ' + Object.entries(counts).map(([k, v]) => k + ' ×' + v).join(', ')));
  for (const name of Object.keys(areas)) {
    const addr = lib.sym(name) >>> 0, fast = cpu.hooks.get(addr);
    if (!fast) continue;
    counts[name] = 0;
    cpu.hooks.set(addr, (c) => {
      const r = c.r, regs = r.slice(), sp = r[13] >>> 0, stackArg = R(sp);
      const parts = areas[name](regs), before = parts.map(([a, n]) => c.u8.slice(a, a + n));
      const ok = fast(c);
      if (ok === false) { for (let i = 0; i < 4; i++) r[i] = regs[i]; return false; }
      const fr = r.slice(0, 4), fm = parts.map(([a, n]) => c.u8.slice(a, a + n));
      // run the original on the same input
      parts.forEach(([a], i) => c.u8.set(before[i], a));
      for (let i = 0; i < 16; i++) r[i] = regs[i];
      cpu.hooks.delete(addr);
      const lr = r[14];
      c.call(addr, [regs[0], regs[1], regs[2], regs[3], stackArg]);
      const or = r.slice(0, 4);
      const nRegs = name === '__aeabi_uldivmod' ? 4 : name === 'crc32' || name === 'adler32' ? 1 : 0; // the others return nothing
      for (let i = 0; i < nRegs; i++) if (fr[i] !== or[i]) throw new Error(`FASTCHECK ${name}: r${i} fast ${fr[i] >>> 0} original ${or[i] >>> 0}`);
      parts.forEach(([a, n], i) => {
        const om = c.u8.subarray(a, a + n);
        for (let k = 0; k < n; k++) if (om[k] !== fm[i][k]) throw new Error(`FASTCHECK ${name}: byte ${k} of area ${i} (at ${(a + k).toString(16)}) fast ${fm[i][k]} original ${om[k]}`);
      });
      r[14] = lr; r[13] = sp;
      counts[name]++;
    });
    // c.call above needs the hook removed while the original runs; put this checking hook back afterwards
    const mine = cpu.hooks.get(addr);
    const wrapped = (c) => { const res = mine(c); if (!cpu.hooks.has(addr) || cpu.hooks.get(addr) !== wrapped) cpu.hooks.set(addr, wrapped); return res; };
    cpu.hooks.set(addr, wrapped);
  }
};
