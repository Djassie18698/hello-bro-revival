// Three screens of the Home middle row that make a shinobi card stronger (C++ on the phone):
//   Reincarnate -> CReincarnationView (sub_ui/ReincarnationView.ccbi): one more copy of the same card, or reincarnation pills
//                  (item 11; how many: newlifeconfig [2] the rebirth number, [3] the card's stars, [4] pills). rl_w_newlife
//                  ReadyCard EatCard (0 = pay with pills) NewLifeCount. What a rebirth gives: newlifeprop ([1] stars, [2] rebirth,
//                  [3] base and growth, [5] restrain, [6] ninjutsu chance).
//   Train       -> CPotentialView (sub_ui/PotentialView.ccbi): rl_x_develop Cmd 1 BagId (limits and what the card has, the four
//                  price rows), Cmd 2 CostId (a roll: <add_num att def ckr>), Cmd 3 (keep the roll).
//   Growth      -> CStrengthView (sub_ui/StrengthView.ccbi), the sage steps: 1-4 sage stones (item 7 or 8) give the chance in
//                  ninjastrength ([2] step, [3]-[6] chance with 1-4 stones, [9] silver; rows 1-15 Sage Stone I, 16-30 Sage Stone III),
//                  extra stones add 0.1 / 0.2 % each up to +10 %. rl_w_star ReadyCard StarStoneID StarStoneNum StarStoneExtID
//                  StarStoneExtNum -> levelSuccess, levelDrop, currentLevel. Auto growth is not built.
// The items you hold come from HB.game.items (rl_r_shoplist Cmd 1601).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const STARS = ['sprite_star01', 'sprite_star02', 'sprite_star03', 'sprite_star04', 'sprite_star05'];
  const items = (id) => (HB.game.items && HB.game.items.get(id)) || 0;
  const set = (n, k, t) => { if (n[k]) n[k].setText(String(t)); };
  const hide = (n, ...names) => names.forEach((k) => { if (n[k]) n[k].visible = false; });

  async function send(cgi, params) {
    const ui = HB.ui;
    ui.loading(true);
    let r;
    try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
    ui.loading(false);
    if (r.code) { ui.tip(ui.errorText(r), 2.2); return null; }
    return r;
  }
  // the middle-sized card of these screens (sprite_ninjaicon with layer_icon, level, stars)
  function showCard(n, card) {
    hide(n, 'node_shadow_back', 'node_shadow_front', 'sprite_ninjaexp', 'node_inlay_frame', 'sprite_dragon_icon');
    if (n.layer_icon) n.layer_icon.removeAll();
    if (!card) { set(n, 'label_ninja_level', ''); STARS.forEach((s) => { if (n[s]) n[s].visible = false; }); return; }
    const inf = HB.info(1, card.id);
    const fr = HB.qualityFrame('middle', inf.quality); if (fr && n.sprite_ninjaicon) n.sprite_ninjaicon.setFrame(fr);
    const art = HB.iconFrame(1, inf.icon, true);
    if (art && n.layer_icon) { n.layer_icon.clip = true; const sp = new HB.Sprite(art); const k = Math.max(n.layer_icon.w / art.sw, n.layer_icon.h / art.sh); sp.sx = sp.sy = k; sp.x = n.layer_icon.w / 2; sp.y = n.layer_icon.h / 2; n.layer_icon.add(sp); }
    set(n, 'label_ninja_level', card.level);
    HB.showStars(n, STARS, Math.min(5, inf.quality));
  }
  const pick = (exclude) => HB.pickCard({ types: [1], exclude });
  const ready = async (...layouts) => { await Promise.all([HB.data.tables(), HB.game.loadItems ? HB.game.loadItems() : null, ...layouts.map((l) => HB.loadCCB(l))]); };

  // ---------------------------------------------------------------- Reincarnate
  HB.screens.rebirth = async function rebirth(seq) {
    const ui = HB.ui;
    ui.loading(true);
    await ready('sub_ui/ReincarnationView');
    const [conf, prop] = await Promise.all([ui.table('newlifeconfig'), ui.table('newlifeprop')]);
    ui.loading(false);
    const card = seq ? HB.data.card(seq) : null;
    const o = {};
    HB.game.showSub('sub_ui/ReincarnationView', o);
    const n = o.n;
    const T = { 0: 'Cost:', 1: 'Cost:', 2: 'Materials', 3: '', 4: 'Reincarnation Pill', 5: 'or the same shinobi card', 6: 'Rebirth: stronger base numbers and restrain', 7: 'Rebirth', 8: '', 9: 'Shinobi rebirth', 10: '1. Base numbers +', 11: '2. Restrain from', 12: 'to', 13: '3. Ninjutsu chance +' };
    for (const k in T) set(n, 'label_ReincarnationView' + k, T[k]);
    if (n.btn_start) n.btn_start.setTitle('Reincarnate');
    showCard(n, card);
    hide(n, 'node_inlay_frame_small', 'node_succeed_anim');
    const inf = card && HB.info(1, card.id), now = card ? card.newlife || 0 : 0, next = now + 1;
    const need = card ? (conf.rows.find((r) => r[2] === next && r[3] === inf.quality) || [])[4] || 0 : 0;
    const copies = card ? HB.data.ofType(1).filter((c) => c.id === card.id && c.seq !== card.seq && !HB.data.inUse(c.seq)) : [];
    let pay = copies.length ? 'card' : 'pill';
    const mark = () => { if (n.sprite_card_selected) n.sprite_card_selected.visible = !!card && pay === 'card'; if (n.sprite_ball_selected) n.sprite_ball_selected.visible = !!card && pay === 'pill'; };
    set(n, 'label_card_cost', card ? 1 : 0); set(n, 'label_meterial_count', copies.length);
    set(n, 'label_ball_cost', need); set(n, 'label_ball_count', items(11));
    if (n.sprite_icon && card) { const ic = HB.cardIcon(1, card.id); if (ic.pic) ic.pic.z = 1; ic.sx = ic.sy = Math.min(n.sprite_icon.w / (ic.w || 1), n.sprite_icon.h / (ic.h || 1)); ic.x = n.sprite_icon.w / 2; ic.y = n.sprite_icon.h / 2; n.sprite_icon.add(ic); }
    // what this rebirth gives
    if (n.label_ninja_title) n.label_ninja_title.visible = !!card; if (n.label_noninja_title) n.label_noninja_title.visible = !card;
    const row = (k) => (card ? prop.rows.find((r) => r[2] === inf.quality && Math.round(r[3]) === k) : null) || [];
    const pct = (v) => Math.round((v || 0) * 100) + '%';
    set(n, 'label_rlevel', next); set(n, 'label_rlevel_basic_upgrade', pct(row(next)[4]));
    set(n, 'label_restrain_upgrade_from', pct(row(now)[6])); set(n, 'label_restrain_upgrade_to', pct(row(next)[6])); set(n, 'label_skill_trigger_upgrade', pct(row(next)[7]));
    mark();
    o.onButton = async (sel) => {
      if (sel === 'clickBack') return HB.game.goHome();
      if (sel === 'clickSelectCard') { const c = await pick(); return rebirth(c ? c.seq : seq); }
      if (!card) return ui.tip('Choose a shinobi first', 1.4);
      if (sel === 'clickSetSelectedCard') { if (!copies.length) return ui.tip('You have no other ' + inf.name + ' card', 1.8); pay = 'card'; return mark(); }
      if (sel === 'clickSetSelectedBall') { pay = 'pill'; return mark(); }
      if (sel !== 'clickStart') return;
      if (pay === 'pill' && items(11) < need) return ui.tip('Not enough Reincarnation Pills (' + items(11) + ' / ' + need + ')', 2);
      const eat = pay === 'card' ? copies.slice().sort((a, b) => a.level - b.level)[0] : null;
      if (pay === 'card' && !eat) return ui.tip('You have no other ' + inf.name + ' card', 1.8);
      if (!(await HB.confirm('Reincarnate ' + inf.name + ' (rebirth ' + next + ')? It goes back to level 1' + (eat ? ' and uses up the other ' + inf.name + ' card (level ' + eat.level + ').' : ' and uses ' + need + ' Reincarnation Pills.'), { ok: 'Reincarnate' }))) return;
      const r = await send('rl_w_newlife', { Cmd: 1, ReadyCard: card.seq, EatCard: eat ? eat.seq : 0, NewLifeCount: next });
      if (!r) return;
      await HB.game.refresh();
      ui.tip(inf.name + ' is reborn: rebirth ' + next, 2.2);
      rebirth(card.seq);
    };
  };

  // ---------------------------------------------------------------- Train (potential)
  HB.screens.potential = async function potential(seq, rolled) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    await ready('sub_ui/PotentialView');
    ui.loading(false);
    const card = seq ? HB.data.card(seq) : null;
    let info = null;
    if (card) { info = await send('rl_x_develop', { Cmd: 1, BagId: card.seq }); if (!info) return; }
    const o = {};
    HB.game.showSub('sub_ui/PotentialView', o);
    const n = o.n;
    showCard(n, card);
    hide(n, 'node_anim_att', 'node_anim_def', 'node_anim_ckr', 'node_anim_att_0', 'node_anim_def_0', 'node_anim_ckr_0');
    set(n, 'label_PotentialView0', 'With pills'); set(n, 'label_PotentialView2', 'With gold'); set(n, 'label_PotentialView4', 'Pills:');
    const a = (tag, k) => (info ? Number(x.a(x.first(info, tag), k, 0)) : 0);
    const stat = [['attack', 'att'], ['defense', 'def'], ['chakra', 'ckr']];
    for (const [tag, k] of stat) {
      set(n, 'label_' + tag, a(tag, 'add_' + k) + '/' + a(tag, 'limit_' + k));
      const d = rolled ? rolled[k] : null;
      if (n['label_' + tag + '_add']) { n['label_' + tag + '_add'].visible = d !== null; if (d !== null) n['label_' + tag + '_add'].setText((d >= 0 ? '+' : '') + d); }
      if (n['sprite_' + tag + '_status']) n['sprite_' + tag + '_status'].visible = d !== null && d !== 0;
      if (d !== null && d < 0 && n['sprite_' + tag + '_status']) n['sprite_' + tag + '_status'].flipY = true;
    }
    const costs = info ? x.all(info, 'cost').map((c) => ({ id: Number(x.a(c, 'cost_id')), name: x.a(c, 'name'), pills: Number(x.a(c, 'need_miyao')), gold: Number(x.a(c, 'need_golden')) })) : [];
    let gold = HB.game.potGold || false, ten = HB.game.potTen || false;
    const cost = () => costs[(ten ? 2 : 0) + (gold ? 1 : 0)] || { id: 1, pills: 0, gold: 0, name: '' };
    const draw = () => {
      const c1 = costs[ten ? 2 : 0] || {}, c2 = costs[ten ? 3 : 1] || {};
      set(n, 'label_cost_normal', c1.pills || 0); set(n, 'label_cost_gold', c2.pills || 0); set(n, 'label_gold_cost', c2.gold || 0);
      set(n, 'label_medicine_count', items(28)); set(n, 'label_mode', ten ? 'Train 10 times' : 'Train once');
      if (n.sprite_normal_selected) n.sprite_normal_selected.visible = !gold; if (n.sprite_gold_selected) n.sprite_gold_selected.visible = gold;
    };
    draw();
    if (n.btn_save) { n.btn_save.setTitle('Keep'); n.btn_save.visible = !!rolled; }
    o.onButton = async (sel) => {
      if (sel === 'clickBack') return HB.game.goHome();
      if (sel === 'clickSelectCard') { const c = await pick(); return potential(c ? c.seq : seq); }
      if (sel === 'btnNormal') { gold = HB.game.potGold = false; return draw(); }
      if (sel === 'btnGold') { gold = HB.game.potGold = true; return draw(); }
      if (sel === 'btnMode') { ten = HB.game.potTen = !ten; return draw(); }
      if (!card) return ui.tip('Choose a shinobi first', 1.4);
      if (sel === 'btnPotential') {
        const c = cost();
        if (items(28) < c.pills) return ui.tip('Not enough Super Ninja Pills (' + items(28) + ' / ' + c.pills + ')', 2);
        const r = await send('rl_x_develop', { Cmd: 2, BagId: card.seq, CostId: c.id });
        if (!r) return;
        const d = x.first(r, 'add_num');
        if (HB.game.loadItems) await HB.game.loadItems();
        await HB.game.refresh();
        return potential(card.seq, { att: Number(x.a(d, 'att', 0)), def: Number(x.a(d, 'def', 0)), ckr: Number(x.a(d, 'ckr', 0)) });
      }
      if (sel === 'btnSave') {
        if (!rolled) return;
        if (!(await send('rl_x_develop', { Cmd: 3, BagId: card.seq }))) return;
        await HB.game.refresh();
        ui.tip('Kept', 1.2);
        return potential(card.seq);
      }
    };
  };

  // ---------------------------------------------------------------- Growth (sage steps)
  const STONES = [7, 8], EXTRA = { 7: 0.1, 8: 0.2 }, EXTRA_MAX = 10, MAX = 15;
  HB.screens.growth = async function growth(seq, st = {}) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    await ready('sub_ui/StrengthView');
    const table = await ui.table('ninjastrength');
    ui.loading(false);
    const card = seq ? HB.data.card(seq) : null;
    const o = {};
    HB.game.showSub('sub_ui/StrengthView', o);
    const n = o.n;
    hide(n, 'node_auto_choose_container', 'node_auto_desc_container', 'button_strength3', 'sprite_cancel_name2', 'sprite_auto_icon', 'result_anim_node', 'bridge_anim_node', 'sprite_stone_fire_wheel', 'sprite_card_fire_wheel', 'node_desc_container');
    const all = o.all || {};
    (all.label_StrengthView0 || []).forEach((l, i) => l.setText(i === 0 ? 'Sage' : 'Extra chance'));
    set(n, 'label_StrengthView1', 'step'); set(n, 'sprite_desc_silver_cost', 'Cost:');
    set(n, 'label_StrengthView7', '1. Sage stones raise a shinobi card step by step: every step adds to its numbers.');
    set(n, 'label_StrengthView8', '2. Better stones and more of them give a higher chance.');
    set(n, 'label_StrengthView9', '3. A failed try can cost a step, but never below steps 3, 6, 9 and 12 once reached.');
    let stone = st.stone || (items(7) ? 7 : items(8) ? 8 : 7), count = st.count || 1, extra = st.extra || 0, extraStone = st.extraStone || stone;
    const lv = card ? card.starlevel || 0 : 0;
    const row = () => table.rows.find((r) => r[2] === lv && (stone === 8 ? r[0] > 15 : r[0] <= 15)) || [];
    const maxExtra = () => Math.max(0, Math.min(items(extraStone) - (extraStone === stone ? count : 0), Math.ceil(Math.min(EXTRA_MAX, 100 - (row()[2 + count] || 0)) / EXTRA[extraStone] - 1e-9)));
    const icon = (holder, id) => { if (!holder) return; const f = HB.iconFrame(0, HB.info(0, id).icon); if (f) { holder.setFrame(f); } };
    if (n.sprite_icon) { n.sprite_icon.removeAll(); if (card) { const ic = HB.cardIcon(1, card.id); if (ic.pic) ic.pic.z = 1; ic.sx = ic.sy = Math.min(1.1, 110 / (ic.w || 110)); ic.x = n.sprite_icon.w / 2; ic.y = n.sprite_icon.h / 2; n.sprite_icon.add(ic); } }
    const draw = () => {
      extra = Math.max(0, Math.min(extra, maxExtra()));
      icon(n.sprite_stone_icon, stone); icon(n.sprite_stone_icon_select, extraStone);
      set(n, 'label_stone_count', items(stone)); set(n, 'label_stone_count_select', extra);
      set(n, 'label_card_level', lv);
      const base = card ? row()[2 + count] || 0 : 0, add = Math.min(EXTRA_MAX, Math.round(extra * EXTRA[extraStone] * 10) / 10);
      set(n, 'label_strength_ratio', base + '%'); set(n, 'label_strength_ratio_extra', add ? '+' + add + '%' : ''); set(n, 'label_percent', add + '%');
      set(n, 'label_cost_silver', card ? row()[9] || 0 : 0);
      for (let i = 1; i <= 4; i++) { const b = n['btn_num' + i]; if (b) b.opacity = i <= count ? 255 : 120; }
    };
    draw();
    const again = () => growth(seq, { stone, count, extra, extraStone });
    o.onButton = async (sel, btn) => {
      if (sel === 'clickBack') return HB.game.goHome();
      if (sel === 'clickHelp') { if (n.node_desc_container) n.node_desc_container.visible = !n.node_desc_container.visible; return; }
      if (sel === 'clickCardSelect') { const c = await pick(); return growth(c ? c.seq : seq, { stone, count }); }
      if (sel === 'clickSelectStone') { stone = STONES[(STONES.indexOf(stone) + 1) % STONES.length]; return draw(); }
      if (sel === 'clickSelectStoneExtra') { extraStone = STONES[(STONES.indexOf(extraStone) + 1) % STONES.length]; extra = 0; return draw(); }
      if (sel === 'clickNumber') { for (let i = 1; i <= 4; i++) if (btn === n['btn_num' + i]) count = i; return draw(); }
      if (sel === 'clickSelectMin') { extra = 0; return draw(); }
      if (sel === 'clickSelectMax') { extra = maxExtra(); return draw(); }
      if (sel === 'clickSelectSub') { extra -= 1; return draw(); }
      if (sel === 'clickSelectAdd') { extra += 1; return draw(); }
      if (sel === 'clickAuto') return ui.tip('Coming soon: automatic growth', 1.4);
      if (sel !== 'clickStrength') return;
      if (!card) return ui.tip('Choose a shinobi first', 1.4);
      if (lv >= MAX) return ui.tip('This shinobi is at the highest step', 1.8);
      if (items(stone) < count) return ui.tip('Not enough ' + HB.info(0, stone).name + ' (' + items(stone) + ' / ' + count + ')', 2);
      const r = await send('rl_w_star', { Cmd: 1, ReadyCard: card.seq, StarStoneID: stone, StarStoneNum: count, StarStoneExtID: extra ? extraStone : 0, StarStoneExtNum: extra });
      if (!r) return;
      const won = Number(r.getAttribute('levelSuccess')) === 1, drop = Number(r.getAttribute('levelDrop')) || 0, now = Number(r.getAttribute('currentLevel'));
      if (HB.game.loadItems) await HB.game.loadItems();
      await HB.game.refresh();
      ui.tip(won ? 'Success! Sage step ' + now : drop ? 'Failed: back to step ' + now : 'Failed: still step ' + now, 2.2);
      again();
    };
  };
})();
