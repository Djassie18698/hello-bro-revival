// Team (the bottom bar's 2nd button): CMyGroupView (sub_ui/ListMyTeamView.ccbi) with one CMyGroupCardView per place
// (sub_ui/TeamNinjaView.ccbi): the ninja, its numbers and its eight slots (weapon, armor, trinket, seal, four ninjutsu).
// The numbers are the server's (rl_r_mainpage <ninjalist> for Team 1, <defenseninjalist> for Team 2).
// Changing: rl_w_ninjalist Cmd 2300 OldID NewID TeamId (swap or add a ninja), Cmd 2301-2308 Seq NewID TeamId (put card NewID
// into slot kind Cmd-2300 of place Seq; 0 = take it out), Cmd 2310 ActiveId (use this team). Then the main page is read again.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' };
  // slot kind -> [the layout's box, card types that fit]
  const SLOTS = [[1, 'sprite_weaponicon', [2]], [2, 'sprite_armoricon', [3]], [3, 'sprite_accesicon', [4]], [4, 'sprite_markicon', [5]],
    [5, 'sprite_skill1', [6]], [6, 'sprite_skill2', [6]], [7, 'sprite_skill3', [6]], [8, 'sprite_skill4', [6]]];
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };

  HB.screens.team = async function team(teamId = 0) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    await Promise.all([HB.data.tables(), HB.loadCCB('sub_ui/ListMyTeamView'), HB.loadCCB('sub_ui/TeamNinjaView')]);
    ui.loading(false);
    const o = {};
    HB.game.showSub('sub_ui/ListMyTeamView', o, 'btn_maingroup');
    const n = o.n, D = HB.data;
    const list = teamId === 1 ? D.teamDef : D.team;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    for (const [b, id] of [[n.ctrl_firstTeam, 0], [n.ctrl_secondTeam, 1]]) if (b) { b.frames[1] = id === teamId ? tabOn || tabOff : tabOff; b.titles[1] = 'Team ' + (id + 1); b.layout(); }
    if (n.sprite_gou1) n.sprite_gou1.visible = D.activeTeam !== 1;
    if (n.sprite_gou2) n.sprite_gou2.visible = D.activeTeam === 1;
    if (n.btn_active_team) n.btn_active_team.setTitle('Activate');
    if (n.btn_active_desc) n.btn_active_desc.setTitle('Detail');
    for (const k of ['label_color_num', 'label_level_num']) if (n[k]) n[k].setText('0'); // gear set counters: later

    const send = async (params) => {
      ui.loading(true);
      let r;
      try { r = await HB.api('rl_w_ninjalist', { ...params, TeamId: teamId }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
      if (r.code) { ui.loading(false); return ui.tip(ui.errorText(r)); }
      await HB.game.refresh();
      ui.loading(false);
      HB.screens.team(teamId);
    };
    o.onButton = (sel) => {
      if (sel === 'BtnBack') return HB.game.goHome();
      if (sel === 'BtnFirstTeam') return HB.screens.team(0);
      if (sel === 'BtnSecTeam') return HB.screens.team(1);
      if (sel === 'BtnActiveTeam') return send({ Cmd: 2310, ActiveId: teamId });
      ui.tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2);
    };

    // the places: the team's ninjas, then one empty place while the team may still grow
    const box = n.node_tablecontent, cellSize = n.node_cardcontent;
    const places = list.map((t) => ({ t }));
    if (list.length < (D.maxTeam || 1)) places.push({ t: null });
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = places.length * cellSize.h;
    const used = new Set(); for (const t of [...D.team, ...D.teamDef]) { used.add(t.seq); t.gear.forEach((s) => used.add(s)); t.jutsu.forEach((s) => used.add(s)); }
    const mine = new Set(list.map((t) => t.seq));
    places.forEach((p, i) => {
      const co = {};
      const cell = HB.build('sub_ui/TeamNinjaView', co, [cellSize.w, cellSize.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - cellSize.w) / 2; cell.y = col.h - (i + 1) * cellSize.h; cell.w = cellSize.w; cell.h = cellSize.h;
      fill(co.n, p.t);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);

    function fill(m, t) {
      const card = t && D.card(t.seq);
      const pickNinja = async () => {
        const c = await HB.pickCard({ types: [1], exclude: (k) => mine.has(k.seq) });
        if (c) send({ Cmd: 2300, OldID: card ? card.seq : 0, NewID: c.seq });
      };
      if (!card) { // an empty place: "tap to add"
        m.sprite_noninja.visible = true; m.sprite_ninjaicon.visible = false;
        for (const [, name] of SLOTS) if (m[name]) m[name].visible = false;
        for (const k of ['label_ninjaname', 'label_ninjaattack', 'label_ninjadefense', 'label_ninjacharkra', 'label_ninjagroup', 'layer_morecom', 'label_tupo_level', 'sprite_star01', 'sprite_star02', 'sprite_star03', 'sprite_star04', 'sprite_star05']) if (m[k]) m[k].visible = false;
        tap(m.sprite_noninja, pickNinja);
        return;
      }
      const inf = HB.info(1, card.id);
      m.label_ninjaname.setText(inf.name);
      m.label_ninjaattack.setText(t.atk[0] + '-' + t.atk[1]);
      m.label_ninjadefense.setText(t.def[0] + '-' + t.def[1]);
      m.label_ninjacharkra.setText(t.chakra[0] + '-' + t.chakra[1]);
      m.label_ninjagroup.setText(String(t.combins));
      const fr = HB.qualityFrame('middle', inf.quality); if (fr) m.sprite_ninjaicon.setFrame(fr);
      const art = HB.iconFrame(1, inf.icon, true);
      if (art && m.layer_icon) { // the big picture, cut to the frame's window
        m.layer_icon.clip = true;
        const sp = new HB.Sprite(art); const k = Math.max(m.layer_icon.w / art.sw, m.layer_icon.h / art.sh);
        sp.sx = sp.sy = k; sp.x = m.layer_icon.w / 2; sp.y = m.layer_icon.h / 2; m.layer_icon.add(sp);
      }
      HB.showStars(m, ['sprite_star01', 'sprite_star02', 'sprite_star03', 'sprite_star04', 'sprite_star05'], Math.min(5, inf.quality));
      m.label_level.setText(String(card.level));
      const el = HB.frameByName(ELEMENT[card.attri] || ELEMENT[1]); if (el) m.sprite_ninjacamp.setFrame(el);
      const grow = card.starlevel > 0 && HB.frameByName('cards_level_small_' + card.starlevel);
      m.sprite_strength_level_frame.visible = m.sprite_strength_level_icon.visible = !!grow; if (grow) m.sprite_strength_level_icon.setFrame(grow);
      m.label_tupo_level.visible = card.tupo > 0; if (card.tupo > 0) m.label_tupo_level.setText('+' + card.tupo);
      m.node_inlay_frame.visible = false; m.sprite_dragon_icon.visible = false; m.layer_morecom.visible = false;
      tap(m.sprite_ninjaicon, pickNinja);
      // the eight slots
      const seqs = [...t.gear, ...t.jutsu];
      SLOTS.forEach(([kind, name, types], i) => {
        const slot = m[name]; if (!slot) return;
        const c = D.card(seqs[i]);
        const tip = m['sprite_tip' + kind], bar = m['sprite_equipbar' + kind], lvl = m['label_equip' + kind], grade = m['label_grade' + kind], holder = m['node_icon' + kind];
        if (grade) grade.visible = false;
        if (c) {
          const ci = HB.info(c.type, c.id);
          const f = HB.qualityFrame('small', ci.quality); if (f) slot.setFrame(f);
          const pic = HB.iconFrame(c.type, ci.icon);
          if (pic && holder) { const sp = new HB.Sprite(pic); const k = Math.min((holder.w - 12) / pic.sw, (holder.h - 12) / pic.sh); sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp); }
          if (tip) tip.visible = false;
          if (lvl) lvl.setText('Lv:' + c.level);
        } else if (bar) bar.visible = false;
        tap(slot, async () => {
          const pick = await HB.pickCard({ types, exclude: (k) => used.has(k.seq) });
          if (pick) send({ Cmd: 2300 + kind, Seq: t.slot, NewID: pick.seq });
        });
      });
    }
  };
})();
