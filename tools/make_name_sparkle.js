// The sparkle of glowing names (owner, 8 Nov 2026: "effects on the names, like sparks, like diamonds"): a white four-point
// diamond twinkle with a soft halo, 64x64 on a see-through background. The game tints it (white or the name's light colour) and
// makes it pop up, turn and fade around the name (util/common.lua PurpleGlow, effect "sparkle"). The game has no such picture
// (its own "light" frames are glows and a light burst).
//   node tools/make_name_sparkle.js [out.png]      then python -I tools/build_cdn.py 28.0.N
const path = require('path');
const { renderPng } = require('./chrome_png');
const out = process.argv[2] || path.join(__dirname, '..', 'server/cdn/src/ccbResources/name_sparkle.png');
const S = 64;
// long rays up/down/left/right, short ones on the diagonals, all pinched to a thin waist (a cut-diamond glint)
const ray = (a, len, wid) => { const r = (d) => (a + d) * Math.PI / 180; const p = (rad, ang) => `${(32 + rad * Math.cos(r(ang))).toFixed(2)},${(32 + rad * Math.sin(r(ang))).toFixed(2)}`; return `${p(len, 0)} ${p(wid, 90)} ${p(wid * 0.6, 180)} ${p(wid, -90)}`; };
const star = (rays) => rays.map(([a, len, wid]) => `<polygon points="${ray(a, len, wid)}"/>`).join('');
const html = `<!doctype html><html><head><meta charset="utf-8"><style>
html, body { margin: 0; width: ${S}px; height: ${S}px; background: transparent; overflow: hidden; }
svg { display: block; }
</style></head><body><svg width="${S}" height="${S}" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
<defs>
  <radialGradient id="halo"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset=".35" stop-color="#fff" stop-opacity=".45"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
  <filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.6"/></filter>
</defs>
<circle cx="32" cy="32" r="16" fill="url(#halo)"/>
<g fill="#fff" filter="url(#soft)" opacity=".85">${star([[0, 30, 3.4], [90, 30, 3.4], [180, 30, 3.4], [270, 30, 3.4], [45, 15, 2.6], [135, 15, 2.6], [225, 15, 2.6], [315, 15, 2.6]])}</g>
<g fill="#fff">${star([[0, 29, 2.6], [90, 29, 2.6], [180, 29, 2.6], [270, 29, 2.6], [45, 13, 1.8], [135, 13, 1.8], [225, 13, 1.8], [315, 13, 1.8]])}</g>
<circle cx="32" cy="32" r="3.2" fill="#fff"/>
</svg></body></html>`;
renderPng(html, out, S, S)
  .then(() => console.log('saved', out, `${S}x${S}`))
  .catch((e) => { console.error(e.message || e); process.exit(1); });
