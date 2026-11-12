// Hello Bro web client: a small 2D engine that draws the game's own CocosBuilder layouts (.ccbi, turned into JSON by
// tools/build_webclient.js) with the game's own sprite sheets and fonts, on an HTML canvas. It copies the parts of cocos2d-x 2
// the game uses: nodes (y up, anchor points), sprites, 9-slice sprites, TTF and bitmap-font labels, buttons, colour layers,
// scroll views, CCB timelines, and taps. No outside library.
'use strict';
const HB = (window.HB = window.HB || {});
HB.ASSETS = 'assets/';

// ---------------------------------------------------------------- matrices (a b c d e f, like canvas setTransform)
const M = {
  mul: (p, q) => [p[0] * q[0] + p[2] * q[1], p[1] * q[0] + p[3] * q[1], p[0] * q[2] + p[2] * q[3], p[1] * q[2] + p[3] * q[3],
    p[0] * q[4] + p[2] * q[5] + p[4], p[1] * q[4] + p[3] * q[5] + p[5]],
  inv: (m) => { const d = m[0] * m[3] - m[1] * m[2] || 1e-9; return [m[3] / d, -m[1] / d, -m[2] / d, m[0] / d, (m[2] * m[5] - m[3] * m[4]) / d, (m[1] * m[4] - m[0] * m[5]) / d]; },
  apply: (m, x, y) => [m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5]],
};
HB.M = M;

// ---------------------------------------------------------------- loading
const cache = new Map();
const once = (key, fn) => { if (!cache.has(key)) cache.set(key, fn()); return cache.get(key); };
const norm = (p) => String(p || '').replace(/\\/g, '/').replace(/^\/+/, '');
HB.json = (p) => once('j:' + p, () => fetch(HB.ASSETS + norm(p)).then((r) => (r.ok ? r.json() : null)).catch(() => null));
HB.image = (p) => once('i:' + p, () => new Promise((ok) => {
  const img = new Image();
  img.onload = () => ok(img);
  img.onerror = () => { console.warn('missing picture', p); ok(null); };
  img.src = HB.ASSETS + norm(p).replace(/\.pvr\.ccz$/i, '.pvr.png').replace(/\.pvr$/i, '.pvr.png');
}));
HB.sheets = {}; // plist path -> { img, frames }
HB.loadSheet = (plist) => once('s:' + plist, async () => {
  const j = await HB.json(norm(plist).replace(/\.plist$/i, '.json'));
  if (!j) { console.warn('missing sheet', plist); return (HB.sheets[plist] = { img: null, frames: {} }); }
  const dir = norm(plist).includes('/') ? norm(plist).replace(/\/[^/]*$/, '/') : '';
  const img = await HB.image(dir + j.tex);
  return (HB.sheets[plist] = { img, frames: j.frames });
});
// a sprite frame: { img, x, y, w, h, rot, ox, oy, sw, sh } (x,y,w,h in the picture; sw,sh = untrimmed size; ox,oy = offset, y up)
HB.frame = (plist, name, quiet) => {
  if (plist === undefined && quiet) { for (const o of Object.values(HB.sheets)) { const g = o.frames[name]; if (g && o.img) return { img: o.img, x: g[0], y: g[1], w: g[2], h: g[3], rot: g[4], ox: g[5], oy: g[6], sw: g[7], sh: g[8] }; } return null; }
  if (!plist) { // a plain picture file instead of a sheet
    const img = HB.images[norm(name)];
    if (img && !(img.naturalWidth > 0)) return HB.frameOfImage(name); // still loading: its size follows when it arrives
    return img ? { img, x: 0, y: 0, w: img.width, h: img.height, rot: 0, ox: 0, oy: 0, sw: img.width, sh: img.height } : null;
  }
  const s = HB.sheets[plist], f = s && s.frames[name];
  if (!f || !s.img) {
    for (const o of Object.values(HB.sheets)) { const g = o.frames[name]; if (g && o.img) return { img: o.img, x: g[0], y: g[1], w: g[2], h: g[3], rot: g[4], ox: g[5], oy: g[6], sw: g[7], sh: g[8] }; }
    // the layout names a sheet that does not exist (experience.plist): the frame's real sheet from the index
    if (!quiet && HB.frameIndex !== undefined && HB.frameByName) { if (!HB.frameIndex) HB.frameIndex = HB.jsonNow('frames.json') || {}; const sh = HB.frameIndex[name]; if (sh && sh !== plist) { HB.loadSheetNow(sh); return HB.frame(sh, name, true); } }
    return null;
  }
  const rot = f[4] && !(s.img.naturalWidth === f[2] && s.img.naturalHeight === f[3]) ? 1 : 0; // "rotated" on a picture that is upright (background_02)
  return { img: s.img, x: f[0], y: f[1], w: f[2], h: f[3], rot, ox: f[5], oy: f[6], sw: f[7], sh: f[8] };
};
HB.images = {};
HB.loadImage = async (p) => (HB.images[norm(p)] = await HB.image(p));
HB.fonts = {};
function parseFnt(txt, p, loadPage) {
  const f = { chars: {}, kern: {}, line: 20, base: 16, pages: [] };
  const dir = norm(p).includes('/') ? norm(p).replace(/\/[^/]*$/, '/') : '';
  const kv = (l) => Object.fromEntries([...l.matchAll(/(\w+)=("[^"]*"|\S+)/g)].map((m) => [m[1], m[2].replace(/"/g, '')]));
  const pages = [];
  for (const l of txt.split(/\r?\n/)) {
    const k = kv(l);
    if (l.startsWith('common')) { f.line = +k.lineHeight; f.base = +k.base; }
    else if (l.startsWith('page')) pages[+k.id] = dir + k.file;
    else if (l.startsWith('char ')) f.chars[+k.id] = { x: +k.x, y: +k.y, w: +k.width, h: +k.height, xo: +k.xoffset, yo: +k.yoffset, adv: +k.xadvance, page: +k.page || 0 };
    else if (l.startsWith('kerning ')) f.kern[k.first + ',' + k.second] = +k.amount;
  }
  f.pages = pages.map((pg) => loadPage(pg));
  return f;
}
HB.loadFnt = (p) => once('f:' + p, async () => {
  const txt = await fetch(HB.ASSETS + norm(p)).then((r) => (r.ok ? r.text() : '')).catch(() => '');
  const f = { chars: {}, kern: {}, line: 20, base: 16, pages: [] };
  const dir = norm(p).includes('/') ? norm(p).replace(/\/[^/]*$/, '/') : '';
  const kv = (l) => Object.fromEntries([...l.matchAll(/(\w+)=("[^"]*"|\S+)/g)].map((m) => [m[1], m[2].replace(/"/g, '')]));
  const pages = [];
  for (const l of txt.split(/\r?\n/)) {
    const k = kv(l);
    if (l.startsWith('common')) { f.line = +k.lineHeight; f.base = +k.base; }
    else if (l.startsWith('page')) pages[+k.id] = dir + k.file;
    else if (l.startsWith('char ')) f.chars[+k.id] = { x: +k.x, y: +k.y, w: +k.width, h: +k.height, xo: +k.xoffset, yo: +k.yoffset, adv: +k.xadvance, page: +k.page || 0 };
    else if (l.startsWith('kerning ')) f.kern[k.first + ',' + k.second] = +k.amount;
  }
  f.pages = await Promise.all(pages.map((pg) => HB.image(pg)));
  return (HB.fonts[p] = f);
});

// collect every sheet, font, picture and sub-layout a layout needs, load them, then the layout can be built at once
HB.loadCCB = (file) => once('c:' + file, async () => {
  const name = norm(file).replace(/\.ccbi?$/i, '');
  const doc = await HB.json(name + '.json');
  if (!doc) { console.warn('missing layout', file); return null; }
  const jobs = [];
  const walk = (n) => {
    for (const [k, v] of Object.entries(n.p)) {
      if (Array.isArray(v) && typeof v[0] === 'string' && typeof v[1] === 'string' && /Frame|displayFrame/i.test(k)) jobs.push(v[0] ? HB.loadSheet(v[0]) : HB.loadImage(v[1]));
      else if (k === 'fntFile' && v) jobs.push(HB.loadFnt(v));
      else if ((k === 'ccbFile' || k === 'container') && v) jobs.push(HB.loadCCB(v));
      else if (k === 'texture' && v) jobs.push(HB.loadImage(v));
    }
    for (const a of Object.values(n.a || {})) for (const pr of Object.values(a)) for (const key of pr.k) if (pr.t === 10) jobs.push(key[1][0] ? HB.loadSheet(key[1][0]) : HB.loadImage(key[1][1]));
    for (const c of n.k || []) walk(c);
  };
  walk(doc.root);
  await Promise.all(jobs);
  doc.file = name.split('/').pop().toUpperCase(); // texts are found by NAME_FILE (tools/build_webclient.js buildStrings)
  return (HB.docs[name] = doc);
});
HB.docs = {};
// loading right away (the Lua scripts expect a layout the moment they ask for it): JSON by a synchronous request, pictures start
// loading and are drawn once they arrive
const jsonNow = (p) => {
  const key = 'J:' + p;
  if (cache.has(key)) return cache.get(key);
  let v = null;
  try { const x = new XMLHttpRequest(); x.open('GET', HB.ASSETS + norm(p), false); x.send(); if (x.status === 200) v = JSON.parse(x.responseText); } catch (e) { v = null; }
  cache.set(key, v);
  return v;
};
HB.jsonNow = jsonNow;
const imageNow = (p) => {
  const key = 'N:' + p;
  if (cache.has(key)) return cache.get(key);
  const img = new Image();
  img.onerror = () => console.warn('missing picture', p);
  img.src = HB.ASSETS + norm(p).replace(/\.pvr\.ccz$/i, '.pvr.png').replace(/\.pvr$/i, '.pvr.png');
  cache.set(key, img);
  return img;
};
HB.imageNow = imageNow;
HB.frameIndex = null; // frame name -> its sheet (assets/frames.json, tools/build_webclient.js)
HB.loadSheetNow = (plist) => {
  if (HB.sheets[plist]) return HB.sheets[plist];
  const j = jsonNow(norm(plist).replace(/\.plist$/i, '.json'));
  if (!j) return (HB.sheets[plist] = { img: null, frames: {} });
  const dir = norm(plist).includes('/') ? norm(plist).replace(/\/[^/]*$/, '/') : '';
  return (HB.sheets[plist] = { img: imageNow(dir + j.tex), frames: j.frames });
};
// a frame by its name only (CCSpriteFrameCache::spriteFrameByName): from a loaded sheet, else its sheet is loaded now
HB.frameByName = (name) => {
  name = norm(name);
  const f = HB.frame(undefined, name, true);
  if (f) return f;
  if (!HB.frameIndex) HB.frameIndex = jsonNow('frames.json') || {};
  const sheet = HB.frameIndex[name];
  if (sheet) { HB.loadSheetNow(sheet); return HB.frame(sheet, name); }
  if (/\.(png|jpg|pvr\.ccz)$/i.test(name)) { HB.images[name] = HB.images[name] || imageNow(name); return HB.frameOfImage(name); }
  return null;
};
// a whole picture as a frame (its size is known once it has loaded)
HB.frameOfImage = (name) => {
  const img = HB.images[norm(name)] || (HB.images[norm(name)] = imageNow(name));
  const f = { img, x: 0, y: 0, rot: 0, ox: 0, oy: 0 };
  Object.defineProperties(f, { w: { get: () => img.naturalWidth || 0 }, h: { get: () => img.naturalHeight || 0 }, sw: { get: () => img.naturalWidth || 0 }, sh: { get: () => img.naturalHeight || 0 } });
  return f;
};
HB.loadFntNow = (p) => {
  if (HB.fonts[p]) return HB.fonts[p];
  let txt = '';
  try { const x = new XMLHttpRequest(); x.open('GET', HB.ASSETS + norm(p), false); x.send(); if (x.status === 200) txt = x.responseText; } catch (e) { /* none */ }
  return (HB.fonts[p] = parseFnt(txt, p, imageNow));
};
HB.loadCCBNow = (file) => {
  const name = norm(file).replace(/\.ccbi?$/i, '');
  if (HB.docs[name]) return HB.docs[name];
  const doc = jsonNow(name + '.json');
  if (!doc) { console.warn('missing layout', file); return null; }
  const pic = (f) => { HB.images[norm(f)] = HB.images[norm(f)] || imageNow(f); };
  const walk = (n) => {
    for (const [k, v] of Object.entries(n.p)) {
      if (Array.isArray(v) && typeof v[0] === 'string' && typeof v[1] === 'string' && /Frame|displayFrame/i.test(k)) { if (v[0]) HB.loadSheetNow(v[0]); else pic(v[1]); }
      else if (k === 'fntFile' && v) HB.loadFntNow(v);
      else if ((k === 'ccbFile' || k === 'container') && v) HB.loadCCBNow(v);
      else if (k === 'texture' && v) pic(v);
    }
    for (const a of Object.values(n.a || {})) for (const pr of Object.values(a)) for (const key of pr.k) if (pr.t === 10) { if (key[1][0]) HB.loadSheetNow(key[1][0]); else pic(key[1][1]); }
    for (const c of n.k || []) walk(c);
  };
  walk(doc.root);
  doc.file = name.split('/').pop().toUpperCase();
  return (HB.docs[name] = doc);
};

// texts: HB.text('TEXT_LABEL_LOGINVIEW1_LOGINVIEW') (a layout label's English text), HB.ui(25) / HB.menu(5) (the game's string tables)
HB.strings = { ui: {}, menu: {}, uiById: {} };
HB.loadStrings = async () => { HB.strings = (await HB.json('strings.json')) || HB.strings; };
HB.text = (key) => HB.strings.ui[key];
HB.ui = (id) => HB.strings.uiById[id] ?? '';
HB.menu = (id) => HB.strings.menu[id] ?? '';

// ---------------------------------------------------------------- tinting (cocos multiplies a sprite's colour into its picture)
const tintCache = new Map();
let canvasIds = 0; // a canvas has no address: its own number keeps two of them apart in the cache
const ready = (img) => img && (img.complete === undefined || (img.complete && img.naturalWidth > 0)); // an Image still loading draws next frame
HB.ready = ready;
function tinted(img, sx, sy, sw, sh, rot, col) {
  if (!ready(img)) return null;
  const key = (img.src || (img._id = img._id || 'c' + ++canvasIds)) + '|' + sx + ',' + sy + ',' + sw + ',' + sh + ',' + rot + '|' + col.join(',');
  let c = tintCache.get(key);
  if (c) return c;
  const W = rot ? sh : sw, H = rot ? sw : sh;
  c = document.createElement('canvas'); c.width = Math.max(1, W); c.height = Math.max(1, H);
  const g = c.getContext('2d');
  g.drawImage(img, sx, sy, W, H, 0, 0, W, H);
  if (col[0] !== 255 || col[1] !== 255 || col[2] !== 255) {
    g.globalCompositeOperation = 'multiply'; g.fillStyle = `rgb(${col[0]},${col[1]},${col[2]})`; g.fillRect(0, 0, W, H);
    g.globalCompositeOperation = 'destination-in'; g.drawImage(img, sx, sy, W, H, 0, 0, W, H);
  }
  if (tintCache.size > 3000) tintCache.clear();
  tintCache.set(key, c);
  return c;
}
const white = (c) => !c || (c[0] === 255 && c[1] === 255 && c[2] === 255);

// ---------------------------------------------------------------- nodes
class Node {
  constructor() {
    Object.assign(this, { x: 0, y: 0, w: 0, h: 0, ax: 0, ay: 0, sx: 1, sy: 1, rot: 0, visible: true, opacity: 255, color: [255, 255, 255],
      z: 0, ignoreAnchor: false, children: [], parent: null, tag: -1, name: '', cascade: false, blend: '' });
  }
  add(c, z) { if (c.parent) c.parent.remove(c); if (z !== undefined) c.z = z; c.parent = this; this.children.push(c); return c; }
  remove(c) { const i = this.children.indexOf(c); if (i >= 0) this.children.splice(i, 1); c.parent = null; }
  removeSelf() { if (this.parent) this.parent.remove(this); }
  removeAll() { for (const c of this.children) c.parent = null; this.children = []; }
  find(name) { for (const c of this.children) { if (c.name === name) return c; const f = c.find(name); if (f) return f; } return null; }
  setSize(w, h) { this.w = w; this.h = h; }
  local() {
    const r = -this.rot * Math.PI / 180, cs = Math.cos(r), sn = Math.sin(r);
    let m = [cs * this.sx, sn * this.sx, -sn * this.sy, cs * this.sy, this.x, this.y];
    if (!this.ignoreAnchor) m = M.mul(m, [1, 0, 0, 1, -this.ax * this.w, -this.ay * this.h]);
    return m;
  }
  world() { return this.parent ? M.mul(this.parent.world(), this.local()) : this.local(); }
  toLocal(px, py) { return M.apply(M.inv(this.world()), px, py); }
  hit(px, py) { const [u, v] = this.toLocal(px, py); return u >= 0 && v >= 0 && u <= this.w && v <= this.h; }
  shown() { for (let n = this; n; n = n.parent) if (!n.visible) return false; return true; }
  visit(ctx, pm, alpha) {
    if (!this.visible) return;
    const m = (this._wm = M.mul(pm, this.local()));
    const a = alpha * this.opacity / 255;
    const kids = this.children.length > 1 ? this.children.slice().sort((p, q) => p.z - q.z) : this.children;
    const ka = this.cascade ? a : alpha;
    let i = 0;
    for (; i < kids.length && kids[i].z < 0; i++) kids[i].visit(ctx, m, ka);
    if (this.draw && a > 0) { ctx.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]); ctx.globalAlpha = a; if (this.blend) ctx.globalCompositeOperation = this.blend; if (this.grey) ctx.filter = 'grayscale(1)'; this.draw(ctx); if (this.grey) ctx.filter = 'none'; if (this.blend) ctx.globalCompositeOperation = 'source-over'; }
    if (this.clip) {
      ctx.save(); ctx.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]); ctx.beginPath(); ctx.rect(0, 0, this.w, this.h); ctx.clip();
      for (; i < kids.length; i++) kids[i].visit(ctx, m, ka);
      ctx.restore();
    } else for (; i < kids.length; i++) kids[i].visit(ctx, m, ka);
  }
  // draw a picture region into the box (dx,dy,dw,dh) given with y up (cocos), flipping it upright on the canvas
  static img(ctx, src, sx, sy, sw, sh, dx, dy, dw, dh) {
    if (!src || dw <= 0 || dh <= 0) return;
    ctx.save(); ctx.translate(dx, dy + dh); ctx.scale(1, -1); ctx.drawImage(src, sx, sy, sw, sh, 0, 0, dw, dh); ctx.restore();
  }
}
HB.Node = Node;

class LayerColor extends Node {
  draw(ctx) { ctx.fillStyle = `rgb(${this.color[0]},${this.color[1]},${this.color[2]})`; ctx.fillRect(0, 0, this.w, this.h); }
}
HB.LayerColor = LayerColor;

class Sprite extends Node {
  constructor(frame) { super(); this.ax = this.ay = 0.5; this.flipX = this.flipY = false; if (frame) this.setFrame(frame); }
  setFrame(f) { this.frame = f; if (f) { this.w = f.sw; this.h = f.sh; } }
  setFrameName(plist, name) { this.setFrame(HB.frame(plist, name)); }
  draw(ctx) {
    const f = this.frame;
    if (!f || !f.img) return;
    if (!this.w && !this.h && f.sw) { this.w = f.sw; this.h = f.sh; }
    const src = tinted(f.img, f.x, f.y, f.w, f.h, f.rot, this.color);
    if (!src) return;
    const dx = (f.sw - f.w) / 2 + f.ox, dy = (f.sh - f.h) / 2 + f.oy;
    ctx.save();
    if (this.flipX || this.flipY) { ctx.translate(this.flipX ? this.w : 0, this.flipY ? this.h : 0); ctx.scale(this.flipX ? -1 : 1, this.flipY ? -1 : 1); }
    ctx.translate(dx, dy + f.h); ctx.scale(1, -1); // now y down, the trimmed box at (0,0,w,h)
    if (f.rot) { ctx.translate(0, f.h); ctx.rotate(-Math.PI / 2); ctx.drawImage(src, 0, 0, f.h, f.w); } // stored turned a quarter clockwise
    else ctx.drawImage(src, 0, 0, f.w, f.h);
    ctx.restore();
  }
}
HB.Sprite = Sprite;

// 9-slice sprite (CCScale9Sprite): corners keep their size, edges and centre stretch
class Scale9 extends Node {
  constructor(frame) { super(); this.ax = this.ay = 0.5; this.insets = [0, 0, 0, 0]; this.frame = frame; this.cascade = true; if (frame) { this.w = frame.w; this.h = frame.h; } }
  draw(ctx) {
    const f = this.frame;
    if (!f || !f.img) return;
    const src = tinted(f.img, f.x, f.y, f.w, f.h, f.rot, this.color);
    if (!src) return;
    let fw = f.w, fh = f.h, [L, T, R, B] = this.insets;
    let cw = fw - L - R, ch = fh - T - B; // capInsets centre
    if (L === 0 && T === 0 && R === 0 && B === 0) { L = R = fw / 3; T = B = fh / 3; cw = fw / 3; ch = fh / 3; }
    let up = src;
    if (f.rot) { up = document.createElement('canvas'); up.width = fw; up.height = fh; const g = up.getContext('2d'); g.translate(0, fh); g.rotate(-Math.PI / 2); g.drawImage(src, 0, 0, fh, fw); f.rot = 0; f.img = up; f.x = f.y = 0; }
    const W = this.w, H = this.h;
    let l = L, r = R, t = T, b = B;
    if (l + r > W) { const k = W / (l + r); l *= k; r *= k; }
    if (t + b > H) { const k = H / (t + b); t *= k; b *= k; }
    const sxs = [0, L, L + cw], sws = [L, cw, R], dxs = [0, l, W - r], dws = [l, W - l - r, r];
    const sys = [0, T, T + ch], shs = [T, ch, B], dys = [0, t, H - b], dhs = [t, H - t - b, b];
    ctx.save(); ctx.translate(0, H); ctx.scale(1, -1); // y down
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      if (sws[i] <= 0 || shs[j] <= 0 || dws[i] <= 0 || dhs[j] <= 0) continue;
      ctx.drawImage(up, sxs[i], sys[j], sws[i], shs[j], dxs[i], dys[j], dws[i] + (i < 2 ? 0.5 : 0), dhs[j] + (j < 2 ? 0.5 : 0));
    }
    ctx.restore();
  }
}
HB.Scale9 = Scale9;

// TTF label (CCLabelTTF): the system font, wrapped inside `dims` when it has a width
// The layouts name iPhone fonts (Arial-BoldMT, Helvetica). The Android game has none of them and draws every label in the phone's own
// font, regular weight (seen on the phone: the chapter names are not bold). Same here: one regular sans-serif for all of them.
const SANS = '1px Roboto, "Helvetica Neue", "Segoe UI", Arial, sans-serif';
const FONT = { 'Arial-BoldMT': SANS, ArialMT: SANS, Helvetica: SANS, 'Helvetica-Bold': SANS, 'Arial-BoldItalicMT': SANS };
const measure = document.createElement('canvas').getContext('2d');
class Label extends Node {
  constructor(text = '', font = 'Helvetica', size = 20, dims = [0, 0], ha = 0, va = 0) {
    super(); this.ax = this.ay = 0.5;
    Object.assign(this, { font, size, dims, ha, va, stroke: null, shadow: null }); this.setText(text);
  }
  css() { return (FONT[this.font] || SANS).replace('1px', this.size + 'px'); }
  setText(t) {
    this.text = String(t ?? '');
    measure.font = this.css();
    const maxW = this.dims[0] > 0 ? this.dims[0] : Infinity, lines = [];
    for (const para of this.text.split('\n')) {
      if (maxW === Infinity) { lines.push(para); continue; }
      let cur = '';
      for (const ch of para.match(/\S+\s*|\s+/g) || ['']) { // break between words; very long words break by letter
        if (measure.measureText(cur + ch).width <= maxW || !cur) cur += ch;
        else { lines.push(cur.trimEnd()); cur = ch; }
        while (measure.measureText(cur).width > maxW && cur.length > 1) { let k = cur.length - 1; while (k > 1 && measure.measureText(cur.slice(0, k)).width > maxW) k--; lines.push(cur.slice(0, k)); cur = cur.slice(k); }
      }
      lines.push(cur.trimEnd());
    }
    this.lines = lines;
    this.lh = Math.round(this.size * 1.2);
    const tw = Math.ceil(Math.max(0, ...lines.map((l) => measure.measureText(l).width)));
    this.w = this.dims[0] > 0 ? this.dims[0] : tw;
    this.h = this.dims[1] > 0 ? this.dims[1] : lines.length * this.lh;
    return this;
  }
  draw(ctx) {
    ctx.save(); ctx.translate(0, this.h); ctx.scale(1, -1);
    ctx.font = this.css(); ctx.textBaseline = 'top';
    ctx.textAlign = ['left', 'center', 'right'][this.ha] || 'left';
    const x = this.ha === 1 ? this.w / 2 : this.ha === 2 ? this.w : 0;
    const total = this.lines.length * this.lh;
    let y = this.va === 1 ? (this.h - total) / 2 : this.va === 2 ? this.h - total : 0;
    y += (this.lh - this.size) / 2;
    for (const l of this.lines) {
      if (this.stroke) { ctx.lineWidth = this.stroke[1] * 2; ctx.strokeStyle = this.stroke[0]; ctx.lineJoin = 'round'; ctx.strokeText(l, x, y); }
      if (this.shadow) { ctx.fillStyle = this.shadow; ctx.fillText(l, x + 1, y + 1); }
      ctx.fillStyle = `rgb(${this.color[0]},${this.color[1]},${this.color[2]})`; ctx.fillText(l, x, y); y += this.lh;
    }
    ctx.restore();
  }
}
HB.Label = Label;

// bitmap-font label (CCLabelBMFont): the game's own number fonts
class BMLabel extends Node {
  constructor(fnt, text = '') { super(); this.ax = this.ay = 0.5; this.fnt = fnt; this.align = 0; this.setText(text); }
  setText(t) {
    this.text = String(t ?? '');
    const f = HB.fonts[this.fnt];
    if (!f) { this.w = 0; this.h = 0; return this; }
    let x = 0, prev = 0, w = 0, lines = 1;
    for (const ch of this.text) {
      const c = ch.codePointAt(0);
      if (c === 10) { w = Math.max(w, x); x = 0; lines++; continue; }
      const g = f.chars[c]; if (!g) continue;
      x += (f.kern[prev + ',' + c] || 0) + g.adv; prev = c;
    }
    this.w = Math.max(w, x); this.h = f.line * lines;
    return this;
  }
  draw(ctx) {
    const f = HB.fonts[this.fnt];
    if (!f) return;
    ctx.save(); ctx.translate(0, this.h); ctx.scale(1, -1);
    let x = 0, y = 0, prev = 0;
    for (const ch of this.text) {
      const c = ch.codePointAt(0);
      if (c === 10) { x = 0; y += f.line; continue; }
      const g = f.chars[c]; if (!g) continue;
      x += f.kern[prev + ',' + c] || 0; prev = c;
      const page = f.pages[g.page];
      if (page && g.w > 0 && ready(page)) ctx.drawImage(white(this.color) ? page : tinted(page, g.x, g.y, g.w, g.h, 0, this.color), white(this.color) ? g.x : 0, white(this.color) ? g.y : 0, g.w, g.h, x + g.xo, y + g.yo, g.w, g.h);
      x += g.adv;
    }
    ctx.restore();
  }
}
HB.BMLabel = BMLabel;

// button (CCControlButton): a 9-slice background per state, a title, grows a little while pressed
class Button extends Node {
  constructor() {
    super(); this.ax = this.ay = 0.5; this.cascade = true;
    Object.assign(this, { frames: {}, titles: {}, titleColors: {}, titleFont: 'Helvetica', titleSize: 12, labelAnchor: [0.5, 0.5], pref: [0, 0],
      zoom: true, enabled: true, pressed: false, selected: false, insets: [0, 0, 0, 0], onTap: null });
    this.bg = this.add(new Scale9(null)); this.bg.ax = this.bg.ay = 0.5;
    this.label = this.add(new Label('', 'Helvetica', 12)); this.label.z = 1;
  }
  state() { return !this.enabled ? 3 : this.pressed || this.selected ? 2 : 1; }
  layout() {
    const s = this.state();
    const fr = this.frames[s] || this.frames[1];
    this.label.font = this.titleFont; this.label.size = this.titleSize;
    this.label.setText(this.titles[s] ?? this.titles[1] ?? '');
    this.label.color = this.titleColors[s] || this.titleColors[1] || [255, 255, 255];
    const w = Math.max(this.label.w + 16, this.pref[0]), h = Math.max(this.label.h + 4, this.pref[1]);
    this.w = w; this.h = h;
    this.bg.frame = fr; this.bg.insets = this.insets; this.bg.w = w; this.bg.h = h; this.bg.x = w / 2; this.bg.y = h / 2;
    this.label.x = w * this.labelAnchor[0]; this.label.y = h * this.labelAnchor[1];
  }
  setTitle(t, s = 1) { this.titles[s] = t; this.layout(); }
  setEnabled(on) { this.enabled = on; this.layout(); }
  press(on) { if (!this.enabled) return; this.pressed = on; if (this.zoom) this.bg.sx = this.bg.sy = this.label.sx = this.label.sy = on ? 1.1 : 1; this.layout(); }
}
HB.Button = Button;

// scroll view (CCScrollView): its content scrolls by dragging, clipped to its box
class ScrollView extends Node {
  constructor() { super(); this.clip = true; this.dir = 1; this.content = this.add(new Node()); this.bounce = true; }
  setContent(n) { this.content.removeSelf(); this.content = this.add(n); n.ignoreAnchor = true; this.toTop(); }
  toTop() { const c = this.content; c.x = 0; c.y = Math.min(0, this.h - c.h * c.sy); }
  limits() { const c = this.content; return { minX: Math.min(0, this.w - c.w * c.sx), maxX: 0, minY: Math.min(0, this.h - c.h * c.sy), maxY: Math.max(0, this.h - c.h * c.sy) > 0 ? this.h - c.h * c.sy : 0 }; }
  scrollBy(dx, dy) {
    const L = this.limits(), c = this.content;
    if (this.dir !== 1) c.x = Math.max(L.minX, Math.min(L.maxX, c.x + dx));
    if (this.dir !== 0) c.y = Math.max(L.minY, Math.min(L.maxY, c.y + dy));
  }
}
HB.ScrollView = ScrollView;

// ---------------------------------------------------------------- building a layout from its JSON
// owner collects named nodes: owner.n.<name> (the last one with that name) and owner.all.<name> (all of them), and gets button taps
// through owner.onButton(selector, node)
HB.build = function build(file, owner = {}, parentSize) {
  const name = norm(file).replace(/\.ccbi?$/i, '');
  const doc = HB.docs[name];
  if (!doc) { console.warn('layout not loaded', file); return new Node(); }
  owner.n = owner.n || {}; owner.all = owner.all || {};
  const root = makeNode(doc.root, parentSize || HB.size, owner, doc);
  root.doc = doc;
  if (doc.auto >= 0) HB.play(root, doc.auto);
  return root;
};
function pos(v, ps) {
  const [x, y, t] = v;
  switch (t) {
    case 1: return [x, ps[1] - y];
    case 2: return [ps[0] - x, ps[1] - y];
    case 3: return [ps[0] - x, y];
    case 4: return [ps[0] * x / 100, ps[1] * y / 100];
    default: return [x, y];
  }
}
function size(v, ps) {
  const [w, h, t] = v;
  switch (t) {
    case 1: return [ps[0] * w / 100, ps[1] * h / 100];
    case 2: return [ps[0] - w, ps[1] - h];
    case 3: return [ps[0] * w / 100, h];
    case 4: return [w, ps[1] * h / 100];
    default: return [w, h];
  }
}
const frameOf = (v) => (v ? HB.frame(v[0], v[1]) : null);
function makeNode(j, ps, owner, doc) {
  const p = j.p;
  let n;
  switch (j.c) {
    case 'CCSprite': n = new Sprite(frameOf(p.displayFrame)); break;
    case 'CCScale9Sprite': n = new Scale9(frameOf(p.spriteFrame)); n.insets = [p.insetLeft || 0, p.insetTop || 0, p.insetRight || 0, p.insetBottom || 0];
      if (!p.anchorPoint) n.ax = n.ay = 0; // CCB leaves it out for these: CCNode's (0,0) (the Event window's frame, Home's side bars)
      break;
    case 'CCLabelTTF': n = new Label('', p.fontName || 'Helvetica', p.fontSize ? p.fontSize[0] : 20, p.dimensions ? size(p.dimensions, ps) : [0, 0], p.horizontalAlignment || 0, p.verticalAlignment || 0); break;
    case 'CCLabelBMFont': n = new BMLabel(p.fntFile); break;
    case 'CCLayerColor': n = new LayerColor(); break;
    case 'CCControlButton': n = new Button(); break;
    case 'CCScrollView': n = new ScrollView(); break;
    case 'CCMenuItemImage': n = new Button(); n.frames = { 1: frameOf(p.normalSpriteFrame), 2: frameOf(p.selectedSpriteFrame), 3: frameOf(p.disabledSpriteFrame) }; break;
    case 'CCBFile': {
      const sub = norm(p.ccbFile || '').replace(/\.ccbi?$/i, '');
      const d = HB.docs[sub];
      n = d ? makeNode(d.root, ps, owner, d) : new Node();
      if (d) { n.doc = d; if (d.auto >= 0) HB.play(n, d.auto); }
      if (p.position) [n.x, n.y] = pos(p.position, ps);
      if (p.scale) { n.sx = p.scale[0]; n.sy = p.scale[1]; }
      if (p.rotation !== undefined) n.rot = p.rotation;
      if (p.visible !== undefined) n.visible = p.visible;
      if (p.tag !== undefined) n.tag = p.tag;
      if (j.n) { n.name = j.n; owner.n[j.n] = n; (owner.all[j.n] = owner.all[j.n] || []).push(n); }
      return n;
    }
    default: n = j.c === 'CCLayer' ? new Node() : new Node(); if (j.c === 'CCLayer') n.isLayer = true;
  }
  n.cls = j.c;
  if (p.contentSize) [n.w, n.h] = size(p.contentSize, ps);
  if (p.anchorPoint) [n.ax, n.ay] = p.anchorPoint;
  if (j.c === 'CCLayer' || j.c === 'CCLayerColor') { if (!p.anchorPoint) n.ax = n.ay = 0; if (p.ignoreAnchorPointForPosition === undefined) n.ignoreAnchor = true; }
  if (p.ignoreAnchorPointForPosition !== undefined) n.ignoreAnchor = p.ignoreAnchorPointForPosition;
  if (p.position) { [n.x, n.y] = pos(p.position, ps); n._posType = p.position[2]; }
  if (p.scale) { n.sx = p.scale[0]; n.sy = p.scale[1]; }
  if (p.rotation !== undefined) n.rot = p.rotation;
  if (p.visible !== undefined) n.visible = p.visible;
  if (p.tag !== undefined) n.tag = p.tag;
  if (p.opacity !== undefined) n.opacity = p.opacity;
  if (p.color) n.color = p.color;
  if (p.blendFunc && p.blendFunc[1] === 1) n.blend = 'lighter';
  if (p.flip && n instanceof Sprite) { n.flipX = p.flip[0]; n.flipY = p.flip[1]; }
  if (n instanceof Scale9 && p.preferedSize) [n.w, n.h] = size(p.preferedSize, ps);
  if (n instanceof Label) n.setText((j.n && HB.text('TEXT_' + j.n.toUpperCase() + '_' + doc.file)) ?? p.string ?? '');
  if (n instanceof BMLabel) n.setText(p.string || '');
  if (n instanceof Button && j.c === 'CCControlButton') {
    for (const s of [1, 2, 3]) {
      if (p['backgroundSpriteFrame|' + s]) n.frames[s] = frameOf(p['backgroundSpriteFrame|' + s]);
      if (p['title|' + s] !== undefined) n.titles[s] = p['title|' + s];
      if (p['titleColor|' + s]) n.titleColors[s] = p['titleColor|' + s];
    }
    n.titleFont = p['titleTTF|1'] || 'Helvetica'; n.titleSize = p['titleTTFSize|1'] ? p['titleTTFSize|1'][0] : 12;
    if (p.labelAnchorPoint) n.labelAnchor = p.labelAnchorPoint;
    if (p.preferedSize) n.pref = size(p.preferedSize, ps);
    if (p.zoomOnTouchDown !== undefined) n.zoom = p.zoomOnTouchDown;
    if (p.enabled !== undefined) n.enabled = p.enabled;
    if (p.ccControl) n.selector = p.ccControl[0];
    const bt = j.n && HB.text('BTN_TEXT_' + j.n.toUpperCase() + '_' + doc.file);
    if (bt != null) n.titles[1] = bt;
    n.layout();
  }
  if (j.c === 'CCMenuItemImage') { if (p.block) n.selector = p.block[0]; n.layout(); }
  if (n instanceof ScrollView) {
    n.dir = p.direction ?? 1; n.clip = p.clipsToBounds !== false;
    if (p.container) { const sub = norm(p.container).replace(/\.ccbi?$/i, ''); if (HB.docs[sub]) n.setContent(makeNode(HB.docs[sub].root, [n.w, n.h], owner, HB.docs[sub])); }
  }
  if (j.a) n.anims = j.a;
  if (j.n) { n.name = j.n; owner.n[j.n] = n; (owner.all[j.n] = owner.all[j.n] || []).push(n); }
  if (n.selector) n.owner = owner;
  const cs = [n.w, n.h];
  for (const c of j.k || []) n.add(makeNode(c, cs, owner, doc));
  return n;
}

// ---------------------------------------------------------------- CCB timelines (the layouts' own animations)
const timelines = new Set();
const EASE = {
  0: () => 0, 1: (t) => t, 2: (t, r = 2) => Math.pow(t, r), 3: (t, r = 2) => Math.pow(t, 1 / r),
  4: (t, r = 2) => (t *= 2) < 1 ? 0.5 * Math.pow(t, r) : 1 - 0.5 * Math.pow(2 - t, r),
  8: (t) => 1 - EASE[9](1 - t), 9: (t) => t < 1 / 2.75 ? 7.5625 * t * t : t < 2 / 2.75 ? 7.5625 * (t -= 1.5 / 2.75) * t + 0.75 : t < 2.5 / 2.75 ? 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375 : 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375,
  11: (t) => t * t * (2.70158 * t - 1.70158), 12: (t) => (t -= 1) * t * (2.70158 * t + 1.70158) + 1,
};
EASE[5] = EASE[2]; EASE[6] = EASE[3]; EASE[7] = EASE[4]; EASE[10] = EASE[4]; EASE[13] = EASE[4];
HB.play = (root, seqId, done) => {
  const doc = root.doc;
  if (!doc) return;
  const seq = typeof seqId === 'string' ? doc.seqs.find((s) => s.name === seqId) : doc.seqs.find((s) => s.id === seqId);
  if (!seq) return;
  for (const t of timelines) if (t.root === root) timelines.delete(t);
  const nodes = [];
  const walk = (n) => { if (n.anims && n.anims[seq.id]) nodes.push(n); for (const c of n.children) if (c.doc !== doc || c === root) walk(c); else if (c.doc === doc) walk(c); };
  walk(root);
  timelines.add({ root, seq, doc, nodes, t: 0, done, cbDone: 0 });
};
function applyKey(n, prop, t, keys, ps) {
  let i = 0;
  while (i < keys.length - 1 && keys[i + 1][0] <= t) i++;
  const a = keys[i], b = keys[i + 1];
  let v = a[1];
  if (b && t > a[0] && a[2] !== 0) {
    const e = (EASE[a[2]] || EASE[1])((t - a[0]) / (b[0] - a[0] || 1), a[3]);
    if (Array.isArray(a[1]) && typeof a[1][0] === 'number') v = a[1].map((x, k) => x + (b[1][k] - x) * e);
    else if (typeof a[1] === 'number') v = a[1] + (b[1] - a[1]) * e;
  }
  switch (prop) {
    case 'position': { const ty = n._posType ?? 0; [n.x, n.y] = pos([v[0], v[1], ty], ps); break; }
    case 'scale': n.sx = v[0]; n.sy = v[1]; break;
    case 'rotation': n.rot = v; break;
    case 'opacity': n.opacity = v; break;
    case 'color': n.color = v.map(Math.round); break;
    case 'visible': n.visible = v; break;
    case 'displayFrame': if (n.setFrame) n.setFrame(HB.frame(v[0], v[1])); break;
  }
}
HB.tick = (dt) => {
  for (const tl of [...timelines]) {
    tl.t += dt;
    const t = Math.min(tl.t, tl.seq.dur);
    for (const n of tl.nodes) for (const [prop, pr] of Object.entries(n.anims[tl.seq.id])) applyKey(n, prop, t, pr.k, n.parent ? [n.parent.w, n.parent.h] : HB.size);
    if (tl.t >= tl.seq.dur) {
      timelines.delete(tl);
      if (tl.seq.next >= 0) HB.play(tl.root, tl.seq.next, tl.done);
      else if (tl.done) tl.done();
    }
  }
  for (const tw of [...tweens]) tw.step(dt);
  if (HB.actionTick) HB.actionTick(dt); // Lua actions (luabind.js)
  if (HB.luaTick) HB.luaTick(dt); // Lua update functions and timers
};

// small tweens for code-made movement: HB.tween(node, { x, y, sx, sy, opacity, rot }, seconds, then)
const tweens = new Set();
HB.tween = (n, to, dur, then, ease = (t) => t) => {
  const from = Object.fromEntries(Object.keys(to).map((k) => [k, n[k]]));
  const tw = { t: 0, step(dt) { this.t += dt; const e = ease(Math.min(1, this.t / dur)); for (const k in to) n[k] = from[k] + (to[k] - from[k]) * e; if (this.t >= dur) { tweens.delete(tw); if (then) then(); } } };
  tweens.add(tw);
  return tw;
};
HB.wait = (sec) => new Promise((ok) => HB.tween({}, {}, sec, ok));

// ---------------------------------------------------------------- the screen, drawing and taps
HB.start = (canvas) => {
  HB.canvas = canvas;
  const ctx = canvas.getContext('2d');
  HB.scene = new Node();
  const fit = () => {
    const vw = window.innerWidth, vh = window.innerHeight;
    let w = vw, h = vh;
    if (h / w < 1.5) w = Math.round(h / 1.78); // a computer or tablet held sideways: a phone-shaped game in the middle
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    canvas.style.width = w + 'px'; canvas.style.height = h + 'px';
    canvas.width = Math.round(w * dpr); canvas.height = Math.round(h * dpr);
    // the game's own rule (AppDelegate::applicationDidFinishLaunching): tall screens are 686 wide, others 768 x 1024
    HB.size = h / w > 1.5 ? [686, 686 * h / w] : [768, 1024];
    HB.scale = canvas.width / HB.size[0];
    HB.scene.w = HB.size[0]; HB.scene.h = HB.size[1];
    if (HB.onResize) HB.onResize();
  };
  fit();
  window.addEventListener('resize', fit);
  let last = performance.now();
  const frame = (now) => {
    const dt = Math.min(0.1, (now - last) / 1000); last = now;
    HB.tick(dt);
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1;
    ctx.fillStyle = '#000'; ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingQuality = 'high';
    HB.scene.visit(ctx, [HB.scale, 0, 0, -HB.scale, 0, canvas.height], 1);
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
  // taps: the top-most visible button (or a node with onTouch) under the finger; dragging moves scroll views
  const point = (e) => { const r = canvas.getBoundingClientRect(); return [(e.clientX - r.left) / r.width * HB.size[0], HB.size[1] - (e.clientY - r.top) / r.height * HB.size[1]]; };
  let down = null;
  canvas.addEventListener('pointerdown', (e) => {
    const [x, y] = point(e);
    if (HB.luaTouchLayers && HB.luaTouchLayers.size && HB.luaTouchBegan && HB.luaTouchBegan(x, y, e)) { down = { lua: true, x, y }; canvas.setPointerCapture(e.pointerId); return; }
    const target = pick(HB.scene, x, y);
    const scroll = scrollAt(HB.scene, x, y);
    down = { x, y, sx: x, sy: y, target, scroll, moved: false };
    if (target instanceof Button) { target.press(true); if (target.luaHandlers && HB.buttonEvent) HB.buttonEvent(target, 1); } // CCControlEventTouchDown
    if (target && target.onTouch) target.onTouch('down', x, y);
    canvas.setPointerCapture(e.pointerId);
  });
  canvas.addEventListener('pointermove', (e) => {
    if (!down) return;
    const [x, y] = point(e);
    if (down.lua) { HB.luaTouchMoved && HB.luaTouchMoved(x, y); return; }
    if (Math.hypot(x - down.sx, y - down.sy) > 12) {
      if (!down.moved && down.target instanceof Button && down.scroll) down.target.press(false);
      down.moved = true;
    }
    if (down.moved && down.scroll) down.scroll.scrollBy(x - down.x, y - down.y);
    if (down.target && down.target.onTouch) down.target.onTouch('move', x, y);
    down.x = x; down.y = y;
  });
  const up = (e, cancel) => {
    if (!down) return;
    const d = down; down = null;
    const [x, y] = point(e);
    if (d.lua) { HB.luaTouchEnded && HB.luaTouchEnded(x, y, cancel); return; }
    if (d.target instanceof Button) {
      const was = d.target.pressed;
      d.target.press(false);
      if (!cancel && was && d.target.hit(x, y) && !(d.moved && d.scroll)) tap(d.target);
    }
    if (d.target && d.target.onTouch) d.target.onTouch(cancel ? 'cancel' : 'up', x, y);
  };
  canvas.addEventListener('pointerup', (e) => up(e, false));
  canvas.addEventListener('pointercancel', (e) => up(e, true));
};
function tap(b) {
  HB.sound && HB.sound('click');
  if (b.onTap) return b.onTap(b);
  if (b.luaHandlers && HB.lua && HB.lua.buttonTap(b)) return; // a button made or bound by a Lua script
  if (b.owner && b.owner.onButton) return b.owner.onButton(b.selector, b);
  console.log('button without action', b.selector, b.name);
}
function inClip(n, x, y) { for (let p = n.parent; p; p = p.parent) if (p.clip && !p.hit(x, y)) return false; return true; }
function pick(n, x, y) {
  if (!n.visible) return null;
  const kids = n.children.slice().sort((p, q) => p.z - q.z);
  for (let i = kids.length - 1; i >= 0; i--) { const r = pick(kids[i], x, y); if (r) return r; }
  if ((n instanceof Button && n.enabled) || n.onTouch || n.swallow) return n.hit(x, y) && inClip(n, x, y) ? (n.swallow && !(n instanceof Button) && !n.onTouch ? n : n) : null;
  return null;
}
function scrollAt(n, x, y) {
  if (!n.visible) return null;
  for (let i = n.children.length - 1; i >= 0; i--) { const r = scrollAt(n.children[i], x, y); if (r) return r; }
  return n instanceof ScrollView && n.hit(x, y) && inClip(n, x, y) ? n : null;
}
HB.tapNode = tap;
