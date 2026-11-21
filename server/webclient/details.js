// Card details: the window you get by tapping a card's picture (Backpack rows for now).
//   shinobi  -> sub_ui/NinjaDetailView.ccbi   (big picture, level bar, attack / defence / chakra, story, stars, its chains)
//   gear     -> dlg_ui/EquipDetailView.ccbi   (CEquipDetailView)
//   ninjutsu -> dlg_ui/NinjasuDetailView.ccbi (a scrolling text; ours: picture + name + what it does)
//   seal     -> sub_ui/MarkDetailView.ccbi
// No request: everything comes from the cards the game already holds (HB.data) and the game's tables. Chains = the ninjamatch rows
// of that shinobi ([3] shinobi, [4] what the chain gives). Numbers are the card's own (table value + growth per level, HB.baseStats):
// growth, reincarnation and potential are not counted yet, the Team screen shows the server's true totals.
// Ours for now: v28's phone shows the shinobi in dlg_ui/NinjaDetailView (a scrolling page built in C++); this is the game's own
// earlier layout of the same window. Growth / Reincarnate / Train buttons come with those screens.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const clean = (s) => String(s ?? '').replace(/\0+$/, '').trim();
  const range = (a) => (a ? Math.round(a[0]) + '-' + Math.round(a[1]) : '0');
  function fit(holder, frame, cover) {
    if (!holder || !frame) return null;
    const sp = new HB.Sprite(frame); const k = (cover ? Math.max : Math.min)(holder.w / (frame.sw || 1), holder.h / (frame.sh || 1));
    sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp);
    return sp;
  }
  const hide = (n, ...names) => names.forEach((k) => { if (n[k]) n[k].visible = false; });
  const stars = (n, q) => { for (let i = 1; i <= 5; i++) if (n['sprite_star' + i]) n['sprite_star' + i].visible = i <= Math.min(5, q); };
  // a button whose word is a picture of Chinese text: our own word on top instead
  function word(btn, label, text) {
    if (label) label.visible = false;
    if (!btn) return;
    const l = new HB.Label(text, 'Arial-BoldMT', 26, [0, 0], 1, 1); l.color = [255, 255, 255]; l.stroke = ['#2a1505', 3]; l.x = btn.w / 2; l.y = btn.h / 2; l.z = 5; btn.add(l);
  }

  // a block of wrapped text for a window's page
  function text(str, width, size, color, centre) {
    const l = new HB.Label(str, 'Arial-BoldMT', size, [width, 0], centre ? 1 : 0, 0); l.color = color; l.ax = 0; l.ay = 0;
    const holder = new HB.Node(); holder.w = width; holder.h = (l.h || size * 1.3) + 14; l.x = 0; l.y = 7; holder.add(l);
    return holder;
  }
  // stacks the parts top to bottom, centred, inside a window's scroll box
  function page(box, parts) {
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(box.h, parts.reduce((a, p) => a + p.h + 10, 20));
    let y = col.h - 10;
    for (const p of parts) { y -= p.h; p.ignoreAnchor = true; p.x = (box.w - p.w) / 2; p.y = y; y -= 10; col.add(p); }
    box.setContent(col); col.y = box.h - col.h; // in place of the page the layout came with
  }

  // HB.screens.details(card, { onChange }) ; card = one of HB.data's cards
  HB.screens.details = async function details(card, opt = {}) {
    await HB.data.tables();
    const inf = HB.info(card.type, card.id), st = HB.baseStats(card);
    const upgrade = (w) => { w.close(); if (card.seq) HB.screens.upgrade(card.seq); }; // seq 0 = a card you are only shown (a reward, a shop item)
    const lvl = Math.max(1, card.level);

    if (card.type === 1) {
      const match = await HB.ui.table('ninjamatch');
      const go = { BtnUpgrade1: 'growth', BtnUpgradeRe: 'rebirth', BtnUpgradePo: 'potential' };
      const w = { onButton: (sel) => { if (sel === 'BtnUpgrade') return upgrade(w); if (go[sel] && HB.screens[go[sel]]) { w.close(); return HB.screens[go[sel]](card.seq); } w.close(); if (sel === 'BtnChange' && opt.onChange) opt.onChange(card); } };
      await HB.dialog('dlg_ui/NinjaDetailView', w);
      const n = w.n, r = inf.row || [];
      n.label_name.setText(inf.name + (card.tupo > 0 ? '  +' + card.tupo : ''));
      n.ctrl_upgrade.setTitle('Level up'); n.ctrl_upgrade1.setTitle('Growth'); n.ctrl_upgradere.setTitle('Rebirth'); n.ctrl_upgradepo.setTitle('Train');
      n.ctrl_close2.visible = false;
      if (opt.onChange) n.ctrl_change.setTitle('Change'); else n.ctrl_change.visible = false;
      // the page inside the window is the game's own (dlg_ui/NinjaSubView): big card, story, chains, growth and rebirth steps
      const bf = HB.qualityFrame('big', inf.quality); if (bf) n.sprite_iconframe.setFrame(bf);
      const art = fit(n.layer_icon, HB.iconFrame(1, inf.icon, true)); if (art) art.z = -1;
      hide(n, 'node_shadow_back', 'node_shadow_front', 'node_inlay_frame', 'sprite_strength_level_frame', 'sprite_strength_level_icon', 'sprite_expval', 'sprite_dragon_icon',
        'label_current_attack_plus', 'label_current_defense_plus', 'label_current_chakra_plus');
      const camp = HB.frameByName({ 1: 'com_text_water_big_icon', 2: 'com_text_fire_big_icon', 3: 'com_text_wind_big_icon', 4: 'com_text_soild_big_icon', 5: 'com_text_thunder_big_icon' }[card.attri]);
      if (camp) n.sprite_ninjacamp.setFrame(camp); else n.sprite_ninjacamp.visible = false;
      n.label_barlevel.setText(String(lvl));
      n.label_attack.setText(range(st.atk)); n.label_defense.setText(range(st.def));
      n.label_charkra.setText(range([r[23] + r[29] * (lvl - 1), r[24] + r[30] * (lvl - 1)]));
      if (n.label_tupo_level) { n.label_tupo_level.visible = card.tupo > 0; if (card.tupo > 0) n.label_tupo_level.setText('+' + card.tupo); }
      if (n.label_NinjaSubView0) n.label_NinjaSubView0.setText('Details');
      n.label_desc.dims = [250, 0]; n.label_desc.setText(clean(inf.desc));
      stars(n, inf.quality);
      n.label_skill.setText('Chains'); n.label_skill1.setText('Growth'); n.label_skill2.setText('Rebirth');
      const chains = match.rows.filter((m) => m[3] === card.id).slice(0, 6);
      for (let i = 1; i <= 6; i++) { const c = chains[i - 1]; n['label_combatname' + i].setText(''); n['label_combat' + i].setText(c ? clean(c[4]) : ''); }
      // growth (sage steps 3 / 6 / 9 / 12) and the eight rebirths: the card's own bonus texts from its table row
      const bonus = r.slice(37, 44).map(clean);
      [['label_cuilian1', 'Step 3'], ['label_cuilian2', 'Step 6'], ['label_cuilian3', 'Step 9'], ['label_cuilian4', 'Step 12']].forEach(([k, t], i) => { if (n[k + '_0']) n[k + '_0'].setText(t); if (n[k]) n[k].setText(bonus[i] || '-'); });
      for (let i = 1; i <= 8; i++) { if (n['label_zhuansheng' + i + '_0']) n['label_zhuansheng' + i + '_0'].setText('Rebirth ' + i); if (n['label_zhuansheng' + i]) n['label_zhuansheng' + i].setText(''); }
      return;
    }
    if (card.type >= 2 && card.type <= 4) {
      const w = { onButton: (sel) => { if (sel === 'BtnUpgrade') return upgrade(w); w.close(); if (sel === 'BtnChange' && opt.onChange) opt.onChange(card); if (sel === 'BtnRemove' && opt.onRemove) opt.onRemove(card); } };
      await HB.dialog('dlg_ui/EquipDetailView', w);
      const n = w.n;
      n.label_name.setText(inf.name);
      if (n.label_EquipDetailView0) n.label_EquipDetailView0.setText('Details');
      fit(n.layer_icon, HB.iconFrame(card.type, inf.icon, true));
      n.label_barlevel.setText(String(lvl));
      hide(n, 'sprite_expval', 'label_grade', 'sprite_ninjacamp', 'btn_advance', 'ctrl_upgrade1', 'label_upgrade1');
      n.label_attackval.setText(range(st.atk)); n.label_defenseval.setText(range(st.def));
      const r = inf.row || [];
      n.label_charkraval.setText(range([(r[11] || 0) + (r[17] || 0) * (lvl - 1), (r[12] || 0) + (r[18] || 0) * (lvl - 1)]));
      if (n.label_markdesc) n.label_markdesc.setText('');
      if (n.layer_textdesc) n.label_desc.dims = [n.layer_textdesc.w || 250, 0];
      n.label_desc.setText(clean(inf.desc));
      stars(n, inf.quality);
      if (!opt.onChange) hide(n, 'ctrl_change', 'label_change');
      if (opt.onRemove) hide(n, 'label_close'); else hide(n, 'label_remove'); // away from the team the middle button reads Close
      return;
    }
    if (card.type === 6) {
      const w = { onButton: () => w.close() };
      await HB.dialog('dlg_ui/NinjasuDetailView', w);
      const n = w.n, box = n.layer_scollview;
      n.label_name.setText(inf.name);
      if (n.label_upgrade1) n.label_upgrade1.setText('Close');
      const icon = HB.cardIcon(6, card.id); if (icon.pic) icon.pic.z = 1; const holder = new HB.Node(); holder.w = box.w; holder.h = 190; icon.sx = icon.sy = 170 / (icon.w || 170); icon.x = box.w / 2; icon.y = 95; holder.add(icon);
      page(box, [holder, text('Level ' + lvl, box.w - 70, 28, [150, 60, 10], 1), text(clean(inf.desc), box.w - 70, 25, [70, 45, 10])]);
      return;
    }
    if (card.type === 5) {
      const w = { onButton: (sel) => { if (sel === 'BtnUpgrade') return upgrade(w); w.close(); if (sel === 'BtnChange' && opt.onChange) opt.onChange(card); if (sel === 'BtnRemove' && opt.onRemove) opt.onRemove(card); } };
      await HB.dialog('dlg_ui/MarkDetailView', w);
      const n = w.n;
      n.label_name.setText(inf.name + '  (Lv ' + lvl + ')');
      hide(n, 'ctrl_upgrade1', 'label_upgrade1');
      if (!opt.onChange) hide(n, 'ctrl_change', 'label_change');
      if (opt.onRemove) hide(n, 'label_close'); else hide(n, 'label_remove');
      // the page is the game's own (dlg_ui/MarkInfoDetails): the seal, what it does, and its five element rows
      fit(n.layer_icon, HB.frameByName(inf.icon));
      n.label_barlevel.setText(String(lvl)); hide(n, 'sprite_expval');
      if (n.label_MarkInfoDetails0) n.label_MarkInfoDetails0.setText('Details');
      n.label_desc.dims = [250, 0]; n.label_desc.setText(clean(inf.desc));
      if (n.label_markdesc) n.label_markdesc.setText('');
      stars(n, inf.quality);
      // markinfo [9]..: per element (water, fire, wind, earth, thunder) attack / defence / chakra / ? share at level 1, then the gain per level
      const r = inf.row || [], pct = (v) => (Math.round(v * 1000) / 10) + '%';
      const NAMES = ['Water', 'Fire', 'Wind', 'Earth', 'Thunder'], KIND = ['ATK', 'DEF', 'Chakra', ''];
      for (let e = 1; e <= 5; e++) {
        const base = r.slice(9 + (e - 1) * 4, 13 + (e - 1) * 4), grow = r.slice(29 + (e - 1) * 4, 33 + (e - 1) * 4);
        const lines = [NAMES[e - 1] + ' shinobi'];
        base.forEach((v, k) => { if (v > 0 && KIND[k]) lines.push(KIND[k] + ' +' + pct(v + (grow[k] || 0) * (lvl - 1))); });
        for (let k = 1; k <= 4; k++) if (n['label_text_' + e + '_' + k]) n['label_text_' + e + '_' + k].setText(lines[k - 1] || '');
      }
    }
  };
})();
