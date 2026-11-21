// Training (the bottom bar's 4th button): what CChapterView, CChapterCellView, CSubChapterView, CSectionBtnCellView and
// CSectionCellView did in libgame.so.
//   chapters   sub_ui/ChapterView.ccbi, 6 chapter pictures a page (sub_ui/ChapterCellView.ccbi), names from storyinfo
//   one chapter  sub_ui/SubChapterListView.ccbi: a row of stage tabs (SubChapterBtnCell.ccbi) and the stage's parts as cards
//              (SubChapter.ccbi): every part before the server's "pos" reads Finish, the part at "pos" has GO
//   requests   rl_w_pve Cmd=2 ChapID -> <preview currentstage/> <stagelist><stage stageid pos pos_time pk_boss_times/>
//                                           <expbuf addrate exp_time/>  (a running EXP card: "EXP * 2" and its clock on every row)
//              rl_w_pve Cmd=3 ChapID StageID Pos WastCashBoss -> <pve .../> <fight> <award type>
// What a tap on GO does (CSectionCellView::ClickEnd / onHttpRequestCompleted):
//   a story row   no fight is shown: the wheel (CDialogRunLevelTurnView, dlg_ui/RunLevelTurnable.ccbi) turns to the part the
//                 server chose (<award type>: 1 a card, 2 silver x2, 3 EXP x2, 4 "Work harder", 5 gold) and shows what the row gave
//   a boss row    the fight (fight.js) with the three victory cards. 3 tries a day (pk_boss_times); at 0 the button shows the
//                 gold price and asks first (menu text 292), then sends WastCashBoss=1
//   no energy     the server answers 40004 and the ramen stall opens
// Rows before the open one read Finish and cannot be played again; a finished stage keeps GO on its last row, the boss.
// The chapter-complete window (sub_ui/ChapterCompleteView.ccbi) is not shown: v28 never opens it (nothing in libgame.so calls
// CChapterCompleteView::init), its pictures (chapters_completed.plist) are not in the game files and the rewards it lists were
// never paid. When a chapter's last boss falls for the first time, the game's message window says so with the game's own
// words (menu text 213 "Congratulations on passing the training %s-%s") and the next chapter opens (ours).
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const PER_PAGE = 6;
  const NOT_OPEN = 'Not open yet'; // a stage further on (ours: the phone's own words for this are not found yet)
  const WHEEL_PART = { 1: 4, 2: 3, 3: 1, 4: 0, 5: 2 }; // <award type> -> the wheel's part, counted against the clock from "Work harder" (CDialogRunLevelTurnView::StartTurn)
  const two = (v) => String(v).padStart(2, '0');
  const clock = (s) => (s >= 3600 ? two(Math.floor(s / 3600)) + ':' : '') + two(Math.floor(s / 60) % 60) + ':' + two(s % 60);

  HB.screens.training = async function training(page) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    const [story] = await Promise.all([ui.table('storyinfo'), ui.table('roundinfo'), HB.loadCCB('sub_ui/ChapterView'), HB.loadCCB('sub_ui/ChapterCellView')]);
    ui.loading(false);
    const o = {};
    HB.game.showSub('sub_ui/ChapterView', o, 'btn_mainround');
    const chapters = story.rows.length, pages = Math.ceil(chapters / PER_PAGE);
    const cur = (HB.game.chap || { cur: 1 }).cur;
    let shown = page === undefined ? Math.floor((Math.min(cur, chapters) - 1) / PER_PAGE) : page;
    const cont = o.n.node_section_container;
    const dotOn = HB.frameByName('outline_003'), dot = HB.frameByName('outline_004'); // gold = the page shown
    function showPage(pg) {
      shown = pg;
      cont.removeAll();
      const co = {};
      cont.add(HB.build('sub_ui/ChapterCellView', co, [cont.w, cont.h]));
      for (let i = 1; i <= PER_PAGE; i++) {
        const chap = pg * PER_PAGE + i, box = co.n['chapter_container' + i], pic = co.n['sprite_chapter' + i], label = co.n['label_chapter' + i];
        if (!box) continue;
        if (chap > chapters) { box.visible = false; continue; }
        const f = HB.frameByName('level_chapter_' + chap);
        if (f && pic) pic.setFrame(f);
        if (label) label.setText(story.rows[chap - 1][2]);
        const open = chap <= cur;
        if (pic) pic.grey = !open; // chapters not reached yet are grey (seen on the phone)
        box.onTouch = (ev, tx, ty) => {
          if (ev === 'down') box._down = [tx, ty];
          if (ev === 'up' && box._down && Math.hypot(tx - box._down[0], ty - box._down[1]) < 14) {
            if (open) openChapter(chap); else ui.tip(HB.menu(293) || NOT_OPEN, 1.2);
          }
        };
      }
      for (let k = 1; k <= 5; k++) { const b = o.n['page_btn' + k]; if (!b) continue; b.visible = k <= pages; b.frames[1] = k - 1 === pg ? dotOn || dot : dot; b.frames[2] = b.frames[1]; b.layout(); }
    }
    o.onButton = (sel) => { const m = /clickPageBtn(\d)/.exec(sel); if (m) showPage(Number(m[1]) - 1); };
    showPage(Math.max(0, Math.min(pages - 1, shown)));
    // test switches (screenshots): &chapter=<n> opens that chapter (&part=<n>: on that stage tab), &go=1 then plays the part that has GO
    if (Q.get('chapter') && !auto.chapter) { auto.chapter = true; setTimeout(() => openChapter(Number(Q.get('chapter')) || cur, Number(Q.get('part')) || undefined), 800); }
  };
  const Q = new URLSearchParams(location.search), auto = {};

  // one chapter: its stages (tabs) and the chosen stage's parts
  async function openChapter(chap, wantStage) {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let list;
    try {
      [list] = await Promise.all([HB.api('rl_w_pve', { Cmd: 2, ChapID: chap }), HB.loadCCB('sub_ui/SubChapterListView'), HB.loadCCB('sub_ui/SubChapterBtnCell'), HB.loadCCB('sub_ui/SubChapter')]);
    } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (list.code) return ui.tip(ui.errorText(list));
    const rows = ui.tables.roundinfo.rows.filter((r) => r[4] === chap);
    const stageIds = [...new Set(rows.map((r) => r[39]))].sort((a, b) => a - b);
    const reached = new Map(x.all(list, 'stage').map((s) => [Number(x.a(s, 'stageid')), { pos: Number(x.a(s, 'pos')), posTime: Number(x.a(s, 'pos_time')), boss: Number(x.a(s, 'pk_boss_times')) }]));
    const current = Number(x.a(x.first(list, 'preview'), 'currentstage', 1));
    const buff = x.first(list, 'expbuf');
    // a running EXP card: its rate and the seconds left, counted down here (CSubChapterView::TimerUpdate). &expbuf=<seconds> = test switch
    const exp2 = { rate: Number(x.a(buff, 'addrate', 0)), until: Date.now() + Number(x.a(buff, 'exp_time', 0)) * 1000, labels: [] };
    if (Q.get('expbuf')) { exp2.rate = 100; exp2.until = Date.now() + Number(Q.get('expbuf')) * 1000; }
    const expLeft = () => Math.max(0, Math.round((exp2.until - Date.now()) / 1000));
    let stage = wantStage && reached.has(wantStage) ? wantStage : current;

    const o = {};
    HB.game.showSub('sub_ui/SubChapterListView', o, 'btn_mainround');
    o.onButton = (sel) => { if (sel === 'clickBack') HB.screens.training(Math.floor((chap - 1) / PER_PAGE)); };
    const myView = o;
    const tick = () => { // the EXP card's clock, once a second while this screen is the one shown
      if (HB.game.subOwner !== myView) return;
      const left = expLeft();
      for (const g of exp2.labels) { g.time.setText(clock(left)); if (left <= 0) g.all.forEach((nd) => { nd.visible = false; }); }
      if (left > 0) setTimeout(tick, 1000);
    };
    if (exp2.rate > 0 && expLeft() > 0) setTimeout(tick, 1000);

    // ---- the stage tabs: one row that scrolls sideways
    const tabsBox = o.n.node_btnlist_container, tabSize = o.n.node_btnlist_cell;
    const tabs = new HB.ScrollView(); tabs.dir = 0; tabs.w = tabsBox.w; tabs.h = tabsBox.h;
    const strip = new HB.Node(); strip.w = stageIds.length * tabSize.w; strip.h = tabSize.h;
    const tabOwners = new Map();
    stageIds.forEach((sid, i) => {
      const to = {};
      const cell = HB.build('sub_ui/SubChapterBtnCell', to, [tabSize.w, tabSize.h]);
      cell.ignoreAnchor = true; cell.x = i * tabSize.w; cell.y = 0; cell.w = tabSize.w; cell.h = tabSize.h;
      const last = rows.filter((r) => r[39] === sid).pop();
      to.n.label_title.setText(last[40]);
      to.n.sprite_boss.visible = last[38] === 2; to.n.sprite_elite.visible = last[38] === 1;
      cell.onTouch = (ev, tx, ty) => {
        if (ev === 'down') cell._down = [tx, ty];
        if (ev === 'up' && cell._down && Math.hypot(tx - cell._down[0], ty - cell._down[1]) < 14) { if (reached.has(sid)) { stage = sid; showStage(); } else ui.tip(NOT_OPEN, 1.2); }
      };
      tabOwners.set(sid, to);
      strip.add(cell);
    });
    tabs.setContent(strip);
    tabsBox.add(tabs);
    const markTabs = () => {
      for (const [sid, to] of tabOwners) {
        const isCur = sid === stage, open = reached.has(sid);
        to.n.sprite_current_section.visible = isCur;
        to.n.sprite_passed_section.visible = !isCur && open;
        to.n.sprite_unavailable_section.visible = !open;
      }
      const i = stageIds.indexOf(stage); // keep the chosen tab in view
      strip.x = Math.max(Math.min(0, tabs.w - strip.w), Math.min(0, tabs.w / 2 - (i + 0.5) * tabSize.w)); strip.y = 0;
    };

    // ---- the parts of the chosen stage, top to bottom, the one to play at the bottom of the list
    const listBox = o.n.node_section_container, cellSize = o.n.node_cardcontent;
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = listBox.w; scroll.h = listBox.h;
    listBox.add(scroll);
    function showStage() {
      markTabs();
      const st = reached.get(stage) || { pos: 1, posTime: 0, boss: 0 };
      exp2.labels = [];
      const parts = rows.filter((r) => r[39] === stage && r[3] <= st.pos).sort((a, b) => a[3] - b[3]);
      const col = new HB.Node(); col.w = scroll.w; col.h = parts.length * cellSize.h;
      parts.forEach((r, i) => {
        const co = {};
        const cell = HB.build('sub_ui/SubChapter', co, [cellSize.w, cellSize.h]);
        cell.ignoreAnchor = true; cell.x = (scroll.w - cellSize.w) / 2; cell.y = col.h - (i + 1) * cellSize.h; cell.w = cellSize.w; cell.h = cellSize.h;
        fillPart(co, r, st, chap);
        col.add(cell);
      });
      scroll.setContent(col);
      col.y = col.h < scroll.h ? scroll.h - col.h : 0; // the list starts at its end, the part to play; a short list sits at the top
      if (Q.get('go') && !auto.go) { auto.go = true; const r = parts[parts.length - 1]; setTimeout(() => play(chap, r, st), 1200); } // test switch
    }
    function fillPart(co, r, st, chapId) {
      const n = co.n, kind = r[38], atPos = r[3] === st.pos, done = r[3] < st.pos;
      n.section_normal_container.visible = kind === 0;
      n.section_enemy_container.visible = false;
      n.section_elite_enemy_container.visible = kind === 1;
      n.section_boss_container.visible = kind === 2;
      n.label_section_no.setText(stage + '-' + r[3]);
      n.label_desc.setText(r[37]);
      n.label_title.setText(r[5]);
      n.label_need_energy.setText(String(r[22]));
      n.label_exp.setText(String(r[23]));
      n.label_silver.setText(String(r[24]));
      const boss = kind !== 0;
      n.label_progress_text.visible = !boss; n.label_fight_text.visible = boss;
      n.label_progress.setText(boss ? String(st.boss) : (done ? r[42] : st.posTime) + '/' + r[42]);
      n.sprite_attack_type.visible = r[48] === 0; n.sprite_defense_type.visible = r[48] !== 0;
      // the prize a boss may give: its icon and stars
      const hasPrize = !!r[44];
      n.node_award_container.visible = hasPrize;
      if (hasPrize) {
        const f = HB.frameByName('icon_' + r[44]) || HB.frameByName('small_' + r[44]) || HB.frameByName(r[44]); // a shinobi, a piece of gear, anything else
        if (f) { n.sprite_boss_award.setFrame(f); const k = 86 / Math.max(f.sw, f.sh); n.sprite_boss_award.sx = n.sprite_boss_award.sy = k; }
        ['sprite_star05', 'sprite_star02', 'sprite_star01', 'sprite_star03', 'sprite_star04'].forEach((nm, i) => { if (n[nm]) n[nm].visible = i < r[45]; });
      }
      // the exp-card timer shows only while an exp card runs
      const running = exp2.rate > 0 && expLeft() > 0;
      n.label_exp_2.visible = n.label_left_time_tip.visible = n.label_left_time.visible = running;
      if (running) { n.label_left_time.setText(clock(expLeft())); exp2.labels.push({ time: n.label_left_time, all: [n.label_exp_2, n.label_left_time_tip, n.label_left_time] }); }
      // the button: GO for the part to play, Finish for the parts before it
      const go = atPos;
      // a boss with no tries left today: the button carries the gold price (roundinfo [43], 10 gold on our servers)
      const paid = go && boss && st.boss <= 0;
      n.sprite_fight_gold_icon.visible = paid; n.label_fight_cost.visible = paid;
      if (paid) n.label_fight_cost.setText(String(r[43] || 10));
      const f = HB.frameByName(paid ? 'level_zhandou_18' : go ? 'level_zhandou_23' : 'level_zhandou_24'); // the plain orange button carries the gold price (CSectionCellView::InitUI)
      if (f) n.sprite_move.setFrame(f);
      if (go) {
        const b = n.sprite_move;
        b.onTouch = (ev, tx, ty) => {
          if (ev === 'down') { b._down = [tx, ty]; b.sx = b.sy = 1.08; }
          if (ev === 'up' || ev === 'cancel') b.sx = b.sy = 1;
          if (ev === 'up' && b._down && Math.hypot(tx - b._down[0], ty - b._down[1]) < 14) play(chapId, r, st);
        };
      }
    }
    let busy = false;
    async function play(chapId, r, st = { boss: 1 }) {
      if (busy) return;
      const boss = r[38] !== 0;
      let buy = 0;
      if (boss && st.boss <= 0) { // no tries left today: ask before spending gold (CCommonDialogView with menu text 292)
        const cost = r[43] || 10;
        const words = (HB.menu(292) || 'You have used up the number of tries for today, are you sure to spend %d gold to continue?').replace('%d', cost);
        if (!Q.get('go') && !(await HB.confirm(words))) return;
        buy = 1;
      }
      busy = true;
      ui.loading(true);
      let reply;
      try { reply = await HB.api('rl_w_pve', { Cmd: 3, ChapID: chapId, StageID: r[39], Pos: r[3], WastCashBoss: buy }); }
      catch (e) { ui.loading(false); busy = false; return ui.tip('Cannot reach the server'); }
      ui.loading(false);
      if (reply.code) {
        busy = false;
        if (Number(reply.code) === 40004 && HB.screens.ramen) { ui.tip(ui.errorText(reply), 1.5); return HB.screens.ramen(); } // out of energy: the ramen stall
        return ui.tip(ui.errorText(reply));
      }
      const before = (HB.game.chap || { cur: chapId }).cur;
      let won = true;
      if (boss || Q.get('wheel') === '0') won = await HB.fight.play(reply, { kind: 'round', exp: r[23], silver: r[24], energy: r[22], boss: r[38] === 2 });
      else await wheel(reply, r);
      await HB.game.refresh();
      busy = false;
      const pve = x.first(reply, 'pve');
      const nextChap = Number(x.a(pve, 'curchapter', chapId)), nextStage = Number(x.a(pve, 'curstage', r[39]));
      // back on the list with the new state; a finished chapter goes on with the next one's first stage
      if (won && nextChap !== chapId && nextChap <= ui.tables.storyinfo.rows.length) {
        if (nextChap > before || Q.get('chapdone')) await chapterDone(chapId);
        return openChapter(nextChap);
      }
      if (Q.get('chapdone')) await chapterDone(chapId); // test switch: show the window after any stage
      return openChapter(chapId, won ? nextStage : r[39]);
    }
    showStage();
    HB.train = { chap, stage: () => stage, reached, play, rows };
  }
  HB.screens.openChapter = openChapter;

  // ---- the wheel of a story row (CDialogRunLevelTurnView): three quick turns, then on to the part the server chose
  async function wheel(reply, r) {
    const ui = HB.ui, x = ui.x;
    await HB.loadCCB('dlg_ui/RunLevelTurnable');
    const award = x.first(reply, 'award');
    const part = WHEEL_PART[Number(x.a(award, 'type', 4))] ?? 0;
    const o = {};
    const cover = ui.modal(0); cover.z = 600;
    const view = ui.screen('dlg_ui/RunLevelTurnable', o);
    cover.add(view); HB.scene.add(cover);
    const n = o.n;
    n.node_bottom_container.visible = false; // the three numbers show when the wheel has stopped (FinishedTurn)
    const table = n.sprite_table;
    const turn = (deg, sec) => new Promise((ok) => HB.tween(table, { rot: table.rot + deg }, sec, ok));
    HB.train.wheel = 'turning'; // for tests
    // StartTurn: 720 and 360 degrees in 0.4 s each, then 72 for every part further and a last 72
    await turn(720, 0.4);
    if (part === 0) { await turn(288, 0.4); await turn(72, 0.4); }
    else { await turn(360, 0.4); if (part > 1) await turn(72 * (part - 1), 0.4 * (part - 1) / 5 + 0.1); await turn(72, 0.4); }
    table.rot = 72 * part;
    await HB.wait(0.35);
    // what the row gave: its own exp and silver, plus the wheel's extra copy, gold or energy (the server pays the same)
    const exp = r[23] + x.n(award, 'exp'), silver = r[24] + (Number(x.a(award, 'coin', 0)) || 0), gold = x.n(award, 'cash');
    n.label_exp.setText(String(exp)); n.label_silver.setText(String(silver)); n.label_gold.setText(String(gold));
    n.node_bottom_container.visible = true;
    HB.train.wheel = 'stopped';
    // tap anywhere to go on (CModalClickOnceLayer); the card part shows its card first
    await new Promise((ok) => { cover.onTouch = (ev) => { if (ev === 'up') ok(); }; if (Q.get('go')) setTimeout(ok, Number(Q.get('wheelwait')) || 2500); });
    cover.removeSelf();
    HB.train.wheel = '';
    const prize = HB.fight.prizeOf && HB.fight.prizeOf(award);
    if (part === 4 && prize && prize.cards.length && HB.showCards && !Q.get('go')) await HB.showCards(prize.cards);
    const energy = x.n(award, 'action');
    if (energy) ui.tip('Energy +' + energy, 1.5);
  }

  // ---- a chapter is finished: a notice in the game's own message window with its own words (menu text 213), then the next chapter
  async function chapterDone(chap) {
    const ui = HB.ui;
    const story = ui.tables.storyinfo.rows[chap - 1];
    const words = (HB.menu(213) || 'Congratulations on passing the training %s-%s').replace('%s', HB.menu(194 + chap) || 'Chapter ' + chap).replace('%s', story ? story[2] : '');
    const o = {};
    await HB.dialog('dlg_ui/CommonDialogView', o);
    const n = o.n;
    n.labelDescription.setText(words);
    if (n.layer_protect) n.layer_protect.visible = false;
    n.leftButton.setTitle('OK');
    if (n.rightButton) { n.leftButton.x = (n.leftButton.x + n.rightButton.x) / 2; n.rightButton.visible = false; } // one button, in the middle
    HB.train.done = true; // for tests
    await new Promise((ok) => { o.onButton = () => ok(); if (Q.get('go')) setTimeout(ok, 4000); });
    o.close();
    HB.train.done = false;
  }
})();
