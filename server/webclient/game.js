// Hello Bro web client: the game's screens (what libgame.so's C++ classes did), built on engine.js and net.js.
//   ?ccb=<layout>   shows one layout on its own (for checking the engine against the phone)
// Screens so far: login (CLoginScene, LoginView.ccbi), account window (the APK's Java window, gumplogin.js), character creation
// (CSelectCountryAvatorScene / CSelectRoleAvatorScene), home (CMainMenu + CDefaultMainMenu + NormalTopBar).
'use strict';
(async () => {
  const HB = window.HB, x = HB.x;
  const msg = (t) => { const m = document.getElementById('msg'); m.textContent = t || ''; m.style.display = t ? '' : 'none'; };
  HB.msg = msg;
  HB.start(document.getElementById('game'));
  await HB.loadStrings();
  const q = new URLSearchParams(location.search);
  const W = () => HB.size[0], H = () => HB.size[1];

  // The game lays its full-screen layouts out for a 768-wide screen and centres them on the 686-wide phone
  // (seen on the phone: the home screen's middle at 383 of 768 lands in the middle of 686).
  const FRAME = 768;
  function screen(file, owner, frame = FRAME) { // frame: 768 for the menus, the real width (W()) for the fight view
    const root = HB.build(file, owner, [frame, H()]);
    // the C++ puts a layout's root so that it covers the screen, whatever its anchor point
    const ign = root.ignoreAnchor;
    root.x = (ign ? 0 : root.ax * root.w) + (W() - frame) / 2;
    root.y = ign ? 0 : root.ay * root.h;
    return root;
  }
  // a modal layer: dims what is under it and swallows taps
  function modal(alpha = 150) {
    const m = new HB.LayerColor(); m.color = [0, 0, 0]; m.opacity = alpha; m.w = W(); m.h = H(); m.swallow = true; m.onTouch = () => {};
    return m;
  }
  // a short message in the middle of the screen (the game's ShowTextTip)
  function tip(text, sec = 2) {
    const l = new HB.Label(text, 'Arial-BoldMT', 26, [W() - 80, 0], 1, 1);
    l.x = W() / 2; l.y = H() / 2; l.stroke = ['#000', 2];
    const bg = new HB.LayerColor(); bg.color = [0, 0, 0]; bg.opacity = 170; bg.w = W(); bg.h = l.h + 40; bg.y = H() / 2 - bg.h / 2; bg.z = 900;
    l.z = 901;
    HB.scene.add(bg); HB.scene.add(l);
    HB.tween(bg, {}, sec, () => { bg.removeSelf(); l.removeSelf(); });
  }
  HB.tip = tip;
  // what the game's C++ kept about the player and the screens, for the Lua scripts (gamebind.js)
  HB.game = {
    user: null,
    changeToSub: (type) => { const name = Object.keys(HB.game.E || {}).find((k) => HB.game.E[k] === type) || type; tip('Coming soon: ' + String(name).replace(/^E_/, '').toLowerCase(), 1.2); },
    changeToActivity: (name) => tip('Coming soon: ' + name, 1.2),
  };
  const errorText = (root) => x.t(root, 'message') || HB.menu(root.code) || 'Error ' + root.code;
  let busy = null;
  HB.loading = (on) => loading(on);
  function loading(on) {
    if (on && !busy) { busy = modal(60); busy.z = 800; HB.scene.add(busy); }
    if (!on && busy) { busy.removeSelf(); busy = null; }
  }

  // ---------------------------------------------------------------- the layout viewer
  if (q.get('ccb')) {
    const name = q.get('ccb');
    await HB.loadCCB(name);
    const owner = { onButton: (sel) => console.log('tap', sel) };
    HB.scene.add(q.get('frame') === '0' ? HB.build(name, owner) : screen(name, owner));
    window.owner = owner;
    msg('');
    return;
  }

  // ---------------------------------------------------------------- account (the APK's account window, gumplogin.js)
  const S = HB.session;
  function deviceId() {
    if (q.get('device')) return 'web-test-' + q.get('device'); // test switch: the same test guest every run instead of a new one
    let d = HB.store.get('device');
    if (!d) { d = 'web-' + Array.from(crypto.getRandomValues(new Uint8Array(12)), (b) => b.toString(16).padStart(2, '0')).join(''); HB.store.set('device', d); }
    return d;
  }
  async function guestLogin() {
    const dev = deviceId(), pw = HB.store.get('guestpw');
    let r = pw ? await HB.account('/quick/login.do', { deviceId: dev, passwd: pw }) : null;
    if (!r || r.code !== 100000) { r = await HB.account('/quick/reg.do', { deviceId: dev, appkey: '' }); if (r.passwd) HB.store.set('guestpw', r.passwd); }
    return r;
  }
  async function signIn() {
    const name = HB.store.get('name'), pw = HB.store.get('namepw');
    const r = name && pw ? await HB.account('/gump/login.do', { deviceId: deviceId(), email: name, passwd: pw }) : await guestLogin();
    if (r && r.code === 100000) { S.uid = String(r.userId); S.session = r.sessionKey; S.nick = r.nick; return true; }
    return false;
  }
  // the account window: guest or a name + password (an HTML form over the canvas: the phone app's window is not game art either)
  function accountWindow(done) {
    const box = document.createElement('div');
    box.style.cssText = 'position:fixed;inset:0;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.6);z-index:10;font:16px Arial,sans-serif';
    box.innerHTML = `<form style="background:#f3e3c3;border:3px solid #7a4a1d;border-radius:12px;padding:18px;width:min(86vw,340px);color:#3a2410">
      <div style="font-weight:bold;font-size:19px;margin-bottom:10px;text-align:center">Account</div>
      <input name="u" placeholder="Name" autocomplete="username" style="width:100%;box-sizing:border-box;padding:10px;margin:4px 0;font-size:16px">
      <input name="p" type="password" placeholder="Password" autocomplete="current-password" style="width:100%;box-sizing:border-box;padding:10px;margin:4px 0;font-size:16px">
      <div id="err" style="color:#a00;min-height:20px;font-size:14px"></div>
      <div style="display:flex;gap:8px;margin-top:6px">
        <button name="login" style="flex:1;padding:10px;font-size:16px">Log in</button>
        <button name="signup" style="flex:1;padding:10px;font-size:16px">Sign up</button></div>
      <button name="guest" style="width:100%;padding:10px;margin-top:8px;font-size:16px">Play as guest</button></form>`;
    document.body.appendChild(box);
    const f = box.querySelector('form'), err = box.querySelector('#err');
    const CODES = { 100010: 'Wrong password', 100011: 'That name is taken', 100012: 'No account with that name', 100013: 'Name or password too short' };
    f.addEventListener('submit', async (e) => {
      e.preventDefault();
      const which = e.submitter && e.submitter.name, u = f.u.value.trim(), p = f.p.value;
      let r;
      try {
        if (which === 'guest') { HB.store.set('name', null); HB.store.set('namepw', null); r = await guestLogin(); }
        else r = await HB.account(which === 'signup' ? '/gump/reg.do' : '/gump/login.do', { deviceId: deviceId(), email: u, passwd: p, appkey: '' });
      } catch { err.textContent = 'Cannot reach the server'; return; }
      if (!r || r.code !== 100000) { err.textContent = CODES[r && r.code] || 'Something went wrong'; return; }
      if (which !== 'guest') { HB.store.set('name', u); HB.store.set('namepw', p); }
      S.uid = String(r.userId); S.session = r.sessionKey;
      box.remove(); done();
    });
  }

  // ---------------------------------------------------------------- login screen (CLoginScene, LoginView.ccbi)
  async function loginScreen() {
    HB.scene.removeAll();
    await HB.loadCCB('LoginView');
    const owner = {};
    const root = screen('LoginView', owner);
    HB.scene.add(root);
    let servers = [];
    try {
      const dir = await HB.api('xk_r_dir', { Cmd: 2, Pt: 1062, GroupID: 2, Version: '28.0' }, { bare: true });
      servers = x.all(dir, 'server').map((s) => ({ id: Number(x.t(s, 'id') || x.a(s, 'id')), name: x.t(s, 'name') || x.a(s, 'name') }));
    } catch { tip('Cannot reach the server'); }
    S.server = Number(HB.store.get('server')) || (servers[0] && servers[0].id) || 1;
    const show = () => {
      const sv = servers.find((s) => s.id === S.server);
      owner.n.label_servername && owner.n.label_servername.setText(sv ? sv.name : 'Server ' + S.server);
      owner.n.label_idname && owner.n.label_idname.setText(S.uid || '');
    };
    owner.n.label_LoginView0 && owner.n.label_LoginView0.setText('Change');
    owner.n.label_versioninfo && owner.n.label_versioninfo.setText('V28.0');
    if (await signIn().catch(() => false)) show(); else show();
    owner.onButton = async (sel) => {
      if (sel === 'BtnReg') accountWindow(show);
      else if (sel === 'BtnSelectServer') {
        if (servers.length > 1) { const i = servers.findIndex((s) => s.id === S.server); S.server = servers[(i + 1) % servers.length].id; HB.store.set('server', S.server); show(); }
      } else if (sel === 'BtnLogin') enterGame();
    };
    if (q.get('auto')) setTimeout(enterGame, 300); // test switch: walk on by itself (screenshots, tools/dev/pageshot.js)
  }

  async function enterGame() {
    if (!S.session && !(await signIn().catch(() => false))) return tip('Cannot reach the server');
    loading(true);
    try {
      const r = await HB.api('rl_w_login2', { Uin: S.uid, Session: S.session, Cmd: 2200 }, { bare: true });
      if (r.code) { loading(false); return tip(errorText(r)); }
      if (x.n(r, 'hasreg') === 0) { loading(false); return createCharacter(); }
      await HB.api('xk_w_dir', { Cmd: 1, Area: 1, Uid: S.uid, Session: S.session, Pt: 1062 }, { bare: true });
      await homeScreen();
    } catch (e) { tip('Cannot reach the server'); console.error(e); }
    loading(false);
  }

  // ---------------------------------------------------------------- character creation (country, then ninja + name)
  async function createCharacter() {
    HB.scene.removeAll();
    await HB.loadCCB('SelectorCountryAvatar');
    const o = {};
    HB.scene.add(screen('SelectorCountryAvatar', o));
    // the phones send 1-4 (live saves only hold 1-4); the layout's icons 02-05 are those countries (01 = Wind, 0, not offered)
    let country = 1;
    const showC = () => { for (let i = 1; i <= 5; i++) { const on = i === country + 1; for (const k of ['iconMap', 'icon']) { const nd = o.n[`selector_country_${k}_0${i}`]; if (nd) nd.visible = on; } } };
    showC();
    o.onButton = (sel) => {
      if (sel === 'BtnNext') return pickNinja(country);
      if (/Pre|Left/i.test(sel)) { country = country === 1 ? 4 : country - 1; showC(); }
      if (/Next|Right/i.test(sel)) { country = country === 4 ? 1 : country + 1; showC(); }
    };
    if (q.get('auto')) setTimeout(() => o.onButton('BtnNext'), 800);
    for (const [nm, d] of [['spr_preC', -1], ['spr_nextC', 1]]) { const s = o.n[nm]; if (s) s.onTouch = (ev) => { if (ev === 'up') { country = ((country - 1 + d + 4) % 4) + 1; showC(); } }; }
  }
  async function pickNinja(country) {
    HB.scene.removeAll();
    await HB.loadCCB('SelectorRoleAvatar');
    const o = {};
    HB.scene.add(screen('SelectorRoleAvatar', o));
    // ORIGINAL starters: Neji 55 / Sakura 56 / Shikamaru 57 (gumplogin / handlers rl_w_reg2: the screen sends the ninja id)
    const NINJA = { 3: 55, 4: 56, 5: 57 }; // which picture is which ninja: (ours, to check on the phone)
    let role = 4;
    const showR = () => { for (const i of [3, 4, 5]) { for (const [k, v] of [['btnSel', true], ['btnUnSel', false], ['desc', true]]) { const nd = o.n[`selector_role_00${i}_${k}`]; if (nd) nd.visible = (i === role) === v; } } };
    showR();
    let nick = '';
    const nameLabel = new HB.Label('', 'Arial-BoldMT', 26); nameLabel.color = [255, 255, 255];
    const input = o.n.selector_role_inputName;
    if (input) { nameLabel.x = input.w / 2; nameLabel.y = input.h / 2; input.add(nameLabel); input.onTouch = (ev) => { if (ev === 'up') { const v = prompt('Your name', nick); if (v) { nick = v.trim().slice(0, 12); nameLabel.setText(nick); } } }; }
    const roll = async () => { try { const r = await HB.api('rl_r_randname', { Cmd: 1 }); nick = x.t(r, 'name'); nameLabel.setText(nick); } catch { /* keep */ } };
    await roll();
    if (q.get('auto')) setTimeout(() => o.onButton('BtnOk'), q.get('auto') === 'slow' ? 4000 : 800);
    o.onButton = async (sel) => {
      const m = /BtnRole_00(\d)/.exec(sel);
      if (m) { role = Number(m[1]); showR(); return; }
      if (sel === 'BtnRollName') return roll();
      if (sel === 'BtnOk') {
        if (!nick) return tip('Please enter a name');
        loading(true);
        try {
          const r = await HB.api('rl_w_reg2', { Nick: nick, Country: country, Card: NINJA[role] });
          loading(false);
          if (r.code) return tip(errorText(r));
          return enterGame();
        } catch { loading(false); tip('Cannot reach the server'); }
      }
    };
  }

  // ---------------------------------------------------------------- home (CMainMenu, CDefaultMainMenu, NormalTopBar)
  const tables = {};
  const table = async (name) => (tables[name] = tables[name] || (await HB.json('data/' + name + '.json')));
  async function homeScreen() {
    const [main] = await Promise.all([HB.api('rl_r_mainpage', { Cmd: 1302 }), table('playerlevel'), table('functionconfig'), HB.loadCCB('MainMenu'), HB.loadCCB('sub_ui/DefaultMainMenu')]);
    if (main.code) return tip(errorText(main));
    const country = x.n(x.first(main, 'user'), 'country');
    const village = 'sub_ui/' + countryName(country) + 'CountryDefaultMenu';
    await HB.loadCCB(village);
    HB.scene.removeAll();
    HB.scene.children.slice().forEach((c) => HB.luaLeave && HB.luaLeave(c));
    const o = { onButton: (sel, btn) => homeButton(sel, btn) };
    const root = screen('MainMenu', o);
    HB.game.menu = o; HB.game.root = root; HB.game.main = main;
    selectBar('btn_mainpage');
    // the home part goes into node_content, laid out in the same 768-wide frame as MainMenu (CMainMenu::ChangeToSubView)
    const content = o.n.node_content;
    content.removeAll();
    const sub = HB.build('sub_ui/DefaultMainMenu', o, [FRAME, content.h]);
    sub.x = -content.x + content.ax * content.w + (sub.ignoreAnchor ? 0 : sub.ax * sub.w); sub.y = sub.ignoreAnchor ? 0 : sub.ay * sub.h;
    sub.h = H(); // CCLayer::init makes a layer as tall as the screen; the scripts place the event buttons from that height (mainActivity.lua: height - 550)
    sub.tag = 1001; // the home part as the scripts find it (GetSubContentNode():getChildByTag(1001))
    content.add(sub);
    // the village behind it (CDefaultSLGMenu::init: sub_ui/<country>CountryDefaultMenu.ccbi into node_slgcontent)
    const slg = o.n.node_slgcontent;
    if (slg) { const v = HB.build(village, o, [slg.w, slg.h]); v.x = v.ignoreAnchor ? 0 : v.ax * v.w; v.y = v.ignoreAnchor ? 0 : v.ay * v.h; slg.add(v); }
    const icon = HB.frame('home/home_btns.plist', countryName(country) + '_icon'), halo = HB.frame('home/home_btns.plist', countryName(country) + '_halo');
    if (icon && o.n.node_country_icon) o.n.node_country_icon.setFrame(icon);
    if (halo && o.n.node_country_halo) o.n.node_country_halo.setFrame(halo);
    HB.scene.add(root);
    fillTopBar(o, main);
    const n = o.n, u = x.first(main, 'user');
    n.label_maxattack && n.label_maxattack.setText(`${x.n(u, 'attactlow')}-${x.n(u, 'attacthigh')}`);
    n.label_maxdefense && n.label_maxdefense.setText(`${x.n(u, 'defenselow')}-${x.n(u, 'defensehigh')}`);
    n.label_maxhonor && n.label_maxhonor.setText(String(x.n(u, 'meritscore')));
    // locked buildings say "Unlock at Lv.N" (CDefaultMainMenu::InitUI: functionconfig 1 / 5 / 2 / 22, menu text 272)
    const lv = x.n(u, 'level');
    for (const [tipNo, fc] of [[1, 1], [2, 5], [3, 2], [4, 22]]) {
      const need = (tables.functionconfig.rows.find((r) => r[0] === fc) || [])[3] || 0;
      const node = n['node_leveltip' + tipNo], label = n['label_leveltip' + tipNo];
      if (node) node.visible = lv < need;
      if (label) label.setText(HB.menu(272).replace('%d', need));
    }
    for (const k of ['sprite_activity_frame', 'label_activity_news', 'sprite_msg_frame', 'label_msg_news']) if (n[k]) n[k].visible = false; // counts come later
    HB.home = { o, main };
    HB.game.subOwner = o;
    { const ci = x.first(main, 'chapinfo'); HB.game.chap = { cur: Number(x.a(ci, 'currentchap', 1)), stage: Number(x.a(ci, 'currentstage', 1)) }; }
    // the player's numbers for the scripts (CPlayerDataMgr), from <user>
    HB.game.user = Object.fromEntries([...u.children].map((c) => [c.nodeName, c.textContent]));
    HB.game.subContent = content;
    HB.game.refreshTopBar = () => { const uu = x.first(main, 'user'); for (const [k, v] of Object.entries(HB.game.user)) { const e = x.first(uu, k); if (e) e.textContent = v; } fillTopBar(o, main); };
    await luaHome(o);
  }
  // the home screen's Lua parts (what CDefaultMainMenu::InitUI asks the Lua engine for): the game's mainActivity.lua first,
  // then the row of small buttons (script/MenuBtnsView.lua InitMenuBtnsView)
  async function luaHome(o) {
    try {
      HB.game.currentSubType = 1; // E_DEFAULTMENU (gamebind.js numbers)
      if (!HB.L) { await HB.startLua({ openGame: HB.openGame }); HB.luaRun('mainActivity.lua'); await HB.luaSettle(); }
      const menu = new HB.CCBProxy(); menu.owner = o; // CDefaultMainMenu as the scripts see it: getNode(name) = the layout's named nodes
      if (HB.luaRun('MenuBtnsView.lua')) HB.luaGlobal('InitMenuBtnsView', menu);
      HB.luaGlobal('initMainMenuActivityBtn'); // CDefaultMainMenu::onEnterTransitionDidFinish: the event buttons on the left
      // test switch: &tap=<button name>[,<button name>...] presses home buttons one after another (screenshots)
      if (q.get('tap')) for (const nm of q.get('tap').split(',')) { await HB.wait(1.5); const b = o.n[nm] || (HB.find && HB.find(nm)); if (b) HB.tapNode(b); else console.warn('no button ' + nm); }
    } catch (e) { HB.luaError(e); }
  }
  // CProfileData::firefly_GetCountryLayoutName: 0 Wind, 1 Mine (thunder), 2 Water, 3 Fire, 4 Earth, anything else Fire
  // VIP badge per VIP level (the game's own list, e.g. CommonBuyItemDialog.lua m_vipframes)
  const VIP_FRAMES = ['vip_015', 'vip_003', 'vip_004', 'vip_005', 'vip_006', 'vip_007', 'vip_008', 'vip_009', 'vip_010', 'vip_011', 'vip_012', 'vip_013', 'vip_014', 'vip_s_13', 'vip_s_14', 'vip_s_15', 'vip_s_16', 'vip_s_17', 'vip_s_18'];
  const countryName = (c) => ['Wind', 'Mine', 'Water', 'Fire', 'Earth'][c] || 'Fire';
  function fillTopBar(o, main) {
    const n = o.n, u = x.first(main, 'user');
    const level = x.n(u, 'level');
    const row = (tables.playerlevel ? tables.playerlevel.rows : []).find((r) => r[1] === level) || [];
    const need = row[2] || 0, maxEnergy = row[4] || x.n(u, 'curaction'); // playerlevel: [2] exp needed, [4] energy (m_own_strengval)
    HB.game.needExp = need; HB.game.maxEnergy = maxEnergy;
    const set = (k, v) => n[k] && n[k].setText(String(v));
    set('label_name', x.t(u, 'nick'));
    set('label_level', level);
    set('label_curexp', `${x.n(u, 'score')}/${need}`);
    set('label_goldval', x.n(u, 'cash'));
    set('label_silverval', x.n(u, 'coin'));
    set('label_bodyval', `${x.n(u, 'curaction')}/${maxEnergy}`);
    set('label_attackval', `${x.n(u, 'cursp')}/5`);
    const bar = (k, f) => { if (n[k]) n[k].sx = Math.max(0, Math.min(1, f)); };
    bar('sprite_levelstate', need ? x.n(u, 'score') / need : 0);
    bar('sprite_bodyratio', maxEnergy ? x.n(u, 'curaction') / maxEnergy : 0);
    bar('sprite_attackratio', x.n(u, 'cursp') / 5);
    const vip = Math.min(18, x.n(u, 'viplevel'));
    const fv = HB.frame('com_res/Resident_2.plist', VIP_FRAMES[vip]);
    if (n.sprite_vipinfo && fv) n.sprite_vipinfo.setFrame(fv);
  }
  function homeButton(sel, btn) {
    // buttons whose screens are the game's own Lua (CDefaultMainMenu::onBtnActivity ...)
    if (sel === 'BtnActivity' && HB.L) { if (HB.luaRun('business_proxy/activityPopup_business.lua')) HB.luaGlobal('initactivityPopupLayer'); return; }
    // the bottom bar (CMainMenu::onBtnDefault / onBtnMyTeam / onBtnBackpack / the Training, Spar and Shop buttons)
    if (sel === 'BtnMainMenu') return homeScreen();
    if (sel === 'BtnRound') return HB.screens.training();
    tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2);
  }
  // the bottom bar's marker sits behind the chosen button
  function selectBar(name) {
    const m = HB.game.menu && HB.game.menu.n;
    if (m && m.sprite_clickbk && m[name]) m.sprite_clickbk.x = m[name].x;
  }
  // put another screen into MainMenu's content area (CMainMenu::ChangeToSubView): a layout in the 768-wide frame
  HB.game.showSub = (file, owner, barButton) => {
    const content = HB.game.subContent;
    const old = content.children.slice(); content.removeAll(); old.forEach((c) => HB.luaLeave && HB.luaLeave(c));
    owner.onButton = owner.onButton || ((sel) => tip('Coming soon: ' + sel, 1.2));
    const sub = HB.build(file, owner, [FRAME, content.h]);
    sub.x = -content.x + content.ax * content.w + (sub.ignoreAnchor ? 0 : sub.ax * sub.w); sub.y = sub.ignoreAnchor ? 0 : sub.ay * sub.h;
    content.add(sub);
    HB.game.currentSubType = 0;
    if (barButton) selectBar(barButton);
    fillTopBar(owner, HB.game.main);
    const n = owner.n, u = x.first(HB.game.main, 'user');
    n.label_maxattack && n.label_maxattack.setText(`${x.n(u, 'attactlow')}-${x.n(u, 'attacthigh')}`);
    n.label_maxdefense && n.label_maxdefense.setText(`${x.n(u, 'defenselow')}-${x.n(u, 'defensehigh')}`);
    n.label_maxhonor && n.label_maxhonor.setText(String(x.n(u, 'meritscore')));
    HB.game.subOwner = owner;
    return sub;
  };
  // after something changed the player's numbers (a fight, a purchase): ask the server again and fill the top bar on screen
  HB.game.refresh = async () => {
    try {
      const main = await HB.api('rl_r_mainpage', { Cmd: 1301, HornFlag: 1 });
      if (main.code) return;
      HB.game.main = main;
      const u = x.first(main, 'user');
      HB.game.user = Object.fromEntries([...u.children].map((c) => [c.nodeName, c.textContent]));
      const ci = x.first(main, 'chapinfo');
      if (ci) HB.game.chap = { cur: Number(x.a(ci, 'currentchap', 1)), stage: Number(x.a(ci, 'currentstage', 1)) };
      if (HB.game.subOwner) fillTopBar(HB.game.subOwner, main);
    } catch (e) { /* keeps the old numbers */ }
  };
  HB.screens = HB.screens || {};
  HB.ui = { screen, modal, tip, loading, errorText: (r) => errorText(r), W, H, FRAME, table, tables, fillTopBar: (o, m) => fillTopBar(o, m), VIP_FRAMES: () => VIP_FRAMES, x, msg };

  msg('');
  await loginScreen();
  window.HBGame = { homeScreen, loginScreen, enterGame };
})();
