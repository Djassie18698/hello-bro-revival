// Battles, the tower (Home > Battles, from level 30): CTowerView (sub_ui/TowerView.ccbi) = the floors you have opened, and
// CTowerLevelView (sub_ui/TowerLevelView.ccbi) = one floor's seven rounds (six guards, then the boss).
// Requests: rl_r_dup Cmd 7000 (<duplist maxchap> with a <dup><chapid><process> per open floor; process = the round to fight next,
// 8 = floor passed), rl_w_dup Cmd 3100 Chap Round (the fight). Enemies, exp, silver and the round's words come from the game's
// towerfloor table ([2] floor, seven rows a floor in id order = its rounds, [4] the enemy shown, [20] exp, [21] silver, [23] words).
// The floors are the phone's own map (map.tmx) since 23 Nov 2026. Rank (CTowerRankDlg, dlg_ui/TowerRankReward.ccbi) since 24 Nov:
// rl_r_dup Cmd 7001 -> <player><step_num><rank><award> (award = a bit per claimed row) + <rank_list><item rank uid nick level step_num
// firstninja firstninjastar newlife>; the Reward tab is the game's tower_reward table ([2] rounds needed, pictures filldropdata [4] [6] [8]),
// claimed with rl_w_dup Cmd 3101 AwardID.
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
      const [list, floors] = await Promise.all([HB.api('rl_r_dup', { Cmd: 7000 }), ui.table('towerfloor'), HB.data.tables(), HB.loadCCB('sub_ui/TowerView'), HB.loadCCB('sub_ui/TowerLevelView'), HB.loadSheet('ccbResources/tower_ui.plist'), HB.loadImage('ccbResources/map001.png'), HB.loadImage('ccbResources/map002.png')]);
      ui.loading(false);
      if (list.code) { ui.tip(ui.errorText(list)); return null; }
      const x = ui.x;
      return { floors, max: Number(x.a(x.first(list, 'duplist'), 'maxchap', 0)) || 0, open: x.all(list, 'dup').map((d) => ({ chap: x.n(d, 'chapid'), process: x.n(d, 'process') || 1 })) };
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
      if (sel === 'BtnRank') return rank(0);
      ui.tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2); };
    // The floors are a map you scroll (CTowerView::InitUI): ccbResources/map.tmx = a 680 x 2040 picture, map001.png on top of
    // map002.png, with one 50 x 50 place per floor (its "o_layer_1" objects, measured from the top-left corner; MAP below).
    // A floor you passed wears pass_tower, the one you are on level_tower, the rest lock_tower. A tap on an open floor opens
    // the "Level Cleared reward" window (CTowerFirstPassReward), whose Enter leads to the floor's seven rounds.
    const box = n.scroll_tower, W = 680, H = 2040, k = box.w / W;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const map = new HB.Node(); map.w = W; map.h = H; map.sx = map.sy = k;
    [['ccbResources/map001.png', 1020], ['ccbResources/map002.png', 0]].forEach(([file, y]) => {
      const fr = HB.frame('', file); if (!fr) return;
      const sp = new HB.Sprite({ ...fr, w: Math.min(fr.w, W), sw: Math.min(fr.sw, W) }); sp.ax = sp.ay = 0; sp.x = 0; sp.y = y; map.add(sp); // map001 is 700 wide: its first 680 are the map
    });
    { // the white dots of the path: the map's third layer, 99 times the 20 x 20 dot that sits in map001's spare right edge (680, 0)
      const fr = HB.frame('', 'ccbResources/map001.png');
      if (fr) for (let i = 0; i < DOTS.length; i += 2) { const d = new HB.Sprite({ ...fr, x: fr.x + 680 * (fr.w / fr.sw || 1), w: 20, h: 20, sw: 20, sh: 20 }); d.ax = d.ay = 0; d.x = DOTS[i]; d.y = H - DOTS[i + 1] - 20; map.add(d); }
    }
    const max = Math.max(1, st.max || 1);
    MAP.forEach(([mx, my], i) => {
      const chap = i + 1, mine = st.open.find((f) => f.chap === chap);
      const passed = chap < max || (mine && mine.process > 7);
      const fr = HB.frameByName(passed ? 'pass_tower' : chap === max ? 'level_tower' : 'lock_tower');
      const sp = new HB.Sprite(fr); sp.x = mx + 25; sp.y = H - (my + 25); map.add(sp);
      if (chap === max && !passed) { sp.sx = sp.sy = 1; (function pulse() { if (!sp.parent || !scroll.parent) return; HB.tween(sp, { sx: 1.08, sy: 1.08 }, 0.7, () => HB.tween(sp, { sx: 1, sy: 1 }, 0.7, pulse)); })(); } // ours: a slow pulse where the phone plays its little ninja animation
      tap(sp, () => { if (chap > max) return ui.tip('Pass floor ' + max + ' first', 1.5); reward(chap, st); });
    });
    scroll.setContent(map);
    // start with the floor you are on in view (a third from the top)
    { const at = MAP[Math.min(MAP.length, max) - 1], top = scroll.h - H * k; map.y = Math.max(top, Math.min(0, top + (at[1] + 25) * k - scroll.h / 3)); }
    box.add(scroll);
  };
  // every floor's place on the map (map.tmx, objects level_1 .. level_25: x, y of the 50 x 50 box, from the top-left corner)
  const MAP = [[270, 100], [140, 190], [290, 240], [467, 292], [320, 390], [170, 490], [440, 520], [300, 590], [100, 660], [291, 752], [450, 830], [320, 920], [160, 980],
    [310, 1080], [240, 1200], [480, 1220], [540, 1340], [400, 1420], [240, 1390], [110, 1490], [300, 1550], [430, 1650], [280, 1750], [200, 1880], [480, 1960]];
  const DOTS = [250,130,220,150,190,160,170,240,200,260,230,270,260,270,350,270,380,290,410,300,440,310,480,350,460,370,400,380,430,380,370,390,300,430,280,450,250,470,220,480,230,520,260,530,290,530,330,530,370,530,400,530,450,580,430,590,360,600,400,600,230,610,270,610,200,620,170,630,140,640,140,710,160,730,180,750,210,760,250,760,350,780,380,800,400,810,430,820,450,880,430,890,400,900,380,920,300,950,260,960,240,980,220,1000,150,1030,170,1060,210,1080,250,1090,280,1090,360,1120,350,1150,320,1160,300,1190,440,1240,280,1250,400,1250,310,1260,350,1260,530,1280,550,1310,520,1390,300,1400,340,1410,490,1410,370,1420,460,1420,220,1430,200,1450,170,1480,140,1550,270,1560,170,1570,220,1570,360,1590,390,1610,420,1630,440,1710,420,1730,400,1750,370,1760,340,1770,280,1800,260,1830,240,1860,240,1930,270,1950,300,1960,340,1970,380,1970,420,1970,450,1970]; // x, y pairs from the top-left corner (map.tmx g_layer3)

  // "Level Cleared reward" (dlg_ui/TowerFirstPassReward): what the floor's boss can drop (rushtower [9]-[12] -> filldropdata), the
  // boss round's exp and silver, today's try, Enter / Return
  async function reward(chap, st) {
    const ui = HB.ui;
    const [tower, fill] = await Promise.all([ui.table('rushtower'), ui.table('filldropdata'), HB.loadCCB('dlg_ui/TowerFirstPassReward')]);
    const row = tower.rows.find((r) => r[0] === chap) || [], boss = st.floors.rows.filter((r) => r[2] === chap).sort((p, q) => q[0] - p[0])[0] || [];
    const mine = st.open.find((f) => f.chap === chap) || { process: chap < (st.max || 1) ? 8 : 1 };
    const w = { onButton: (sel) => { w.close(); if (sel === 'BtnLogin') floor(chap); } };
    await HB.dialog('dlg_ui/TowerFirstPassReward', w);
    const m = w.n;
    m.label_TowerFirstPassReward0.setText('Level Cleared reward'); m.label_TowerFirstPassReward2.setText('Possibility of boss landing');
    m.label_TowerFirstPassReward1.setText('Number of challenges today:');
    m.ctrl_enter.setTitle('Enter'); m.ctrl_back.setTitle('Return');
    m.label_exp.setText(String(boss[20] || 0)); m.label_silver.setText(String(boss[21] || 0));
    m.label_challenge.setText(mine.process > 7 ? '0/1' : '1/1');
    for (let i = 1; i <= 4; i++) {
      const d = fill.rows.find((r) => r[0] === row[8 + i]), icon = m['sprite_icon' + i], name = m['label_icon' + i];
      if (!d) { for (const z of [icon, name, m['ctrl_reward' + i]]) if (z) z.visible = false; continue; }
      const nm = clean(d[2]);
      if (name) { name.setText(nm); const room = 150; if (name.w > room) name.sx = name.sy = Math.max(0.5, room / name.w); } // ours: made to fit (the phone lets the four names run into each other)
      const qf = HB.qualityFrame('small', Math.max(1, d[4] || 1)); if (qf && icon) icon.setFrame(qf);
      const pic = HB.frameByName('small_' + d[3]) || HB.frameByName(d[3]) || HB.frameByName('icon_' + d[3]);
      if (pic && icon) { const sp = new HB.Sprite(pic); const q = Math.min((icon.w - 12) / (pic.sw || 1), (icon.h - 12) / (pic.sh || 1)); sp.sx = sp.sy = q; sp.x = icon.w / 2; sp.y = icon.h / 2; icon.add(sp); }
    }
  }

  // the Rank window: two tabs, Rank (the top 100 by rounds won: place, first card, level, name, rounds) and Reward (one row per floor)
  async function rank(tab) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let reply, rewards, fill;
    try {
      [reply, rewards, fill] = await Promise.all([HB.api('rl_r_dup', { Cmd: 7001 }), ui.table('tower_reward'), ui.table('filldropdata'), HB.data.tables(),
        HB.loadCCB('dlg_ui/TowerRankReward'), HB.loadCCB('dlg_ui/TowerRankCell1'), HB.loadCCB('dlg_ui/TowerRankCell2'), HB.loadSheet('ccbResources/tower_ui.plist')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const me = x.first(reply, 'player'), steps = x.n(me, 'step_num') || 0, place = x.n(me, 'rank') || 0;
    let mask = x.n(me, 'award') || 0;
    const w = { onButton: (sel) => { if (sel === 'BtnClose') return w.close(); if (sel === 'BtnRank') return show(0); if (sel === 'BtnReward') return show(1); } };
    await HB.dialog('dlg_ui/TowerRankReward', w);
    const m = w.n;
    m.label_TowerRankReward0.setText('Progress:'); m.label_progress.setText(String(steps)); m.label_rank.setText(place ? String(place) : 'Not ranked');
    const tabs = [m.ctrl_rank, m.ctrl_reward].map((b) => b && { b, off: b.frames[1], on: b.frames[2] || b.frames[1] });
    let scroll = null;
    const list = (count, size, make) => {
      if (scroll) scroll.removeSelf();
      const box = m.node_tablecontent;
      scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
      const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, count) * size.h;
      for (let i = 0; i < count; i++) { const cell = make(i); cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h; col.add(cell); }
      scroll.setContent(col); box.add(scroll);
    };
    const digit = (holder, name) => { const fr = HB.frameByName(name); if (!fr || !holder) return null; const sp = new HB.Sprite(fr); sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp); return sp; };
    const rows = x.all(x.first(reply, 'rank_list'), 'item');
    function show(t) {
      tabs.forEach((k, i) => { if (k) { k.b.frames[1] = i === t ? k.on : k.off; k.b.layout(); } });
      if (t === 0) return list(rows.length, m.node_cardcontent1, (i) => {
        const r = rows[i], co = {}, cell = HB.build('dlg_ui/TowerRankCell1', co, [m.node_cardcontent1.w, m.node_cardcontent1.h]), c = co.n, no = Number(x.a(r, 'rank')) || i + 1;
        const bk = HB.frameByName(i % 2 ? 'tower_rank_12' : 'tower_rank_11'); if (bk && c.sprite_bk) c.sprite_bk.setFrame(bk);
        // the place: a gold number for the first three, then one or two plain digits (CTowerRankCell)
        if (no <= 3) digit(c.index_pos, 'tower_rank_gold_number_' + no);
        else if (no < 10) digit(c.index_pos, 'tower_rank_number_' + no);
        else if (no < 100) { digit(c.index_pos1, 'tower_rank_number_' + Math.floor(no / 10)); digit(c.index_pos2, 'tower_rank_number_' + no % 10); }
        else String(no).split('').forEach((d, k) => { const sp = digit(c.index_pos, 'tower_rank_number_' + d); if (sp) { sp.sx = sp.sy = 0.7; sp.x = c.index_pos.w / 2 + (k - 1) * 26; } }); // ours: place 100 has no room for three digits
        const id = Number(x.a(r, 'firstninja')) || 0, inf = id ? HB.info(1, id) : null;
        for (const k of ['node_shadow_back', 'node_shadow_front', 'node_inlay_frame']) if (c[k]) c[k].visible = false;
        if (inf && c.sprite_ninjaicon) {
          const qf = HB.qualityFrame('ninjaSmall', inf.quality) || HB.qualityFrame('small', inf.quality), pic = HB.iconFrame(1, inf.icon);
          if (qf) c.sprite_ninjaicon.setFrame(qf);
          if (pic && c.node_icon) { const sp = new HB.Sprite(pic); const q = Math.min(c.node_icon.w / (pic.sw || 1), c.node_icon.h / (pic.sh || 1)); sp.sx = sp.sy = q; sp.x = c.node_icon.w / 2; sp.y = c.node_icon.h / 2; c.node_icon.add(sp); }
        }
        c.label_level.setText(String(x.a(r, 'level') || '')); c.label_name.setText(String(x.a(r, 'nick') || '')); c.label_step.setText(String(x.a(r, 'step_num') || 0));
        return cell;
      });
      list(rewards.rows.length, m.node_cardcontent2, (i) => {
        const g = rewards.rows[i], co = {}, cell = HB.build('dlg_ui/TowerRankCell2', co, [m.node_cardcontent2.w, m.node_cardcontent2.h]), c = co.n;
        c.label_TowerRankCell20.setText('reward'); c.label_TowerRankCell20.x += 26; c.label_TowerRankCell20.sx = c.label_TowerRankCell20.sy = 0.78; c.label_item_title.setText(String(g[2]));
        [g[4], g[6], g[8]].forEach((fid, k) => {
          const d = fill.rows.find((r) => r[0] === fid), icon = c['sprite_item' + (k + 1)], name = c['label_item_name' + (k + 1)];
          if (!d) { if (icon) icon.visible = false; if (name) name.visible = false; return; }
          if (name) { name.setText(clean(d[2])); const room = 150; if (name.w > room) name.sx = name.sy = Math.max(0.5, room / name.w); }
          const qf = HB.qualityFrame('small', Math.max(1, d[4] || 1)); if (qf && icon) icon.setFrame(qf);
          const pic = HB.frameByName('small_' + d[3]) || HB.frameByName(d[3]) || HB.frameByName('icon_' + d[3]);
          if (pic && icon) { const sp = new HB.Sprite(pic); const q = Math.min((icon.w - 12) / (pic.sw || 1), (icon.h - 12) / (pic.sh || 1)); sp.sx = sp.sy = q; sp.x = icon.w / 2; sp.y = icon.h / 2; icon.add(sp); }
        });
        const got = () => Math.floor(mask / 2 ** g[0]) % 2 === 1, can = steps >= g[2];
        const state = () => { const l = c.label_get_title; l.sx = l.sy = 1; l.setText(got() ? 'Claimed' : 'Claim'); if (l.w > 96) l.sx = l.sy = 96 / l.w; c.btn_scale_sprite.grey = got() || !can; };
        state();
        tap(c.btn_scale_sprite, async () => {
          if (got()) return ui.tip('Already claimed', 1.3);
          if (!can) return ui.tip('Win ' + g[2] + ' rounds first (you have ' + steps + ')', 1.8);
          ui.loading(true);
          let r; try { r = await HB.api('rl_w_dup', { Cmd: 3101, AwardID: g[0] }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
          ui.loading(false);
          if (r.code) return ui.tip(ui.errorText(r), 2);
          mask += 2 ** g[0]; state();
          if (HB.game.loadItems) await HB.game.loadItems();
          await HB.game.refresh();
          const cards = HB.awards ? HB.awards(r) : [];
          if (cards.length && HB.showCards) await HB.showCards(cards, 'You got'); else ui.tip('Claimed', 1.5);
        });
        return cell;
      });
    }
    show(tab || 0);
  }

  async function floor(chap) {
    const ui = HB.ui, x = ui.x, st = await load();
    if (!st) return;
    const mine = st.open.find((f) => f.chap === chap) || { chap, process: 1 };
    const rounds = st.floors.rows.filter((r) => r[2] === chap).sort((a, b) => a[0] - b[0]); // [2] = the floor, its seven rounds in id order (it read [1], the row's own number: one round only)
    const o = {};
    HB.game.showSub('sub_ui/TowerLevelView', o);
    const n = o.n;
    if (n.label_TowerLevelView0) n.label_TowerLevelView0.setText('Defeat:');
    if (n.label_TowerLevelView1) n.label_TowerLevelView1.setText('Drop:');
    if (n.label_boxdesc) n.label_boxdesc.setText('Mystery Treasure');
    const story = clean(((await ui.table('rushtower')).rows.find((r) => r[0] === chap) || [])[7]); // the floor's own words (rushtower m_towerdesc)
    const show = () => {
      const r = rounds[6] || []; // the box on top shows the boss round's exp and silver whatever round you are on (phone)
      n.label_exp.setText(String(r[20] || 0)); n.label_silver.setText(String(r[21] || 0));
      if (n.label_levelinfo) { if (n.node_levelinfo) n.label_levelinfo.dims = [n.node_levelinfo.w, 0]; n.label_levelinfo.setText(story || 'Floor ' + chap); }
      for (let i = 1; i <= 7; i++) { const f = n['sprite_fight_icon' + i]; if (f) f.visible = false; }
    };
    for (let i = 1; i <= 7; i++) {
      const r = rounds[i - 1] || [], id = '0' + i, inf = HB.info(1, r[4]);
      const name = n['label_name' + id]; if (name) name.setText(r[4] ? inf.name : '');
      const holder = n['node_icon' + id], pic = r[4] && HB.iconFrame(1, inf.icon, i === 7);
      const grey = i > mine.process; // a round you cannot fight yet is grey (phone)
      if (i === 7 && n.sprite_boss_frame && pic) { // the boss: its big picture filling the card frame of its stars
        const bf = n.sprite_boss_frame, qf = HB.qualityFrame('middle', inf.quality); if (qf) bf.setFrame(qf);
        const sp = new HB.Sprite(pic); const k = Math.min((bf.w - 4) / (pic.sw || 1), (bf.h - 4) / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = bf.w / 2; sp.y = bf.h / 2; sp.z = 1; if (grey) sp.grey = true; bf.add(sp);
      } else if (holder && pic) { const sp = new HB.Sprite(pic); const k = Math.min(holder.w / (pic.sw || 1), holder.h / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; if (grey) sp.grey = true; holder.add(sp); }
      const beat = n['sprite_beat' + i]; if (beat) beat.visible = mine.process > i;
    }
    show();
    o.onButton = async (sel) => {
      if (sel === 'BtnBack') return HB.screens.tower();
      const m = /^BtnIconClick0(\d)$/.exec(sel);
      if (!m) return;
      const round = Number(m[1]);
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
