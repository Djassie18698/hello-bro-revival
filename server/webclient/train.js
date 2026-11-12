// Training (the bottom bar's 4th button): what CChapterView, CChapterCellView, CSubChapterView, CSectionBtnCellView and
// CSectionCellView did in libgame.so.
//   chapters   sub_ui/ChapterView.ccbi, 6 chapter pictures a page (sub_ui/ChapterCellView.ccbi), names from storyinfo
//   one chapter  sub_ui/SubChapterListView.ccbi: a row of stage tabs (SubChapterBtnCell.ccbi) and the stage's parts as cards
//              (SubChapter.ccbi): every part before the server's "pos" reads Finish, the part at "pos" has GO
//   requests   rl_w_pve Cmd=2 ChapID -> <preview currentstage/> <stagelist><stage stageid pos pos_time pk_boss_times/>
//              rl_w_pve Cmd=3 ChapID StageID Pos WastCashBoss -> the fight (fight.js plays it)
// roundinfo columns (docs/TABLE-COLUMNS.md): [2] number in the chapter, [3] part in the stage, [4] chapter, [5] name, [22] energy,
// [23] exp, [24] silver, [37] text, [38] 0 normal / 1 elite / 2 boss, [39] stage, [40] stage name, [42] times, [44] prize icon,
// [45] prize stars, [48] 0 attack / 1 defence.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const PER_PAGE = 6;
  const NOT_OPEN = 'Not open yet'; // (ours: the phone's own words for this are not found yet)

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
            if (open) openChapter(chap); else ui.tip(NOT_OPEN, 1.2);
          }
        };
      }
      for (let k = 1; k <= 5; k++) { const b = o.n['page_btn' + k]; if (!b) continue; b.visible = k <= pages; b.frames[1] = k - 1 === pg ? dotOn || dot : dot; b.frames[2] = b.frames[1]; b.layout(); }
    }
    o.onButton = (sel) => { const m = /clickPageBtn(\d)/.exec(sel); if (m) showPage(Number(m[1]) - 1); };
    showPage(Math.max(0, Math.min(pages - 1, shown)));
    // test switches (screenshots): &chapter=<n> opens that chapter, &go=1 then plays the part that has GO
    if (Q.get('chapter') && !auto.chapter) { auto.chapter = true; setTimeout(() => openChapter(Number(Q.get('chapter')) || cur), 800); }
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
    let stage = wantStage && reached.has(wantStage) ? wantStage : current;

    const o = {};
    HB.game.showSub('sub_ui/SubChapterListView', o, 'btn_mainround');
    o.onButton = (sel) => { if (sel === 'clickBack') HB.screens.training(Math.floor((chap - 1) / PER_PAGE)); };

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
      if (Q.get('go') && !auto.go) { auto.go = true; const r = parts[parts.length - 1]; setTimeout(() => play(chap, r), 1200); }
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
        const f = HB.frameByName('icon_' + r[44]) || HB.frameByName(r[44]);
        if (f) { n.sprite_boss_award.setFrame(f); const k = 86 / Math.max(f.sw, f.sh); n.sprite_boss_award.sx = n.sprite_boss_award.sy = k; }
        ['sprite_star05', 'sprite_star02', 'sprite_star01', 'sprite_star03', 'sprite_star04'].forEach((nm, i) => { if (n[nm]) n[nm].visible = i < r[45]; });
      }
      // the exp-card timer shows only while an exp card runs
      const rate = Number(x.a(buff, 'addrate', 0));
      n.label_exp_2.visible = n.label_left_time_tip.visible = n.label_left_time.visible = rate > 0;
      n.sprite_fight_gold_icon.visible = false; n.label_fight_cost.visible = false;
      // the button: GO for the part to play, Finish for the parts before it
      const go = atPos;
      const f = HB.frameByName(go ? 'level_zhandou_23' : 'level_zhandou_24');
      if (f) n.sprite_move.setFrame(f);
      if (go) {
        const b = n.sprite_move;
        b.onTouch = (ev, tx, ty) => {
          if (ev === 'down') { b._down = [tx, ty]; b.sx = b.sy = 1.08; }
          if (ev === 'up' || ev === 'cancel') b.sx = b.sy = 1;
          if (ev === 'up' && b._down && Math.hypot(tx - b._down[0], ty - b._down[1]) < 14) play(chapId, r);
        };
      }
    }
    let busy = false;
    async function play(chapId, r) {
      if (busy) return; busy = true;
      ui.loading(true);
      let reply;
      try { reply = await HB.api('rl_w_pve', { Cmd: 3, ChapID: chapId, StageID: r[39], Pos: r[3], WastCashBoss: 0 }); }
      catch (e) { ui.loading(false); busy = false; return ui.tip('Cannot reach the server'); }
      ui.loading(false);
      if (reply.code) { busy = false; return ui.tip(ui.errorText(reply)); }
      const won = await HB.fight.play(reply, { kind: 'round', exp: r[23], silver: r[24], energy: r[22] });
      await HB.game.refresh();
      busy = false;
      const pve = x.first(reply, 'pve');
      const nextChap = Number(x.a(pve, 'curchapter', chapId)), nextStage = Number(x.a(pve, 'curstage', r[39]));
      // back on the list with the new state; a finished chapter goes on with the next one's first stage
      if (won && nextChap !== chapId && nextChap <= ui.tables.storyinfo.rows.length) return openChapter(nextChap);
      return openChapter(chapId, won ? nextStage : r[39]);
    }
    showStage();
    HB.train = { chap, stage: () => stage, reached, play, rows };
  }
  HB.screens.openChapter = openChapter;
})();
