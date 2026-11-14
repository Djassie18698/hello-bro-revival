// The system functions libgame.so imports from Android (libc, libm, libz, liblog, libdl, pthread), written in JavaScript on
// top of the emulator's memory. makeSys(cpu, opts) -> { resolve(name, isFunc) -> address, malloc, free, ... }
//   opts.vfs: { read(path) -> Uint8Array | null, write(path, bytes), exists(path), list(dir) }   the phone's files
//   opts.log(text)                                                                               the app's log lines
// A function nobody wrote yet stops the emulator with its name (so the next one to write is always known).
'use strict';
(function (root) {
  const Cpu = typeof module !== 'undefined' && module.exports ? require('./cpu.js') : root.EmuCpu;
  const EmuError = Cpu.EmuError;

  function makeSys(cpu, opts = {}) {
    const r = cpu.r, u8 = cpu.u8;
    const log = opts.log || ((s) => console.log(s));
    const vfs = opts.vfs || { read: () => null, write: () => {}, exists: () => false, list: () => [] };
    const sys = { calls: new Map(), missing: new Set() };
    const arg = (i) => (i < 4 ? r[i] : cpu.r32((r[13] + (i - 4) * 4) >>> 0)); // the i-th word argument of the current call
    const dbl = (lo, hi) => { cpu.i32[SCR >>> 2] = lo; cpu.i32[(SCR >>> 2) + 1] = hi; return cpu.dv.getFloat64(SCR, true); };
    const retD = (v) => { cpu.dv.setFloat64(SCR, v, true); r[0] = cpu.i32[SCR >>> 2]; r[1] = cpu.i32[(SCR >>> 2) + 1]; };
    const flt = (w) => { cpu.i32[SCR >>> 2] = w; return cpu.dv.getFloat32(SCR, true); };
    const retF = (v) => { cpu.dv.setFloat32(SCR, v, true); return cpu.i32[SCR >>> 2]; };

    // ---------------------------------------------------------------- memory: a simple size-class allocator
    let brk = opts.heapStart, heapEnd = opts.heapEnd;
    const SCR = brk; brk += 16; // 16 scratch bytes for number conversions
    const freeLists = new Map();
    const cls = (n) => { if (n <= 16) return 16; if (n <= 4096) return (n + 15) & ~15; let c = 8192; while (c < n) c *= 2; return n > 1 << 20 ? (n + 4095) & ~4095 : c; };
    function malloc(n) {
      n = n >>> 0;
      const size = cls(n || 1);
      const fl = freeLists.get(size);
      let p;
      if (fl && fl.length) p = fl.pop();
      else { p = brk + 8; brk += size + 8; if (brk > heapEnd) throw new EmuError('out of emulated memory (' + (brk >>> 20) + ' MB)'); }
      cpu.i32[(p - 8) >>> 2] = size;
      return p;
    }
    function free(p) {
      if (!p) return;
      const size = cpu.i32[(p - 8) >>> 2];
      let fl = freeLists.get(size); if (!fl) freeLists.set(size, (fl = []));
      fl.push(p);
    }
    function calloc(n, m) { const s = Math.imul(n, m) >>> 0, p = malloc(s); u8.fill(0, p, p + s); return p; }
    function realloc(p, n) {
      if (!p) return malloc(n);
      const old = cpu.i32[(p - 8) >>> 2];
      if ((n >>> 0) <= old) return p;
      const q = malloc(n); u8.copyWithin(q, p, p + old); free(p); return q;
    }
    const strdup = (s) => { const b = Cpu.enc.encode(s); const p = malloc(b.length + 1); u8.set(b, p); u8[p + b.length] = 0; return p; };
    Object.assign(sys, { malloc, free, calloc, realloc, strdup, heapUsed: () => brk - opts.heapStart });
    const strlen = (a) => { let e = a; while (u8[e]) e++; return e - a; };
    const errnoAddr = malloc(4); cpu.w32(errnoAddr, 0);
    const setErrno = (e) => cpu.w32(errnoAddr, e);

    // ---------------------------------------------------------------- printf family
    // args: { w(): next 32-bit word, d(): next double (8-byte aligned) , q(): next 64-bit integer as BigInt }
    const regArgs = (first) => { let i = first; return { w: () => arg(i++), d: () => { i += i & 1; const v = dbl(arg(i), arg(i + 1)); i += 2; return v; }, q: () => { i += i & 1; const v = (BigInt(arg(i + 1)) << 32n) | BigInt(arg(i) >>> 0); i += 2; return v; } }; };
    const vaArgs = (p) => ({ w: () => { const v = cpu.r32(p); p += 4; return v; }, d: () => { p = (p + 7) & ~7; const v = cpu.rf64(p); p += 8; return v; }, q: () => { p = (p + 7) & ~7; const v = (BigInt(cpu.r32(p + 4)) << 32n) | BigInt(cpu.r32(p) >>> 0); p += 8; return v; } });
    function fmtG(n, prec, upper) {
      if (prec === 0) prec = 1;
      if (n === 0) return '0';
      const e = Math.floor(Math.log10(Math.abs(n)));
      let s;
      if (e < -4 || e >= prec) { s = n.toExponential(prec - 1); let [m, ex] = s.split('e'); if (m.includes('.')) m = m.replace(/0+$/, '').replace(/\.$/, ''); const sg = ex[0] === '-' ? '-' : '+'; ex = ex.replace(/^[+-]/, ''); if (ex.length < 2) ex = '0' + ex; s = m + 'e' + sg + ex; }
      else { s = n.toFixed(Math.max(0, prec - 1 - e)); if (s.includes('.')) s = s.replace(/0+$/, '').replace(/\.$/, ''); }
      return upper ? s.toUpperCase() : s;
    }
    function format(fmtAddr, a) {
      const f = cpu.cstr(fmtAddr);
      let out = '';
      for (let i = 0; i < f.length; i++) {
        const c = f[i];
        if (c !== '%') { out += c; continue; }
        if (f[i + 1] === '%') { out += '%'; i++; continue; }
        let j = i + 1, flags = '';
        while ('-+ #0'.includes(f[j])) flags += f[j++];
        let width = '', prec;
        if (f[j] === '*') { width = String(a.w()); j++; } else while (/\d/.test(f[j])) width += f[j++];
        if (f[j] === '.') { j++; prec = ''; if (f[j] === '*') { prec = String(a.w()); j++; } else while (/\d/.test(f[j])) prec += f[j++]; }
        let len = '';
        while ('hlLqjzt'.includes(f[j])) len += f[j++];
        const conv = f[j]; i = j;
        let s;
        const big = len === 'll' || len === 'q' || len === 'L' || len === 'j';
        switch (conv) {
          case 'd': case 'i': { let v = big ? a.q() : BigInt(a.w()); if (len === 'h') v = BigInt((Number(v) << 16) >> 16); s = (v < 0n ? -v : v).toString(); if (prec !== undefined) s = s.padStart(Number(prec), '0'); s = (v < 0n ? '-' : flags.includes('+') ? '+' : flags.includes(' ') ? ' ' : '') + s; break; }
          case 'u': { const v = big ? BigInt.asUintN(64, a.q()) : BigInt(a.w() >>> 0); s = v.toString(); if (prec !== undefined) s = s.padStart(Number(prec), '0'); break; }
          case 'x': case 'X': case 'o': { const v = big ? BigInt.asUintN(64, a.q()) : BigInt(a.w() >>> 0); s = v.toString(conv === 'o' ? 8 : 16); if (conv === 'X') s = s.toUpperCase(); if (prec !== undefined) s = s.padStart(Number(prec), '0'); if (flags.includes('#') && v !== 0n && conv !== 'o') s = '0' + conv + s; break; }
          case 'p': s = '0x' + (a.w() >>> 0).toString(16); break;
          case 'c': s = String.fromCharCode(a.w() & 255); break;
          case 's': { const p = a.w(); s = p ? cpu.cstr(p) : '(null)'; if (prec !== undefined) s = s.slice(0, Number(prec)); break; }
          case 'f': case 'F': { const v = a.d(); s = isFinite(v) ? v.toFixed(prec === undefined ? 6 : Number(prec || 0)) : v !== v ? 'nan' : v > 0 ? 'inf' : '-inf'; if (v >= 0 && flags.includes('+')) s = '+' + s; break; }
          case 'e': case 'E': { const v = a.d(); s = v.toExponential(prec === undefined ? 6 : Number(prec || 0)).replace(/e([+-])(\d)$/, 'e$10$2'); if (conv === 'E') s = s.toUpperCase(); break; }
          case 'g': case 'G': { const v = a.d(); s = isFinite(v) ? fmtG(v, prec === undefined ? 6 : Number(prec || 0), conv === 'G') : v !== v ? 'nan' : v > 0 ? 'inf' : '-inf'; break; }
          case 'n': a.w(); s = ''; break;
          default: s = '%' + (conv || '');
        }
        const w = Number(width || 0);
        if (s.length < w) {
          if (flags.includes('-')) s = s.padEnd(w);
          else if (flags.includes('0') && 'diuxXofFeEgG'.includes(conv)) { const sg = /^[-+ ]/.test(s) ? s[0] : ''; s = sg + s.slice(sg.length).padStart(w - sg.length, '0'); }
          else s = s.padStart(w);
        }
        out += s;
      }
      return out;
    }
    const putStr = (dst, s, max) => { const b = Cpu.enc.encode(s); if (dst && max !== 0) { const n = max === undefined ? b.length : Math.min(b.length, max - 1); u8.set(b.subarray(0, n), dst); u8[dst + n] = 0; } return b.length; };

    // ---------------------------------------------------------------- files (FILE* and file descriptors) on the virtual file system
    const files = new Map(); // FILE* / fd -> { path, data: Uint8Array, pos, len, write, dirty }
    const sF = calloc(3, 84); // stdin, stdout, stderr
    let nextFd = 10;
    // a big read-only file can come in pieces: vfs.openLazy(path) -> { size, read(pos, n) -> Uint8Array } (the game's data file)
    const lazyBytes = (lz) => ({ length: lz.size, subarray: (a, b) => lz.read(a, Math.max(0, b - a)) });
    const at = (f, i) => (f.data.lazy ? f.data.subarray(i, i + 1)[0] : f.data[i]);
    sys.at = at;
    const openFile = (path, mode) => {
      const wr = /[wa+]/.test(mode);
      if (!wr && vfs.openLazy) { const lz = vfs.openLazy(path); if (lz) { const d = lazyBytes(lz); d.lazy = true; return { path, data: d, pos: 0, len: lz.size, write: false, dirty: false }; } }
      let data = vfs.read(path);
      if (!data && !wr) return null;
      if (mode.startsWith('w') || !data) data = new Uint8Array(0);
      return { path, data, pos: mode.startsWith('a') ? data.length : 0, len: data.length, write: wr, dirty: false };
    };
    const fwriteBytes = (f, bytes) => {
      if (f.pos + bytes.length > f.data.length) { const nd = new Uint8Array(Math.max(f.data.length * 2, f.pos + bytes.length, 256)); nd.set(f.data.subarray(0, f.len)); f.data = nd; }
      f.data.set(bytes, f.pos); f.pos += bytes.length; f.len = Math.max(f.len, f.pos); f.dirty = true;
    };
    const flush = (f) => { if (f && f.dirty) { vfs.write(f.path, f.data.subarray(0, f.len)); f.dirty = false; } };
    const outText = (fp, s) => { if (fp === sF + 84 || fp === sF + 168 || fp === 1 || fp === 2) { log(s.replace(/\n$/, '')); return; } const f = files.get(fp); if (f) fwriteBytes(f, Cpu.enc.encode(s)); };

    // ---------------------------------------------------------------- the functions
    const F = {};
    const D1 = (fn) => (c, a, b) => retD(fn(dbl(a, b)));
    const D2 = (fn) => (c, a, b, x, y) => retD(fn(dbl(a, b), dbl(x, y)));
    const F1 = (fn) => (c, a) => retF(fn(flt(a)));
    const F2 = (fn) => (c, a, b) => retF(fn(flt(a), flt(b)));
    Object.assign(F, {
      malloc: (c, n) => malloc(n), free: (c, p) => { free(p); }, calloc: (c, n, m) => calloc(n, m), realloc: (c, p, n) => realloc(p, n),
      memcpy: (c, d, s, n) => { u8.copyWithin(d, s, s + (n >>> 0)); return d; },
      memmove: (c, d, s, n) => { u8.copyWithin(d, s, s + (n >>> 0)); return d; },
      memset: (c, d, v, n) => { u8.fill(v, d, d + (n >>> 0)); return d; },
      memcmp: (c, a, b, n) => { n >>>= 0; for (let i = 0; i < n; i++) { const x = u8[a + i] - u8[b + i]; if (x) return x; } return 0; },
      memchr: (c, a, v, n) => { n >>>= 0; v &= 255; for (let i = 0; i < n; i++) if (u8[a + i] === v) return a + i; return 0; },
      memrchr: (c, a, v, n) => { v &= 255; for (let i = (n >>> 0) - 1; i >= 0; i--) if (u8[a + i] === v) return a + i; return 0; },
      memmem: (c, h, hn, nd, nn) => { for (let i = 0; i + nn <= hn; i++) { let k = 0; while (k < nn && u8[h + i + k] === u8[nd + k]) k++; if (k === nn) return h + i; } return 0; },
      strlen: (c, a) => strlen(a),
      strnlen: (c, a, n) => { let i = 0; while (i < (n >>> 0) && u8[a + i]) i++; return i; },
      strcpy: (c, d, s) => { const n = strlen(s) + 1; u8.copyWithin(d, s, s + n); return d; },
      strncpy: (c, d, s, n) => { n >>>= 0; let i = 0; for (; i < n && u8[s + i]; i++) u8[d + i] = u8[s + i]; for (; i < n; i++) u8[d + i] = 0; return d; },
      strcat: (c, d, s) => { const n = strlen(s) + 1; u8.copyWithin(d + strlen(d), s, s + n); return d; },
      strncat: (c, d, s, n) => { const e = d + strlen(d); let i = 0; for (; i < (n >>> 0) && u8[s + i]; i++) u8[e + i] = u8[s + i]; u8[e + i] = 0; return d; },
      strlcat: (c, d, s, n) => { const dl = strlen(d), sl = strlen(s); if (dl < (n >>> 0)) { const k = Math.min(sl, n - dl - 1); u8.copyWithin(d + dl, s, s + k); u8[d + dl + k] = 0; } return dl + sl; },
      strcmp: (c, a, b) => { for (let i = 0; ; i++) { const x = u8[a + i], y = u8[b + i]; if (x !== y) return x - y; if (!x) return 0; } },
      strncmp: (c, a, b, n) => { for (let i = 0; i < (n >>> 0); i++) { const x = u8[a + i], y = u8[b + i]; if (x !== y) return x - y; if (!x) return 0; } return 0; },
      strcoll: (c, a, b) => F.strcmp(c, a, b),
      strcasecmp: (c, a, b) => { for (let i = 0; ; i++) { let x = u8[a + i], y = u8[b + i]; if (x >= 65 && x <= 90) x += 32; if (y >= 65 && y <= 90) y += 32; if (x !== y) return x - y; if (!x) return 0; } },
      strncasecmp: (c, a, b, n) => { for (let i = 0; i < (n >>> 0); i++) { let x = u8[a + i], y = u8[b + i]; if (x >= 65 && x <= 90) x += 32; if (y >= 65 && y <= 90) y += 32; if (x !== y) return x - y; if (!x) return 0; } return 0; },
      strchr: (c, a, v) => { v &= 255; for (let i = a; ; i++) { if (u8[i] === v) return i; if (!u8[i]) return 0; } },
      strrchr: (c, a, v) => { v &= 255; let found = 0; for (let i = a; ; i++) { if (u8[i] === v) found = i; if (!u8[i]) return found; } },
      strstr: (c, h, nd) => { const nn = strlen(nd); if (!nn) return h; for (let i = h; u8[i]; i++) { let k = 0; while (k < nn && u8[i + k] === u8[nd + k]) k++; if (k === nn) return i; } return 0; },
      strpbrk: (c, a, set) => { const s = cpu.cstr(set); for (let i = a; u8[i]; i++) if (s.includes(String.fromCharCode(u8[i]))) return i; return 0; },
      strcspn: (c, a, set) => { const s = cpu.cstr(set); let i = 0; while (u8[a + i] && !s.includes(String.fromCharCode(u8[a + i]))) i++; return i; },
      strdup: (c, a) => { const n = strlen(a) + 1, p = malloc(n); u8.copyWithin(p, a, a + n); return p; },
      strxfrm: (c, d, s, n) => { const l = strlen(s); if (n >>> 0) { const k = Math.min(l, n - 1); u8.copyWithin(d, s, s + k); u8[d + k] = 0; } return l; },
      strtok_r: (c, s, delim, save) => {
        const dl = cpu.cstr(delim); let p = s || cpu.r32(save);
        if (!p) return 0;
        while (u8[p] && dl.includes(String.fromCharCode(u8[p]))) p++;
        if (!u8[p]) { cpu.w32(save, 0); return 0; }
        const start = p;
        while (u8[p] && !dl.includes(String.fromCharCode(u8[p]))) p++;
        if (u8[p]) { u8[p] = 0; cpu.w32(save, p + 1); } else cpu.w32(save, 0);
        return start;
      },
      strerror: () => strdup('error'), strerror_r: (c, e, buf, n) => { putStr(buf, 'error', n); return 0; },
      atoi: (c, a) => parseInt(cpu.cstr(a), 10) | 0, atol: (c, a) => parseInt(cpu.cstr(a), 10) | 0,
      strtol: (c, a, endp, base) => { const s = cpu.cstr(a); const m = /^\s*[-+]?(0[xX][0-9a-fA-F]+|[0-9a-zA-Z]+)?/.exec(s); let txt = m[0]; let v = parseInt(txt, base || (/^\s*[-+]?0[xX]/.test(txt) ? 16 : /^\s*[-+]?0\d/.test(txt) ? 8 : 10)); if (v !== v) { v = 0; txt = ''; } else { const digits = base > 10 || /0[xX]/.test(txt) ? txt : /^\s*[-+]?\d*/.exec(s)[0]; txt = digits; } if (endp) cpu.w32(endp, a + Cpu.enc.encode(txt).length); return Math.max(-2147483648, Math.min(2147483647, v)) | 0; },
      strtoul: (c, a, endp, base) => (F.strtol(c, a, endp, base) >>> 0) | 0,
      strtoll: (c, a, endp, base) => BigInt(F.strtol(c, a, endp, base)),
      strtod: (c, a, endp) => { const s = cpu.cstr(a); const m = /^\s*[-+]?(\d+\.?\d*([eE][-+]?\d+)?|\.\d+([eE][-+]?\d+)?|inf(inity)?|nan)/i.exec(s); if (endp) cpu.w32(endp, a + (m ? m[0].length : 0)); retD(m ? Number(m[0]) : 0); },
      // ---- printf family
      sprintf: (c, d, f) => putStr(d, format(f, regArgs(2))),
      snprintf: (c, d, n, f) => putStr(d, format(f, regArgs(3)), n >>> 0),
      vsprintf: (c, d, f, va) => putStr(d, format(f, vaArgs(va))),
      vsnprintf: (c, d, n, f, va) => putStr(d, format(f, vaArgs(va)), n >>> 0),
      printf: (c, f) => { const s = format(f, regArgs(1)); log(s.replace(/\n$/, '')); return s.length; },
      fprintf: (c, fp, f) => { const s = format(f, regArgs(2)); outText(fp, s); return s.length; },
      vfprintf: (c, fp, f, va) => { const s = format(f, vaArgs(va)); outText(fp, s); return s.length; },
      putchar: (c, ch) => ch, putc: (c, ch, fp) => { outText(fp, String.fromCharCode(ch)); return ch; }, fputc: (c, ch, fp) => { outText(fp, String.fromCharCode(ch)); return ch; },
      fputs: (c, s, fp) => { outText(fp, cpu.cstr(s)); return 1; }, perror: (c, s) => { log('perror: ' + cpu.cstr(s)); },
      __swbuf: (c, ch, fp) => { outText(fp, String.fromCharCode(ch & 255)); return ch & 255; },
      __android_log_print: (c, prio, tag, f) => { log('[' + cpu.cstr(tag) + '] ' + format(f, regArgs(3))); return 0; },
      __assert2: (c, file, line, fn, expr) => { throw new EmuError(`assert ${cpu.cstr(expr)} at ${cpu.cstr(file)}:${line} (${cpu.cstr(fn)})`); },
      abort: () => { throw new EmuError('abort() called'); },
      exit: (c, code) => { throw new EmuError('exit(' + code + ')'); },
      __stack_chk_fail: () => { throw new EmuError('stack check failed'); },
      __errno: () => errnoAddr,
      __cxa_atexit: () => 0, __cxa_finalize: () => 0,
      // ---- files
      fopen: (c, path, mode) => { const p = cpu.cstr(path), f = openFile(p, cpu.cstr(mode)); if (opts.traceFiles) log('fopen ' + p + (f ? '' : ' (missing)')); if (!f) { setErrno(2); return 0; } const fp = calloc(1, 84); files.set(fp, f); return fp; },
      fclose: (c, fp) => { flush(files.get(fp)); files.delete(fp); if (fp < sF || fp > sF + 168) free(fp); return 0; },
      fread: (c, dst, size, n, fp) => { const f = files.get(fp); if (!f || !size) return 0; const want = Math.imul(size, n) >>> 0, got = Math.min(want, f.len - f.pos); u8.set(f.data.subarray(f.pos, f.pos + got), dst); f.pos += got; return (got / size) | 0; },
      fwrite: (c, src, size, n, fp) => { const total = Math.imul(size, n) >>> 0; if (fp === sF + 84 || fp === sF + 168) { log(Cpu.dec.decode(u8.subarray(src, src + total)).replace(/\n$/, '')); return n; } const f = files.get(fp); if (!f) return 0; fwriteBytes(f, u8.slice(src, src + total)); return n; },
      fseek: (c, fp, off, whence) => { const f = files.get(fp); if (!f) return -1; f.pos = Math.max(0, whence === 0 ? off : whence === 1 ? f.pos + off : f.len + off); return 0; },
      ftell: (c, fp) => { const f = files.get(fp); return f ? f.pos : -1; },
      rewind: (c, fp) => { const f = files.get(fp); if (f) f.pos = 0; },
      fflush: (c, fp) => { flush(files.get(fp)); return 0; },
      ferror: () => 0,
      fgets: (c, dst, n, fp) => { const f = files.get(fp); if (!f || f.pos >= f.len) return 0; let i = 0; while (i < n - 1 && f.pos < f.len) { const ch = at(f, f.pos++); u8[dst + i++] = ch; if (ch === 10) break; } u8[dst + i] = 0; return dst; },
      getc: (c, fp) => { const f = files.get(fp); return f && f.pos < f.len ? at(f, f.pos++) : -1; },
      __srget: (c, fp) => { const f = files.get(fp); return f && f.pos < f.len ? at(f, f.pos++) : -1; },
      ungetc: (c, ch, fp) => { const f = files.get(fp); if (f && f.pos > 0) f.pos--; return ch; },
      remove: (c, path) => { vfs.write(cpu.cstr(path), null); return 0; },
      rename: (c, a, b) => { const d = vfs.read(cpu.cstr(a)); if (!d) return -1; vfs.write(cpu.cstr(b), d); vfs.write(cpu.cstr(a), null); return 0; },
      access: (c, path) => (vfs.exists(cpu.cstr(path)) || (vfs.openLazy && vfs.openLazy(cpu.cstr(path))) ? 0 : -1),
      mkdir: () => 0, chmod: () => 0, umask: () => 0,
      stat: (c, path, st) => { const p = cpu.cstr(path), lz = vfs.openLazy && vfs.openLazy(p), d = lz ? { length: lz.size } : vfs.read(p), dir = !d && vfs.isDir && vfs.isDir(p); if (!d && !dir) { setErrno(2); return -1; } u8.fill(0, st, st + 104); cpu.w32(st + 16, dir ? 0o40755 : 0o100644); cpu.w32(st + 48, d ? d.length : 0); return 0; },
      open: (c, path, flags) => { const p = cpu.cstr(path), f = openFile(p, (flags & 3) === 0 ? 'r' : flags & 0x200 ? 'w' : flags & 0x40 ? 'a' : 'r+'); if (opts.traceFiles) log('open ' + p + (f ? '' : ' (missing)')); if (!f) { setErrno(2); return -1; } const fd = nextFd++; files.set(fd, f); return fd; },
      close: (c, fd) => { flush(files.get(fd)); files.delete(fd); return 0; },
      read: (c, fd, dst, n) => { const f = files.get(fd); if (!f) return -1; const got = Math.min(n >>> 0, f.len - f.pos); u8.set(f.data.subarray(f.pos, f.pos + got), dst); f.pos += got; return got; },
      write: (c, fd, src, n) => { if (fd === 1 || fd === 2) { log(Cpu.dec.decode(u8.subarray(src, src + n))); return n; } const f = files.get(fd); if (!f) return -1; fwriteBytes(f, u8.slice(src, src + n)); return n; },
      lseek: (c, fd, off, whence) => { const f = files.get(fd); if (!f) return -1; f.pos = Math.max(0, whence === 0 ? off : whence === 1 ? f.pos + off : f.len + off); return f.pos; },
      fstat: (c, fd, st) => { const f = files.get(fd); if (!f) return -1; u8.fill(0, st, st + 104); cpu.w32(st + 16, 0o100644); cpu.w32(st + 48, f.len); return 0; },
      // ---- time
      time: (c, p) => { const t = Math.floor(Date.now() / 1000); if (p) cpu.w32(p, t); return t; },
      gettimeofday: (c, tv) => { const now = Date.now(); if (tv) { cpu.w32(tv, Math.floor(now / 1000)); cpu.w32(tv + 4, (now % 1000) * 1000); } return 0; },
      clock_gettime: (c, id, ts) => { const now = typeof performance !== 'undefined' ? performance.now() + (performance.timeOrigin || 0) : Date.now(); cpu.w32(ts, Math.floor(now / 1000)); cpu.w32(ts + 4, Math.floor((now % 1000) * 1e6)); return 0; },
      clock: () => (Date.now() * 1000) | 0,
      difftime: (c, a, b) => retD(a - b),
      localtime: (c, tp) => tmOut(cpu.r32(tp), tmBuf, false), localtime_r: (c, tp, out) => tmOut(cpu.r32(tp), out, false),
      gmtime: (c, tp) => tmOut(cpu.r32(tp), tmBuf, true), gmtime_r: (c, tp, out) => tmOut(cpu.r32(tp), out, true),
      mktime: (c, tm) => Math.floor(new Date(cpu.r32(tm + 20) + 1900, cpu.r32(tm + 16), cpu.r32(tm + 12), cpu.r32(tm + 8), cpu.r32(tm + 4), cpu.r32(tm)).getTime() / 1000),
      strftime: (c, dst, max, f, tm) => {
        const g = (o) => cpu.r32(tm + o), p2 = (n) => String(n).padStart(2, '0');
        const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], MON = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        // every code the phone's C library knows (14 Nov 2026: %X was left as it was, so the app's request field Clinettime held a '%X';
        // the Lua screens that log their request with string.format (util/common.lua sendRequest, log = 1: Hot Treasure) stopped there
        // with 'bad argument #2 to format' and never filled in). A code it does not know becomes nothing, never a lone '%'.
        const H = g(8), h12 = H % 12 || 12, yday = g(28), off = -new Date().getTimezoneOffset();
        const one = (k) => ({ Y: String(g(20) + 1900), C: p2(Math.floor((g(20) + 1900) / 100)), y: p2(g(20) % 100), m: p2(g(16) + 1), d: p2(g(12)), e: String(g(12)).padStart(2, ' '),
          H: p2(H), I: p2(h12), l: String(h12).padStart(2, ' '), k: String(H).padStart(2, ' '), M: p2(g(4)), S: p2(g(0)), p: H < 12 ? 'AM' : 'PM', P: H < 12 ? 'am' : 'pm',
          A: DAYS[g(24)] || '', a: (DAYS[g(24)] || '').slice(0, 3), B: MON[g(16)] || '', b: (MON[g(16)] || '').slice(0, 3), h: (MON[g(16)] || '').slice(0, 3),
          w: String(g(24)), u: String(g(24) || 7), j: String(yday + 1).padStart(3, '0'), n: String.fromCharCode(10), t: String.fromCharCode(9), '%': '%',
          z: (off < 0 ? '-' : '+') + p2(Math.floor(Math.abs(off) / 60)) + p2(Math.abs(off) % 60), Z: '' })[k];
        const combo = { X: '%H:%M:%S', T: '%H:%M:%S', R: '%H:%M', r: '%I:%M:%S %p', x: '%m/%d/%y', D: '%m/%d/%y', F: '%Y-%m-%d', c: '%a %b %e %H:%M:%S %Y' };
        const s = cpu.cstr(f).replace(/%[EO]?(.)/g, (all, k) => (combo[k] ? combo[k].replace(/%(.)/g, (x, kk) => one(kk)) : one(k) ?? ''));
        return putStr(dst, s, max) < max ? Cpu.enc.encode(s).length : 0;
      },
      usleep: () => { cpu.yielding = true; return 0; }, alarm: () => 0, // in a thread: let the others run
      // ---- math (doubles travel in two registers, floats in one: soft-float calling convention)
      sin: D1(Math.sin), cos: D1(Math.cos), tan: D1(Math.tan), asin: D1(Math.asin), acos: D1(Math.acos), atan: D1(Math.atan), sinh: D1(Math.sinh), cosh: D1(Math.cosh), tanh: D1(Math.tanh),
      exp: D1(Math.exp), log: D1(Math.log), log10: D1(Math.log10), sqrt: D1(Math.sqrt), ceil: D1(Math.ceil), floor: D1(Math.floor),
      atan2: D2(Math.atan2), pow: D2(Math.pow), fmod: D2((a, b) => a % b),
      sinf: F1(Math.sin), cosf: F1(Math.cos), tanf: F1(Math.tan), asinf: F1(Math.asin), acosf: F1(Math.acos), expf: F1(Math.exp), logf: F1(Math.log), sqrtf: F1(Math.sqrt), ceilf: F1(Math.ceil), floorf: F1(Math.floor),
      atan2f: F2(Math.atan2), powf: F2(Math.pow), fmodf: F2((a, b) => a % b),
      ldexp: (c, a, b, e) => retD(dbl(a, b) * Math.pow(2, e)),
      frexp: (c, a, b, ep) => { const v = dbl(a, b); if (v === 0 || !isFinite(v)) { cpu.w32(ep, 0); return retD(v); } let e = Math.floor(Math.log2(Math.abs(v))) + 1, m = v / Math.pow(2, e); if (Math.abs(m) >= 1) { m /= 2; e++; } if (Math.abs(m) < 0.5) { m *= 2; e--; } cpu.w32(ep, e); retD(m); },
      modf: (c, a, b, ip) => { const v = dbl(a, b), i = v < 0 ? Math.ceil(v) : Math.floor(v); cpu.wf64(ip, i); retD(v - i); },
      lrand48: () => (Math.random() * 0x7fffffff) | 0, srand48: () => {},
      // ---- misc
      qsort: (c, base, n, size, cmp) => {
        const items = []; for (let i = 0; i < n; i++) items.push(u8.slice(base + i * size, base + (i + 1) * size));
        const a = malloc(size), b = malloc(size);
        items.sort((x, y) => { u8.set(x, a); u8.set(y, b); return cpu.call(cmp, [a, b]); });
        items.forEach((it, i) => u8.set(it, base + i * size));
        free(a); free(b);
      },
      bsearch: (c, key, base, n, size) => { const cmp = arg(4); let lo = 0, hi = n - 1; while (lo <= hi) { const mid = (lo + hi) >> 1, p = base + mid * size, x = cpu.call(cmp, [key, p]); if (x === 0) return p; if (x < 0) hi = mid - 1; else lo = mid + 1; } return 0; },
      getenv: () => 0, setlocale: () => 0, getpid: () => 1234, getuid: () => 10001, geteuid: () => 10001, getgid: () => 10001, getegid: () => 10001,
      sigaction: () => 0, bsd_signal: () => 0, raise: () => 0, kill: () => 0, system: () => -1, syscall: () => -1,
      dlopen: () => 0, dlsym: () => 0, dlclose: () => 0, dlerror: () => 0,
      openlog: () => {}, closelog: () => {}, syslog: () => {},
      __gnu_Unwind_Find_exidx: (c, pc, count) => { cpu.w32(count, sys.exidx[1]); return sys.exidx[0]; },
      // ---- threads: one emulated thread for now; locks always succeed
      pthread_mutex_init: () => 0, pthread_mutex_destroy: () => 0, pthread_mutex_lock: () => 0, pthread_mutex_unlock: () => 0, pthread_mutex_trylock: () => 0,
      pthread_mutexattr_init: () => 0, pthread_mutexattr_destroy: () => 0, pthread_mutexattr_settype: () => 0,
      pthread_cond_init: () => 0, pthread_cond_destroy: () => 0, pthread_cond_signal: () => 0,
      pthread_key_create: (c, keyp, dtor) => { const k = tls.length; tls.push(0); cpu.w32(keyp, k); return 0; },
      pthread_key_delete: () => 0,
      pthread_getspecific: (c, k) => tls[k] | 0, pthread_setspecific: (c, k, v) => { tls[k] = v; return 0; },
      pthread_once: (c, once, fn) => { if (!cpu.r32(once)) { cpu.w32(once, 1); cpu.call(fn, []); } return 0; },
      pthread_create: (c, tidp, attr, fn, a) => { const stack = malloc(256 << 10); const th = cpu.newThread(fn, a, stack + (256 << 10) - 16); th.id = sys.threads.length + 1; sys.threads.push(th); cpu.w32(tidp, th.id); return 0; },
      pthread_detach: () => 0, pthread_join: () => 0,
      // ---- setjmp / longjmp: registers r4-r11, sp, lr go into the jmp_buf
      setjmp: (c, buf) => { for (let i = 0; i < 8; i++) cpu.w32(buf + i * 4, r[4 + i]); cpu.w32(buf + 32, r[13]); cpu.w32(buf + 36, r[14]); cpu.w32(buf + 40, cpu.depth | 0); return 0; },
      sigsetjmp: (c, buf) => F.setjmp(c, buf),
      longjmp: (c, buf, val) => {
        if (cpu.r32(buf + 40) !== (cpu.depth | 0)) throw new EmuError('longjmp across a JavaScript call');
        for (let i = 0; i < 8; i++) r[4 + i] = cpu.r32(buf + i * 4);
        r[13] = cpu.r32(buf + 32); const lr = cpu.r32(buf + 36);
        r[0] = val || 1; cpu.T = lr & 1; r[15] = lr & ~1; cpu.unwound = true;
      },
      siglongjmp: (c, buf, val) => F.longjmp(c, buf, val),
    });
    // ---- wide characters (wchar_t is 4 bytes; the C++ library sets up its locale with these)
    const wlen = (a) => { let n = 0; while (cpu.r32(a + n * 4)) n++; return n; };
    Object.assign(F, {
      wctob: (c, w) => (w >= 0 && w < 128 ? w : -1), btowc: (c, ch) => (ch >= 0 && ch < 128 ? ch : -1),
      wcslen: (c, a) => wlen(a),
      wmemcpy: (c, d, s, n) => { u8.copyWithin(d, s, s + n * 4); return d; }, wmemmove: (c, d, s, n) => { u8.copyWithin(d, s, s + n * 4); return d; },
      wmemset: (c, d, v, n) => { for (let i = 0; i < n; i++) cpu.w32(d + i * 4, v); return d; },
      wmemchr: (c, a, v, n) => { for (let i = 0; i < n; i++) if (cpu.r32(a + i * 4) === v) return a + i * 4; return 0; },
      wmemcmp: (c, a, b, n) => { for (let i = 0; i < n; i++) { const x = cpu.r32(a + i * 4) - cpu.r32(b + i * 4); if (x) return x; } return 0; },
      wcscoll: (c, a, b) => { for (let i = 0; ; i++) { const x = cpu.r32(a + i * 4), y = cpu.r32(b + i * 4); if (x !== y) return x - y; if (!x) return 0; } },
      wcsxfrm: (c, d, s, n) => { const l = wlen(s); for (let i = 0; i < Math.min(l + 1, n); i++) cpu.w32(d + i * 4, cpu.r32(s + i * 4)); return l; },
      wcsftime: () => 0,
      towlower: (c, w) => (w >= 65 && w <= 90 ? w + 32 : w), towupper: (c, w) => (w >= 97 && w <= 122 ? w - 32 : w),
      wctype: (c, name) => ({ alnum: 1, alpha: 2, blank: 3, cntrl: 4, digit: 5, graph: 6, lower: 7, print: 8, punct: 9, space: 10, upper: 11, xdigit: 12 })[cpu.cstr(name)] || 0,
      iswctype: (c, w, t) => { if (w < 0 || w > 127) return 0; const ch = String.fromCharCode(w); return [0, /[A-Za-z0-9]/, /[A-Za-z]/, /[ \t]/, /[\x00-\x1f\x7f]/, /[0-9]/, /[!-~]/, /[a-z]/, /[ -~]/, /[!-\/:-@\[-`{-~]/, /\s/, /[A-Z]/, /[0-9A-Fa-f]/][t].test(ch) ? 1 : 0; },
      // one byte <-> one wide character (UTF-8 text stays bytes inside the app; only ASCII passes through these)
      mbrtowc: (c, pwc, s, n) => { if (!s) return 0; if (!n) return -2; const ch = u8[s]; if (pwc) cpu.w32(pwc, ch); return ch ? 1 : 0; },
      wcrtomb: (c, s, wc) => { if (!s) return 1; u8[s] = wc; return 1; },
      getwc: () => -1, putwc: (c, w) => w, ungetwc: () => -1,
      // ---- sscanf: the conversions the app's formats use
      sscanf: (c, src, f) => scan(cpu.cstr(src), cpu.cstr(f), regArgs(2)),
      fscanf: () => -1,
      setvbuf: () => 0, fdopen: () => 0, freopen: () => 0, tmpfile: () => 0, tmpnam: () => 0, writev: () => -1, fcntl: () => 0, ioctl: () => -1,
      basename: (c, p) => { const s = cpu.cstr(p); return p + Cpu.enc.encode(s.slice(0, s.lastIndexOf('/') + 1)).length; },
      // ---- folders
      opendir: (c, path) => { const p = cpu.cstr(path); if (!(vfs.isDir && vfs.isDir(p))) return 0; const h = calloc(1, 280); files.set(h, { dir: vfs.list(p), i: 0 }); return h; },
      readdir: (c, h) => { const d = files.get(h); if (!d || d.i >= d.dir.length) return 0; const e = d.dir[d.i++]; u8.fill(0, h, h + 280); cpu.w8(h + 18, e.dir ? 4 : 8); putStr(h + 19, e.name, 256); return h; },
      closedir: (c, h) => { files.delete(h); free(h); return 0; },
      // ---- memory maps: only anonymous ones (a block of the heap)
      mmap: (c, addr, len) => calloc(1, len), munmap: () => 0,
      // ---- network: nothing answers yet (the game's requests are bridged at a higher level later)
      socket: () => -1, connect: () => -1, bind: () => -1, listen: () => -1, accept: () => -1, send: () => -1, recv: () => -1, sendto: () => -1, recvfrom: () => -1, shutdown: () => 0,
      getsockname: () => -1, getpeername: () => -1, getsockopt: () => -1, setsockopt: () => -1, poll: () => 0, socketpair: () => -1,
      getaddrinfo: () => -2, freeaddrinfo: () => {}, gethostbyname: () => 0, gethostname: (c, buf, n) => { putStr(buf, 'web', n); return 0; }, getservbyname: () => 0, inet_pton: () => 0, inet_ntop: () => 0,
      getpwuid: () => 0, getopt: () => -1, fork: () => -1, execl: () => -1, waitpid: () => -1, dup2: () => -1,
      regcomp: () => 1, regexec: () => 1, regfree: () => {},
      pthread_exit: () => { if (!cpu.thread) throw new EmuError('pthread_exit on the main thread'); cpu.thread.done = true; cpu.yielding = true; },
      // waiting = "let the others run, then look again" (a wake-up without a signal is allowed, the app's loops check again);
      // on the main thread: run the other threads once, then go on
      pthread_cond_wait: () => { if (cpu.thread) cpu.yielding = true; else sys.runThreads(); return 0; },
    });
    function scan(s, f, a) {
      let si = 0, n = 0;
      const ws = () => { while (si < s.length && /\s/.test(s[si])) si++; };
      for (let i = 0; i < f.length; i++) {
        const ch = f[i];
        if (/\s/.test(ch)) { ws(); continue; }
        if (ch !== '%') { if (s[si] !== ch) return n; si++; continue; }
        i++;
        if (f[i] === '%') { ws(); if (s[si] !== '%') return n; si++; continue; }
        let skip = false, width = '', len = '';
        if (f[i] === '*') { skip = true; i++; }
        while (/\d/.test(f[i])) width += f[i++];
        while ('hlLqjz'.includes(f[i])) len += f[i++];
        const conv = f[i], w = width ? Number(width) : Infinity;
        if (conv === 'n') { if (!skip) cpu.w32(a.w(), Cpu.enc.encode(s.slice(0, si)).length); continue; }
        let m;
        if (conv === 'c') { const k = width ? w : 1; if (si + k > s.length) return n || -1; if (!skip) { const p = a.w(); u8.set(Cpu.enc.encode(s.substr(si, k)).subarray(0, k), p); n++; } si += k; continue; }
        if (conv === '[') {
          let j = i + 1, neg = false; if (f[j] === '^') { neg = true; j++; }
          let set = ''; if (f[j] === ']') { set += ']'; j++; }
          while (j < f.length && f[j] !== ']') set += f[j++];
          i = j;
          const inSet = (c2) => { for (let k = 0; k < set.length; k++) { if (set[k + 1] === '-' && k + 2 < set.length) { if (c2 >= set[k] && c2 <= set[k + 2]) return true; k += 2; } else if (set[k] === c2) return true; } return false; };
          let e = si; while (e < s.length && e - si < w && inSet(s[e]) !== neg) e++;
          if (e === si) return n;
          if (!skip) { putStr(a.w(), s.slice(si, e)); n++; }
          si = e; continue;
        }
        ws();
        if (si >= s.length) return n || -1;
        const rest = s.slice(si, w === Infinity ? undefined : si + w);
        switch (conv) {
          case 'd': case 'u': m = /^[-+]?\d+/.exec(rest); break;
          case 'i': m = /^[-+]?(0[xX][0-9a-fA-F]+|\d+)/.exec(rest); break;
          case 'x': case 'X': case 'p': m = /^[-+]?(0[xX])?[0-9a-fA-F]+/.exec(rest); break;
          case 'o': m = /^[-+]?[0-7]+/.exec(rest); break;
          case 'f': case 'g': case 'e': case 'E': case 'G': m = /^[-+]?(\d+\.?\d*([eE][-+]?\d+)?|\.\d+([eE][-+]?\d+)?)/.exec(rest); break;
          case 's': m = /^\S+/.exec(rest); break;
          default: return n;
        }
        if (!m) return n;
        si += m[0].length;
        if (skip) continue;
        const p = a.w();
        if (conv === 's') putStr(p, m[0]);
        else if ('fgeEG'.includes(conv)) { if (len === 'l' || len === 'L') cpu.wf64(p, Number(m[0])); else cpu.wf32(p, Number(m[0])); }
        else {
          const v = conv === 'x' || conv === 'X' || conv === 'p' ? parseInt(m[0], 16) : conv === 'o' ? parseInt(m[0], 8) : conv === 'i' ? Number(m[0].replace(/^([-+]?)0[xX]/, '$10x')) || parseInt(m[0]) : parseInt(m[0], 10);
          if (len === 'll' || len === 'q') { const b = BigInt(Math.trunc(v)); cpu.w32(p, Number(BigInt.asIntN(32, b))); cpu.w32(p + 4, Number(BigInt.asIntN(32, b >> 32n))); }
          else if (len === 'h') cpu.w16(p, v); else if (len === 'hh') cpu.w8(p, v); else cpu.w32(p, v);
        }
        n++;
      }
      return n;
    }
    const tls = [0];
    sys.threads = [];
    sys.runThreads = () => { for (const th of sys.threads) if (!th.done) cpu.runThread(th); };
    sys.exidx = [0, 0];
    const tmBuf = calloc(1, 48);
    function tmOut(t, out, utc) {
      const d = new Date(t * 1000), g = (f) => (utc ? d['getUTC' + f]() : d['get' + f]());
      const jan1 = utc ? Date.UTC(g('FullYear'), 0, 1) : new Date(g('FullYear'), 0, 1).getTime();
      [g('Seconds'), g('Minutes'), g('Hours'), g('Date'), g('Month'), g('FullYear') - 1900, g('Day'), Math.floor((d.getTime() - jan1) / 864e5), 0].forEach((v, i) => cpu.w32(out + i * 4, v));
      cpu.w32(out + 36, utc ? 0 : -d.getTimezoneOffset() * 60); cpu.w32(out + 40, 0);
      return out;
    }

    // ---------------------------------------------------------------- data the app reads directly (not functions)
    const DATA = {};
    DATA.__sF = sF;
    DATA.__stack_chk_guard = (() => { const p = malloc(4); cpu.w32(p, 0x5a5a1234); return p; })();
    { // _ctype_: a pointer to 1 + 256 flag bytes (bionic); _tolower_tab_ / _toupper_tab_: pointers to 1 + 256 shorts
      const U = 1, L = 2, N = 4, S = 8, P = 16, C = 32, X = 64, B = 128;
      const t = calloc(1, 257);
      for (let ch = 0; ch < 128; ch++) {
        let f = 0;
        if (ch < 32 || ch === 127) f |= C;
        if (ch === 32) f |= S | B; else if (ch >= 9 && ch <= 13) f |= S;
        if (ch >= 48 && ch <= 57) f |= N;
        if (ch >= 65 && ch <= 90) f |= U | (ch <= 70 ? X : 0);
        if (ch >= 97 && ch <= 122) f |= L | (ch <= 102 ? X : 0);
        if ((ch >= 33 && ch <= 47) || (ch >= 58 && ch <= 64) || (ch >= 91 && ch <= 96) || (ch >= 123 && ch <= 126)) f |= P;
        u8[t + 1 + ch] = f;
      }
      DATA._ctype_ = (() => { const p = malloc(4); cpu.w32(p, t); return p; })();
      const lo = calloc(257, 2), up = calloc(257, 2);
      cpu.w16(lo, -1 & 0xffff); cpu.w16(up, -1 & 0xffff);
      for (let ch = 0; ch < 256; ch++) { cpu.w16(lo + 2 + ch * 2, ch >= 65 && ch <= 90 ? ch + 32 : ch); cpu.w16(up + 2 + ch * 2, ch >= 97 && ch <= 122 ? ch - 32 : ch); }
      DATA._tolower_tab_ = (() => { const p = malloc(4); cpu.w32(p, lo); return p; })();
      DATA._toupper_tab_ = (() => { const p = malloc(4); cpu.w32(p, up); return p; })();
    }
    DATA.optarg = calloc(1, 4); DATA.optind = calloc(1, 4);

    sys.F = F; sys.DATA = DATA; sys.format = format; sys.regArgs = regArgs; sys.files = files; sys.arg = arg; sys.dbl = dbl; sys.flt = flt; sys.retF = retF; sys.retD = retD; sys.putStr = putStr;
    const trapOf = new Map();
    sys.resolve = (name, isFunc) => {
      if (name in DATA) return DATA[name];
      if (trapOf.has(name)) return trapOf.get(name);
      const fn = F[name] || (opts.extra && opts.extra[name]);
      const t = cpu.trap(fn ? (c, a, b, x, y) => fn(c, a, b, x, y) : () => { throw new EmuError('the app called ' + name + '(), which is not written yet'); }, name);
      if (!fn) sys.missing.add(name);
      trapOf.set(name, t);
      return t;
    };
    return sys;
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = makeSys; else root.EmuMakeSys = makeSys;
})(typeof window !== 'undefined' ? window : globalThis);
