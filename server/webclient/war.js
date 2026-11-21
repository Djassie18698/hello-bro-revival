// War (Home > the War building, CMyCountryView, countrywar/MyCountryView.ccbi) and the National treasure (CCountryTreasure).
// War has four tabs, each its own layout inside node_content:
//   0 My country  CMyCountryInfo    countrywar/MyCountryInfoView   rl_r_countrynew (<officallist><offical><id><nick><uid>, <pack><canget>
//                 <resttime>, <timeinfo><begin><end>); Match = rl_w_countrynew Cmd 4002 Offical=<seat> (<officaltake direct="1"> = the seat
//                 was empty, direct="0" = a fight against its holder, the fight's parts inside <officaltake>); the gift bag of your own
//                 seat = Cmd 4003. Prices of a try: normalconfig 11 / 12 / 13.
//   1 War         CWarInfoView      countrywar/WarInfoViewNew      rl_r_warnew (<preview fightlefttime curintercost>, <allicountry>,
//                 <oppecountry>, <user> maxalive restalive curpower score scorerank killnum rank beattack ... autowar, <country><my killnum>
//                 <he killnum>, <autoinfo>); rl_w_warnew Cmd 4102 attack (a fight), 4101 buy revives, 4104 clear the wait, 4103 AutoType
//                 1-3 Auto-Attack (CDlgAutoFightBuy); news lines rl_r_warmsgnew Cmd 7700 (<warmsg>); the "?" windows
//                 rl_r_countryranknew Cmd 4201 kills / 4204 times attacked / 4203 (CWarAttackProgressDialog, CCountryWarProgressDialog).
//   2 Reward      CScoreShopView    countrywar/CountryScoreShop    the game's warconfig rows of type 2 ([4] place, [5] exploit price,
//                 [6] drop pack); rl_w_warnew Cmd 4100 PackID; my exploit = rl_r_warnew <user><curpower>.
//   3 Ranking     CWarRankInfoView  countrywar/PlayerRankInfoView  rl_r_countryranknew Cmd 4202 (players: rank nick power countryid),
//                 Cmd 4200 (countries: id king winnum falinum).
// National treasure: countrywar/CountryTreasury.ccbi; rl_r_tear (<trea><attack><canattack><resttime><restattacknum>, <victory><country id
// attack defnese>, <award num>, <awardhis coin merit>, <country><count><isguard>), Defend = rl_w_tearguard, Contribute = rl_w_tear
// (<award coin merit>), Plunder = the window countrywar/SnatchDialogView (rl_r_tearcountry: <country id><tearnum><grabnum>) then
// rl_w_tearcountry ToCountry (<tear direct="1"> = nobody guarded, direct="0" = a fight); Cmd 13001 skips the wait for gold (normalconfig 25).
// Ours: the wording of the news lines and tips; an empty seat says "(empty)"; Auto-Attack is left to the server (it attacks for you every
// 20 s, also with the game closed), the phone also attacked by itself while the screen was open.
// Test switch: &open=war&tab=0..3 / &open=treasure, then &act=<a>,<b> presses things by themselves: attack, revive, clear, auto<1-3>,
// kills, hits, vs, match<seat>, bag<seat>, buy<pack id>, nations, countries, guard, handin, raid<country>, skip.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const Q = new URLSearchParams(location.search);
  const tap = (node, fn) => { if (!node) return; node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const set = (n, k, t) => { if (n[k]) n[k].setText(String(t)); };
  const show = (n, k, on) => { if (n[k]) n[k].visible = !!on; };
  const two = (v) => String(v).padStart(2, '0');
  const clock = (s) => two(Math.floor(s / 3600)) + ':' + two(Math.floor(s / 60) % 60) + ':' + two(s % 60);
  const clean = (s) => String(s ?? '').replace(/\0+$/, '').trim();
  const obj = (e) => (e ? Object.fromEntries([...e.children].map((c) => [c.nodeName, c.textContent])) : {});
  const child = (e, tag) => (e ? [...e.children].find((c) => c.nodeName === tag) : null);
  // CProfileData: 0 Wind, 1 Mine (thunder), 2 Water, 3 Fire, 4 Earth; the pictures are com_icon_country_<name>, cw_boss_<name>, com_label_<name>
  const CNAME = ['Wind', 'Mine', 'Water', 'Fire', 'Earth'];
  const LAND = ['Land of Wind', 'Land of Lightning', 'Land of Water', 'Land of Fire', 'Land of Earth']; // (ours: the names in the tips)
  const cname = (c) => CNAME[Number(c)] || 'Fire';
  const land = (c) => LAND[Number(c)] || 'Land of Fire';
  const flag = (sp, c) => { const f = HB.frameByName('com_icon_country_' + cname(c)); if (sp && f) sp.setFrame(f); };
  const toMidnight = () => { const m = new Date(); m.setHours(24, 0, 0, 0); return Math.max(0, Math.round((m - Date.now()) / 1000)); };
  const nc = (id, d) => { const t = HB.ui.tables.normalconfig, r = t && t.rows.find((q) => q[0] === id); return r && r[3] != null ? r[3] : d; };
  const myCountry = () => Number((HB.game.user || {}).country || 0);

  async function send(cgi, params) {
    const ui = HB.ui;
    ui.loading(true);
    let r;
    try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
    ui.loading(false);
    if (r.code) { ui.tip(ui.errorText(r), 2.2); return null; }
    return r;
  }
  // rows of one cell layout in a box that scrolls
  function list(box, size, rows, layout, fill) {
    box.removeAll();
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows.length) * size.h;
    rows.forEach((r, i) => {
      const co = {};
      const cell = HB.build(layout, co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      fill(co.n, r, i);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
    return scroll;
  }
  // a second-by-second clock that stops when its label left the screen
  function ticker(label, seconds, text, done) {
    const born = Date.now();
    const alive = (nd) => { for (let p = nd; p; p = p.parent) if (p === HB.scene) return true; return false; };
    (function tick() {
      if (!alive(label)) return;
      const s = seconds - Math.floor((Date.now() - born) / 1000);
      if (s <= 0) { label.setText(text(0)); if (done) done(); return; }
      label.setText(text(s)); HB.tween({}, {}, 1, tick);
    })();
  }
  // the line on top of the War tab: the news run through it one after another (the phone scrolls them)
  function headline(label, lines) {
    if (!label) return;
    const alive = (nd) => { for (let p = nd; p; p = p.parent) if (p === HB.scene) return true; return false; };
    let i = 0;
    (function next() {
      if (i && !alive(label)) return;
      let t = lines[i % lines.length]; i++;
      if (t.length > 56) t = t.slice(0, 55) + '…';
      label.setText(t);
      label.sx = label.sy = Math.min(1, 640 / (label.w || 1)); // the whole line inside its bar (at the layout's size 40 letters were cut off on both sides)
      if (lines.length > 1) HB.tween({}, {}, 3.5, next);
    })();
  }
  // the test switch &act=...: each screen offers its actions by name
  let acts = (Q.get('act') || '').split(',').filter(Boolean);
  async function runActs(table) {
    while (acts.length) {
      const m = /^([a-z]+)(\d*)$/.exec(acts[0]);
      if (!m || !table[m[1]]) return;
      acts.shift();
      await HB.wait(1.2);
      if (await table[m[1]](Number(m[2]) || 0) === 'stop') return;
    }
  }

  // ================================================================ War
  const TABS = [['country', 'BtnMyCountryInfo', 'countrywar/MyCountryInfoView'], ['countrywar', 'BtnCountryWar', 'countrywar/WarInfoViewNew'],
    ['countryshop', 'BtnCountryShop', 'countrywar/CountryScoreShop'], ['rank', 'BtnWarRank', 'countrywar/PlayerRankInfoView']];
  HB.screens.war = async function war(tab = 0, sub = 0) {
    const ui = HB.ui, x = ui.x;
    tab = TABS[tab] ? tab : 0;
    ui.loading(true);
    try {
      await Promise.all([HB.data.tables(), ui.table('normalconfig'), ui.table('warconfig'), ui.table('dropinfo'), ...['countrywar/MyCountryView', ...TABS.map((t) => t[2]), 'countrywar/WarMsgCell', 'countrywar/CountryScoreShopCell',
        'countrywar/PlayerRankCell', 'countrywar/CountryRankCell'].map((f) => HB.loadCCB(f))]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    const o = {};
    HB.game.showSub('countrywar/MyCountryView', o);
    const n = o.n;
    // seen on the phone (photos 0525, 0833): the chosen tab wears the banner picture, which the layout calls ..._disable
    TABS.forEach(([key], i) => { show(n, 'sprite_' + key + '_enable', i !== tab); show(n, 'sprite_' + key + '_disable', i === tab); });
    show(n, 'sprite_notify_countryinfo', false);
    const inner = {};
    o.onButton = (sel, btn) => {
      const i = TABS.findIndex((t) => t[1] === sel);
      if (i >= 0) return war(i);
      if (sel === 'BtnBack') return HB.game.goHome();
      if (inner.onButton) return inner.onButton(sel, btn);
    };
    const box = (o.all.node_content || [n.node_content])[0]; // the layout's own, not the one of the ranking view it carries inside
    box.removeAll();
    const view = HB.build(TABS[tab][2], inner, [box.w, box.h]);
    view.ignoreAnchor = true; view.x = 0; view.y = 0;
    box.add(view);
    const m = inner.n;
    return [officials, warInfo, shop, ranking][tab]();

    // ---------------------------------------------------------------- 0: my country's officials
    async function officials() {
      const [reply, info] = await Promise.all([send('rl_r_countrynew', { Cmd: 7100 }), HB.api('rl_r_warnew', { Cmd: 7200 }).catch(() => null)]);
      if (!reply) return;
      const seats = new Map(x.all(x.first(reply, 'officallist'), 'offical').map((s) => [x.n(s, 'id'), obj(s)]));
      const pack = x.first(reply, 'pack'), canGet = x.n(pack, 'canget') === 1, wait = x.n(pack, 'resttime');
      const me = Number((HB.game.user || {}).uid || HB.uid || 0), myNick = (HB.game.user || {}).nick;
      const boss = HB.frameByName('cw_boss_' + cname(myCountry())); if (boss && m.sprite_country_boss) m.sprite_country_boss.setFrame(boss);
      const hm = (s) => Math.floor(s / 3600) + ':' + two(Math.floor(s / 60) % 60); // CMyCountryInfo::SetTimeToText
      const ti = x.first(reply, 'timeinfo');
      set(m, 'label_tip_time', hm(x.n(ti, 'begin')) + '-' + hm(x.n(ti, 'end')));
      const foes = info && !info.code ? x.all(child(info, 'oppecountry'), 'oppecountryid').map((e) => land(e.textContent)) : [];
      set(m, 'label_tip_2', 'War starts every night'); set(m, 'label_tip_3', 'War is declared automatically'); // capitals like the line above them
      set(m, 'label_warinfotip', foes.length ? 'Today we fight ' + foes.join(' and ') : 'No war declared today');
      const mine = (s) => s && (Number(s.uid) === me || (!me && s.nick === myNick));
      let mySeat = 0;
      for (let k = 1; k <= 7; k++) {
        const s = seats.get(k);
        if (mine(s)) mySeat = k;
        set(m, 'label_officailname' + k, s ? s.nick : '(empty)');
        const t = m['label_pack_resttime' + k];
        if (t) {
          t.visible = mine(s);
          if (mine(s)) { if (canGet) t.setText('Claim!'); else ticker(t, wait, (v) => clock(v)); }
        }
        if (m['ctrl_comp' + k]) m['ctrl_comp' + k].visible = !mine(s);
      }
      const price = (k) => nc(k === 1 ? 11 : k <= 3 ? 12 : 13, 0);
      const bagPack = (k) => (k === 1 ? 218 : k <= 3 ? 219 : 220); // warconfig rows 1-3: the Officer's Gift packs
      async function match(k) {
        const s = seats.get(k), cost = price(k);
        // the phone's CVieCostDlg: "Competing for this position requires gold: N"
        const text = (s ? 'Fight ' + s.nick + ' for this seat?' : 'Take this empty seat?') + (cost ? '\nCompeting for this position requires gold: ' + cost : '');
        if (!Q.get('act') && !(await HB.confirm(text, { ok: s ? 'Fight' : 'Take it', title: 'Compete' }))) return;
        const r = await send('rl_w_countrynew', { Cmd: 4002, Offical: k });
        if (!r) return;
        const take = x.first(r, 'officaltake');
        if (take && Number(x.a(take, 'direct', 1)) === 0) {
          // the fight's parts sit inside <officaltake>: hand them to the fight screen as a <fight>
          const doc = take.ownerDocument, root = doc.createElement('root'), f = doc.createElement('fight');
          [...take.children].forEach((c) => f.appendChild(c.cloneNode(true))); root.appendChild(f);
          const won = await HB.fight.play(root, { kind: 'official', exp: 0, silver: 0, energy: 0 });
          await HB.game.refresh();
          ui.tip(won ? 'You won the seat!' : 'You lost: ' + s.nick + ' keeps the seat', 2.2);
        } else { await HB.game.refresh(); ui.tip('The seat is yours!', 2); }
        return war(0);
      }
      async function bag(k) {
        const text = clean((ui.tables.dropinfo.rows.find((r) => r[0] === bagPack(k)) || [])[2]) || "Officer's Gift pack";
        if (k !== mySeat) return ui.tip("Officer's Gift pack (once a day for this seat). " + text, 3.5);
        if (!canGet) return ui.tip('Already collected: the next gift comes with the clock', 2);
        const r = await send('rl_w_countrynew', { Cmd: 4003 });
        if (!r) return;
        await HB.game.refresh();
        const got = HB.awards(r);
        if (got.length) await HB.showCards(got, "Officer's Gift pack"); else ui.tip("Officer's Gift pack collected", 2);
        return war(0);
      }
      inner.onButton = (sel) => {
        let k = /^clickComp(\d)$/.exec(sel); if (k) return match(Number(k[1]));
        k = /^clickReward(\d)$/.exec(sel); if (k) return bag(Number(k[1]));
      };
      runActs({ match: async (k) => { await match(k || 7); return 'stop'; }, bag: async (k) => { await bag(k || mySeat || 7); return 'stop'; } });
    }

    // ---------------------------------------------------------------- 1: the war
    async function warInfo() {
      const [reply, news, own] = await Promise.all([send('rl_r_warnew', { Cmd: 7200 }), HB.api('rl_r_warmsgnew', { Cmd: 7700 }).catch(() => null), HB.api('rl_r_warmsgnew', { Cmd: 7701 }).catch(() => null)]);
      if (!reply) return;
      const pv = x.first(reply, 'preview'), u = obj(child(reply, 'user')), cty = child(reply, 'country'), auto = obj(child(reply, 'autoinfo'));
      const allies = x.all(child(reply, 'allicountry'), 'allicountryid').map((e) => Number(e.textContent));
      const foes = x.all(child(reply, 'oppecountry'), 'oppecountryid').map((e) => Number(e.textContent));
      for (let k = 1; k <= 3; k++) {
        const a = m['sprite_my_country_icon_' + k], e = m['sprite_enemy_country_icon_' + k];
        if (a) { a.visible = k <= allies.length; flag(a, allies[k - 1]); }
        if (e) { e.visible = k <= foes.length; flag(e, foes[k - 1]); }
      }
      set(m, 'label_mycountrykills', x.a(child(cty, 'my'), 'killnum', 0)); set(m, 'label_enemykills', x.a(child(cty, 'he'), 'killnum', 0));
      set(m, 'label_total_score', u.score || 0); set(m, 'label_total_rank', u.scorerank || 0); set(m, 'label_liftcount', u.restalive || 0);
      set(m, 'label_attack_score', u.killnum || 0); set(m, 'label_attack_rank', u.rank || 0); set(m, 'label_war_merit', u.curpower || 0);
      set(m, 'label_defense_score', u.beattack || 0); set(m, 'label_defense_rank', u.beattackrank || 0); set(m, 'label_ninja_merit', u.beattackmerit || 0);
      // text that fits: the three rows of numbers. The layout's places are the Chinese ones ("killing number： 0rank： 11" ran into
      // each other): shorter words with a plain colon, and every number right behind its word
      { const W = { 0: 'Total points:', 1: 'Rank:', 4: 'Kills:', 5: 'Rank:', 6: 'War exploit:', 7: 'Casualties:', 8: 'Rank:', 9: 'Ninja exploit:' };
        for (const k in W) set(m, 'label_WarInfoView' + k, W[k]);
        const after = (word, num) => { const a = m[word], b = m[num]; if (a && b) b.x = a.x - a.ax * a.w + a.w + 10 + b.ax * b.w; };
        const at = (word, like) => { if (m[word] && m[like]) m[word].x = m[like].x; };
        at('label_WarInfoView5', 'label_WarInfoView1'); at('label_WarInfoView8', 'label_WarInfoView1'); // the three Rank words in one column
        for (const [a, b] of [['label_WarInfoView0', 'label_total_score'], ['label_WarInfoView1', 'label_total_rank'], ['label_WarInfoView4', 'label_attack_score'], ['label_WarInfoView5', 'label_attack_rank'], ['label_WarInfoView6', 'label_war_merit'], ['label_WarInfoView7', 'label_defense_score'], ['label_WarInfoView8', 'label_defense_rank'], ['label_WarInfoView9', 'label_ninja_merit']]) after(a, b); }
      // the war is open all day on this server: the clock runs to midnight (CWarInfoView::UpdateRestTime)
      const open = Number(x.a(pv, 'open', 1)) === 1;
      const world = news && !news.code ? x.all(news, 'warmsg').map(obj) : [];
      const line = (r) => land(r.fromcountry) + ' shinobi ' + r.fromnick + (Number(r.iswin) === 1 ? ' has defeated ' : ' was beaten by ') + land(r.tocountry) + ' shinobi ' + r.tonick;
      headline(m.label_country_state, !open ? ['War has not started yet!'] : world.length ? world.slice(0, 8).map(line) : ['The war is on!']);
      show(m, 'btn_result', !open); show(m, 'label_result_name', !open);
      show(m, 'sprite_declare_cd', false); show(m, 'sprite_war_cd', true);
      if (m.label_resttime) ticker(m.label_resttime, toMidnight(), (v) => clock(v), () => war(1));
            const cd = Number(x.a(pv, 'fightlefttime', 0)), clearCost = Number(x.a(pv, 'curintercost', 30)), autoOn = Number(u.autowar) === 1;
      // with Auto-Attack on the phone shows no Attack button, only the line under the clock (photo 0833)
      show(m, 'node_attack_cd', cd > 0); show(m, 'node_cd_clear', cd > 0 && !autoOn); show(m, 'btn_attack', cd <= 0 && !autoOn);
      set(m, 'label_WarInfoViewNew0', 'Attack again in:');
      if (autoOn && cd > 0 && m.node_attack_cd) m.node_attack_cd.y -= 44; // under the "Auto-Attack is on" line, as on the phone
      set(m, 'label_review_name', 'Clear'); set(m, 'label_cd_gold', clearCost);
      if (cd > 0 && m.label_fight_cd_time) ticker(m.label_fight_cd_time, cd, (v) => clock(v).slice(3), () => war(1));
      show(m, 'node_auto_attacted', false); show(m, 'label_join_auto_attack', autoOn); show(m, 'node_cancel_container', !autoOn);
      set(m, 'label_join_auto_attack', 'Auto-Attack is on for today'); set(m, 'label_WarInfoView14', 'Let the system attack for you?'); set(m, 'label_WarInfoView15', 'Autoplay');
      // the news lines (CCountryWarDescTable): who beat whom
      const rows = own && !own.code ? x.all(own, 'warmsg').map(obj) : [], myNick = (HB.game.user || {}).nick;
      if (m.node_table_war_desc && m.node_cell_war_desc) {
        list(m.node_table_war_desc, m.node_cell_war_desc, rows, 'countrywar/WarMsgCell', (c, r) => {
          const won = Number(r.iswin) === 1, byMe = r.fromnick === myNick;
          if (!c.label_msg) return;
          // the phone's lines (photo 0833): green "you defeated X,get 10 points and 10 exploit", red "... and failed,get 0 points and 0 exploit"
          const good = byMe ? won : !won;
          c.label_msg.setText(byMe ? 'you defeated ' + r.tonick + (won ? '' : ' and failed') + ',get ' + r.score + ' points and ' + r.powernum + ' exploit'
            : r.fromnick + (won ? ' defeated you' : ' attacked you and failed,get 2 points and 2 exploit'));
          c.label_msg.color = good ? [60, 230, 40] : [240, 40, 30];
        });
      }
      if (m.node_content) m.node_content.removeAll();
      if (autoOn) HB.tween({}, {}, 20, () => { for (let p = view; p; p = p.parent) if (p === HB.scene) return war(1); }); // the server attacks every 20 s: show how it goes

      async function attack() {
        if (Number(u.restalive) <= 0) return ui.tip('No revives left: buy more or wait until tomorrow', 2.2);
        const r = await send('rl_w_warnew', { Cmd: 4102 });
        if (!r) return war(1);
        const won = Number(x.a(x.first(r, 'CountryWar'), 'batter', 0)) === 1;
        await HB.fight.play(r, { kind: 'war', exp: won ? 36 : 0, silver: won ? 36 : 0, energy: 0 });
        await HB.game.refresh();
        ui.tip(won ? 'Kill! +10 points, +10 exploit' : 'Defeated: one revive used', 2);
        return war(1);
      }
      async function revive() {
        const cost = nc(15, 30), times = nc(17, 10);
        if (!Q.get('act') && !(await HB.confirm('Buy ' + times + ' revives for ' + cost + ' gold?', { ok: 'Buy' }))) return;
        if (!(await send('rl_w_warnew', { Cmd: 4101 }))) return;
        await HB.game.refresh(); ui.tip('Revives are full again', 1.8);
        return war(1);
      }
      async function clearCd() {
        if (!Q.get('act') && !(await HB.confirm('Clear the attack wait for ' + clearCost + ' gold?', { ok: 'Clear' }))) return;
        if (!(await send('rl_w_warnew', { Cmd: 4104 }))) return;
        await HB.game.refresh();
        return war(1);
      }
      // CDlgAutoFightBuy: three choices, the price of each from <autoinfo>
      async function autoBuy(pick) {
        const base = Number(auto.auto_cost1 || 50);
        const total = (t) => base + (t > 1 ? Number(auto['auto_cost' + t] || 0) : 0);
        let type = pick || 1;
        const buy = async () => {
          if (!(await send('rl_w_warnew', { Cmd: 4103, AutoType: type }))) return;
          await HB.game.refresh(); ui.tip('Auto-Attack bought: the system attacks for you until midnight', 2.5);
          return war(1);
        };
        if (pick) return buy();
        const w = {};
        await HB.dialog('countrywar/CountryAutoFightBuy', w);
        const d = w.n;
        const mark = () => { for (let k = 1; k <= 3; k++) show(d, 'sprite_selected_' + k, k === type); };
        set(d, 'label_auto_1', base); set(d, 'label_auto_cost_2', total(2)); set(d, 'label_auto_cost_3', total(3));
        set(d, 'label_auto_times_2', auto.auto_times2 || 0); set(d, 'label_auto_times_3', auto.auto_times3 || 0);
        // the two lines "cost N gold to auto-clean cooldown N times": the layout leaves gaps sized for the Chinese text, so the
        // numbers are written into the sentence instead
        let top = d.label_title; while (top && top.parent && top.parent.parent && top.parent.parent !== HB.scene) top = top.parent;
        const lines = []; (function walk(nd) { if (typeof nd.text === 'string' && /auto-clean/i.test(nd.text) && /cost/i.test(nd.text)) lines.push(nd); (nd.children || []).forEach(walk); })(top || { children: [] });
        lines.sort((a, b) => a.y - b.y); // as built: the 5-times line comes out below the 10-times one
        if (lines.length === 2) {
          lines.forEach((l, i) => l.setText('cost ' + total(i + 2) + ' gold to auto-clean cooldown ' + (auto['auto_times' + (i + 2)] || 0) + ' times'));
          for (const k of ['label_auto_cost_2', 'label_auto_cost_3', 'label_auto_times_2', 'label_auto_times_3']) show(d, k, false);
        }
        mark();
        w.onButton = (sel) => {
          const k = ['BtnAutoBuyOne', 'BtnAutoBuyTwo', 'BtnAutoBuyThree'].indexOf(sel);
          if (k >= 0) { type = k + 1; return mark(); }
          w.close();
          if (sel === 'onConfirm') buy();
        };
      }
      // the "?" windows: today's best of my country and of the enemy (six rows)
      async function progress(kind) {
        const layout = { kills: 'countrywar/WarAttackProgressDialog', hits: 'countrywar/WarDefenseProgressDialog', vs: 'countrywar/CountryWarProgressDialog' }[kind];
        const cmd = { kills: 4201, hits: 4204, vs: 4203 }[kind];
        const mineC = allies[0] ?? myCountry(), foe = foes[0];
        ui.loading(true);
        let a, b;
        try { [a, b] = await Promise.all([HB.api('rl_r_countryranknew', { Cmd: cmd, Country: mineC, Page: 1 }), foe === undefined ? null : HB.api('rl_r_countryranknew', { Cmd: cmd, Country: foe, Page: 1 }), HB.loadCCB(layout)]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
        ui.loading(false);
        if (a.code) return ui.tip(ui.errorText(a));
        const w = { onButton: () => w.close() };
        await HB.dialog(layout, w);
        const d = w.n, ur = x.first(a, 'userrank');
        set(d, 'labelTitle', { kills: 'Kills today', hits: 'Times attacked today', vs: 'War progress' }[kind]);
        set(d, 'label_kill_count', x.a(ur, 'myscorecount', 0)); set(d, 'label_rank', x.a(ur, 'myrank', 0)); set(d, 'label_merit', x.a(ur, 'myscore', 0));
        if (kind === 'vs') {
          const mk = Number(x.a(child(cty, 'my'), 'killnum', 0)), hk = Number(x.a(child(cty, 'he'), 'killnum', 0));
          show(d, 'sprite_win_result', mk >= hk && mk > 0); show(d, 'sprite_lose_result', mk < hk); show(d, 'button_chest', false);
          set(d, 'label_progress_info', 'Kills today: your side ' + mk + ', the enemy ' + hk);
        }
        const L = x.all(a, 'user').map(obj), R = b && !b.code ? x.all(b, 'user').map(obj) : [];
        for (let k = 1; k <= 6; k++) {
          const l = L[k - 1], r = R[k - 1];
          show(d, 'node_container' + k, l || r);
          for (const [side, row] of [['my', l], ['enemy', r]]) {
            const ic = d['icon_' + side + '_country_player' + k];
            if (ic) { ic.visible = !!row; if (row) flag(ic, row.countryid); }
            set(d, 'label_' + side + '_country_player' + k, row ? row.nick : '');
            set(d, 'label_killed_' + side + '_country_player' + k, row ? row.realval : '');
          }
        }
        return w;
      }
      inner.onButton = (sel) => {
        if (sel === 'clickAttack') return attack();
        if (sel === 'clickBuyReborn') return revive();
        if (sel === 'BtnClearCd') return clearCd();
        if (sel === 'clickAutoAttack') return autoBuy();
        if (sel === 'clickAttackDetail') return progress('kills');
        if (sel === 'clickDefenseDetail') return progress('hits');
        if (sel === 'clickVs' || sel === 'clickReadResult') return progress('vs');
      };
      runActs({ attack: async () => { await attack(); return 'stop'; }, revive: async () => { await revive(); return 'stop'; }, clear: async () => { await clearCd(); return 'stop'; },
        auto: async (k) => { await autoBuy(k); return 'stop'; }, kills: () => progress('kills'), hits: () => progress('hits'), vs: () => progress('vs') });
    }

    // ---------------------------------------------------------------- 2: the exploit shop
    async function shop() {
      const reply = await send('rl_r_warnew', { Cmd: 225 });
      if (!reply) return;
      const have = Number(obj(child(reply, 'user')).curpower || 0);
      set(m, 'label_own_score', have);
      const rows = ui.tables.warconfig.rows.filter((r) => r[3] === 2).sort((a, b) => a[4] - b[4]);
      const drop = (id) => clean((ui.tables.dropinfo.rows.find((r) => r[0] === id) || [])[2]);
      async function buy(row) {
        if (have < row[5]) return ui.tip('Not enough war exploit: ' + have + ' of ' + row[5], 2);
        if (!Q.get('act') && !(await HB.confirm('Trade ' + row[5] + ' war exploit for this pack?', { ok: 'Exchange' }))) return;
        const r = await send('rl_w_warnew', { Cmd: 4100, PackID: row[0] });
        if (!r) return;
        await HB.game.refresh();
        const got = HB.awards(r);
        if (got.length) await HB.showCards(got, clean(row[2])); else ui.tip('Exchanged', 1.5);
        return war(2);
      }
      list(m.node_table, m.node_cell, rows, 'countrywar/CountryScoreShopCell', (c, row) => {
        set(c, 'label_name_exchange', clean(row[2])); set(c, 'label_popularity_exchange', row[5]);
        if (c.label_desc) { const t = drop(row[6]); c.label_desc.setText(t.length > 84 ? t.slice(0, 82).replace(/[ ,]+S*$/, '') + '…' : t); }
        set(c, 'label_ArenaExchangeCellView0', '');
        show(c, 'label_total_exchange', false); show(c, 'label_today_exchange', false); show(c, 'label_exchange_count', false);
        const f = HB.frameByName('cw_box_' + (((row[4] - 1) % 5) + 1)); // CScoreShopCell::InitUI: cw_box_%d (ours: places 6-9 reuse the five boxes)
        if (f && c.sprite_box_icon) c.sprite_box_icon.setFrame(f);
        tap(c.btn_exchange, () => buy(row));
      });
      runActs({ buy: async (id) => { const row = rows.find((r) => r[0] === id) || rows[0]; await buy(row); return 'stop'; } });
    }

    // ---------------------------------------------------------------- 3: the rankings
    async function ranking() {
      const nations = sub === 1;
      const reply = await send('rl_r_countryranknew', { Cmd: nations ? 4200 : 4202, Country: 0, Page: 1 });
      if (!reply) return;
      const on = HB.frameByName('com_tab_02'), off = HB.frameByName('com_tab_01');
      [['ctrl_userrank', 'Players'], ['ctrl_countryrank', 'Countries']].forEach(([k, title], i) => { const b = m[k]; if (!b) return; if (off && on && b.frames && b.frames[1] && /com_tab/.test(String((b.frames[1] || {}).name || ''))) b.frames[1] = i === sub ? on : off; b.selected = i === (nations ? 1 : 0); b.layout(); });
      show(m, 'ctrl_nextpage', false); // the server sends its whole list (top 50) at once
      inner.onButton = (sel) => { if (sel === 'clickUserRank') return war(3, 0); if (sel === 'clickCountryRank') return war(3, 1); };
      const cup = (c, rank) => { const f = HB.frameByName((nations ? 'cw_country_cup' : 'cw_person_cup') + rank); if (c.sprite_rank_cup) { c.sprite_rank_cup.visible = rank <= 3; if (f && rank <= 3) c.sprite_rank_cup.setFrame(f); } show(c, 'label_rank', rank > 3 || !c.sprite_rank_cup); };
      if (nations) {
        const rows = x.all(x.first(reply, 'countryrank'), 'country').map(obj);
        list(m.node_content, m.node_cellcontent, rows, 'countrywar/CountryRankCell', (c, r, i) => {
          set(c, 'label_rank', i + 1); cup(c, i + 1);
          set(c, 'label_name', r.king || '(no leader)'); set(c, 'label_wintimes', r.winnum || 0); set(c, 'label_failtimes', r.falinum || 0);
          flag(c.icon_country, r.id);
        });
      } else {
        const rows = x.all(x.first(reply, 'userlist'), 'user').map(obj);
        list(m.node_content, m.node_cellcontent, rows, 'countrywar/PlayerRankCell', (c, r) => {
          set(c, 'label_rank', r.rank); cup(c, Number(r.rank));
          set(c, 'label_name', r.nick); set(c, 'label_historymerit', r.power); set(c, 'label_honor', '');
          flag(c.icon_country, r.countryid);
        });
      }
      runActs({ nations: async () => { await war(3, 1); return 'stop'; } });
    }
  };

  // ================================================================ National treasure
  HB.screens.treasure = async function treasure() {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let reply;
    try { [reply] = await Promise.all([HB.api('rl_r_tear', { Cmd: 13000 }), HB.data.tables(), ui.table('normalconfig'), ui.table('functionconfig'), HB.loadCCB('countrywar/CountryTreasury'), HB.loadCCB('countrywar/SnatchDialogView')]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    // functionconfig 6: "National Treasure level 45 unlocked" (the test switch &open=treasure gets in at any level)
    const fc = ui.tables.functionconfig.rows.find((r) => r[0] === 6) || [];
    if (Q.get('open') !== 'treasure' && Number((HB.game.user || {}).level || 1) < (fc[3] || 0)) return ui.tip(clean(fc[4]) || 'Locked', 2);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const trea = x.first(reply, 'trea'), atk = child(trea, 'attack'), ctry = child(trea, 'country');
    const cd = x.n(atk, 'resttime'), left = x.n(atk, 'restattacknum'), bank = Number(x.a(child(trea, 'award'), 'num', 0)), guard = x.n(ctry, 'isguard') === 1;
    const wins = x.all(child(trea, 'victory'), 'country').map((c) => ({ id: Number(x.a(c, 'id', 0)), attack: Number(x.a(c, 'attack', 0)), defend: Number(x.a(c, 'defnese', 0)) }));
    const o = {};
    HB.game.showSub('countrywar/CountryTreasury', o);
    const n = o.n, me = HB.game.user || {}, mine = myCountry();
    set(n, 'label_country_treasure', x.n(ctry, 'count')); set(n, 'label_handin_silver', 3000); set(n, 'label_my_treasure', bank); set(n, 'label_resttime', left);
    set(n, 'label_gold', me.cash ?? me.gold ?? 0); set(n, 'label_silver', me.coin ?? 0);
    const lf = HB.frameByName('com_label_' + cname(mine)); if (lf && n.sprite_country_label) n.sprite_country_label.setFrame(lf);
    flag(n.sprite_country_icon, mine);
    // the title picture's English words run under the place the layout gives the country's sign ("National treasu"): the sign
    // goes, smaller, into the plain end of the title's frame
    if (n.sprite_country_icon) { n.sprite_country_icon.x = 323; n.sprite_country_icon.sx = n.sprite_country_icon.sy = 0.55; }
    for (let k = 1; k <= 4; k++) {
      const w = wins[k - 1];
      for (const [key, val] of [['defeat', w && w.defend], ['snatch', w && w.attack]]) {
        const sp = n['sprite_' + key + '_country' + k], lb = n['label_' + key + '_count' + k];
        if (sp) { sp.visible = !!w; if (w) flag(sp, w.id); }
        if (lb) { lb.visible = !!w; lb.setText(String(val || 0)); }
      }
    }
    // CCountryTreasure::InitContent: the Defend button shows treasury_guard while you stand guard
    const gf = guard && HB.frameByName('treasury_guard'); if (gf && n.label_guard) n.label_guard.setFrame(gf);
    show(n, 'label_cd', cd > 0); show(n, 'label_cdtimer', cd > 0);
    set(n, 'label_cd', 'Next plunder in:');
    if (cd > 0 && n.label_cdtimer) ticker(n.label_cdtimer, cd, (v) => clock(v), () => treasure());
    // the long line "You currently have N national treasure(s)! (Cleared after 24 hours)": the number goes into the text (the layout's gap is the Chinese one; "You carry" so it fits the width)
    if (n.label_CountryTreasury3) { n.label_CountryTreasury3.setText('You carry ' + bank + ' national treasure(s)! (Cleared after 24 hours)'); show(n, 'label_my_treasure', false); }
    // numbers right behind their words (the layout's places are the Chinese ones: "3000silver", "Treasure Amount:      1")
    if (n.label_CountryTreasury6 && n.label_handin_silver) n.label_CountryTreasury6.x = n.label_handin_silver.x + n.label_handin_silver.w + 8;
    if (n.label_CountryTreasury4 && n.label_country_treasure) n.label_country_treasure.x = n.label_CountryTreasury4.x + n.label_CountryTreasury4.w + 12;

    async function toGuard() {
      if (!(await send('rl_w_tearguard', { Cmd: 13003 }))) return;
      ui.tip(guard ? 'You stopped guarding the treasury' : 'You now guard your country’s treasury', 2);
      return treasure();
    }
    async function handIn() {
      if (bank <= 0) return ui.tip('You carry no treasure: plunder another country first', 2);
      const r = await send('rl_w_tear', { Cmd: 13002 });
      if (!r) return;
      const a = [...r.children].find((c) => c.nodeName === 'award');
      await HB.game.refresh();
      ui.tip('Turned in: +' + x.a(a, 'coin', 0) + ' silver, +' + x.a(a, 'merit', 0) + ' war exploit', 2.5);
      return treasure();
    }
    async function skip() {
      const cost = nc(25, 15);
      if (!Q.get('act') && !(await HB.confirm('Skip the wait for ' + cost + ' gold?', { ok: 'Skip' }))) return false;
      if (!(await send('rl_w_tearcountry', { Cmd: 13001 }))) return false;
      await HB.game.refresh();
      treasure();
      return true;
    }
    async function raid(to) {
      const r = await send('rl_w_tearcountry', { Cmd: 13000, ToCountry: to });
      if (!r) return treasure();
      const direct = Number(x.a(x.first(r, 'tear'), 'direct', 1)) === 1;
      let won = true;
      if (!direct) { won = Number(x.a(x.first(x.first(r, 'fight'), 'preview'), 'result', 0)) === 1; await HB.fight.play(r, { kind: 'treasure', exp: 0, silver: 0, energy: 0 }); }
      await HB.game.refresh();
      ui.tip(direct ? 'Nobody guarded ' + land(to) + ': you took a treasure!' : won ? 'You beat the guard ' + x.t(x.first(r, 'oppe'), 'nick') + ' and took a treasure!' : 'The guard ' + x.t(x.first(r, 'oppe'), 'nick') + ' drove you off', 2.6);
      return treasure();
    }
    // CTreaureSnatchDialogView: the other countries, what they took today and what was taken from them; pick one, GO
    async function countries() {
      if (left <= 0) return ui.tip('No plunders left today', 2);
      if (cd > 0) return skip();
      const list2 = await send('rl_r_tearcountry', { Cmd: 13000 });
      if (!list2) return;
      const rows = x.all(x.first(list2, 'countrylist'), 'country').map((c) => ({ id: Number(x.a(c, 'id', 0)), tear: x.n(c, 'tearnum'), grab: x.n(c, 'grabnum') })).filter((c) => c.id !== mine).slice(0, 4);
      const w = {};
      await HB.dialog('countrywar/SnatchDialogView', w);
      const d = w.n;
      let pick = 0;
      const mark = () => { for (let k = 1; k <= 4; k++) if (d['sprite_bg' + k]) d['sprite_bg' + k].opacity = k - 1 === pick ? 255 : 90; };
      for (let k = 1; k <= 4; k++) {
        const c = rows[k - 1];
        for (const key of ['sprite_icon', 'label_treasure', 'label_count', 'btn_country', 'sprite_bg']) show(d, key + k, c);
        if (!c) continue;
        flag(d['sprite_icon' + k], c.id); set(d, 'label_treasure' + k, c.tear); set(d, 'label_count' + k, c.grab);
        if (d['btn_country' + k]) d['btn_country' + k].onTap = () => { pick = k - 1; mark(); };
      }
      mark();
      w.onButton = (sel, btn) => {
        if (sel === 'clickCountry1') { const k = [1, 2, 3, 4].find((i) => d['btn_country' + i] === btn); if (k && rows[k - 1]) { pick = k - 1; mark(); } return; }
        w.close();
        if (sel === 'clickFight' && rows[pick]) raid(rows[pick].id);
      };
      return w;
    }
    o.onButton = (sel) => {
      if (sel === 'clickBack' || sel === 'BtnBack') return HB.game.goHome();
      if (sel === 'clickToBeGuard') return toGuard();
      if (sel === 'clickHandIn') return handIn();
      if (sel === 'clickSnatch') return countries();
    };
    runActs({ guard: async () => { await toGuard(); return 'stop'; }, handin: async () => { await handIn(); return 'stop'; }, countries: () => countries(),
      raid: async (c) => { await raid(c); return 'stop'; }, skip: async () => { await skip(); return 'stop'; } });
  };
})();
