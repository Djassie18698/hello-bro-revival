// The "system" pieces around every screen (C++ on the phone, CMainMenu and its helpers). What each one is on the phone, from re/all.txt:
//   Loading picture   CModalLoadingLayer, sub_ui/LoadingView.ccbi (a spinner, timeline loadinganim) while a request runs;
//                     ShowUnvisibleLoadingDlg = the same cover without the spinner. game.js's loading() hands over to SYS.loading.
//   Time-out window   CTimeOutDlg, dlg_ui/TimeOutDialogView.ccbi (CMainMenu::ShowTimeOutDlg): the server did not answer; its button
//                     (BtnReLoad) sends the same request again. Here: HB.api is wrapped, a request that fails in the game waits for it.
//   Top banner        CMainMenu::InitAnnounceMsg / NextAnnounceMsg / UpdateTopAnnounce: a 24-point label in MenuTopbar's node_inform
//                     that runs right to left through the rows of the game's own sysnotice table, one after another.
//   Notice            CMainMenu::ShowSystemNotice: dlg_ui/NormalNotice.ccbi (timeline showspeaker) with a bulletin of rl_r_bulletin
//                     (CSystemADMgr::LoadNotice): level above 4, between its begin and end time, type 1 once per device
//                     (SaveLocalNotice), type 2 once per session.
//   Marquee           the game's own ui_layer/ui_borderWarTip.lua (CSystemADMgr::openProvokeNoticeLua runs it on a timer): asks
//                     rl_r_marquee and shows MarqueeTipView.ccbi through ui_marqueeShowTip.lua. The script does all of it.
//   Red bubbles       Home: sprite_activity_frame / label_activity_news = CPlayerDataMgr's ActivityNewsNum (the scripts set it,
//                     RefreshActivityTips shows it); sprite_msg_frame / label_msg_news = CNoticeDataMgr::GetNewMsgCount after
//                     CNoticeDataHelper::requestAllNoticeInfo (rl_r_msg Cmd 1800, 1801, 1802; CDefaultMainMenu::InitMsgCount).
//   Glowing names     ours (server/specialnames.js): the hot-updated util/common.lua PurpleGlow draws it. The No.1 Shinobi list calls
//                     it itself; the top bar's name (C++ on the phone, PurpleTopBar finds it through GetCurrentSubMenu) is handed
//                     to the same Lua function from here, on every screen that has the top bar. Asked with rl_r_purplename.
//   Team compare      CNewTeamCompareView, core_combat/NewTeamCompare.ccbi + dlg_ui/TeamCompareItemView.ccbi: the "Team compare"
//                     button of the Victory and Defeat screens (CNewResultWinView / CNewResultFailView::ShowCompareTeam) lays it
//                     into the result's content layer: one row per place, my card left, theirs right.
//   Next-day ad       CNextDayAd, activity/NextDayAd.ccbi: one line ("come again tomorrow ...", menu text 287) in node_adlayer of
//                     the running-ninja loading box (CAnimationView: animations/chutianloading | gangshouloading | xiaoyingloading,
//                     timeline runloading), only on the first login day (CAnimationView::InitUI: TotalLoginDay 1, ContinueLoginDays 0).
// Not built, because the v28 phone never shows them (re/all.txt has no caller of their constructors):
//   sub_ui/SystemNotice (CSystemNotice is never created; the only other user, script/InGameNoticeListView.lua, has the body of
//   showInGameNoticeView commented out: "inner notices closed for now"), activity/DaysAd (CDaysAd), dlg_ui/NoTouchTimeOutDialogView
//   (CNoTouchTimeOutDlg), dlg_ui/TeamCompareView (CTeamCompareView: the Friends / Arena / Spar lists have no compare window).
// Test switches: &sys=timeout | notice | loading | compare | ad (comma list), tried two seconds after Home is up.
'use strict';
(function () {
  const HB = window.HB, Lua = window.Lua;
  const q = new URLSearchParams(location.search);
  const SYS = (HB.system = { glow: null, actNews: 0, msgNews: 0, loginDays: 0, news: '' });
  const W = () => HB.size[0], H = () => HB.size[1];
  const num = (v) => Number(v) || 0;
  const clean = (s) => String(s == null ? '' : s).replace(/\0+$/, '').trim();
  const asLua = (fn) => (...a) => { const r = fn(...a); return Array.isArray(r) ? r : r === undefined ? Lua.R.EMPTY : [r]; };
  // a layout laid over the whole screen
  const full = (file, owner, size) => { const r = HB.build(file, owner, size || [W(), H()]); r.x = r.ignoreAnchor ? 0 : r.ax * r.w; r.y = r.ignoreAnchor ? 0 : r.ay * r.h; return r; };
  const cover = (alpha, z) => { const m = new HB.LayerColor(); m.color = [0, 0, 0]; m.opacity = alpha; m.w = W(); m.h = H(); m.swallow = true; m.onTouch = () => {}; m.z = z; return m; };
  const inGame = () => !!(HB.game && HB.game.menu && HB.game.menu.n);
  const api0 = HB.api; // the plain request (net.js), for the quiet questions asked from here

  // ---------------------------------------------------------------- loading picture
  const SPIN_AFTER = 300; // (ours) the spinner comes after 0.3 s: our server answers at once, the phone's picture would only flicker
  let busy = null;
  SYS.loading = (on, unseen) => {
    if (on && !busy) {
      busy = cover(0, 800); HB.scene.add(busy);
      const mine = busy;
      const spin = () => {
        if (busy !== mine || !mine.parent || !HB.docs['sub_ui/LoadingView']) return;
        const v = full('sub_ui/LoadingView', {}); mine.add(v); HB.play(v, 'loadinganim');
      };
      if (!unseen) mine._t = setTimeout(spin, q.get('sys') === 'loading' ? 0 : SPIN_AFTER);
    }
    if (!on && busy) { clearTimeout(busy._t); busy.removeSelf(); busy = null; }
  };

  // ---------------------------------------------------------------- time-out window
  const TIMEOUT = 20000; // (ours) how long a request may take; the phone's own limit is not known
  let asking = null;
  function timeoutWindow() {
    if (asking) return asking;
    asking = (async () => {
      await HB.loadCCB('dlg_ui/TimeOutDialogView');
      await new Promise((ok) => {
        const dim = cover(0, 850);
        const o = { onButton: (sel) => { if (sel === 'BtnReLoad') { dim.removeSelf(); ok(); } } };
        dim.add(full('dlg_ui/TimeOutDialogView', o)); HB.scene.add(dim);
        dim.fade = 0; HB.tween(dim, { fade: 1 }, 0.14);
        SYS.timeoutOpen = o;
      });
      asking = null; SYS.timeoutOpen = null;
    })();
    return asking;
  }
  SYS.timeoutWindow = timeoutWindow;
  HB.api = async function (cgi, params, opts) {
    for (;;) {
      let timer;
      try {
        return await Promise.race([api0(cgi, params, opts), new Promise((_, no) => { timer = setTimeout(() => no(new Error('network')), TIMEOUT); })]);
      } catch (e) {
        if (!e || e.message !== 'network' || !inGame() || (opts && opts.bare)) throw e; // the login screen keeps its own message
        await timeoutWindow();
      } finally { clearTimeout(timer); }
    }
  };

  // ---------------------------------------------------------------- top banner
  const HAN = /[一-鿿]/; // (ours) rows 5 and 6 of the English game's table are still Chinese: left out
  const SPEED = 60; // points a second (by eye: the Lua marquee moves one point a frame)
  const banner = { box: null, label: null, at: -1 };
  function bannerTexts() {
    const rows = ((HB.ui && HB.ui.tables.sysnotice) || {}).rows || [];
    const list = rows.map((r) => clean(r[2])).filter((t) => t && !HAN.test(t));
    return (SYS.news ? [SYS.news] : []).concat(list); // (ours) the Server Manager's announcement runs through first; the phone only has it under News > System
  }
  function bannerNext() {
    const list = bannerTexts(), l = banner.label;
    if (!list.length) { l.visible = false; return; }
    banner.at = (banner.at + 1) % list.length;
    l.setText(list[banner.at].replace(/\s*\n\s*/g, ' ')); l.visible = true; l.x = banner.box.w;
  }
  function bannerAttach(box) {
    banner.box = box; box.clip = true;
    const l = (banner.label = new HB.Label('', 'Helvetica', 24)); // CCLabelTTF::create(text, font, 24), colour 210 160 110 (InitAnnounceMsg)
    l.ax = 0; l.ay = 0.5; l.color = [210, 160, 110]; l.y = box.h / 2;
    box.add(l);
    bannerNext();
  }
  function bannerTick(dt) {
    const l = banner.label;
    if (!l || !l.parent) return;
    if (!l.visible) { if ((banner.wait = (banner.wait || 0) + dt) > 1) { banner.wait = 0; bannerNext(); } return; }
    l.x -= SPEED * dt;
    if (l.x < -l.w) bannerNext();
    l.opacity = banner.marquee ? 0 : 255; // the scripts' marquee (MarqueeTipView) lies on the same bar while it runs
  }

  // ---------------------------------------------------------------- notice (the bulletin with the speaker)
  const shownNow = new Set();
  let bulletins = null, noticeUp = false;
  async function showNotice(text) {
    if (noticeUp) return;
    noticeUp = true;
    try {
      await HB.loadCCB('dlg_ui/NormalNotice');
      const o = {};
      const v = HB.ui.screen('dlg_ui/NormalNotice', o);
      v.z = 560;
      if (o.n.labelDescription) o.n.labelDescription.setText(String(text).replace(/\\n/g, '\n'));
      HB.scene.add(v);
      await new Promise((ok) => { HB.play(v, 'showspeaker', ok); setTimeout(ok, 4000); });
      v.removeSelf();
    } catch (e) { console.warn('notice', e); }
    noticeUp = false;
  }
  SYS.showNotice = showNotice;
  async function bulletin() {
    const x = HB.x;
    if (num((HB.game.user || {}).level) <= 4) return; // CMainMenu::ShowSystemNotice: not below level 5
    if (!bulletins) {
      const r = await api0('rl_r_bulletin', { Cmd: 1 });
      const now = x.n(r, 'servertime');
      bulletins = x.all(r, 'bulletin').map((b) => ({ id: x.n(b, 'id'), type: x.n(b, 'type'), begin: x.n(b, 'begintime'), end: x.n(b, 'endtime'), text: x.t(b, 'content'), now }));
    }
    for (const b of bulletins) {
      if (!(b.begin < b.now && b.now < b.end) || !b.text) continue;
      if (b.type === 1) { if (HB.store.get('notice.' + b.id)) continue; HB.store.set('notice.' + b.id, '1'); }
      else if (b.type === 2) { if (shownNow.has(b.id)) continue; shownNow.add(b.id); }
      else continue;
      await showNotice(b.text);
    }
  }

  // ---------------------------------------------------------------- Home's red bubbles
  function bubbles() {
    const n = HB.home && HB.home.o && HB.home.o.n;
    if (!n) return;
    const put = (frame, label, count) => {
      if (n[frame]) n[frame].visible = count > 0;
      if (n[label]) { n[label].visible = count > 0; if (count > 0) n[label].setText(String(Math.min(99, count))); }
    };
    // Like the phone (compared 22 Nov 2026): CDefaultMainMenu::InitUI hides the layout's four counter nodes for good.
    //   Event: the layout's red ball sprite_notify_activity shows while ActivityNewsNum > 0 (RefreshActivityTips), no number.
    //   News: the count sits on the News button of the small row, drawn by the game's own MenuBtnsView.lua SetMessageCount;
    //   the red ball on that row's 7th button is its SetReincarnationCount (item 11 owned, 80 or more) (CDefaultMainMenu::InitMsgCount).
    put('sprite_activity_frame', 'label_activity_news', 0);
    put('sprite_msg_frame', 'label_msg_news', 0);
    if (n.sprite_notify_activity) n.sprite_notify_activity.visible = SYS.actNews > 0;
    try { if (HB.L && HB.L.get('SetMessageCount') !== undefined) { HB.luaGlobal('SetMessageCount', String(SYS.msgNews)); const balls = () => HB.luaGlobal('SetReincarnationCount', (HB.game.items && HB.game.items.get(11)) || 0); balls(); if (HB.game.loadItems && !SYS.itemsAsked) { SYS.itemsAsked = true; HB.game.loadItems().then(balls).catch(() => {}); } } } catch (e) { if (HB.luaError) HB.luaError(e); }
  }
  SYS.bubbles = bubbles;
  // the three News lists, like CNoticeDataHelper::requestAllNoticeInfo; unread = iStatus 0 (our reading of GetNewMsgCount)
  let newsAt = 0;
  async function loadNews() {
    if (Date.now() - newsAt < 5000) return;
    newsAt = Date.now();
    const x = HB.x;
    const lists = await Promise.all([1800, 1801, 1802].map((cmd) => api0('rl_r_msg', { Cmd: cmd, Page: 1 }).catch(() => null)));
    let unread = 0;
    lists.forEach((r, i) => { for (const m of x.all(r, 'msg')) if (x.t(m, 'iStatus') === '0' && (i < 2 || clean(x.t(m, 'text')))) unread++; });
    SYS.msgNews = unread;
    const note = lists[2] && x.first(lists[2], 'msg');
    SYS.news = note ? clean(x.t(note, 'text')) : '';
    bubbles();
  }
  SYS.loadNews = () => { newsAt = 0; return loadNews(); };

  // ---------------------------------------------------------------- the scripts' side: news count, login days
  function patchLua() {
    const B = HB.lua.B, G = HB.L.G;
    const cls = G.get(B('CPlayerDataMgr')), inst = cls && cls.get(B('instance'));
    if (inst) {
      const got = inst(cls), obj = Array.isArray(got) ? got[0] : got;
      const over = {
        SetActivityNewsNum: asLua((self, v) => { SYS.actNews = Math.max(0, num(v)); bubbles(); }), GetActivityNewsNum: asLua(() => SYS.actNews),
        SetTotalLoginDay: asLua((self, v) => { SYS.loginDays = num(v); }),
      };
      const proxy = { luaGet(k) { const f = over[Lua.fromBytes(String(k))]; return f || obj.luaGet(k); }, luaSet(k, v) { obj.luaSet(k, v); } };
      cls.set(B('instance'), () => [proxy]); cls.set(B('sharedInstance'), () => [proxy]);
    }
    G.set(B('RefreshActivityTips'), asLua(() => { bubbles(); }));
  }

  // ---------------------------------------------------------------- glowing name in the top bar
  async function askGlow() {
    try {
      const r = await api0('rl_r_purplename', { Cmd: 1 }), p = HB.x.first(r, 'purple');
      SYS.glow = p && p.getAttribute('glow') === '1' ? { color: p.getAttribute('color') || 'af46ff', fx: p.getAttribute('fx') || '' } : null;
    } catch (e) { /* keeps what it knew */ }
  }
  function glowTick() {
    if (!HB.L || !SYS.glow || HB.L.get('PurpleGlow') === undefined) return;
    const o = HB.game.subOwner, l = o && o.n && o.n.label_name;
    if (!l || !l.parent || !(l instanceof HB.Label) || !l.shown()) return;
    const B = HB.lua.B;
    HB.luaGlobal('PurpleGlow', l, B(SYS.glow.color), B(SYS.glow.fx)); // returns at once when this label already glows with this text
  }

  // ---------------------------------------------------------------- the running-ninja box of the first load, with the next-day ad
  const RUN = ['animations/chutianloading', 'animations/gangshouloading', 'animations/xiaoyingloading'];
  let boot = null, booted = false, bootEnd = Promise.resolve();
  async function bootCover() {
    const b = (boot = { dim: cover(200, 790), o: {} });
    bootEnd = new Promise((ok) => { b.end = ok; });
    HB.scene.add(b.dim);
    b.guard = setTimeout(() => bootDone(true), 15000);
    const file = RUN[Math.floor(Math.random() * RUN.length)];
    await Promise.all([HB.loadCCB(file), HB.loadCCB('activity/NextDayAd')]);
    if (boot !== b || !b.dim.parent) return;
    b.view = HB.ui.screen(file, b.o); b.dim.add(b.view); HB.play(b.view, 'runloading');
    const l = b.o.n['label_' + file.split('/').pop() + '0']; if (l && HAN.test(l.text)) l.setText('Loading'); // the game's English text when the table has one
  }
  async function bootDone(now) {
    const b = boot;
    if (!b) return;
    boot = null; clearTimeout(b.guard);
    const box = b.o.n && b.o.n.node_adlayer;
    if (!now && box && (SYS.loginDays === 1 || /\bad\b/.test(q.get('sys') || ''))) {
      const ao = {};
      box.add(full('activity/NextDayAd', ao, [box.w, box.h]));
      const l = ao.n.lable_nexttips;
      if (l) { l.setText(HB.menu(287) || l.text); if (l.w > box.w - 24) l.sx = l.sy = (box.w - 24) / l.w; } // CNextDayAd::InitUI: LabelHelper::setLabelByID(label, 287)
      // (ours) the phone's loading lasts long enough to read it; ours is over at once, so it stays 2.5 s (not when a test walks by itself)
      if (!q.get('auto') || q.get('sys')) await new Promise((ok) => setTimeout(ok, 2500));
    }
    b.dim.removeSelf(); b.end();
  }
  if (HB.startLua) {
    const start0 = HB.startLua;
    HB.startLua = async function (game) {
      bootCover().catch(() => {});
      const L = await start0.call(this, game);
      try { patchLua(); } catch (e) { console.warn('system.js: the scripts hooks', e); }
      return L;
    };
    const settle0 = HB.luaSettle;
    HB.luaSettle = async function (...a) { const r = await settle0.apply(this, a); if (!booted) { booted = true; bootDone(); } return r; };
  }

  // ---------------------------------------------------------------- team compare (Victory / Defeat screens)
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' }; // util/tools.lua getAttributeIcon
  const CMP = ['core_combat/NewTeamCompare', 'dlg_ui/TeamCompareItemView'];
  function fightTeams(reply) {
    const x = HB.x, fight = x.first(reply, 'fight');
    const side = (tag) => x.all(x.first(fight, tag), 'ninja').map((c) => ({ id: x.n(c, 'id'), level: x.n(c, 'level') || 1, attri: x.n(c, 'attri') }));
    return fight ? { mine: side('killer'), foes: side('guard') } : { mine: [], foes: [] };
  }
  function compareSide(m, who, c) {
    const box = m['node_' + (who === 'my' ? 'myteam' : 'enemy')];
    if (!c) { if (box) box.visible = false; return; }
    const inf = HB.info(1, c.id), r = inf.row || [], lv = Math.max(1, c.level) - 1;
    const set = (k, v) => { if (m[k]) m[k].setText(String(v)); };
    for (const k of ['node_inlay_frame_' + who, 'node_' + who + '_shadow_back', 'node_' + who + '_shadow_front']) if (m[k]) m[k].visible = false; // the glow of grown cards: the fight reply has it, not drawn here yet
    const frame = HB.qualityFrame('ninjaSmall', inf.quality), holder = m['sprite_' + who], iconBox = m['node_' + who + 'icon'];
    if (frame && holder) holder.setFrame(frame);
    const pic = HB.iconFrame(1, inf.icon);
    if (pic && iconBox) { const sp = new HB.Sprite(pic); sp.sx = sp.sy = Math.min(iconBox.w / (pic.sw || 1), iconBox.h / (pic.sh || 1)); sp.x = iconBox.w / 2; sp.y = iconBox.h / 2; iconBox.add(sp); }
    const el = HB.frameByName(ELEMENT[c.attri] || ''), camp = m['sprite_' + who + 'camp'];
    if (camp) { if (el) camp.setFrame(el); else camp.visible = false; }
    set('label_' + who + 'name', inf.name); set('label_' + who + 'level', c.level);
    // the card's own numbers at its level from ninjainfo ([20]+[26] attack, [22]+[28] defence, [24]+[30] chakra, the upper values).
    // (ours: the phone reads them from its FightNinjaData, which the server's reply does not carry for both sides)
    set('label_' + who + 'attack', Math.round(num(r[20]) + num(r[26]) * lv)); set('label_' + who + 'defense', Math.round(num(r[22]) + num(r[28]) * lv)); set('label_' + who + 'chakra', Math.round(num(r[24]) + num(r[30]) * lv));
    const name = m['label_' + who + 'name']; if (name && name.w > 170) name.sx = name.sy = Math.max(0.55, 170 / name.w);
  }
  async function toggleCompare(owner, btn) {
    let layer = btn && btn.parent;
    while (layer && !/layer_content$/.test(layer.name || '')) layer = layer.parent;
    if (!layer || owner._cmpBusy) return;
    if (owner._cmp) { // (ours) the button brings the result back, so the prize cards of a Training win can still be drawn
      owner._cmp.view.removeSelf(); owner._cmp.hidden.forEach((c) => { c.visible = true; }); owner._cmp = null;
      return;
    }
    owner._cmpBusy = true;
    try { await Promise.all([...CMP.map((f) => HB.loadCCB(f)), HB.data.tables()]); } finally { owner._cmpBusy = false; }
    // the button stays, with the picture lying on it (its word is a sprite at the same place)
    const keep = new Set(Object.entries(owner.n).filter(([k]) => /teamcompare$/.test(k)).map(([, v]) => v));
    for (const c of layer.children) if (c instanceof HB.Sprite && Math.abs(c.x - btn.x) < 14 && Math.abs(c.y - btn.y) < 14) keep.add(c);
    const hidden = layer.children.filter((c) => c.visible && !keep.has(c));
    hidden.forEach((c) => { c.visible = false; });
    const co = {};
    const view = HB.build(CMP[0], co, [layer.w, layer.h]);
    view.x = view.ignoreAnchor ? 0 : view.ax * view.w; view.y = view.ignoreAnchor ? 0 : view.ay * view.h; view.z = 5;
    for (const k of keep) k.z = 20;
    layer.add(view);
    const t = fightTeams(SYS.lastFight), rows = Math.max(t.mine.length, t.foes.length), box = co.n.node_content, size = co.n.node_cardview;
    const LIFT = 84; // (ours) the list ends above the Team compare button, which stays to go back
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h - LIFT; scroll.y = LIFT;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows) * size.h;
    for (let i = 0; i < rows; i++) {
      const io = {};
      const cell = HB.build(CMP[1], io, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      compareSide(io.n, 'my', t.mine[i]); compareSide(io.n, 'enemy', t.foes[i]);
      col.add(cell);
    }
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    view.fade = 0; HB.tween(view, { fade: 1 }, 0.14);
    owner._cmp = { view, hidden };
  }
  // fight.js is not touched: its result screen is built through HB.ui.screen, so the hook sits there. It keeps the Team compare
  // buttons that fight.js still hides ("not built yet") and takes their taps (onTeamCompare) before the screen's own handler.
  function compareHook(owner) {
    for (const [k, node] of Object.entries(owner.n)) {
      if (!/teamcompare$/.test(k)) continue;
      Object.defineProperty(node, 'visible', { configurable: true, get: () => true, set() {} });
      node.removeSelf = () => {};
      if (node.setTitle && /^Title$/i.test((node.titles || {})[1] || '')) node.setTitle('');
    }
    let real = owner.onButton;
    Object.defineProperty(owner, 'onButton', { configurable: true, enumerable: true, get: () => (sel, b) => (sel === 'onTeamCompare' ? toggleCompare(owner, b) : real && real(sel, b)), set: (f) => { real = f; } });
  }
  function installCompare() {
    const screen0 = HB.ui.screen;
    HB.ui.screen = function (file, owner) {
      const root = screen0.apply(this, arguments);
      if (/NewFightResult_(Win|Fail)View$/.test(file) && owner && owner.n) { try { compareHook(owner); } catch (e) { console.warn('team compare', e); } }
      return root;
    };
    if (HB.fight && HB.fight.play) {
      const play0 = HB.fight.play;
      HB.fight.play = function (reply) { SYS.lastFight = reply; return play0.apply(this, arguments); };
    }
    CMP.forEach((f) => HB.loadCCB(f).catch(() => {}));
  }

  // ---------------------------------------------------------------- the watch: new top bar, Home opened, timers
  let seenHome = null, slow = 0, glowAt = 0, marqueeAt = 0, tried = false, installed = false;
  function onHome() {
    bubbles();
    loadNews().catch(() => {});
    askGlow();
    bootEnd.then(bulletin).catch(() => {}); // after the loading box, like the phone (the main menu shows it)
    // the phone's timer (CMainMenu::UpdataProvokeNoticeData) runs the script again and again; here: when Home opens, five minutes apart (ours)
    bootEnd.then(() => { if (HB.L && Date.now() - marqueeAt > 300000) { marqueeAt = Date.now(); HB.luaRun('ui_layer/ui_borderWarTip.lua'); } });
    if (!tried && q.get('sys')) { tried = true; bootEnd.then(() => setTimeout(tests, 2000)); }
  }
  async function tests() {
    for (const t of q.get('sys').split(',')) {
      if (t === 'timeout') timeoutWindow();
      if (t === 'notice') showNotice('Welcome back to Hello Bro!');
      if (t === 'loading') { SYS.loading(true); }
      if (t === 'compare') { // a spar against the first player of the list, then Team compare
        const r = await api0('rl_r_friend', { Cmd: 1 }), u = HB.x.first(r, 'user');
        if (!u) continue;
        const f = await api0('rl_w_pvp', { Cmd: 2701, ToUid: HB.x.t(u, 'id') });
        HB.fight.play(f, { kind: 'spar', exp: 0, silver: 0, energy: 0 });
      }
    }
  }
  function tick(dt) {
    bannerTick(dt);
    if ((slow += dt) < 0.3) return;
    slow = 0;
    if (!installed && HB.ui && HB.ui.screen && HB.ui.table) {
      installed = true;
      installCompare();
      HB.ui.table('sysnotice').catch(() => {});
      for (const f of ['sub_ui/LoadingView', 'dlg_ui/TimeOutDialogView']) HB.loadCCB(f).catch(() => {});
    }
    if (!inGame()) return;
    banner.marquee = HB.scene.children.some((c) => c.z === 500 && c.children.some((k) => k.tag === 168)); // ui_borderWarTip.lua: addChild(tip, 3, 168)
    const box = HB.game.menu.n.node_inform;
    if (box && box !== banner.box) bannerAttach(box);
    if (HB.home && HB.home !== seenHome) { seenHome = HB.home; onHome(); }
    if (Date.now() - glowAt > 450) { glowAt = Date.now(); try { glowTick(); } catch (e) { /* the name stays plain */ } }
  }
  let last = performance.now();
  const frame = (now) => { const dt = Math.min(0.1, (now - last) / 1000); last = now; try { tick(dt); } catch (e) { console.warn('system.js', e); } requestAnimationFrame(frame); };
  requestAnimationFrame(frame);
})();
