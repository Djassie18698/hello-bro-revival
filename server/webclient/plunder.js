// Plunder (Home > Plunder, from the level in functionconfig 2): the seal list CMarksListView (sub_ui/MarkListView.ccbi) with one
// CMarkCardView per tailed-beast seal (sub_ui/MarkMergaView.ccbi: the seal, its fragments with how many you hold, Merge / Get),
// the rivals to plunder a fragment from CPlunderListView (sub_ui/PlunderListView.ccbi + PlunderNinjaView.ccbi), the preview
// (sub_ui/PlunderPreView.ccbi) and the fight (fight.js).
// Requests: rl_r_markchip (<chiplist><chip><id><count>, <markmerge><mark><id><resttime> = syntheses running or finished, <cash> = the
// gold price of finishing one at once), rl_w_markchip Cmd 2800 MarkID [UseCash=1] (start / finish now), Cmd 2801 MarkID (take the
// seal), rl_r_pk (rivals), rl_w_pvp Cmd 2701 ToUid Chip=<fragment> (the fight; the answer's <message> says a fragment was taken).
// Tables: markmerge ([0] seal, [3]-[10] its fragments), plunderinfo (chance words by level difference, like CPlunderCardView::InitUI),
// playerlevel of MY level ([8] / [9] exp for a win / loss, [10] / [11] silver), as the phone's preview shows.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const two = (n) => String(n).padStart(2, '0');
  const clock = (s) => two(Math.floor(s / 3600)) + ':' + two(Math.floor(s / 60) % 60) + ':' + two(s % 60);
  const clean = (s) => String(s ?? '').replace(/\0+$/, '').trim();
  let at = 0; // how far the seal list was scrolled, kept while you go plundering

  async function send(cgi, params) {
    const ui = HB.ui;
    ui.loading(true);
    let r;
    try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
    ui.loading(false);
    if (r.code) { ui.tip(ui.errorText(r)); return null; }
    return r;
  }
  // a picture fitted into a holder sprite
  function fit(holder, frame, pad = 0, z = 1) {
    if (!holder || !frame) return null;
    const sp = new HB.Sprite(frame); const k = Math.min((holder.w - pad) / (frame.sw || 1), (holder.h - pad) / (frame.sh || 1));
    sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; sp.z = z; holder.add(sp);
    return sp;
  }

  HB.screens.plunder = async function plunder(keep) {
    const ui = HB.ui, x = ui.x;
    if (!keep) at = 0;
    ui.loading(true);
    let reply, merges;
    try {
      [reply, merges] = await Promise.all([HB.api('rl_r_markchip', { Cmd: 2800 }), ui.table('markmerge'), ui.table('plunderinfo'), HB.data.tables(), HB.loadCCB('sub_ui/MarkListView'), HB.loadCCB('sub_ui/MarkMergaView'),
        HB.loadCCB('sub_ui/PlunderListView'), HB.loadCCB('sub_ui/PlunderNinjaView'), HB.loadCCB('sub_ui/PlunderPreView')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const have = new Map(x.all(x.first(reply, 'chiplist'), 'chip').map((c) => [x.n(c, 'id'), x.n(c, 'count')]));
    const running = new Map(x.all(x.first(reply, 'markmerge'), 'mark').map((m) => [x.n(m, 'id'), x.n(m, 'resttime')]));
    const cash = x.n(reply, 'cash') || 30, born = Date.now();
    const o = {};
    HB.game.showSub('sub_ui/MarkListView', o);
    const n = o.n;
    o.onButton = (sel) => { if (sel === 'BtnBack') return HB.game.goHome(); };
    const box = n.node_tablecontent, size = n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, merges.rows.length) * size.h;
    merges.rows.forEach((row, i) => {
      const co = {};
      const cell = HB.build('sub_ui/MarkMergaView', co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      seal(co.n, row);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    if (at) scroll.scrollBy(0, Math.min(at, Math.max(0, col.h - scroll.h)));
    const remember = () => { at = Math.max(0, col.y - (scroll.h - col.h)); };

    function seal(m, row) {
      const id = row[0], inf = HB.info(5, id), frags = row.slice(3, 11).filter((f) => f > 0);
      m.label_markname.setText(inf.name);
      m.label_desc.setText(clean(inf.desc));
      const qf = HB.qualityFrame('middle', inf.quality); if (qf) m.sprite_mark_frame.setFrame(qf);
      fit(m.sprite_mark_frame, HB.frameByName(inf.icon) || HB.frameByName('small_' + inf.icon), 36, 1);
      const sets = Math.min(...frags.map((f) => have.get(f) || 0));
      m.label_chip_count.setText(String(HB.data.ofType(5).filter((c) => c.id === id).length)); // the seals of this kind you own
      for (let k = 1; k <= 8; k++) {
        const slot = m['sprite_btn' + k], f = frags[k - 1];
        if (!slot) continue;
        if (!f) { slot.parent.visible = false; continue; }
        const count = have.get(f) || 0, fi = HB.info(5, f);
        const pic = fit(slot, HB.frameByName('small_' + fi.icon) || HB.frameByName(fi.icon), 14);
        if (pic && !count) pic.opacity = 110;
        m['label_chip' + k].setText(String(count));
        const tip = m['sprite_tipgetit' + k];
        if (tip) { tip.visible = !count; const l = m['label_MarkMergaView' + (k - 1)]; if (l) { l.size = 20; l.setText('Plunder'); } }
        tap(slot, () => { remember(); rivals(f); });
      }
      // the button under the seal: Merge (all fragments), Get (a finished synthesis); a running one shows its clock and "finish now"
      const left = running.has(id) ? running.get(id) : -1;
      const busy = left > 0, ready = left === 0;
      m.label_merge.visible = !ready; m.label_get.visible = ready;
      for (const k of ['label_countDown', 'label_time', 'btn_finish', 'label_MarkMergaView8']) if (m[k]) m[k].visible = busy;
      if (busy) {
        m.label_countDown.setText('Ready in:'); m.label_MarkMergaView8.setText('Finish now');
        (function tick() {
          if (!m.label_time.parent || !box.parent || !scroll.parent) return;
          const s = left - Math.floor((Date.now() - born) / 1000);
          if (s <= 0) return plunder(true);
          m.label_time.setText(clock(s)); HB.tween({}, {}, 1, tick);
        })();
        tap(m.btn_finish, async () => {
          if (!(await HB.confirm('Finish this seal now for ' + cash + ' gold?', { ok: 'Finish' }))) return;
          remember();
          if (await send('rl_w_markchip', { Cmd: 2800, MarkID: id, UseCash: 1 })) await take(id);
        });
      }
      tap(m.sprite_btn_com, async () => {
        remember();
        if (ready) return take(id);
        if (busy) return ui.tip('This seal is still being made', 1.5);
        if (sets < 1) return ui.tip('Collect all ' + frags.length + ' fragments first', 1.8);
        if (await send('rl_w_markchip', { Cmd: 2800, MarkID: id })) plunder(true);
      });
    }
    async function take(id) {
      const r = await send('rl_w_markchip', { Cmd: 2801, MarkID: id });
      if (!r) return plunder(true);
      await HB.game.refresh();
      await HB.showCards([{ type: 5, id, num: 1 }], 'Seal made');
      plunder(true);
    }

    // ------------------------------------------------------------ who to plunder a fragment from
    async function rivals(chip) {
      const list = await send('rl_r_pk', { Cmd: 2700, Chip: chip });
      if (!list) return;
      const me = HB.game.user || {}, myLevel = Number(me.level || 1);
      const lv = ui.tables.playerlevel.rows.find((r) => r[1] === myLevel) || [];
      const chance = (level) => { let key = level - myLevel; key = key === 0 ? 1 : key < 0 ? 300 - key : key; const r = ui.tables.plunderinfo.rows.find((q) => q[0] === key); return r ? clean(r[4]) : 'No'; };
      const p = {};
      HB.game.showSub('sub_ui/PlunderListView', p);
      const q = p.n, fi = HB.info(5, chip);
      if (q.label_PlunderListView0) q.label_PlunderListView0.setText('Plunder: ' + fi.name);
      if (q.btnMoreFights) q.btnMoreFights.setTitle('Refresh opponents');
      if (q.btn_back) q.btn_back.setTitle('Back');
      p.onButton = (sel) => { if (sel === 'BtnBack') return plunder(true); if (sel === 'clickMoreFights') return rivals(chip); };
      const rows = x.all(list, 'user').map((u) => Object.fromEntries([...u.children].map((c) => [c.nodeName, c.textContent])));
      const pbox = q.node_tablecontent, psize = q.node_cardcontent;
      const sc = new HB.ScrollView(); sc.dir = 1; sc.w = pbox.w; sc.h = pbox.h;
      const pc = new HB.Node(); pc.w = pbox.w; pc.h = Math.max(1, rows.length) * psize.h;
      rows.forEach((r, i) => {
        const co = {};
        const cell = HB.build('sub_ui/PlunderNinjaView', co, [psize.w, psize.h]);
        cell.ignoreAnchor = true; cell.x = (pbox.w - psize.w) / 2; cell.y = pc.h - (i + 1) * psize.h; cell.w = psize.w; cell.h = psize.h;
        const m = co.n;
        m.label_name.setText(r.nick); m.label_level.setText(String(r.level));
        m.label_attack.setText(r.attacklow + '-' + r.attackhigh);
        if (m.label_PlunderNinjaView0) m.label_PlunderNinjaView0.setText('Chance:');
        m.label_getratio.setText(chance(Number(r.level)));
        if (m.label_PlunderNinjaView3) m.label_PlunderNinjaView3.setText('Plunder');
        for (const k of ['node_inlay_frame', 'node_shadow_back', 'node_shadow_front']) if (m[k]) m[k].visible = false;
        const inf = HB.info(1, r.firstninja);
        const frame = HB.qualityFrame('ninjaSmall', Math.max(inf.quality, Math.min(6, Number(r.firstninjastar) || 1)));
        if (frame) m.sprite_ninjaicon.setFrame(frame);
        fit(m.node_icon, HB.iconFrame(1, inf.icon));
        tap(m.sprite_btn_plunder, () => preview(r));
        pc.add(cell);
      });
      sc.setContent(pc); pc.y = sc.h - pc.h;
      pbox.add(sc);

      async function preview(r) {
        const w = { onButton: (sel) => { w.close(); if (sel === 'BtnFight') fight(r); } };
        await HB.dialog('sub_ui/PlunderPreView', w);
        const m = w.n;
        m.label_myname.setText(me.nick || ''); m.label_enemyname.setText(r.nick);
        if (m.label_PlunderPreView1) m.label_PlunderPreView1.setText('Plunder preview');
        if (m.label_PlunderPreView0) m.label_PlunderPreView0.setText('You may take a fragment:');
        m.label_winexp.setText(String(lv[8] || 0)); m.label_failexp.setText(String(lv[9] || 0));
        m.label_winsilver.setText(String(lv[10] || 0)); m.label_failsilver.setText(String(Math.min(Number(me.coin || 0), lv[11] || 0)));
        const pic = HB.frameByName('small_' + fi.icon) || HB.frameByName(fi.icon);
        if (pic && m.sprite_markicon) { const k = Math.min(m.sprite_markicon.w / pic.sw, m.sprite_markicon.h / pic.sh) || 1; const sx = m.sprite_markicon.sx; m.sprite_markicon.setFrame(pic); m.sprite_markicon.sx = m.sprite_markicon.sy = sx * Math.min(1, k); }
        m.ctrl_fight.setTitle('Plunder'); m.ctrl_qiut.setTitle('Run away');
      }
      async function fight(r) {
        const reply2 = await send('rl_w_pvp', { Cmd: 2701, ToUid: r.id, Chip: chip });
        if (!reply2) return;
        const won = Number(x.a(x.first(x.first(reply2, 'fight'), 'preview'), 'result', 0)) === 1;
        const got = /plundered/i.test(x.t(reply2, 'message') || '');
        await HB.fight.play(reply2, { kind: 'plunder', exp: won ? lv[8] || 0 : lv[9] || 0, silver: won ? lv[10] || 0 : 0, energy: 0 });
        await HB.game.refresh();
        ui.tip(got ? 'You took ' + fi.name + '!' : won ? 'You won, but found no fragment' : 'Plunder failed', 2.2);
        if (got) return plunder(true);
        rivals(chip);
      }
    }
  };
})();
