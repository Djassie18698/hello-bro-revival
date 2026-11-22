// Backpack (CMyBackpackView, backpack/MyBackpackView.ccbi) and the list used to pick a card (CGameObjListView,
// gameobjlist/GameObjListview.ccbi). Both show rows made from gameobjlist/ListNinja / ListWeapon / ListArmor / ListAcciess /
// ListNinjutsu / ListMark.ccbi (CGameObjCardView). The cards come with rl_r_mainpage (HB.data).
// A row like the phone (CGameObjCardView::initClickFuncs): the picture opens the card's details, the button levels it up, a tap on
// the row itself turns it over to its tip (layer_tips, backpack/BackpackTips.ccbi): where such cards come from (packtips [2]) with
// "Go shopping" (the Shop on tab packtips [4]) and a second button to Training / Spar / Plunder (packtips [3] = 1 / 2 / 3).
// v28 has no selling and no soul / element / inherit / split buttons on a row: the app's row code only knows the buttons above
// (card split, rl_w_split_card, is never opened; refining shinobi into souls is the Secret Shop's own screen).
// Fragments tab (BackpackNinjaPiece / EquipPiece / NinjutsuPiece / PetPiece.ccbi): the <chipbag> of rl_r_mainpage, one row per
// piece_info id you hold ([3] kind 1 shinobi / 2 gear / 4 ninjutsu / 5 pet, [4] attack / defence / god card, [5] stars, [6] what it
// becomes, [7] how many are needed, [8] the drop pack). Merge = rl_w_comm Cmd 10 ChipBagID=<piece id>; the reply's <award> is shown.
// Red dots (firefly_hasMerge): on a fragment kind, and on the Fragments tab, when something there can be merged.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const LAYOUT = { 1: 'ListNinja', 2: 'ListWeapon', 3: 'ListArmor', 4: 'ListAcciess', 5: 'ListMark', 6: 'ListNinjutsu' };
  const PIECE = { 1: ['BackpackNinjaPiece', 'ctrl_ninja_piece', 'BtnNinjaPiece', 'sprite_notify_ninja', 'Shinobi'], 2: ['BackpackEquipPiece', 'ctrl_equip_piece', 'BtnEquipPiece', 'sprite_notify_equip', 'Equip'],
    4: ['BackpackNinjutsuPiece', 'ctrl_ninjutsu_piece', 'BtnninjutsuPiece', 'sprite_notify_ninjutsu', 'Ninjutsu'], 5: ['BackpackPetPiece', 'ctrl_pet_piece', 'BtnpetPiece', 'sprite_notify_pet', 'Fragment'] };
  const loadLists = () => Promise.all([...Object.values(LAYOUT).map((l) => HB.loadCCB('gameobjlist/' + l)), HB.ui.table('packtips'), HB.ui.table('functionconfig')]);
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' };
  const PAGE_TITLE = { 1: 'mypack_cha_gotoexperience', 2: 'mypack_cha_tofight', 3: 'mypack_cha_gotoplunder' };
  const clean = (s) => String(s ?? '').replace(/\0+$/, '').trim();
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
  const tapOn = (node, fn) => { if (!node) return; node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  // a name that is too long for its box gets smaller instead of running over the picture next to it
  const fitName = (label, max) => { if (label && label.w > max) label.sx = label.sy = Math.max(0.6, max / label.w); };
  // a picture drawn straight on its frame: over the frame (its middle is not see-through), under the frame's own labels (Lv, +N)
  const under = (holder, sp) => { const k = holder.children; k.splice(k.indexOf(sp), 1); k.unshift(sp); };
  // the row turns over between its card (layer_info) and its tip (layer_tips)
  function flip(cell, n) {
    cell.swallow = true;
    tapOn(cell, () => { const tips = !n.layer_tips.visible; n.layer_tips.visible = tips; n.layer_info.visible = !tips; });
  }

  // one row: opt.button = 'choose' | 'upgrade' | null, opt.onButton(card), opt.onRow(card), opt.tips = the row turns over to its tip
  function listCell(card, size, opt = {}) {
    const co = {};
    const cell = HB.build('gameobjlist/' + (LAYOUT[card.type] || 'ListNinja'), co, [size.w, size.h]);
    cell.ignoreAnchor = true; cell.w = size.w; cell.h = size.h;
    const n = co.n, inf = HB.info(card.type, card.id);
    if (n.layer_tips) n.layer_tips.visible = false;
    if (n.label_name) { n.label_name.setText(inf.name); if (card.type === 1 && n.sprite_ninjacamp) n.label_name.x = 198; fitName(n.label_name, card.type === 1 ? 136 : 190); } // shinobi: centred between the picture and the element badge
    n.label_level && n.label_level.setText(String(card.level));
    const frame = HB.qualityFrame(card.type === 1 ? 'ninjaSmall' : 'small', inf.quality);
    if (frame && n.sprite_ninjaicon) n.sprite_ninjaicon.setFrame(frame);
    const pic = HB.iconFrame(card.type, inf.icon);
    if (pic && n.sprite_ninjaicon) {
      const holder = n.node_icon || n.sprite_ninjaicon, w = holder.w || n.sprite_ninjaicon.w, h = holder.h || n.sprite_ninjaicon.h;
      const sp = new HB.Sprite(pic); const k = Math.min((w - (n.node_icon ? 0 : 12)) / pic.sw, (h - (n.node_icon ? 0 : 12)) / pic.sh);
      sp.sx = sp.sy = k; sp.x = w / 2; sp.y = h / 2;
      holder.add(sp); if (!n.node_icon) under(holder, sp);
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
    if (btn && opt.button && opt.onButton) tapOn(btn, () => opt.onButton(card));
    if (opt.onRow && n.sprite_ninjaicon) tapOn(n.sprite_ninjaicon, () => opt.onRow(card)); // the picture opens the card's details
    if (opt.inUse && n.layer_info) { const l = new HB.Label('Already in play', 'Helvetica', 18); l.color = [120, 80, 30]; l.ax = 1; l.x = size.w - 14; l.y = 22; n.layer_info.add(l); } // text as on the phone
    // the tip side: where these cards come from, and the two ways there
    const tip = opt.tips && n.layer_tips && n.layer_info && HB.row('packtips', { 5: 6, 6: 5 }[card.type] || card.type); // packtips rows: shinobi, weapon, armor, trinket, ninjutsu, seal
    if (tip) {
      if (n.label_tiptext) { n.label_tiptext.dims = [size.w - 60, 0]; n.label_tiptext.setText(clean(tip[2])); }
      const f = HB.frameByName(PAGE_TITLE[tip[3]]); if (f && n.sprite_gotopagetitle) n.sprite_gotopagetitle.setFrame(f);
      tapOn(n.sprite_gotostore, () => HB.screens.shop && HB.screens.shop(Math.max(0, tip[4] - 1))); // CStoreItemsView::SetTabView(packtips [4])
      tapOn(n.sprite_gotopage, () => { // CGameObjCardView::GotoPage
        if (tip[3] === 2) return HB.screens.spar && HB.screens.spar();
        if (tip[3] === 3) {
          const fc = HB.row('functionconfig', 2), lv = Number((HB.game.user || {}).level) || 1; // Plunder opens at functionconfig 2's level
          if (fc && lv < fc[3]) return HB.ui.tip(clean(fc[4]) || 'Plunder opens at level ' + fc[3], 1.8);
          return HB.screens.plunder && HB.screens.plunder();
        }
        return HB.screens.training && HB.screens.training();
      });
      flip(cell, n);
    }
    return cell;
  }
  // ---------------------------------------------------------------- the Backpack's own rows
  // CMyBackpackCardView with backpack/Backpack<Kind>.ccbi (compared with the phone 22 Nov 2026; the gameobjlist/List<Kind> rows above
  // are the "choose a card" lists). A shinobi row: picture with glow and reborn corners, name, element, five stars (gold up to its
  // stars), attack / defence / chakra as the details window counts them, "Already in play", Level up, and under the numbers the small
  // buttons Soul (a card not in play whose stars may be refined: normalconfig 81 + stars, god cards always) and WuXing conversion
  // (Change Element). Gear: its one number, +N of an advanced weapon / armor, the "Suit" ribbon. The list ends with one tip row
  // (where these cards come from, Go shopping / the page it names).
  const PACK = { 1: 'BackpackNinja', 2: 'BackpackWeapon', 3: 'BackpackArmor', 4: 'BackpackAcciess', 5: 'BackpackMark', 6: 'BackpackNinjutsu' };
  const packLists = () => Promise.all([...Object.values(PACK).map((l) => HB.loadCCB('backpack/' + l)), HB.ui.table('packtips'), HB.ui.table('functionconfig')]);
  function packCell(card, size, opt = {}) {
    const type = card.tipFor || card.type, co = {};
    const cell = HB.build('backpack/' + PACK[type], co, [size.w, size.h]);
    cell.ignoreAnchor = true; cell.w = size.w; cell.h = size.h;
    const n = co.n;
    if (card.tipFor) { // the last row: the tip
      if (n.layer_info) n.layer_info.visible = false;
      if (n.layer_tips) n.layer_tips.visible = true;
      const tip = HB.row('packtips', { 5: 6, 6: 5 }[type] || type); // packtips rows: shinobi, weapon, armor, trinket, ninjutsu, seal
      if (tip) {
        if (n.label_tiptext) { n.label_tiptext.dims = [size.w - 60, 0]; n.label_tiptext.setText(clean(tip[2])); }
        const f = HB.frameByName(PAGE_TITLE[tip[3]]); if (f && n.sprite_gotopagetitle) n.sprite_gotopagetitle.setFrame(f);
        tapOn(n.sprite_gotostore, () => HB.screens.shop && HB.screens.shop(Math.max(0, tip[4] - 1))); // CStoreItemsView::SetTabView(packtips [4])
        tapOn(n.sprite_gotopage, () => {
          if (tip[3] === 2) return HB.screens.spar && HB.screens.spar();
          if (tip[3] === 3) {
            const fc = HB.row('functionconfig', 2), lv = Number((HB.game.user || {}).level) || 1;
            if (fc && lv < fc[3]) return HB.ui.tip(clean(fc[4]) || 'Plunder opens at level ' + fc[3], 1.8);
            return HB.screens.plunder && HB.screens.plunder();
          }
          return HB.screens.training && HB.screens.training();
        });
      }
      return cell;
    }
    const inf = HB.info(card.type, card.id), used = HB.data.inUse(card.seq);
    if (n.layer_tips) n.layer_tips.visible = false;
    if (n.label_name) n.label_name.setText(inf.name);
    if (n.label_level) n.label_level.setText(String(card.level));
    const frame = HB.qualityFrame(card.type === 1 ? 'ninjaSmall' : 'small', inf.quality);
    if (frame && n.sprite_ninjaicon) n.sprite_ninjaicon.setFrame(frame);
    const pic = HB.iconFrame(card.type, inf.icon);
    if (pic && n.sprite_ninjaicon) {
      const holder = n.node_icon || n.sprite_ninjaicon, w = holder.w || n.sprite_ninjaicon.w, h = holder.h || n.sprite_ninjaicon.h;
      const sp = new HB.Sprite(pic); const k = Math.min((w - (n.node_icon ? 0 : 12)) / pic.sw, (h - (n.node_icon ? 0 : 12)) / pic.sh);
      sp.sx = sp.sy = k; sp.x = w / 2; sp.y = h / 2;
      holder.add(sp); if (!n.node_icon) under(holder, sp);
    }
    if (card.type === 1) HB.cardDress(n, card, 'small');
    else if (n.sprite_ninjaicon) HB.suitRibbon(n.sprite_ninjaicon, card);
    const star = HB.frameByName('com_normal_star');
    for (let i = 1; i <= 5; i++) if (n['sprite_star' + i] && i <= Math.min(5, inf.quality) && star) n['sprite_star' + i].setFrame(star);
    const st = HB.cardStats(card), dash = card.type === 2 || card.type === 3 ? '--' : '-', rng = (a) => a[0] + dash + a[1]; // a weapon's and an armor's number has two dashes on the phone ('%d--%d')
    if (n.label_attack) n.label_attack.setText(rng(st.atk));
    if (n.label_defense) n.label_defense.setText(rng(st.def));
    if (n.label_charkra) n.label_charkra.setText(rng(st.chakra));
    if (n.sprite_ninjacamp) { const f = HB.frameByName(ELEMENT[card.attri] || ELEMENT[1]); if (f) n.sprite_ninjacamp.setFrame(f); }
    if (n.label_tupo_level) { n.label_tupo_level.visible = card.tupo > 0; if (card.tupo > 0) n.label_tupo_level.setText('+' + card.tupo); }
    if (n.label_grade) { n.label_grade.visible = card.newlife > 0; if (card.newlife > 0) n.label_grade.setText('+' + card.newlife); }
    if (n.label_desctype) n.label_desctype.setText(''); // the phone's Backpack shows no text under a seal's name
    if (n.label_equiped) n.label_equiped.visible = used;
    // the small buttons
    const soul = card.type === 1 && !used && (inf.quality >= 6 || ((HB.row('normalconfig', 81 + inf.quality) || [])[3] === 1));
    if (n.spr_btn_trainsoul) n.spr_btn_trainsoul.visible = soul;
    const split = card.type === 1 && !used && inf.quality >= 6; // Decompose: a god card that is not in play
    if (n.spr_btn_split) n.spr_btn_split.visible = split;
    if (n.spr_btn_change_attr) n.spr_btn_change_attr.visible = true;
    if (split) tapOn(n.spr_btn_split, () => opt.onSplit && opt.onSplit(card));
    if (n.spr_btn_inherit_disableit) n.spr_btn_inherit_disableit.visible = false;
    if (n.sprite_btn_advance) n.sprite_btn_advance.visible = false;
    if (soul) tapOn(n.spr_btn_trainsoul, () => HB.game.changeToActivitySubMenu('ShowTrainSoulView', 'gTrainSoulEntry={prePage="backpack", bagId=' + card.seq + '}'));
    tapOn(n.spr_btn_change_attr, () => HB.game.changeToActivitySubMenu('ShowAttributeDanView', card.seq));
    tapOn(n.sprite_btn_upgrade, () => opt.onButton && opt.onButton(card));
    if (opt.onRow && n.sprite_ninjaicon) tapOn(n.sprite_ninjaicon, () => opt.onRow(card)); // the picture opens the card's details
    return cell;
  }
  // a scrolling column of rows inside `box`
  function fillList(box, cellSize, cards, opt, make = listCell) {
    box.removeAll();
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(cards.length * cellSize.h, 1);
    cards.forEach((c, i) => { const cell = make(c, cellSize, typeof opt === 'function' ? opt(c) : opt); cell.x = (box.w - cellSize.w) / 2; cell.y = col.h - (i + 1) * cellSize.h; col.add(cell); });
    scroll.setContent(col);
    col.y = scroll.h - col.h;
    box.add(scroll);
    return scroll;
  }
  // strongest and rarest first (ours: the phone's exact order is not known yet)
  const sorted = (cards) => HB.sortCards(cards); // the game's own order (CLess)
  HB.bag = { listCell, fillList, sorted, loadLists };

  // ---------------------------------------------------------------- fragments
  // the fragments you hold: [{ id, num, row (piece_info), kind, need, ready }]
  function pieces() {
    const x = HB.ui.x, bag = HB.game.main && x.first(HB.game.main, 'chipbag');
    return (bag ? x.all(bag, 'chipitem') : []).map((c) => {
      const id = Number(x.a(c, 'id', 0)), num = Number(x.a(c, 'num', 0)), row = HB.row('piece_info', id);
      return row && num > 0 ? { id, num, row, kind: row[3], need: row[7], ready: num >= row[7] } : null;
    }).filter(Boolean).sort((a, b) => (b.ready - a.ready) || rankOf(b)[0] - rankOf(a)[0] || rankOf(a)[1] - rankOf(b)[1] || a.id - b.id); // as seen on the phone: god cards first, then by the card's rank number
  }
  function rankOf(p) { // [stars of the card the fragments make (god = 6), its rank number]
    if (p.kind !== 1) return [p.row[5] || 0, 0];
    const r = HB.row('ninjainfo', p.row[6]) || HB.info(1, p.row[6]).row || [];
    return [r[11] || p.row[5] || 0, r[5] || 0];
  }
  HB.bag.pieces = pieces;
  // what a piece becomes: the card type and id for HB.info, or a pet (petinfo [2] name, [3] picture)
  function target(p) {
    const id = p.row[6];
    if (p.kind === 1) return { type: 1, id };
    if (p.kind === 2) { const r = HB.row('equipmentinfo', id); return { type: 2 + ((r && r[3]) || 0), id }; }
    if (p.kind === 4) return { type: 6, id };
    return { pet: HB.row('petinfo', id), id };
  }
  function pieceCell(p, size, opt) {
    const co = {};
    const cell = HB.build('backpack/' + PIECE[p.tipFor || p.kind][0], co, [size.w, size.h]);
    cell.ignoreAnchor = true; cell.w = size.w; cell.h = size.h;
    if (p.tipFor) { // the list's last row, like the phone: where fragments come from + the way to the Secret Shop
      const m = co.n;
      if (m.layer_info) m.layer_info.visible = false;
      if (m.layer_tips) m.layer_tips.visible = true;
      tapOn(m.sprite_gotostore, () => HB.game.changeToActivitySubMenu && HB.game.changeToActivitySubMenu('ShowSecretShopView', 'gSecretShopEntry={prePage="backpack"}')); // CMyBackpackCardView::GotoMysticalStore
      return cell;
    }
    const n = co.n, t = target(p), inf = t.pet ? { name: clean(t.pet[2]), icon: clean(t.pet[3]), quality: 5 } : HB.info(t.type, t.id);
    if (n.layer_tips) n.layer_tips.visible = false;
    if (n.label_name) { n.label_name.setText(clean(p.row[2]) || inf.name); fitName(n.label_name, 165); }
    // "Number of fragments:" and "Not gathered yet" stay the game's own words (fit.js makes them fit)
    const stars = p.row[5] || 0, star = HB.frameByName('com_normal_star');
    for (let i = 1; i <= 5; i++) { const s = n['sprite_star' + i]; if (!s) continue; s.visible = stars > 0; if (i <= Math.min(5, stars) && star) s.setFrame(star); }
    const kindOf = t.pet ? 1 : t.type;
    const frame = HB.qualityFrame(kindOf === 1 ? 'ninjaSmall' : 'small', t.pet ? 5 : inf.quality);
    if (frame && n.sprite_ninjaicon) n.sprite_ninjaicon.setFrame(frame);
    const pic = HB.iconFrame(kindOf, inf.icon);
    if (pic && n.sprite_ninjaicon) {
      const holder = n.node_ninjaicon || n.sprite_ninjaicon, w = holder.w || n.sprite_ninjaicon.w, h = holder.h || n.sprite_ninjaicon.h, pad = n.node_ninjaicon ? 0 : 12;
      const sp = new HB.Sprite(pic), k = Math.min((w - pad) / pic.sw, (h - pad) / pic.sh);
      sp.sx = sp.sy = k; sp.x = w / 2; sp.y = h / 2; holder.add(sp); if (!n.node_ninjaicon) under(holder, sp);
    }
    if (n.label_collect) n.label_collect.setText(p.num + '/' + p.need);
    if (n.node_lack) n.node_lack.visible = !p.ready;
    if (n.sprite_btn_merge) n.sprite_btn_merge.visible = p.ready;
    if (n.label_merge) { n.label_merge.visible = p.ready; n.label_merge.setText('Merge'); }
    for (let i = 1; i <= 3; i++) if (n['sprite_ninja_type' + i]) n['sprite_ninja_type' + i].visible = p.kind === 1 && p.row[4] === i; // attack card / defence card / god card
    if (p.ready) tapOn(n.sprite_btn_merge, () => opt.onMerge(p, t));
    if (!t.pet) tapOn(n.sprite_ninjaicon, () => HB.screens.details && HB.screens.details({ seq: 0, type: t.type, id: t.id, level: 1, attri: 0, tupo: 0 }, { view: true }));
    return cell;
  }

  // ---------------------------------------------------------------- the Backpack
  const TABS = [['ctrl_ninja', 'BtnNinja', 1], ['ctrl_weapon', 'BtnWeapon', 2], ['ctrl_armors', 'BtnArmors', 3], ['ctrl_shipin', 'BtnAccessori', 4], ['ctrl_ninjutsu', 'Btnninjutsu', 6], ['ctrl_marks', 'BtnMarks', 5]];
  // backpack(1-6) = the cards of that kind; backpack(11 / 12 / 14 / 15) = Fragments: shinobi / gear / ninjutsu / pet
  HB.screens.backpack = async function backpack(type = 1) {
    const ui = HB.ui;
    type = Number(type) || 1;
    ui.loading(true);
    await Promise.all([HB.data.tables(), HB.loadCCB('backpack/MyBackpackView'), loadLists(), packLists(), ui.table('piece_info'), ui.table('petinfo'), ...Object.values(PIECE).map((p) => HB.loadCCB('backpack/' + p[0]))]);
    ui.loading(false);
    const o = {};
    HB.game.showSub('backpack/MyBackpackView', o, 'btn_mainpackage');
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    let cardType = type >= 1 && type <= 6 ? type : 1, pieceKind = PIECE[type - 10] ? type - 10 : 0;
    const dots = () => {
      const ready = new Set(pieces().filter((p) => p.ready).map((p) => p.kind));
      if (n.sprite_notify_backpack) n.sprite_notify_backpack.visible = ready.size > 0;
      for (const k of Object.keys(PIECE)) { const d = n[PIECE[k][3]]; if (d) d.visible = ready.has(Number(k)); }
    };
    const top = (frag) => {
      n.node_backpack.visible = !frag; n.node_piecebackpack.visible = frag;
      for (const [b, on] of [[n.ctrl_backpack, !frag], [n.ctrl_piecebackpack, frag]]) if (b) { b.selected = on; b.layout(); } // the buttons' own lit pictures
    };
    const show = (t) => {
      cardType = t; pieceKind = 0; top(false); dots();
      for (const [name, , ty] of TABS) { const b = n[name]; if (b) { b.frames[1] = ty === t ? tabOn || tabOff : tabOff; b.layout(); } }
      const cards = HB.sortCards(HB.data.ofType(t));
      fillList(n.node_tablecontent, n.node_cardcontent, [...cards, { tipFor: t }], () => ({ onButton: (k) => HB.screens.upgrade(k.seq), onRow: (k) => HB.screens.details && HB.screens.details(k) }), packCell);
      note(cards.length ? '' : 'Nothing here yet');
    };
    const showPieces = (kind) => {
      pieceKind = kind; top(true); dots();
      for (const k of Object.keys(PIECE)) { const b = n[PIECE[k][1]]; if (b) { b.frames[1] = Number(k) === kind ? tabOn || tabOff : tabOff; b.setTitle(PIECE[k][4]); } }
      const list = pieces().filter((p) => p.kind === kind);
      fillList(n.node_tablecontent, n.node_cardcontent, [...list, { tipFor: kind }], { onMerge: merge }, pieceCell);
      note(list.length ? '' : 'No ' + PIECE[kind][4].toLowerCase() + ' fragments yet');
    };
    let noteLabel = null;
    function note(text) { // an empty list says so (ours: the phone shows an empty page)
      if (noteLabel) { noteLabel.removeSelf(); noteLabel = null; }
      if (!text) return;
      const box = n.node_tablecontent; noteLabel = new HB.Label(text, 'Arial-BoldMT', 26, [0, 0], 1, 1); noteLabel.color = [120, 80, 30]; noteLabel.x = box.w / 2; noteLabel.y = box.h - 80; box.add(noteLabel);
    }
    let busy = false;
    async function merge(p, t) {
      if (busy) return; busy = true;
      ui.loading(true);
      let r;
      try { r = await HB.api('rl_w_comm', { Cmd: 10, ChipBagID: p.id }); } catch (e) { r = null; }
      if (!r || r.code) { ui.loading(false); busy = false; return ui.tip(r ? ui.errorText(r) : 'Cannot reach the server'); }
      HB.game.lastMergeReply = r; // for checks
      await HB.game.refresh();
      ui.loading(false); busy = false;
      const got = HB.awards ? HB.awards(r) : [];
      showPieces(pieceKind);
      if (got.length && HB.showCards) await HB.showCards(got, 'You got');
      else ui.tip('Merged: ' + (t.pet ? clean(t.pet[2]) : HB.info(t.type, t.id).name), 1.8);
    }
    o.onButton = (sel) => {
      const tab = TABS.find((x) => x[1] === sel);
      if (tab) return show(tab[2]);
      const pk = Object.keys(PIECE).find((k) => PIECE[k][2] === sel);
      if (pk) return showPieces(Number(pk));
      if (sel === 'BtnBackPack') return show(cardType);
      if (sel === 'BtnPieceBackPack') return showPieces(pieceKind || 1);
      ui.tip('Coming soon: ' + (sel === 'BtnPurchase' ? 'Top-up' : sel.replace(/^Btn/, '')), 1.2);
    };
    if (pieceKind) showPieces(pieceKind); else show(cardType);
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
