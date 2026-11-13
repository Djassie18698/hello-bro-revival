// An ARMv5TE emulator (ARM + Thumb-1, no FPU: the game's libgame.so is "armeabi" soft-float code) in plain JavaScript, with
// the memory of the emulated phone and "traps": addresses outside memory that call a JavaScript function (the system functions
// the app imports, see sys.js). Runs in Node (tools/dev/emu-boot.js) and in the browser.
//   const cpu = new Cpu(memBytes); cpu.trap(fn) -> address; cpu.call(addr, [args]) -> r0 (runs until the function returns)
'use strict';
(function (root) {
  const TRAP_BASE = 0xf0000000;
  class EmuError extends Error {}

  class Cpu {
    constructor(size) {
      this.size = size;
      this.buf = new ArrayBuffer(size);
      this.u8 = new Uint8Array(this.buf); this.u16 = new Uint16Array(this.buf); this.u32 = new Uint32Array(this.buf); this.i32 = new Int32Array(this.buf);
      this.dv = new DataView(this.buf);
      this.r = new Int32Array(16);
      this.N = 0; this.Z = 0; this.C = 0; this.V = 0; this.T = 0; this.Q = 0;
      this.traps = [null]; this.trapNames = ['<return>']; // trap 0 = "the called function has returned"
      this.steps = 0; this.stop = false; this.budget = Infinity; this.pauseDepth = -1; this.busy = false;
      // address|T -> fn(cpu): replaces an internal function (returns to lr; false = run the original; a number = jump there).
      // hookPages marks the 4 KB pages that hold a hook, so the other instructions skip the lookup (it is in the hottest loop)
      const pages = (this.hookPages = new Uint8Array((size >>> 12) + 1));
      this.hooks = new (class extends Map { set(k, v) { if ((k >>> 12) < pages.length) pages[k >>> 12] = 1; return super.set(k, v); } })();
    }
    // ---- memory (little endian); unaligned access goes byte by byte
    r8(a) { return this.u8[a]; }
    r16(a) { return a & 1 ? this.u8[a] | (this.u8[a + 1] << 8) : this.u16[a >>> 1]; }
    r32(a) { return a & 3 ? (this.u8[a] | (this.u8[a + 1] << 8) | (this.u8[a + 2] << 16) | (this.u8[a + 3] << 24)) : this.i32[a >>> 2]; }
    w8(a, v) { this.u8[a] = v; }
    w16(a, v) { if (a & 1) { this.u8[a] = v; this.u8[a + 1] = v >>> 8; } else this.u16[a >>> 1] = v; }
    w32(a, v) { if (a & 3) { this.u8[a] = v; this.u8[a + 1] = v >>> 8; this.u8[a + 2] = v >>> 16; this.u8[a + 3] = v >>> 24; } else this.i32[a >>> 2] = v; }
    rf32(a) { return this.dv.getFloat32(a, true); } wf32(a, v) { this.dv.setFloat32(a, v, true); }
    rf64(a) { return this.dv.getFloat64(a, true); } wf64(a, v) { this.dv.setFloat64(a, v, true); }
    cstr(a) { if (!a) return ''; let e = a; const u = this.u8; while (u[e]) e++; return Cpu.dec.decode(u.subarray(a, e)); }
    bytes(a, n) { return this.u8.subarray(a, a + n); }
    wstr(a, s) { const b = Cpu.enc.encode(s); this.u8.set(b, a); this.u8[a + b.length] = 0; return b.length; }

    trap(fn, name) { this.traps.push(fn); this.trapNames.push(name || fn.name || '?'); return (TRAP_BASE + (this.traps.length - 1) * 4) >>> 0; }

    // call an emulated function like C would: up to 4 arguments in r0-r3, more on the stack; returns r0
    call(addr, args = []) {
      const r = this.r, save = [r[13], r[14], r[15], this.T, this.depth | 0];
      let sp = r[13] & ~7;
      if (args.length > 4) { sp -= ((args.length - 4) * 4 + 7) & ~7; for (let i = 4; i < args.length; i++) this.w32(sp + (i - 4) * 4, args[i]); }
      for (let i = 0; i < 4 && i < args.length; i++) r[i] = args[i];
      r[13] = sp; r[14] = TRAP_BASE | 0;
      this.T = addr & 1; r[15] = addr & ~1;
      this.depth = (this.depth | 0) + 1;
      const my = this.depth;
      this.returned = 0;
      this.run(my);
      const res = r[0];
      r[13] = save[0]; r[14] = save[1]; r[15] = save[2]; this.T = save[3]; this.depth = save[4];
      return res;
    }

    // the same as call(), but the work is cut into slices of `slice` instructions with a pause in between, so the browser stays
    // alive during long work (the app's start: ~1 billion instructions). Only pauses at the top level (not inside a trap's own
    // calls, not inside another thread), so nothing else may use the processor until it resolves.
    async callAsync(addr, args = [], slice = 3e6, onSlice) {
      const r = this.r, save = [r[13], r[14], r[15], this.T, this.depth | 0];
      let sp = r[13] & ~7;
      if (args.length > 4) { sp -= ((args.length - 4) * 4 + 7) & ~7; for (let i = 4; i < args.length; i++) this.w32(sp + (i - 4) * 4, args[i]); }
      for (let i = 0; i < 4 && i < args.length; i++) r[i] = args[i];
      r[13] = sp; r[14] = TRAP_BASE | 0;
      this.T = addr & 1; r[15] = addr & ~1;
      this.depth = (this.depth | 0) + 1;
      const my = this.depth;
      this.pauseDepth = my; this.busy = true;
      try {
        for (;;) {
          this.budget = this.steps + slice;
          const how = this.run(my);
          if (how !== 'pause') break;
          if (onSlice) onSlice();
          await new Promise((ok) => setTimeout(ok, 0));
        }
      } finally { this.pauseDepth = -1; this.budget = Infinity; this.busy = false; }
      const res = r[0];
      r[13] = save[0]; r[14] = save[1]; r[15] = save[2]; this.T = save[3]; this.depth = save[4];
      return res;
    }

    // run until the call started at `depth` returns (pc reaches trap 0)
    run(depth) {
      const r = this.r;
      for (;;) {
        const pc = r[15] >>> 0;
        if (pc >= TRAP_BASE) {
          if (pc >= 0xffff0000) { // ARM Linux kernel helpers (ARMv5 has no atomic instructions): cmpxchg, get_tls, memory barrier
            if (pc === 0xffff0fc0) { const ptr = r[2] >>> 0; if (this.r32(ptr) === r[0]) { this.w32(ptr, r[1]); r[0] = 0; this.C = 1; } else { r[0] = 1; this.C = 0; } }
            else if (pc === 0xffff0fe0) r[0] = this.tls | 0;
            else if (pc !== 0xffff0fa0) throw new EmuError('kernel helper ' + pc.toString(16));
            const lr = r[14]; this.T = lr & 1; r[15] = lr & ~1; continue;
          }
          const idx = (pc - TRAP_BASE) >>> 2;
          if (idx === 0) { if (this.depth === depth) return 'done'; throw new EmuError('return at the wrong depth'); }
          const fn = this.traps[idx];
          if (!fn) throw new EmuError('bad trap ' + idx);
          const lr = r[14];
          const res = fn(this, r[0], r[1], r[2], r[3]);
          if (this.unwound) { this.unwound = false; continue; } // longjmp / thread switch changed pc itself
          if (res !== undefined) { if (typeof res === 'bigint') { r[0] = Number(BigInt.asIntN(32, res)); r[1] = Number(BigInt.asIntN(32, res >> 32n)); } else r[0] = res; }
          this.T = lr & 1; r[15] = lr & ~1;
          if (this.yielding) { if (this.depth === depth && this.thread) { this.yielding = false; return 'yield'; } this.yielding = false; }
          continue;
        }
        if (pc < this.size && this.hookPages[pc >>> 12]) { const h = this.hooks.get(pc | this.T); if (h) { const lr = r[14], v = h(this); if (v !== false) { if (typeof v === 'number') { this.T = v & 1; r[15] = v & ~1; } else { this.T = lr & 1; r[15] = lr & ~1; } continue; } } } // false: run the original, a number: go on at that address
        if (this.T) this.thumb(pc); else this.arm(pc);
        if (++this.steps >= this.budget && depth === this.pauseDepth && this.depth === depth && !this.thread) return 'pause';
      }
    }

    // ---- other threads of the app, run in turns: a thread runs until it waits (pthread_cond_wait, usleep) or ends
    // th = { regs: Int32Array(16), flags: [N, Z, C, V, T], done }
    newThread(fn, arg, stackTop) {
      const regs = new Int32Array(16);
      regs[0] = arg; regs[13] = stackTop & ~7; regs[14] = TRAP_BASE | 0; regs[15] = fn & ~1;
      return { regs, flags: [0, 0, 0, 0, fn & 1], done: false };
    }
    runThread(th) {
      if (th.done || this.thread) return;
      const r = this.r, saveR = r.slice(), saveF = [this.N, this.Z, this.C, this.V, this.T];
      r.set(th.regs); [this.N, this.Z, this.C, this.V, this.T] = th.flags;
      this.thread = th; this.depth = (this.depth | 0) + 1; this.yielding = false;
      let how;
      try { how = this.run(this.depth); } finally {
        th.regs.set(r); th.flags = [this.N, this.Z, this.C, this.V, this.T];
        this.thread = null; this.depth--;
        r.set(saveR); [this.N, this.Z, this.C, this.V, this.T] = saveF;
      }
      if (how === 'done') th.done = true;
    }
    cond(c) {
      switch (c) {
        case 0: return this.Z; case 1: return !this.Z; case 2: return this.C; case 3: return !this.C;
        case 4: return this.N; case 5: return !this.N; case 6: return this.V; case 7: return !this.V;
        case 8: return this.C && !this.Z; case 9: return !this.C || this.Z;
        case 10: return this.N === this.V; case 11: return this.N !== this.V;
        case 12: return !this.Z && this.N === this.V; case 13: return this.Z || this.N !== this.V;
        default: return true;
      }
    }
    nz(v) { this.N = v < 0 ? 1 : 0; this.Z = v === 0 ? 1 : 0; return v; }
    add(a, b, c) { // a + b + c with flags
      const res = (a + b + c) | 0;
      this.C = ((a >>> 0) + (b >>> 0) + c) > 0xffffffff ? 1 : 0;
      this.V = ((~(a ^ b) & (a ^ res)) >>> 31);
      this.N = res < 0 ? 1 : 0; this.Z = res === 0 ? 1 : 0;
      return res;
    }
    sub(a, b, c) { return this.add(a, ~b, c); } // a - b - !c
    branchTo(addr) { this.T = addr & 1; this.r[15] = addr & ~1; } // BX: bit 0 picks Thumb

    // ------------------------------------------------------------ Thumb-1
    thumb(pc) {
      const r = this.r, op = this.u16[pc >>> 1];
      r[15] = pc + 2;
      switch (op >> 11) {
        case 0: { const rd = op & 7, v = r[(op >> 3) & 7], n = (op >> 6) & 31; if (n) { this.C = (v >>> (32 - n)) & 1; r[rd] = this.nz(v << n); } else r[rd] = this.nz(v); return; }
        case 1: { const rd = op & 7, v = r[(op >> 3) & 7], n = (op >> 6) & 31; if (n) { this.C = (v >>> (n - 1)) & 1; r[rd] = this.nz(v >>> n); } else { this.C = v >>> 31; r[rd] = this.nz(0); } return; }
        case 2: { const rd = op & 7, v = r[(op >> 3) & 7], n = (op >> 6) & 31; if (n) { this.C = (v >> (n - 1)) & 1; r[rd] = this.nz(v >> n); } else { this.C = v >>> 31; r[rd] = this.nz(v >> 31); } return; }
        case 3: { const rd = op & 7, a = r[(op >> 3) & 7], b = op & 0x400 ? (op >> 6) & 7 : r[(op >> 6) & 7]; r[rd] = op & 0x200 ? this.sub(a, b, 1) : this.add(a, b, 0); return; }
        case 4: r[(op >> 8) & 7] = this.nz(op & 255); return;
        case 5: this.sub(r[(op >> 8) & 7], op & 255, 1); return;
        case 6: { const rd = (op >> 8) & 7; r[rd] = this.add(r[rd], op & 255, 0); return; }
        case 7: { const rd = (op >> 8) & 7; r[rd] = this.sub(r[rd], op & 255, 1); return; }
        case 8:
          if (op & 0x400) { // hi register operations / BX
            const rd = (op & 7) | ((op >> 4) & 8), rm = (op >> 3) & 15;
            const vm = rm === 15 ? pc + 4 : r[rm];
            switch ((op >> 8) & 3) {
              case 0: { const v = ((rd === 15 ? pc + 4 : r[rd]) + vm) | 0; if (rd === 15) r[15] = v & ~1; else r[rd] = v; return; }
              case 1: this.sub(rd === 15 ? pc + 4 : r[rd], vm, 1); return;
              case 2: if (rd === 15) r[15] = vm & ~1; else r[rd] = vm; return;
              default: if (op & 0x80) r[14] = (pc + 2) | 1; this.branchTo(vm); return;
            }
          } else {
            const rd = op & 7, b = r[(op >> 3) & 7], a = r[rd];
            switch ((op >> 6) & 15) {
              case 0: r[rd] = this.nz(a & b); return;
              case 1: r[rd] = this.nz(a ^ b); return;
              case 2: { const n = b & 255; if (n === 0) this.nz(a); else if (n < 32) { this.C = (a >>> (32 - n)) & 1; r[rd] = this.nz(a << n); } else { this.C = n === 32 ? a & 1 : 0; r[rd] = this.nz(0); } return; }
              case 3: { const n = b & 255; if (n === 0) this.nz(a); else if (n < 32) { this.C = (a >>> (n - 1)) & 1; r[rd] = this.nz(a >>> n); } else { this.C = n === 32 ? a >>> 31 : 0; r[rd] = this.nz(0); } return; }
              case 4: { const n = b & 255; if (n === 0) this.nz(a); else if (n < 32) { this.C = (a >> (n - 1)) & 1; r[rd] = this.nz(a >> n); } else { this.C = a >>> 31; r[rd] = this.nz(a >> 31); } return; }
              case 5: r[rd] = this.add(a, b, this.C); return;
              case 6: r[rd] = this.sub(a, b, this.C); return;
              case 7: { const n = b & 255; if (n === 0) this.nz(a); else { const k = n & 31; const v = k ? (a >>> k) | (a << (32 - k)) : a; this.C = v >>> 31; r[rd] = this.nz(v); } return; }
              case 8: this.nz(a & b); return;
              case 9: r[rd] = this.sub(0, b, 1); return;
              case 10: this.sub(a, b, 1); return;
              case 11: this.add(a, b, 0); return;
              case 12: r[rd] = this.nz(a | b); return;
              case 13: r[rd] = this.nz(Math.imul(a, b)); return;
              case 14: r[rd] = this.nz(a & ~b); return;
              default: r[rd] = this.nz(~b); return;
            }
          }
        case 9: r[(op >> 8) & 7] = this.i32[(((pc + 4) & ~3) + (op & 255) * 4) >>> 2]; return;
        case 10: case 11: { // load / store with register offset
          const a = (r[(op >> 3) & 7] + r[(op >> 6) & 7]) >>> 0, rd = op & 7;
          switch ((op >> 9) & 7) {
            case 0: this.w32(a, r[rd]); return;
            case 1: this.w16(a, r[rd]); return;
            case 2: this.u8[a] = r[rd]; return;
            case 3: r[rd] = (this.u8[a] << 24) >> 24; return;
            case 4: r[rd] = this.r32(a); return;
            case 5: r[rd] = this.r16(a); return;
            case 6: r[rd] = this.u8[a]; return;
            default: r[rd] = (this.r16(a) << 16) >> 16; return;
          }
        }
        case 12: this.w32((r[(op >> 3) & 7] + ((op >> 6) & 31) * 4) >>> 0, r[op & 7]); return;
        case 13: r[op & 7] = this.r32((r[(op >> 3) & 7] + ((op >> 6) & 31) * 4) >>> 0); return;
        case 14: this.u8[(r[(op >> 3) & 7] + ((op >> 6) & 31)) >>> 0] = r[op & 7]; return;
        case 15: r[op & 7] = this.u8[(r[(op >> 3) & 7] + ((op >> 6) & 31)) >>> 0]; return;
        case 16: this.w16((r[(op >> 3) & 7] + ((op >> 6) & 31) * 2) >>> 0, r[op & 7]); return;
        case 17: r[op & 7] = this.r16((r[(op >> 3) & 7] + ((op >> 6) & 31) * 2) >>> 0); return;
        case 18: this.w32((r[13] + (op & 255) * 4) >>> 0, r[(op >> 8) & 7]); return;
        case 19: r[(op >> 8) & 7] = this.r32((r[13] + (op & 255) * 4) >>> 0); return;
        case 20: r[(op >> 8) & 7] = ((pc + 4) & ~3) + (op & 255) * 4; return;
        case 21: r[(op >> 8) & 7] = r[13] + (op & 255) * 4; return;
        case 22: case 23: {
          if ((op & 0xff00) === 0xb000) { r[13] += op & 0x80 ? -(op & 127) * 4 : (op & 127) * 4; return; }
          if ((op & 0xf600) === 0xb400) { // push / pop
            let list = op & 255;
            if (op & 0x800) { // pop
              let sp = r[13] >>> 0;
              for (let i = 0; i < 8; i++) if (list & (1 << i)) { r[i] = this.r32(sp); sp += 4; }
              if (op & 0x100) { const v = this.r32(sp); sp += 4; r[13] = sp; this.branchTo(v); return; } // v5T: popping pc can switch to ARM
              r[13] = sp; return;
            }
            let n = (op & 0x100 ? 1 : 0); for (let i = 0; i < 8; i++) if (list & (1 << i)) n++;
            let sp = (r[13] - n * 4) >>> 0; r[13] = sp;
            for (let i = 0; i < 8; i++) if (list & (1 << i)) { this.w32(sp, r[i]); sp += 4; }
            if (op & 0x100) this.w32(sp, r[14]);
            return;
          }
          if ((op & 0xff00) === 0xbe00) throw new EmuError('bkpt at ' + pc.toString(16));
          throw new EmuError('thumb: unknown ' + op.toString(16) + ' at ' + pc.toString(16));
        }
        case 24: { let a = r[(op >> 8) & 7] >>> 0; for (let i = 0; i < 8; i++) if (op & (1 << i)) { this.w32(a, r[i]); a += 4; } r[(op >> 8) & 7] = a; return; }
        case 25: { const rn = (op >> 8) & 7; let a = r[rn] >>> 0; for (let i = 0; i < 8; i++) if (op & (1 << i)) { r[i] = this.r32(a); a += 4; } if (!(op & (1 << rn))) r[rn] = a; return; }
        case 26: case 27: {
          const c = (op >> 8) & 15;
          if (c === 15) throw new EmuError('swi in thumb at ' + pc.toString(16));
          if (this.cond(c)) r[15] = pc + 4 + (((op & 255) << 24) >> 23);
          return;
        }
        case 28: r[15] = pc + 4 + (((op & 0x7ff) << 21) >> 20); return;
        case 29: { const t = (r[14] + ((op & 0x7ff) << 1)) & ~3; r[14] = (pc + 2) | 1; this.T = 0; r[15] = t; return; } // BLX: to ARM code
        case 30: r[14] = pc + 4 + (((op & 0x7ff) << 21) >> 9); return;
        default: { const t = r[14] + ((op & 0x7ff) << 1); r[14] = (pc + 2) | 1; r[15] = t & ~1; return; }
      }
    }

    // ------------------------------------------------------------ ARM (v5TE)
    // the shifter operand of a data-processing instruction; sets this.sc = the carry it produces
    shifted(op, pc) {
      const r = this.r, rm = op & 15, v = rm === 15 ? pc + 8 : r[rm], type = (op >> 5) & 3;
      let n;
      if (op & 0x10) { n = r[(op >> 8) & 15] & 255; if (n === 0) { this.sc = this.C; return v; } }
      else {
        n = (op >> 7) & 31;
        if (n === 0) {
          switch (type) {
            case 0: this.sc = this.C; return v;
            case 1: this.sc = v >>> 31; return 0;
            case 2: this.sc = v >>> 31; return v >> 31;
            default: this.sc = v & 1; return (v >>> 1) | (this.C << 31); // RRX
          }
        }
      }
      switch (type) {
        case 0: if (n < 32) { this.sc = (v >>> (32 - n)) & 1; return v << n; } this.sc = n === 32 ? v & 1 : 0; return 0;
        case 1: if (n < 32) { this.sc = (v >>> (n - 1)) & 1; return v >>> n; } this.sc = n === 32 ? v >>> 31 : 0; return 0;
        case 2: if (n < 32) { this.sc = (v >> (n - 1)) & 1; return v >> n; } this.sc = v >>> 31; return v >> 31;
        default: { const k = n & 31; const x = k ? (v >>> k) | (v << (32 - k)) : v; this.sc = x >>> 31; return x; }
      }
    }
    arm(pc) {
      const r = this.r, op = this.i32[pc >>> 2];
      r[15] = pc + 4;
      const c = op >>> 28;
      if (c !== 14) {
        if (c === 15) { // unconditional space: BLX imm, PLD
          if ((op & 0x0e000000) === 0x0a000000) { r[14] = pc + 4; this.T = 1; r[15] = pc + 8 + ((op << 8) >> 6) + ((op >> 23) & 2); return; }
          if ((op & 0x0d70f000) === 0x0550f000) return; // PLD
          throw new EmuError('arm: unknown ' + (op >>> 0).toString(16) + ' at ' + pc.toString(16));
        }
        if (!this.cond(c)) return;
      }
      switch ((op >> 25) & 7) {
        case 0:
          if ((op & 0x90) === 0x90) { // multiplies and extra load/stores
            if ((op & 0x60) === 0) {
              if ((op & 0x0fc00000) === 0) { // MUL / MLA
                const rd = (op >> 16) & 15; let v = Math.imul(r[op & 15], r[(op >> 8) & 15]);
                if (op & 0x200000) v = (v + r[(op >> 12) & 15]) | 0;
                r[rd] = v; if (op & 0x100000) this.nz(v); return;
              }
              if ((op & 0x0f800000) === 0x00800000) { // UMULL UMLAL SMULL SMLAL
                const lo = (op >> 12) & 15, hi = (op >> 16) & 15;
                let a = BigInt(r[op & 15]), b = BigInt(r[(op >> 8) & 15]);
                if (!(op & 0x400000)) { a = BigInt.asUintN(32, a); b = BigInt.asUintN(32, b); }
                let v = a * b;
                if (op & 0x200000) v += (BigInt.asUintN(32, BigInt(r[hi])) << 32n) | BigInt.asUintN(32, BigInt(r[lo]));
                r[lo] = Number(BigInt.asIntN(32, v)); r[hi] = Number(BigInt.asIntN(32, v >> 32n));
                if (op & 0x100000) { this.N = r[hi] < 0 ? 1 : 0; this.Z = r[lo] === 0 && r[hi] === 0 ? 1 : 0; }
                return;
              }
              if ((op & 0x0fb00000) === 0x01000000) { // SWP / SWPB
                const a = r[(op >> 16) & 15] >>> 0, rd = (op >> 12) & 15, v = r[op & 15];
                if (op & 0x400000) { const t = this.u8[a]; this.u8[a] = v; r[rd] = t; } else { const t = this.r32(a); this.w32(a, v); r[rd] = t; }
                return;
              }
            }
            // LDRH STRH LDRSB LDRSH LDRD STRD
            const rn = (op >> 16) & 15, rd = (op >> 12) & 15, P = op & 0x1000000, U = op & 0x800000, W = op & 0x200000, L = op & 0x100000;
            const off = op & 0x400000 ? ((op >> 4) & 0xf0) | (op & 15) : r[op & 15];
            const base = rn === 15 ? pc + 8 : r[rn];
            const a2 = U ? base + off : base - off, a = (P ? a2 : base) >>> 0;
            const sh = (op >> 5) & 3;
            if (L) { const v = sh === 1 ? this.r16(a) : sh === 2 ? (this.u8[a] << 24) >> 24 : (this.r16(a) << 16) >> 16; if (!P || W) r[rn] = a2; r[rd] = v; }
            else if (sh === 1) { this.w16(a, r[rd]); if (!P || W) r[rn] = a2; }
            else if (sh === 2) { const v0 = this.r32(a), v1 = this.r32(a + 4); if (!P || W) r[rn] = a2; r[rd] = v0; r[rd + 1] = v1; } // LDRD
            else { this.w32(a, r[rd]); this.w32(a + 4, r[rd + 1]); if (!P || W) r[rn] = a2; } // STRD
            return;
          }
          if ((op & 0x01900000) === 0x01000000) { // misc: BX BLX CLZ MRS MSR, saturating and 16-bit multiplies
            if ((op & 0x0ffffff0) === 0x012fff10) { this.branchTo(r[op & 15]); return; }
            if ((op & 0x0ffffff0) === 0x012fff30) { const t = r[op & 15]; r[14] = pc + 4; this.branchTo(t); return; }
            if ((op & 0x0fff0ff0) === 0x016f0f10) { r[(op >> 12) & 15] = Math.clz32(r[op & 15]); return; }
            if ((op & 0x0fbf0fff) === 0x010f0000) { r[(op >> 12) & 15] = (this.N << 31) | (this.Z << 30) | (this.C << 29) | (this.V << 28) | (this.Q << 27) | 0x10; return; }
            if ((op & 0x0fb0fff0) === 0x0120f000) { const v = r[op & 15]; if (op & 0x80000) { this.N = v >>> 31; this.Z = (v >>> 30) & 1; this.C = (v >>> 29) & 1; this.V = (v >>> 28) & 1; this.Q = (v >>> 27) & 1; } return; }
            if ((op & 0x0f900090) === 0x01000080) { // SMLAxy SMULxy SMULWy SMLAWy SMLALxy
              const rm = r[op & 15], rs = r[(op >> 8) & 15], x = op & 0x20 ? rm >> 16 : (rm << 16) >> 16, y = op & 0x40 ? rs >> 16 : (rs << 16) >> 16;
              const rd = (op >> 16) & 15, rn = (op >> 12) & 15;
              switch ((op >> 21) & 3) {
                case 0: { const v = Math.imul(x, y), s = (v + r[rn]) | 0; if (((~(v ^ r[rn])) & (v ^ s)) < 0) this.Q = 1; r[rd] = s; return; }
                case 1: { const v = Number((BigInt(rm) * BigInt(y)) >> 16n) | 0; if (op & 0x20) { r[rd] = v; } else { const s = (v + r[rn]) | 0; if (((~(v ^ r[rn])) & (v ^ s)) < 0) this.Q = 1; r[rd] = s; } return; }
                case 2: { let v = BigInt(Math.imul(x, y)) + ((BigInt(r[rd]) << 32n) | BigInt.asUintN(32, BigInt(r[rn]))); r[rn] = Number(BigInt.asIntN(32, v)); r[rd] = Number(BigInt.asIntN(32, v >> 32n)); return; }
                default: r[rd] = Math.imul(x, y); return;
              }
            }
            if ((op & 0x0f900ff0) === 0x01000050) { // QADD QSUB QDADD QDSUB
              const sat = (v) => { if (v > 2147483647) { this.Q = 1; return 2147483647; } if (v < -2147483648) { this.Q = 1; return -2147483648; } return v; };
              let b = r[(op >> 16) & 15]; const a = r[op & 15];
              if (op & 0x400000) b = sat(b * 2);
              r[(op >> 12) & 15] = sat(op & 0x200000 ? a - b : a + b); return;
            }
            throw new EmuError('arm: unknown misc ' + (op >>> 0).toString(16) + ' at ' + pc.toString(16));
          }
        // falls through: data processing with a register operand
        case 1: {
          let b;
          if (op & 0x2000000) {
            if ((op & 0x01900000) === 0x01000000) { // MSR with an immediate (flags)
              if ((op & 0x0fb0f000) === 0x0320f000) { const rot = ((op >> 8) & 15) * 2, im = op & 255, v = rot ? (im >>> rot) | (im << (32 - rot)) : im; if (op & 0x80000) { this.N = v >>> 31; this.Z = (v >>> 30) & 1; this.C = (v >>> 29) & 1; this.V = (v >>> 28) & 1; } return; }
              throw new EmuError('arm: unknown ' + (op >>> 0).toString(16) + ' at ' + pc.toString(16));
            }
            const rot = ((op >> 8) & 15) * 2, im = op & 255;
            if (rot) { b = (im >>> rot) | (im << (32 - rot)); this.sc = b >>> 31; } else { b = im; this.sc = this.C; }
          } else b = this.shifted(op, pc);
          const rn = (op >> 16) & 15, rd = (op >> 12) & 15, S = op & 0x100000;
          const a = rn === 15 ? pc + 8 : r[rn];
          let v;
          switch ((op >> 21) & 15) {
            case 0: v = a & b; if (S) { this.nz(v); this.C = this.sc; } break;
            case 1: v = a ^ b; if (S) { this.nz(v); this.C = this.sc; } break;
            case 2: v = S ? this.sub(a, b, 1) : (a - b) | 0; break;
            case 3: v = S ? this.sub(b, a, 1) : (b - a) | 0; break;
            case 4: v = S ? this.add(a, b, 0) : (a + b) | 0; break;
            case 5: v = S ? this.add(a, b, this.C) : (a + b + this.C) | 0; break;
            case 6: v = S ? this.sub(a, b, this.C) : (a - b - 1 + this.C) | 0; break;
            case 7: v = S ? this.sub(b, a, this.C) : (b - a - 1 + this.C) | 0; break;
            case 8: this.nz(a & b); this.C = this.sc; return;
            case 9: this.nz(a ^ b); this.C = this.sc; return;
            case 10: this.sub(a, b, 1); return;
            case 11: this.add(a, b, 0); return;
            case 12: v = a | b; if (S) { this.nz(v); this.C = this.sc; } break;
            case 13: v = b; if (S) { this.nz(v); this.C = this.sc; } break;
            case 14: v = a & ~b; if (S) { this.nz(v); this.C = this.sc; } break;
            default: v = ~b; if (S) { this.nz(v); this.C = this.sc; } break;
          }
          if (rd === 15) this.branchTo(v); else r[rd] = v; // v5T: writing pc can switch to Thumb
          return;
        }
        case 2: case 3: { // LDR STR LDRB STRB
          const rn = (op >> 16) & 15, rd = (op >> 12) & 15, P = op & 0x1000000, U = op & 0x800000, B = op & 0x400000, W = op & 0x200000, L = op & 0x100000;
          let off;
          if (op & 0x2000000) { const sv = this.sc; off = this.shifted(op & ~0x10, pc); this.sc = sv; } else off = op & 0xfff;
          const base = rn === 15 ? pc + 8 : r[rn];
          const a2 = U ? base + off : base - off, a = (P ? a2 : base) >>> 0;
          if (L) {
            const v = B ? this.u8[a] : this.r32(a);
            if (!P || W) r[rn] = a2;
            if (rd === 15) this.branchTo(v); else r[rd] = v;
          } else {
            const v = rd === 15 ? pc + 12 : r[rd];
            if (B) this.u8[a] = v; else this.w32(a, v);
            if (!P || W) r[rn] = a2;
          }
          return;
        }
        case 4: { // LDM STM
          const rn = (op >> 16) & 15, P = op & 0x1000000, U = op & 0x800000, W = op & 0x200000, L = op & 0x100000;
          let n = 0; for (let i = 0; i < 16; i++) if (op & (1 << i)) n++;
          const base = r[rn];
          let a = (U ? (P ? base + 4 : base) : (P ? base - n * 4 : base - n * 4 + 4)) >>> 0;
          const end = U ? base + n * 4 : base - n * 4;
          if (L) {
            if (W) r[rn] = end;
            for (let i = 0; i < 15; i++) if (op & (1 << i)) { r[i] = this.r32(a); a += 4; }
            if (op & 0x8000) this.branchTo(this.r32(a));
          } else {
            for (let i = 0; i < 16; i++) if (op & (1 << i)) { this.w32(a, i === 15 ? pc + 12 : r[i]); a += 4; }
            if (W) r[rn] = end;
          }
          return;
        }
        case 5: { // B BL
          if (op & 0x1000000) r[14] = pc + 4;
          r[15] = pc + 8 + ((op << 8) >> 6);
          return;
        }
        default:
          if ((op & 0x0f000000) === 0x0f000000) throw new EmuError('swi ' + (op & 0xffffff).toString(16) + ' at ' + pc.toString(16));
          throw new EmuError('arm: coprocessor ' + (op >>> 0).toString(16) + ' at ' + pc.toString(16));
      }
    }
  }
  Cpu.enc = new TextEncoder(); Cpu.dec = new TextDecoder('utf-8');
  Cpu.TRAP_BASE = TRAP_BASE; Cpu.EmuError = EmuError;
  if (typeof module !== 'undefined' && module.exports) module.exports = Cpu; else root.EmuCpu = Cpu;
})(typeof window !== 'undefined' ? window : globalThis);
