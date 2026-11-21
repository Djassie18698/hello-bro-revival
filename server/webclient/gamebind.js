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

    // ---------------- the player's cards as the scripts see them (CGameObject / CPlayerNinja ...): one object per card, kept per seq
    const two = (n) => String(n).padStart(2, '0');
    const clock = (s) => two(Math.floor(s / 3600)) + ':' + two(Math.floor(s / 60) % 60) + ':' + two(Math.floor(s % 60));
    let refreshing = null;
    const later = () => { if (!refreshing) refreshing = setTimeout(() => { refreshing = null; HB.game.refresh && HB.game.refresh(); }, 400); };
    const cardObjects = new Map();
    function cardObject(c) {
      if (!c) return undefined;
      let o = cardObjects.get(c.seq);
      if (o && o.card === c) return o.obj;
      const inf = () => HB.info(c.type, c.id), st = () => HB.baseStats(c);
      const chakra = () => { const r = inf().row || [], lv = Math.max(1, c.level) - 1; return c.type === 1 ? [r[23] + r[29] * lv, r[24] + r[30] * lv] : [0, 0]; };
      const obj = gameObject('CGameObject', {
        GetGUID: () => c.seq, GetDataID: () => c.id, GetLevel: () => c.level, GetQuality: () => inf().quality, GetName: () => B(inf().name), GetObjType: () => c.type,
        GetReincarnationLevel: () => c.newlife || 0, GetStrengthLevel: () => c.starlevel || 0, GetCardCamp: () => c.attri || 0, GetTupoLevel: () => c.tupo || 0,
        GetAttackMin: () => Math.round((st().atk || [0, 0])[0]), GetAttackMax: () => Math.round((st().atk || [0, 0])[1]),
        GetDefenseMin: () => Math.round((st().def || [0, 0])[0]), GetDefenseMax: () => Math.round((st().def || [0, 0])[1]),
        GetChakraMin: () => Math.round(chakra()[0] || 0), GetChakraMax: () => Math.round(chakra()[1] || 0),
        IsUsingInAnyTeam: () => HB.data.inUse(c.seq), GetCardIcon: () => B(inf().icon), GetCardFrame: () => inf().quality,
        SetLevel: (v) => { c.level = num(v); }, SetReincarnationLevel: (v) => { c.newlife = num(v); }, SetTupoLevel: (v) => { c.tupo = num(v); }, SetCardCamp: (v) => { c.attri = num(v); },
        GetSkillName: () => B(inf().name), GetSkillDesc: () => B(inf().desc), GetSkillIcon: () => B(inf().icon), GetExp: () => c.exp || 0,
      }, {
        m_level: () => c.level, m_quality: () => inf().quality, m_name: () => inf().name, m_ninjaname: () => inf().name, m_ninjaicon: () => inf().icon, m_dataid: () => c.id, m_guid: () => c.seq,
        m_attackmax: () => Math.round((st().atk || [0, 0])[1]), m_attackmin: () => Math.round((st().atk || [0, 0])[0]),
        m_defensemax: () => Math.round((st().def || [0, 0])[1]), m_defensemin: () => Math.round((st().def || [0, 0])[0]),
        m_strengthLevel: () => c.starlevel || 0, m_reincarnationLevel: () => c.newlife || 0,
      });
      obj.__card = c;
      cardObjects.set(c.seq, { card: c, obj });
      return obj;
    }
    // a C++ vector as the scripts use it: list:size(), list[i] from 0
    function vector(items) {
      const size = asLua(() => items.length), at = asLua((self, i) => items[num(i)]);
      return { luaGet(k) { if (typeof k === 'number') return items[k]; const key = Lua.fromBytes(String(k)); return key === 'size' || key === 'count' ? size : key === 'at' || key === 'objectAtIndex' ? at : undefined; }, luaSet() {} };
    }
    ['e_obj_ninja', 'e_obj_weapon', 'e_obj_armors', 'e_obj_decoration', 'e_obj_mark', 'e_obj_ninjutsu'].forEach((n, i) => gval(n, i + 1)); // ours: the server's card types
    const cardList = (type) => vector(HB.data.ofType(type).map(cardObject));
    const teamObject = gameObject('CTeamData', { GetSuitInfo: () => -1, /* no set active: the team's sets are not read from the server yet */ GetTeamSize: () => HB.data.team.length });

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
      GetVipLevel: () => num(user().viplevel), SetVipLevel: (v) => { if (HB.game.user) HB.game.user.viplevel = num(v); HB.game.refreshTopBar && HB.game.refreshTopBar(); },
      AddSilver: (v) => { if (HB.game.user) HB.game.user.coin = num(HB.game.user.coin) + num(v); HB.game.refreshTopBar && HB.game.refreshTopBar(); },
      AddExp: () => later(), AddMerit: () => later(), SetBodyValue: (v) => { if (HB.game.user) HB.game.user.curaction = num(v); HB.game.refreshTopBar && HB.game.refreshTopBar(); },
      // a reward arrived / a card left: the phone patched its own lists, we read the player again from the server (soon after, once)
      AddDataFromReward: () => later(), RemoveObjByID: (seq) => { HB.data.cards.delete(num(seq)); later(); }, updatePieceNum: () => later(),
      GetObjectList: (type) => cardList(num(type)), GetObjectByID: (seq) => cardObject(HB.data.card(num(seq))),
      GetActiveTeam: () => teamObject, GetTeamByIndex: () => teamObject,
      GetMeritIcon: () => undefined, // the rank badge's picture name: the layout's own badge stays
      GetTimeText: (sec) => B(clock(num(sec))), GetTotalPkRestTime: () => 0, GetTotalEnergyRestTime: () => 0, GetPkRestTimeText: () => B('00:00:00'), GetEnergyRestTimeText: () => B('00:00:00'),
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
      AddDialog: (HB.game.addDialog = (layer, node, z) => {
        if (!node) return;
        const dim = new HB.LayerColor(); dim.color = [0, 0, 0]; dim.opacity = 0; dim.w = HB.size[0]; dim.h = HB.size[1]; dim.swallow = true; dim.onTouch = () => {}; dim.ignoreAnchor = true;
        dim.z = num(z); node.__dim = dim;
        layer.add(dim); layer.add(node, num(z)); HB.luaEnter(node);
        const watch = () => { if (!node.parent) { dim.removeSelf(); return; } requestAnimationFrame(watch); };
        requestAnimationFrame(watch);
      }),
    });
    const mainMenu = gameObject('CMainMenu', {
      ShowTextTip: (t, sec) => HB.tip(txt(t), num(sec, 2)),
      ShowErrorTip: (code, sec) => HB.tip(HB.menu(num(code)) || 'Error ' + num(code), num(sec, 2)),
      ShowLoadingDlg: () => HB.loading(true), ShowUnvisibleLoadingDlg: () => HB.loading(true, true), CloseLoadding: () => HB.loading(false),
      ShowSpecialLoading: () => HB.loading(true), CloseSpecialLoading: () => HB.loading(false),
      GetModelLayer: () => getModelLayer(),
      ChangeToSub: (type) => HB.game.changeToSub(num(type)),
      ChangeToActivitySubMenu: (name, arg) => HB.game.changeToActivitySubMenu(txt(name), arg),
      GetActivitySubMenuView: () => HB.game.activitySubMenu,
      ChangeToActivity: (name) => HB.game.changeToActivity(txt(name)),
      GetSubContentNode: () => HB.game.subContent,
      GetCurrentSubMenu: () => HB.game.currentSub, GetCurrentSubMenuType: () => HB.game.currentSubType || 0, GetPreSubMenuType: () => HB.game.preSubType || 0,
      OnShowUserInfo: () => HB.game.refreshTopBar && HB.game.refreshTopBar(),
      SetNinjalistNeedtoReLoad: () => {}, addChild: (n) => { if (n) { HB.scene.add(n); HB.luaEnter(n); } },
      ShowArenaView: () => HB.game.changeToSub(E.E_ARENAVIEW), LogOut: () => location.reload(),
      ShowPurchasList: () => HB.game.changeToSub(E.E_STOREITEMSVIEW), getHornFlag: () => 0,
      // the "you got" window for a reward the scripts read from an <award> (RLRequest.lua InitAwardData -> FightReward)
      AddDialog: (node, z) => { HB.game.addDialog(getModelLayer(), node, z); },
      ShowCommonBox: (reward) => { showReward(reward); },
      ShowCommonBoxForCallBack: (reward, cb) => { showReward(reward).then(() => { if (cb) HB.luaCall(cb); }); },
      ShowNinjaDetail: (card) => { const c = card && card.__card; if (c && HB.screens.details) HB.screens.details(c); },
      getCircleClipNode: () => { const n = new HB.Node(); n.clip = true; return n; }, doPromoter: () => {},
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
    singleton('CSoundMgr', 'CSoundMgr', HB.soundMgr ? HB.soundMgr() : { PlayEffect: () => {}, PlayBackgroundSound: () => {}, PlayBgSoundByTypeId: () => {}, StopBackgroundSound: () => {}, StopAllEffect: () => {}, SetSoundEffectEnable: () => {}, SetBackSoundEnable: () => {} }); // sound.js

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
    // A drop pack that is not in the table (the Lucky Wheel's "super award" slot, drop 1000000) answers with the pack asked for before it:
    // the wheel scripts compare its amount without a nil check and work on the phone, so the C++ cannot answer nil there (our guess: it
    // hands back its last row). Only for Struct_Dropinfo; every other table answers nil for an unknown id.
    let lastDrop;
    dataMgr.set(B('GetDataByID'), (struct, id) => { const r = rowOf(struct, id); if (/dropinfo$/i.test(txt(struct))) { if (r) lastDrop = r; return [r || lastDrop]; } return [r]; });
    dataMgr.set(B('GetDataCount'), (struct) => { rowOf(struct, -1); const t = rowsById.get(txt(struct).replace(/^Struct_/, '').toLowerCase()); return [t ? t.size : 0]; });
    G.set(B('DataMgr'), dataMgr);
    HB.dataRow = rowOf;

    // ---------------- the event list (the Event screen, CActivityView) and other C++ functions the scripts call
    HB.game.activities = [];
    gfn('ClearActivityName', () => { HB.game.activities = []; });
    gfn('PushActivityName', (name, icon) => { HB.game.activities.push({ name: txt(name), icon: txt(icon) }); });
    gfn('RefreshActivityTips', () => {});
    // the Event screen (CActivityView, luascreens.js): the scripts put their layer into its content node
    const activityView = gameObject('CActivityView', {
      GetNodeContent: () => HB.game.activityContent, SetCurrentActIndex: () => {}, onStepNext: () => {}, onStepNextForLua: () => {},
      GetFromNaruto: () => HB.game.activityFrom === 'naruto', GetFromNan: () => HB.game.activityFrom === 'nan',
    });
    const actTopBar = gameObject('CActTopBarView', { Refresh: () => {} });
    gfn('GetActivityView', () => activityView); gfn('GetActTopBarView', () => actTopBar); gfn('GetActivityItemOffset', () => 0);
    gfn('CallBackFinishTrans', () => {}); gfn('GetLoadScene', () => undefined); gfn('getMyBackpackView', () => HB.game.backpackView);
    gfn('fightdataSetDefenseVipLevel', () => {}); gfn('InAppInitInstance', () => {}); gfn('InAppPurchase', () => {});

    HB.openGameObj(lua); // CGameObjElement: pictures and frames (data.js)
    // ---------------- rewards as the scripts build them: FightReward (cards, items, fragments + m_silver, m_gold ...), CardNetData, DropProData
    const TYPE_OF_PIECE = { 1: 1, 2: 2, 3: 6, 4: 5 }; // piece_info m_piece_type -> our card type (shinobi, gear, ninjutsu, seal)
    const field = (t, k) => { const v = t && t.get ? t.get(B(k)) : undefined; return v === undefined || v === null ? 0 : Number(typeof v === 'string' ? txt(v) : v) || 0; };
    function newReward() {
      const cards = [], props = [], chips = [];
      const o = gameObject('FightReward', {
        pushCard: (c) => { cards.push(c); }, pushProp: (c) => { props.push(c); }, pushChipCard: (c) => { chips.push(c); },
        cardCount: () => cards.length, propCount: () => props.length, chipCardCount: () => chips.length,
        getCard: (i) => cards[num(i)], getProp: (i) => props[num(i)], getChipCard: (i) => chips[num(i)],
      });
      o.__reward = { cards, props, chips };
      return o;
    }
    luaClass('FightReward', { new: newReward, create: newReward });
    luaClass('CardNetData', { new: () => new LuaTable(), create: () => new LuaTable() });
    luaClass('DropProData', { new: () => new LuaTable(), create: () => new LuaTable() });
    function showReward(reward) {
      const r = reward && reward.__reward;
      if (!r || !HB.showCards) return Promise.resolve();
      const list = [];
      for (const c of r.cards) list.push({ type: field(c, 'm_type') || 1, id: field(c, 'm_dataid'), num: field(c, 'm_count') || 1 });
      for (const c of r.props) list.push({ type: 0, id: field(c, 'm_id'), num: field(c, 'm_count') || 1 });
      for (const c of r.chips) list.push({ type: TYPE_OF_PIECE[field(c, 'm_type')] || 1, id: field(c, 'm_dataid'), num: field(c, 'm_piecenum') || 1, piece: true });
      later();
      const got = list.filter((c) => c.id > 0);
      if (!got.length) {
        const peer = reward.__peer, g = (k) => (peer ? field(peer, k) : 0);
        const bits = [[g('m_silver'), 'silver'], [g('m_gold'), 'gold'], [g('m_exp'), 'exp'], [g('m_soul'), 'souls'], [g('m_merit'), 'merit'], [g('m_bodyvalue'), 'energy']].filter((b) => b[0] > 0).map((b) => b[0] + ' ' + b[1]);
        if (bits.length) HB.tip('You got ' + bits.join(', '), 2.2);
        return Promise.resolve();
      }
      return HB.showCards(got, 'You got');
    }

    // ---------------- CActivityCommonCardView: a plain node that hands out the nodes of the layout read into it
    luaClass('CActivityCommonCardView', { create: () => { const n = new HB.Node(); n.isLayer = true; n.ignoreAnchor = true; return n; } });
    HB.lua.methods(HB.Node, {
      SetProxy: (n, proxy) => { n.__proxy = proxy; }, AssignCCBMemberVariable: () => {},
      SetIndex: (n, i) => { n.__index = num(i); }, GetIndex: (n) => n.__index || 0,
      onStepNext: () => {}, onStepNextForLua: () => {}, // the tutorial's hooks on the screen that is showing (the tutorial is off)
      GetNode: (n, name) => (n.__proxy && n.__proxy.owner ? n.__proxy.owner.n[txt(name)] : undefined),
    });
    // ---------------- ItemDataInfo + CGameObjElement:GetItemInfoByDropid: what a drop pack holds, in the scripts' own terms
    // mainType 1 card (subType 1 shinobi, 2 gear, 3 seal, 4 ninjutsu), 2 item, 3 silver, 4 gold, 5 fragment, 6 souls (util/common.lua setObjTypeInfo)
    const itemInfoOf = (dropId, t) => {
      const d = HB.row('dropinfo', num(dropId));
      const set = (k, v) => t.set(B(k), typeof v === 'string' ? B(v) : v);
      set('dropid', num(dropId));
      if (!d) { set('mainType', 0); set('subType', 0); set('itemId', 0); set('quality', 1); set('num', 0); set('icon', ''); return; }
      const pick = d[3] ? [1, 1, d[3], 1] : d[4] ? [1, 2, d[4], 2] : d[5] ? [1, 4, d[5], 6] : d[6] ? [1, 3, d[6], 5] : d[7] ? [2, 0, d[7], 0] : d[8] ? [5, 0, d[8], -1] : d[11] ? [3, 0, num(dropId), -1] : d[10] ? [4, 0, num(dropId), -1] : d[9] ? [6, 0, num(dropId), -1] : [0, 0, 0, -1];
      const inf = pick[3] >= 0 ? HB.info(pick[3], pick[2]) : { quality: 1, icon: '', name: '' };
      set('mainType', pick[0]); set('subType', pick[1]); set('itemId', pick[2]); set('quality', inf.quality || 1); set('icon', inf.icon || ''); set('name', inf.name || ''); set('num', d[13] || 1);
    };
    luaClass('ItemDataInfo', { new: () => new LuaTable(), create: () => new LuaTable() });
    const elem = G.get(B('CGameObjElement'));
    if (elem && elem.set) {
      elem.set(B('GetItemInfoByDropid'), (self, dropId, t) => { if (t && t.set) itemInfoOf(dropId, t); return Lua.R.EMPTY; });
      elem.set(B('GetInfoFromDropId'), (self, dropId, t) => { if (t && t.set) itemInfoOf(dropId, t); return Lua.R.EMPTY; });
    }
    // ---------------- CTradeMgr: the items you hold (rl_r_shoplist Cmd 1601 answers the counts; asked once at Home, again after a change)
    HB.game.items = HB.game.items || new Map();
    HB.game.loadItems = async () => { try { const r = await HB.api('rl_r_shoplist', { Cmd: 1601 }); const x = HB.ui.x, m = new Map(); for (const g of x.all(r, 'goods')) m.set(x.n(g, 'propid'), x.n(g, 'bagnum')); if (m.size) HB.game.items = m; HB.game.itemsAt = Date.now(); } catch (e) { /* the counts stay as they were */ } };
    const consumeObject = (id) => { const r = HB.row('consumeinfo', num(id)); if (!r) return undefined; const t = rowOf('Struct_Consumeinfo', num(id)) || new LuaTable(); t.set(B('m_count'), HB.game.items.get(num(id)) || 0); t.set(B('m_bagnum'), HB.game.items.get(num(id)) || 0); return t; };
    const trade = gameObject('CTradeMgr', {
      GetConsumItemCountByID: (id) => HB.game.items.get(num(id)) || 0,
      SetConsumItemCountByID: (id, n) => { HB.game.items.set(num(id), num(n)); },
      GetConsumByIDForLua: (id) => consumeObject(id), GetConsum: (id) => consumeObject(id), SetConsum: () => {},
      GetGiftByIDForLua: () => undefined, GetGift: () => undefined,
      GetRemenLimitRest: () => num(HB.game.ramenLeft, 0), SetRemenLimitRest: (v) => { HB.game.ramenLeft = num(v); }, GetRemenLimitTotal: () => num(HB.game.ramenTotal, 0), SetRemenLimitTotal: (v) => { HB.game.ramenTotal = num(v); },
      GetHyourouganLmtRest: () => 0, GetCMD: () => 0,
      ShowBuyDialogForLua: () => HB.screens.shop && HB.screens.shop(2), UseGiftPackItem: () => {}, UseConsumeItemByID: () => {},
    });
    luaClass('CTradeMgr', { instance: () => trade, sharedInstance: () => trade });
    // paying with real money (Google Play on the phone): top-ups are free on our servers and go through the Top-up window's own request
    luaClass('PayHelperForLua', { goldPay: () => HB.tip('Top-ups are free here: use the Top-up window', 2.2), monthCardPay: () => HB.tip('A free top-up of this price starts the Monthly Card (Top-up window)', 2.6) });

    // ================ FIGHTS THE SCRIPTS START (played by fight.js) ================ begin
    // World Boss (fightBossView.lua), No.1 Shinobi (ui_hallOfFameView.lua) and the Ninja Test (ui_ninjaTestMain.lua) do what the
    // C++ screens do: CFightResultData:instance():Clear(), InitFightXML(<fight>, data), data:SetFightType(...), InitAwardData(
    // data:GetRewardData(), <award>), then CRoundFightView:new():init(), GetMainMenu():addChild(view, 5), view:Start().
    // Here the <fight> (and the <award> the script read) go to HB.fight as XML text; the server has already decided the fight.
    {
      const esc = (v) => String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      const toXml = (t) => { // a LuaXML table ([0] = tag, text keys = attributes, 1..n = children) back to XML text
        if (!(t instanceof LuaTable)) return esc(txt(t));
        let attrs = '';
        for (const [k, v] of t.hash) if (typeof k === 'string') attrs += ' ' + txt(k) + '="' + esc(txt(v)) + '"';
        const tag = txt(t.get(0)) || 'node';
        return '<' + tag + attrs + '>' + t.arr.map(toXml).join('') + '</' + tag + '>';
      };
      const FT_FIGHT = 2, FT_BOSS = 9; // (ours: the scripts only pass them on, the real numbers of the C++ enum are not needed)
      gval('FT_FIGHT', FT_FIGHT); gval('FT_BOSS', FT_BOSS);
      const cur = { fight: '', type: 0, reward: null };
      singleton('CFightResultData', 'CFightResultData', {
        Clear: () => { cur.fight = ''; cur.type = 0; cur.reward = null; G.set(B('InitFightXML'), readFight); },
        SetFightType: (t) => { cur.type = num(t); }, GetFightType: () => cur.type,
        GetRewardData: () => (cur.reward = cur.reward || newReward()),
        IsWin: () => /<preview[^>]*result="1"/.test(cur.fight),
        SetFightbossDamageTimes: () => {}, AddExtData: () => {},
      });
      // RLRequest.lua has its own InitFightXML, which copies the <fight> into C++ objects piece by piece. Every script calls Clear()
      // right before it, so Clear() puts this reader in its place: the whole <fight> is kept as it came.
      const readFight = (node) => { cur.fight = toXml(node); return Lua.R.EMPTY; };
      class LuaFightView extends HB.Node {}
      methods(LuaFightView, {
        init: () => true, SetIsEliteBoss: () => {}, SetFightResultData: () => {},
        Start: (view) => {
          const boss = cur.type === FT_BOSS;
          // a prize the script read from the reply: shown after the fight (the boss fight has no result screen of its own here:
          // the phone's "damage dealt" window, CRoundResultView, is not built; the script's own tip tells what the hit gave)
          const r = cur.reward && cur.reward.__reward;
          const award = r && r.cards.length ? '<award><cardlist>' + r.cards.map((c) => '<card><id>' + num(c.get(B('m_dataid'))) + '</id><type>' + num(c.get(B('m_type'))) + '</type><num>' + (num(c.get(B('m_count'))) || 1) + '</num></card>').join('') + '</cardlist></award>' : '';
          if (cur.fight && HB.fight) HB.fight.playXml(cur.fight + award, { kind: boss ? 'boss' : 'spar', exp: 0, silver: 0, energy: 0, noResult: boss, lua: true })
            .catch((e) => console.error(e)).then(() => { view.removeSelf(); if (HB.game.refresh) HB.game.refresh(); });
          else view.removeSelf();
        },
      });
      const newView = () => new LuaFightView();
      luaClass('CRoundFightView', { new: newView, create: newView });
    }
    // ================ FIGHTS THE SCRIPTS START ================ end

    // ---------------- not done yet: the rest answers nil and is logged (each name once)
    for (const name of ['CUserGuideManager', 'CProfileData']) {
      const obj = gameObject(name, {});
      const t = new LuaTable();
      const mt = new LuaTable();
      mt.set('__index', (self, k) => { const key = Lua.fromBytes(String(k)); if (key === 'instance' || key === 'sharedInstance') return [asLua(() => obj)]; return [asLua(() => { missing(name + ':' + key); return undefined; })]; });
      t.mt = mt;
      G.set(B(name), t);
    }
  };
})();
