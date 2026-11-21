// Fights: the playback (CRoundTeamFightView, sub_ui/RoundTeamView.ccbi with CNewFightCardView cards, core_combat/
// CoreFightCardView.ccbi) and the result screens (CNewResultWinView / CNewResultFailView). The server has already decided the
// fight (game.js battleXml); this only shows it:
//   <fight><preview result defensenick defenselevel defenseviplevel defensecountry/>
//     <guard><ninjalist><ninja><id><bagid><low><high><end><level><attri><starlevel><newlife>   the enemy's cards (defending)
//     <killer><ninjalist>... <master_pet><id><pet_id>                                           my cards (attacking), my pet
//     <roundlist><round><AttackNinja><Attack><DefenseNinja><Defense><CauseLimit><LimitVal><FinalAttack><FinalDefense>
//                       <AttPetSkillHurt><skills><skill><cardid><chakraattack><chakra>
//   <award type dropid coin><cardlist><card><id><type><num>...   the prize behind the three cards of the win screen
// A round: my card in front hits the enemy card in front. The bigger number wins and keeps the difference; the loser is out.
// Seen on the phone: the card in front sits in the middle of five places; my waiting cards stand left of it, the enemy's right.
//
// What a round plays, in the order of CRoundTeamFightView::completedAnimationSequenceNamed (libgame.so):
//   a ninjutsu fired   the card's "preskill" flash -> the cut-in (core_combat/CoreFightSkillView "showskill": the ninja's big
//                      picture slides through, the ninjutsu's name, what it adds) -> the ninjutsu's own effect
//                      (animations/<ninjutsuinfo m_effectid>, timeline "SkillEffectComplete"; the hit shakes the enemy card)
//                      -> "Skill bonus: +N" (core_combat/ShowEffectView "showMySkillEffect") -> the card's "+N" ("showgetval")
//   my pet's skill     core_combat/PetSkill_ef2 on the pet badge -> PetSkill_ef3 (the pet's picture grows) -> PetSkill_ef
//                      (the claw) on the enemy card -> the card's "+N"
//   element restrain   core_combat/RestraintView with the "X beats Y" picture -> "Constrain damage: -N" on the beaten side
//   the hit            core_combat/ShowRayView "showray" (the blade), both cards "gethurt" + "showhurtval" with "-N"
// Card frames (CNewFightCardView::InitUI): the ray background and the corner bar by the ninja's stars (name tables in
// libgame.so at 0x8781d8 / 0x8781f4), the glow of a grown card (CGameObjElement::SetCombatFrameShadowBack / Front:
// animations/shadow/<Green 3-5 | Yellow 6-8 | Blue 9-11 | Purple 12+>FrameLongShadow*.ccbi by growth level).
'use strict';
(function () {
  const HB = window.HB;
  const Q = new URLSearchParams(location.search);
  const ELEMENT = { 1: 'com_text_water_icon', 2: 'com_text_fire_icon', 3: 'com_text_wind_icon', 4: 'com_text_soild_icon', 5: 'com_text_thunder_icon' }; // util/tools.lua getAttributeIcon
  const CARD_FRAME = ['06', '06', '07', '08', '09', '10', '11'].map((s) => 'core_combat_' + s); // by stars 0-6: grey, grey, yellow, green, blue, purple, orange
  const CARD_BAR = ['24', '24', '26', '27', '28', '25', '25'].map((s) => 'core_combat_' + s);
  // the "X beats Y" pictures by the winning element (0-5): drawn upwards when my card (below) beats theirs, downwards when theirs beats mine
  const LIMIT_UP = ['31', '31', '32', '33', '35', '34'].map((s) => 'core_combat_' + s);
  const LIMIT_DOWN = ['18', '18', '17', '16', '14', '15'].map((s) => 'core_combat_' + s);
  // the country flags of the top and bottom bar: country 0 Wind, 1 Thunder, 2 Water, 3 Fire, 4 Earth (the village rule,
  // CProfileData::firefly_GetCountryLayoutName; which flag picture goes with which number is not checked on the phone)
  const FLAG = { 0: 'cb_country_04', 1: 'cb_country_03', 2: 'cb_country_02', 3: 'cb_country_01', 4: 'cb_country_05' };
  const short = (v) => (v >= 10000 ? Math.floor(v / 1000) + 'K' : String(Math.max(0, Math.round(v)))); // 188178 -> 188K (seen on the phone)
  const num = (v) => (v >= 1000000 ? short(v) : String(Math.round(v))); // the numbers that fly off a card
  let tablesReady = null;
  const names = async () => (tablesReady = tablesReady || Promise.all(['ninjainfo', 'equipmentinfo', 'ninjutsuinfo', 'markinfo', 'consumeinfo', 'petinfo'].map((t) => HB.ui.table(t))));
  const rowOf = (table, id) => { const t = HB.ui.tables[table]; return t ? t.rows.find((r) => r[1] === id) || null : null; };
  const shadowOf = (star) => (star >= 12 ? 'Purple' : star >= 9 ? 'Blue' : star >= 6 ? 'Yellow' : star >= 3 ? 'Green' : '');
  // how long a layout's timeline runs, with the timelines it goes on to by itself
  const durOf = (root, name) => {
    const d = root && root.doc; if (!d) return 0;
    let s = d.seqs.find((q) => q.name === name), t = 0; const seen = new Set();
    while (s && !seen.has(s.id)) { seen.add(s.id); t += s.dur; s = s.next >= 0 ? d.seqs.find((q) => q.id === s.next) : null; }
    return t;
  };
  // which win-screen part a kind of fight uses (CNewResultWinView::InitUI, by CFightResultData's fight type)
  const WIN_PART = { round: 'round', train: 'round', plunder: 'plunder', war: 'cw', arena: 'areana', boss: 'wb', tower: 'tower' };
  const WIN_PARTS = ['round', 'plunder', 'cw', 'areana', 'wb', 'tower', 'normal'];
  const LABEL_OF = { round: 'round', plunder: 'plunder', cw: 'cw', areana: 'ar', wb: 'wb', tower: 'tower', normal: 'normal' };

  HB.fight = {
    // plays the fight in a server reply; resolves true (won) / false when the player has closed the result screen.
    // info: { kind: 'round' | 'train' | 'spar' | 'plunder' | 'arena' | 'tower' | 'war' | 'boss' | ..., exp, silver, energy, boss }
    //         boss = a boss stage (the boss mark on a card), noResult = no result screen (a World Boss hit), feats / kills / failExp = numbers for the result screen
    async play(reply, info = {}) {
      const ui = HB.ui, x = ui.x;
      const fight = x.first(reply, 'fight');
      if (!fight) return true;
      const preview = x.first(fight, 'preview');
      const won = Number(x.a(preview, 'result', 0)) === 1;
      const side = (tag) => x.all(x.first(fight, tag), 'ninja').map((n) => ({ id: x.n(n, 'id'), end: x.n(n, 'end'), level: x.n(n, 'level'), attri: x.n(n, 'attri'), star: x.n(n, 'starlevel'), newlife: x.n(n, 'newlife') }));
      const foes = side('guard'), mine = side('killer');
      const rounds = x.all(x.first(fight, 'roundlist'), 'round').map((r) => ({
        atk: x.n(r, 'Attack'), def: x.n(r, 'Defense'), cause: x.n(r, 'CauseLimit'), limit: x.n(r, 'LimitVal'), finA: x.n(r, 'FinalAttack'), finD: x.n(r, 'FinalDefense'),
        pet: x.n(r, 'AttPetSkillHurt'),
        skills: x.all(x.first(r, 'skills'), 'skill').map((s) => ({ card: x.n(s, 'cardid'), add: x.n(s, 'chakraattack'), chakra: x.n(s, 'chakra') })),
      }));
      const petId = x.n(x.first(x.first(fight, 'killer'), 'master_pet'), 'pet_id');
      await names();
      const pet = petId ? rowOf('petinfo', petId) : null;
      // everything the fight will show, loaded before it starts: the layouts, each card's picture, the ninjutsu effects that fire
      const effects = new Set();
      for (const r of rounds) for (const s of r.skills) { const nj = rowOf('ninjutsuinfo', s.card); s.row = nj; if (nj && nj[7]) { s.effect = 'animations/' + String(nj[7]).replace(/\.ccbi?$/i, ''); effects.add(s.effect); } }
      const shadows = new Set([...foes, ...mine].map((c) => shadowOf(c.star)).filter(Boolean));
      const files = ['sub_ui/RoundTeamView', 'core_combat/CoreFightCardView', 'core_combat/CoreFightSkillView', 'core_combat/RestraintView', 'core_combat/ShowEffectView',
        'core_combat/ShowRayView', 'animations/hexinzhandou_donghua3', ...effects,
        ...(pet ? ['core_combat/PetSkill_ef', 'core_combat/PetSkill_ef2', 'core_combat/PetSkill_ef3'] : []),
        ...[...shadows].flatMap((c) => ['animations/shadow/' + c + 'FrameLongShadowBack', 'animations/shadow/' + c + 'FrameLongShadowFront'])];
      await Promise.all(files.map((f) => HB.loadCCB(f)));
      // the card pictures: npc/<picture>_combat.plist (CNewFightCardView)
      for (const c of [...foes, ...mine]) { const row = rowOf('ninjainfo', c.id); c.row = row; c.pic = row ? row[3] : ''; c.quality = row ? Math.max(0, Math.min(6, row[11] || 0)) : 1; if (c.pic) HB.loadSheetNow('npc/' + c.pic + '_combat.plist'); }

      HB.fight.now = 'fight'; // for tests: 'fight' while the cards play, 'result' on the result screen, '' when closed
      const cover = ui.modal(255); cover.z = 600;
      const o = {};
      const view = ui.screen('sub_ui/RoundTeamView', o); // a 768-wide layout like the menus (its top bar spans 38..723)
      view.z = 601;
      HB.scene.add(cover); HB.scene.add(view);
      const n = o.n, user = HB.game.user || {};
      n.label_enemyname.setText(x.a(preview, 'defensenick'));
      if (n.label_enemyname.w > 236) n.label_enemyname.sx = n.label_enemyname.sy = Math.max(0.6, 236 / n.label_enemyname.w); // stays left of the VIP badge (ours: the phone lets a long name run under it)
      const vipF = ui.VIP_FRAMES();
      const setVip = (sp, lv) => { const f = HB.frameByName(vipF[Math.min(18, Math.max(0, lv))]); if (f && sp) sp.setFrame(f); };
      setVip(n.sprite_enemyviplevel, Number(x.a(preview, 'defenseviplevel', 0))); setVip(n.sprite_myviplevel, Number(user.viplevel || 0));
      const flag = (sp, c) => { const f = HB.frameByName(FLAG[Number(c)] || FLAG[3]); if (f && sp) sp.setFrame(f); };
      flag(n.sprite_enemycountry, x.a(preview, 'defensecountry', 0)); flag(n.sprite_mycountry, user.country || 0);
      // my master pet's badge on my row (CRoundTeamFightView::InitUI: petinfo's picture in sp_myPet); the server sends no enemy pet
      n.node_enemyPet.visible = false;
      n.node_myPet.visible = !!pet;
      if (pet) {
        const f = HB.iconFrame(1, pet[3]);
        if (f && n.sp_myPet) { const bg = n.sp_myPet, pic = new HB.Sprite(f); pic.sx = pic.sy = Math.min(bg.w / (f.sw || 1), bg.h / (f.sh || 1)) * 0.92; pic.x = bg.w / 2; pic.y = bg.h / 2; bg.add(pic); }
      }
      const animBox = n.node_animcontent; animBox.z = 50;
      // a full-screen effect layer on top of the cards
      const layer = (file, owner = {}) => { const l = HB.build(file, owner, [animBox.w, animBox.h]); l.x = l.ignoreAnchor ? 0 : l.ax * l.w; l.y = l.ignoreAnchor ? 0 : l.ay * l.h; animBox.add(l); return l; };

      // ---- the two rows of cards
      const bossCard = info.boss ? foes.reduce((b, c) => (!b || c.end > b.end ? c : b), null) : null; // the boss mark: on their strongest card (ours: which card wore it is not known)
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
          // the frame by the ninja's stars: the ray background behind the picture and the corner bar around it
          const bg = HB.frameByName(CARD_FRAME[c.quality]), bar = HB.frameByName(CARD_BAR[c.quality]);
          if (bg) { const inner = m.sprite_cardframe.parent; m.sprite_cardframe.setFrame(bg); m.sprite_cardframe.sx = (inner.w - 4) / bg.sw; m.sprite_cardframe.sy = (inner.h - 4) / bg.sh; }
          if (bar) m.sprite_framebar.frame = bar;
          const el = HB.frameByName(ELEMENT[c.attri] || ELEMENT[1]); if (el) m.sprite_ninjacamp.setFrame(el);
          const icon = HB.frameByName(isMine ? 'com_small_attack_icon' : 'com_small_defense_icon'); if (icon) m.sprite_attacktype.setFrame(icon);
          m.sprite_bosstype.visible = c === bossCard; m.sprite_fightfail.visible = false; m.sprite_redbounder.visible = false; m.node_inlay_frame.visible = false;
          m.sprite_valbk.visible = false;
          // a grown card glows: behind the picture and over it
          const glow = shadowOf(c.star);
          if (glow) for (const [part, host] of [['Back', m.node_shadow_back], ['Front', m.node_shadow_front]]) {
            const g = HB.build('animations/shadow/' + glow + 'FrameLongShadow' + part, {}, [host.w, host.h]);
            g.x = g.ignoreAnchor ? 0 : g.ax * g.w; g.y = g.ignoreAnchor ? 0 : g.ay * g.h; host.add(g); HB.play(g, 'action');
          }
          box.add(cell);
          const inner = m.sprite_cardframe.parent;
          return { c, cell, m, art, inner, home: [inner.x, inner.y], flashes: inner.children.filter((k) => k.cls === 'CCLayerColor'), value: 0, dead: false, mine: isMine };
        });
        const place = (cur, quick) => cards.forEach((cd, i) => {
          const slot = isMine ? 2 - (i - cur) : 2 + (i - cur);
          const tx = slot * cw;
          if (quick) cd.cell.x = tx; else HB.tween(cd.cell, { x: tx }, 0.25);
        });
        return { cards, place, cw };
      }
      const A = row(mine, n.node_mycardlist, n.node_mycardsize, true);
      const D = row(foes, n.node_enemycardlist, n.node_enemycardsize, false);
      A.place(0, true); D.place(0, true);
      const counts = (a, d) => {
        n.label_myteamcount.setText(`${mine.length - a}/${mine.length}`);
        n.label_enemyteamcount.setText(`${foes.length - d}/${foes.length}`);
      };
      counts(0, 0);

      // ---- Skip, waiting, and the small steps every round is made of
      const st = { skip: false };
      st.skipP = new Promise((ok) => { st.go = ok; });
      const doSkip = () => { if (st.skip) return; st.skip = true; animBox.removeAll(); st.go(); };
      o.onButton = (sel) => { if (sel === 'BtnPass') doSkip(); };
      const sleep = (sec) => (st.skip || !(sec > 0) ? Promise.resolve() : Promise.race([HB.wait(sec), st.skipP]));
      const anim = (root, name, extra = 0) => { if (st.skip) return Promise.resolve(); HB.play(root, name); return sleep(durOf(root, name) + extra); };
      // a card's number: it runs to the new value (CNewFightCardView::update)
      const setVal = (cd, v, roll) => {
        const from = cd.value; cd.value = v; cd.m.sprite_valbk.visible = true;
        if (cd.roll) { cd.roll.stop = true; cd.roll = null; }
        if (!roll || st.skip || from === v) return void cd.m.label_effectval.setText(short(v));
        const r = { t: 0, stop: false }; cd.roll = r;
        HB.tween(r, { t: 1 }, 0.35);
        const step = () => { if (r.stop) return; cd.m.label_effectval.setText(short(from + (v - from) * r.t)); if (r.t < 1) requestAnimationFrame(step); else cd.roll = null; };
        step();
      };
      const still = (cd) => { // a card at rest: no number in the air, no flash, back in its place
        HB.play(cd.cell, 'Default Timeline');
        cd.m.label_getval.visible = false; cd.m.label_hurtval.visible = false; cd.flashes.forEach((f) => { f.visible = false; });
        cd.inner.x = cd.home[0]; cd.inner.y = cd.home[1];
      };
      const front = (cd, on) => { cd.m.sprite_redbounder.visible = on && !cd.dead; if (on && !cd.dead && !st.skip) HB.play(cd.cell, 'showlight'); else still(cd); };
      const kill = (cd) => { cd.dead = true; cd.art.grey = true; cd.m.sprite_fightfail.visible = true; cd.m.sprite_redbounder.visible = false; setVal(cd, 0); still(cd); };
      // "+N" / "-N" over a card (its "showgetval" timeline), then the number itself changes
      const gain = async (cd, delta, to) => {
        if (!st.skip) { cd.m.label_getval.setText((delta >= 0 ? '+' : '-') + num(Math.abs(delta))); await anim(cd.cell, 'showgetval'); }
        setVal(cd, to, true);
        if (!st.skip) front(cd, true);
      };
      // the ShowEffectView line ("Skill bonus: +N" / "Constrain damage: -N") on one side
      const eo = {}; const effView = layer('core_combat/ShowEffectView', eo);
      const EFF = ['layer_enemyeffect', 'layer_limitenemy', 'layer_myeffect', 'layer_limitmy'];
      EFF.forEach((k) => { if (eo.n[k]) eo.n[k].visible = false; });
      const effect = async (which, label, text, seq) => { // CRoundTeamFightView::setEffectLayer
        if (st.skip) return;
        if (!effView.parent) animBox.add(effView);
        EFF.forEach((k) => { if (eo.n[k]) eo.n[k].visible = k === which; });
        if (eo.n[label]) eo.n[label].setText(text);
        await anim(effView, seq);
        if (eo.n[which]) eo.n[which].visible = false;
      };

      // ---- a ninjutsu fires: flash, cut-in, the ninjutsu's own effect, the bonus
      async function ninjutsu(a, d, s) {
        if (!st.skip) {
          await anim(a.cell, 'preskill');
          const so = {}; const cut = layer('core_combat/CoreFightSkillView', so);
          const big = a.c.pic && (HB.frameByName(a.c.pic) || HB.iconFrame(1, a.c.pic, true));
          if (so.n.sprite_ninjaicon) { if (big) { so.n.sprite_ninjaicon.setFrame(big); const k = Math.min(1, 420 / (big.sh || 420)); so.n.sprite_ninjaicon.sx = so.n.sprite_ninjaicon.sy = k; } else so.n.sprite_ninjaicon.visible = false; }
          so.n.label_ninjustuname.setText(s.row ? String(s.row[2]) : 'Ninjutsu');
          if (so.n.label_ninjustuname.w > animBox.w * 0.86) so.n.label_ninjustuname.sx = so.n.label_ninjustuname.sy = animBox.w * 0.86 / so.n.label_ninjustuname.w; // a long English name stays on the screen
          so.n.label_addattack.setText('Skill damage increase: ' + s.add); // the phone's words (owner's video of v28)
          so.n.label_addchackra.setText('(Chakra increase: ' + s.chakra + ')');
          so.n.label_ninjawords.setText(a.c.row && typeof a.c.row[17] === 'string' ? a.c.row[17] : '');
          if (so.n.label_ninjawords.w > animBox.w * 0.8) so.n.label_ninjawords.sx = so.n.label_ninjawords.sy = Math.max(0.5, animBox.w * 0.8 / so.n.label_ninjawords.w);
          await anim(cut, 'showskill');
          cut.removeSelf();
          if (s.effect && !st.skip) {
            const fx = layer(s.effect);
            const seq = fx.doc && fx.doc.seqs.find((q) => q.name === 'SkillEffectComplete');
            if (seq) {
              // the effect's own marks: the enemy card shakes from "SkillEffectHitBegin" to "SkillEffectHitEnd"
              const mark = (name) => { const cb = (seq.cb || []).find((c) => c[1] === name); return cb ? cb[0] : -1; };
              const t0 = mark('SkillEffectHitBegin'), t1 = mark('SkillEffectHitEnd');
              HB.play(fx, 'SkillEffectComplete');
              if (t0 >= 0) {
                await sleep(t0);
                const until = Math.max(t0 + 0.27, t1 >= 0 ? t1 : t0 + 0.27);
                for (let t = t0; t < until && !st.skip; t += 0.27) { HB.play(d.cell, 'shake'); await sleep(0.27); }
                if (!st.skip) front(d, true);
                await sleep(seq.dur - until);
              } else await sleep(seq.dur);
            }
            fx.removeSelf();
          }
          await effect('layer_myeffect', 'label_myskillval', '+' + num(s.add), 'showMySkillEffect');
        }
        await gain(a, s.add, a.value + s.add);
      }
      // ---- my pet's skill: the badge lights up, the pet jumps in, its claw lands on the enemy card
      async function petSkill(a, d, hurt) {
        if (!st.skip && pet) {
          const host = n.node_animMypet;
          const g = HB.build('core_combat/PetSkill_ef2', {}, [host.w, host.h]); g.x = g.ignoreAnchor ? 0 : g.ax * g.w; g.y = g.ignoreAnchor ? 0 : g.ay * g.h; host.add(g);
          await anim(g, 'petSkill2'); g.removeSelf();
          if (!st.skip) {
            const po = {}; const jump = layer('core_combat/PetSkill_ef3', po);
            const f = HB.iconFrame(1, pet[3]);
            for (const k of ['sp_pet1', 'sp_pet2', 'sp_pet3']) if (po.n[k] && f) po.n[k].setFrame(f);
            await anim(jump, 'petSkill3'); jump.removeSelf();
          }
          if (!st.skip) {
            const claw = layer('core_combat/PetSkill_ef');
            const p = claw.children[0]; // onto the enemy card in front
            if (p) { const mid = HB.M.apply(d.cell.world(), d.cell.w / 2, d.cell.h / 2); [p.x, p.y] = claw.toLocal(mid[0], mid[1]); }
            HB.play(d.cell, 'gethurt');
            await anim(claw, 'petSkill'); claw.removeSelf();
            if (!st.skip) front(d, true);
          }
        }
        await gain(a, hurt, a.value + hurt);
      }
      // ---- element restrain: the "X beats Y" picture, then the beaten side loses LimitVal
      async function restrain(a, d, r) {
        const mineWins = r.cause > 0;
        if (!st.skip) {
          const ro = {}; const rv = layer('core_combat/RestraintView', ro);
          const icon = ro.n.sprite_limiticon, f = HB.frameByName((mineWins ? LIMIT_UP : LIMIT_DOWN)[mineWins ? a.c.attri : d.c.attri] || '');
          const bar = rv.children.find((c) => c !== icon);
          if (icon && f) icon.setFrame(f);
          // the layout's own timeline carries no movement here: the light column opens, the picture drops in, both fade (by eye)
          if (bar && icon) { bar.x = icon.x; bar.y = icon.y - bar.h / 2; bar.sy = 0; bar.opacity = 200; HB.tween(bar, { sy: 1 }, 0.18); }
          if (icon) { icon.opacity = 0; icon.sx = icon.sy = 2.2; HB.tween(icon, { sx: 1.2, sy: 1.2, opacity: 255 }, 0.2); }
          await sleep(durOf(rv, 'showprops') - 0.13);
          if (icon) HB.tween(icon, { opacity: 0 }, 0.13); if (bar) HB.tween(bar, { opacity: 0 }, 0.13);
          await sleep(0.13);
          rv.removeSelf();
          if (mineWins) await effect('layer_limitenemy', 'label_limitenemyval', '-' + num(r.limit), 'showLimitEnemyEffect');
          else await effect('layer_limitmy', 'label_limitmyval', '-' + num(r.limit), 'showLimitMyEffect');
        }
        if (mineWins) await gain(d, -r.limit, r.finD); else await gain(a, -r.limit, r.finA);
      }

      // ---- the rounds
      let i = 0, j = 0;
      if (Q.get('fightwait')) await HB.wait(Number(Q.get('fightwait'))); // test switch: hold the first picture (screenshots)
      if (!st.skip) { const vs = layer('animations/hexinzhandou_donghua3'); await anim(vs, 'hexinvs'); vs.removeSelf(); } // the opening flash (CRoundTeamFightView::InitUI)
      for (const r of rounds) {
        if (i >= A.cards.length || j >= D.cards.length) break;
        const a = A.cards[i], d = D.cards[j];
        setVal(a, r.atk); setVal(d, r.def);
        front(a, true); front(d, true);
        await sleep(0.35);
        for (const s of r.skills) await ninjutsu(a, d, s);
        if (r.pet) await petSkill(a, d, r.pet);
        if (r.cause && r.limit) await restrain(a, d, r);
        // the hit: the blade between the two cards, both lose what the other had
        if (!st.skip) {
          const ray = layer('core_combat/ShowRayView');
          HB.play(ray, 'showray');
          const hurt = '-' + num(Math.min(r.finA, r.finD));
          a.m.label_hurtval.setText(hurt); d.m.label_hurtval.setText(hurt);
          HB.play(a.cell, 'gethurt'); HB.play(d.cell, 'gethurt');
          await sleep(durOf(a.cell, 'gethurt'));
          ray.removeSelf();
        }
        const aWins = r.finA > r.finD, dWins = r.finA < r.finD;
        if (aWins) { kill(d); setVal(a, r.finA - r.finD, true); j++; }
        else if (dWins) { kill(a); setVal(d, r.finD - r.finA, true); i++; }
        else { kill(a); kill(d); i++; j++; }
        front(a, false); front(d, false);
        counts(i, j);
        A.place(i, st.skip); D.place(j, st.skip);
        await sleep(0.35);
      }
      counts(won ? i : mine.length, won ? foes.length : j);
      await sleep(0.4);
      animBox.removeAll();

      // ---- the result
      HB.fight.now = 'result';
      const help = info.noResult ? null : await result(reply, { won: Q.get('fightfail') ? false : won, preview, foes, mine, rounds, info });
      cover.removeSelf(); view.removeSelf();
      HB.fight.now = '';
      if (help) openHelp(help);
      return won;
    },
    // a fight the game's own scripts start (World Boss, No.1 Shinobi, Ninja Test): the <fight> and <award> as XML text
    playXml(text, info = {}) {
      const doc = new DOMParser().parseFromString('<root>' + text + '</root>', 'text/xml');
      return HB.fight.play(doc.documentElement, info);
    },
  };

  // ---- the Defeat screen's help buttons lead to another screen (CNewResultFailView::onBtnPray ... : ChangeToSub, then closeThis).
  // The screen that started the fight puts itself back first (it waits for this fight to end), so the help screen opens right
  // after that screen is shown again, or after a moment when nothing is shown again (a fight started by a script).
  let pending = null, hooked = false;
  function openHelp(name) {
    const seq = () => { const t = (HB.data.team || [])[0]; return t ? t.seq : (HB.data.ofType(1)[0] || {}).seq; };
    const go = { shop: () => HB.screens.shop && HB.screens.shop(0), upgrade: () => HB.screens.upgrade && HB.screens.upgrade(seq()), growth: () => HB.screens.growth && HB.screens.growth(seq()),
      potential: () => HB.screens.potential && HB.screens.potential(seq()), rebirth: () => HB.screens.rebirth && HB.screens.rebirth(seq()),
      team: () => HB.screens.team && HB.screens.team(0), gear: () => HB.screens.backpack && HB.screens.backpack(2) }[name];
    if (!go) return;
    const run = () => { if (pending !== run) return; pending = null; go(); };
    pending = run;
    if (!hooked && HB.game && HB.game.showSub) {
      hooked = true;
      const showSub = HB.game.showSub;
      HB.game.showSub = function (...a) { const r = showSub.apply(this, a); const p = pending; if (p) setTimeout(p, 0); return r; };
    }
    setTimeout(run, 3000);
  }

  // the result screen; resolves with the help screen the player chose on the Defeat screen (or nothing)
  async function result(reply, f) {
    const ui = HB.ui, x = ui.x;
    const file = f.won ? 'core_combat/NewFightResult_WinView' : 'core_combat/NewFightResult_FailView';
    await HB.loadCCB(file);
    const o = {};
    const view = ui.screen(file, o);
    view.z = 610;
    HB.scene.add(view);
    const n = o.n, user = HB.game.user || {}, info = f.info;
    const set = (k, v) => { if (n[k]) n[k].setText(String(v)); };
    const hide = (...ks) => { for (const k of ks) if (n[k]) n[k].visible = false; };
    set('label_mylevel', user.level || 1); set('label_enemylevel', x.a(f.preview, 'defenselevel', 1));
    set('label_myname', user.nick || ''); set('label_enemyname', x.a(f.preview, 'defensenick'));
    for (const k of ['label_myname', 'label_enemyname']) if (n[k] && n[k].w > 250) n[k].sx = n[k].sy = Math.max(0.55, 250 / n[k].w); // inside its panel
    // the totals: my cards' attack and the enemy cards' defence (<end>), and how often each side's element beat the other's
    set('level_myattack', f.mine.reduce((t, c) => t + c.end, 0)); set('label_enemyattack', f.foes.reduce((t, c) => t + c.end, 0));
    set('label_myRestrain', f.rounds.filter((r) => r.cause === 1).length); set('label_enemyRestrain', f.rounds.filter((r) => r.cause === -1).length);
    const award = x.first(reply, 'award');
    let done; const closed = new Promise((ok) => { done = ok; });
    o.close = () => done();
    const kind = Q.get('fightkind') || info.kind || 'spar';
    if (f.won) {
      // the phone shows the layout's resting state (the face between the two panels), not its 'showwinanim' timeline; the rays turn
      if (n.sprite_lightview) { const spin = () => HB.tween(n.sprite_lightview, { rot: n.sprite_lightview.rot + 360 }, 8, spin); spin(); }
      const part = WIN_PART[kind] || 'normal', lab = LABEL_OF[part];
      for (const p of WIN_PARTS) if (n[p + '_layer_content']) n[p + '_layer_content'].visible = p === part;
      for (const p of Object.values(LABEL_OF)) hide('btn_' + p + '_teamcompare', 'sprite_' + p + '_teamcompare'); // Team compare: not built yet
      set('label_' + lab + '_getexp', '+' + (info.exp || 0)); set('label_' + lab + '_getsilver', '+' + (info.silver || 0));
      const prize = prizeOf(award);
      let after = null; // what is shown once the screen is closed
      if (part === 'round') {
        set('label_round_getgold', award ? x.n(award, 'cash') : 0); set('label_round_needbdoy', info.energy ? '-' + info.energy : 0);
        // the three cards to draw from: core_combat/RS_WinAnim.ccbi laid into layer_round_selectanim. "normalshow" makes them pulse;
        // "animshow<k>" turns card k over first and then the other two. The prize is already decided by the server (<award>).
        await HB.loadCCB('core_combat/RS_WinAnim');
        const ro = {};
        const box = n.layer_round_selectanim;
        const rs = HB.build('core_combat/RS_WinAnim', ro, [box.w, box.h]);
        rs.x = rs.ignoreAnchor ? 0 : rs.ax * rs.w; rs.y = rs.ignoreAnchor ? 0 : rs.ay * rs.h;
        const draw = ['btn_round__select1', 'btn_round_select2', 'btn_round_select3'].map((k) => n[k]).filter(Boolean);
        draw.forEach((b) => { b.opacity = 0; }); // the buttons only catch the tap; the cards drawn are RS_WinAnim's
        if (n.btn_back) n.btn_back.visible = !prize;
        if (prize) { box.add(rs); HB.play(rs, 'normalshow'); } else { draw.forEach((b) => { b.visible = false; }); hide('label_NewFightResult_WinView0'); }
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
              if (c !== k) { for (const nd of [icon, plate, stars]) if (nd) nd.removeSelf(); continue; } // the other two only turn over
              const fr = prize.icon && (HB.frameByName('icon_' + prize.icon) || HB.frameByName('small_' + prize.icon) || HB.frameByName(prize.icon));
              if (icon) { delete icon.anims; icon.visible = true; if (fr) { icon.setFrame(fr); icon.sx = icon.sy = 84 / Math.max(fr.sw, fr.sh); } else icon.visible = false; }
              if (name) name.setText(prize.text);
              // the prize's stars under its picture (a card), the fragment mark (a piece)
              if (stars) { for (let s = 1; s <= 5; s++) { const sp = ro.n['sprite_item' + c + '_star0' + s]; if (sp) sp.visible = s <= prize.stars; } const pc = ro.n['sprite_piece_' + c]; if (pc) pc.visible = !!prize.piece; }
            }
            HB.play(rs, 'animshow' + k, () => { if (n.btn_back) n.btn_back.visible = true; });
          }
        };
      } else {
        if (part === 'plunder') {
          const got = /plundered/i.test(x.t(reply, 'message') || '');
          set('label_plunder_needbdoy', '-1'); // one fight point (the row's own cost)
          set('label_plunderinfo', got ? 'You took the fragment!' : 'You won, but found no fragment'); // (ours: the phone's "plundertip" came from the dead server)
          hide('layer_plunder_chipinfo');
        } else if (part === 'areana') {
          const sp = x.first(reply, 'sport');
          const from = x.a(sp, 'fromrank'), to = x.a(sp, 'torank');
          set('label_ar_order', from || '-'); set('label_ar_neworder', to || from || '-');
          const renown = x.a(sp, 'renown_delta') || x.a(sp, 'renown');
          if (renown) set('label_ar_arcoin', '+' + renown); else hide('label_ar_arcoin');
          hide('label_ar_fightval');
        } else if (part === 'cw' || part === 'wb') {
          const p = part === 'cw' ? 'cw' : 'wb';
          if (info.feats !== undefined) set('label_' + p + '_feats', '+' + info.feats); else hide('label_' + p + '_feats', part === 'cw' ? 'label_NewFightResult_WinView1' : 'label_NewFightResult_WinView4');
          if (info.kills !== undefined) set('label_cw_countinuekill', info.kills); else hide('label_cw_countinuekill');
        } else if (part === 'tower') {
          if (prize && prize.cards.length) { set('label_tower_fragname', prize.text); const c = prize.cards[0]; const ic = HB.cardIcon(c.type, c.id); if (n.node_tower_icon) { ic.x = n.node_tower_icon.w / 2; ic.y = n.node_tower_icon.h / 2; n.node_tower_icon.add(ic); } }
          else hide('layer_tower_chipinfo');
        }
        // a prize outside Training has no cards to draw: it is shown in the "you got" window after this screen (ours)
        if (prize && prize.cards.length && part !== 'tower' && HB.showCards) after = () => HB.showCards(prize.cards);
        if (n.btn_back) n.btn_back.visible = true;
        if (Q.get('close')) setTimeout(() => o.close(), 3000); // test switch
        o.onButton = (sel) => { if (sel === 'onBtnBack' || sel === 'onPlunderAgain') return o.close(); };
      }
      await closed;
      view.removeSelf();
      if (after) await after();
      return null;
    }
    // ---- Defeat: nothing won; five ways to get stronger
    set('label_getexp', '+' + (info.failExp || 0)); set('label_getsilver', '+0'); set('label_getgold', '+0'); set('label_needbdoy', info.energy ? '-' + info.energy : '+0');
    if (n.btn_teamcompare) n.btn_teamcompare.removeSelf(); // Team compare: not built yet
    // The five pictures, left to right: Recruit -> the Shop's recruit scrolls (ChangeToSub 8), Level-up -> feed cards to my first
    // shinobi (the phone: the Backpack's shinobi list), Strengthen -> the Backpack's gear list (CMyBackpackView type 1),
    // Growth (ChangeToSub 0x1e), reincarnate (ChangeToSub 0x1f)   (CNewResultFailView::onBtnPray ... onBtnNewLife)
    const HELP = { onBtnPray: 'shop', onBtnUpgrade: 'upgrade', onBtnWeapon: 'gear', onBtnCuiLian: 'growth', onBtnNewLife: 'rebirth' };
    let help = null;
    o.onButton = (sel) => {
      if (sel === 'onBtnBack') return o.close();
      if (HELP[sel]) { help = HELP[sel]; o.close(); }
    };
    if (Q.get('failtap')) setTimeout(() => o.onButton(Q.get('failtap')), 2500); // test switch
    await closed;
    view.removeSelf();
    return help;
  }

  // what the <award> holds, in words and with a picture name when there is one
  function prizeOf(award) {
    if (!award) return null;
    const x = HB.ui.x, T = HB.ui.tables;
    const parts = [], cards = [];
    let icon = '', stars = 0, piece = false;
    for (const c of x.all(x.first(award, 'cardlist'), 'card')) {
      const id = x.n(c, 'id'), type = x.n(c, 'type'), cnt = x.n(c, 'num') || 1;
      const table = type === 1 ? T.ninjainfo : type === 6 ? T.ninjutsuinfo : type === 5 ? T.markinfo : T.equipmentinfo;
      const row = table && table.rows.find((r) => r[1] === id);
      parts.push((row ? row[2] : 'Card ' + id) + (cnt > 1 ? ' x' + cnt : ''));
      cards.push({ type, id, num: cnt });
      if (!icon && HB.info) { const inf = HB.info(type, id); icon = inf.icon; stars = inf.quality; }
      else if (!icon && row && typeof row[3] === 'string') icon = row[3];
    }
    for (const p of x.all(x.first(award, 'proplist'), 'prop')) {
      const id = x.n(p, 'id') || Number(x.a(p, 'id', 0)), cnt = x.n(p, 'num') || Number(x.a(p, 'num', 1));
      const row = T.consumeinfo && T.consumeinfo.rows.find((r) => r[1] === id);
      parts.push((row ? row[2] : 'Item ' + id) + (cnt > 1 ? ' x' + cnt : ''));
      cards.push({ type: 0, id, num: cnt });
      if (!icon && row && typeof row[3] === 'string') icon = row[3];
    }
    const coin = x.n(award, 'coin'), cash = x.n(award, 'cash'), soul = x.n(award, 'soul');
    if (coin) { parts.push(coin + ' silver'); icon = icon || 'com_silver_icon'; }
    if (cash) { parts.push(cash + ' gold'); icon = icon || 'com_gold_icon'; }
    if (soul) parts.push(soul + ' souls');
    if (!parts.length) return null;
    return { text: parts.join(', '), icon, stars, piece, cards };
  }
  HB.fight.prizeOf = prizeOf;
})();
