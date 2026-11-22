// Team (the bottom bar's 2nd button): CMyGroupView (sub_ui/ListMyTeamView.ccbi) with one CMyGroupCardView per place
// (sub_ui/TeamNinjaView.ccbi). A place shows one of its three layers, like the phone (CMyGroupCardView::InitUI):
//   layer_ninja  a shinobi with its numbers and eight slots (weapon, armor, trinket, seal, four ninjutsu), or the empty "To Battle" card
//   layer_tip    the next place that is still locked: what opens it (newcardinfo [2], [3]) and, when a training stage is asked,
//                where you are now + Go Train
//   layer_suit   the last place: the colour set and the level set of this line-up (suit_info)
// The numbers are the server's (rl_r_mainpage <ninjalist> / <suitlist> for Team 1, <defenseninjalist> / <defensesuitlist> for Team 2).
// Changing: rl_w_ninjalist Cmd 2300 OldID NewID TeamId (swap or add a shinobi), Cmd 2301-2308 Seq NewID TeamId (put card NewID
// into slot kind Cmd-2300 of place Seq; 0 = take it off), Cmd 2310 ActiveId (use this team). Then the main page is read again, so
// the top bar and every place show what the server counted.
// Taps like the phone: the shinobi's picture = its details with Change; a filled slot = the card's details with Change / Take off
// (weaponClick ... skillClick4 open CEquipDetailView, markClick CMarkDetailView); an empty slot or the empty card = the list to choose from.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' };
  // slot kind -> [the layout's box, card types that fit]
  const SLOTS = [[1, 'sprite_weaponicon', [2]], [2, 'sprite_armoricon', [3]], [3, 'sprite_accesicon', [4]], [4, 'sprite_markicon', [5]],
    [5, 'sprite_skill1', [6]], [6, 'sprite_skill2', [6]], [7, 'sprite_skill3', [6]], [8, 'sprite_skill4', [6]]];
  const TEAM2_LEVEL = 100; // normalconfig 211 (the server's game.TEAM2_LEVEL)
  // CMyGroupView::initSuitBtnAnim: the two round buttons wear the colour of the running set (suit_info [3]: stars 4 / 5 / 6, growth 6 / 9 / 12)
  const SUIT_BTN = { 1: { 3: 'suit_green', 4: 'suit_blue', 5: 'suit_purple', 6: 'suit_orange' }, 2: { 6: 'suit_sun_green', 9: 'suit_sun_blue', 12: 'suit_sun_purple' } };
  const SUIT_CARD = { 4: 'card_green', 5: 'card_blue', 6: 'card_purple' };
  const DETAIL = ['Description of attacking team line-up', // util/localizable.lua ui_active_team_title / ui_active_team_desc
    '1, When the second team line-up has reached level 100, it is activated.\n2, The second team can use all Shinobi, ninjitsus, and equipments. (can combine with the first team)\n3, On the team page, click on "activate team" button, and the line-up will be used. There can only be one line-up active at any given time.\n4, The current team used has a tick symbol given.'];
  const clean = (s) => String(s ?? '').replace(/\0+$/, '').trim();
  const tap = (node, fn) => { if (!node) return; node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const keep = { team: -1, y: null }; // where the list stood, so a change does not jump back to the top (the phone keeps its offset too)

  HB.screens.team = async function team(teamId) {
    const ui = HB.ui, x = ui.x;
    if (teamId === undefined || teamId === null) teamId = HB.data.activeTeam; // the phone opens on the line-up in use
    teamId = Number(teamId) === 1 ? 1 : 0;
    ui.loading(true);
    const [suitT, matchT, skillT] = await Promise.all([ui.table('suit_info'), ui.table('ninjamatch'), ui.table('skill_suit_info'), HB.data.tables(), HB.loadCCB('sub_ui/ListMyTeamView'), HB.loadCCB('sub_ui/TeamNinjaView')]);
    ui.loading(false);
    const D = HB.data, level = Number((HB.game.user || {}).level) || 1, suitRows = skillT.rows;
    if (teamId === 1 && level < TEAM2_LEVEL) { ui.tip('Team 2 opens at level ' + TEAM2_LEVEL, 1.8); teamId = 0; }
    const o = {};
    HB.game.showSub('sub_ui/ListMyTeamView', o, 'btn_maingroup');
    const n = o.n;
    const list = teamId === 1 ? D.teamDef : D.team;
    // what data.js does not keep: the sets of each line-up and each place's chains (running ones and ones that only miss a partner)
    const main = HB.game.main;
    const suitIds = x.all(x.first(main, teamId === 1 ? 'defensesuitlist' : 'suitlist'), 'item').map((i) => Number(x.a(i, 'id', 0)));
    const suits = {}; for (const id of suitIds) { const r = suitT.rows.find((s) => s[1] === id); if (r) suits[r[2]] = r; }
    const chains = {};
    for (const nj of x.all(x.first(main, teamId === 1 ? 'defenseninjalist' : 'ninjalist'), 'ninja')) {
      const ids = (tag) => x.all(x.first(nj, tag), 'combin').map((c) => x.n(c, 'combinid'));
      chains[x.n(nj, 'seq')] = { active: ids('combinlist'), ready: ids('readycombinlist') };
    }

    // ---- the bar on top: tabs, the tick on the used team, Activate, Detail, the two set buttons
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    for (const [b, id] of [[n.ctrl_firstTeam, 0], [n.ctrl_secondTeam, 1]]) if (b) { b.frames[1] = id === teamId ? tabOn || tabOff : tabOff; b.labelAnchor = [0.42, 0.3]; b.titleSize = Math.max(b.titleSize, 22); b.setTitle('Team ' + (id + 1)); }
    if (n.sprite_gou1) n.sprite_gou1.visible = D.activeTeam !== 1;
    if (n.sprite_gou2) n.sprite_gou2.visible = D.activeTeam === 1;
    if (n.btn_active_team) n.btn_active_team.setTitle('Activate');
    if (n.btn_active_desc) n.btn_active_desc.setTitle('Detail');
    for (const [type, btn, num] of [[1, n.color_suit_btn, n.label_color_num], [2, n.level_suit_btn, n.label_level_num]]) {
      const r = suits[type], f = r && HB.frameByName(SUIT_BTN[type][r[3]]);
      if (f && btn) { btn.frames[1] = btn.frames[2] = f; btn.layout(); }
      if (btn) btn.opacity = r ? 255 : 110; // no set yet: the phone greys the button
      if (num) { num.visible = !!r; if (r) num.setText(String(r[4])); }
    }

    const send = async (params) => {
      ui.loading(true);
      let r;
      try { r = await HB.api('rl_w_ninjalist', { ...params, TeamId: teamId }); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return false; }
      if (r.code) { ui.loading(false); ui.tip(ui.errorText(r)); return false; }
      HB.game.lastTeamReply = r; // for checks: the server's own numbers after this change
      await HB.game.refresh();
      ui.loading(false);
      keep.team = teamId; keep.y = col.y;
      HB.screens.team(teamId);
      return true;
    };
    o.onButton = (sel) => {
      if (sel === 'BtnBack') return HB.game.goHome();
      if (sel === 'BtnFirstTeam') return teamId === 0 ? null : HB.screens.team(0);
      if (sel === 'BtnSecTeam') return teamId === 1 ? null : HB.screens.team(1);
      if (sel === 'BtnActiveTeam') {
        if (D.activeTeam === teamId) return ui.tip('This team is already the one in use', 1.5);
        return send({ Cmd: 2310, ActiveId: teamId });
      }
      if (sel === 'BtnDesc') return showDetail();
      if (sel === 'colorSuitBtn') return showSuit('ShowColorSuitView');
      if (sel === 'levelSuitBtn') return showSuit('ShowLevelSuitView');
    };
    // Detail = ShowCommonDialogBox.lua showDialogBoxForActiveTeam: the big common window with the game's own text
    async function showDetail() {
      const w = { onButton: () => w.close() };
      await HB.dialog('dlg_ui/CommonDialogViewBig', w);
      const d = w.n;
      d.labelTitle.setText(DETAIL[0]); d.labelDescription.setText(DETAIL[1]);
      d.leftButton.setTitle('OK'); d.rightButton.setTitle('Close');
      if (d.layer_protect) d.layer_protect.visible = false;
    }
    // the two set lists are the game's own Lua windows (ui_colorSuitView / ui_levelSuitView), laid over this screen
    // (activitySubmenHelper.lua ShowColorSuitView / ShowLevelSuitView add them to the window layer; the helper script is run here
    // when no Lua screen was opened before)
    function showSuit(fn) {
      try {
        if (HB.L && HB.L.get(fn) === undefined && HB.luaRun) HB.luaRun('activitySubmenHelper.lua');
        if (HB.L && HB.L.get(fn) !== undefined) {
          HB.luaGlobal(fn);
          // the script's own X and Confirm do not get our taps (its touch layer takes them first): a tap anywhere closes the window (ours)
          const layer = HB.scene.children.filter((c) => c.z === 500 && c.isLayer).pop(), win = layer && layer.children[layer.children.length - 1];
          if (win && HB.luaTouchBegan) {
            const began = HB.luaTouchBegan;
            HB.luaTouchBegan = function () { HB.luaTouchBegan = began; if (win.parent) { if (HB.luaLeave) HB.luaLeave(win); win.removeSelf(); } return true; };
          }
          return;
        }
      } catch (e) { if (HB.luaError) HB.luaError(e); }
      ui.tip('This window cannot open yet', 1.5);
    }

    // ---- the places
    const box = n.node_tablecontent, cellSize = n.node_cardcontent;
    const maxTeam = Math.max(1, D.maxTeam || 1);
    const places = list.map((t) => ({ kind: 'ninja', t }));
    for (let i = list.length; i < maxTeam; i++) places.push({ kind: 'ninja', t: null });
    const nextRow = HB.row('newcardinfo', maxTeam + 1);
    if (nextRow) places.push({ kind: 'tip', row: nextRow });
    places.push({ kind: 'suit' });
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = places.length * cellSize.h;
    const inTeam = new Set(list.map((t) => t.seq)); // shinobi of this line-up
    const worn = new Set(); for (const t of list) { t.gear.forEach((s) => s && worn.add(s)); t.jutsu.forEach((s) => s && worn.add(s)); } // Team 2 may use what Team 1 wears
    places.forEach((p, i) => {
      const co = {};
      const cell = HB.build('sub_ui/TeamNinjaView', co, [cellSize.w, cellSize.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - cellSize.w) / 2; cell.y = col.h - (i + 1) * cellSize.h; cell.w = cellSize.w; cell.h = cellSize.h;
      const m = co.n;
      if (m.layer_ninja) m.layer_ninja.visible = p.kind === 'ninja';
      if (m.layer_tip) m.layer_tip.visible = p.kind === 'tip';
      if (m.layer_suit) m.layer_suit.visible = p.kind === 'suit';
      if (p.kind === 'ninja') fill(m, p.t);
      else if (p.kind === 'tip') fillTip(co, p.row);
      else fillSuit(m);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    if (keep.team === teamId && keep.y !== null) col.y = Math.max(Math.min(0, scroll.h - col.h), Math.min(Math.max(0, scroll.h - col.h), keep.y));
    keep.team = -1; keep.y = null;
    box.add(scroll);
    HB.screens.team.state = { teamId, places: places.map((p) => p.kind + (p.t ? ':' + p.t.seq : '')), suits: Object.values(suits).map((r) => r[1]) }; // for tests

    // skill_suit_info: [3] kind 1 = four ninjutsu ids, 2 = weapon, armor, trinket, seal ids ([4]..[7])
    function skillSuit(c) { return suitRows.find((r) => (c.type === 6 ? r[3] === 1 && r.slice(4, 8).includes(c.id) : r[3] === 2 && r[4 + [2, 3, 4, 5].indexOf(c.type)] === c.id)) || null; }
    function fill(m, t) {
      const card = t && D.card(t.seq);
      const pickNinja = async () => {
        const c = await HB.pickCard({ types: [1], exclude: (k) => inTeam.has(k.seq) });
        if (c) send({ Cmd: 2300, OldID: card ? card.seq : 0, NewID: c.seq });
      };
      if (!card) { // an open place without a shinobi: the "To Battle" card
        m.sprite_noninja.visible = true; m.sprite_ninjaicon.visible = false;
        for (const [, name] of SLOTS) if (m[name]) m[name].visible = false;
        for (const k of ['label_ninjaname', 'label_ninjaattack', 'label_ninjadefense', 'label_ninjacharkra', 'label_ninjagroup', 'layer_morecom', 'label_tupo_level', 'sprite_star01', 'sprite_star02', 'sprite_star03', 'sprite_star04', 'sprite_star05']) if (m[k]) m[k].visible = false;
        tap(m.sprite_noninja, pickNinja);
        return;
      }
      if (m.sprite_noninja) m.sprite_noninja.visible = false;
      const inf = HB.info(1, card.id);
      m.label_ninjaname.setText(inf.name);
      m.label_ninjaattack.setText(t.atk[0] + '-' + t.atk[1]);
      m.label_ninjadefense.setText(t.def[0] + '-' + t.def[1]);
      m.label_ninjacharkra.setText(t.chakra[0] + '-' + t.chakra[1]);
      // chains: running / all this shinobi has ('%d/%d' on the phone)
      const mine = matchT.rows.filter((r) => r[3] === card.id), ch = chains[t.slot] || { active: [], ready: [] };
      m.label_ninjagroup.setText(ch.active.length + '/' + mine.length);
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
      HB.cardDress(m, card, 'middle'); // reborn corners, dragon mark, glow, exp bar / "Max"
      // a chain that only misses its partner in the team (CMyGroupCardView::initReadyCombin): the strip under the card names it
      const ready = ch.ready.map((id) => matchT.rows.find((r) => r[1] === id)).filter(Boolean)[0];
      m.layer_morecom.visible = !!ready;
      if (ready && m.label_morecom) m.label_morecom.setText(clean(ready[4]));
      tap(m.sprite_ninjaicon, () => HB.screens.details(card, { onChange: pickNinja, team: t, chains: ch.active }));
      // the eight slots
      const seqs = [...t.gear, ...t.jutsu];
      SLOTS.forEach(([kind, name, types], i) => {
        const slot = m[name]; if (!slot) return;
        const c = D.card(seqs[i]);
        const tip = m['sprite_tip' + kind], bar = m['sprite_equipbar' + kind], lvl = m['label_equip' + kind], grade = m['label_grade' + kind], holder = m['node_icon' + kind];
        if (grade) grade.visible = false;
        const old = slot.children.filter((k) => k._suit); old.forEach((k) => k.removeSelf());
        const choose = async () => {
          const pick = await HB.pickCard({ types, exclude: (k) => worn.has(k.seq) });
          if (pick) send({ Cmd: 2300 + kind, Seq: t.slot, NewID: pick.seq });
        };
        if (c) {
          const ci = HB.info(c.type, c.id);
          const f = HB.qualityFrame('small', ci.quality); if (f) slot.setFrame(f);
          const pic = HB.iconFrame(c.type, ci.icon);
          if (pic && holder) { const sp = new HB.Sprite(pic); const k = Math.min((holder.w - 12) / pic.sw, (holder.h - 12) / pic.sh); sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp); }
          if (tip) tip.visible = false;
          if (lvl) lvl.setText('Lv::' + c.level); // two colons, as the phone writes it here
          if (grade && c.newlife > 0 && (c.type === 2 || c.type === 3)) { grade.visible = true; grade.setText('+' + c.newlife); } // an advanced weapon / armor: +N
          // a card of a ninjutsu set or a gear set wears the "Suit" ribbon in its colour (CMyGroupCardView::setEquipSuitIconTitle:
          // ccbResources/equip_suit.plist icon_title_<colour>); with two or more of the set in this place a light runs round it
          const set = skillSuit(c);
          if (set) {
            const rf = HB.frameByName('icon_title_' + (['yellow', 'green', 'blue', 'purple', 'orange'][ci.quality - 2] || 'yellow'));
            if (rf) { const rb = new HB.Sprite(rf); rb._suit = true; rb.x = rf.sw / 2; rb.y = slot.h - rf.sh / 2; rb.z = 5; slot.add(rb); }
            const worn = seqs.map((s) => D.card(s)).filter((k) => k && skillSuit(k) === set).length;
            if (worn >= 2) HB.loadCCB('animations/suit_light_round').then(() => { if (!slot.parent) return; const g = HB.build('animations/suit_light_round', {}, [slot.w, slot.h]); g._suit = true; g.z = 6; g.x = g.ignoreAnchor ? 0 : g.ax * g.w; g.y = g.ignoreAnchor ? 0 : g.ay * g.h; slot.add(g); }).catch(() => {});
          }
          tap(slot, () => HB.screens.details(c, { onChange: choose, onRemove: () => send({ Cmd: 2300 + kind, Seq: t.slot, NewID: 0 }) }));
        } else {
          if (bar) bar.visible = false;
          tap(slot, choose);
        }
      });
    }

    // the next place, still locked: what opens it; with a training stage asked, where you are now and Go Train
    function fillTip(co, row) {
      const m = co.n;
      const lines = [clean(row[2]), clean(row[3])].filter(Boolean).map((s) => s.replace(/\s+/g, ' '));
      if (m.label_param1) { m.label_param1.dims = [400, 0]; m.label_param1.size = 22; m.label_param1.setText('Next place opens:\n' + lines.join('\n')); }
      const stage = row[7] > 0;
      if (m.node_exp_limit) m.node_exp_limit.visible = stage;
      if (!stage) return;
      // the row reads "Current chapter: <n>, round <m>"; the layout's own pieces are Chinese words around two numbers
      const ch = HB.game.chap || { cur: 1, stage: 1 };
      (co.all.label_cur_chapter || []).concat(m.label_TeamNinjaTipView0 || [], m.label_TeamNinjaTipView1 || [], m.label_cur_chapter_sub || []).forEach((l) => { l.visible = false; });
      const lim = m.node_exp_limit, now = new HB.Label('Now: chapter ' + ch.cur + ', round ' + ch.stage, 'Arial-BoldMT', 22, [0, 0], 1, 1);
      now.color = [110, 70, 20]; now.x = lim.w / 2; now.y = lim.h - 30; lim.add(now);
      co.onButton = (sel) => { if (sel === 'click_goto' && HB.screens.training) HB.screens.training(); };
    }

    // the sets of this line-up: per kind the running set with what it gives, then the next two to reach ("not active yet")
    function fillSuit(m) {
      const pct = (v) => Math.round(v * 100) + '%';
      for (const [type, key] of [[1, 'color'], [2, 'level']]) {
        const r = suits[type];
        const rows = suitT.rows.filter((s) => s[2] === type && s[1] <= 48); // rows 49-56 repeat 41-48 with Chinese names
        const set = (k, v) => { const l = m['label_' + key + '_' + k]; if (l) l.setText(v); };
        set('param', r ? clean(r[12]) : 'No ' + (type === 1 ? 'star' : 'growth') + ' set yet');
        ['ATK +', 'DEF +', 'Chakra +', 'ATK +', 'DEF +', 'Chakra +'].forEach((t, i) => set('desc_' + (i + 1), t));
        [5, 7, 9].forEach((c, i) => set('param' + (i + 1), r ? String(r[c]) : '0'));
        [6, 8, 10].forEach((c, i) => set('param' + (i + 4), r ? pct(r[c]) : '0%'));
        const better = rows.filter((s) => !r || s[5] > r[5] || (s[5] === r[5] && s[6] > r[6])).sort((a, b) => a[5] - b[5] || a[6] - b[6]);
        set('param7', better[0] ? clean(better[0][12]) : ''); set('param8', better[1] ? clean(better[1][12]) : '');
        const title = m['label_TeamNinjaSuitView' + (type - 1)]; if (title) title.setText(better.length ? 'Not active yet:' : '');
      }
      const r = suits[1], f = HB.frameByName((r && SUIT_CARD[r[3]]) || 'card_green');
      if (f && m.node_card) { const sp = new HB.Sprite(f); const k = Math.min(m.node_card.w / (f.sw || 1), m.node_card.h / (f.sh || 1)); sp.sx = sp.sy = k; sp.x = m.node_card.w / 2; sp.y = m.node_card.h / 2; if (!r) sp.opacity = 110; m.node_card.add(sp); }
    }
  };
})();
