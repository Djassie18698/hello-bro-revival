// The game's own C++ helpers that its Lua scripts call (libgame.so tolua bindings), rebuilt for the web client:
// GetMainMenu() (tips, loading, dialogs, switching screens), CPlayerDataMgr (the player's numbers from rl_r_mainpage),
// CNetUser / CServerListMgr (who and where: the requests go to the page's own server), DataMgr.GetDataByID (the game tables
// by their C++ field names), CSoundMgr, platform and version functions, the screen-type constants.
// Something a script asks for that is not here yet answers nil and is logged once: HB.luaMissing (console: "Lua wants ...").
'use strict';
(function () {
  const HB = window.HB, Lua = window.Lua;
  const { LuaTable } = Lua;
  HB.luaMissing = new Set();
  const missing = (what) => { if (!HB.luaMissing.has(what)) { HB.luaMissing.add(what); console.info('Lua wants ' + what + ' (not in the web client yet)'); } };

  HB.openGame = (lua) => {
    const { methods, userdata, fields, luaClass, gfn, gval, txt, B, CCSize, CCPoint } = lua;
    const num = (v, d = 0) => (typeof v === 'number' ? v : v === undefined || v === null ? d : Number(v) || d);
    const G = HB.L.G;
    const asLua = (fn) => (...a) => { const r = fn(...a); return Array.isArray(r) ? r : r === undefined ? Lua.R.EMPTY : [r]; };
    // a singleton or object of the game: known methods, and any other name answers nil (logged once)
    function gameObject(name, fns, fieldGetters = {}) {
      const o = {
        luaGet(k) {
          const key = Lua.fromBytes(String(k));
          if (Object.prototype.hasOwnProperty.call(fieldGetters, key)) { const v = fieldGetters[key](); return typeof v === 'string' ? B(v) : v; }
          if (Object.prototype.hasOwnProperty.call(fns, key)) return fns[key];
          if (this.__peer) { const v = this.__peer.get(k); if (v !== undefined) return v; }
          return asLua(() => { missing(name + ':' + key); return undefined; });
        },
        luaSet(k, v) { (this.__peer || (this.__peer = new LuaTable())).set(k, v); },
      };
      for (const k of Object.keys(fns)) { const f = fns[k]; fns[k] = asLua((self, ...a) => f(...a)); }
      return o;
    }
    const singleton = (cls, name, fns, fieldGetters) => { const obj = gameObject(name, fns, fieldGetters); luaClass(cls, { instance: () => obj, sharedInstance: () => obj }); return obj; };

    // ---------------- who and where
    const S = HB.session;
    const origin = location.origin;
    singleton('CNetUser', 'CNetUser', {
      GetUserID: () => num(S.uid), GetSessionID: () => B(S.session), GetPlatformID: () => 1062, GetAreaID: () => S.server, GetGroupID: () => S.group, GetPayID: () => 0,
    });
    const serverConfig = gameObject('ServerConfig', {}, { m_url: () => origin, m_accounturl: () => origin, m_name: () => S.serverName || '', m_id: () => S.server });
    singleton('CServerListMgr', 'CServerListMgr', { GetServerConfig: () => serverConfig, GetSelectConfig: () => serverConfig, GetAreaUrl: () => B(origin + '/xk_r_dir') });
    gfn('GetPlatformStr', () => B('Android')); gfn('GetPlatForm', () => B('android')); gfn('GetGameVersion', () => B('28.0'));
    gfn('GetAeraURL', () => B(origin));
    gfn('GetClinetTime', () => { const d = new Date(), p = (n) => String(n).padStart(2, '0'); return B(`${d.getFullYear()}/${p(d.getMonth() + 1)}/${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())} ${d.toLocaleDateString('en-US', { weekday: 'long' })}`); });
    gfn('openHyperlink', (u) => { const url = txt(u); if (/^https?:\/\//i.test(url)) window.open(url, '_blank', 'noopener'); });
    gval('is_applestore', false);

    // ---------------- the player (CPlayerDataMgr::firefly_GetPlayerInfoData: filled from rl_r_mainpage <user>)
    const user = () => HB.game.user || {};
    const playerInfo = gameObject('PlayerInfoData', {}, {
      m_uid: () => num(S.uid), m_name: () => user().nick || '', m_level: () => num(user().level), m_exp: () => num(user().score),
      m_gold: () => num(user().cash), m_silver: () => num(user().coin), m_bodyvalue: () => num(user().curaction), m_fightcount: () => num(user().cursp),
      m_viplevel: () => num(user().viplevel), m_countrytype: () => num(user().country), m_soul: () => num(user().soul),
      m_meritlevel: () => num(user().meritlevel), m_meritscore: () => num(user().meritscore),
    });
    singleton('CPlayerDataMgr', 'CPlayerDataMgr', {
      GetPlayerInfoData: () => playerInfo,
      SetGold: (g) => { if (HB.game.user) HB.game.user.cash = num(g); HB.game.refreshTopBar && HB.game.refreshTopBar(); },
      AddGold: (g) => { if (HB.game.user) HB.game.user.cash = num(HB.game.user.cash) + num(g); HB.game.refreshTopBar && HB.game.refreshTopBar(); },
      GetCountryType: () => num(user().country),
      GetTotalLoginDay: () => num(user().logindays, 1), SetTotalLoginDay: () => {},
      SetActivityNewsNum: () => {}, SetActivityNews: () => {}, SetMoraOpen: (v) => { HB.game.moraOpen = v; }, GetMoraOpen: () => HB.game.moraOpen || 0,
      SetNaturoOpened: () => {}, SetNanOpened: () => {}, SetPkPassTime: () => {}, SetLotteryProgress: () => {},
      GetMaxBodyValue: () => HB.game.maxEnergy || 0, GetMaxAttackCount: () => 5, GetNextLevelExp: () => HB.game.needExp || 0,
    });

    // ---------------- the main menu (CMainMenu): tips, loading, dialogs, screens
    let modelLayer = null;
    const getModelLayer = () => {
      if (!modelLayer || !modelLayer.parent) {
        modelLayer = new HB.Node(); modelLayer.w = HB.size[0]; modelLayer.h = HB.size[1]; modelLayer.z = 500; modelLayer.isLayer = true; modelLayer.ignoreAnchor = true;
        HB.scene.add(modelLayer); HB.luaEnter(modelLayer);
      }
      return modelLayer;
    };
    // CModelLayer::AddDialog(node, z): a dialog over everything; taps under it are blocked
    HB.lua.methods(HB.Node, {
      AddDialog: (layer, node, z) => {
        if (!node) return;
        const dim = new HB.LayerColor(); dim.color = [0, 0, 0]; dim.opacity = 0; dim.w = HB.size[0]; dim.h = HB.size[1]; dim.swallow = true; dim.onTouch = () => {}; dim.ignoreAnchor = true;
        dim.z = num(z); node.__dim = dim;
        layer.add(dim); layer.add(node, num(z)); HB.luaEnter(node);
        const watch = () => { if (!node.parent) { dim.removeSelf(); return; } requestAnimationFrame(watch); };
        requestAnimationFrame(watch);
      },
    });
    const mainMenu = gameObject('CMainMenu', {
      ShowTextTip: (t, sec) => HB.tip(txt(t), num(sec, 2)),
      ShowErrorTip: (code, sec) => HB.tip(HB.menu(num(code)) || 'Error ' + num(code), num(sec, 2)),
      ShowLoadingDlg: () => HB.loading(true), ShowUnvisibleLoadingDlg: () => HB.loading(true, true), CloseLoadding: () => HB.loading(false),
      ShowSpecialLoading: () => HB.loading(true), CloseSpecialLoading: () => HB.loading(false),
      GetModelLayer: () => getModelLayer(),
      ChangeToSub: (type) => HB.game.changeToSub(num(type)),
      ChangeToActivitySubMenu: (name, arg) => HB.game.changeToActivity(txt(name), arg),
      ChangeToActivity: (name) => HB.game.changeToActivity(txt(name)),
      GetSubContentNode: () => HB.game.subContent,
      GetCurrentSubMenu: () => HB.game.currentSub, GetCurrentSubMenuType: () => HB.game.currentSubType || 0, GetPreSubMenuType: () => HB.game.preSubType || 0,
      OnShowUserInfo: () => HB.game.refreshTopBar && HB.game.refreshTopBar(),
      SetNinjalistNeedtoReLoad: () => {}, addChild: (n) => { if (n) { HB.scene.add(n); HB.luaEnter(n); } },
      ShowArenaView: () => HB.game.changeToSub(E.E_ARENAVIEW), LogOut: () => location.reload(),
      ShowPurchasList: () => HB.game.changeToSub(E.E_STOREITEMSVIEW), getHornFlag: () => 0,
    });
    gfn('GetMainMenu', () => mainMenu);
    // the screens (SUBMENUTYPE): the numbers are ours, only this client reads them
    const E = {};
    ['E_DEFAULTMENU', 'E_STOREITEMSVIEW', 'E_GAMEROUND', 'E_GAMEGROUPVIEW', 'E_BACKPACKVIEW', 'E_REINCARNATIONVIEW', 'E_COUNTRYWARDEFAULT', 'E_ARENAVIEW',
      'E_TOWERVIEW', 'E_STRENGTHVIEW', 'E_FIGHTLISTEVIEW', 'E_POTENTIALVIEW', 'E_SUBCHAPTERVIEW', 'E_PLUNDERLISTVIEW', 'E_MONEYTREEVIEW', 'E_MARKLSTVIEW',
      'E_INFORMATIONVIEW', 'E_GAMEBOOKLISTVIEW', 'E_FRIENDLISTVIEW', 'E_COUNTRYTREASURE', 'E_ACTIVITYVIEW'].forEach((n, i) => { E[n] = i + 1; gval(n, i + 1); });
    HB.game.E = E;
    ['E_GET_PURCHASE_LIST', 'E_GET_AWARD'].forEach((n, i) => gval(n, 100 + i));
    gval('E_FRAMETYPE_SMALL', 0); gval('E_FRAMETYPE_MIDDLE', 1); gval('E_FRAMETYPE_LARGE', 2);
    ['SOUND_BUTTON', 'SOUND_BEIJINGMAIN', 'SOUND_DUOBAOJINGJI', 'SOUND_STORY', 'SOUND_TIANTI', 'SOUND_ZHENGUOZHAN'].forEach((n, i) => gval(n, i + 1));
    singleton('CSoundMgr', 'CSoundMgr', { PlayEffect: () => {}, PlayBgSound: () => {}, PlayBgSoundByTypeId: () => {}, StopBgSound: () => {}, StopAllEffect: () => {}, SetEffectOn: () => {}, SetMusicOn: () => {} });

    // ---------------- the game tables by their C++ names: DataMgr.GetDataByID("Struct_Ninjainfo", id).m_ninjaname
    const cols = HB.jsonNow('columns.json') || {};
    const rowsById = new Map();
    const rowOf = (struct, id) => {
      const table = txt(struct).replace(/^Struct_/, '').toLowerCase();
      if (!rowsById.has(table)) {
        const d = HB.jsonNow('data/' + table + '.json');
        const m = new Map();
        if (d) for (const r of d.rows) m.set(r[1], r);
        rowsById.set(table, m);
      }
      const r = rowsById.get(table).get(num(id));
      if (!r) return undefined;
      const t = new LuaTable();
      const names = cols[table] || [];
      for (let i = 1; i < r.length; i++) { const nm = names[i] || 'm_col' + i; const v = r[i]; t.set(B(nm), typeof v === 'string' ? B(v.replace(/\0+$/, '')) : v); }
      return t;
    };
    const dataMgr = new LuaTable();
    dataMgr.set(B('GetDataByID'), (struct, id) => [rowOf(struct, id)]);
    dataMgr.set(B('GetDataCount'), (struct) => { rowOf(struct, -1); const t = rowsById.get(txt(struct).replace(/^Struct_/, '').toLowerCase()); return [t ? t.size : 0]; });
    G.set(B('DataMgr'), dataMgr);
    HB.dataRow = rowOf;

    // ---------------- the event list (the Event screen, CActivityView) and other C++ functions the scripts call
    HB.game.activities = [];
    gfn('ClearActivityName', () => { HB.game.activities = []; });
    gfn('PushActivityName', (name, icon) => { HB.game.activities.push({ name: txt(name), icon: txt(icon) }); });
    gfn('RefreshActivityTips', () => {});
    gfn('GetActivityView', () => HB.game.activityView); gfn('GetActTopBarView', () => HB.game.actTopBar);
    gfn('CallBackFinishTrans', () => {}); gfn('GetLoadScene', () => undefined); gfn('getMyBackpackView', () => HB.game.backpackView);
    gfn('fightdataSetDefenseVipLevel', () => {}); gfn('InAppInitInstance', () => {}); gfn('InAppPurchase', () => {});

    // ---------------- not done yet: the rest answers nil and is logged (each name once)
    HB.openGameObj(lua); // CGameObjElement: pictures and frames (data.js)
    for (const name of ['CTradeMgr', 'CUserGuideManager', 'CFightResultData', 'CProfileData']) {
      const obj = gameObject(name, {});
      const t = new LuaTable();
      const mt = new LuaTable();
      mt.set('__index', (self, k) => { const key = Lua.fromBytes(String(k)); if (key === 'instance' || key === 'sharedInstance') return [asLua(() => obj)]; return [asLua(() => { missing(name + ':' + key); return undefined; })]; });
      t.mt = mt;
      G.set(B(name), t);
    }
  };
})();
