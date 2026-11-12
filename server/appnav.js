// The control panel as a phone app (owner, 12 Nov 2026: on the iPhone home screen the panel could not scroll, then lost its tabs).
// Safari on iPhone does not scroll pages inside frames well, so on a phone (or an iPad) the panel uses no frames: every tab is its own
// page (?embed=1&app=1) and this script, served at /admin/appnav.js and included by each of those pages, puts the panel's top bar with
// the tabs above it. Without app=1 in the address it does nothing (the desktop panel keeps its frames).
(function () {
  const q = new URLSearchParams(location.search);
  if (!q.has('app')) return;
  const TABS = [
    ['server', '🖥️ Server', '/manager?embed=1&app=1'],
    ['admin', '🎁 Players & items', '/admin?embed=1&app=1'],
    ['team', '🛡️ Team builder', '/admin?embed=1&app=1&tab=team'],
    ['log', '📈 Player log', '/admin/playerlog?embed=1&app=1'],
    ['track', '🔎 Tracker', '/admin/track?embed=1&app=1'],
    ['site', '🌐 Website', '/admin/sitestats?embed=1&app=1'],
    ['progress', '📋 Progress', '/panel?app=1#progress'],
  ];
  const p = location.pathname;
  const cur = p === '/manager' ? 'server' : p === '/admin/playerlog' ? 'log' : p === '/admin/track' ? 'track' : p === '/admin/sitestats' ? 'site'
    : p === '/admin' ? (q.get('tab') === 'team' ? 'team' : 'admin') : 'progress';
  // the notch: let the page reach under the status bar, the bar keeps clear of it
  const vp = document.querySelector('meta[name=viewport]');
  if (vp && !/viewport-fit/.test(vp.content)) vp.content += ',viewport-fit=cover';
  const css = document.createElement('style');
  css.textContent = `html,body{background:#0b0a14!important}
#hbapp{position:sticky;top:0;z-index:50;margin:0 0 4px;padding:max(10px,env(safe-area-inset-top)) 0 8px;background:rgba(11,10,20,.92);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);border-bottom:1px solid rgba(255,255,255,.08);font-family:Inter,system-ui,sans-serif}
#hbapp .hd{display:flex;align-items:center;gap:10px;padding:0 12px 8px}
#hbapp .lg{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;font-size:19px;background:linear-gradient(135deg,#ff8a1f,#ff3d5a)}
#hbapp b{font-family:Bangers,Impact,sans-serif;font-size:23px;letter-spacing:2px;font-weight:400;background:linear-gradient(90deg,#fff 0%,#ffb648 45%,#ff8a1f 70%,#ff5f6d 100%);-webkit-background-clip:text;background-clip:text;color:transparent}
#hbapp nav{display:flex;gap:8px;overflow-x:auto;-webkit-overflow-scrolling:touch;scrollbar-width:none;padding:0 12px}
#hbapp nav::-webkit-scrollbar{display:none}
#hbapp nav a{flex:none;padding:9px 14px;border-radius:12px;border:1px solid rgba(255,255,255,.08);background:rgba(24,22,40,.72);color:#a39fc0;font-weight:800;font-size:14px;text-decoration:none;white-space:nowrap}
#hbapp nav a.on{color:#1a0f02;background:linear-gradient(135deg,#ffb648,#ff8a1f);border-color:transparent}`;
  document.head.appendChild(css);
  const bar = document.createElement('div');
  bar.id = 'hbapp';
  bar.innerHTML = '<div class="hd"><span class="lg">🍥</span><b>HELLO BRO</b></div><nav>' +
    TABS.map(([k, t, h]) => `<a href="${h}"${k === cur ? ' class="on"' : ''}>${t.replace(/&/g, '&amp;')}</a>`).join('') + '</nav>';
  document.body.insertBefore(bar, document.body.firstChild);
  const on = bar.querySelector('a.on');
  if (on) on.scrollIntoView({ inline: 'center', block: 'nearest' });
  // a page that asks the panel to switch tabs ({goto}) or the admin page's Team editor (?tab=team)
  window.addEventListener('message', (e) => {
    if (e.origin !== location.origin || !e.data || !e.data.goto) return;
    const t = TABS.find(([k]) => k === e.data.goto);
    if (t) location.href = t[2];
  });
  if (q.get('tab')) window.postMessage({ tab: q.get('tab') }, location.origin);
})();
