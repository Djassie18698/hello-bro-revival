// Fast versions of the app's busiest inner functions. Profiling the start (tools/dev/emu-profile.js) showed ~60 % of all
// emulated instructions in a handful of library functions: unpacking PNG pictures (libpng 1.2.46 png_read_filter_row) and
// zip data (zlib 1.2.3 inflate_fast), their checksums (crc32, adler32) and 64-bit division. Each one is replaced here by
// JavaScript that does exactly what the C code does, on the emulated memory ("hooks", like net.js). A hook may return false
// to let the original code run instead (used for rare error paths, so the app's own error messages stay right).
//   hookFast(cpu, lib, log)
'use strict';
(function (root) {
  function hookFast(cpu, lib, log) {
    const u8 = cpu.u8, r = cpu.r;
    let n = 0;
    const hook = (name, fn) => { const a = lib.sym(name); if (!a) { log('fast: no ' + name + ' in the app'); return; } cpu.hooks.set(a >>> 0, fn); n++; };

    // ---- crc32(crc, buf, len) and adler32(adler, buf, len) (zlib 1.2.3; buf 0 = the start value)
    const CRC = new Int32Array(256);
    for (let i = 0; i < 256; i++) { let c = i; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; CRC[i] = c; }
    hook('crc32', (c) => {
      const buf = r[1] >>> 0, len = r[2] >>> 0;
      if (!buf) { r[0] = 0; return; }
      let crc = ~r[0];
      for (let i = buf, e = buf + len; i < e; i++) crc = CRC[(crc ^ u8[i]) & 255] ^ (crc >>> 8);
      r[0] = ~crc;
    });
    hook('adler32', (c) => {
      const buf = r[1] >>> 0;
      let len = r[2] >>> 0;
      if (!buf) { r[0] = 1; return; }
      let a = r[0] & 0xffff, b = (r[0] >>> 16) & 0xffff, i = buf;
      while (len > 0) { const k = len < 3800 ? len : 3800; len -= k; for (const e = i + k; i < e; i++) { a += u8[i]; b += a; } a %= 65521; b %= 65521; }
      r[0] = (b << 16) | a;
    });

    // ---- 64-bit unsigned division: __aeabi_uldivmod(n, d) -> quotient r0:r1, remainder r2:r3 (by 0: left to the original)
    hook('__aeabi_uldivmod', () => {
      const nl = r[0] >>> 0, nh = r[1] >>> 0, dl = r[2] >>> 0, dh = r[3] >>> 0;
      if (!dl && !dh) return false;
      if (!nh && !dh) { const q = Math.floor(nl / dl); r[0] = q; r[1] = 0; r[2] = nl - q * dl; r[3] = 0; return; }
      const N = (BigInt(nh) << 32n) | BigInt(nl), D = (BigInt(dh) << 32n) | BigInt(dl), q = N / D, m = N % D;
      r[0] = Number(q & 0xffffffffn); r[1] = Number(q >> 32n); r[2] = Number(m & 0xffffffffn); r[3] = Number(m >> 32n);
    });

    // ---- libpng 1.2.46 png_read_filter_row(png_ptr, row_info, row, prev_row, filter): undoes one row's PNG filter
    // row_info: width u32 @0, rowbytes u32 @4, color_type @8, bit_depth @9, channels @10, pixel_depth @11
    hook('png_read_filter_row', () => {
      const info = r[1] >>> 0, row = r[2] >>> 0, prev = r[3] >>> 0, filter = cpu.r32(r[13] >>> 0);
      const rowbytes = cpu.r32(info + 4) >>> 0, bpp = (u8[info + 11] + 7) >> 3;
      switch (filter) {
        case 0: break;
        case 1: for (let i = bpp; i < rowbytes; i++) u8[row + i] = u8[row + i] + u8[row + i - bpp]; break;
        case 2: for (let i = 0; i < rowbytes; i++) u8[row + i] = u8[row + i] + u8[prev + i]; break;
        case 3:
          for (let i = 0; i < bpp; i++) u8[row + i] = u8[row + i] + (u8[prev + i] >> 1);
          for (let i = bpp; i < rowbytes; i++) u8[row + i] = u8[row + i] + ((u8[prev + i] + u8[row + i - bpp]) >> 1);
          break;
        case 4:
          for (let i = 0; i < bpp; i++) u8[row + i] = u8[row + i] + u8[prev + i];
          for (let i = bpp; i < rowbytes; i++) {
            const a = u8[row + i - bpp], b = u8[prev + i], c = u8[prev + i - bpp];
            const p = b - c, q = a - c, pa = p < 0 ? -p : p, pb = q < 0 ? -q : q, s = p + q, pc = s < 0 ? -s : s;
            u8[row + i] = u8[row + i] + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c);
          }
          break;
        default: return false; // "Ignoring bad adaptive filter type": the original warns
      }
    });

    // ---- zlib 1.2.3 inflate_fast(strm, start): the inner loop that unpacks zip data
    // z_stream: next_in @0, avail_in @4, next_out @12, avail_out @16, state @28
    // inflate_state: mode @0, wsize @40, whave @44, write @48, window @52, hold @56, bits @60, lencode @76, distcode @80,
    // lenbits @84, distbits @88; a code is 4 bytes: op u8, bits u8, val u16. TYPE = 11.
    // Bad data: nothing is saved and the original runs (it writes the same bytes again and sets the right error message).
    hook('inflate_fast', () => {
      const strm = r[0] >>> 0, start = r[1] >>> 0, st = cpu.r32(strm + 28) >>> 0, R = (a) => cpu.r32(a) >>> 0;
      let inp = R(strm), out = R(strm + 12);
      const availIn = R(strm + 4), availOut = R(strm + 16);
      const last = inp + availIn - 5, beg = out - (start - availOut), end = out + availOut - 257;
      const wsize = R(st + 40), whave = R(st + 44), write = R(st + 48), win = R(st + 52);
      let hold = R(st + 56), bits = R(st + 60);
      const lcode = R(st + 76), dcode = R(st + 80), lmask = (1 << R(st + 84)) - 1, dmask = (1 << R(st + 88)) - 1;
      let toType = false;
      do {
        if (bits < 15) { hold += u8[inp++] << bits; bits += 8; hold += u8[inp++] << bits; bits += 8; hold >>>= 0; }
        let here = lcode + ((hold & lmask) << 2);
        for (;;) { // dolen
          let op = u8[here + 1];
          hold >>>= op; bits -= op;
          op = u8[here];
          if (op === 0) { u8[out++] = u8[here + 2]; break; }
          if (op & 16) {
            let len = u8[here + 2] | (u8[here + 3] << 8);
            op &= 15;
            if (op) {
              if (bits < op) { hold = (hold + (u8[inp++] << bits)) >>> 0; bits += 8; }
              len += hold & ((1 << op) - 1); hold >>>= op; bits -= op;
            }
            if (bits < 15) { hold += u8[inp++] << bits; bits += 8; hold += u8[inp++] << bits; bits += 8; hold >>>= 0; }
            let dh = dcode + ((hold & dmask) << 2);
            for (;;) { // dodist
              op = u8[dh + 1];
              hold >>>= op; bits -= op;
              op = u8[dh];
              if (op & 16) {
                let dist = u8[dh + 2] | (u8[dh + 3] << 8);
                op &= 15;
                if (bits < op) { hold = (hold + (u8[inp++] << bits)) >>> 0; bits += 8; if (bits < op) { hold = (hold + (u8[inp++] << bits)) >>> 0; bits += 8; } }
                dist += hold & ((1 << op) - 1);
                hold >>>= op; bits -= op;
                op = out - beg;
                let from;
                if (dist > op) { // copy from the window
                  op = dist - op;
                  if (op > whave) return false; // "invalid distance too far back"
                  from = win;
                  if (write === 0) {
                    from += wsize - op;
                    if (op < len) { len -= op; do u8[out++] = u8[from++]; while (--op); from = out - dist; }
                  } else if (write < op) {
                    from += wsize + write - op; op -= write;
                    if (op < len) {
                      len -= op; do u8[out++] = u8[from++]; while (--op);
                      from = win;
                      if (write < len) { op = write; len -= op; do u8[out++] = u8[from++]; while (--op); from = out - dist; }
                    }
                  } else {
                    from += write - op;
                    if (op < len) { len -= op; do u8[out++] = u8[from++]; while (--op); from = out - dist; }
                  }
                  while (len > 2) { u8[out++] = u8[from++]; u8[out++] = u8[from++]; u8[out++] = u8[from++]; len -= 3; }
                  if (len) { u8[out++] = u8[from++]; if (len > 1) u8[out++] = u8[from++]; }
                } else { // copy direct from the output
                  from = out - dist;
                  do { u8[out++] = u8[from++]; u8[out++] = u8[from++]; u8[out++] = u8[from++]; len -= 3; } while (len > 2);
                  if (len) { u8[out++] = u8[from++]; if (len > 1) u8[out++] = u8[from++]; }
                }
                break;
              }
              if ((op & 64) === 0) { dh = dcode + (((u8[dh + 2] | (u8[dh + 3] << 8)) + (hold & ((1 << op) - 1))) << 2); continue; }
              return false; // "invalid distance code"
            }
            break;
          }
          if ((op & 64) === 0) { here = lcode + (((u8[here + 2] | (u8[here + 3] << 8)) + (hold & ((1 << op) - 1))) << 2); continue; }
          if (op & 32) { toType = true; break; } // end of block
          return false; // "invalid literal/length code"
        }
        if (toType) break;
      } while (inp < last && out < end);
      // give back the whole bytes not used yet, and save
      const back = bits >>> 3;
      inp -= back; bits -= back << 3; hold = bits ? (hold & ((1 << bits) - 1)) >>> 0 : 0;
      if (toType) cpu.w32(st, 11);
      cpu.w32(strm, inp); cpu.w32(strm + 12, out);
      cpu.w32(strm + 4, inp < last ? 5 + (last - inp) : 5 - (inp - last));
      cpu.w32(strm + 16, out < end ? 257 + (end - out) : 257 - (out - end));
      cpu.w32(st + 56, hold); cpu.w32(st + 60, bits);
    });
    // ---- code without a name of its own: checked byte by byte first, so another build of the app is never touched
    const at = (off, words, fn) => {
      const a = lib.base + (off & ~1);
      for (let i = 0; i < words.length; i++) if ((cpu.r32(a + (i << 2)) >>> 0) !== words[i]) { log('fast: code at ' + off.toString(16) + ' is not what was expected'); return; }
      cpu.hooks.set((a & ~1) | (off & 1), fn); n++;
    };
    // __sync_fetch_and_add_4 / __sync_fetch_and_sub_4 (libgcc, over the kernel's cmpxchg): the use counts of every std::string
    at(0x6cfb94, [0xe92d40f8, 0xe59f6028, 0xe1a05000, 0xe1a07001], () => { const p = r[0] >>> 0, old = cpu.r32(p); cpu.w32(p, old + r[1]); r[0] = old; });
    at(0x6cfbcc, [0xe92d40f8, 0xe59f6028, 0xe1a05000, 0xe1a07001], () => { const p = r[0] >>> 0, old = cpu.r32(p); cpu.w32(p, old - r[1]); r[0] = old; });
    // CCImage::_initWithPngData, the loop that multiplies red, green and blue by alpha (CC_RGB_PREMULTIPLY_ALPHA) for an RGBA
    // picture. Starts at 0x528782 (r6 = the image, r5 = the row pointers), goes on at 0x5287ea like the original after it.
    at(0x528783, [0x230069f4, 0xe02246ac, 0x18b0683e], () => {
      const img = r[6] >>> 0, rows = r[5] >>> 0, height = cpu.r16(img + 0x16), rowbytes = cpu.r32((r[13] >>> 0) + 0x18) >>> 0;
      let o = cpu.r32(img + 0x1c) >>> 0;
      const u32 = cpu.u32;
      for (let y = 0; y < height; y++) {
        const row = cpu.r32(rows + (y << 2)) >>> 0;
        for (let x = 0; x < rowbytes; x += 4) {
          const p = row + x, a1 = u8[p + 3] + 1;
          const v = ((u8[p] * a1) >>> 8) | ((u8[p + 1] * a1) & 0xffffff00) | (((u8[p + 2] * a1) >> 8) << 16) | (u8[p + 3] << 24);
          if (o & 3) cpu.w32(o, v); else u32[o >>> 2] = v >>> 0;
          o += 4;
        }
      }
      u8[img + 0x21] = 1;
      r[4] = o; r[3] = img + 2; r[2] = 1; r[12] = rows;
      return (lib.base + 0x5287ea) | 1;
    });
    return n;
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = hookFast; else root.EmuHookFast = hookFast;
})(typeof window !== 'undefined' ? window : globalThis);
