// Ninjabook: the collection (the Home middle row's first icon; C++ on the phone: CGameBookListView + CGameBookCardView).
//   layout  sub_ui/GameObjBookList.ccbi (three tabs: Ninja / Gear / Ninjutsu) with a grid of sub_ui/GameObjBookCard.ccbi
//   tables  ninjabookrank  [1] place, [2] picture, [3] shinobi id, [4] its second version (attack / defence card)
//           equipbookrank  [1] place, [2] picture, [3] gear id          ninjutsubookrank  [1] place, [2] picture, [3] ninjutsu id
// No request: the phone reads the three tables and asks CPlayerDataMgr whether you hold the card (GetObjByDataID); a card you
// hold shows in its quality frame, the others in the plain frame. Tap = the card's own window (CGameCardNinja on the phone,
// our details window here).
// Ours: a card you do not hold is drawn grey (the phone's exact look of a missing card was not read from the C++), and the
// line "Collected a / b" under the tabs.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const TABS = [
    { btn: 'ctrl_ninja', sel: 'BtnNinja', title: 'Ninja', table: 'ninjabookrank', types: [1], ids: (r) => [r[3], r[4]].filter(Boolean), frame: 'ninjaSmall' },
    { btn: 'ctrl_weapon', sel: 'BtnWeapon', title: 'Gear', table: 'equipbookrank', types: [2, 3, 4], ids: (r) => [r[3]], frame: 'small' },
    { btn: 'ctrl_ninjutsu', sel: 'BtnNinjustu', title: 'Ninjutsu', table: 'ninjutsubookrank', types: [6], ids: (r) => [r[3]], frame: 'small' },
  ];
  const clean = (s) => String(s ?? '').replace(/\0+$/, '');

  HB.screens.ninjabook = async function ninjabook(tab = 0) {
    const ui = HB.ui, T = TABS[tab] || TABS[0];
    ui.loading(true);
    let t;
    try { [t] = await Promise.all([ui.table(T.table), HB.data.tables(), HB.loadCCB('sub_ui/GameObjBookList'), HB.loadCCB('sub_ui/GameObjBookCard')]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    const o = {};
    HB.game.showSub('sub_ui/GameObjBookList', o);
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    TABS.forEach((x, i) => { const b = n[x.btn]; if (b) { if (tabOff) b.frames[1] = i === tab ? tabOn || tabOff : tabOff; b.titles[1] = x.title; b.titleSize = 26; b.layout(); } }); // 26: 'Ninjutsu' filled its tab from edge to edge at 30
    o.onButton = (sel) => { const i = TABS.findIndex((x) => x.sel === sel); if (i >= 0) return ninjabook(i); if (/Back|Close/i.test(sel)) return HB.game.goHome(); };

    const mine = new Set(HB.data.ofType(...T.types).map((c) => c.id));
    const rows = t.rows.slice().sort((a, b) => a[1] - b[1]);
    const box = n.node_tablecontent, size = n.node_cardcontent;
    const cols = 4, lines = Math.ceil(rows.length / cols);
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const grid = new HB.Node(); grid.w = box.w; grid.h = Math.max(1, lines) * size.h;
    let have = 0;
    rows.forEach((r, i) => {
      const ids = T.ids(r), held = ids.find((id) => mine.has(id)), id = held || ids[0];
      if (held) have++;
      const type = T.types[0], inf = HB.info(type, id);
      const co = {};
      const cell = HB.build('sub_ui/GameObjBookCard', co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (i % cols) * size.w + (box.w - cols * size.w) / 2; cell.y = grid.h - (Math.floor(i / cols) + 1) * size.h; cell.w = size.w; cell.h = size.h;
      const m = co.n, holder = m.sprite_iconframe;
      const fr = HB.qualityFrame(T.frame, held ? inf.quality : 1);
      if (fr && holder) holder.setFrame(fr);
      // the picture comes when the row scrolls into view: all 287 at once is more than the server lets one visitor ask for
      cell.fill = () => {
        cell.fill = null;
        const pic = HB.iconFrame(type, clean(r[2])) || HB.iconFrame(type, inf.icon);
        if (!pic || !holder) return;
        const sp = new HB.Sprite(pic); const k = Math.min((holder.w - 16) / (pic.sw || 1), (holder.h - 16) / (pic.sh || 1));
        sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; sp.z = 1; sp.grey = !held; holder.add(sp);
      };
      if (holder) holder.grey = !held;
      if (m.label_framename) m.label_framename.setText(inf.name); // hidden in the layout, like on the phone
      cell.onTouch = (ev, tx, ty) => {
        if (ev === 'down') cell._d = [tx, ty];
        if (ev === 'up' && cell._d && Math.hypot(tx - cell._d[0], ty - cell._d[1]) < 14 && HB.screens.details) {
          HB.sound && HB.sound('click');
          const row = inf.row;
          HB.screens.details((held && HB.data.ofType(...T.types).find((c) => c.id === held)) || { seq: 0, type: type === 2 && row ? (row[3] || 2) : type, id, level: 1, attri: 0, tupo: 0, starlevel: 0, newlife: 0, exp: 0 }, { view: true });
        }
      };
      grid.add(cell);
    });
    scroll.setContent(grid); grid.y = scroll.h - grid.h;
    box.add(scroll);
    const watch = () => {
      if (!grid.parent || !scroll.parent || !box.shown()) return;
      for (const cell of grid.children) if (cell.fill && cell.y + grid.y < box.h + size.h && cell.y + grid.y > -2 * size.h) cell.fill();
      requestAnimationFrame(watch);
    };
    watch();
    // ours: how many of this tab you hold
    const l = new HB.Label('Collected ' + have + ' / ' + rows.length, 'Arial-BoldMT', 22, [0, 0], 1, 1); l.color = [255, 240, 200]; l.stroke = ['#2a1505', 3];
    l.ax = 1; l.x = box.w - 6; l.y = box.h + 22; l.z = 5; box.add(l);
  };
})();
