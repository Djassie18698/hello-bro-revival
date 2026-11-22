// English versions of the game's pictures that have Chinese words drawn INTO them, for the rewritten game only
// (server/webclient; the phone app keeps its own files). Each one is made from the game's own picture: the place of the Chinese
// words is painted over with what lies around it (a smooth patch between the patch's four edges) and the English is set on top
// in the colours and outline of the words it replaces. Rendered at double size by headless Chrome (tools/chrome_png.js), like the
// HD pictures, into server/webclient/ui/en/<name>.png (in git). server/webclient/pictures.js tells the engine to use them.
//   node tools/make_webclient_en.js [name filter]        needs server/webclient/assets (node tools/build_webclient.js, build_hd.js)
//   node tools/make_webclient_en.js --sheet              also a before / after board: re/en-pictures.png
// A picture = { name (the frame's name, or the file's path for a plain picture), from (its sheet, for a frame),
//   clear: true (start empty: the picture is words only), patch: [[x, y, w, h] ...] (painted over), plate: [[x, y, w, h, top colour,
//   bottom colour, softness] ...] (a soft plate in the background's colour, where the background has a pattern), fade (a patch
//   that runs out downward), text: [...] }.
// All places are in the ORIGINAL picture's pixels, y down. A text: { t, x, y (its middle), size, font, fill: [top, bottom],
//   stroke: [colour, width], glow: [colour, blur], align, spacing, stack: true (letters under each other, y = the first one's
//   middle, step = distance), squeeze (width factor) }.
const fs = require('fs'), path = require('path');
const { renderPng } = require('./chrome_png');
const ROOT = path.join(__dirname, '..'), A = path.join(ROOT, 'server/webclient/assets'), OUT = path.join(ROOT, 'server/webclient/ui/en');

const GOLD = ['#fff46b', '#ff9a14'], DARK = '#6a1a00';
const CREAM = ['#fff2b8', '#ffd66e'];
const LIME = ['#f6ff66', '#86d81c'];
const ribbon = (name, from, t, size, x = 57) => ({ name, from, plate: [[x - 48, 81.5, 96, 30, '#5c0909', '#4c0606', 1]], text: [{ t, x, y: 97.5, size, font: 'Nunito', weight: 800, fill: ['#ffeeb0', '#ffe08a'], stroke: ['#4a0500', 1.2] }] });
const PICTURES = [
  // ---- Lottery ticket (activity/LotteryTicketView and its two windows)
  { name: 'lottery_bg_title', from: 'ccbResources/lottery', plate: [[14, 13, 38, 47, '#1d3527', '#14261c', 2], [121, 13, 187, 47, '#1d3527', '#14261c', 2]], // 第 [n] 期忍村彩票
    text: [{ t: 'No.', x: 33, y: 37, size: 27, fill: GOLD, stroke: [DARK, 5], glow: ['#3a0d00', 3] }, { t: 'LOTTERY', x: 215, y: 37, size: 31, spacing: 3, fill: GOLD, stroke: [DARK, 5], glow: ['#3a0d00', 3] }] },
  { name: 'lottery_bg_6', from: 'ccbResources/lottery', plate: [[20, 92, 46, 152, '#17906f', '#128a66', 5]],  // the scroll: 本期下注
    text: [{ t: 'BETS', x: 43, y: 112, step: 37, stack: true, size: 36, fill: GOLD, stroke: [DARK, 6], glow: ['#3a0d00', 3] }] },
  { name: 'lottery_first', from: 'ccbResources/lottery', clear: true, text: [{ t: '1st Prize', x: 65, y: 22, size: 27, fill: GOLD, stroke: ['#5a2400', 5] }] },                 // 一等奖
  { name: 'lottery_second', from: 'ccbResources/lottery', clear: true, text: [{ t: '2nd Prize', x: 62.5, y: 23, size: 26, fill: ['#ffffff', '#b4b4b4'], stroke: ['#3d3424', 5] }] }, // 二等奖
  { name: 'lottery_third', from: 'ccbResources/lottery', clear: true, text: [{ t: '3rd Prize', x: 62.5, y: 23, size: 26, fill: ['#fff6e0', '#d6ae78'], stroke: ['#4a341c', 5] }] },  // 三等奖
  { name: 'lottery_open_time', from: 'ccbResources/lottery', clear: true, text: [{ t: 'This draw is at:', x: 233, y: 16, align: 'right', size: 24, fill: LIME, stroke: ['#141400', 4.5] }] }, // 本期彩票开奖时间：
  { name: 'lottery_get_time', from: 'ccbResources/lottery', clear: true, text: [{ t: 'Claim before:', x: 181, y: 16, align: 'right', size: 24, fill: LIME, stroke: ['#141400', 4.5] }] },     // 领奖截止时间：
  { name: 'lottery_end_time', from: 'ccbResources/lottery', clear: true, text: [{ t: 'Bets close:', x: 181, y: 16, align: 'right', size: 24, fill: LIME, stroke: ['#141400', 4.5] }] },       // 下注截止时间：
  { name: 'lottery_pre_winerList', from: 'ccbResources/lottery', patch: [[16, 14, 231, 35]], text: [{ t: 'Last 1st-prize winners', x: 131.5, y: 31.5, size: 21, fill: CREAM, stroke: ['#5a0c00', 4] }] }, // 上期一等奖中奖名单
  { name: 'lottery_cur_myNums', from: 'ccbResources/lottery', patch: [[14, 14, 156, 35]], text: [{ t: 'This round', x: 92, y: 31.5, size: 24, fill: CREAM, stroke: ['#5a0c00', 4] }] },                  // 本期投注号码
  { name: 'lottery_pre_myNums', from: 'ccbResources/lottery', patch: [[14, 14, 156, 35]], text: [{ t: 'Last round', x: 92, y: 31.5, size: 24, fill: CREAM, stroke: ['#5a0c00', 4] }] },                  // 上期投注号码
  // ---- the Event bar's round icons with a red ribbon
  ribbon('activity21', 'ccbResources/activity_btns_2', 'Lottery', 19, 60),        // 忍村彩票
  ribbon('activity35', 'ccbResources/activity_btns_3', 'Challenge', 17),          // 超忍挑战 (not run by our server)
  ribbon('activity45', 'ccbResources/activity_btns_3', 'Flip cards', 17),         // 翻牌充值 (not run by our server)
  // ---- Home's buttons (plain picture files)
  { name: 'ccbResources/activity_icon_8.png', fade: [[1, 45, 83, 26]],                                         // 七日目标: the 7-day goals pouch
    text: [{ t: '7-Day Goals', x: 42.5, y: 57.5, size: 15.5, fill: ['#ffff70', '#ffc21a'], stroke: ['#d81408', 4.5], glow: ['#ff2a10', 3] }] },
  { name: 'ccbResources/activity_icon_6.png', patch: [[35, 14, 38, 39]],                                       // 榜: the rank scroll
    text: [{ t: 'TOP', x: 54.5, y: 33.5, size: 17.5, fill: ['#ffe14a', '#ff8a12'], stroke: ['#7a3200', 3.6] }] },
  { name: 'ccbResources/activity_icon_2.png', patch: [[23, 61, 49, 17]],                                       // 30级
    text: [{ t: 'Lv.30', x: 47.5, y: 70, size: 16, fill: ['#ffffff', '#f2f2f2'], stroke: ['#2a2a2a', 3.4] }] },
];

const dataUrl = (file) => 'data:image/' + (file.endsWith('.webp') ? 'webp' : 'png') + ';base64,' + fs.readFileSync(file).toString('base64');
// the picture to start from: the HD one when there is one (then k = 2), and the frame's place in it
function source(p) {
  let file, rect = null, rot = 0;
  if (p.from) { const j = JSON.parse(fs.readFileSync(path.join(A, p.from + '.json'), 'utf8')); const f = j.frames[p.name]; if (!f) throw new Error('no frame ' + p.name);
    file = path.join(path.dirname(p.from), j.tex).replace(/\\/g, '/'); rect = [f[0], f[1], f[2], f[3]]; rot = f[4] ? 1 : 0; if (f[7] !== f[2] || f[8] !== f[3] || f[5] || f[6]) throw new Error(p.name + ' is trimmed: not handled'); }
  else file = p.name;
  const hd = path.join(A, 'hd', file + '.webp');
  return fs.existsSync(hd) ? { url: dataUrl(hd), k: 2, rect, rot } : { url: dataUrl(path.join(A, file)), k: 1, rect, rot };
}
const PAGE = (p, s) => `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito:wght@800;900&display=swap" rel="stylesheet">
<style>html,body{margin:0;background:transparent;overflow:hidden}canvas{display:block}</style></head><body><canvas id="c"></canvas><script>
const P = ${JSON.stringify(p)}, S = ${JSON.stringify({ k: s.k, rect: s.rect, rot: s.rot })};
const im = new Image();
im.onload = async () => {
  const r = S.rect || [0, 0, im.width / S.k, im.height / S.k], W = S.rot ? r[3] : r[2], H = S.rot ? r[2] : r[3];
  const c = document.getElementById('c'); c.width = W * 2; c.height = H * 2; const g = c.getContext('2d');
  window.SIZE = [W, H];
  if (!P.clear) { g.imageSmoothingQuality = 'high'; g.drawImage(im, r[0] * S.k, r[1] * S.k, r[2] * S.k, r[3] * S.k, 0, 0, W * 2, H * 2); }
  // paint a place over with a smooth patch between its four edges (a Coons patch of the pixels just outside it)
  const patch = (x0, y0, w, h, fade) => { x0 = Math.round(x0 * 2); y0 = Math.round(y0 * 2); w = Math.round(w * 2); h = Math.round(h * 2);
    const d = g.getImageData(x0 - 1, y0 - 1, w + 2, h + 2), a = d.data, at = (x, y) => (y * (w + 2) + x) * 4;
    // the edges are smoothed first (a noisy edge would be drawn out into stripes)
    const smooth = (len, get, set) => { const R = 7, src = []; for (let i = 0; i < len; i++) src.push(get(i)); for (let i = 0; i < len; i++) for (let k = 0; k < 4; k++) { let t = 0, n = 0; for (let j = Math.max(0, i - R); j <= Math.min(len - 1, i + R); j++) { t += src[j][k]; n++; } set(i, k, t / n); } };
    const px = (o) => [a[o], a[o + 1], a[o + 2], a[o + 3]];
    if (!fade) { smooth(w + 2, (i) => px(at(i, 0)), (i, k, v) => { a[at(i, 0) + k] = v; }); smooth(w + 2, (i) => px(at(i, h + 1)), (i, k, v) => { a[at(i, h + 1) + k] = v; });
      smooth(h + 2, (i) => px(at(0, i)), (i, k, v) => { a[at(0, i) + k] = v; }); smooth(h + 2, (i) => px(at(w + 1, i)), (i, k, v) => { a[at(w + 1, i) + k] = v; }); }
    const keep = g.getImageData(x0 - 1, y0 - 1, w + 2, h + 2).data;
    if (fade) for (let x = 0; x < w + 2; x++) for (let k = 0; k < 4; k++) a[at(x, h + 1) + k] = k === 3 ? 0 : a[at(x, 0) + k]; // fade: the lower edge is see-through
    for (let y = 1; y <= h; y++) for (let x = 1; x <= w; x++) { const u = x / (w + 1), v = y / (h + 1), o = at(x, y);
      for (let k = 0; k < 4; k++) { const T = a[at(x, 0) + k], B = a[at(x, h + 1) + k], L = a[at(0, y) + k], R = a[at(w + 1, y) + k];
        const c00 = a[at(0, 0) + k], c10 = a[at(w + 1, 0) + k], c01 = a[at(0, h + 1) + k], c11 = a[at(w + 1, h + 1) + k];
        const val = fade ? (1 - v) * T + v * B : (1 - v) * T + v * B + (1 - u) * L + u * R - ((1 - u) * (1 - v) * c00 + u * (1 - v) * c10 + (1 - u) * v * c01 + u * v * c11);
        a[o + k] = Math.max(0, Math.min(255, Math.round(val))); } }
    for (let i = 0; i < a.length; i++) { const x = (i >> 2) % (w + 2), y = Math.floor((i >> 2) / (w + 2)); if (x === 0 || y === 0 || x === w + 1 || y === h + 1) a[i] = keep[i]; } // the edge itself stays as it was
    g.putImageData(d, x0 - 1, y0 - 1); };
  // a soft plate in the background's own colour, for a patterned background (no pattern under the new words)
  const plate = (x, y, w, h, c0, c1, soft) => { g.save(); g.filter = 'blur(' + (soft || 3) * 2 + 'px)'; const gr = g.createLinearGradient(0, y * 2, 0, (y + h) * 2); gr.addColorStop(0, c0); gr.addColorStop(1, c1); g.fillStyle = gr; g.beginPath(); g.roundRect(x * 2, y * 2, w * 2, h * 2, 8); g.fill(); g.restore(); };
  (P.plate || []).forEach((q) => plate(...q));
  (P.patch || []).forEach((q) => patch(q[0], q[1], q[2], q[3], false));
  (P.fade || []).forEach((q) => patch(q[0], q[1], q[2], q[3], true));
  await document.fonts.load('800 20px Nunito'); await document.fonts.load('20px "Lilita One"'); await document.fonts.ready;
  g.setTransform(2, 0, 0, 2, 0, 0); g.lineJoin = 'round'; g.textBaseline = 'middle';
  const one = (t, s, x, y) => { g.font = (s.weight || 400) + ' ' + s.size + 'px "' + (s.font || 'Lilita One') + '"'; g.textAlign = s.align || 'center'; g.letterSpacing = (s.spacing || 0) + 'px';
    const yy = y + s.size * 0.04, dx = s.align === 'right' ? 0 : (s.spacing || 0) / 2;
    if (s.glow) { g.save(); g.shadowColor = s.glow[0]; g.shadowBlur = s.glow[1] * 2; g.strokeStyle = s.stroke[0]; g.lineWidth = s.stroke[1]; g.strokeText(t, x + dx, yy); g.restore(); }
    if (s.stroke) { g.strokeStyle = s.stroke[0]; g.lineWidth = s.stroke[1]; g.strokeText(t, x + dx, yy); }
    const gr = g.createLinearGradient(0, yy - s.size * 0.42, 0, yy + s.size * 0.38); gr.addColorStop(0, s.fill[0]); gr.addColorStop(1, s.fill[1]); g.fillStyle = gr; g.fillText(t, x + dx, yy); };
  for (const s of P.text || []) { if (s.stack) [...s.t].forEach((ch, i) => one(ch, s, s.x, s.y + i * s.step)); else one(s.t, s, s.x, s.y); }
  document.title = 'ok';
};
im.src = ${JSON.stringify(s.url)};
</script></body></html>`;

(async () => {
  const args = process.argv.slice(2), filter = args.find((a) => !a.startsWith('--')) || '';
  fs.mkdirSync(OUT, { recursive: true });
  const file = (p) => path.basename(p.name).replace(/\.png$/i, '') + '.png';
  for (const p of PICTURES.filter((q) => filter.split(',').some((f) => q.name.includes(f)))) { if (args.includes('--board')) break;
    const s = source(p);
    const [W, H] = s.rect ? (s.rot ? [s.rect[3], s.rect[2]] : [s.rect[2], s.rect[3]]) : sizeOf(path.join(A, p.name));
    await renderPng(PAGE(p, s), path.join(OUT, file(p)), W * 2, H * 2, "document.title === 'ok'");
    console.log('saved ui/en/' + file(p), W * 2 + 'x' + H * 2);
  }
  if (args.includes('--sheet')) { // before / after board
    const cells = PICTURES.filter((q) => filter.split(',').some((f) => q.name.includes(f))).map((p) => { const s = source(p), r = s.rect, f = path.join(OUT, file(p)); if (!fs.existsSync(f)) return '';
      const [w, h] = r ? [r[2], r[3]] : sizeOf(path.join(A, p.name));
      const before = `<div style="width:${w * 2}px;height:${h * 2}px;background:url(${s.url}) ${r ? -r[0] * 2 : 0}px ${r ? -r[1] * 2 : 0}px / ${s.k === 2 ? 'auto' : '200%'} no-repeat;${s.k === 2 ? '' : 'background-size:' + sizeOf(path.join(A, s.rect ? JSON.parse(fs.readFileSync(path.join(A, p.from + '.json'), 'utf8')).tex && path.join(path.dirname(p.from), JSON.parse(fs.readFileSync(path.join(A, p.from + '.json'), 'utf8')).tex) : p.name)).map((v) => v * 2 + 'px').join(' ')}"></div>`;
      return `<div class="cell">${before}<img src="${dataUrl(f)}"><span>${path.basename(p.name)}</span></div>`; }).join('');
    await renderPng(`<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#7d838c;font:12px sans-serif;color:#fff;width:1500px}.cell{display:inline-block;margin:8px;vertical-align:top}.cell>div,.cell>img{display:block;margin-bottom:4px;background-color:#5f656e}</style><body>${cells}`, path.join(ROOT, 're/en-pictures.png'), 1500, Number(process.env.SHEET_H) || 1500);
    console.log('saved re/en-pictures.png');
  }
})().catch((e) => { console.error(e.message || e); process.exit(1); });

// a PNG's size from its header
function sizeOf(file) { const b = fs.readFileSync(file); return [b.readUInt32BE(16), b.readUInt32BE(20)]; }
