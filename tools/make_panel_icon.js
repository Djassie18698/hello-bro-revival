// The control panel's home-screen icon (owner, 12 Nov 2026: "an app for iPhone"): Safari > Share > Add to Home Screen uses it.
// Same look as the panel's own logo (orange-red tile with the 🍥 swirl). iOS rounds the corners itself, so the picture is a full square.
//   node tools/make_panel_icon.js   -> server/panel-icon.png (512 px; server.js serves it at /admin/app-icon.png)
const path = require('path');
const { renderPng } = require('./chrome_png');
const S = 512;
const html = `<!doctype html><html><body style="margin:0;background:transparent">
<div style="width:${S}px;height:${S}px;display:grid;place-items:center;background:radial-gradient(70% 70% at 30% 20%,#ffb648 0%,#ff8a1f 45%,#e8323f 100%)">
<span style="font-size:${S * 0.62}px;line-height:1;font-family:'Segoe UI Emoji','Apple Color Emoji','Noto Color Emoji',sans-serif;filter:drop-shadow(0 ${S * 0.02}px ${S * 0.03}px rgba(60,10,0,.45))">🍥</span>
</div></body></html>`;
renderPng(html, path.join(__dirname, '..', 'server', 'panel-icon.png'), S, S).then(() => console.log('saved server/panel-icon.png'));
