// Loads an ARM ELF shared library (libgame.so) into the emulator's memory, like Android's linker: copies the segments, fills
// in the addresses (relocations), points every imported function at a trap (sys.js) and lists the start-up functions.
//   const lib = loadElf(cpu, bytes, base, resolve)   resolve(name, isFunction) -> address of an import
//   lib.sym(name) -> address of an exported function (Thumb functions keep bit 0), lib.init -> [addresses of constructors]
'use strict';
(function (root) {
  function loadElf(cpu, file, base, resolve) {
    const dv = new DataView(file.buffer, file.byteOffset, file.byteLength);
    const u16 = (o) => dv.getUint16(o, true), u32 = (o) => dv.getUint32(o, true);
    if (u32(0) !== 0x464c457f || u16(18) !== 40) throw new Error('not an ARM ELF file');
    const phoff = u32(28), phnum = u16(44), phentsize = u16(42);
    let dyn = 0, end = 0, exidx = [0, 0];
    for (let i = 0; i < phnum; i++) {
      const p = phoff + i * phentsize, type = u32(p), off = u32(p + 4), vaddr = u32(p + 8), filesz = u32(p + 16), memsz = u32(p + 20);
      if (type === 1) { cpu.u8.set(file.subarray(off, off + filesz), base + vaddr); end = Math.max(end, vaddr + memsz); }
      else if (type === 2) dyn = vaddr;
      else if (type === 0x70000001) exidx = [base + vaddr, memsz >>> 3];
    }
    const m32 = (a) => cpu.r32(base + a) >>> 0;
    const d = {};
    for (let p = dyn; ; p += 8) { const tag = m32(p); if (tag === 0) break; d[tag] = m32(p + 4); }
    const symtab = d[6], strtab = d[5], rel = d[17], relsz = d[18] || 0, jmprel = d[23], pltrelsz = d[2] || 0, hash = d[4];
    const nsyms = hash !== undefined ? m32(hash + 4) : 0;
    const name = (o) => cpu.cstr(base + strtab + o);
    const exportsMap = new Map(), symAddr = new Array(nsyms);
    for (let i = 0; i < nsyms; i++) {
      const s = symtab + i * 16, nm = name(m32(s)), value = m32(s + 4), info = cpu.u8[base + s + 12], shndx = cpu.r16(base + s + 14);
      if (shndx !== 0) { symAddr[i] = base + value; if (nm) exportsMap.set(nm, base + value); }
      else if (nm) symAddr[i] = resolve(nm, (info & 15) === 2) >>> 0;
      else symAddr[i] = 0;
    }
    const apply = (table, size) => {
      for (let p = table; p < table + size; p += 8) {
        const where = base + m32(p), info = m32(p + 4), type = info & 255, sym = info >>> 8;
        switch (type) {
          case 23: cpu.w32(where, cpu.r32(where) + base); break; // R_ARM_RELATIVE
          case 21: case 22: cpu.w32(where, symAddr[sym]); break; // GLOB_DAT, JUMP_SLOT
          case 2: cpu.w32(where, cpu.r32(where) + symAddr[sym]); break; // ABS32
          default: throw new Error('relocation type ' + type);
        }
      }
    };
    if (rel) apply(rel, relsz);
    if (jmprel) apply(jmprel, pltrelsz);
    const init = [];
    if (d[25]) for (let i = 0; i < (d[27] || 0); i += 4) { const f = m32(d[25] + i); if (f && f !== 0xffffffff) init.push(f); } // DT_INIT_ARRAY (already relocated)
    return { base, end: base + end, exidx, init, sym: (n) => exportsMap.get(n), exports: exportsMap };
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = loadElf; else root.EmuLoadElf = loadElf;
})(typeof window !== 'undefined' ? window : globalThis);
