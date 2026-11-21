// The PC look (owner, 21 Nov 2026: "landscape, so it feels like a real PC game"): on a wide window the game stands in the middle
// of a stage instead of a black screen: the game's own blue moon night behind it, a framed game picture, and a panel on each
// side. Left: who you are (name, level, VIP, gold, silver, energy, fights: the same numbers as the game's top bar, read from
// HB.game.user). Right: the server (players online from /status), full screen, and links (wiki, Discord, item page).
// A phone or a narrow window gets none of this (the game fills the screen there). ?stage=0 switches it off.
'use strict';
(() => {
  const HB = window.HB;
  if (/[?&]stage=0/.test(location.search)) return;
  const css = `
  @import url('https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito:wght@600;800&display=swap');
  body.wide { background: transparent; } /* the picture below sits behind the body */
  body.wide::before { content: ''; position: fixed; inset: -40px; background: url(bg-moon.webp) center 30%/cover, #0b1430; filter: blur(3px) brightness(.62); z-index: -2; }
  body.wide::after { content: ''; position: fixed; inset: 0; background: radial-gradient(ellipse at center, transparent 35%, rgba(3,5,14,.82) 100%); z-index: -1; }
  body.wide canvas { border-radius: 10px; box-shadow: 0 0 0 3px #c8913c, 0 0 0 6px #3a2413, 0 18px 60px rgba(0,0,0,.75); }
  .side { display: none; position: fixed; top: 50%; transform: translateY(-50%); width: min(300px, calc((100vw - 100vh / 1.78) / 2 - 56px)); color: #f4e6cc; font: 600 15px/1.45 Nunito, "Trebuchet MS", Arial, sans-serif; -webkit-user-select: none; user-select: none; }
  body.wide .side { display: block; }
  .side.l { right: calc(50% + 100vh / 1.78 / 2 + 28px); }
  .side.r { left: calc(50% + 100vh / 1.78 / 2 + 28px); }
  .side .logo { display: block; width: 100%; margin-bottom: 14px; filter: drop-shadow(0 6px 10px rgba(0,0,0,.6)); }
  .side .card { background: linear-gradient(rgba(46,31,19,.92), rgba(26,16,9,.92)); border: 2px solid #c8913c; border-radius: 12px; padding: 14px 16px; margin-bottom: 14px; box-shadow: 0 8px 24px rgba(0,0,0,.5); }
  .side h3 { margin: 0 0 8px; font: 20px "Lilita One", Impact, sans-serif; color: #ffd36b; letter-spacing: .5px; }
  .side .row { display: flex; justify-content: space-between; gap: 10px; padding: 3px 0; border-bottom: 1px solid rgba(200,145,60,.18); }
  .side .row:last-child { border-bottom: 0; }
  .side .row span:last-child { color: #fff; font-weight: 800; }
  .side .name { font: 24px "Lilita One", Impact, sans-serif; color: #fff; margin-bottom: 6px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .side button, .side a.btn { display: block; width: 100%; box-sizing: border-box; margin-top: 8px; padding: 10px; border-radius: 10px; border: 2px solid #1d5e12; background: linear-gradient(#7fd04c, #3f9a22); color: #fff; font: 18px "Lilita One", Impact, sans-serif; text-align: center; text-decoration: none; text-shadow: 0 1px 0 #1a4a0c; cursor: pointer; }
  .side a.btn.blue { border-color: #134a7a; background: linear-gradient(#5ab4f0, #2a73c0); text-shadow: 0 1px 0 #0c3058; }
  .side button:hover, .side a.btn:hover { filter: brightness(1.12); }
  .side .dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; background: #5fdc4a; margin-right: 6px; box-shadow: 0 0 6px #5fdc4a; }
  .side .dot.off { background: #e0503a; box-shadow: 0 0 6px #e0503a; }
  .side small { display: block; color: #bda77f; margin-top: 6px; }`;
  document.head.append(Object.assign(document.createElement('style'), { textContent: css }));
  const el = (html) => { const d = document.createElement('div'); d.innerHTML = html; return d.firstElementChild; };
  const left = el(`<div class="side l"><img class="logo" src="logo-ninjaonline.webp" alt="Ninja Online">
    <div class="card" id="st-me" style="display:none"><div class="name" id="st-name"></div>
      <div class="row"><span>Level</span><span id="st-lv"></span></div><div class="row"><span>VIP</span><span id="st-vip"></span></div>
      <div class="row"><span>Gold</span><span id="st-gold"></span></div><div class="row"><span>Silver</span><span id="st-silver"></span></div>
      <div class="row"><span>Energy</span><span id="st-energy"></span></div><div class="row"><span>Fights</span><span id="st-sp"></span></div></div></div>`);
  const right = el(`<div class="side r"><div class="card"><h3>Server</h3><div id="st-status"><span class="dot off"></span>Checking…</div>
      <button id="st-full">Full screen</button><small>F11 works too</small></div>
    <div class="card"><h3>More</h3><a class="btn blue" target="_blank" rel="noopener" href="https://ninjaonlinereborn.com/wiki/">Wiki</a>
      <a class="btn blue" target="_blank" rel="noopener" href="https://discord.gg/2Cbp4UDHrU">Discord</a></div></div>`);
  document.body.append(left, right);
  const $ = (id) => document.getElementById(id);
  // wide = room for the side panels next to the 9:16 game
  const size = () => document.body.classList.toggle('wide', innerWidth - innerHeight / 1.78 > 2 * 230);
  size(); addEventListener('resize', size);
  $('st-full').onclick = () => { if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen().catch(() => {}); };
  document.addEventListener('fullscreenchange', () => { $('st-full').textContent = document.fullscreenElement ? 'Leave full screen' : 'Full screen'; });
  const fmt = (n) => Number(n || 0).toLocaleString('en-US');
  setInterval(() => {
    const u = HB.game && HB.game.user;
    $('st-me').style.display = u ? '' : 'none';
    if (!u) return;
    $('st-name').textContent = u.nick || ''; $('st-lv').textContent = u.level || 1; $('st-vip').textContent = u.viplevel || 0;
    $('st-gold').textContent = fmt(u.cash); $('st-silver').textContent = fmt(u.coin);
    $('st-energy').textContent = (u.curaction || 0) + (u.maxaction ? ' / ' + u.maxaction : ''); $('st-sp').textContent = (u.cursp || 0) + (u.maxsp ? ' / ' + u.maxsp : '');
  }, 500);
  const status = async () => {
    try { const s = await (await fetch('/status')).json(); $('st-status').innerHTML = '<span class="dot"></span>Online · ' + Number(s.online || 0) + ' playing now'; }
    catch { $('st-status').innerHTML = '<span class="dot off"></span>Server not reachable'; }
  };
  status(); setInterval(status, 60000);
})();
