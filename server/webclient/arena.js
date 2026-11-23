// Arena, the ladder (Home > Arena): CArenaViewNew (sub_ui/ArenaViewNew.ccbi) with one COpponentCardView per row
// (sub_ui/ArenaCellViewNew.ccbi). Tabs: Arena (the players around your place + yourself with the daily reward) and Rank (top 50).
// Requests: rl_r_sport (my place, reputation, attacks left today, the rows), rl_w_sport ToRank=<place> (the fight; the answer's
// <sport> says the reputation won and the new place), rl_r_sportrank (top 50), rl_x_sport_ext Cmd 3 (claim today's place reward),
// rl_w_sportpack (clear the cooldown for gold). Exchange tab (reputation shop): rl_x_sport_ext Cmd 1 (<renown_value> my reputation,
// <ritem><id><dayget><totalget> = times LEFT, -1 = no limit of that kind), Cmd 2 Exchg=<id> (the trade); the goods are the game's
// exchange_award table ([3] how many, [6] reputation price, [7] the drop pack it gives, [9] its name).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const two = (n) => String(n).padStart(2, '0');
  const clock = (s) => two(Math.floor(s / 3600)) + ':' + two(Math.floor(s / 60) % 60) + ':' + two(s % 60);

  let lastMy = null; // my place and reputation from the Compete list: the Rank tab's reply has none, the phone shows what it last knew
  HB.screens.arena = async function arena(tab = 0) {
    const ui = HB.ui, x = ui.x;
    if (tab === 2) return exchange();
    ui.loading(true);
    let reply;
    try {
      if (tab === 1 && !lastMy) { const first = await HB.api('rl_r_sport', { Cmd: 2800 }); const e = !first.code && x.first(first, 'my'); if (e) lastMy = Object.fromEntries([...e.children].map((c) => [c.nodeName, c.textContent])); }
      [reply] = await Promise.all([HB.api(tab === 1 ? 'rl_r_sportrank' : 'rl_r_sport', { Cmd: 2800 }), HB.data.tables(), HB.loadCCB('sub_ui/ArenaViewNew'), HB.loadCCB('sub_ui/ArenaCellViewNew')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const o = {};
    HB.game.showSub('sub_ui/ArenaViewNew', o);
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    [['ctrl_arena', 'Compete'], ['ctrl_rank', 'Rank'], ['ctrl_exchange', 'Exchange']].forEach(([name, title], i) => { const b = n[name]; if (b) { if (tabOff) b.frames[1] = i === tab ? tabOn || tabOff : tabOff; b.titles[1] = title; b.titleSize = 26; b.layout(); } });
    const obj = (e) => Object.fromEntries([...e.children].filter((c) => c.nodeName !== 'teammate').map((c) => [c.nodeName, c.textContent]));
    const my = tab === 0 ? obj(x.first(reply, 'my')) : null;
    if (n.layer_exchange) n.layer_exchange.visible = false;
    if (my) lastMy = my;
    if (n.ctrl_luckyrank) n.ctrl_luckyrank.visible = tab === 1; // only on the Rank tab (a dead button on the phone too: it asks the server nothing)
    if (my) {
      n.label_rank.setText(my.rank); n.label_popularity.setText(my.renown);
      if (n.label_ArenaViewNew0) n.label_ArenaViewNew0.setText('Attacks today:');
      n.label_remain_times.setText(my.todayresttime + '/' + my.todayall);
      for (const k of ['sprite_next_viplevel', 'label_add_desc', 'label_next_level_add', 'label_per_day_desc', 'label_max_vip']) if (n[k]) n[k].visible = false;
      if (n.label_ArenaViewNew1) { n.label_ArenaViewNew1.size = 22; n.label_ArenaViewNew1.setText('(Attacks also earn reputation)'); } // 22: at the layout's 26 it ran to the frame's edge
    } else if (lastMy) { n.label_rank.setText(lastMy.rank); n.label_popularity.setText(lastMy.renown); if (n.node_arena) n.node_arena.visible = false; } // Rank tab: my place and reputation stay, the attack counter goes
    else if (n.layer_rank) n.layer_rank.visible = false;
    o.onButton = (sel) => {
      if (sel === 'BtnArena') return arena(0);
      if (sel === 'BtnRank') return arena(1);
      if (sel === 'BtnExchange') return arena(2);
      if (sel === 'BtnBack') return HB.game.goHome();
      if (sel === 'BtnLuckyRank') return; // nothing happens on the phone either
      ui.tip('Coming soon: ' + sel.replace(/^Btn/, ''), 1.2);
    };
    const rows = x.all(reply, tab === 1 ? 'item' : 'user').map((e) => ({ ...obj(e), mates: x.all(x.first(e, 'teammate'), 'mate').map((m) => x.n(m, 'ninja')) }));
    const box = n.node_tablecontent, size = n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows.length) * size.h;
    const born = Date.now();
    rows.forEach((r, i) => {
      const co = {};
      const cell = HB.build('sub_ui/ArenaCellViewNew', co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      slice(co.n); fill(co.n, r);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    // the list starts at its top, like the phone (it used to jump to your own row)

    // the row's frame is a 9-slice whose two fixed sides are wider than its picture (arena_17 is 412 wide, the sides 35 + 380): keep a middle strip to stretch
    function slice(m) { for (const s of [m.sprite_other, m.sprite_me]) if (s && s.frame && s.insets && s.insets[0] + s.insets[2] > s.frame.w - 6) s.insets = [s.insets[0], s.insets[1], s.frame.w - s.insets[0] - 6, s.insets[3]]; }
    function icon(m, k, ninja) {
      const frame = m['sprite_ninjaicon' + k], holder = m['node_icon' + k];
      if (!frame) return;
      if (!ninja) return; // an empty place keeps the layout's dark frame, like the phone
      const inf = HB.info(1, ninja);
      const f = HB.qualityFrame('small', inf.quality); if (f) frame.setFrame(f); // CGameObjElement::GetArenaNinjaFrame: the small square box of its stars (small_box_skill_0N)
      const pic = HB.iconFrame(1, inf.icon);
      if (pic && holder) { const sp = new HB.Sprite(pic); const s = Math.min((holder.w - 10) / (pic.sw || 1), (holder.h - 10) / (pic.sh || 1)); sp.sx = sp.sy = s; sp.x = holder.w / 2; sp.y = holder.h / 2; holder.add(sp); }
    }
    function fill(m, r) {
      const me = Number(r.host) === 1;
      m.sprite_me.visible = me && tab === 0; m.sprite_other.visible = !(me && tab === 0);
      if (tab === 1) { const gf = HB.frameByName('arena_02'); if (gf) m.sprite_other.frame = gf; } // the Rank tab: every row in the gold frame
      m.label_name.setText(r.nick); m.label_level.setText(String(r.level)); m.label_rank.setText(String(r.rank));
      if (m.label_ArenaCellViewNew0) { const l = m.label_ArenaCellViewNew0; l.size = 20; l.setText('Reward:'); l.y -= 6; } // smaller and lower: the card above it and the coin beside it leave this much room
      m.label_coin_gain.setText(String(r.rewardcoin || 0)); m.label_popularity_gain.setText(String(r.rewardrenown || 0));
      const team = tab === 1 ? r.mates : [Number(r.ninja), ...r.mates];
      for (let k = 1; k <= 4; k++) icon(m, k, team[k - 1]);
      m.node_resttime.visible = false; m.node_overtime.visible = false; m.node_already_get.visible = false; m.btn_getreward.visible = false;
      m.btn_fight.visible = tab === 1 || !me;
      if (tab === 1) { const tf = HB.frameByName('arena_14'); if (tf) m.btn_fight.setFrame(tf); } // the Rank tab's "Team" button (the phone's does nothing when tapped)
      if (tab === 0 && me) {
        const claimed = Number(my.dayrewardstat) === 1;
        m.node_already_get.visible = claimed; m.btn_getreward.visible = !claimed;
        if (!claimed) {
          m.node_overtime.visible = true;
          if (m.label_ArenaCellViewNew2) m.label_ArenaCellViewNew2.setText('Claim within');
          (function tick() { if (!m.label_overtime.parent || !box.parent) return; m.label_overtime.setText(clock(Math.max(0, Number(my.timeleft) - Math.floor((Date.now() - born) / 1000)))); HB.tween({}, {}, 1, tick); })();
          tap(m.btn_getreward, async () => {
            const a = await send('rl_x_sport_ext', { Cmd: 3 });
            if (!a) return;
            await HB.game.refresh();
            const got = HB.awards(a);
            if (got.length) await HB.showCards(got, 'Place reward'); else ui.tip('Place reward claimed: ' + (r.rewardcoin || 0) + ' silver, ' + (r.rewardrenown || 0) + ' reputation', 2);
            arena(0);
          });
        }
      }
      if (tab === 0 && !me) tap(m.btn_fight, () => fight(r));
    }
    async function send(cgi, params) {
      ui.loading(true);
      let r;
      try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
      ui.loading(false);
      if (r.code) { ui.tip(ui.errorText(r)); return null; }
      return r;
    }
    async function fight(r) {
      if (Number(my.todayresttime) <= 0) return ui.tip('No attacks left today', 1.5);
      if (Number(my.resttime) > 0 && Number(my.restbatter) <= 0) {
        if (!(await HB.confirm('The arena is cooling down. Clear it for 30 gold?', { ok: 'Clear' }))) return;
        if (!(await send('rl_w_sportpack', { Cmd: 1 }))) return;
      }
      const reply2 = await send('rl_w_sport', { Cmd: 2801, ToRank: r.rank });
      if (!reply2) return;
      const won = Number(x.a(x.first(x.first(reply2, 'fight'), 'preview'), 'result', 0)) === 1;
      await HB.fight.play(reply2, { kind: 'arena', exp: won ? Number(r.winexp || 0) : Number(r.failexp || 0), silver: won ? Number(r.wincoin || 0) : Number(r.failcoin || 0), energy: 0 });
      const sp = x.first(reply2, 'sport');
      await HB.game.refresh();
      if (sp && won && Number(x.a(sp, 'torank')) < Number(x.a(sp, 'fromrank'))) ui.tip('Your place: ' + x.a(sp, 'fromrank') + ' > ' + x.a(sp, 'torank'), 2);
      arena(0);
    }
  };
  // ---------------------------------------------------------------- the Exchange tab
  async function exchange() {
    const ui = HB.ui, x = ui.x, arena = HB.screens.arena;
    ui.loading(true);
    let reply, goods;
    try {
      [reply, goods] = await Promise.all([HB.api('rl_x_sport_ext', { Cmd: 1 }), ui.table('exchange_award'), HB.data.tables(), HB.loadCCB('sub_ui/ArenaViewNew'), HB.loadCCB('sub_ui/ArenaExchangeCellView')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const o = {};
    HB.game.showSub('sub_ui/ArenaViewNew', o);
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    [['ctrl_arena', 'Compete'], ['ctrl_rank', 'Rank'], ['ctrl_exchange', 'Exchange']].forEach(([name, title], i) => { const b = n[name]; if (b) { if (tabOff) b.frames[1] = i === 2 ? tabOn || tabOff : tabOff; b.titles[1] = title; b.titleSize = 26; b.layout(); } });
    if (n.layer_rank) n.layer_rank.visible = false;
    if (n.layer_exchange) n.layer_exchange.visible = true;
    const mine = x.n(reply, 'renown_value');
    if (n.label_curr_popularity) n.label_curr_popularity.setText(String(mine));
    o.onButton = (sel) => { if (sel === 'BtnArena') return arena(0); if (sel === 'BtnRank') return arena(1); if (sel === 'BtnBack') return HB.game.goHome(); };
    const left = new Map(x.all(reply, 'ritem').map((r) => [x.n(r, 'id'), { day: Number(x.t(r, 'dayget')), total: Number(x.t(r, 'totalget')) }]));
    const box = n.node_tablecontent, size = n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, goods.rows.length) * size.h;
    goods.rows.forEach((g, i) => {
      const co = {};
      const cell = HB.build('sub_ui/ArenaExchangeCellView', co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      const m = co.n, d = HB.row('dropinfo', g[7]) || [], l = left.get(g[0]) || { day: -1, total: -1 };
      // what the pack holds: dropinfo [3] shinobi, [4] gear, [5] ninjutsu, [6] seal, [7] item
      const what = d[3] ? [1, d[3]] : d[4] ? [2, d[4]] : d[5] ? [6, d[5]] : d[6] ? [5, d[6]] : d[7] ? [7, d[7]] : null;
      if (what) {
        const inf = HB.info(what[0], what[1]), qf = HB.qualityFrame(what[0] === 1 ? 'ninjaSmall' : 'small', inf.quality), pic = HB.iconFrame(what[0], inf.icon);
        if (qf) m.sprite_ninjaicon.setFrame(qf);
        if (pic) { const sp = new HB.Sprite(pic); const k = Math.min((m.sprite_ninjaicon.w - 12) / (pic.sw || 1), (m.sprite_ninjaicon.h - 12) / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = m.sprite_ninjaicon.w / 2; sp.y = m.sprite_ninjaicon.h / 2; sp.z = 1; m.sprite_ninjaicon.add(sp); }
        m.label_desc.dims = [330, 0]; { const t = String(inf.desc || ''); m.label_desc.setText(t.length > 62 ? t.slice(0, 60).replace(/\s+\S*$/, '') + '...' : t); }
      } else m.label_desc.setText('');
      m.label_exchange_num.setText(String(g[3])); m.label_exchange_num.z = 2; // how many you get, over the picture's corner like the phone (it lay under the picture)
      { // the table cuts long names short ("Element Change Pil"): the item's own name when it starts the same way
        const short = String(g[9] || '').replace(/\0+$/, ''), full = what ? String(HB.info(what[0], what[1]).name || '') : '';
        m.label_name_exchange.setText(full.length > short.length && full.startsWith(short) ? full : short);
      }
      if (m.label_name_exchange.w > 228) m.label_name_exchange.sx = m.label_name_exchange.sy = 228 / m.label_name_exchange.w;
      const total = l.total !== -1;
      m.label_total_exchange.visible = total; m.label_today_exchange.visible = !total && l.day !== -1;
      // one small label at the right end of the name bar (the layout's pair, words with a hole for the number, did not fit in English)
      for (const lb of [m.label_total_exchange, m.label_today_exchange]) { lb.size = 18; lb.ax = 1; lb.x = m.label_exchange_count.x + 46; lb.setText(lb === m.label_total_exchange ? 'Left in total: ' + l.total : 'Left today: ' + l.day); }
      m.label_exchange_count.visible = false;
      if (m.label_ArenaExchangeCellView0) m.label_ArenaExchangeCellView0.setText('');
      m.label_popularity_exchange.setText(String(g[6]));
      const none = (total && l.total <= 0) || (!total && l.day === 0);
      if (none) m.btn_exchange.grey = true;
      const word = new HB.Label('Exchange', 'Arial-BoldMT', 21, [0, 0], 1, 1); word.color = [255, 255, 255]; word.stroke = ['#2a1505', 3]; word.x = m.btn_exchange.w / 2; word.y = m.btn_exchange.h / 2; m.btn_exchange.add(word);
      tap(m.btn_exchange, async () => {
        if (none) return ui.tip('None of these left', 1.4);
        if (mine < g[6]) return ui.tip('Not enough reputation', 1.6);
        if (!(await HB.confirm('Trade ' + g[6] + ' reputation for ' + String(g[9]).replace(/\0+$/, '') + (g[3] > 1 ? ' x' + g[3] : '') + '?', { ok: 'Exchange' }))) return;
        ui.loading(true);
        let r;
        try { r = await HB.api('rl_x_sport_ext', { Cmd: 2, Exchg: g[0] }); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
        ui.loading(false);
        if (r.code) return ui.tip(ui.errorText(r));
        await HB.game.refresh();
        const got = HB.awards(r);
        if (got.length) await HB.showCards(got, 'Exchanged'); else ui.tip('Exchanged', 1.5);
        exchange();
      });
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
  }
})();
