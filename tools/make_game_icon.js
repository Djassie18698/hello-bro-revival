// The Ninja Online iPhone game app's icon (tools/ios-game): the website's NINJA ONLINE logo on the game's blue moon (server/site/img/bg-moon.webp),
// so it looks different from the Ninja Panel icon. iOS rounds the corners itself, so the picture is a full square.
//   node tools/make_game_icon.js   -> tools/ios-game/NinjaOnline/Assets.xcassets/AppIcon.appiconset/icon-1024.png
const fs = require('fs'), path = require('path');
const { renderPng } = require('./chrome_png');
const S = 1024, img = (f) => 'data:image/webp;base64,' + fs.readFileSync(path.join(__dirname, '..', 'server', 'site', 'img', f)).toString('base64');
const html = `<!doctype html><html><body style="margin:0;background:#000">
<div style="position:relative;width:${S}px;height:${S}px;overflow:hidden;display:grid;place-items:center;background:#0b1430 url(${img('bg-moon.webp')}) center 35%/cover">
<div style="position:absolute;inset:0;background:linear-gradient(transparent 40%,rgba(5,8,25,.75))"></div>
<img id="l" src="${img('logo-ninjaonline.webp')}" style="position:relative;width:${S * 0.92}px;margin-top:${S * 0.18}px;filter:drop-shadow(0 ${S * 0.015}px ${S * 0.03}px rgba(0,0,0,.8))">
</div></body></html>`;
renderPng(html, path.join(__dirname, 'ios-game', 'NinjaOnline', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-1024.png'), S, S, "document.getElementById('l').complete")
  .then(() => console.log('saved tools/ios-game/NinjaOnline/Assets.xcassets/AppIcon.appiconset/icon-1024.png'));
