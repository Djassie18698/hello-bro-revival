// The PC frame (owner, 21 Nov 2026: "a PC app that can run on phones, but with PC in mind", "less portrait, more landscape",
// "like a real PC game"). On a wide window the game is not a phone in the middle of a wallpaper: it stands between two wooden
// columns built from the game's own interface pieces, and the columns do real work.
//   left   who you are (name, VIP, level, exp / energy / fights bars, gold, silver, attack, defence: HB.game.user, so it follows
//          every HB.game.refresh()) and the menu: the game's own buttons for every screen that exists, one click from anywhere,
//          the one you are on marked
//   right  the server (/status), today in the game (/api/today), the strongest players (/api/top), full screen, wiki, Discord,
//          the keys
// The game itself gets a little wider there (5:8 instead of 9:16: HB.stageBox, read by engine.js) and keeps the full height.
// Keys (any window size): Esc = close the window on top / Back / Home, 1-6 = the bottom bar, F = full screen.
// A phone, a portrait window or one under 900 px wide gets none of this: the game fills the screen exactly as before.
// ?stage=0 switches the frame off (the old phone-shaped game in the middle, keys still work).
'use strict';
(() => {
  const HB = window.HB;
  const OFF = /[?&]stage=0/.test(location.search);
  const RATIO = (() => { const m = /[?&]ratio=(\d+)/.exec(location.search); return m ? m[1] / 100 : 1.7; })(); // (?ratio=160 tries another shape)
  // height : width of the game on a PC. Taller than 1.5 (the game's tall-screen layout, 686 wide); Home needs about this much height
  const isWide = (vw, vh) => !OFF && vw >= 900 && vw >= vh * 1.3;
  HB.stageBox = (vw, vh) => (isWide(vw, vh) ? [Math.round(vh / RATIO), vh] : null);

  const G = () => HB.game || {};
  const S = () => HB.screens || {};
  const el = (html) => { const d = document.createElement('div'); d.innerHTML = html.trim(); return d.firstElementChild; };
  const $ = (id) => document.getElementById(id);
  const fmt = (n) => Number(n || 0).toLocaleString('en-US');
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  // ---------------------------------------------------------------- where you are, and going somewhere
  // every screen function is wrapped once so the menu knows which one opened last (sound.js wraps the same way)
  const SCREEN_KEY = { team: 'team', backpack: 'backpack', upgrade: 'backpack', training: 'training', openChapter: 'training', spar: 'spar', shop: 'shop', arena: 'arena',
    tower: 'tower', plunder: 'plunder', war: 'war', news: 'news', friends: 'friends', growth: 'growth', potential: 'potential', rebirth: 'rebirth', ninjabook: 'ninjabook', custom: 'custom' };
  const LUA_KEY = { ShowGodCardSyntheticView: 'evolve', ShowTrainSoulView: 'soul', ShowLimitTrainView: 'dun' };
  let here = '';
  const wrap = (obj, name, key) => {
    const f = obj[name];
    if (typeof f !== 'function' || f._pc) return;
    const w = function (...a) { const k = key(a); if (k !== undefined) here = k; return f.apply(this, a); };
    w._pc = true; obj[name] = w;
  };
  const watch = () => {
    for (const k of Object.keys(S())) wrap(S(), k, () => (k === 'details' ? undefined : SCREEN_KEY[k] || ''));
    if (HB.game) {
      wrap(HB.game, 'changeToActivitySubMenu', (a) => LUA_KEY[a[0]] || '');
      wrap(HB.game, 'changeToActivity', () => 'events');
    }
  };
  const atHome = () => G().currentSubType === 1;
  const where = () => (atHome() ? 'home' : here);
  // windows and fights lie over the screen (z 500 and up, tips are 900): the menu waits for them
  // (the layer the scripts put their windows in stays behind, empty, after a window closed: that is not a window)
  const filled = (n) => n.visible && (n.constructor !== HB.Node || n.children.some(filled));
  const over = () => (HB.scene ? HB.scene.children.filter((c) => c.z >= 500 && c.z < 800 && filled(c)) : []);
  const inGame = () => !!(G().user && G().subContent);
  const level = () => Number((G().user || {}).level || 1);
  // functionconfig: the level a building opens at (5 Arena, 1 Battles, 2 Plunder), as game.js asks for its Home buttons
  const lockOf = (id) => { const t = HB.ui && HB.ui.tables && HB.ui.tables.functionconfig; const r = t && t.rows.find((x) => x[0] === id); return r && level() < (r[3] || 0) ? r : null; };
  const homeThen = async (f) => { if (!atHome()) { await G().goHome(); await HB.wait(0.3); } f(); };

  const MENU = [
    ['', [
      { k: 'home', t: 'Home', i: 'com_sub_mainmenu', key: '1', go: () => G().goHome() },
      { k: 'team', t: 'Team', i: 'com_sub_gourp', key: '2', s: 'team' },
      { k: 'backpack', t: 'Backpack', i: 'com_sub_backpackage', key: '3', s: 'backpack' },
      { k: 'training', t: 'Training', i: 'com_sub_adventrue', key: '4', s: 'training' },
      { k: 'spar', t: 'Spar', i: 'com_sub_fightwith', key: '5', s: 'spar' },
      { k: 'shop', t: 'Shop', i: 'com_sub_store', key: '6', s: 'shop' }]],
    ['Village', [
      { k: 'arena', t: 'Arena', i: 'def_fight', s: 'arena', lock: 5 },
      { k: 'tower', t: 'Battles', i: 'def_rush_tower', s: 'tower', lock: 1 },
      { k: 'plunder', t: 'Plunder', i: 'def_plunder', s: 'plunder', lock: 2 },
      { k: 'war', t: 'War', i: 'def_countrywar', s: 'war' },
      { k: 'org', t: 'Akatsuki', i: 'def_org', lua: () => homeThen(() => G().luaHomeButton && G().luaHomeButton('BtnOrg')) },
      { k: 'events', t: 'Events', i: 'def_btn_active', lua: () => homeThen(() => { if (HB.luaRun('business_proxy/activityPopup_business.lua')) HB.luaGlobal('initactivityPopupLayer'); }) },
      { k: 'custom', t: 'Special', i: 'activity1', s: 'custom', cap: true },
      { k: 'news', t: 'News', i: 'def_msg_btn', s: 'news' },
      { k: 'friends', t: 'Friends', i: 'def_btn_friends', s: 'friends' }]],
    ['Shinobi', [
      { k: 'growth', t: 'Growth', i: 'cuilian', s: 'growth' },
      { k: 'potential', t: 'Train', i: 'def_btn_potential', s: 'potential' },
      { k: 'rebirth', t: 'Reincarnate', i: 'def_btn_rein', s: 'rebirth' },
      { k: 'evolve', t: 'Evolve', i: 'def_godCard', lua: () => G().changeToActivitySubMenu('ShowGodCardSyntheticView') },
      { k: 'soul', t: 'Soul', i: 'def_btn_trainsoul', lua: () => G().changeToActivitySubMenu('ShowTrainSoulView') },
      { k: 'dun', t: 'Dungeon', i: 'def_btn_limitTrain', lua: () => G().changeToActivitySubMenu('ShowLimitTrainView') },
      { k: 'ninjabook', t: 'Ninja book', i: 'def_btn_ninjabook', s: 'ninjabook' }]],
  ];
  const ITEMS = MENU.flatMap((g) => g[1]);
  const exists = (it) => (it.s ? !!S()[it.s] : it.lua ? !!HB.L : true);
  const open = (it) => {
    if (!inGame() || !exists(it) || over().length) return; // not logged in yet, or a window / a fight is open
    const lock = it.lock && lockOf(it.lock);
    if (lock) return HB.tip(String(lock[4] || 'Locked').replace(/ +$/, ''), 2); // the game's own "level N unlocked" text
    HB.sound && HB.sound('click');
    try { const r = it.go ? it.go() : it.s ? S()[it.s]() : it.lua(); if (r && r.catch) r.catch((e) => console.warn('menu', it.k, e)); } catch (e) { console.warn('menu', it.k, e); }
  };

  // Esc: the close / back button of whatever is on top, else Home
  const BACK = /close|cancel|return|exit|back(?!pack|ground)/i;
  const findBack = (root) => {
    let hit = null;
    const walk = (n) => { if (hit || !n.visible) return; if (n instanceof HB.Button && n.enabled && BACK.test(String(n.selector || '') + ' ' + String(n.name || ''))) { hit = n; return; } for (const c of n.children) walk(c); };
    walk(root);
    return hit;
  };
  // a script's window without a close button closes on a tap next to it (the Event window): Esc gives it that tap, in the corner
  const outsideTap = () => { if (HB.luaTouchLayers && HB.luaTouchLayers.size && HB.luaTouchBegan && HB.luaTouchBegan(3, 3, {})) HB.luaTouchEnded && HB.luaTouchEnded(3, 3, false); };
  const back = () => {
    if (!HB.scene) return;
    const tops = over().sort((a, b) => b.z - a.z);
    if (tops.length) { if (tops[0].z >= 600) return; const b = tops.map(findBack).find(Boolean); if (b) HB.tapNode(b); else outsideTap(); return; } // a fight plays on; a window closes
    if (!inGame() || atHome()) return;
    const b = findBack(G().subContent);
    if (b) HB.tapNode(b); else G().goHome();
  };
  const fullScreen = () => { if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen({ navigationUI: 'hide' }).catch(() => {}); };
  addEventListener('keydown', (e) => {
    if (e.ctrlKey || e.metaKey || e.altKey || e.repeat || /^(INPUT|TEXTAREA|SELECT)$/.test((e.target || {}).tagName || '') || (e.target || {}).isContentEditable) return;
    if (e.key === 'Escape') { if (!document.fullscreenElement) back(); return; } // in full screen the browser itself takes Esc to leave it
    if (e.key === 'Backspace') { e.preventDefault(); return back(); }
    if (e.key === 'f' || e.key === 'F') return fullScreen();
    const it = ITEMS.find((x) => x.key === e.key);
    if (it) open(it);
  });
  HB.stage = { open: (k) => { const it = ITEMS.find((x) => x.k === k); if (it) open(it); }, back, fullScreen, where, wide: () => document.body.classList.contains('wide') };
  if (OFF) return;

  // ---------------------------------------------------------------- the two columns
  document.head.append(Object.assign(document.createElement('link'), { rel: 'stylesheet', href: 'stage.css' }));
  const left = el(`<div class="pc l">
    <img class="logo" src="logo-ninjaonline.webp" alt="Ninja Online">
    <div class="panel" id="pc-me" hidden><h3><span>Shinobi</span><small id="pc-power"></small></h3><div class="body">
      <div class="who"><span class="lv" id="pc-lv"></span><span class="name" id="pc-name"></span><img id="pc-vip" alt=""></div>
      <div class="bar exp"><span>Exp</span><i><b id="pc-exp-b"></b><span id="pc-exp"></span></i></div>
      <div class="bar"><span>Energy</span><i><b id="pc-en-b"></b><span id="pc-en"></span></i></div>
      <div class="bar"><span>Fights</span><i><b id="pc-sp-b"></b><span id="pc-sp"></span></i></div>
      <div class="nums"><div title="Gold"><canvas data-i="com_gold_icon"></canvas><span id="pc-gold"></span></div><div title="Silver"><canvas data-i="com_silver_icon"></canvas><span id="pc-silver"></span></div>
        <div title="Attack"><canvas data-i="com_fight_icon"></canvas><span id="pc-atk"></span></div><div title="Defense"><canvas data-i="com_defense_icon"></canvas><span id="pc-def"></span></div></div>
    </div></div>
    <div class="panel nav" id="pc-nav" hidden><h3><span>Menu</span><small id="pc-here"></small></h3><div class="body" id="pc-cells"></div></div></div>`);
  const right = el(`<div class="pc r">
    <div class="panel"><h3><span>Server</span><small id="pc-clock"></small></h3><div class="body">
      <div class="line"><span id="pc-status"><span class="dot off"></span>Checking…</span><b id="pc-online"></b></div>
      <div class="line"><span>Shinobi so far</span><b id="pc-players">…</b></div></div></div>
    <div class="panel" id="pc-today" hidden><h3><span>Today</span><small>server time</small></h3><div class="body"><div id="pc-lines"></div><ul class="events" id="pc-events"></ul></div></div>
    <div class="panel grow" id="pc-top" hidden><h3><span>Strongest shinobi</span><small>attack</small></h3><div class="body" id="pc-ranks"></div></div>
    <div class="btns"><button class="btn green" id="pc-full">Full screen</button><button class="btn green" id="pc-install" hidden>Install app</button>
      <a class="btn" target="_blank" rel="noopener" href="https://ninjaonlinereborn.com/wiki/">Wiki</a><a class="btn" target="_blank" rel="noopener" href="https://discord.gg/2Cbp4UDHrU">Discord</a></div>
    <p class="keys"><kbd>Esc</kbd>back<kbd>1</kbd>–<kbd>6</kbd>menu<kbd>F</kbd>full screen<kbd>Wheel</kbd>lists</p></div>`);
  const mount = () => { document.body.append(left, right); size(); };
  // the window: wide or not, the game's width (engine.js asked HB.stageBox the same question) and the columns' size
  function size() {
    const vw = innerWidth, vh = innerHeight, wide = isWide(vw, vh);
    document.body.classList.toggle('wide', wide);
    if (!wide) return;
    const gw = Math.round(vh / RATIO), col = Math.min((vw - gw) / 2, vh * 0.66);
    const st = document.documentElement.style;
    st.setProperty('--gw', gw + 'px'); st.setProperty('--col', col + 'px'); st.setProperty('--em', Math.max(7, Math.min(vh * 0.0152, col / 31)) + 'px');
  }
  addEventListener('resize', size);
  if (document.body) mount(); else addEventListener('DOMContentLoaded', mount);
  const wideNow = () => document.body && document.body.classList.contains('wide');

  // the game's own pictures on small canvases (drawn by the engine's Sprite, so sheets, turned frames and HD all work)
  const paint = (c) => {
    const f = HB.frameByName && HB.frameByName(c.dataset.i);
    if (!f || !f.img || !(f.img.naturalWidth > 0) || !(f.sw > 0)) return false;
    const px = c.width = c.height = 128, ctx = c.getContext('2d'), k = Math.min(px / f.sw, px / f.sh);
    ctx.imageSmoothingQuality = 'high';
    ctx.setTransform(k, 0, 0, -k, (px - f.sw * k) / 2, px - (px - f.sh * k) / 2);
    const s = new HB.Sprite(f); s.ax = s.ay = 0; s.draw(ctx);
    return true;
  };
  const paintAll = () => { for (const c of document.querySelectorAll('.pc canvas[data-i]:not([data-ok])')) { try { if (paint(c)) c.dataset.ok = 1; } catch (e) { /* its sheet is still loading */ } } };

  // the menu: rebuilt only when the list of screens that exist changes
  let navSig = '';
  const drawNav = () => {
    const sig = ITEMS.filter(exists).map((x) => x.k).join();
    if (sig !== navSig) {
      navSig = sig;
      $('pc-cells').innerHTML = MENU.map(([title, items]) => { const have = items.filter(exists); return have.length ? (title ? `<h4>${title}</h4>` : '') + '<div class="cells">' + have.map((it) =>
        `<button class="cell${it.cap ? ' cap' : ''}" data-k="${it.k}" title="${it.t}${it.key ? ' (key ' + it.key + ')' : ''}">${it.key ? `<kbd>${it.key}</kbd>` : ''}<canvas data-i="${it.i}"></canvas>${it.cap ? `<span>${it.t}</span>` : ''}</button>`).join('') + '</div>' : ''; }).join('');
    }
    const at = where(), cur = ITEMS.find((x) => x.k === at);
    $('pc-here').textContent = cur ? cur.t : '';
    for (const b of $('pc-cells').querySelectorAll('.cell')) {
      const it = ITEMS.find((x) => x.k === b.dataset.k);
      b.classList.toggle('on', b.dataset.k === at);
      b.classList.toggle('lock', !!(it.lock && lockOf(it.lock)));
    }
    $('pc-nav').classList.toggle('busy', over().length > 0);
  };
  left.addEventListener('click', (e) => { const b = e.target.closest && e.target.closest('.cell'); if (b) { HB.stage.open(b.dataset.k); b.blur(); } });

  // the player: the same numbers as the game's top bar
  let meSig = '';
  const drawMe = () => {
    const u = G().user, on = inGame();
    $('pc-me').hidden = $('pc-nav').hidden = !on;
    if (!on) return;
    const sig = JSON.stringify([u.nick, u.level, u.viplevel, u.score, u.cash, u.coin, u.curaction, u.cursp, u.attactlow, u.attacthigh, u.defenselow, u.defensehigh, G().needExp, G().maxEnergy]);
    if (sig === meSig) return;
    meSig = sig;
    const bar = (id, v, max) => { $(id).textContent = max ? `${fmt(v)} / ${fmt(max)}` : fmt(v); $(id + '-b').style.width = Math.max(0, Math.min(100, max ? v / max * 100 : 0)) + '%'; };
    $('pc-name').textContent = u.nick || ''; $('pc-lv').textContent = u.level || 1;
    $('pc-vip').src = 'ui/vip-' + Math.max(0, Math.min(18, Number(u.viplevel) || 0)) + '.webp'; $('pc-vip').title = 'VIP ' + (u.viplevel || 0);
    bar('pc-exp', Number(u.score) || 0, G().needExp || 0); bar('pc-en', Number(u.curaction) || 0, G().maxEnergy || 0); bar('pc-sp', Number(u.cursp) || 0, 5);
    $('pc-gold').textContent = fmt(u.cash); $('pc-silver').textContent = fmt(u.coin);
    $('pc-atk').textContent = `${fmt(u.attactlow)}-${fmt(u.attacthigh)}`; $('pc-def').textContent = `${fmt(u.defenselow)}-${fmt(u.defensehigh)}`;
    $('pc-power').textContent = u.meritscore > 0 ? 'Merit ' + fmt(u.meritscore) : '';
    drawTop();
  };

  // ---------------------------------------------------------------- the live column
  let today = null, top = null;
  const two = (n) => String(n).padStart(2, '0');
  const drawToday = () => {
    if (!today) return;
    const t = new Date(Date.now() + (today.offset || 0) * 60000), h = t.getUTCHours(), now = Date.now() / 1000;
    $('pc-clock').textContent = 'server time ' + two(h) + ':' + two(t.getUTCMinutes());
    const win = (list) => { const cur = (list || []).find(([a, b]) => h >= a && h < b); if (cur) return `<b class="now">now, until ${two(cur[1])}:00</b>`; const nx = (list || []).find(([a]) => a > h) || (list || [])[0]; return nx ? `<b>${two(nx[0])}:00</b>` : '<b>-</b>'; };
    const lines = [['Free ramen', win(today.ramen)], ['Energy refill', `<b>${two(today.energyRefill)}:00</b>`]];
    if (today.god) lines.push(today.superNinja ? ['Super Ninja: ' + esc(today.god.name), `<b class="now">${Math.max(1, Math.ceil((today.god.until - now) / 60))} min left</b>`] : ['Super Ninja', win(today.week && today.week.superNinja)]);
    const day = today.week && today.week.days && today.week.days[today.week.day - 1];
    if (day && day.shardRush) lines.push(['Shard Rush', '<b class="now">today</b>']);
    $('pc-lines').innerHTML = lines.map(([a, b]) => `<div class="line"><span>${a}</span>${b}</div>`).join('');
    $('pc-events').innerHTML = (today.running || []).slice(0, 10).map((e) => `<li title="${esc(e)}">${esc(e)}</li>`).join('');
    $('pc-today').hidden = false;
  };
  function drawTop() {
    if (!top || !top.length) return;
    const me = (G().user || {}).nick;
    $('pc-ranks').innerHTML = top.map((p) => `<div class="rank${p.name === me ? ' me' : ''}"><span class="n">${p.rank}</span><span class="nm${p.glow ? ' glow' : ''}"${p.glow && /^[0-9a-f]{6}$/i.test(p.glow.color) ? ` style="color:#${p.glow.color}"` : ''}>${esc(p.name)}</span><span class="lv">Lv ${p.level}</span><span class="atk">${fmt(p.atk && p.atk[1])}</span></div>`).join('');
    $('pc-top').hidden = false;
  }
  const get = async (url) => { const r = await fetch(url); if (!r.ok) throw new Error(url + ' ' + r.status); return r.json(); };
  const status = async () => {
    if (!wideNow()) return;
    try { const s = await get('/status'); $('pc-status').innerHTML = '<span class="dot"></span>Online'; $('pc-online').textContent = fmt(s.online) + ' playing now'; $('pc-players').textContent = fmt(s.players); }
    catch { $('pc-status').innerHTML = '<span class="dot off"></span>Not reachable'; $('pc-online').textContent = ''; }
  };
  const slow = async () => {
    if (!wideNow()) return;
    try { today = await get('/api/today'); drawToday(); } catch { /* keeps what it showed */ }
    try { top = (await get('/api/top')).top; drawTop(); } catch { /* keeps what it showed */ }
  };
  let fetched = false;
  const live = () => { if (wideNow() && !fetched) { fetched = true; status(); slow(); } };
  setInterval(status, 60000); setInterval(slow, 300000); setInterval(drawToday, 20000);
  addEventListener('resize', live);

  const tick = () => { try { watch(); if (!wideNow()) return; live(); drawMe(); if (inGame()) { drawNav(); paintAll(); } } catch (e) { console.warn('stage', e); } };
  setInterval(tick, 300);

  // full screen and installing as an app
  right.querySelector('#pc-full').onclick = (e) => { fullScreen(); e.currentTarget.blur(); };
  document.addEventListener('fullscreenchange', () => { right.querySelector('#pc-full').textContent = document.fullscreenElement ? 'Window' : 'Full screen'; });
  let installEvent = null;
  addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); installEvent = e; right.querySelector('#pc-install').hidden = false; });
  addEventListener('appinstalled', () => { right.querySelector('#pc-install').hidden = true; });
  right.querySelector('#pc-install').onclick = () => { if (installEvent) { installEvent.prompt(); installEvent = null; right.querySelector('#pc-install').hidden = true; } };
})();
