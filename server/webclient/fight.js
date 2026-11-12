// Fights: the playback (CRoundTeamFightView, sub_ui/RoundTeamView.ccbi with CNewFightCardView cards, core_combat/
// CoreFightCardView.ccbi) and the result screens (CNewResultWinView / CNewResultFailView). The server has already decided the
// fight (game.js battleXml); this only shows it:
//   <fight><preview result defensenick defenselevel defenseviplevel defensecountry/>
//     <guard><ninjalist><ninja><id><bagid><low><high><end><level><attri><starlevel><newlife>   the enemy's cards (defending)
//     <killer><ninjalist>...                                                                     my cards (attacking)
//     <roundlist><round><AttackNinja><Attack><DefenseNinja><Defense><CauseLimit><LimitVal><FinalAttack><FinalDefense><skills>
//   <award type dropid coin><cardlist><card><id><type><num>...   the prize behind the three cards of the win screen
// A round: my card in front hits the enemy card in front. The bigger number wins and keeps the difference; the loser is out.
// Seen on the phone: the card in front sits in the middle of five places; my waiting cards stand left of it, the enemy's right.
'use strict';
(function () {
  const HB = window.HB;
  const Q = new URLSearchParams(location.search);
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' }; // util/tools.lua getAttributeIcon
  const short = (v) => (v >= 10000 ? Math.floor(v / 1000) + 'K' : String(Math.max(0, Math.round(v)))); // 188178 -> 188K (seen on the phone)
  let tablesReady = null;
  const names = async () => (tablesReady = tablesReady || Promise.all(['ninjainfo', 'equipmentinfo', 'ninjutsuinfo', 'markinfo', 'consumeinfo'].map((t) => HB.ui.table(t))));
  const ninjaRow = (id) => (HB.ui.tables.ninjainfo ? HB.ui.tables.ninjainfo.rows.find((r) => r[1] === id) : null);

  HB.fight = {
    // plays the fight in a server reply; resolves true (won) / false when the player has closed the result screen
    async play(reply, info = {}) {
      const ui = HB.ui, x = ui.x;
      const fight = x.first(reply, 'fight');
      if (!fight) return true;
      await Promise.all([names(), HB.loadCCB('sub_ui/RoundTeamView'), HB.loadCCB('core_combat/CoreFightCardView')]);
      const preview = x.first(fight, 'preview');
      const won = Number(x.a(preview, 'result', 0)) === 1;
      const side = (tag) => x.all(x.first(fight, tag), 'ninja').map((n) => ({ id: x.n(n, 'id'), end: x.n(n, 'end'), level: x.n(n, 'level'), attri: x.n(n, 'attri') }));
      const foes = side('guard'), mine = side('killer');
      const rounds = x.all(x.first(fight, 'roundlist'), 'round').map((r) => ({
        atk: x.n(r, 'Attack'), def: x.n(r, 'Defense'), cause: x.n(r, 'CauseLimit'), finA: x.n(r, 'FinalAttack'), finD: x.n(r, 'FinalDefense'),
        skills: x.all(x.first(r, 'skills'), 'skill').map((s) => ({ card: x.n(s, 'cardid'), add: x.n(s, 'chakraattack') })),
      }));
      // the card pictures: npc/<picture>_combat.plist (CNewFightCardView)
      for (const c of [...foes, ...mine]) { const row = ninjaRow(c.id); c.pic = row ? row[3] : ''; if (c.pic) HB.loadSheetNow('npc/' + c.pic + '_combat.plist'); }

      const cover = ui.modal(255); cover.z = 600;
      const o = {};
      const view = ui.screen('sub_ui/RoundTeamView', o); // a 768-wide layout like the menus (its top bar spans 38..723)
      view.z = 601;
      HB.scene.add(cover); HB.scene.add(view);
      const n = o.n, user = HB.game.user || {};
      n.label_enemyname.setText(x.a(preview, 'defensenick'));
      const vipF = ui.VIP_FRAMES();
      const setVip = (sp, lv) => { const f = HB.frameByName(vipF[Math.min(18, Math.max(0, lv))]); if (f && sp) sp.setFrame(f); };
      setVip(n.sprite_enemyviplevel, Number(x.a(preview, 'defenseviplevel', 0))); setVip(n.sprite_myviplevel, Number(user.viplevel || 0));
      const flag = (sp, c) => { const f = HB.frameByName('cb_country_0' + (Number(c) + 1)); if (f && sp) sp.setFrame(f); }; // (ours: which flag is which country is to check on the phone)
      flag(n.sprite_enemycountry, x.a(preview, 'defensecountry', 0)); flag(n.sprite_mycountry, user.country || 0);
      n.node_myPet.visible = false; n.node_enemyPet.visible = false; // pets: later

      // ---- the two rows of cards
      function row(list, box, sizeNode, isMine) {
        box.clip = true;
        const cw = sizeNode.w, ch = sizeNode.h, slots = Math.max(1, Math.round(box.w / cw));
        const back = HB.frameByName(isMine ? 'core_combat_04' : 'core_combat_05');
        for (let k = 0; k < slots; k++) { const b = new HB.Sprite(back); b.x = (k + 0.5) * cw; b.y = ch / 2; if (back) { b.sx = (cw - 6) / back.sw; b.sy = (ch - 4) / back.sh; } box.add(b); }
        const cards = list.map((c) => {
          const co = {};
          const cell = HB.build('core_combat/CoreFightCardView', co, [cw, ch]);
          cell.ignoreAnchor = true; cell.w = cw; cell.h = ch; cell.y = 0; cell.z = 1;
          const m = co.n;
          const pic = c.pic && HB.frame('npc/' + c.pic + '_combat.plist', c.pic + '_combat');
          if (pic) pic.rot = 0; // the list says "rotated", but it is an upright slice of the big picture (the phone shows the ninja standing)
          const holder = m.node_fightcardicon;
          const art = new HB.Sprite(pic || null);
          if (pic) { art.sx = holder.w / pic.sw; art.sy = holder.h / pic.sh; }
          art.x = holder.w / 2; art.y = holder.h / 2;
          holder.add(art);
          const el = HB.frameByName(ELEMENT[c.attri] || ELEMENT[1]); if (el) m.sprite_ninjacamp.setFrame(el);
          const icon = HB.frameByName(isMine ? 'com_small_attack_icon' : 'com_small_defense_icon'); if (icon) m.sprite_attacktype.setFrame(icon);
          m.sprite_bosstype.visible = false; m.sprite_fightfail.visible = false; m.sprite_redbounder.visible = false; m.node_inlay_frame.visible = false;
          m.sprite_valbk.visible = false;
          box.add(cell);
          return { c, cell, m, art, value: 0, dead: false };
        });
        const place = (cur, quick) => cards.forEach((cd, i) => {
          const slot = isMine ? 2 - (i - cur) : 2 + (i - cur);
          const tx = slot * cw;
          if (quick) cd.cell.x = tx; else HB.tween(cd.cell, { x: tx }, 0.25);
        });
        return { cards, place };
      }
      const A = row(mine, n.node_mycardlist, n.node_mycardsize, true);
      const D = row(foes, n.node_enemycardlist, n.node_enemycardsize, false);
      A.place(0, true); D.place(0, true);
      const counts = (a, d) => {
        n.label_myteamcount.setText(`${mine.length - a}/${mine.length}`);
        n.label_enemyteamcount.setText(`${foes.length - d}/${foes.length}`);
      };
      counts(0, 0);
      const showVal = (cd, v) => { cd.value = v; cd.m.sprite_valbk.visible = true; cd.m.label_effectval.setText(short(v)); };
      const kill = (cd) => { cd.dead = true; cd.art.grey = true; cd.m.sprite_fightfail.visible = true; cd.m.sprite_redbounder.visible = false; showVal(cd, 0); HB.play(cd.cell, 'Default Timeline'); };
      const front = (cd, on) => { cd.m.sprite_redbounder.visible = on; };

      // ---- the rounds
      let skip = false;
      o.onButton = (sel) => { if (sel === 'BtnPass') skip = true; };
      const wait = async (sec) => { if (!skip) await HB.wait(sec); };
      let i = 0, j = 0;
      if (Q.get('fightwait')) await HB.wait(Number(Q.get('fightwait'))); // test switch: hold the first picture (screenshots)
      for (const r of rounds) {
        if (i >= A.cards.length || j >= D.cards.length) break;
        const a = A.cards[i], d = D.cards[j];
        const bonus = r.skills.reduce((t, s) => t + s.add, 0);
        showVal(a, r.atk + bonus); showVal(d, r.def);
        front(a, true); front(d, true);
        if (!skip) { HB.play(a.cell, 'showlight'); await wait(0.35); }
        const aWins = r.finA > r.finD, dWins = r.finA < r.finD;
        const loser = aWins ? d : dWins ? a : null;
        if (!skip) { if (loser) HB.play(loser.cell, 'gethurt'); else { HB.play(a.cell, 'gethurt'); HB.play(d.cell, 'gethurt'); } await wait(0.45); }
        if (aWins) { kill(d); showVal(a, r.finA - r.finD); j++; }
        else if (dWins) { kill(a); showVal(d, r.finD - r.finA); i++; }
        else { kill(a); kill(d); i++; j++; }
        front(a, false); front(d, false);
        HB.play(a.cell, 'Default Timeline');
        counts(i, j);
        A.place(i, skip); D.place(j, skip);
        await wait(0.3);
      }
      counts(won ? i : mine.length, won ? foes.length : j);
      await wait(0.4);

      // ---- the result
      await result(reply, { won, preview, foes, mine, rounds, info });
      cover.removeSelf(); view.removeSelf();
      return won;
    },
  };

  async function result(reply, f) {
    const ui = HB.ui, x = ui.x;
    const file = f.won ? 'core_combat/NewFightResult_WinView' : 'core_combat/NewFightResult_FailView';
    await HB.loadCCB(file);
    const o = {};
    const view = ui.screen(file, o);
    view.z = 610;
    HB.scene.add(view);
    const n = o.n, user = HB.game.user || {};
    const set = (k, v) => { if (n[k]) n[k].setText(String(v)); };
    set('label_mylevel', user.level || 1); set('label_enemylevel', x.a(f.preview, 'defenselevel', 1));
    set('label_myname', user.nick || ''); set('label_enemyname', x.a(f.preview, 'defensenick'));
    // the totals: my cards' attack and the enemy cards' defence (<end>), and how often each side's element beat the other's
    set('level_myattack', f.mine.reduce((t, c) => t + c.end, 0)); set('label_enemyattack', f.foes.reduce((t, c) => t + c.end, 0));
    set('label_myRestrain', f.rounds.filter((r) => r.cause === 1).length); set('label_enemyRestrain', f.rounds.filter((r) => r.cause === -1).length);
    const award = x.first(reply, 'award');
    const closed = new Promise((ok) => { o.close = ok; });
    if (f.won) {
      // the phone shows the layout's resting state (the face between the two panels), not its 'showwinanim' timeline; the rays turn
      if (n.sprite_lightview) { const spin = () => HB.tween(n.sprite_lightview, { rot: n.sprite_lightview.rot + 360 }, 8, spin); spin(); }
      set('label_round_getexp', '+' + (f.info.exp || 0)); set('label_round_getsilver', '+' + (f.info.silver || 0));
      set('label_round_getgold', award ? x.n(award, 'cash') : 0); set('label_round_needbdoy', 0);
      const prize = prizeOf(award);
      // the three cards to draw from: core_combat/RS_WinAnim.ccbi laid into layer_round_selectanim. "normalshow" makes them pulse;
      // "animshow<k>" turns card k over first and then the other two. The prize is already decided by the server (<award>).
      await HB.loadCCB('core_combat/RS_WinAnim');
      const ro = {};
      const box = n.layer_round_selectanim;
      const rs = HB.build('core_combat/RS_WinAnim', ro, [box.w, box.h]);
      rs.x = rs.ignoreAnchor ? 0 : rs.ax * rs.w; rs.y = rs.ignoreAnchor ? 0 : rs.ay * rs.h;
      const draw = ['btn_round__select1', 'btn_round_select2', 'btn_round_select3'].map((k) => n[k]).filter(Boolean);
      draw.forEach((b) => { b.opacity = 0; }); // the buttons only catch the tap; the cards drawn are RS_WinAnim's
      for (const k of ['btn_round_teamcompare', 'sprite_round_teamcompare']) if (n[k]) n[k].visible = false; // not shown after a training fight (seen on the phone)
      if (n.btn_back) n.btn_back.visible = !prize;
      if (prize) { box.add(rs); HB.play(rs, 'normalshow'); } else draw.forEach((b) => { b.visible = false; });
      let picked = false;
      if (Q.get('pick')) { setTimeout(() => o.onButton('onSelectCard' + Q.get('pick')), 1500); if (Q.get('close')) setTimeout(() => o.close(), 4500); } // test switches
      o.onButton = (sel) => {
        if (sel === 'onBtnBack') return o.close();
        const m = /^onSelectCard([123])/.exec(sel);
        if (m && prize && !picked) {
          picked = true;
          const k = Number(m[1]);
          for (const c of [1, 2, 3]) {
            const icon = ro.n['sprite_itemicon' + c], name = ro.n['label_itemname' + c], stars = ro.n['node_award_container' + c], plate = ro.n['node_item_container' + c];
            if (stars) stars.removeSelf();
            if (c !== k) { for (const nd of [icon, plate]) if (nd) nd.removeSelf(); continue; } // the other two only turn over
            const f = prize.icon && (HB.frameByName('icon_' + prize.icon) || HB.frameByName(prize.icon));
            if (icon) { delete icon.anims; icon.visible = true; if (f) { icon.setFrame(f); icon.sx = icon.sy = 84 / Math.max(f.sw, f.sh); } else icon.visible = false; }
            if (name) name.setText(prize.text);
          }
          HB.play(rs, 'animshow' + k, () => { if (n.btn_back) n.btn_back.visible = true; });
        }
      };
    } else {
      set('label_getexp', '+0'); set('label_getsilver', '+0'); set('label_getgold', '+0'); set('label_needbdoy', '+0');
      o.onButton = (sel) => {
        if (sel === 'onBtnBack') return o.close();
        ui.tip('Coming soon: ' + sel.replace(/^onBtn/, ''), 1.2);
      };
    }
    await closed;
    view.removeSelf();
  }

  // what the <award> holds, in words and with a picture name when there is one
  function prizeOf(award) {
    if (!award) return null;
    const x = HB.ui.x, T = HB.ui.tables;
    const parts = [];
    let icon = '';
    for (const c of x.all(x.first(award, 'cardlist'), 'card')) {
      const id = x.n(c, 'id'), type = x.n(c, 'type'), num = x.n(c, 'num') || 1;
      const table = type === 1 ? T.ninjainfo : type === 6 ? T.ninjutsuinfo : type === 5 ? T.markinfo : T.equipmentinfo;
      const row = table && table.rows.find((r) => r[1] === id);
      parts.push((row ? row[2] : 'Card ' + id) + (num > 1 ? ' x' + num : ''));
      if (!icon && row && typeof row[3] === 'string') icon = row[3];
    }
    for (const p of x.all(x.first(award, 'proplist'), 'prop')) {
      const id = x.n(p, 'id') || Number(x.a(p, 'id', 0)), num = x.n(p, 'num') || Number(x.a(p, 'num', 1));
      const row = T.consumeinfo && T.consumeinfo.rows.find((r) => r[1] === id);
      parts.push((row ? row[2] : 'Item ' + id) + (num > 1 ? ' x' + num : ''));
      if (!icon && row && typeof row[3] === 'string') icon = row[3];
    }
    const coin = x.n(award, 'coin'), cash = x.n(award, 'cash'), soul = x.n(award, 'soul');
    if (coin) { parts.push(coin + ' silver'); icon = icon || 'com_silver_icon'; }
    if (cash) { parts.push(cash + ' gold'); icon = icon || 'com_gold_icon'; }
    if (soul) parts.push(soul + ' souls');
    if (!parts.length) return null;
    return { text: parts.join(', '), icon };
  }
})();
