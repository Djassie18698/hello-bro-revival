// The two frames the game's own Lua screens live in, and the Home buttons that lead to them.
//  1. CActivityView, the Event screen (activity/ActivityDefaultView.ccbi): a strip of event icons on top (ActivityBarCellView, the
//     names the scripts pushed with PushActivityName) and node_contentview, where the chosen event's script puts its layer.
//     GetMainMenu():ChangeToActivity("<script>") opens it and runs script/<script>.lua (each script ends with xpcall(init...)).
//  2. CActivitySubMenu: an empty screen; GetMainMenu():ChangeToActivitySubMenu("<function>", "<lua text>") opens it and calls that
//     global function of activitySubmenHelper.lua (ShowRouletteView, ShowOrgView, showBase ...), which adds its layer with
//     AddViewToActivitySubMenu -> GetMainMenu():GetActivitySubMenuView().
// Also GetMainMenu():ChangeToSub(E_...) for the screens rebuilt in JavaScript.
'use strict';
(function () {
  const HB = window.HB;
  const game = () => HB.game;
  let helperLoaded = false;
  const helper = () => { if (!helperLoaded) helperLoaded = HB.luaRun('activitySubmenHelper.lua'); return helperLoaded; };

  // an empty layer in the place where screens go
  function blankSub() {
    const content = game().subContent;
    const old = content.children.slice(); content.removeAll(); old.forEach((c) => HB.luaLeave && HB.luaLeave(c));
    const layer = new HB.Node(); layer.w = HB.ui.FRAME; layer.h = content.h; layer.ignoreAnchor = true; layer.isLayer = true;
    layer.x = -content.x + content.ax * content.w;
    content.add(layer); HB.luaEnter && HB.luaEnter(layer);
    layer.fade = 0; HB.tween(layer, { fade: 1 }, 0.16);
    return layer;
  }

  (HB.onGame = HB.onGame || []).push(install); if (HB.game) install();
  function install() {
  // ---------------------------------------------------------------- 2. the empty sub menu
  const fresh = async () => { if (HB.game.loadItems && Date.now() - (HB.game.itemsAt || 0) > 8000) await HB.game.loadItems(); }; // the items you hold, for the scripts (CTradeMgr)
  HB.game.changeToActivitySubMenu = async function (fn, arg) {
    if (!HB.L) return HB.ui.tip('Coming soon: ' + fn, 1.2);
    if (!helper()) return HB.ui.tip('This screen cannot open yet', 1.5);
    if (HB.L.get(fn) === undefined) return HB.ui.tip('Coming soon: ' + fn.replace(/^(do)?Show/i, ''), 1.2);
    await fresh();
    game().activitySubMenu = blankSub();
    game().currentSub = game().activitySubMenu; game().currentSubType = (game().E || {}).E_ACTIVITYVIEW || 0;
    if (arg === undefined || arg === null) HB.luaGlobal(fn); else HB.luaGlobal(fn, arg);
  };

  // ---------------------------------------------------------------- 1. the Event screen
  const iconFrame = (icon) => (/[\\/]/.test(icon) ? HB.frame('', icon) : HB.frameByName(icon));
  HB.game.changeToActivity = async function (name, from) {
    if (!HB.L) return HB.ui.tip('Coming soon: ' + name, 1.2);
    // an entry can be a line of Lua instead of a script name (activity_config type 1)
    if (/[():]/.test(name)) { HB.luaCall(HB.L.load(name)); return; }
    await Promise.all([HB.loadCCB('activity/ActivityDefaultView'), HB.loadCCB('activity/ActivityBarCellView'), fresh()]);
    const o = {};
    game().showSub('activity/ActivityDefaultView', o);
    const n = o.n, list = game().activities || [];
    game().activityContent = n.node_contentview; n.node_contentview.isLayer = true;
    game().activityFrom = from || '';
    game().currentSub = n.node_contentview.parent; game().currentSubType = (game().E || {}).E_ACTIVITYVIEW || 0;
    // the strip of event icons
    const box = n.node_groupview, cellSize = n.node_topbar_cell;
    const row = new HB.ScrollView(); row.dir = 0; row.w = box.w; row.h = box.h;
    const strip = new HB.Node(); strip.w = Math.max(box.w, list.length * cellSize.w); strip.h = box.h;
    let mine = -1;
    list.forEach((a, i) => {
      const co = {};
      const cell = HB.build('activity/ActivityBarCellView', co, [cellSize.w, cellSize.h]);
      cell.ignoreAnchor = true; cell.x = i * cellSize.w; cell.y = 0; cell.w = cellSize.w; cell.h = cellSize.h;
      const m = co.n, on = a.name === name;
      if (on) mine = i;
      if (m.sprite_selectedBg) m.sprite_selectedBg.visible = on;
      if (m.sprite_notify) m.sprite_notify.visible = false;
      const f = iconFrame(a.icon); if (f && m.sprite_icon) m.sprite_icon.setFrame(f);
      cell.onTouch = (ev, tx, ty) => { if (ev === 'down') cell._d = [tx, ty]; if (ev === 'up' && cell._d && Math.hypot(tx - cell._d[0], ty - cell._d[1]) < 14 && !on) HB.game.changeToActivity(a.name); };
      strip.add(cell);
    });
    row.setContent(strip); strip.y = 0;
    if (mine > 2) row.scrollBy(-Math.min((mine - 2) * cellSize.w, strip.w - row.w), 0);
    box.add(row);
    game().activityStrip = row; game().activityCell = cellSize.w;
    o.onButton = (sel, btn) => { row.scrollBy(btn === n.btn_left ? cellSize.w * 2 : -cellSize.w * 2, 0); };
    HB.luaRun(name.replace(/\.lua$/i, '') + '.lua');
  };

  // ---------------------------------------------------------------- GetMainMenu():ChangeToSub(type)
  HB.game.changeToSub = function (type) {
    const E = game().E || {}, S = HB.screens;
    const map = {
      [E.E_DEFAULTMENU]: () => game().goHome(), [E.E_STOREITEMSVIEW]: () => S.shop(), [E.E_GAMEROUND]: () => S.training(), [E.E_SUBCHAPTERVIEW]: () => S.training(),
      [E.E_GAMEGROUPVIEW]: () => S.team(), [E.E_BACKPACKVIEW]: () => S.backpack(), [E.E_ARENAVIEW]: () => S.arena(), [E.E_TOWERVIEW]: () => S.tower(),
      [E.E_FIGHTLISTEVIEW]: () => S.spar(), [E.E_PLUNDERLISTVIEW]: () => S.plunder(), [E.E_MARKLSTVIEW]: () => S.plunder(), [E.E_MONEYTREEVIEW]: () => S.moneytree(),
      [E.E_STRENGTHVIEW]: () => S.growth && S.growth(), [E.E_POTENTIALVIEW]: () => S.potential && S.potential(), [E.E_REINCARNATIONVIEW]: () => S.rebirth && S.rebirth(),
      [E.E_INFORMATIONVIEW]: () => S.news && S.news(), [E.E_FRIENDLISTVIEW]: () => S.friends && S.friends(), [E.E_GAMEBOOKLISTVIEW]: () => S.ninjabook && S.ninjabook(),
      [E.E_COUNTRYWARDEFAULT]: () => S.war && S.war(), [E.E_COUNTRYTREASURE]: () => S.treasure && S.treasure(),
    };
    const go = map[type];
    const name = Object.keys(E).find((k) => E[k] === type) || String(type);
    const key = { E_STRENGTHVIEW: 'growth', E_POTENTIALVIEW: 'potential', E_REINCARNATIONVIEW: 'rebirth', E_INFORMATIONVIEW: 'news', E_FRIENDLISTVIEW: 'friends', E_GAMEBOOKLISTVIEW: 'ninjabook', E_COUNTRYWARDEFAULT: 'war', E_COUNTRYTREASURE: 'treasure' }[name];
    if (!go || (key && !S[key])) return HB.ui.tip('Coming soon: ' + name.replace(/^E_/, '').replace(/VIEW$/, '').toLowerCase(), 1.2);
    go();
  };

  // ---------------------------------------------------------------- Home buttons that open Lua screens (CDefaultMainMenu::onBtn...)
  // returns true when the button was one of these
  HB.game.luaHomeButton = function (sel) {
    if (!HB.L) return false;
    const act = {
      BtnDailyTask: () => HB.luaRun('business_proxy/dailyTask_business.lua'),
      BtnSaveTime: () => HB.luaRun('business_proxy/saveTime_business.lua'),
      BtnSevenDay: () => HB.game.changeToActivity('business_proxy/sevenDay_business'),
      BtnPay: () => HB.game.changeToActivity('business_proxy/firstMoneyAward'),
      BtnNaruto: () => HB.game.changeToActivity('loginPackActivity', 'naruto'),
      BtnNan: () => HB.game.changeToActivity('upradePackActivity', 'nan'),
      BtnBuyFund: () => HB.game.changeToActivitySubMenu('ShowGrowthFundView'),
      BtnRoulette: () => HB.game.changeToActivitySubMenu('ShowRouletteView'),
      BtnMora: () => HB.game.changeToActivitySubMenu('ShowMoraView'),
      BtnAwardCenter: () => { if (helper()) HB.luaGlobal('ShowAwardCenter'); },
      BtnOrg: () => { if (helper()) HB.luaGlobal('ShowOrgView'); },
    }[sel];
    if (!act) return false;
    act();
    return true;
  };
  // the village's Lua buildings (base.js)
  HB.game.luaBuilding = function (k) {
    const fn = { energy: 'doShowBase', secretshop: 'ShowSecretShopView', ninja: 'ShowMultiBattleView', borderWar: 'ShowBorderWarView' }[k];
    if (!fn || !HB.L) return false;
    HB.game.changeToActivitySubMenu(fn);
    return true;
  };
  }
})();
