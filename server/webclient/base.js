// The village on the Home screen and two of its buildings.
// CDefaultSLGMenu: the village layout (sub_ui/<country>CountryDefaultMenu.ccbi) holds six buildings standing on a wheel around
// node_radius: Base (centre), Cross and Noodle to the right, Border, Shop and the money tree to the left. Swiping turns the wheel,
// a tap opens the building. Ours for now: how far a swipe turns it and the snap to the nearest building are by eye.
//   Noodle     -> the ramen stall, CRamenView (sub_ui/RamenView.ccbi): rl_w_ramen fills energy and grudge (12-14 and 18-20, once each)
//   money tree -> CMoneyTreeView (sub_ui/MoneyTreeView.ccbi): rl_r_mtree (<cf> the rules, <user> used / free shakes), rl_w_mtree (a shake)
// Base (My Base), Shop (secret shop), Cross (cross-server battle) and Border (border war) are the game's own Lua screens: not yet.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const BUILDINGS = { borderWar: ['Border war'], treasure: ['Ramen', 'ramen'], energy: ['My Base'], ninja: ['Cross-server battle'], tree: ['Money tree', 'moneytree'], secretshop: ['Secret shop'] };
  let turned = Number(new URLSearchParams(location.search).get('wheel')) || 0; // the wheel's turn, kept while you visit a building (test switch: &wheel=<radians>)

  // called by game.js once the village is built; n = the home screen's named nodes
  HB.villageWheel = function villageWheel(n) {
    const L = n.layer_building, hub = n.node_radius;
    if (!L || !hub) return;
    const cx = hub.x - L.x, cy = hub.y - L.y;
    const items = Object.keys(BUILDINGS).map((k) => ({ k, sp: n['sprite_' + k] })).filter((i) => i.sp)
      .map((i) => ({ ...i, a: Math.atan2(i.sp.x - cx, i.sp.y - cy), r: Math.hypot(i.sp.x - cx, i.sp.y - cy) }));
    if (!items.length) return;
    const min = -Math.max(...items.map((i) => i.a)), max = -Math.min(...items.map((i) => i.a));
    const place = (rot) => { for (const i of items) { i.sp.x = cx + i.r * Math.sin(i.a + rot); i.sp.y = cy + i.r * Math.cos(i.a + rot); i.sp.rot = (i.a + rot) * 180 / Math.PI; i.sp.z = Math.round(100 - i.sp.y / 10); } }; // a building stands upright at the top and leans as it goes round
    Object.defineProperty(L, 'wheel', { configurable: true, get: () => turned, set: (v) => { turned = Math.max(min, Math.min(max, v)); place(turned); } });
    L.wheel = turned;
    let start = null;
    L.onTouch = (ev, x, y) => {
      if (ev === 'down') { start = { x, y, last: x, moved: false }; return; }
      if (!start) return;
      if (ev === 'move') {
        if (Math.abs(x - start.x) > 14) start.moved = true;
        if (start.moved) L.wheel = turned + (x - start.last) / 430;
        start.last = x;
        return;
      }
      const s = start; start = null;
      if (ev !== 'up') return;
      if (s.moved) { // settle on the building nearest the top
        const near = items.reduce((b, i) => (Math.abs(i.a + turned) < Math.abs(b.a + turned) ? i : b));
        return void HB.tween(L, { wheel: -near.a }, 0.18);
      }
      const hit = items.filter((i) => i.sp.hit(x, y)).sort((p, q) => q.sp.z - p.sp.z)[0];
      if (!hit) return;
      const [name, screen] = BUILDINGS[hit.k];
      if (screen && HB.screens[screen]) return HB.screens[screen]();
      if (HB.game.luaBuilding && HB.game.luaBuilding(hit.k)) return; // Base, Shop, Cross, Border: the game's own Lua screens (luascreens.js)
      HB.ui.tip('Coming soon: ' + name, 1.2);
    };
  };

  async function send(cgi, params) {
    const ui = HB.ui;
    ui.loading(true);
    let r;
    try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
    ui.loading(false);
    if (r.code) { ui.tip(ui.errorText(r), 2.2); return null; }
    return r;
  }

  // ---------------------------------------------------------------- the ramen stall
  HB.screens.ramen = async function ramen() {
    const ui = HB.ui;
    await HB.loadCCB('sub_ui/RamenView');
    const o = {};
    HB.game.showSub('sub_ui/RamenView', o);
    o.onButton = async (sel) => {
      if (sel !== 'clickEat') return;
      if (!(await send('rl_w_ramen', { Cmd: 1 }))) return;
      await HB.game.refresh();
      ui.tip('Delicious! Energy and grudge are full again', 2.2);
      ramen();
    };
  };

  // ---------------------------------------------------------------- the money tree
  HB.screens.moneytree = async function moneytree(last) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let reply;
    try { [reply] = await Promise.all([HB.api('rl_r_mtree', { Cmd: 1 }), HB.loadCCB('sub_ui/MoneyTreeView')]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const cf = x.first(reply, 'cf'), us = x.first(reply, 'user'), me = HB.game.user || {};
    const perDay = x.n(cf, 'timesperday'), low = x.n(cf, 'low_multiple'), top = x.n(cf, 'top_multiple'), cost = x.n(cf, 'shake_cost'), start = x.n(cf, 'start_silver');
    const used = x.n(us, 'usedTimes'), free = x.n(us, 'freeTimes');
    const o = {};
    HB.game.showSub('sub_ui/MoneyTreeView', o);
    const n = o.n;
    n.label_goldval.setText(String(me.cash ?? me.gold ?? 0)); n.label_silverval.setText(String(me.coin ?? 0));
    n.label_desc.setText('Each shake drops ' + start * low + ' to ' + start * top + ' silver.');
    n.label_times.setText(String(Math.max(0, perDay - used)));
    n.label_costgold.setText(String(cost)); n.label_getsilver.setText(String(start * low));
    if (n.label_MoneyTreeView2) n.label_MoneyTreeView2.setText('Spend');
    if (n.label_MoneyTreeView4) n.label_MoneyTreeView4.setText('silver');
    n.node_tips.visible = free <= 0; n.label_freetry.visible = free > 0;
    n.label_freetry.setText(free > 0 ? 'You have ' + free + ' free shake' + (free > 1 ? 's' : '') + ' left' : '');
    n.label_try.setText(last ? 'The tree dropped ' + last + ' silver!' : 'Try your luck, friend!');
    let busy = false;
    o.onButton = async (sel) => {
      if (sel === 'onBtnBack') return HB.game.goHome();
      if (sel !== 'onBtnSwing' || busy) return;
      if (used >= perDay) return ui.tip('No shakes left today', 1.6);
      busy = true;
      const r = await send('rl_w_mtree', { Cmd: 2 });
      if (!r) { busy = false; return; }
      // the tree shakes (ours: the phone plays its own animation in node_anim)
      const tree = n.node_anim && n.node_anim.parent; if (tree) { const x0 = tree.x; for (let i = 0; i < 4; i++) { await new Promise((ok) => HB.tween(tree, { x: x0 + (i % 2 ? -7 : 7) }, 0.06, ok)); } tree.x = x0; }
      await HB.game.refresh();
      moneytree(x.n(x.first(r, 'user'), 'latestSilver'));
    };
  };
})();
