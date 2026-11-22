// Battles, the tower (Home > Battles, from level 30): CTowerView (sub_ui/TowerView.ccbi) = the floors you have opened, and
// CTowerLevelView (sub_ui/TowerLevelView.ccbi) = one floor's seven rounds (six guards, then the boss).
// Requests: rl_r_dup Cmd 7000 (<duplist maxchap> with a <dup><chapid><process> per open floor; process = the round to fight next,
// 8 = floor passed), rl_w_dup Cmd 3100 Chap Round (the fight). Enemies, exp, silver and the round's words come from the game's
// towerfloor table ([1] floor, [2] round, [4] the enemy shown, [20] exp, [21] silver, [23] words).
// Ours for now: the floor list is drawn as plain rows (the phone draws a tower picture you scroll up); Rank and Sweep are not built.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const clean = (s) => String(s ?? '').replace(/\0+$/, '');

  async function load() {
    const ui = HB.ui;
    ui.loading(true);
    try {
      const [list, floors] = await Promise.all([HB.api('rl_r_dup', { Cmd: 7000 }), ui.table('towerfloor'), HB.data.tables(), HB.loadCCB('sub_ui/TowerView'), HB.loadCCB('sub_ui/TowerLevelView')]);
      ui.loading(false);
      if (list.code) { ui.tip(ui.errorText(list)); return null; }
      const x = ui.x;
      return { floors, open: x.all(list, 'dup').map((d) => ({ chap: x.n(d, 'chapid'), process: x.n(d, 'process') || 1 })) };
    } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
  }

  HB.screens.tower = async function tower() {
    const ui = HB.ui, st = await load();
    if (!st) return;
    const o = {};
    HB.game.showSub('sub_ui/TowerView', o);
    const n = o.n;
    if (n.btn_sweep) n.btn_sweep.setTitle('Sweep');
    o.onButton = (sel) => { if (sel === 'BtnBack') return HB.game.goHome();
      // Sweep is the game's own script (CTowerView::onBtnSweep: execLuaScript("business_proxy/towerSweep_business.lua"))
      if (sel === 'BtnSweep' && HB.L && HB.luaRun) { const go = () => HB.luaRun('business_proxy/towerSweep_business.lua'); return HB.game.loadItems ? HB.game.loadItems().then(go) : go(); }
      ui.tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2); };
    const box = n.scroll_tower;
    const rowH = 96, list = st.open.slice().reverse();
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h - 175; // the layout's box runs on under the top bar
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, list.length) * rowH;
    const frame = HB.frameByName('com_bk_frame_16');
    list.forEach((f, i) => {
      const row = new HB.Node(); row.w = Math.min(600, box.w - 20); row.h = rowH - 12; row.x = (box.w - row.w) / 2; row.y = col.h - (i + 1) * rowH + 6;
      if (frame) { const bg = new HB.Scale9(frame); bg.ax = bg.ay = 0; bg.w = row.w; bg.h = row.h; row.add(bg); }
      const done = f.process > 7;
      const t = new HB.Label('Floor ' + f.chap, 'Arial-BoldMT', 30, [0, 0], 0, 1); t.ax = 0; t.x = 28; t.y = row.h / 2; t.color = [255, 232, 170]; t.stroke = ['#2a1505', 3]; row.add(t);
      const s = new HB.Label(done ? 'Passed' : 'Round ' + Math.min(7, f.process) + ' / 7', 'Arial-BoldMT', 24, [0, 0], 2, 1); s.ax = 1; s.x = row.w - 28; s.y = row.h / 2; s.color = done ? [140, 240, 110] : [255, 255, 255]; s.stroke = ['#000', 3]; row.add(s);
      tap(row, () => floor(f.chap));
      col.add(row);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    // next to the layout's own (empty) scroll view, in the same place: bottom-left corner from its anchor
    scroll.x = box.x - box.ax * box.w; scroll.y = box.y - box.ay * box.h; scroll.z = box.z + 1;
    box.parent.add(scroll);
  };

  async function floor(chap) {
    const ui = HB.ui, x = ui.x, st = await load();
    if (!st) return;
    const mine = st.open.find((f) => f.chap === chap) || { chap, process: 1 };
    const rounds = st.floors.rows.filter((r) => r[1] === chap).sort((a, b) => a[2] - b[2]);
    const o = {};
    HB.game.showSub('sub_ui/TowerLevelView', o);
    const n = o.n;
    if (n.label_TowerLevelView0) n.label_TowerLevelView0.setText('Defeat:');
    if (n.label_TowerLevelView1) n.label_TowerLevelView1.setText('Drops:');
    if (n.label_boxdesc) n.label_boxdesc.setText('Mystery treasure');
    let pick = Math.min(7, mine.process);
    const show = () => {
      const r = rounds[pick - 1] || [];
      n.label_exp.setText(String(r[20] || 0)); n.label_silver.setText(String(r[21] || 0));
      if (n.label_levelinfo) { if (n.node_levelinfo) n.label_levelinfo.dims = [n.node_levelinfo.w, 0]; n.label_levelinfo.setText('Floor ' + chap + ', round ' + pick + (clean(r[23]) ? '\n' + clean(r[23]) : '')); }
      for (let i = 1; i <= 7; i++) { const f = n['sprite_fight_icon' + i]; if (f) f.visible = i === pick && mine.process <= 7 && i === mine.process; }
    };
    for (let i = 1; i <= 7; i++) {
      const r = rounds[i - 1] || [], id = '0' + i, inf = HB.info(1, r[4]);
      const name = n['label_name' + id]; if (name) name.setText(r[4] ? inf.name : '');
      const holder = n['node_icon' + id], pic = r[4] && HB.iconFrame(1, inf.icon, i === 7);
      if (holder && pic) { holder.clip = i === 7; const sp = new HB.Sprite(pic); const k = (i === 7 ? Math.max : Math.min)(holder.w / (pic.sw || 1), holder.h / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp); }
      const beat = n['sprite_beat' + i]; if (beat) beat.visible = mine.process > i;
    }
    show();
    o.onButton = async (sel) => {
      if (sel === 'BtnBack') return HB.screens.tower();
      const m = /^BtnIconClick0(\d)$/.exec(sel);
      if (!m) return;
      const round = Number(m[1]);
      if (round !== pick) { pick = round; return show(); }
      if (round < mine.process) return ui.tip('Already beaten', 1.2);
      if (round > mine.process) return ui.tip('Beat round ' + mine.process + ' first', 1.5);
      const r = rounds[round - 1] || [];
      ui.loading(true);
      let reply;
      try { reply = await HB.api('rl_w_dup', { Cmd: 3100, Chap: chap, Round: round }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
      ui.loading(false);
      if (reply.code) return ui.tip(ui.errorText(reply));
      const won = Number(x.a(x.first(x.first(reply, 'fight'), 'preview'), 'result', 0)) === 1;
      await HB.fight.play(reply, { kind: 'tower', exp: won ? r[20] || 0 : 0, silver: won ? r[21] || 0 : 0, energy: 0 });
      await HB.game.refresh();
      floor(chap);
    };
  }
})();
