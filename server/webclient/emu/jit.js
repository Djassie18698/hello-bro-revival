// Turns the app's machine code into JavaScript, a block at a time (a "JIT"): a stretch of instructions that has run often
// (cpu.jitHot times) becomes one JavaScript function with the instruction decoding already done, so the browser runs it
// directly instead of cpu.thumb()/cpu.arm() taking every instruction apart again. Exactly the same results as cpu.js:
// every instruction is written out like its cpu.js code, and anything rare simply calls cpu.thumb()/cpu.arm() for that
// one instruction. A block ends at a jump that always happens, before a hooked address, or after 120 instructions; a jump
// that may happen leaves the block early. The function returns how many instructions it ran (cpu.steps stays exact).
//   attachJit(Cpu); cpu.enableJit(codeStart, codeEnd)
'use strict';
(function (root) {
  const COND = ['c.Z', '!c.Z', 'c.C', '!c.C', 'c.N', '!c.N', 'c.V', '!c.V', '(c.C&&!c.Z)', '(!c.C||c.Z)', '(c.N===c.V)', '(c.N!==c.V)', '(!c.Z&&c.N===c.V)', '(c.Z||c.N!==c.V)', 'true'];
  const NZ = (v) => `c.N=${v}>>>31;c.Z=${v}===0?1:0;`;
  const R32 = (a) => `(${a}&3?c.r32(${a}):i32[${a}>>>2])`;
  const W32 = (a, v) => `if(${a}&3)c.w32(${a},${v});else i32[${a}>>>2]=${v};`;
  const K = (x) => `(${x | 0})`;
  const FLAG = { N: 1, Z: 2, C: 4, V: 8 };
  const MAX_BLOCKS = 20000; // each block costs ~4 KB of browser memory; past this all are thrown away and made again
  const jump = (v, k) => `c.T=${v}&1;r[15]=${v}&~1;return ${k};`;
  // c.add(a, b, carry) / c.sub(...) in the generated code -> the same arithmetic written out (a call costs a lot when the
  // browser has no compiler of its own, like an iPhone in Lockdown Mode)
  const ARG = '([^,()]+|\\([^()]*\\))';
  const ARITH_RE = new RegExp('(r\\[\\d+\\]=|const v=)?c\\.(add|sub)\\(' + ARG + ',' + ARG + ',' + ARG + '\\);', 'g');
  const inlineArith = (src) => src.replace(ARITH_RE, (m, dst, fn, a, b, ci) => {
    const body = `const x=${a},y=${fn === 'sub' ? `~${b}` : b},ci=${ci},v=(x+y+ci)|0;c.C=((x>>>0)+(y>>>0)+ci)>4294967295?1:0;c.V=(~(x^y)&(x^v))>>>31;c.N=v>>>31;c.Z=v===0?1:0;`;
    if (dst === 'const v=') return body;
    return '{' + body + (dst ? dst + 'v;' : '') + '}';
  });

  // ---------------------------------------------------------------- Thumb
  function thumb(op, pc, k) {
    const fb = { s: `c.thumb(${pc});if(r[15]!==${pc + 2}||!c.T)return ${k};`, end: false };
    switch (op >> 11) {
      case 0: { const rd = op & 7, rm = (op >> 3) & 7, n = (op >> 6) & 31; return { s: n ? `{let v=r[${rm}];c.C=(v>>>${32 - n})&1;v=v<<${n};r[${rd}]=v;${NZ('v')}}` : `{const v=r[${rm}];r[${rd}]=v;${NZ('v')}}` }; }
      case 1: { const rd = op & 7, rm = (op >> 3) & 7, n = (op >> 6) & 31; return { s: n ? `{let v=r[${rm}];c.C=(v>>>${n - 1})&1;v=(v>>>${n})|0;r[${rd}]=v;${NZ('v')}}` : `{c.C=r[${rm}]>>>31;r[${rd}]=0;c.N=0;c.Z=1;}` }; }
      case 2: { const rd = op & 7, rm = (op >> 3) & 7, n = (op >> 6) & 31; return { s: n ? `{let v=r[${rm}];c.C=(v>>${n - 1})&1;v=v>>${n};r[${rd}]=v;${NZ('v')}}` : `{let v=r[${rm}];c.C=v>>>31;v=v>>31;r[${rd}]=v;${NZ('v')}}` }; }
      case 3: { const rd = op & 7, a = `r[${(op >> 3) & 7}]`, b = op & 0x400 ? String((op >> 6) & 7) : `r[${(op >> 6) & 7}]`; return { s: `r[${rd}]=${op & 0x200 ? `c.sub(${a},${b},1)` : `c.add(${a},${b},0)`};` }; }
      case 4: { const v = op & 255; return { s: `r[${(op >> 8) & 7}]=${v};c.N=0;c.Z=${v === 0 ? 1 : 0};` }; }
      case 5: return { s: `c.sub(r[${(op >> 8) & 7}],${op & 255},1);` };
      case 6: { const rd = (op >> 8) & 7; return { s: `r[${rd}]=c.add(r[${rd}],${op & 255},0);` }; }
      case 7: { const rd = (op >> 8) & 7; return { s: `r[${rd}]=c.sub(r[${rd}],${op & 255},1);` }; }
      case 8:
        if (op & 0x400) {
          const rd = (op & 7) | ((op >> 4) & 8), rm = (op >> 3) & 15;
          const vm = rm === 15 ? K(pc + 4) : `r[${rm}]`, vd = rd === 15 ? K(pc + 4) : `r[${rd}]`;
          switch ((op >> 8) & 3) {
            case 0: return rd === 15 ? { s: `{const v=(${vd}+${vm})|0;r[15]=v&~1;return ${k};}`, end: true } : { s: `r[${rd}]=(${vd}+${vm})|0;` };
            case 1: return { s: `c.sub(${vd},${vm},1);` };
            case 2: return rd === 15 ? { s: `r[15]=${vm}&~1;return ${k};`, end: true } : { s: `r[${rd}]=${vm};` };
            default: return { s: `{const t=${vm};${op & 0x80 ? `r[14]=${(pc + 2) | 1};` : ''}${jump('t', k)}}`, end: true };
          }
        } else {
          const rd = op & 7, a = `r[${rd}]`, b = `r[${(op >> 3) & 7}]`;
          switch ((op >> 6) & 15) {
            case 0: return { s: `{const v=${a}&${b};r[${rd}]=v;${NZ('v')}}` };
            case 1: return { s: `{const v=${a}^${b};r[${rd}]=v;${NZ('v')}}` };
            case 5: return { s: `r[${rd}]=c.add(${a},${b},c.C);` };
            case 6: return { s: `r[${rd}]=c.sub(${a},${b},c.C);` };
            case 8: return { s: `{const v=${a}&${b};${NZ('v')}}` };
            case 9: return { s: `r[${rd}]=c.sub(0,${b},1);` };
            case 10: return { s: `c.sub(${a},${b},1);` };
            case 11: return { s: `c.add(${a},${b},0);` };
            case 12: return { s: `{const v=${a}|${b};r[${rd}]=v;${NZ('v')}}` };
            case 13: return { s: `{const v=Math.imul(${a},${b});r[${rd}]=v;${NZ('v')}}` };
            case 14: return { s: `{const v=${a}&~${b};r[${rd}]=v;${NZ('v')}}` };
            case 15: return { s: `{const v=~${b};r[${rd}]=v;${NZ('v')}}` };
            default: return fb; // shifts and rotates by a register
          }
        }
      case 9: return { s: `r[${(op >> 8) & 7}]=i32[${((((pc + 4) & ~3) + (op & 255) * 4) >>> 2)}];` };
      case 10: case 11: {
        const rd = op & 7, pre = `{const a=(r[${(op >> 3) & 7}]+r[${(op >> 6) & 7}])>>>0;`;
        switch ((op >> 9) & 7) {
          case 0: return { s: pre + W32('a', `r[${rd}]`) + '}' };
          case 1: return { s: pre + `c.w16(a,r[${rd}]);}` };
          case 2: return { s: pre + `u8[a]=r[${rd}];}` };
          case 3: return { s: pre + `r[${rd}]=(u8[a]<<24)>>24;}` };
          case 4: return { s: pre + `r[${rd}]=${R32('a')};}` };
          case 5: return { s: pre + `r[${rd}]=c.r16(a);}` };
          case 6: return { s: pre + `r[${rd}]=u8[a];}` };
          default: return { s: pre + `r[${rd}]=(c.r16(a)<<16)>>16;}` };
        }
      }
      case 12: return { s: `{const a=(r[${(op >> 3) & 7}]+${((op >> 6) & 31) * 4})>>>0;${W32('a', `r[${op & 7}]`)}}` };
      case 13: return { s: `{const a=(r[${(op >> 3) & 7}]+${((op >> 6) & 31) * 4})>>>0;r[${op & 7}]=${R32('a')};}` };
      case 14: return { s: `u8[(r[${(op >> 3) & 7}]+${(op >> 6) & 31})>>>0]=r[${op & 7}];` };
      case 15: return { s: `r[${op & 7}]=u8[(r[${(op >> 3) & 7}]+${(op >> 6) & 31})>>>0];` };
      case 16: return { s: `c.w16((r[${(op >> 3) & 7}]+${((op >> 6) & 31) * 2})>>>0,r[${op & 7}]);` };
      case 17: return { s: `r[${op & 7}]=c.r16((r[${(op >> 3) & 7}]+${((op >> 6) & 31) * 2})>>>0);` };
      case 18: return { s: `{const a=(r[13]+${(op & 255) * 4})>>>0;${W32('a', `r[${(op >> 8) & 7}]`)}}` };
      case 19: return { s: `{const a=(r[13]+${(op & 255) * 4})>>>0;r[${(op >> 8) & 7}]=${R32('a')};}` };
      case 20: return { s: `r[${(op >> 8) & 7}]=${K(((pc + 4) & ~3) + (op & 255) * 4)};` };
      case 21: return { s: `r[${(op >> 8) & 7}]=r[13]+${(op & 255) * 4};` };
      case 22: case 23: {
        if ((op & 0xff00) === 0xb000) return { s: `r[13]+=${op & 0x80 ? -(op & 127) * 4 : (op & 127) * 4};` };
        if ((op & 0xf600) === 0xb400) {
          const list = op & 255;
          let s = '{';
          if (op & 0x800) { // pop
            s += 'let sp=r[13]>>>0;';
            for (let i = 0; i < 8; i++) if (list & (1 << i)) s += `r[${i}]=${R32('sp')};sp+=4;`;
            if (op & 0x100) return { s: s + `const v=${R32('sp')};sp+=4;r[13]=sp;${jump('v', k)}}`, end: true };
            return { s: s + 'r[13]=sp;}' };
          }
          let n = op & 0x100 ? 1 : 0; for (let i = 0; i < 8; i++) if (list & (1 << i)) n++;
          s += `let sp=(r[13]-${n * 4})>>>0;r[13]=sp;`;
          for (let i = 0; i < 8; i++) if (list & (1 << i)) s += W32('sp', `r[${i}]`) + 'sp+=4;';
          if (op & 0x100) s += W32('sp', 'r[14]');
          return { s: s + '}' };
        }
        return fb;
      }
      case 24: { const rn = (op >> 8) & 7; let s = `{let a=r[${rn}]>>>0;`; for (let i = 0; i < 8; i++) if (op & (1 << i)) s += W32('a', `r[${i}]`) + 'a+=4;'; return { s: s + `r[${rn}]=a;}` }; }
      case 25: { const rn = (op >> 8) & 7; let s = `{let a=r[${rn}]>>>0;`; for (let i = 0; i < 8; i++) if (op & (1 << i)) s += `r[${i}]=${R32('a')};a+=4;`; return { s: s + (op & (1 << rn) ? '}' : `r[${rn}]=a;}`) }; }
      case 26: case 27: {
        const cd = (op >> 8) & 15;
        if (cd >= 14) return fb;
        return { s: `if(${COND[cd]}){r[15]=${K(pc + 4 + (((op & 255) << 24) >> 23))};return ${k};}` };
      }
      case 28: return { s: `r[15]=${K(pc + 4 + (((op & 0x7ff) << 21) >> 20))};return ${k};`, end: true };
      case 29: return { s: `{const t=(r[14]+${(op & 0x7ff) << 1})&~3;r[14]=${(pc + 2) | 1};c.T=0;r[15]=t;return ${k};}`, end: true };
      case 30: return { s: `r[14]=${K(pc + 4 + (((op & 0x7ff) << 21) >> 9))};` };
      default: return { s: `{const t=r[14]+${(op & 0x7ff) << 1};r[14]=${(pc + 2) | 1};r[15]=t&~1;return ${k};}`, end: true };
    }
  }

  // ---------------------------------------------------------------- ARM
  // the shifter operand: sets locals b (and sc, the carry, when wanted)
  function shift(op, pc, wantC) {
    if (op & 0x10) return `b=c.shifted(${op},${pc});sc=c.sc;`;
    const rm = op & 15, v = rm === 15 ? K(pc + 8) : `r[${rm}]`, type = (op >> 5) & 3, n = (op >> 7) & 31;
    const C = (x) => (wantC ? `sc=${x};` : '');
    if (n === 0) {
      switch (type) {
        case 0: return `b=${v};` + C('c.C');
        case 1: return C(`${v}>>>31`) + 'b=0;';
        case 2: return `{const x=${v};${C('x>>>31')}b=x>>31;}`;
        default: return `{const x=${v};${C('x&1')}b=(x>>>1)|(c.C<<31);}`;
      }
    }
    switch (type) {
      case 0: return `{const x=${v};${C(`(x>>>${32 - n})&1`)}b=x<<${n};}`;
      case 1: return `{const x=${v};${C(`(x>>>${n - 1})&1`)}b=(x>>>${n})|0;}`;
      case 2: return `{const x=${v};${C(`(x>>${n - 1})&1`)}b=x>>${n};}`;
      default: return `{const x=${v};b=(x>>>${n})|(x<<${32 - n});${C('b>>>31')}}`;
    }
  }
  function arm(op, pc, k) {
    const fb = { s: `c.arm(${pc});if(r[15]!==${pc + 4}||c.T)return ${k};`, end: false };
    const cd = op >>> 28;
    if (cd === 15) {
      if ((op & 0x0e000000) === 0x0a000000) return { s: `r[14]=${pc + 4};c.T=1;r[15]=${K(pc + 8 + ((op << 8) >> 6) + ((op >> 23) & 2))};return ${k};`, end: true };
      if ((op & 0x0d70f000) === 0x0550f000) return { s: '' }; // PLD
      return fb;
    }
    let body = null, branches = false;
    switch ((op >> 25) & 7) {
      case 0:
        if ((op & 0x90) === 0x90) {
          if ((op & 0x60) === 0) {
            if ((op & 0x0fc00000) === 0) { const rd = (op >> 16) & 15; body = `{let v=Math.imul(r[${op & 15}],r[${(op >> 8) & 15}]);${op & 0x200000 ? `v=(v+r[${(op >> 12) & 15}])|0;` : ''}r[${rd}]=v;${op & 0x100000 ? NZ('v') : ''}}`; if (rd === 15) return fb; break; }
            return fb;
          }
          const rn = (op >> 16) & 15, rd = (op >> 12) & 15, P = op & 0x1000000, U = op & 0x800000, W = op & 0x200000, L = op & 0x100000, sh = (op >> 5) & 3;
          if (rd >= 14 || rn === 15 && (W || !P)) return fb;
          const off = op & 0x400000 ? String(((op >> 4) & 0xf0) | (op & 15)) : `r[${op & 15}]`;
          let s = `{const base=${rn === 15 ? K(pc + 8) : `r[${rn}]`},a2=base${U ? '+' : '-'}${off},a=(${P ? 'a2' : 'base'})>>>0;`;
          const wb = !P || W ? `r[${rn}]=a2;` : '';
          if (L) s += `const v=${sh === 1 ? 'c.r16(a)' : sh === 2 ? '(u8[a]<<24)>>24' : '(c.r16(a)<<16)>>16'};${wb}r[${rd}]=v;}`;
          else if (sh === 1) s += `c.w16(a,r[${rd}]);${wb}}`;
          else if (sh === 2) s += `const v0=${R32('a')},a4=a+4,v1=${R32('a4')};${wb}r[${rd}]=v0;r[${rd + 1}]=v1;}`;
          else s += `${W32('a', `r[${rd}]`)}const a4=a+4;${W32('a4', `r[${rd + 1}]`)}${wb}}`;
          body = s; break;
        }
        if ((op & 0x01900000) === 0x01000000) {
          if ((op & 0x0ffffff0) === 0x012fff10) { body = `{const t=r[${op & 15}];${jump('t', k)}}`; branches = true; break; }
          if ((op & 0x0ffffff0) === 0x012fff30) { body = `{const t=r[${op & 15}];r[14]=${pc + 4};${jump('t', k)}}`; branches = true; break; }
          return fb;
        }
      // falls through
      case 1: {
        let pre;
        const S = op & 0x100000, opc = (op >> 21) & 15, logical = [0, 1, 8, 9, 12, 13, 14, 15].includes(opc);
        if (op & 0x2000000) {
          if ((op & 0x01900000) === 0x01000000) return fb; // MSR
          const rot = ((op >> 8) & 15) * 2, im = op & 255, b = rot ? ((im >>> rot) | (im << (32 - rot))) | 0 : im;
          pre = `const b=${K(b)},sc=${rot ? b >>> 31 : 'c.C'};`;
        } else pre = 'let b,sc;' + shift(op, pc, S && logical);
        const rn = (op >> 16) & 15, rd = (op >> 12) & 15, a = rn === 15 ? K(pc + 8) : `r[${rn}]`;
        const lz = S ? 'c.C=sc;' : '';
        let v;
        switch (opc) {
          case 0: v = `const v=${a}&b;` + (S ? NZ('v') + lz : ''); break;
          case 1: v = `const v=${a}^b;` + (S ? NZ('v') + lz : ''); break;
          case 2: v = `const v=${S ? `c.sub(${a},b,1)` : `(${a}-b)|0`};`; break;
          case 3: v = `const v=${S ? `c.sub(b,${a},1)` : `(b-${a})|0`};`; break;
          case 4: v = `const v=${S ? `c.add(${a},b,0)` : `(${a}+b)|0`};`; break;
          case 5: v = `const v=${S ? `c.add(${a},b,c.C)` : `(${a}+b+c.C)|0`};`; break;
          case 6: v = `const v=${S ? `c.sub(${a},b,c.C)` : `(${a}-b-1+c.C)|0`};`; break;
          case 7: v = `const v=${S ? `c.sub(b,${a},c.C)` : `(b-${a}-1+c.C)|0`};`; break;
          case 8: body = `{${pre}{const v=${a}&b;${NZ('v')}c.C=sc;}}`; break;
          case 9: body = `{${pre}{const v=${a}^b;${NZ('v')}c.C=sc;}}`; break;
          case 10: body = `{${pre}c.sub(${a},b,1);}`; break;
          case 11: body = `{${pre}c.add(${a},b,0);}`; break;
          case 12: v = `const v=${a}|b;` + (S ? NZ('v') + lz : ''); break;
          case 13: v = 'const v=b;' + (S ? NZ('v') + lz : ''); break;
          case 14: v = `const v=${a}&~b;` + (S ? NZ('v') + lz : ''); break;
          default: v = 'const v=~b;' + (S ? NZ('v') + lz : ''); break;
        }
        if (!body) { body = `{${pre}${v}${rd === 15 ? jump('v', k) : `r[${rd}]=v;`}}`; branches = rd === 15; }
        break;
      }
      case 2: case 3: {
        const rn = (op >> 16) & 15, rd = (op >> 12) & 15, P = op & 0x1000000, U = op & 0x800000, B = op & 0x400000, W = op & 0x200000, L = op & 0x100000;
        if (rn === 15 && (W || !P)) return fb;
        let s = '{';
        if (op & 0x2000000) s += 'let b,sc;' + shift(op & ~0x10, pc, false) + 'const off=b;'; else s += `const off=${op & 0xfff};`;
        s += `const base=${rn === 15 ? K(pc + 8) : `r[${rn}]`},a2=base${U ? '+' : '-'}off,a=(${P ? 'a2' : 'base'})>>>0;`;
        const wb = !P || W ? `r[${rn}]=a2;` : '';
        if (L) { s += `const v=${B ? 'u8[a]' : R32('a')};${wb}${rd === 15 ? jump('v', k) : `r[${rd}]=v;`}}`; branches = rd === 15; }
        else s += `const v=${rd === 15 ? K(pc + 12) : `r[${rd}]`};${B ? 'u8[a]=v;' : W32('a', 'v')}${wb}}`;
        body = s; break;
      }
      case 4: {
        const rn = (op >> 16) & 15, P = op & 0x1000000, U = op & 0x800000, W = op & 0x200000, L = op & 0x100000;
        if (op & 0x400000) return fb; // user-mode registers
        let n = 0; for (let i = 0; i < 16; i++) if (op & (1 << i)) n++;
        let s = `{const base=r[${rn}];let a=(base${U ? (P ? '+4' : '') : (P ? `-${n * 4}` : `-${n * 4 - 4}`)})>>>0;`;
        const end = `base${U ? '+' : '-'}${n * 4}`;
        if (L) {
          if (W) s += `r[${rn}]=${end};`;
          for (let i = 0; i < 15; i++) if (op & (1 << i)) s += `r[${i}]=${R32('a')};a+=4;`;
          if (op & 0x8000) { s += `{const v=${R32('a')};${jump('v', k)}}`; branches = true; }
        } else {
          for (let i = 0; i < 16; i++) if (op & (1 << i)) s += W32('a', i === 15 ? K(pc + 12) : `r[${i}]`) + 'a+=4;';
          if (W) s += `r[${rn}]=${end};`;
        }
        body = s + '}'; break;
      }
      case 5:
        body = `${op & 0x1000000 ? `r[14]=${pc + 4};` : ''}r[15]=${K(pc + 8 + ((op << 8) >> 6))};return ${k};`; branches = true; break;
      default: return fb;
    }
    if (cd === 14) return { s: body, end: branches };
    return { s: `if(${COND[cd]}){${body}}` };
  }

  function attachJit(Cpu) {
    const P = Cpu.prototype;
    // the code range the JIT may translate; blocks are made after cpu.jitHot runs of their first instruction
    P.enableJit = function (lo, hi, hot) {
      this.jitLo = lo >>> 0; this.jitHi = hi >>> 0; this.jitHot = hot || 64;
      this.jitArith = true; this.jitLong = false; this.jitRegs = true; // add/sub written out; blocks that go on through jumps (slower in V8)
      this.heat = new Uint8Array(((hi - lo) >>> 1) + 1); // runs counted per instruction address (Thumb: 2 bytes)
      this.jidx = new Uint16Array(this.heat.length); // block number * 2 + Thumb bit, 0 = none (at most MAX_BLOCKS blocks)
      this.fns = [null]; this.jitCount = 0;
    };
    P.flushJit = function () { if (this.heat) { this.heat.fill(0); this.jidx.fill(0); this.fns.length = 1; } };
    // a block goes on through jumps and calls that always happen to a fixed address, and a jump back to its own start
    // stays inside it (a loop; the block returns after 20 000 instructions at the latest so pauses still come)
    P.compile = function (pc, T0) {
      const parts = [];
      let k = 0, a = pc, T = T0, ended = false, lr = null, loops = false;
      const seen = new Set();
      const ok = (x, t) => x >= this.jitLo && x < this.jitHi && !seen.has(x) && !(this.hookPages[x >>> 12] && this.hooks.has(x | t));
      for (;;) {
        if (k > 0 && !ok(a, T)) break;
        seen.add(a);
        k++;
        const op = T ? this.u16[a >>> 1] : this.i32[a >>> 2];
        let next = null, link = '', nT = T;
        if (T) {
          const top = op >> 11;
          if (top === 28) next = (a + 4 + (((op & 0x7ff) << 21) >> 20)) | 0;
          else if (top === 31 && lr !== null) { next = (lr + ((op & 0x7ff) << 1)) & ~1; link = `r[14]=${(a + 2) | 1};`; }
          else if (top === 29 && lr !== null) { next = (lr + ((op & 0x7ff) << 1)) & ~3; link = `r[14]=${(a + 2) | 1};c.T=0;`; nT = 0; }
          lr = top === 30 ? (a + 4 + (((op & 0x7ff) << 21) >> 9)) | 0 : null;
          if ((top === 26 || top === 27) && T0 === 1 && ((op >> 8) & 15) < 14 && ((a + 4 + (((op & 255) << 24) >> 23)) | 0) === pc) {
            parts.push(`if(${COND[(op >> 8) & 15]}){n+=${k};if(n<20000)continue;r[15]=${pc};return n;}`); loops = true; a += 2; continue;
          }
        } else if ((op >>> 28) === 14 && ((op >> 25) & 7) === 5) {
          next = (a + 8 + ((op << 8) >> 6)) | 0; if (op & 0x1000000) link = `r[14]=${a + 4};`;
        } else if ((op >>> 28) === 15 && (op & 0x0e000000) === 0x0a000000) {
          next = (a + 8 + ((op << 8) >> 6) + ((op >> 23) & 2)) | 0; link = `r[14]=${a + 4};c.T=1;`; nT = 1;
        }
        if (next !== null && next === pc && nT === T0 && !link) { parts.push(`n+=${k};if(n<20000)continue;r[15]=${pc};return n;`); loops = true; ended = true; break; }
        if (this.jitLong && next !== null && k < 200 && ok(next, nT)) { parts.push(link); a = next; T = nT; continue; }
        const g = T ? thumb(op, a, 'n+' + k) : arm(op, a, 'n+' + k);
        parts.push(g.s);
        a += T ? 2 : 4;
        if (g.end) { ended = true; break; }
        if (k >= 200) break;
      }
      if (!ended) parts.push(`r[15]=${a};return n+${k};`);
      this.jitCount++;
      if (this.fns.length >= MAX_BLOCKS) this.flushJit(); // memory: start again with the blocks needed now
      // flags nobody reads: an instruction's N/Z/C/V are left out when a later one in the block sets them again before
      // anything reads them or the block can be left (a jump out, a call to cpu.thumb/arm: those count as reading all)
      let live = 15;
      for (let i = parts.length - 1; i >= 0; i--) {
        let p = this.jitArith ? inlineArith(parts[i]) : parts[i];
        if (/return|continue|c\.(thumb|arm|shifted)\(/.test(p)) { parts[i] = p; live = 15; continue; }
        let w = 0, rd = 0;
        for (const m of p.matchAll(/c\.([NZCV])(=+)?/g)) { const bit = FLAG[m[1]]; if (m[2] === '=') w |= bit; else rd |= bit; }
        const dead = w & ~live;
        if (dead) p = p.replace(/c\.([NZCV])=(?!=)[^;]*;/g, (m, fl) => (dead & FLAG[fl] ? '' : m));
        parts[i] = p;
        live = (live & ~(p.startsWith('if(') ? 0 : w)) | rd;
      }
      let s = parts.join('\n'), pro = '';
      // registers r0-r14 live in local variables inside the block (much cheaper than the register array, above all without a
      // compiler): read at the start, written back before every way out and before cpu.thumb/arm/shifted, which use the array
      // (and read again after cpu.thumb/arm, which may change any of them)
      if (this.jitRegs) {
        s = s.replace(/r\[(\d|1[0-4])\]/g, 'r$1');
        const used = new Set(), set = new Set();
        for (const m of s.matchAll(/\br(\d|1[0-4])\b(\s*(?:[+-]?=)(?!=))?/g)) { used.add(m[1]); if (m[2]) set.add(m[1]); }
        const wb = [...set].map((n) => `r[${n}]=r${n};`).join(''), load = [...used].map((n) => `r${n}=r[${n}]`);
        s = s.replace(/return ([^;]*);/g, `{${wb}return $1;}`)
          .replace(/c\.(thumb|arm)\((\d+)\);/g, `${wb}c.$1($2);${load.length ? load.join(';') + ';' : ''}`)
          .replace(/b=c\.shifted\(/g, `${wb}b=c.shifted(`);
        if (load.length) pro = 'let ' + load.join(',') + ';';
      }
      return new Function('c', 'r', 'u8', 'i32', pro + (loops ? `let n=0;for(;;){${s}}` : 'const n=0;' + s));
    };
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = attachJit; else root.EmuAttachJit = attachJit;
})(typeof window !== 'undefined' ? window : globalThis);
