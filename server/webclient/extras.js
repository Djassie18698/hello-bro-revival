// Small windows the phone had in C++ (and two of the game's own script screens that only needed a way in):
//   Level-up window  CPlayerLevelUp, dlg_ui/PlayerLevelUpDlg.ccbi: old -> new level, the level's attack / defence / team size from
//                    the playerlevel table ([5] team size, [6] attack, [7] defence), "new team slot" when the team grew, "level-up
//                    gift" every 10th level (CPlayerLevelUp::InitUI: level % 10), sound levelup. Shown whenever the player's level
//                    is higher than it was a moment ago (after a fight, a gift ...).
//   Player info      PlayerInfoDlg, dlg_ui/PlayerInfoDlg.ccbi + meritRankCell: tap the top bar (BtnPlayerMsg). Numbers from
//                    rl_r_mainpage <user>; the rank list is the playemedal table ([2] name, [3]-[8] attack / defence / chakra,
//                    [9] W.A. needed, [10] badge); energy 1 per 180 s, grudge 1 per 2 h (the server's rule, game.js).
//   Settings         the game's own ui_layer/ui_gameSettingLayer.lua on GameSettingViewForLua.ccbi (music, effects, Discord, invite code)
//   VIP list         the game's own VipListView.lua (InitVipListView) inside the Shop's frame, tab VIP (rl_r_vipshop, rl_w_vipshopbuy)
// No other file is edited for these: this file watches HB.game (which screen is on, the player's level).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const set = (n, k, t) => { if (n[k] && n[k].setText) n[k].setText(String(t)); };
  const num = (v) => Number(v) || 0;
  const two = (v) => String(v).padStart(2, '0');
  const clock = (s) => { s = Math.max(0, Math.floor(s)); return two(Math.floor(s / 3600)) + ':' + two(Math.floor((s % 3600) / 60)) + ':' + two(s % 60); };
  const user = () => (HB.game && HB.game.user) || {};
  const lvRow = (lv) => ((HB.ui.tables.playerlevel || {}).rows || []).find((r) => r[1] === Number(lv)) || [];
  // a window over everything, the layout in the middle; returns { root, n, close }
  async function win(file, owner, z = 620) {
    await HB.loadCCB(file);
    const dim = HB.ui.modal(150); dim.z = z;
    const root = HB.ui.screen(file, owner);
    dim.add(root); HB.scene.add(dim);
    dim.fade = 0; HB.tween(dim, { fade: 1 }, 0.14);
    owner.root = root; owner.dim = dim; owner.close = () => dim.removeSelf();
    return owner;
  }

  // ---------------------------------------------------------------- level-up window
  let showing = false;
  async function levelUp(from, to) {
    if (showing) return;
    showing = true;
    try {
      await Promise.all([HB.ui.table('playerlevel'), HB.loadCCB('animations/UpgradeUpLight').catch(() => null)]);
      const o = {};
      await win('dlg_ui/PlayerLevelUpDlg', o, 700);
      const n = o.n, a = lvRow(from), b = lvRow(to);
      set(n, 'label_levelfrom', from); set(n, 'label_levelto', to);
      set(n, 'label_attackfrom', a[6] || 0); set(n, 'label_attackto', b[6] || 0);
      set(n, 'label_defensefrom', a[7] || 0); set(n, 'label_defenseto', b[7] || 0);
      set(n, 'label_teamfrom', a[5] || 1); set(n, 'label_teamto', b[5] || 1);
      set(n, 'label_PlayerLevelUpDlg0', 'Energy is full: go on training!');
      set(n, 'label_PlayerLevelUpDlg1', 'Grudge is full: spar and plunder!');
      const slot = (b[5] || 1) > (a[5] || 1), gift = Number(to) % 10 === 0 || Math.floor(to / 10) > Math.floor(from / 10);
      set(n, 'label_newninjatip', 'A new team slot is open'); set(n, 'label_leveltip', 'A level-up gift is waiting');
      if (n.btn_newninja) n.btn_newninja.setTitle('Add a ninja'); if (n.btn_levelaward) n.btn_levelaward.setTitle('Get the gift');
      for (const k of ['label_newninjatip', 'btn_newninja']) if (n[k]) n[k].visible = slot;
      for (const k of ['label_leveltip', 'btn_levelaward']) if (n[k]) n[k].visible = gift;
      // the rays behind it (CAnimLayer animations/UpgradeUpLight.ccbi, timeline ShowLight)
      try {
        if (n.layer_light && HB.docs['animations/UpgradeUpLight']) { const lo = {}; const light = HB.build('animations/UpgradeUpLight', lo, [n.layer_light.w, n.layer_light.h]); n.layer_light.add(light); HB.play(light, 'ShowLight'); }
      } catch (e) { /* the window works without its rays */ }
      let ready = false;
      const done = new Promise((ok) => {
        o.finish = () => { o.close(); ok(); };
        o.onButton = (sel) => {
          o.finish();
          if (sel === 'onNewNinja' && HB.screens.team) HB.screens.team();
          if (sel === 'onGetAward' && HB.game.changeToActivity && HB.L) HB.game.changeToActivity('upradePackActivity', 'nan');
        };
        o.dim.onTouch = (ev) => { if (ev === 'up' && ready) o.finish(); };
      });
      try { HB.play(o.root, 'showlevelup', () => { try { HB.play(o.root, 'showlevelupinfo', () => { ready = true; }); } catch (e) { ready = true; } }); } catch (e) { ready = true; }
      setTimeout(() => { ready = true; }, 1800);
      await done;
    } catch (e) { console.warn('level-up window', e); }
    showing = false;
  }
  HB.levelUp = levelUp;
  HB.screens.levelup = () => { const lv = num(user().level) || 1; return levelUp(Math.max(1, lv - 1), lv); }; // test switch: &open=levelup

  // ---------------------------------------------------------------- player info window
  const ENERGY_EVERY = 180, SP_EVERY = 2 * 3600; // the server's rule (game.js energyTick / spState)
  let serverName = null;
  async function areaName() {
    if (serverName !== null) return serverName;
    try {
      const x = HB.ui.x, dir = await HB.api('xk_r_dir', { Cmd: 2, Pt: 1062, GroupID: 2, Version: '28.0' }, { bare: true });
      const sv = x.all(dir, 'server').map((s) => ({ id: Number(x.t(s, 'id') || x.a(s, 'id')), name: x.t(s, 'name') || x.a(s, 'name') })).find((s) => s.id === Number(HB.session.server));
      serverName = sv ? sv.name : '';
    } catch (e) { serverName = ''; }
    return serverName;
  }
  HB.screens.playerinfo = async function playerInfo() {
    const ui = HB.ui;
    ui.loading(true);
    let medals, area;
    try { [medals, area] = await Promise.all([ui.table('playemedal'), areaName(), ui.table('playerlevel'), HB.loadCCB('dlg_ui/meritRankCell'), HB.game.refresh()]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    const at = Date.now(), u = user(), o = {};
    await win('dlg_ui/PlayerInfoDlg', o);
    const n = o.n, row = lvRow(u.level);
    o.onButton = () => o.close();
    const TEXT = ['Rank:', 'Attack:', 'Defence:', 'Chakra:', 'War merit:', 'Team:', 'W.A.:', 'Silver:', 'Gold:', 'Grudge:', 'Energy:', 'Next grudge in:', 'All grudge in:', 'Next energy in:', 'All energy in:', 'Rank', 'Title', 'W.A.', 'Attack', 'Defence', 'Chakra'];
    TEXT.forEach((t, i) => set(n, 'label_PlayerInfoDlg' + i, t));
    set(n, 'label_playername', u.nick || ''); set(n, 'label_level', u.level || 1); set(n, 'label_areaname', area || '');
    const need = row[2] || 0;
    set(n, 'label_expValue', num(u.score) + '/' + need);
    if (n.sprite_curexp) n.sprite_curexp.sx = Math.max(0, Math.min(1, need ? num(u.score) / need : 0));
    set(n, 'label_attack', num(u.attactlow) + '-' + num(u.attacthigh)); set(n, 'label_defense', num(u.defenselow) + '-' + num(u.defensehigh)); set(n, 'label_charkraval', num(u.chakralow) + '-' + num(u.chakrahigh));
    set(n, 'label_honor', num(u.meritscore)); set(n, 'label_merit', num(u.warpower));
    set(n, 'label_silver', num(u.coin)); set(n, 'label_gold', num(u.cash));
    set(n, 'label_NinjaNum', HB.data.team.length + '/' + (num(u.maxteammember) || row[5] || 1));
    const vf = HB.frame('com_res/Resident_2.plist', ui.VIP_FRAMES()[Math.min(18, num(u.viplevel))]);
    if (vf && n.sprite_viplevel) n.sprite_viplevel.setFrame(vf);
    const mine = medals.rows.find((r) => r[1] === num(u.meritlevel));
    set(n, 'label_meritname', mine ? mine[2] : 'None');
    if (n.sprite_merit_icon) { const f = mine && HB.frameByName(String(mine[10]).replace(/\0+$/, '')); if (f) n.sprite_merit_icon.setFrame(f); else n.sprite_merit_icon.visible = !!mine; }
    // energy and grudge with their clocks
    const maxE = row[4] || num(u.curaction), maxS = row[3] || num(u.cursp), e = num(u.curaction), sp = num(u.cursp);
    set(n, 'label_bodyValue', e + '/' + maxE); set(n, 'label_fightValue', sp + '/' + maxS);
    if (n.sprite_curbody) n.sprite_curbody.sx = Math.max(0, Math.min(1, maxE ? e / maxE : 0));
    if (n.sprite_curfight) n.sprite_curfight.sx = Math.max(0, Math.min(1, maxS ? sp / maxS : 0));
    const left = (have, max, every, passed) => { if (have >= max) return [0, 0]; const next = Math.max(0, every - (num(passed) % every)); return [next, next + (max - have - 1) * every]; };
    const tE = left(e, maxE, ENERGY_EVERY, u.LastActionUpdatePastTime), tS = left(sp, maxS, SP_EVERY, u.LastSPUpdatePastTime);
    const tick = () => {
      if (!o.dim.parent) return;
      const gone = (Date.now() - at) / 1000, show = (k, t, full) => set(n, k, clock(full ? 0 : t - gone));
      show('label_EnergyRestTime', tE[0] > gone ? tE[0] : tE[0] + Math.ceil((gone - tE[0]) / ENERGY_EVERY) * ENERGY_EVERY, e >= maxE || tE[1] <= gone);
      show('label_totalEnergyRestTime', tE[1], e >= maxE || tE[1] <= gone);
      show('label_PkRestTime', tS[0] > gone ? tS[0] : tS[0] + Math.ceil((gone - tS[0]) / SP_EVERY) * SP_EVERY, sp >= maxS || tS[1] <= gone);
      show('label_totalPkRestTime', tS[1], sp >= maxS || tS[1] <= gone);
      setTimeout(tick, 1000);
    };
    tick();
    // the list of ranks (PlayerInfoCell = dlg_ui/meritRankCell)
    const box = n.node_tabelContent, size = n.node_cellcontent;
    if (box && size) {
      const rows = medals.rows.slice().sort((p, q) => p[1] - q[1]);
      const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
      const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows.length) * size.h;
      rows.forEach((r, i) => {
        const co = {};
        const cell = HB.build('dlg_ui/meritRankCell', co, [size.w, size.h]);
        cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
        const m = co.n;
        for (const k of ['label_meritname', 'label_needHonor']) if (m[k]) m[k].size = 20; // 20: the longer titles (Junior Chūnin) ran into the number beside them at 24
        set(m, 'label_level', r[1]); set(m, 'label_meritname', r[2]); set(m, 'label_needHonor', r[9]);
        set(m, 'label_attckAdd', '+' + r[3]); set(m, 'label_defenseAdd', '+' + r[5]); set(m, 'label_charkraAdd', '+' + r[7]);
        if (mine && r[1] === mine[1]) for (const k of Object.keys(m)) if (m[k].setText) m[k].color = [200, 60, 20]; // your own rank
        col.add(cell);
      });
      scroll.setContent(col); col.y = scroll.h - col.h;
      if (mine) { const i = rows.findIndex((r) => r[1] === mine[1]); col.y = Math.min(0, Math.max(scroll.h - col.h, scroll.h - col.h + Math.max(0, i - 1) * size.h)); }
      box.add(scroll);
    }
  };

  // ---------------------------------------------------------------- Settings (the game's own script)
  // Two things are set right for the browser before it opens, once, as soon as the scripts run (so the Home row's own Settings
  // icon, which runs the script by itself, gets them too):
  //  - its text box reads "local x, y = sprite:getPosition()"; our bridge answers getPosition with a point, so the same function
  //    is given here with getPositionX / getPositionY (nothing else changed);
  //  - its own tap-swallowing layer would take the taps meant for its buttons here; AddDialog already blocks what is under it.
  const SETTING_FIX = `
    require('ui_layer/ui_gameSettingLayer')
    if not ui_gameSettingLayer.__web then
      ui_gameSettingLayer.__web = true
      local init0 = ui_gameSettingLayer.init
      function ui_gameSettingLayer.init(self)
        init0(self)
        self.node_:setTouchEnabled(false)
        -- text that fits (ours, web only): the headings are centred on a point made for two Chinese signs, so the English ones
        -- ran out of the window on the left; they now start where 'Invitation Code' starts. Music / Sound move clear of their boxes.
        local left = self.text_invite_code and self.text_invite_code:getPositionX() or 78
        for _, l in ipairs({ self.text_sound_settings, self.text_contact_service, self.text_usercenter }) do
          if l then l:setAnchorPoint(ccp(0, 0.5)) l:setPosition(ccp(left, l:getPositionY())) end
        end
        if self.text_username then self.text_username:setScale(0.85) end -- the Discord address reached the box's edge
        for _, l in ipairs({ self.text_sound, self.text_sound_effect }) do
          if l then local x = l:getPositionX() - l:getContentSize().width / 2 + 12 l:setAnchorPoint(ccp(0, 0.5)) l:setPosition(ccp(x, l:getPositionY())) end
        end
      end
      function ui_gameSettingLayer.initEditBox(self)
        local function editboxEventHandle(eventType)
          if eventType == "ended" then self:onInputDone() end
        end
        local ptx, pty = self.sprite_input:getPositionX(), self.sprite_input:getPositionY()
        local size = self.sprite_input:getContentSize()
        local parentNode = self.sprite_input:getParent()
        self.sprite_input:removeFromParentAndCleanup(true)
        self.edit_invite_code = CCEditBox:create(size, self.sprite_input)
        self.edit_invite_code:registerScriptEditBoxHandler(editboxEventHandle)
        parentNode:addChild(self.edit_invite_code, 1)
        self.edit_invite_code:setPosition(ccp(ptx + size.width / 2, pty + size.height / 2))
        self.edit_invite_code:setAnchorPoint(ccp(0.5, 0.5))
        self.edit_invite_code:setMaxLength(20)
        self.edit_invite_code:setInputMode(kEditBoxInputModeSingleLine)
        self.edit_invite_code:setReturnType(kKeyboardReturnTypeDone)
        self.edit_invite_code:setFontColor(ccc3(0, 0, 0))
        self.edit_invite_code:setTouchPriority(kCCMenuHandlerPriority - 1)
        self.edit_invite_code:setTouchEnabled(true)
        self.edit_invite_code:setPlaceHolder(localizable.ui_gameSettings_inviteCodeInput)
      end
    end
`;
  let settingReady = false;
  const settingFix = () => { if (settingReady || !HB.L) return settingReady; try { HB.luaCall(HB.L.load(SETTING_FIX)); settingReady = true; } catch (e) { HB.luaError(e); } return settingReady; };
  HB.screens.settings = async function settings() {
    if (!HB.L) return HB.ui.tip('Settings open from the Home screen', 1.5);
    await HB.loadCCB('GameSettingViewForLua');
    settingFix();
    // the Home row's own line (MenuBtnsData.lua)
    try { HB.luaCall(HB.L.load("require('ui_layer/ui_gameSettingLayer'); local gameSettingView = createObj(ui_gameSettingLayer);GetMainMenu():GetModelLayer():AddDialog(gameSettingView.node_, 3);")); } catch (e) { HB.luaError(e); }
  };

  // ---------------------------------------------------------------- VIP list (the Shop's fourth tab; the game's own script)
  const SHOP_TABS = [['ctrl_ninja', 'Recruit'], ['ctrl_weapon', 'Giftpack'], ['ctrl_armors', 'Tool'], ['ctrl_vip', 'VIP']];
  HB.screens.viplist = async function vipList() {
    const ui = HB.ui;
    if (!HB.L) return ui.tip('Coming soon: VIP', 1.2);
    ui.loading(true);
    try { await Promise.all([HB.loadCCB('store/StoreItemsView'), HB.loadCCB('store/VipListView'), HB.loadCCB('store/VipCellView').catch(() => null), HB.data.tables()]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    const o = {};
    HB.game.showSub('store/StoreItemsView', o, 'btn_mainstore');
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    SHOP_TABS.forEach(([name, title], i) => { const b = n[name]; if (b) { if (tabOff) b.frames[1] = i === 3 ? tabOn || tabOff : tabOff; b.titles[1] = title; b.layout(); } });
    if (n.label_StoreItemsView0) { const l = n.label_StoreItemsView0; l.size = 24; l.x += 24; l.setText('Top-up'); } // as in shop.js: clear of the 1st Recharge sticker
    if (n.sprite_notify_pray) n.sprite_notify_pray.visible = false;
    o.onButton = (sel) => {
      const i = ['BtnPray', 'BtnGiftPack', 'BtnConsum'].indexOf(sel);
      if (i >= 0 && shop0) return shop0(i);
      if (sel === 'BtnVipInfo') return;
      ui.tip('Coming soon: ' + (sel === 'BtnPurchase' ? 'Top-up' : sel), 1.2);
    };
    // CStoreItemsView::ChangeToTab: runs script/VipListView.lua and calls InitVipListView(the shop view)
    const view = new HB.CCBProxy(); view.owner = o;
    HB.game.currentSub = view;
    if (HB.luaRun('VipListView.lua')) HB.luaGlobal('InitVipListView', view);
  };
  // the Shop's VIP tab leads here (shop.js answers that button with "coming soon")
  let shop0 = null;
  const hookShop = () => {
    if (shop0 || !HB.screens.shop) return;
    shop0 = HB.screens.shop;
    HB.screens.shop = async function (...a) {
      const r = await shop0.apply(this, a);
      const o = HB.game.subOwner;
      if (o && o.n && o.n.ctrl_vip && o.onButton && !o.__vip) { o.__vip = true; const was = o.onButton; o.onButton = (sel, btn) => (sel === 'BtnVipInfo' ? HB.screens.viplist() : was(sel, btn)); }
      return r;
    };
  };
  hookShop();

  // ---------------------------------------------------------------- watching the game: the top bar's tap, a higher level
  let lastOwner = null, lastLevel = null, lastUid = null;
  setInterval(() => {
    const g = HB.game;
    if (!g) return;
    hookShop();
    if (!settingReady && HB.L && g.user && g.subOwner) settingFix();
    // the top bar of whatever screen is on (sub_ui/NormalTopBar: ctrl_btnplayermsg -> BtnPlayerMsg)
    const o = g.subOwner;
    if (o && o.n && o !== lastOwner) { lastOwner = o; const b = o.n.ctrl_btnplayermsg; if (b) b.onTap = () => HB.screens.playerinfo(); }
    // CMainMenu shows CPlayerLevelUp when the level in a reply is higher than the one it holds
    const u = g.user;
    if (u && u.level !== undefined) {
      const lv = Number(u.level), uid = HB.session && HB.session.uid;
      if (lastLevel !== null && uid === lastUid && lv > lastLevel) levelUp(lastLevel, lv);
      lastLevel = lv; lastUid = uid;
    }
  }, 250);
})();
