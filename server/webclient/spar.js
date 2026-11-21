// Spar (the bottom bar's 5th button): CFightListView (sub_ui/FightListView.ccbi) with one CFightNinjaView per rival
// (sub_ui/FightNinjaView.ccbi), the preview window (sub_ui/FightPreView.ccbi) and the fight itself (fight.js).
// Rivals: rl_r_pk (a <user> per rival: id, nick, level, attack, firstninja + its stars, coin). Fight: rl_w_pvp Cmd 2701 ToUid.
// What a fight pays is the game's own duelinfo table picked by the RIVAL's level, like the phone's preview shows it:
// [5] / [6] exp for a win / loss, [7] / [8] war achievements, [3] share of the rival's silver won, [4] share of yours lost.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };

  HB.screens.spar = async function spar() {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let list, duel;
    try {
      [list, duel] = await Promise.all([HB.api('rl_r_pk', { Cmd: 2700 }), ui.table('duelinfo'), HB.data.tables(), HB.loadCCB('sub_ui/FightListView'), HB.loadCCB('sub_ui/FightNinjaView'), HB.loadCCB('sub_ui/FightPreView')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (list.code) return ui.tip(ui.errorText(list));
    const o = {};
    HB.game.showSub('sub_ui/FightListView', o, 'btn_mainfight');
    const n = o.n;
    if (n.label_FightListView0) n.label_FightListView0.setText('Spar');
    if (n.btn_more_fights) n.btn_more_fights.setTitle('Refresh opponents');
    o.onButton = (sel) => { if (sel === 'clickMoreFights') return spar(); ui.tip('Coming soon: ' + (sel === 'searchHandler' ? 'Search' : sel), 1.2); };
    const duelRows = duel.rows.filter((r) => r[0] === r[2]);
    const pay = (level) => duelRows.find((r) => r[0] === level) || duelRows[duelRows.length - 1] || [];
    const rivals = x.all(list, 'user').map((u) => Object.fromEntries([...u.children].map((c) => [c.nodeName, c.textContent])));

    const box = n.node_tablecontent, size = n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rivals.length) * size.h;
    rivals.forEach((r, i) => {
      const co = {};
      const cell = HB.build('sub_ui/FightNinjaView', co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      row(co.n, r);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);

    function row(m, r) {
      const d = pay(Number(r.level));
      m.label_name.setText(r.nick);
      if (m.label_FightNinjaView0) m.label_FightNinjaView0.setText('Win:');     // a capital like the words around it (W.A. = war achievements, the game's own short form)
      m.label_level.setText(String(r.level));
      m.label_attack.setText(r.attacklow + '-' + r.attackhigh);
      m.label_merit.setText(String(d[7] || 0));
      m.label_coin.setText(String(Math.round(Number(r.coin || 0) * (d[3] || 0))));
      if (m.node_merit_container) m.node_merit_container.visible = false;
      for (const k of ['node_inlay_frame', 'node_shadow_back', 'node_shadow_front']) if (m[k]) m[k].visible = false;
      const inf = HB.info(1, r.firstninja);
      const frame = HB.qualityFrame('ninjaSmall', Math.max(inf.quality, Math.min(6, Number(r.firstninjastar) || 1)));
      if (frame) m.sprite_ninjaicon.setFrame(frame);
      const pic = HB.iconFrame(1, inf.icon);
      if (pic && m.node_icon) { const sp = new HB.Sprite(pic); const k = Math.min(m.node_icon.w / (pic.sw || 1), m.node_icon.h / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = m.node_icon.w / 2; sp.y = m.node_icon.h / 2; m.node_icon.add(sp); }
      tap(m.sprite_btn_fight, () => preview(r, d));
    }
    // the preview window: what a win and a loss pay, Spar / Run away
    async function preview(r, d) {
      const me = HB.game.user || {};
      const w = { onButton: (sel) => { w.close(); if (sel === 'BtnFight') fight(r, d); } };
      await HB.dialog('sub_ui/FightPreView', w);
      const m = w.n;
      m.label_myname.setText(me.nick || ''); m.label_enemyname.setText(r.nick);
      m.label_winexp.setText(String(d[5] || 0)); m.label_failexp.setText(String(d[6] || 0));
      m.label_winmerit.setText(String(d[7] || 0)); m.label_failmerit.setText(String(d[8] || 0));
      m.label_winsilver.setText(String(Math.round(Number(r.coin || 0) * (d[3] || 0))));
      m.label_failsilver.setText(String(Math.min(1000, Math.round(Number(me.coin || 0) * (d[4] || 0))))); // a loss costs at most 1000 silver (normalconfig 89)
      if (m.sprite_markicon) m.sprite_markicon.visible = false;
      m.ctrl_fight.setTitle('Spar'); m.ctrl_qiut.setTitle('Run away');
    }
    async function fight(r, d) {
      ui.loading(true);
      let reply;
      try { reply = await HB.api('rl_w_pvp', { Cmd: 2701, ToUid: r.id }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
      ui.loading(false);
      if (reply.code) return ui.tip(ui.errorText(reply));
      const won = Number(x.a(x.first(x.first(reply, 'fight'), 'preview'), 'result', 0)) === 1;
      await HB.fight.play(reply, { kind: 'spar', exp: won ? d[5] : d[6], silver: won ? Math.round(Number(r.coin || 0) * (d[3] || 0)) : 0, energy: 0 });
      await HB.game.refresh();
      spar();
    }
  };
})();
