// The iPhone app's icon (owner, 12 Nov 2026: "a sideload app, with the Ninja Online logo"): the website's NINJA ONLINE logo
// (server/site/img/logo-ninjaonline.webp) on the night-blue of the website. iOS rounds the corners itself, so the picture is a full square.
//   node tools/make_ios_icon.js   -> tools/ios-panel/NinjaPanel/Assets.xcassets/AppIcon.appiconset/icon-1024.png
const fs = require('fs'), path = require('path');
const { renderPng } = require('./chrome_png');
const S = 1024;
const logo = 'data:image/webp;base64,' + fs.readFileSync(path.join(__dirname, '..', 'server', 'site', 'img', 'logo-ninjaonline.webp')).toString('base64');
const html = `<!doctype html><html><body style="margin:0;background:#0b1430">
<div style="width:${S}px;height:${S}px;display:grid;place-items:center;background:radial-gradient(80% 65% at 50% 30%,#2d4f9e 0%,#15265a 50%,#0b1430 100%)">
<img id="l" src="${logo}" style="width:${S * 0.9}px;filter:drop-shadow(0 ${S * 0.015}px ${S * 0.03}px rgba(0,0,0,.6))">
</div></body></html>`;
renderPng(html, path.join(__dirname, '..', 'tools', 'ios-panel', 'NinjaPanel', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-1024.png'), S, S, "document.getElementById('l').complete")
  .then(() => console.log('saved tools/ios-panel/NinjaPanel/Assets.xcassets/AppIcon.appiconset/icon-1024.png'));

// the start screen's logo (see-through, shown 280 points wide = 840 px on a 3x iPhone): LaunchLogo.imageset
const LW = 840, LH = Math.round(840 * 958 / 1642);
const logoHtml = `<!doctype html><html><body style="margin:0;background:transparent"><img id="l" src="${logo}" style="display:block;width:${LW}px;height:${LH}px"></body></html>`;
const setDir = path.join(__dirname, '..', 'tools', 'ios-panel', 'NinjaPanel', 'Assets.xcassets', 'LaunchLogo.imageset');
fs.mkdirSync(setDir, { recursive: true });
fs.writeFileSync(path.join(setDir, 'Contents.json'), JSON.stringify({ images: [{ idiom: 'universal', filename: 'LaunchLogo@3x.png', scale: '3x' }], info: { author: 'xcode', version: 1 } }, null, 2) + '\n');
setTimeout(() => renderPng(logoHtml, path.join(setDir, 'LaunchLogo@3x.png'), LW, LH, "document.getElementById('l').complete")
  .then(() => console.log('saved tools/ios-panel/NinjaPanel/Assets.xcassets/LaunchLogo.imageset/LaunchLogo@3x.png')), 3000);
