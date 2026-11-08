// The game's login logo as "NINJA ONLINE / REBORN" (owner, 8 Nov 2026), the same look as the website's hero logo:
// the owner's NINJA ONLINE picture (server/site/img/logo-ninjaonline.webp) with REBORN under it (Lilita One, gold gradient,
// thick brown outline). Rendered by headless Chrome (tools/chrome_png.js) on a see-through background at the original logo's
// size (562x328), into server/cdn/src/ccbResources/logo.png (hot update; LoginView.ccbi and LogoScene.ccbi show ccbResources/logo.png).
//   node tools/make_login_logo.js [out.png]      then python -I tools/build_cdn.py 28.0.N
const path = require('path');
const { renderPng } = require('./chrome_png');
const ROOT = path.join(__dirname, '..');
const out = process.argv[2] || path.join(ROOT, 'server/cdn/src/ccbResources/logo.png');
const W = 562, H = 328;
const img = 'file:///' + path.join(ROOT, 'server/site/img/logo-ninjaonline.webp').replace(/\\/g, '/');
const html = `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Lilita+One&display=swap" rel="stylesheet">
<style>
html, body { margin: 0; width: ${W}px; height: ${H}px; background: transparent; overflow: hidden; }
.logo { width: ${W}px; height: ${H}px; display: flex; flex-direction: column; align-items: center; justify-content: center;
  filter: drop-shadow(0 5px 6px rgba(0, 0, 0, .55)); }
img { display: block; width: 486px; height: auto; }
span { position: relative; display: block; margin-top: -10px; font: 400 64px/0.9 'Lilita One', sans-serif; letter-spacing: .02em; white-space: nowrap;
  color: #3a1405; -webkit-text-stroke: .16em #3a1405; text-shadow: 0 .09em 0 #230a02; }
span::after { content: attr(data-t); position: absolute; left: 0; top: 0; -webkit-text-stroke: 0; text-shadow: none;
  background: linear-gradient(180deg, #fff8b8 6%, #ffd640 34%, #ff9b1f 60%, #f2541a 92%);
  -webkit-background-clip: text; background-clip: text; color: transparent; -webkit-text-fill-color: transparent; }
</style></head><body><div class="logo"><img src="${img}" alt=""><span data-t="REBORN">REBORN</span></div></body></html>`;
renderPng(html, out, W, H, "document.fonts.check('64px \"Lilita One\"') && document.images[0].complete && document.images[0].naturalWidth > 0")
  .then(() => console.log('saved', out, `${W}x${H}`))
  .catch((e) => { console.error(e.message || e); process.exit(1); });
