// Shop (the bottom bar's last button): CStoreItemsView (store/StoreItemsView.ccbi) with one CItemView per row:
//   Recruit   store/StoreNinjaView: the three scrolls (1 in 10000 = 300 gold, 1 in 1000 = 150 gold, 1 in 100 = a recruitment order),
//             free pull when its timer is at 0; Recruit opens the game's recruit window (dlg_ui/PrayDialogView: once or ten times)
//   Giftpack  store/StorePacksView (rl_w_shopbuy Cmd 1701 Packageid)
//   Tool      store/StoreGoodsView (rl_w_shopbuy Cmd 1700 Goodsid Count; Use = rl_w_propuse, later)
// The list comes from rl_r_shoplist Cmd 1600 (packages, goods with the amount owned, recruit timers). Pulls: rl_w_recruit Cmd 1900
// (once) / 1901 (ten) Type = scroll, Free = 1 for the free pull; the answer's <award> cards are shown in the "you got" window below.
// Also here, for every screen: HB.dialog (a layout as a window over the game), HB.confirm (CommonDialogView) and
// HB.showCards (what you got: one big card or a grid). The phone turns the card over with an animation: ours fades it in.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const two = (n) => String(n).padStart(2, '0');
  const clock = (s) => two(Math.floor(s / 3600)) + ':' + two(Math.floor(s / 60) % 60) + ':' + two(s % 60);

  // ---------------------------------------------------------------- windows every screen can use
  // a layout as a window: dimmed game behind it, taps stay inside; owner.close() takes it away
  const dialog = HB.dialog = async (file, owner = {}) => {
    await HB.loadCCB(file);
    const dim = HB.ui.modal(150); dim.z = 600;
    const root = HB.ui.screen(file, owner);
    dim.add(root); HB.scene.add(dim);
    root.sx = root.sy = 0.9; dim.fade = 0; HB.tween(root, { sx: 1, sy: 1 }, 0.14); HB.tween(dim, { fade: 1 }, 0.14);
    owner.close = () => dim.removeSelf();
    return owner;
  };
  // "Are you sure?": HB.confirm(text, { ok: 'Buy', cancel: 'Close', title }) -> true / false
  const confirm = HB.confirm = (text, opt = {}) => new Promise((done) => {
    const o = { onButton: (sel) => { o.close(); done(sel === 'leftHandler'); } };
    dialog('dlg_ui/CommonDialogView', o).then(() => {
      const n = o.n;
      n.labelDescription.setText(text);
      if (opt.title) n.labelTitle.setText(opt.title);
      n.leftButton.setTitle(opt.ok || 'OK'); n.rightButton.setTitle(opt.cancel || 'Close');
      if (n.layer_protect) n.layer_protect.visible = false;
    });
  });
  // what you got: cards = [{ type, id, num }]; one = its big picture, more = a grid of small ones. Tap anywhere to close.
  const showCards = HB.showCards = (cards, title = 'You got') => new Promise((done) => {
    if (!cards.length) return done();
    const ui = HB.ui, W = ui.W(), H = ui.H();
    const dim = ui.modal(235); dim.z = 650;
    const head = new HB.Label(title, 'Arial-BoldMT', 44, [0, 0], 1, 1); head.color = [255, 220, 110]; head.stroke = ['#3a1a05', 4]; head.x = W / 2; head.y = H - 150; dim.add(head);
    const hint = new HB.Label('Tap to continue', 'Arial-BoldMT', 24, [0, 0], 1, 1); hint.color = [255, 255, 255]; hint.x = W / 2; hint.y = 90; hint.opacity = 0; dim.add(hint);
    const named = (c, y, size) => { const inf = HB.info(c.type, c.id); const l = new HB.Label(inf.name + (c.num > 1 ? ' x' + c.num : ''), 'Arial-BoldMT', size, [0, 0], 1, 1); l.color = [255, 255, 255]; l.stroke = ['#000', 3]; l.y = y; return l; };
    if (cards.length === 1) {
      const c = cards[0], inf = HB.info(c.type, c.id);
      const art = HB.iconFrame(c.type, inf.icon, true);
      const box = new HB.Node(); box.x = W / 2; box.y = H / 2 + 20; dim.add(box);
      if (art) { const sp = new HB.Sprite(art); const k = Math.min(430 / (art.sw || 1), 520 / (art.sh || 1), c.type === 1 ? 1.4 : 2.2); sp.sx = sp.sy = k; box.add(sp); }
      const star = HB.frameByName('com_normal_star');
      if (star) for (let i = 0; i < Math.min(5, inf.quality); i++) { const s = new HB.Sprite(star); s.x = (i - (Math.min(5, inf.quality) - 1) / 2) * 46; s.y = -300; box.add(s); }
      const nm = named(c, -350, 34); box.add(nm);
      box.sx = box.sy = 0.3; box.fade = 0; HB.tween(box, { sx: 1, sy: 1, fade: 1 }, 0.25);
    } else {
      const per = 5, gap = 124, rows = Math.ceil(cards.length / per);
      cards.forEach((c, i) => {
        const icon = HB.cardIcon(c.type, c.id), r = Math.floor(i / per), col = i % per;
        const cell = new HB.Node(); cell.x = W / 2 + (col - (Math.min(per, cards.length) - 1) / 2) * gap; cell.y = H / 2 + ((rows - 1) / 2 - r) * 170 + 30;
        icon.x = 0; icon.y = 0; cell.add(icon);
        const nm = named(c, -70, 17); nm.dims = [gap - 6, 0]; nm.setText(nm.text); cell.add(nm);
        cell.fade = 0; cell.sx = cell.sy = 0.4; dim.add(cell);
        HB.tween({}, {}, 0.06 * i, () => HB.tween(cell, { sx: 1, sy: 1, fade: 1 }, 0.18));
      });
    }
    HB.scene.add(dim);
    let open = false;
    HB.tween(hint, { opacity: 255 }, 0.6, () => { open = true; });
    dim.onTouch = (ev) => { if (ev === 'up' && open) { dim.removeSelf(); done(); } };
  });
  // the cards and items named in a reply's <award> parts
  const awards = (reply) => {
    const x = HB.ui.x, out = [];
    for (const a of x.all(reply, 'award')) {
      for (const c of x.all(x.first(a, 'cardlist'), 'card')) out.push({ type: x.n(c, 'type') || 1, id: x.n(c, 'id'), num: x.n(c, 'num') || 1 });
      for (const p of x.all(x.first(a, 'proplist'), 'prop')) out.push({ type: 0, id: x.n(p, 'id'), num: x.n(p, 'num') || 1 });
    }
    return out.filter((c) => c.id > 0);
  };
  HB.awards = awards;

  // ---------------------------------------------------------------- the shop
  const TABS = [['ctrl_ninja', 'Recruit'], ['ctrl_weapon', 'Giftpack'], ['ctrl_armors', 'Tool'], ['ctrl_vip', 'VIP']];
  const SCROLL = { 1: 'Shop_02', 2: 'Shop_03', 3: 'Shop_04' };
  const TEN = { 1: 2800, 2: 1400 }; // the server's ten-pull prices (game.js TEN_COST)
  let timer = null;

  HB.screens.shop = async function shop(tab = 0) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let list;
    try {
      [list] = await Promise.all([HB.api('rl_r_shoplist', { Cmd: 1600 }), HB.data.tables(), ui.table('giftinfo'), ...['store/StoreItemsView', 'store/StoreNinjaView', 'store/StorePacksView', 'store/StoreGoodsView'].map((f) => HB.loadCCB(f))]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (list.code) return ui.tip(ui.errorText(list));
    const o = {};
    HB.game.showSub('store/StoreItemsView', o, 'btn_mainstore');
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    TABS.forEach(([name, title], i) => { const b = n[name]; if (b) { if (tabOff) b.frames[1] = i === tab ? tabOn || tabOff : tabOff; b.titles[1] = title; b.titleSize = 26; b.layout(); } }); // 26: 'Giftpack' filled its tab from edge to edge at 30
    if (n.label_StoreItemsView0) { const l = n.label_StoreItemsView0; l.size = 24; l.x += 24; l.setText('Top-up'); } // smaller and to the right: the 1st Recharge sticker lies over the button's left half
    if (n.sprite_notify_pray) n.sprite_notify_pray.visible = false;
    o.onButton = (sel) => {
      if (sel === 'BtnPray') return shop(0);
      if (sel === 'BtnGiftPack') return shop(1);
      if (sel === 'BtnConsum') return shop(2);
      ui.tip('Coming soon: ' + (sel === 'BtnVipInfo' ? 'VIP' : sel === 'BtnPurchase' ? 'Top-up' : sel), 1.2);
    };
    const kids = (tag) => x.all(list, tag).map((e) => Object.fromEntries([...e.children].map((c) => [c.nodeName, c.textContent])));
    const goods = kids('goods'), orders = Number((goods.find((g) => Number(g.propid) === 30) || {}).bagnum || 0);
    const rows = tab === 0 ? kids('recruit') : tab === 1 ? kids('packages').filter((p) => Number(p.package_show) !== 0) : goods.filter((g) => Number(g.prop_yuanbao) > 0 || Number(g.prop_yinzi) > 0);

    const box = n.node_tablecontent, size = n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows.length) * size.h;
    const ticking = [];
    rows.forEach((r, i) => {
      const co = {};
      const cell = HB.build(['store/StoreNinjaView', 'store/StorePacksView', 'store/StoreGoodsView'][tab], co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      [recruitRow, packRow, goodsRow][tab](co.n, r);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    if (timer) timer.stop = true;
    const mine = (timer = { stop: false });
    (function tick() { if (mine.stop || !box.parent) return; ticking.forEach((f) => f()); HB.tween({}, {}, 1, tick); })();

    function recruitRow(m, r) {
      const id = Number(r.recruit_id), cost = Number(r.recruit_yuanbao);
      const f = HB.frameByName(SCROLL[id]); if (f) m.sprite_ninjatype.setFrame(f);
      if (m.sprite_notify_cell) m.sprite_notify_cell.visible = false;
      m.label_remind.size = 20; m.label_remind.x += 14; // clear of the star the scroll's picture ends its 'Star level' line with
      let left = Number(r.free_recruit_time_left) || 0;
      const born = Date.now();
      const free = () => id !== 3 && Number(r.recruit_time) > 0 && left - Math.floor((Date.now() - born) / 1000) <= 0;
      const draw = () => {
        if (id === 3) { m.label_remind.setText('You have: ' + orders); return; }
        const s = left - Math.floor((Date.now() - born) / 1000);
        m.label_remind.setText(Number(r.recruit_time) <= 0 ? '' : s <= 0 ? 'Free recruitment' : clock(s) + ' until free');
        if (m.sprite_notify_cell) m.sprite_notify_cell.visible = s <= 0 && Number(r.recruit_time) > 0;
      };
      draw(); ticking.push(draw);
      if (id === 3) { m.sprite_goldicon.visible = false; m.label_newsprice.size = 22; m.label_newsprice.x += 16; m.label_newsprice.setText('Use up recruitment orders x 1'); } // at the layout's 30 it ran over the shinobi's picture
      else { m.label_goldval.setText(String(cost)); m.label_newsprice.visible = false; }
      tap(m.sprite_btn_getit, () => (id === 3 ? pull(id, 1, false) : prayWindow(id, cost, free())));
    }
    function packRow(m, p) {
      m.label_name.setText(p.package_name); m.label_desc.setText(p.package_desc || packText(p));
      if (m.node_descframe) { m.label_desc.dims = [Math.max(200, m.node_descframe.w), 0]; m.label_desc.setText(m.label_desc.text); }
      const gold = Number(p.package_yuanbao), silver = Number(p.package_yinzi);
      m.label_goldval.setText(String(gold || silver));
      if (!gold && silver) { const s = HB.frameByName('com_silver_icon'); if (s) m.sprite_goldicon.setFrame(s); }
      if (m.label_StorePacksView0) m.label_StorePacksView0.setText('Price:');
      icon(m.sprite_packagetype, 0, p.package_icon);
      tap(m.sprite_btn_buyit, async () => {
        if (!(await confirm('Buy ' + p.package_name + ' for ' + (gold || silver) + (gold ? ' gold?' : ' silver?'), { ok: 'Buy' }))) return;
        const r = await send('rl_w_shopbuy', { Cmd: 1701, Packageid: p.package_id });
        if (!r) return;
        const got = [...x.all(r, 'retobj')].map((e) => ({ type: [0, 0, 1, 2, 3, 4, 6, 5][Number(x.a(e, 'type'))] ?? 0, id: Number(x.a(e, 'id')), num: Number(x.a(e, 'num')) || 1 })).filter((c) => c.id > 0);
        await HB.game.refresh();
        if (got.length) await showCards(got); else ui.tip('Bought. Cards from a bag wait in the Award Center.', 2);
        shop(1);
      });
    }
    function goodsRow(m, g) {
      const gold = Number(g.prop_yuanbao), silver = Number(g.prop_yinzi);
      m.label_name.setText(g.prop_name);
      const inf = HB.info(0, g.propid);
      m.label_desc.setText(inf.desc || '');
      if (m.node_descsize) { m.label_desc.dims = [Math.max(200, m.node_descsize.w), 0]; m.label_desc.setText(m.label_desc.text); }
      if (m.label_notsell) m.label_notsell.visible = false;
      if (m.label_StoreGoodsView0) m.label_StoreGoodsView0.setText('Price:');
      m.label_priceval.setText(String(gold || silver));
      if (!gold && silver) { const s = HB.frameByName('com_silver_icon'); if (s) m.sprite_iconframe.setFrame(s); }
      m.label_havecount.setText(String(g.bagnum || 0));
      icon(m.sprite_goodstype, 0, g.prop_icon);
      tap(m.sprite_btn_buyit, async () => {
        if (!(await confirm('Buy ' + g.prop_name + ' for ' + (gold || silver) + (gold ? ' gold?' : ' silver?'), { ok: 'Buy' }))) return;
        const r = await send('rl_w_shopbuy', { Cmd: 1700, Goodsid: g.propid, Count: 1 });
        if (!r) return;
        await HB.game.refresh();
        ui.tip('Bought ' + g.prop_name, 1.2);
        shop(2);
      });
      tap(m.sprite_btn_useit, async () => {
        if (!(Number(g.bagnum) > 0)) return ui.tip('You have no ' + g.prop_name, 1.5);
        const r = await send('rl_w_propuse', { Cmd: 1800, Goodsid: g.propid });
        if (!r) return;
        await HB.game.refresh();
        ui.tip('Used ' + g.prop_name, 1.2);
        shop(2);
      });
    }
    function packText(p) { const d = HB.row('giftinfo', p.package_id); return d ? String(d[6] || '').replace(/\0+$/, '') : ''; }
    function icon(holder, type, name) {
      const pic = HB.iconFrame(type, String(name || '').replace(/\0+$/, ''));
      if (!pic || !holder) return;
      const sp = new HB.Sprite(pic); const k = Math.min((holder.w - 14) / (pic.sw || 1), (holder.h - 14) / (pic.sh || 1));
      sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp);
    }
    async function send(cgi, params) {
      ui.loading(true);
      let r;
      try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
      ui.loading(false);
      if (r.code) { ui.tip(r.getAttribute('message') || ui.errorText(r)); return null; }
      return r;
    }
    async function pull(id, count, free) {
      const r = await send('rl_w_recruit', { Cmd: count === 10 ? 1901 : 1900, Type: id, Free: free ? 1 : 0 });
      if (!r) return;
      await HB.game.refresh();
      await showCards(awards(r), count === 10 ? 'You recruited' : 'New shinobi!');
      shop(0);
    }
    // the game's recruit window: once (free when the timer is done) or ten times
    async function prayWindow(id, cost, free) {
      const w = { onButton: (sel) => { w.close(); if (sel === 'clickPrayOne') pull(id, 1, free); else if (sel === 'clickPrayTen') pull(id, 10, false); } };
      let left = 0;
      try { const r = await HB.api('rl_r_recruit', { Cmd: 1902, Type: id }); left = Number(x.a(x.first(r, 'recruit'), 'protect_comming', 0)); } catch (e) { /* the window still opens */ }
      await dialog('dlg_ui/PrayDialogView', w);
      const m = w.n;
      m.labelTitle.setText('Shinobi recruit');
      m.label_prayone_cost.setText(String(cost)); m.label_prayten_cost.setText(String(TEN[id] || cost * 10));
      m.label_prayone_free.setText('Free this time'); m.label_prayone_free.visible = free; m.node_prayone_cost_container.visible = !free;
      if (m.node_cost_gold) m.node_cost_gold.visible = false;
      for (const k of ['label_PrayDialogView2', 'label_PrayDialogView3', 'label_PrayDialogView4', 'label_PrayDialogView5']) if (m[k] && m[k].parent === m.labelTitle.parent) m[k].visible = false;
      m.node_desc1_container.visible = left > 1; m.node_desc2_container.visible = left === 1; m.node_desc3_container.visible = false;
      if (left > 1) m.label_protect_coming.setText(String(left - 1));
    }
  };
})();
