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
  const TABLES = ['dropinfo', 'ninjainfo', 'equipmentinfo', 'ninjutsuinfo', 'markinfo', 'consumeinfo', 'playerlevel', 'newcardinfo', 'ninjaupgrade', 'newlifeprop', 'ninjastrengthconfig', 'equipnewlifeprop', 'skill_suit_info', 'normalconfig'];
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
        this.cards.set(g('seq'), { seq: g('seq'), type: g('type'), id: g('id'), level: g('level'), exp: g('exp'), attri: g('attri'), starlevel: g('starlevel'), newlife: g('newlife'), tupo: g('tupo_level'), status: g('status'), pot: [g('attack_add'), g('defence_add'), g('cha_add')] });
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
    get used() { return this.activeTeam === 1 ? this.teamDef : this.team; }, // the line-up in use (activeTeamId 0 = Team 1, 1 = Team 2): Home's card row, fights
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
    if (t === 5) return big ? HB.frameByName(icon) : HB.frameByName('small_' + icon) || HB.frameByName(icon); // a seal in a small box is its own square picture (mark/small_hallmark_N), not the big one made smaller
    if (t >= 2 && t <= 6) return HB.frameByName((big ? 'big_' : 'small_') + icon) || HB.frameByName('small_' + icon) || HB.frameByName(icon);
    return HB.frameByName(big ? 'big_' + icon : icon) || HB.frameByName('big_' + icon) || HB.frameByName(icon);
  };
  HB.qualityFrame = (kind, q) => HB.frameByName({ ninjaSmall: 'small_icon_frame_0', middle: 'middle_frame_0', small: 'small_box_skill_0', box: 'small_box0', big: 'frame_big_0' }[kind] + Math.max(1, Math.min(6, q)));

  // a grown card glows (CGameObjElement::firefly_SetFrameShadowBack / Front: growth 3-5 Green, 6-8 Yellow, 9-11 Blue, 12+ Purple;
  // animations/shadow/<Colour>Frame[Long]Shadow<Back|Front>.ccbi, timeline "action", centred in the layout's node_shadow_back / _front).
  // HB.cardShadow(back node, front node, growth level, long = the fight's tall card). The nodes are emptied first.
  HB.shadowColour = (star) => (star >= 12 ? 'Purple' : star >= 9 ? 'Blue' : star >= 6 ? 'Yellow' : star >= 3 ? 'Green' : '');
  HB.cardShadow = async (back, front, star, long) => {
    const colour = HB.shadowColour(Number(star) || 0);
    for (const [part, host] of [['Back', back], ['Front', front]]) {
      if (!host) continue;
      host.removeAll(); host.visible = !!colour;
      if (!colour) continue;
      const name = 'animations/shadow/' + colour + 'Frame' + (long ? 'Long' : '') + 'Shadow' + part;
      try { await HB.loadCCB(name); } catch (e) { continue; }
      if (host.children.length) continue; // filled again meanwhile
      const g = HB.build(name, {}, [host.w, host.h]);
      g.x = g.ignoreAnchor ? 0 : g.ax * g.w; g.y = g.ignoreAnchor ? 0 : g.ay * g.h; host.add(g); HB.play(g, 'action');
    }
  };

  // A card's own numbers as the phone draws them in the Backpack and on the details window; the same sums as the server's
  // game.ninjaStats / equipStats (CPlayerNinja::firefly_GetAttackMin, CPlayerWeapon::firefly_GetAttackMin):
  //   shinobi: base = (1 + basis) * level-1 value + (1 + grow) * per-level value * (level - 1), basis / grow = newlifeprop of the rebirth
  //            grade; God breakthrough +4 % a level on the element's stats; bonus = (min + max) / 2 * ninjastrengthconfig[growth] + training
  //            points, added to min and max (the green "+N" of the details window)
  //   gear:    (value + per-level value * (level - 1)) * (1 + equipnewlifeprop of its grade)
  //   ninjutsu: m_attackvalue + m_attackvalue_up * (level - 1)
  // -> { atk: [lo, hi], def, chakra, base: { atk, def, chakra } (before the bonus), bonus: [atk, def, chakra] }
  HB.cardStats = (card) => {
    const r = HB.info(card.type, card.id).row, lv = Math.max(1, card.level || 1);
    const none = { atk: [0, 0], def: [0, 0], chakra: [0, 0], base: { atk: [0, 0], def: [0, 0], chakra: [0, 0] }, bonus: [0, 0, 0] };
    if (!r) return none;
    const pack = (v, bonus = [0, 0, 0]) => ({ base: { atk: [v[0], v[1]], def: [v[2], v[3]], chakra: [v[4], v[5]] }, bonus,
      atk: [v[0] + bonus[0], v[1] + bonus[0]], def: [v[2] + bonus[1], v[3] + bonus[1]], chakra: [v[4] + bonus[2], v[5] + bonus[2]] });
    if (card.type === 1) {
      const nl = card.newlife > 0 ? ((T().newlifeprop || {}).rows || []).find((x) => x[3] === card.newlife) : null;
      const basis = nl ? Math.fround(nl[4]) : 0, grow = nl ? Math.fround(nl[5]) : 0; // 32-bit floats on the phone: 0.35 is a hair under 0.35 there (Santa of The Six Paths reads 8106-8978, not 8107-8980)
      const BREAK = { 1: 'c', 2: 'ac', 3: 'dc', 4: 'd', 5: 'a' }[card.attri || 1] || 'c';
      const v = [0, 1, 2, 3, 4, 5].map((i) => Math.floor(((1 + basis) * (r[19 + i] || 0) + (1 + grow) * (r[25 + i] || 0) * (lv - 1)) * (1 + (BREAK.includes('adc'[i >> 1]) ? 0.04 * (card.tupo || 0) : 0))));
      const add = ((((T().ninjastrengthconfig || {}).rows || []).find((x) => x[1] === (card.starlevel || 0))) || [])[2] || 0;
      const pot = card.pot || [0, 0, 0];
      const bonus = [0, 1, 2].map((s) => Math.trunc(Math.fround(Math.fround(v[2 * s] + v[2 * s + 1]) * Math.fround(add)) * 0.5) + (pot[s] || 0));
      return pack(v, bonus);
    }
    if (card.type >= 2 && card.type <= 4) {
      const row = ((T().equipnewlifeprop || {}).rows || []).find((x) => x[3] === (card.newlife || 0));
      const mult = 1 + (row ? row[4] : 0);
      return pack([0, 1, 2, 3, 4, 5].map((i) => Math.floor(((r[7 + i] || 0) + (r[13 + i] || 0) * (lv - 1)) * mult)));
    }
    if (card.type === 6) { const a = (r[10] || 0) + (r[18] || 0) * (lv - 1); return pack([a, a, a, a, 0, 0]); }
    return none;
  };
  // the game's own order of a card list (CLess, used by CPlayerDataMgr::firefly_Resort): cards in use first, then more stars, then the
  // higher rebirth grade, then the higher growth, then the table's rank number (ninjainfo m_ninjarank, lowest first); equal cards stand by id, then in the order they came (as seen on the phone)
  HB.sortCards = (cards) => cards.slice().sort((a, b) => {
    const ia = HB.info(a.type, a.id), ib = HB.info(b.type, b.id);
    return (HB.data.inUse(b.seq) - HB.data.inUse(a.seq)) || ib.quality - ia.quality || (b.newlife || 0) - (a.newlife || 0) || (b.starlevel || 0) - (a.starlevel || 0)
      || (a.type === 1 ? ((ia.row || [])[5] || 0) - ((ib.row || [])[5] || 0) : 0) || a.id - b.id || a.seq - b.seq;
  });
  // the set a ninjutsu or a piece of gear belongs to (skill_suit_info: [3] kind 1 = four ninjutsu ids, 2 = weapon, armor, trinket, seal)
  HB.skillSuit = (c) => (((T().skill_suit_info || {}).rows) || []).find((r) => (c.type === 6 ? r[3] === 1 && r.slice(4, 8).includes(c.id) : r[3] === 2 && r[4 + [2, 3, 4, 5].indexOf(c.type)] === c.id)) || null;
  // the "Suit" ribbon over the corner of such a card's small box (setEquipSuitIconTitle: ccbResources/equip_suit.plist icon_title_<colour>)
  HB.suitRibbon = (box, card) => {
    box.children.filter((k) => k._ribbon).forEach((k) => k.removeSelf());
    if (!HB.skillSuit(card)) return null;
    const rf = HB.frameByName('icon_title_' + (['yellow', 'green', 'blue', 'purple', 'orange'][HB.info(card.type, card.id).quality - 2] || 'yellow'));
    if (!rf) return null;
    const rb = new HB.Sprite(rf); rb._ribbon = true; rb.x = rf.sw / 2; rb.y = (box.h || 0) - rf.sh / 2; rb.z = 5; box.add(rb);
    return rb;
  };

  // What every shinobi card wears besides its picture and stars (CGameObjElement::firefly_NinjaCardCommonInit):
  //   the silver corners of a reborn card (newlife 1-8: <size>_top_inlay_frame<n> / <size>_down_inlay_frame<n>) and its dragon mark,
  //   the glow of a grown card, and the exp bar: as full as the exp towards the next level, or full with the word "Max" at the top level.
  // size = 'small' | 'middle' | 'big' (the layout's card size); m = the layout's named nodes.
  HB.cardDress = (m, card, size) => {
    const life = Math.max(0, Math.min(8, Number(card.newlife) || 0));
    if (m.node_inlay_frame) m.node_inlay_frame.visible = life > 0;
    for (const [k, part] of [['sprite_frame_corner1', 'top'], ['sprite_frame_corner2', 'down']]) {
      const f = life > 0 && HB.frameByName(size + '_' + part + '_inlay_frame' + life);
      if (m[k]) { m[k].visible = !!f; if (f) m[k].setFrame(f); }
    }
    if (m.sprite_dragon_icon) { const f = life > 0 && HB.frameByName(size + '_dragon' + life); m.sprite_dragon_icon.visible = !!f; if (f) m.sprite_dragon_icon.setFrame(f); }
    HB.cardShadow(m.node_shadow_back, m.node_shadow_front, card.starlevel);
    // the growth badge (cards_level_<size>_<growth>, ccbResources/strengthLevelIcon.plist)
    if (m.sprite_strength_level_icon) {
      const g = card.starlevel > 0 && HB.frameByName('cards_level_' + (size === 'big' ? 'big' : 'small') + '_' + card.starlevel);
      m.sprite_strength_level_icon.visible = !!g; if (m.sprite_strength_level_frame) m.sprite_strength_level_frame.visible = !!g;
      if (g) m.sprite_strength_level_icon.setFrame(g);
    }
    const bar = m.sprite_ninjaexp || m.sprite_expval, up = (T().ninjaupgrade || {}).rows;
    if (bar && up) {
      const top = up.length, need = (up.find((r) => r[1] === card.level) || [])[2] || 0;
      if (bar._w === undefined) bar._w = bar.w;
      const full = card.level >= top;
      bar.w = Math.max(1, bar._w * (full || !need ? 1 : Math.max(0, Math.min(1, card.exp / need))));
      if (bar._max) { bar._max.removeSelf(); bar._max = null; }
      if (full) { const l = new HB.Label('Max', 'Arial-BoldMT', 30, [0, 0], 1, 1); l.x = bar._w / 2; l.y = bar.h / 2; bar.add(l); bar._max = l; }
    }
  };

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
      GetNinjaIcon: (size, icon) => sf(HB.iconFrame(1, txt(icon), num(size) !== 0)), // the phone: size 0 = the small icon_<name>, middle and large = the big picture npc/<name> (the scripts scale it: God Recruit's win card 0.5)
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
      GetFrameDragon: (size, k) => sf(HB.frameByName(['small', 'middle', 'big'][num(size)] + '_dragon' + num(k))), // the dragon mark of a reborn card (phone: middle_dragon%d / big_dragon%d)
      SetFrameShadowBack: () => {}, SetFrameShadowFront: () => {}, SetCombatFrameShadowBack: () => {}, SetCombatFrameShadowFront: () => {},
      // a window about one thing / one drop pack: a short tip for now (the phone opens its detail window)
      // a window about one thing: ShowCommonItemDetail(1, 1 shinobi / 2 gear / 3 seal / 4 ninjutsu, id) or (2, 0, item id); the details window for cards, a tip for items
      ShowCommonItemDetail: (main, sub, id) => {
        const type = num(main) === 1 ? ({ 1: 1, 2: 2, 3: 5, 4: 6 }[num(sub)] || 1) : 0;
        if (type && HB.screens.details) { const r = HB.info(type, num(id)).row; return void HB.screens.details({ seq: 0, type: type === 2 && r ? (r[3] || 2) : type, id: num(id), level: 1, attri: 0, tupo: 0 }, { view: true }); }
        const inf = HB.info(type, num(id)); HB.tip(inf.name + (inf.desc ? '\n' + inf.desc : ''), 2.5);
      },
      // what a drop pack holds: the things themselves in the "you got" look (title Contains), or its words for a random pack
      ShowDropByID: (dropId) => {
        const d = row('dropinfo', num(dropId));
        if (!d) return;
        const got = d[3] ? { type: 1, id: d[3] } : d[4] ? { type: 2, id: d[4] } : d[5] ? { type: 6, id: d[5] } : d[6] ? { type: 5, id: d[6] } : d[7] ? { type: 0, id: d[7] } : null;
        if (got && HB.showCards && d[12] !== 1) return void HB.showCards([{ ...got, num: d[13] || 1 }], 'Contains');
        HB.tip(clean(d[2]) || 'Reward', 2.5);
      },
      ShowFillByID: () => {},
    });
  };
})();
