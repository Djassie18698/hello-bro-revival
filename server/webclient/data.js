// What the phone's CPlayerDataMgr kept and CGameObjElement drew, for every screen and for the Lua scripts:
//   HB.data      the player's cards and teams, read from rl_r_mainpage (<card> list, <ninjalist>, <defenseninjalist>)
//   HB.info      name / picture / quality of a ninja, gear, seal, ninjutsu or item from the game tables
//   HB.cardIcon  a small framed picture of one of them (frame by quality, picture, level)
// Card types (the server's cards.type): 1 ninja, 2 weapon, 3 armor, 4 trinket, 5 seal, 6 ninjutsu. Items = consumeinfo ids.
// Pictures (CGameObjElement in libgame.so): ninja icon/icon_<pic> (big art npc/<pic>), gear equip/small_<icon> and big_<icon>,
// ninjutsu skill/small_<icon> and big_<icon>, seal mark/<icon>, item props/<icon> (big_<icon>). Frames by quality 1-6:
// small_icon_frame_0q (ninja, small), middle_frame_0q, small_box_skill_0q / small_box0q / frame_big_0q (things).
'use strict';
(function () {
  const HB = window.HB;
  const T = () => HB.ui.tables;
  const TABLES = ['dropinfo', 'ninjainfo', 'equipmentinfo', 'ninjutsuinfo', 'markinfo', 'consumeinfo', 'playerlevel', 'newcardinfo'];
  const byId = new Map();
  const row = (table, id) => {
    let m = byId.get(table);
    if (!m) { m = new Map(); const t = T()[table]; if (!t) return null; for (const r of t.rows) m.set(r[1], r); byId.set(table, m); }
    return m.get(Number(id)) || null;
  };
  HB.row = row;
  const clean = (s) => String(s ?? '').replace(/\0+$/, '');

  HB.data = {
    cards: new Map(), // seq -> { seq, type, id, level, exp, attri, starlevel, newlife, tupo, status }
    team: [], teamDef: [], // the two line-ups: [{ slot, seq (ninja card), gear: [weapon, armor, trinket, seal], jutsu: [4], atk: [lo, hi], def, chakra, combins }]
    ready: null,
    tables() { return (this.ready = this.ready || Promise.all(TABLES.map((t) => HB.ui.table(t)))); },
    load(main) {
      const x = HB.ui.x;
      this.cards.clear();
      for (const c of main.children) {
        if (c.nodeName !== 'card') continue;
        const g = (k) => x.n(c, k);
        this.cards.set(g('seq'), { seq: g('seq'), type: g('type'), id: g('id'), level: g('level'), exp: g('exp'), attri: g('attri'), starlevel: g('starlevel'), newlife: g('newlife'), tupo: g('tupo_level'), status: g('status') });
      }
      const list = (tag) => x.all(x.first(main, tag), 'ninja').map((n) => {
        const g = (k) => x.n(n, k);
        return { slot: g('seq'), seq: g('ninjaid'), gear: [g('weaponid'), g('armorid'), g('decoratorid'), g('markid')], jutsu: [g('ninjintsu1seq'), g('ninjintsu2seq'), g('ninjintsu3seq'), g('ninjintsu4seq')],
          atk: [g('attacklow'), g('attackhigh')], def: [g('defenselow'), g('defensehigh')], chakra: [g('chakralow'), g('chakrahigh')], combins: x.all(x.first(n, 'combinlist'), 'combin').length };
      }).sort((a, b) => a.slot - b.slot);
      this.team = list('ninjalist'); this.teamDef = list('defenseninjalist');
      this.maxTeam = x.n(x.first(main, 'user'), 'maxteammember');
      this.activeTeam = x.n(x.first(main, 'user'), 'activeTeamId');
    },
    card(seq) { return this.cards.get(Number(seq)) || null; },
    ofType(...types) { return [...this.cards.values()].filter((c) => types.includes(c.type)); },
    inUse(seq) { return [...this.team, ...this.teamDef].some((t) => t.seq === seq || t.gear.includes(seq) || t.jutsu.includes(seq)); },
  };

  // name, picture name, quality and the table row of a thing
  HB.info = (type, id) => {
    let r, o;
    switch (Number(type)) {
      case 1: r = row('ninjainfo', id); o = r && { name: r[2], icon: r[3], quality: r[11] || 1, desc: r[16] }; break;
      case 2: case 3: case 4: r = row('equipmentinfo', id); o = r && { name: r[2], icon: r[4], quality: r[6] || 1, desc: r[19] }; break;
      case 5: r = row('markinfo', id); o = r && { name: r[2], icon: r[4], quality: r[6] || 1, desc: r[7] }; break;
      case 6: r = row('ninjutsuinfo', id); o = r && { name: r[2], icon: r[r.length - 2], quality: r[5] || 1, desc: r[r.length - 3] }; break;
      default: r = row('consumeinfo', id); o = r && { name: r[2], icon: r[3], quality: 1, desc: r[6] };
    }
    if (!o) return { name: '?', icon: '', quality: 1, desc: '', row: null };
    o.name = clean(o.name); o.icon = clean(o.icon); o.desc = clean(o.desc); o.row = r; o.quality = Math.max(1, Math.min(6, o.quality));
    return o;
  };
  // the picture of a thing as a sprite frame; big = the large version where one exists
  HB.iconFrame = (type, icon, big) => {
    if (!icon) return null;
    const t = Number(type);
    if (t === 1) return big ? HB.frameByName(icon) || HB.frameByName('icon_' + icon) : HB.frameByName('icon_' + icon);
    if (t === 5) return HB.frameByName(icon);
    if (t >= 2 && t <= 6) return HB.frameByName((big ? 'big_' : 'small_') + icon) || HB.frameByName('small_' + icon) || HB.frameByName(icon);
    return HB.frameByName(big ? 'big_' + icon : icon) || HB.frameByName('big_' + icon) || HB.frameByName(icon);
  };
  HB.qualityFrame = (kind, q) => HB.frameByName({ ninjaSmall: 'small_icon_frame_0', middle: 'middle_frame_0', small: 'small_box_skill_0', box: 'small_box0', big: 'frame_big_0' }[kind] + Math.max(1, Math.min(6, q)));

  // a small framed picture: HB.cardIcon(type, id, { level, size }) -> a node `size` wide (default: the frame's own size)
  HB.cardIcon = (type, id, opt = {}) => {
    const inf = HB.info(type, id);
    const frame = HB.qualityFrame(Number(type) === 1 ? 'ninjaSmall' : 'small', inf.quality);
    const box = new HB.Sprite(frame);
    const pic = HB.iconFrame(type, inf.icon);
    if (pic) {
      const sp = new HB.Sprite(pic);
      const k = Math.min((box.w - 10) / (pic.sw || 1), (box.h - 10) / (pic.sh || 1));
      sp.sx = sp.sy = k; sp.x = box.w / 2; sp.y = box.h / 2; sp.z = -1;
      box.add(sp);
      box.pic = sp;
    }
    if (opt.level) {
      const l = new HB.BMLabel('characters/number_18.fnt', 'Lv:' + opt.level); HB.loadFntNow('characters/number_18.fnt'); l.setText('Lv:' + opt.level);
      l.x = box.w / 2; l.y = 12; l.z = 2; box.add(l);
    }
    if (opt.size && box.w) box.sx = box.sy = opt.size / box.w;
    box.info = inf;
    return box;
  };
  // stars of a quality: shows the first `q` of the layout's star sprites
  HB.showStars = (n, names, q) => names.forEach((nm, i) => { if (n[nm]) n[nm].visible = i < q; });

  // ---------------------------------------------------------------- the same for the Lua scripts (CGameObjElement)
  HB.openGameObj = (lua) => {
    const { luaClass, txt, B, SpriteFrame } = lua;
    const num = (v, d = 0) => (typeof v === 'number' ? v : Number(v) || d);
    const sf = (f) => (f ? new SpriteFrame(f) : undefined);
    const frameKind = (size) => (num(size) === 0 ? 'small' : num(size) === 1 ? 'box' : 'big');
    luaClass('CGameObjElement', {
      GetNinjaIcon: (size, icon) => sf(HB.iconFrame(1, txt(icon), num(size) === 2)),
      GetEquipIcon: (size, icon) => sf(HB.iconFrame(2, txt(icon), num(size) !== 0)),
      GetNinjutsuIcon: (size, icon) => sf(HB.iconFrame(6, txt(icon), num(size) !== 0)),
      GetConsumeIcon: (size, icon) => sf(HB.iconFrame(0, txt(icon), num(size) !== 0)),
      GetGiftPackIcon: (size, icon) => sf(HB.iconFrame(0, txt(icon), num(size) !== 0)),
      GetMarkFragmentIcon: (size, icon) => sf(HB.iconFrame(5, txt(icon))),
      GetNinjaFrame: (size, q) => sf(HB.qualityFrame(num(size) === 0 ? 'ninjaSmall' : num(size) === 1 ? 'middle' : 'big', num(q, 1))),
      GetItemFrame: (size, q) => sf(HB.qualityFrame(frameKind(size), num(q, 1))),
      GetEquipFrame: (size, q) => sf(HB.qualityFrame(frameKind(size), num(q, 1))),
      GetNinjutsuFrame: (size, q) => sf(HB.qualityFrame(frameKind(size), num(q, 1))),
      GetArenaNinjaFrame: (q) => sf(HB.qualityFrame('small', num(q, 1))),
      GetTopInlayFrame: (size, k) => sf(HB.frameByName(['small', 'middle', 'big'][num(size)] + '_top_inlay_frame' + num(k, 1))),
      GetDownInlayFrame: (size, k) => sf(HB.frameByName(['small', 'middle', 'big'][num(size)] + '_down_inlay_frame' + num(k, 1))),
      SetFrameShadowBack: () => {}, SetFrameShadowFront: () => {}, SetCombatFrameShadowBack: () => {}, SetCombatFrameShadowFront: () => {},
      // a window about one thing / one drop pack: a short tip for now (the phone opens its detail window)
      ShowCommonItemDetail: (type, id) => { const inf = HB.info(num(type), num(id)); HB.tip(inf.name + (inf.desc ? '\n' + inf.desc : ''), 2.5); },
      ShowDropByID: (dropId) => { const d = row('dropinfo', num(dropId)); HB.tip(d ? clean(d[2]) || 'Reward' : 'Reward', 2.5); },
      ShowFillByID: () => {},
    });
  };
})();
