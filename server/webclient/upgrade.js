// Level up a card by feeding it other cards (the Backpack's Upgrade button): CCardUpgradeView (upgrade/CardUpgradeView.ccbi),
// the card on top (upgrade/UpgradeNinja.ccbi) and a grid of material cards (upgrade/MaterialNinjaView.ccbi, the phone's own tile) you tick.
// Request: rl_w_strengthen SRCBagID=<card> EATCardsBagIDList=<a|b|c>. The numbers shown are the game's own upgrade tables, the same
// ones the server uses (game.js strengthen): every eaten card gives [3] exp and costs [4] silver from its own kind's table at its
// level; the growing card needs [2] exp per level. A card can reach your level x 2 + 10 (never past its table's last level).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const TABLE = { 1: 'ninjaupgrade', 2: 'equipupgrade', 3: 'equipupgrade', 4: 'equipupgrade', 5: 'markupgrade', 6: 'ninjutsuupgrade' };
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };

  HB.screens.upgrade = async function upgrade(seq) {
    const ui = HB.ui, D = HB.data;
    const card = D.card(seq);
    if (!card) return HB.screens.backpack();
    ui.loading(true);
    const [tab] = await Promise.all([ui.table(TABLE[card.type]), HB.data.tables(), ...['upgrade/CardUpgradeView', 'upgrade/UpgradeNinja', 'upgrade/MaterialNinjaView'].map((f) => HB.loadCCB(f))]);
    ui.loading(false);
    const rowAt = (lv) => tab.rows.find((r) => r[1] === Math.max(1, lv)) || [];
    const top = Math.min(Number((HB.game.user || {}).level || 1) * 2 + 10, tab.rows.length);
    const o = {};
    HB.game.showSub('upgrade/CardUpgradeView', o, 'btn_mainpackage');
    const n = o.n, inf = HB.info(card.type, card.id);
    if (n.label_CardUpgradeView0) n.label_CardUpgradeView0.setText('Material cards');
    if (n.label_CardUpgradeView1) { n.label_CardUpgradeView1.dims = [0, 0]; n.label_CardUpgradeView1.setText('All 1-2 star cards'); }
    if (n.sprite_selectall) n.sprite_selectall.visible = false;
    if (n.node_anim_tip) n.node_anim_tip.visible = false;

    // the card that grows
    const co = {};
    const top1 = HB.build('upgrade/UpgradeNinja', co, [n.node_cardinfo.w, n.node_cardinfo.h]);
    top1.ignoreAnchor = true; n.node_cardinfo.add(top1);
    const m = co.n;
    m.label_name.setText(inf.name); m.label_level.setText(String(card.level));
    if (m.label_UpgradeNinja0) m.label_UpgradeNinja0.setText('Card to upgrade');
    // long English names: the layout leaves room for four Chinese signs. The "Lv:" picture and its number move right, up to the
    // stars, and the name is set smaller; what is still too long is scaled into the room that is left
    { const lv = m.label_level, tag = lv.parent.children.filter((s) => s instanceof HB.Sprite && !s.name && Math.abs(s.y - lv.y) < 25 && s.x < lv.x && lv.x - s.x < 80).pop();
      if (tag) { tag.x += 29; lv.x += 29; }
      m.label_name.size = 20; m.label_name.setText(inf.name);
      const room = tag ? 133 : 104; if (m.label_name.w > room) m.label_name.sx = m.label_name.sy = room / m.label_name.w; }
    if (m.label_UpgradeNinja1) { m.label_UpgradeNinja1.setText('Gives'); m.label_UpgradeNinja1.sx = m.label_UpgradeNinja1.sy = 0.7; m.label_UpgradeNinja1.x -= 10; }
    if (m.label_UpgradeNinja2) { m.label_UpgradeNinja2.setText('Needs'); m.label_UpgradeNinja2.sx = m.label_UpgradeNinja2.sy = 0.7; m.label_UpgradeNinja2.x -= 16; }
    for (const k of ['node_inlay_frame', 'node_shadow_back', 'node_shadow_front']) if (m[k]) m[k].visible = false;
    const fr = HB.qualityFrame(card.type === 1 ? 'ninjaSmall' : 'small', inf.quality); if (fr) m.sprite_ninjaicon.setFrame(fr);
    const pic = HB.iconFrame(card.type, inf.icon);
    if (pic && m.node_icon) { const sp = new HB.Sprite(pic); const k = Math.min(m.node_icon.w / (pic.sw || 1), m.node_icon.h / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = m.node_icon.w / 2; sp.y = m.node_icon.h / 2; m.node_icon.add(sp); }
    const star = HB.frameByName('com_normal_star');
    for (let i = 1; i <= 5; i++) if (m['sprite_star' + i] && i <= Math.min(5, inf.quality) && star) m['sprite_star' + i].setFrame(star);
    const barFull = m.sprite_expbar ? m.sprite_expbar.w : 0;
    // a card at its top level: "Max" on the full bar, like the phone
    let maxTag = null;
    if (m.sprite_expbar) { maxTag = new HB.Label('Max', 'Helvetica', 26, [0, 0], 1, 1); maxTag.color = [255, 255, 255]; maxTag.x = m.sprite_expbar.x - m.sprite_expbar.ax * barFull + barFull / 2; maxTag.y = m.sprite_expbar.y + (0.5 - m.sprite_expbar.ay) * m.sprite_expbar.h; maxTag.z = m.sprite_expbar.z + 1; maxTag.visible = false; m.sprite_expbar.parent.add(maxTag); }

    // the material cards: the same kind, not in a team, not the card itself
    const mats = HB.bag.sorted(D.ofType(card.type).filter((c) => c.seq !== card.seq && !D.inUse(c.seq))).reverse();
    const chosen = new Set(), marks = new Map();
    const worth = (c) => { const r = rowAt(c.level); return [r[3] || 0, r[4] || 0]; };
    const after = () => { // level and exp once the chosen cards are eaten
      let exp = 0, cost = 0; for (const s of chosen) { const [e, c] = worth(D.card(s)); exp += e; cost += c; }
      let level = card.level, cur = card.exp + exp;
      for (;;) { const need = rowAt(level)[2]; if (!need || level >= top || cur < need) break; cur -= need; level++; }
      return { exp, cost, level, cur };
    };
    const redraw = () => {
      const a = after(), need = rowAt(a.level)[2] || 0;
      m.label_expval.setText(String(a.exp)); m.label_needsilver.setText(String(a.cost));
      m.label_level.setText(String(a.level)); m.label_level.color = a.level > card.level ? [120, 255, 90] : [255, 255, 255];
      if (maxTag) maxTag.visible = a.level >= top;
      if (m.sprite_expbar && barFull) m.sprite_expbar.w = Math.max(1, barFull * (a.level >= top || !need ? 1 : Math.min(1, a.cur / need)));
      for (const [s, mark] of marks) mark.visible = chosen.has(s);
    };
    const box = n.node_tablecontent, size = n.node_cardcontent, per = Math.max(1, Math.floor(box.w / size.w));
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const rows = Math.max(1, Math.ceil(mats.length / per));
    const col = new HB.Node(); col.w = box.w; col.h = rows * size.h;
    const place = (c, i) => {
      // the phone's own tile (upgrade/MaterialNinjaView): the picture in its star frame with "Lv:N" on it, the name under it, five
      // stars down the right side (as many gold as the card has), a tick when chosen
      const mo = {}, ci = HB.info(c.type, c.id);
      const cell = HB.build('upgrade/MaterialNinjaView', mo, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.w = size.w; cell.h = size.h;
      cell.x = (box.w - per * size.w) / 2 + (i % per) * size.w; cell.y = col.h - (Math.floor(i / per) + 1) * size.h;
      const t = mo.n, p = HB.iconFrame(c.type, ci.icon);
      const qf = HB.qualityFrame('small', ci.quality); if (qf && t.sprite_icon) t.sprite_icon.setFrame(qf); // the small square box of its stars (small_box_skill_0N)
      if (p && t.sprite_icon) { const sp = new HB.Sprite(p); const k = Math.min((t.sprite_icon.w - 10) / (p.sw || 1), (t.sprite_icon.h - 10) / (p.sh || 1)); sp.sx = sp.sy = k; sp.x = t.sprite_icon.w / 2; sp.y = t.sprite_icon.h / 2; t.sprite_icon.add(sp); }
      { const dark = HB.frameByName('com_nromal_star_bk'); for (let q = 1; q <= 5; q++) { const st = t['sprite_star' + q]; if (st && dark && q > Math.min(5, ci.quality)) { const w0 = st.w; st.setFrame(dark); st.sx = st.sy = w0 / (st.w || w0); } } } // the stars it lacks are dark
      if (t.label_level) t.label_level.setText('LV:' + c.level);
      if (t.label_grade) t.label_grade.setText(''); // the phone shows no "+N" on these tiles
      if (t.label_name) { // the name's first words that fit the little box, like the phone ("Golden", "Akimichi")
        t.label_name.dims = [0, 0]; const words = String(ci.name || '').split(' '); let txt = words[0] || '';
        t.label_name.setText(txt);
        for (let wi = 1; wi < words.length; wi++) { t.label_name.setText(txt + ' ' + words[wi]); if (t.label_name.w > 96) { t.label_name.setText(txt); break; } txt += ' ' + words[wi]; }
        if (t.label_name.w > 96) t.label_name.sx = t.label_name.sy = 96 / t.label_name.w;
      }
      const mark = t.sprite_selectflag || new HB.Node(); mark.visible = chosen.has(c.seq);
      marks.set(c.seq, mark);
      cell.onTouch = (ev, tx, ty) => { if (ev === 'down') cell._d = [tx, ty]; if (ev === 'up' && cell._d && Math.hypot(tx - cell._d[0], ty - cell._d[1]) < 14) { if (chosen.has(c.seq)) chosen.delete(c.seq); else chosen.add(c.seq); redraw(); } };
      col.add(cell);
      return cell;
    };
    if (mats.length <= 60) mats.forEach(place);
    else {
      // many material cards (ours): only the rows in view exist, like the Backpack's long lists (bag.js fillList)
      const live = new Map(), draw = col.visit.bind(col);
      col.visit = (...a) => {
        const r0 = Math.max(0, Math.floor((col.h + col.y - scroll.h) / size.h) - 2), r1 = Math.min(rows - 1, Math.floor((col.h + col.y) / size.h) + 2);
        for (const [i, cell] of live) { const r = Math.floor(i / per); if (r < r0 - 2 || r > r1 + 2) { col.remove(cell); live.delete(i); marks.delete(mats[i].seq); } }
        for (let i = r0 * per; i < Math.min(mats.length, (r1 + 1) * per); i++) if (!live.has(i)) live.set(i, place(mats[i], i));
        return draw(...a);
      };
    }
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    if (!mats.length && n.node_anim_tip) n.node_anim_tip.visible = true;
    redraw();

    o.onButton = async (sel) => {
      if (sel === 'BtnBack') return HB.screens.backpack(card.type);
      if (sel === 'BtnBuyItem') return HB.screens.shop ? HB.screens.shop(1) : ui.tip('Coming soon: Shop', 1.2);
      if (sel === 'BtnSelectALL') { const low = mats.filter((c) => HB.info(c.type, c.id).quality <= 2); const all = low.every((c) => chosen.has(c.seq)); low.forEach((c) => (all ? chosen.delete(c.seq) : chosen.add(c.seq))); return redraw(); }
      if (sel === 'BtnUpgrade') {
        if (!chosen.size) return ui.tip('Choose material cards first', 1.5);
        if (card.level >= top) return ui.tip('This card is at its top level for now', 1.8);
        const a = after();
        if (Number((HB.game.user || {}).coin || 0) < a.cost) return ui.tip('Not enough silver', 1.5);
        ui.loading(true);
        let r;
        try { r = await HB.api('rl_w_strengthen', { Cmd: 2200, SRCBagID: card.seq, EATCardsBagIDList: [...chosen].join('|') }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
        if (r.code) { ui.loading(false); return ui.tip(ui.errorText(r)); }
        await HB.game.refresh();
        ui.loading(false);
        const now = D.card(card.seq);
        ui.tip(inf.name + (now && now.level > card.level ? ': level ' + card.level + ' > ' + now.level : ': +' + a.exp + ' exp'), 1.8);
        return upgrade(card.seq);
      }
    };
  };
})();
