// Builds the web client's game files (server/webclient/assets/, git-ignored) from the original game files in re/obb
// (made by `python -I tools/setup_re.py`). Nothing is drawn new: every picture, layout and font is the game's own.
//   node tools/build_webclient.js          only files that changed
//   node tools/build_webclient.js --all    everything again
// What it makes:
//   *.pvr.ccz (encrypted sprite sheets, tools/pvrccz.py)  -> same path, .pvr.png
//   *.plist (sprite sheet frame lists)                    -> same path, .json  { tex, frames: { name: [x,y,w,h,rot,ox,oy,sw,sh] } }
//   *.ccbi (CocosBuilder layouts, tools/ccbi.py)          -> same path, .json  { seqs, auto, root: { c, n, t, p, a, k } }
//   server/cdn/src (our hot-update files) is laid over re/obb, like on the phones
//   *.png, *.fnt, *.mp3, *.wav, *.lua, *.xml               -> copied as they are
'use strict';
const fs = require('fs'), path = require('path'), zlib = require('zlib');

const ROOT = path.join(__dirname, '..');
const SRC = path.join(ROOT, 're', 'obb');
const HOT = path.join(ROOT, 'server', 'cdn', 'src'); // our hot-update files (English texts, fixes) win over the originals
const OUT = path.join(ROOT, 'server', 'webclient', 'assets');
const ALL = process.argv.includes('--all');

// ---------- encrypted sprite sheets (.pvr.ccz, 'CCZp'), same key and steps as tools/pvrccz.py ----------
const KEY = [0xf013c6ef, 0x5ca560ce, 0x01471215, 0xca9bada1];
const KS = (() => {
  const k = new Uint32Array(1024);
  let s = 0, z = k[1023], rounds = 6;
  const mx = (y, z, p, e) => ((((z >>> 5) ^ (y << 2)) + ((y >>> 3) ^ (z << 4))) ^ ((s ^ y) + (KEY[(p & 3) ^ e] ^ z))) >>> 0;
  while (rounds--) {
    s = (s + 0x9e3779b9) >>> 0;
    const e = (s >>> 2) & 3;
    for (let p = 0; p < 1023; p++) { const y = k[p + 1]; k[p] = (k[p] + mx(y, z, p, e)) >>> 0; z = k[p]; }
    const y = k[0]; k[1023] = (k[1023] + mx(y, z, 1023, e)) >>> 0; z = k[1023];
  }
  return k;
})();
function decryptCcz(buf) {
  if (buf.toString('latin1', 0, 4) === 'CCZ!') return zlib.inflateSync(buf.subarray(16)); // a few sheets are not encrypted
  if (buf.toString('latin1', 0, 4) !== 'CCZp') throw new Error('not a ccz sprite sheet');
  const n = (buf.length - 12) >> 2;
  let b = 0, i = 0;
  const xor = (i) => buf.writeUInt32LE((buf.readUInt32LE(12 + 4 * i) ^ KS[b]) >>> 0, 12 + 4 * i);
  while (i < n && i < 512) { xor(i); b = (b + 1) % 1024; i++; }
  while (i < n) { xor(i); b = (b + 1) % 1024; i += 64; }
  return zlib.inflateSync(buf.subarray(16));
}
function pvrToRgba(pvr) {
  let fmt, w, h, start;
  if (pvr.toString('latin1', 0, 4) === 'PVR\x03') {
    const lo = pvr.readUInt32LE(8), hi = pvr.readUInt32LE(12);
    h = pvr.readUInt32LE(24); w = pvr.readUInt32LE(28); start = 52 + pvr.readUInt32LE(48);
    fmt = { '8888': 0x12, '4444': 0x10, '5551': 0x11, '565': 0x13, '888': 0x15, '8': 0x1b }[
      hi === 0x08080808 && lo === 0x61626772 ? '8888' : hi === 0x04040404 && lo === 0x61626772 ? '4444' : hi === 0x01050505 ? '5551' :
      hi === 0x00050605 ? '565' : hi === 0x00080808 ? '888' : lo === 0x61 && hi === 0x08 ? '8' : '?'] || ('v3:' + hi.toString(16) + ':' + lo.toString(16));
  } else {
    start = pvr.readUInt32LE(0); h = pvr.readUInt32LE(4); w = pvr.readUInt32LE(8); fmt = pvr.readUInt32LE(16) & 0xff;
  }
  const px = pvr.subarray(start), out = Buffer.alloc(w * h * 4), N = w * h;
  switch (fmt) {
    case 0x12: px.copy(out, 0, 0, N * 4); break;
    case 0x1a: for (let i = 0; i < N; i++) { out[4 * i] = px[4 * i + 2]; out[4 * i + 1] = px[4 * i + 1]; out[4 * i + 2] = px[4 * i]; out[4 * i + 3] = px[4 * i + 3]; } break;
    case 0x10: for (let i = 0; i < N; i++) { const c = px[2 * i] | px[2 * i + 1] << 8; out[4 * i] = (c >> 12 & 15) * 17; out[4 * i + 1] = (c >> 8 & 15) * 17; out[4 * i + 2] = (c >> 4 & 15) * 17; out[4 * i + 3] = (c & 15) * 17; } break;
    case 0x11: for (let i = 0; i < N; i++) { const c = px[2 * i] | px[2 * i + 1] << 8; out[4 * i] = (c >> 11 & 31) * 255 / 31 | 0; out[4 * i + 1] = (c >> 6 & 31) * 255 / 31 | 0; out[4 * i + 2] = (c >> 1 & 31) * 255 / 31 | 0; out[4 * i + 3] = (c & 1) * 255; } break;
    case 0x13: for (let i = 0; i < N; i++) { const c = px[2 * i] | px[2 * i + 1] << 8; out[4 * i] = (c >> 11 & 31) * 255 / 31 | 0; out[4 * i + 1] = (c >> 5 & 63) * 255 / 63 | 0; out[4 * i + 2] = (c & 31) * 255 / 31 | 0; out[4 * i + 3] = 255; } break;
    case 0x15: for (let i = 0; i < N; i++) { out[4 * i] = px[3 * i]; out[4 * i + 1] = px[3 * i + 1]; out[4 * i + 2] = px[3 * i + 2]; out[4 * i + 3] = 255; } break;
    case 0x16: for (let i = 0; i < N; i++) { out[4 * i] = out[4 * i + 1] = out[4 * i + 2] = px[i]; out[4 * i + 3] = 255; } break;
    case 0x17: for (let i = 0; i < N; i++) { out[4 * i] = out[4 * i + 1] = out[4 * i + 2] = px[2 * i]; out[4 * i + 3] = px[2 * i + 1]; } break;
    case 0x1b: for (let i = 0; i < N; i++) { out[4 * i] = out[4 * i + 1] = out[4 * i + 2] = 255; out[4 * i + 3] = px[i]; } break;
    default: throw new Error('pixel format ' + fmt + ' not handled');
  }
  return { w, h, rgba: out };
}
function png(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4); }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type, 'latin1'), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(zlib.crc32(td) >>> 0);
    return Buffer.concat([len, td, crc]);
  };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 6 })), chunk('IEND', Buffer.alloc(0))]);
}

// ---------- sprite sheet frame lists (.plist, TexturePacker format 1-3) ----------
function plistValue(xml, i) { // returns [value, nextIndex]; a tiny parser for the dict/string/integer/real/true/false the sheets use
  const re = /<(\/?)(dict|key|string|integer|real|true|false|array)(\/?)>/g;
  re.lastIndex = i;
  const m = re.exec(xml);
  if (!m) return [undefined, xml.length];
  const tag = m[2];
  if (m[3] === '/' || tag === 'true' || tag === 'false') {
    if (tag === 'true' || tag === 'false') { const end = m[3] === '/' ? re.lastIndex : xml.indexOf('</' + tag + '>', re.lastIndex) + tag.length + 3; return [tag === 'true', end]; }
    return [tag === 'string' ? '' : tag === 'dict' ? {} : tag === 'array' ? [] : 0, re.lastIndex];
  }
  if (tag === 'dict') {
    const o = {}; let j = re.lastIndex;
    for (;;) {
      const k = /<key>([\s\S]*?)<\/key>|<\/dict>/g; k.lastIndex = j;
      const km = k.exec(xml);
      if (!km || km[0] === '</dict>') return [o, km ? k.lastIndex : xml.length];
      const [v, nj] = plistValue(xml, k.lastIndex);
      o[km[1].replace(/&amp;/g, '&')] = v; j = nj;
    }
  }
  if (tag === 'array') {
    const a = []; let j = re.lastIndex;
    for (;;) {
      const close = xml.indexOf('</array>', j), next = xml.indexOf('<', j);
      if (next === close) return [a, close + 8];
      const [v, nj] = plistValue(xml, j); a.push(v); j = nj;
    }
  }
  const end = xml.indexOf('</' + tag + '>', re.lastIndex);
  const text = xml.slice(re.lastIndex, end).replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
  return [tag === 'integer' || tag === 'real' ? Number(text) : text, end + tag.length + 3];
}
const nums = (s) => String(s || '').match(/-?[\d.]+/g)?.map(Number) || [];
function convertPlist(xml) {
  const root = plistValue(xml, xml.indexOf('<dict>'))[0];
  if (!root || !root.frames) return null; // not a sprite sheet (particles etc.)
  const meta = root.metadata || {}, fmt = meta.format || 0, frames = {};
  for (const [name, f] of Object.entries(root.frames)) {
    let r;
    if (fmt === 3) {
      const [x, y, w, h] = nums(f.textureRect), [ox, oy] = nums(f.spriteOffset), [sw, sh] = nums(f.spriteSourceSize);
      r = [x, y, w, h, f.textureRotated ? 1 : 0, ox, oy, sw, sh];
    } else if (fmt === 0) {
      r = [f.x, f.y, f.width, f.height, 0, f.offsetX || 0, f.offsetY || 0, f.originalWidth || f.width, f.originalHeight || f.height];
    } else {
      const [x, y, w, h] = nums(f.frame), [ox, oy] = nums(f.offset), [sw, sh] = nums(f.sourceSize);
      r = [x, y, w, h, f.rotated ? 1 : 0, ox || 0, oy || 0, sw || w, sh || h];
    }
    frames[name] = r;
  }
  return { tex: meta.textureFileName || meta.realTextureFileName || '', frames };
}

// ---------- CocosBuilder layouts (.ccbi v5), the same reading as tools/ccbi.py plus the animation keyframes ----------
function parseCcbi(d) {
  let p = 0, bit = 0;
  const getbit = () => { const b = (d[p] >> bit) & 1; if (++bit >= 8) { bit = 0; p++; } return b; };
  const align = () => { if (bit) { bit = 0; p++; } };
  const int = (signed) => {
    let n = 0; while (!getbit()) n++;
    let cur = 0; for (let a = n - 1; a >= 0; a--) if (getbit()) cur |= 1 << a;
    cur |= 1 << n; align();
    return signed ? (cur % 2 ? (cur >> 1) : -(cur >> 1)) : cur - 1;
  };
  const byte = () => d[p++];
  const float = () => {
    const t = byte();
    if (t < 4) return [0, 1, -1, 0.5][t];
    if (t === 4) return int(true);
    const v = d.readFloatLE(p); p += 4; return Math.round(v * 1e4) / 1e4;
  };
  const utf8 = () => { const n = (byte() << 8) | byte(); const s = d.toString('utf8', p, p + n); p += n; return s; };
  if (d.toString('latin1', 0, 4) !== 'ibcc') throw new Error('not a ccbi');
  p = 4;
  const version = int(false), js = byte();
  const strs = []; for (let i = int(false); i > 0; i--) strs.push(utf8());
  const cstr = () => strs[int(false)];
  const seqs = [];
  for (let i = int(false); i > 0; i--) {
    const s = { dur: float(), name: cstr(), id: int(false), next: int(true), cb: [], snd: [] };
    for (let j = int(false); j > 0; j--) s.cb.push([float(), cstr(), int(false)]);
    for (let j = int(false); j > 0; j--) s.snd.push([float(), cstr(), float(), float(), float()]);
    seqs.push(s);
  }
  const auto = int(true);
  const value = (t) => {
    switch (t) {
      case 0: case 1: return [float(), float(), int(false)];
      case 2: case 3: case 27: return [float(), float()];
      case 4: return [float(), float(), int(false)];
      case 5: case 7: return float();
      case 6: case 20: return int(true);
      case 8: return [float(), float()];
      case 9: return !!byte();
      case 10: return [cstr(), cstr()];
      case 11: case 17: case 18: case 19: case 23: case 24: return cstr();
      case 12: return byte();
      case 13: return [byte(), byte(), byte()];
      case 14: return Array.from({ length: 8 }, float);
      case 15: return [!!byte(), !!byte()];
      case 16: return [int(false), int(false)];
      case 21: return [cstr(), int(false)];
      case 22: return [cstr(), cstr()];
      case 25: return [cstr(), int(false), int(false)];
      case 26: return [float(), int(false)];
    }
    throw new Error('unknown property type ' + t);
  };
  const keyValue = (t) => {
    switch (t) {
      case 9: return !!byte();
      case 12: return byte();
      case 13: return [byte(), byte(), byte()];
      case 5: return float();
      case 0: case 3: case 4: case 27: return [float(), float()];
      case 10: return [cstr(), cstr()];
    }
    throw new Error('keyframe type ' + t);
  };
  const node = () => {
    const n = { c: cstr(), p: {} };
    if (js) cstr();
    const at = int(false);
    if (at) { n.n = cstr(); n.t = at; }
    const anim = {};
    for (let i = int(false); i > 0; i--) {
      const seq = int(false), props = {};
      for (let j = int(false); j > 0; j--) {
        const name = cstr(), t = int(false), keys = [];
        for (let k = int(false); k > 0; k--) {
          const time = float(), easing = int(false), opt = easing >= 2 && easing <= 7 ? float() : undefined;
          keys.push([time, keyValue(t), easing, opt]);
        }
        props[name] = { t, k: keys };
      }
      anim[seq] = props;
    }
    if (Object.keys(anim).length) n.a = anim;
    const count = int(false) + int(false);
    for (let i = 0; i < count; i++) {
      const t = int(false), name = cstr(); byte();
      n.p[name] = value(t);
    }
    const kids = int(false);
    if (kids) { n.k = []; for (let i = 0; i < kids; i++) n.k.push(node()); }
    return n;
  };
  const root = node();
  if (p !== d.length) throw new Error(`did not end at the end of the file (${p} of ${d.length})`);
  return { v: version, seqs, auto, root };
}

// ---------- walk re/obb ----------
const COPY = new Set(['.bin', '.png', '.fnt', '.mp3', '.wav', '.lua', '.xml', '.jpg', '.json']);
const stats = { png: 0, plist: 0, ccbi: 0, copy: 0, skip: 0, fail: [] };
function newer(src, dst) {
  if (ALL || src.startsWith(HOT)) return true; // hot-update files are few: always laid over again
  if (!src.startsWith(HOT) && fs.existsSync(path.join(HOT, path.relative(SRC, src)))) return false; // a hot-update copy replaces it
  try { return fs.statSync(dst).mtimeMs < fs.statSync(src).mtimeMs; } catch { return true; }
}
function write(dst, data) { fs.mkdirSync(path.dirname(dst), { recursive: true }); fs.writeFileSync(dst, data); }
function walk(dir, base = SRC) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const src = path.join(dir, ent.name);
    if (ent.isDirectory()) { walk(src, base); continue; }
    const rel = path.relative(base, src);
    const low = ent.name.toLowerCase();
    try {
      if (low.endsWith('.pvr.ccz')) {
        const dst = path.join(OUT, rel.slice(0, -4) + '.png'); // x.pvr.ccz -> x.pvr.png (a plain x.png can sit next to it)
        if (!newer(src, dst)) { stats.skip++; continue; }
        const { w, h, rgba } = pvrToRgba(decryptCcz(Buffer.from(fs.readFileSync(src))));
        write(dst, png(w, h, rgba)); stats.png++;
      } else if (low.endsWith('.plist')) {
        const dst = path.join(OUT, rel.slice(0, -6) + '.json');
        if (!newer(src, dst)) { stats.skip++; continue; }
        const j = convertPlist(fs.readFileSync(src, 'utf8'));
        if (j) {
          const dir = path.dirname(src), plain = j.tex.replace(/\.pvr\.ccz$/i, '.png'), stem = j.tex.replace(/\.(pvr\.ccz|png)$/i, '');
          const has = (f) => fs.existsSync(path.join(dir, f)) || fs.existsSync(path.join(HOT, path.relative(base, dir), f));
          // the frame list names the picture; when only the other kind exists, take that one (the game does the same)
          j.tex = /\.pvr\.ccz$/i.test(j.tex) ? (has(j.tex) ? stem + '.pvr.png' : plain) : (has(plain) ? plain : stem + '.pvr.png');
          write(dst, JSON.stringify(j)); stats.plist++;
        }
      } else if (low.endsWith('.ccbi')) {
        const dst = path.join(OUT, rel.slice(0, -5) + '.json');
        if (!newer(src, dst)) { stats.skip++; continue; }
        write(dst, JSON.stringify(parseCcbi(fs.readFileSync(src)))); stats.ccbi++;
      } else if (COPY.has(path.extname(low))) {
        const dst = path.join(OUT, rel);
        if (!newer(src, dst)) { stats.skip++; continue; }
        write(dst, fs.readFileSync(src)); stats.copy++;
      }
    } catch (e) { stats.fail.push(rel + ': ' + e.message); }
  }
}

// ---------- texts: a layout's label or button gets its English text by its member name (libgame.so GetStringFromMemberName /
// GetBtnStringFromMemberName: "STRING_UI_TEXT_" or "STRING_UI_BTN_TEXT_" + NAME_FILE in capitals -> a number, made by the giant
// InitSTRINGUICONST; the number is a row of Struct_String_UI). The English game keeps its English in the _zh tables.
function buildStrings() {
  const all = path.join(ROOT, 're', 'all.txt');
  const lines = fs.readFileSync(all, 'utf8').split('\n');
  const start = lines.findIndex((l) => l.startsWith('===== _Z17InitSTRINGUICONSTv'));
  if (start < 0) throw new Error('InitSTRINGUICONST not found in re/all.txt');
  const ids = {};
  let name = null, r3 = null;
  for (let i = start + 1; i < lines.length && !lines[i].startsWith('====='); i++) {
    const l = lines[i];
    let m;
    if ((m = l.match(/-> 0x[0-9a-f]+ '(STRING_UI_\w+)'/))) { name = m[1]; r3 = null; }
    else if ((m = l.match(/movs r3, #(0x[0-9a-f]+|\d+)/))) r3 = Number(m[1]);
    else if ((m = l.match(/ldr r3, \[pc, #0x[0-9a-f]+\]\s+; =(0x[0-9a-f]+)/))) r3 = Number(m[1]);
    else if ((m = l.match(/lsls r3, r3, #(0x[0-9a-f]+|\d+)/)) && r3 !== null) r3 = r3 * 2 ** Number(m[1]);
    else if ((m = l.match(/adds r3, #(0x[0-9a-f]+|\d+)/)) && r3 !== null) r3 += Number(m[1]);
    else if (/str r3, \[r1, #4\]/.test(l) && name) { ids[name] = r3; name = null; }
  }
  const table = (f) => { const t = {}; for (const r of JSON.parse(fs.readFileSync(path.join(ROOT, 'server', 'data', f), 'utf8')).rows) t[r[0]] = String(r[2] || '').replace(/\0+$/, ''); return t; };
  const ui = table('Struct_String_UI_zh.json'), menu = table('Struct_String_Menu_zh.json');
  const byName = {};
  for (const [k, id] of Object.entries(ids)) if (ui[id]) byName[k.replace(/^STRING_UI_/, '')] = ui[id];
  write(path.join(OUT, 'strings.json'), JSON.stringify({ ui: byName, menu, uiById: ui }));
  return Object.keys(byName).length;
}
// the game tables the server also uses (server/data, already public in the repo): names, pictures, levels ...
// plus assets/columns.json = each table's C++ field names (docs/TABLE-COLUMNS.md, from Struct_<Table>::InitMemberNames), for the
// scripts' DataMgr.GetDataByID("Struct_Ninjainfo", id).m_name
function copyTables() {
  let n = 0;
  const cols = {};
  let cur = null;
  for (const line of fs.readFileSync(path.join(ROOT, 'docs', 'TABLE-COLUMNS.md'), 'utf8').split(/\r?\n/)) {
    let m;
    if ((m = /^## (\S+)/.exec(line))) cur = cols[m[1]] = [];
    else if (cur && (m = /^\| (\d+) \| (m_\w+) \|/.exec(line))) cur[Number(m[1])] = m[2];
  }
  write(path.join(OUT, 'columns.json'), JSON.stringify(cols));
  for (const f of fs.readdirSync(path.join(ROOT, 'server', 'data'))) {
    if (!f.endsWith('.json') || /^Struct_String_/.test(f)) continue;
    write(path.join(OUT, 'data', f), fs.readFileSync(path.join(ROOT, 'server', 'data', f))); n++;
  }
  return n;
}

// the Lua scripts in one file (assets/lua.json: path -> source as bytes, laid over like the rest), and every sprite frame's sheet
// (assets/frames.json: frame name -> .plist), so a script can name a frame whose sheet is not loaded yet
function bundleLua() {
  const out = {};
  const walkLua = (d, base) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const f = path.join(d, e.name); if (e.isDirectory()) walkLua(f, base); else if (f.endsWith('.lua')) out[path.relative(base, f).split(path.sep).join('/')] = fs.readFileSync(f).toString('latin1'); } };
  walkLua(path.join(SRC, 'script'), SRC);
  if (fs.existsSync(path.join(HOT, 'script'))) walkLua(path.join(HOT, 'script'), HOT);
  write(path.join(OUT, 'lua.json'), JSON.stringify(out));
  return Object.keys(out).length;
}
function frameIndex() {
  const idx = {};
  const walkJ = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const f = path.join(d, e.name); if (e.isDirectory()) { if (e.name !== 'data') walkJ(f); } else if (f.endsWith('.json')) {
    let j; try { j = JSON.parse(fs.readFileSync(f, 'utf8')); } catch { continue; }
    if (!j || !j.frames || j.tex === undefined) continue;
    const plist = path.relative(OUT, f).split(path.sep).join('/').replace(/\.json$/, '.plist');
    for (const k of Object.keys(j.frames)) if (!(k in idx)) idx[k] = plist;
  } } };
  walkJ(OUT);
  write(path.join(OUT, 'frames.json'), JSON.stringify(idx));
  return Object.keys(idx).length;
}

// --emu: the three files the emulator route needs (server/webclient/emu runs the original app's own code): the app's code
// (re/libgame.so), an apk (its assets: baseconfig.json, the logo) and the data file (.obb, taken out of the .xapk on the Desktop)
function emuFiles() {
  const dst = path.join(OUT, 'emu');
  fs.mkdirSync(dst, { recursive: true });
  fs.copyFileSync(path.join(ROOT, 're', 'libgame.so'), path.join(dst, 'libgame.dat'));
  const apk = path.join(ROOT, 'release', 'HelloBro-for-127.0.0.1-18081.apk');
  if (fs.existsSync(apk)) fs.copyFileSync(apk, path.join(dst, 'game-apk.dat')); else console.log('  no ' + apk);
  const obb = path.join(ROOT, 're', 'emu', 'main.28.com.hello.bro.yo.obb');
  if (fs.existsSync(obb)) fs.copyFileSync(obb, path.join(dst, 'main-obb.dat')); else console.log('  no ' + obb + ' (unpack it from the .xapk: Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb)');
  fs.mkdirSync(path.join(dst, 'cdn'), { recursive: true });
  for (const f of fs.readdirSync(path.join(ROOT, 'server', 'cdn'))) if (f.endsWith('.zip')) fs.copyFileSync(path.join(ROOT, 'server', 'cdn', f), path.join(dst, 'cdn', f.replace(/.zip$/, '.dat'))); // the hot update
  console.log('emulator files copied to server/webclient/assets/emu');
}
if (require.main === module && process.argv.includes('--emu')) { emuFiles(); process.exit(0); }
if (require.main === module) {
  if (!fs.existsSync(SRC)) { console.error('re/obb is missing: run  python -I tools/setup_re.py  first'); process.exit(1); }
  const t0 = Date.now();
  walk(SRC);
  if (fs.existsSync(HOT)) walk(HOT, HOT);
  console.log(`texts: ${buildStrings()} layout labels and buttons; tables: ${copyTables()}; Lua scripts: ${bundleLua()}; sprite frames: ${frameIndex()}`);
  console.log(`web client files in server/webclient/assets: ${stats.png} sprite sheets, ${stats.plist} frame lists, ${stats.ccbi} layouts, ` +
    `${stats.copy} copied, ${stats.skip} unchanged, ${stats.fail.length} failed (${((Date.now() - t0) / 1000).toFixed(1)} s)`);
  for (const f of stats.fail.slice(0, 30)) console.log('  FAILED ' + f);
  if (stats.fail.length) process.exitCode = 1;
}
module.exports = { parseCcbi, convertPlist, decryptCcz, pvrToRgba };
