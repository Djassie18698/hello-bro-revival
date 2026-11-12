// Backpack (CMyBackpackView, backpack/MyBackpackView.ccbi) and the list used to pick a card (CGameObjListView,
// gameobjlist/GameObjListview.ccbi). Both show rows made from gameobjlist/ListNinja / ListWeapon / ListArmor / ListAcciess /
// ListNinjutsu / ListMark.ccbi (CGameObjCardView). No request: the cards come with rl_r_mainpage (HB.data).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const LAYOUT = { 1: 'ListNinja', 2: 'ListWeapon', 3: 'ListArmor', 4: 'ListAcciess', 5: 'ListMark', 6: 'ListNinjutsu' };
  const loadLists = () => Promise.all(Object.values(LAYOUT).map((l) => HB.loadCCB('gameobjlist/' + l)));
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' };
  // a card's own numbers from its table row: value at level 1 plus the growth per level
  // (ours for now: the phone also counts growth, rebirth and potential; the team screen shows the server's true numbers)
  function baseStats(card) {
    const r = HB.info(card.type, card.id).row, lv = Math.max(1, card.level) - 1;
    if (!r) return {};
    if (card.type === 1) return { atk: [r[19] + r[25] * lv, r[20] + r[26] * lv], def: [r[21] + r[27] * lv, r[22] + r[28] * lv] };
    if (card.type >= 2 && card.type <= 4) return { atk: [r[7] + r[13] * lv, r[8] + r[14] * lv], def: [r[9] + r[15] * lv, r[10] + r[16] * lv] };
    return {};
  }
  HB.baseStats = baseStats;
  const range = (a) => (a ? Math.round(a[0]) + '-' + Math.round(a[1]) : '0');

  // one row: opt.button = 'choose' | 'upgrade' | null, opt.onButton(card), opt.onRow(card)
  function listCell(card, size, opt = {}) {
    const co = {};
    const cell = HB.build('gameobjlist/' + (LAYOUT[card.type] || 'ListNinja'), co, [size.w, size.h]);
    cell.ignoreAnchor = true; cell.w = size.w; cell.h = size.h;
    const n = co.n, inf = HB.info(card.type, card.id);
    if (n.layer_tips) n.layer_tips.visible = false;
    n.label_name && n.label_name.setText(inf.name);
    n.label_level && n.label_level.setText(String(card.level));
    const frame = HB.qualityFrame(card.type === 1 ? 'ninjaSmall' : 'small', inf.quality);
    if (frame && n.sprite_ninjaicon) n.sprite_ninjaicon.setFrame(frame);
    const pic = HB.iconFrame(card.type, inf.icon);
    if (pic && n.sprite_ninjaicon) {
      const holder = n.node_icon || n.sprite_ninjaicon, w = holder.w || n.sprite_ninjaicon.w, h = holder.h || n.sprite_ninjaicon.h;
      const sp = new HB.Sprite(pic); const k = Math.min((w - (n.node_icon ? 0 : 12)) / pic.sw, (h - (n.node_icon ? 0 : 12)) / pic.sh);
      sp.sx = sp.sy = k; sp.x = w / 2; sp.y = h / 2; if (!n.node_icon) sp.z = -1;
      holder.add(sp);
    }
    if (n.node_inlay_frame) n.node_inlay_frame.visible = false;
    const star = HB.frameByName('com_normal_star');
    for (let i = 1; i <= 5; i++) if (n['sprite_star' + i] && i <= Math.min(5, inf.quality) && star) n['sprite_star' + i].setFrame(star);
    const st = baseStats(card);
    n.label_attack && n.label_attack.setText(range(st.atk));
    n.label_defense && n.label_defense.setText(range(st.def));
    if (n.sprite_ninjacamp) { const f = HB.frameByName(ELEMENT[card.attri] || ELEMENT[1]); if (f) n.sprite_ninjacamp.setFrame(f); }
    if (n.label_tupo_level) { n.label_tupo_level.visible = card.tupo > 0; if (card.tupo > 0) n.label_tupo_level.setText('+' + card.tupo); }
    if (n.label_grade) n.label_grade.visible = false;
    if (n.label_desctype) n.label_desctype.setText(inf.desc);
    // the button on the right
    const label = n['label_' + (LAYOUT[card.type] || 'ListNinja') + '0'];
    const btn = n.sprite_btn_upgrade;
    if (!opt.button) { if (btn) btn.visible = false; if (label) label.visible = false; }
    else if (opt.button === 'upgrade') {
      if (label) label.visible = false;
      const f = HB.frameByName('mypack_cha_upgrade');
      if (f && btn) { const t = new HB.Sprite(f); t.x = btn.w / 2; t.y = btn.h / 2; btn.add(t); }
    } else if (label) label.setText(HB.text('TEXT_LABEL_LISTNINJA0_LISTNINJA') || 'Choose');
    const tapOn = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(card); }; };
    if (btn && opt.button && opt.onButton) tapOn(btn, opt.onButton);
    if (opt.inUse) { const l = new HB.Label('Already in play', 'Helvetica', 18); l.color = [120, 80, 30]; l.ax = 1; l.x = size.w - 14; l.y = 22; cell.add(l); } // text as on the phone
    return cell;
  }
  // a scrolling column of rows inside `box`
  function fillList(box, cellSize, cards, opt) {
    box.removeAll();
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(cards.length * cellSize.h, 1);
    cards.forEach((c, i) => { const cell = listCell(c, cellSize, typeof opt === 'function' ? opt(c) : opt); cell.x = (box.w - cellSize.w) / 2; cell.y = col.h - (i + 1) * cellSize.h; col.add(cell); });
    scroll.setContent(col);
    col.y = col.h < scroll.h ? scroll.h - col.h : scroll.h - col.h;
    box.add(scroll);
    return scroll;
  }
  // strongest and rarest first (ours: the phone's exact order is not known yet)
  const sorted = (cards) => cards.slice().sort((a, b) => HB.info(b.type, b.id).quality - HB.info(a.type, a.id).quality || b.level - a.level || a.seq - b.seq);
  HB.bag = { listCell, fillList, sorted, loadLists };

  // ---------------------------------------------------------------- the Backpack
  const TABS = [['ctrl_ninja', 'BtnNinja', 1], ['ctrl_weapon', 'BtnWeapon', 2], ['ctrl_armors', 'BtnArmors', 3], ['ctrl_shipin', 'BtnAccessori', 4], ['ctrl_ninjutsu', 'Btnninjutsu', 6], ['ctrl_marks', 'BtnMarks', 5]];
  HB.screens.backpack = async function backpack(type = 1) {
    const ui = HB.ui;
    ui.loading(true);
    await Promise.all([HB.data.tables(), HB.loadCCB('backpack/MyBackpackView'), loadLists()]);
    ui.loading(false);
    const o = {};
    HB.game.showSub('backpack/MyBackpackView', o, 'btn_mainpackage');
    const n = o.n;
    n.node_piecebackpack.visible = false;
    for (const k of ['sprite_notify_backpack', 'sprite_notify_ninja', 'sprite_notify_equip', 'sprite_notify_ninjutsu', 'sprite_notify_pet']) if (n[k]) n[k].visible = false;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    const show = (t) => {
      type = t;
      for (const [name, , ty] of TABS) { const b = n[name]; if (b) { b.frames[1] = ty === t ? tabOn || tabOff : tabOff; b.layout(); } }
      const cards = sorted(HB.data.ofType(t));
      fillList(n.node_tablecontent, n.node_cardcontent, cards, (c) => ({ button: t === 1 ? 'upgrade' : null, inUse: HB.data.inUse(c.seq), onButton: () => ui.tip('Coming soon: level up', 1.2) }));
    };
    o.onButton = (sel) => {
      const tab = TABS.find((x) => x[1] === sel);
      if (tab) return show(tab[2]);
      if (sel === 'BtnBackPack') return show(type);
      ui.tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2);
    };
    show(type);
  };

  // ---------------------------------------------------------------- pick one card from a list (the Team screen's "change")
  // HB.pickCard({ types: [1], exclude: (card) => bool, title }) -> resolves the chosen card, or null after Back
  HB.pickCard = async function pickCard(opt) {
    const ui = HB.ui;
    await Promise.all([HB.loadCCB('gameobjlist/GameObjListview'), loadLists()]);
    return new Promise((done) => {
      const o = {};
      const view = ui.screen('gameobjlist/GameObjListview', o);
      view.z = 550;
      const cover = ui.modal(255); cover.z = 549;
      HB.scene.add(cover); HB.scene.add(view);
      ui.fillTopBar(o, HB.game.main);
      const close = (card) => { cover.removeSelf(); view.removeSelf(); done(card); };
      o.onButton = (sel) => { if (sel === 'BtnBack') close(null); };
      const cards = sorted(HB.data.ofType(...opt.types).filter((c) => !(opt.exclude && opt.exclude(c))));
      fillList(o.n.node_tablecontent, o.n.node_cardcontent, cards, () => ({ button: 'choose', onButton: (c) => close(c) }));
      if (!cards.length) ui.tip('Nothing to choose from', 1.5);
    });
  };
})();
