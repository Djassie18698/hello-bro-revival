// A contact sheet of a sprite sheet of the rewritten game: every frame cut out, with its name and size, on a grey board.
// For finding pictures with Chinese words in them and for drawing their English versions (tools/make_webclient_en.js).
//   node tools/dev/sheet-view.js <sheet> [name filter] [out.png] [zoom]     sheet = path under server/webclient/assets without ending,
//   e.g. ccbResources/lottery; a plain picture (ccbResources/activity_icon_3.png) is shown whole
const fs = require('fs'), path = require('path');
const { renderPng } = require('../chrome_png');
const A = path.join(__dirname, '..', '..', 'server', 'webclient', 'assets');
const [sheet, filter = '', out = 're/sheet.png', zoom = '2'] = process.argv.slice(2);
const url = (p) => 'file:///' + p.replace(/\\/g, '/');
let frames, img;
if (/\.(png|jpg)$/i.test(sheet)) { img = path.join(A, sheet); frames = { [sheet]: null }; }
else { const j = JSON.parse(fs.readFileSync(path.join(A, sheet + '.json'), 'utf8')); img = path.join(A, path.dirname(sheet), j.tex); frames = j.frames; }
const names = Object.keys(frames).filter((n) => n.includes(filter));
const html = `<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#8a8f98;font:12px sans-serif;color:#fff;width:1200px}
div{display:inline-block;margin:6px;vertical-align:top;background:#6b7079}canvas{display:block;background:repeating-conic-gradient(#777 0 25%,#888 0 50%) 0 0/16px 16px}</style><body><script>
const F = ${JSON.stringify(names.map((n) => [n, frames[n]]))}, Z = ${Number(zoom)};
const im = new Image(); im.onload = () => { for (const [n, f] of F) { const g = f || [0, 0, im.width, im.height, 0];
  const rot = g[4] && !(im.width === g[2] && im.height === g[3]); const w = g[2], h = g[3];
  const d = document.createElement('div'), c = document.createElement('canvas'); c.width = w * Z; c.height = h * Z; const x = c.getContext('2d');
  if (rot) { x.translate(0, h * Z); x.rotate(-Math.PI / 2); x.drawImage(im, g[0], g[1], h, w, 0, 0, h * Z, w * Z); } else x.drawImage(im, g[0], g[1], w, h, 0, 0, w * Z, h * Z);
  d.appendChild(c); d.appendChild(document.createTextNode(n + ' ' + w + 'x' + h + (rot ? ' rot' : ''))); document.body.appendChild(d); }
  document.title = 'ok ' + document.body.scrollHeight; }; im.src = ${JSON.stringify(url(img))};
</script>`;
renderPng(html, out, 1200, Number(process.env.SHEET_H) || 1400, "document.title.startsWith('ok')").then(() => console.log('saved', out, names.length, 'frames')).catch((e) => { console.error(e.message || e); process.exit(1); });
