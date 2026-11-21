// Custom events in the rewritten game (ours; owner, 21 Nov 2026: "I want to be able to add custom events easily").
// The events are small text files on the server (server/customevents.js, folder custom-events): this is their screen and the Home
// button that opens it. The button only stands on Home while at least one event runs; it shows a red dot when something can be taken.
// Requests: rl_x_custom Cmd 1 (the list), Cmd 2 Id (claim). The screen is drawn with the game's own pieces (the window frame,
// the green and grey buttons, the event icons), not with a layout of its own: there is none for something the game never had.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const label = (text, size, color, w, centre) => { const l = new HB.Label(text, 'Arial-BoldMT', size, [w || 0, 0], centre ? 1 : 0, 1); l.color = color; l.ax = centre ? 0.5 : 0; l.ay = 0.5; return l; };
  const icon = (name) => (name ? (/[\\/]/.test(name) ? HB.frame('', name) : HB.frameByName(name) || HB.frameByName('icon_' + name)) : null) || HB.frameByName('activity1');
  const events = (reply) => [...reply.querySelectorAll('event')].map((e) => Object.fromEntries([...e.attributes].map((a) => [a.name, a.value])));

  async function list() { try { const r = await HB.api('rl_x_custom', { Cmd: 1 }); return r.code ? [] : events(r); } catch (e) { return []; } }

  HB.screens.custom = async function custom() {
    const ui = HB.ui;
    ui.loading(true);
    let rows;
    try { [rows] = await Promise.all([list(), HB.data.tables(), HB.loadCCB('social/FriendMainView')]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    const o = {};
    HB.game.showSub('social/FriendMainView', o);
    o.onButton = () => HB.game.goHome();
    const box = o.n.node_content, W = box.w, H = box.h;
    const head = label('Special events', 40, [255, 226, 140], 0, true); head.stroke = ['#3a1a05', 4]; head.x = W / 2; head.y = H - 44; box.add(head);
    const back = new HB.Scale9(HB.frameByName('com_btn_green_01') || HB.frameByName('com_btn_blue_01')); back.ax = 0; back.ay = 0.5; back.w = 120; back.h = 58; back.x = 14; back.y = H - 44; box.add(back);
    const bl = label('Back', 26, [255, 255, 255], 0, true); bl.stroke = ['#12300a', 3]; bl.x = 60; bl.y = 29; back.add(bl);
    tap(back, () => HB.game.goHome());
    if (!rows.length) { const none = label('No special event is running right now.', 28, [90, 60, 20], W - 80, true); none.x = W / 2; none.y = H / 2; box.add(none); return; }
    const rowH = 190, top = 90;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = W; scroll.h = H - top - 10; scroll.y = 10;
    const col = new HB.Node(); col.w = W; col.h = Math.max(scroll.h, rows.length * rowH);
    const frame = HB.frameByName('com_bk_frame_16') || HB.frameByName('com_bk_frame_09');
    rows.forEach((e, i) => {
      const row = new HB.Node(); row.w = Math.min(700, W - 24); row.h = rowH - 14; row.x = (W - row.w) / 2; row.y = col.h - (i + 1) * rowH + 7;
      if (frame) { const bg = new HB.Scale9(frame); bg.ax = bg.ay = 0; bg.w = row.w; bg.h = row.h; row.add(bg); }
      const f = icon(e.icon);
      if (f) { const sp = new HB.Sprite(f); const k = Math.min(110 / (f.sw || 110), 110 / (f.sh || 110)); sp.sx = sp.sy = k; sp.x = 78; sp.y = row.h / 2; row.add(sp); }
      const tw = row.w - 150 - 170;
      const t = label(e.title, 30, [150, 60, 10], 0); t.x = 150; t.y = row.h - 34; row.add(t);
      const days = Number(e.left) > 0 ? (Number(e.left) === 1 ? 'last day' : e.left + ' days left') : '';
      if (days) { const d = label(days, 20, [200, 60, 40], 0); d.ax = 1; d.x = row.w - 22; d.y = row.h - 34; row.add(d); }
      const text = label(e.text, 22, [70, 45, 10], tw); text.ay = 1; text.x = 150; text.y = row.h - 56; row.add(text);
      const give = label('You get: ' + e.give, 20, [40, 110, 30], tw); give.ay = 0; give.x = 150; give.y = 16; row.add(give);
      const state = Number(e.state);
      const bf = HB.frameByName(state === 0 ? 'com_btn_green_01' : 'com_btn_blue_01');
      const btn = new HB.Scale9(bf); btn.ax = 1; btn.ay = 0.5; btn.w = 150; btn.h = 64; btn.x = row.w - 20; btn.y = row.h / 2 - 12; if (state !== 0) btn.grey = true; row.add(btn);
      const word = label(state === 0 ? 'Claim' : state === 1 ? (e.repeat === 'daily' ? 'Tomorrow' : 'Taken') : 'Locked', 26, [255, 255, 255], 0, true); word.stroke = ['#2a1505', 3]; word.x = 75; word.y = 32; btn.add(word);
      tap(btn, async () => {
        if (state === 1) return ui.tip(e.repeat === 'daily' ? 'Already taken today: come back tomorrow' : 'Already taken', 1.6);
        if (state === 2) return ui.tip('You need ' + (e.need || 'more') + ' for this one', 1.8);
        ui.loading(true);
        let r;
        try { r = await HB.api('rl_x_custom', { Cmd: 2, Id: e.id }); } catch (err) { ui.loading(false); return ui.tip('Cannot reach the server'); }
        ui.loading(false);
        if (r.code) return ui.tip(ui.errorText(r), 2);
        if (HB.game.loadItems) await HB.game.loadItems();
        await HB.game.refresh();
        const got = HB.awards ? HB.awards(r) : [];
        if (got.length) await HB.showCards(got, e.title); else ui.tip('You got: ' + e.give, 2.4);
        custom();
      });
      col.add(row);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
  };

  // the Home button (called by game.js when Home is built): only while an event runs
  HB.customHomeButton = async function (n, root) {
    const rows = await list();
    if (!rows.length || !root || !root.parent) return;
    const f = icon(rows[0].icon);
    if (!f) return;
    const b = new HB.Sprite(f); b.sx = b.sy = Math.min(1, 92 / (f.sw || 92)); b.x = HB.ui.FRAME - 78; b.y = root.h - 985; b.z = 20; // under Awards in the right column (ours)
    const l = label('Special', 20, [255, 240, 170], 0, true); l.stroke = ['#3a1a05', 3]; l.x = (f.sw || 92) / 2; l.y = -12; b.add(l);
    if (rows.some((e) => Number(e.state) === 0)) { const dot = HB.frameByName('com_notify_icon') || HB.frameByName('def_notify'); if (dot) { const d = new HB.Sprite(dot); d.x = (f.sw || 92) - 8; d.y = (f.sh || 92) - 8; b.add(d); } }
    tap(b, () => HB.screens.custom());
    root.add(b);
  };
})();
