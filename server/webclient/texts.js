// Texts of our own for the rewritten game (ours; owner, 21 Nov 2026: "all text should match the boxes so it looks finished").
// The game's layouts and scripts are used as they are (the phone app must not change), so what has to read differently in the
// browser is laid ON TOP of the game's own tables here, in one place:
//   BUTTONS   the game's table holds a button's English text under BTN_TEXT_<member name>_<Layout> too (buttons the scripts
//             find by name: "btn_back" of GodCardSyntheticView = "Return"). The phone's C++ reads those; engine.js only reads the
//             ones filed under a button's action. Every layout that is built gets them here, so those buttons are not Chinese.
//   UI        layout texts: a label "TEXT_<NAME>_<LAYOUT>" or a button "BTN_TEXT_<name>_<Layout>" -> our text (replaces the
//             game's table entry; also the way to give a text to a label or button the table has no English for)
//   LUA       the scripts' own texts (script/util/localizable.lua): name -> our text, set once the scripts run
//   LAYOUT    a layout's name -> function (names, root) run right after it is built: moves or resizes labels that the script
//             does not touch again (plain cocos calls on our nodes)
// HB.texts.report() lists the Chinese texts on the screen that is showing. fit.js still shrinks what is too long.
'use strict';
(function () {
  const HB = window.HB;
  const CJK = /[㐀-鿿]/;

  const UI = {
    // ---- buttons the table has no English for (found with tools/dev/js-screens.js --lua)
    BTN_TEXT_btn_reset_RechargeTurnedCardView: 'Reset',        // 重置
    BTN_TEXT_btn_tab1_SuperNinjaChallenge: 'Easy',             // 简单
    BTN_TEXT_btn_tab2_SuperNinjaChallenge: 'Normal',           // 普通
    BTN_TEXT_btn_tab3_SuperNinjaChallenge: 'Hard',             // 困难
    BTN_TEXT_btn_challenge_SuperNinjaChallenge: 'Challenge',   // 挑战
    BTN_TEXT_btn_bingo_multiBattleBingoItem: 'Bet',            // 押宝
    BTN_TEXT_btn_inherit_NinjaInheritView: 'Inherit',          // 传承
    BTN_TEXT_closeBtn_PetPsychicArrayTipsbtn_close_PetPsychicArrayTips: 'OK', // 确定
    // ---- labels the table has no English for
    TEXT_LABEL_LIMITSUPERNINJA1_LIMITSUPERNINJA: 'more for a sure',                                              // "Recruit 8 [more for a sure] Five-Star Purple Card"
    TEXT_LABEL_REINCARNATIONVIEW6_ADVANCEEQUIPVIEW: 'God cards can only be reborn with Reincarnation Pills',
    TEXT_LABEL_OLDPRICE_GODRECRUITVIEW: 'Price:',              // 原价：999 (the script writes the number when the event runs)
    TEXT_LABEL_UNUSE2_GODRECRUITVIEW: 'Now:',                  // 折扣价：
    TEXT_LABEL_TIME_GODRECRUITVIEW: 'Time left: 00:00:00',     // 剩余时间：00:00:00
    TEXT_LABEL_SCORE_GODRECRUITVIEW: 'Energy points:',         // 能量点：
    TEXT_LABEL_REST_TIME_FIRSTMONEYAWARD: '',                  // "Left0分钟": empty until the script writes the time
    // ---- shorter words where the English ran out of its box
    TEXT_LABEL_MONTHCARD0_MONTHCARD: '$4.99 card',             // "4.99-dollars monthly card" ran off its red ribbon
    TEXT_LABEL_MONTHCARD2_MONTHCARD: '$9.99 card',
    TEXT_LABEL_PAY_KEEPPAYCELL: 'Top-up',                      // "Recharge" was wider than its button
    TEXT_LABEL_MYSCORE_ORGDONATEVIEW: 'My contribution: 0',      // 您当前的贡献度是：0 (the script writes it for guild members)
    TEXT_LABEL_ORGNAME_ORGMAINVIEW: '',                         // XX组织, a place holder
    TEXT_LABEL_VIPLISTVIEW0_VIPLISTVIEW: ' to become:',         // with vip_list_need_gold below: "Top up $1 more to become: VIP1"
  };

  const LUA = {
    ui_gameSettings_title: 'Settings',
    ui_keepPay_cell_title: 'Streak: day %s',                   // "Recharge Streak: %s D" ran off its red ribbon
    ui_ninjaTestMain_text2: 'Challenge',                       // "chanllenge"
    ui_ninjaTestMain_text9: 'Exam room',                       // "exame room"
    ui_label_petlist_text: 'Pets',                             // "telepathize beasts" ran over the building beside it
    ui_first_money_left: 'Left ',                              // "Left0 min"
    ui_hotTreasure_text2: 'This time free',
    ui_hotTreasure_btn2: 'Ten hunts',
    vip_gift_text: ' Honorable gift',                          // "VIP1Honorable gift"
    vip_list_need_gold: 'Top up $%s more',                     // "Recharge %s $ You will become:"
  };

  // tips a script shows with Chinese words written into the script itself (not in localizable): the tip's text -> ours
  const TIPS = {
    '转国成功': 'You changed country',                          // switchCountry.lua, after the Immigration Card
  };

  // script functions that build a text from Chinese words: the same function in English (run once, with the texts above)
  const LUA_CODE = `
if tools then
  local function span(t, sep)
    if t.d ~= 0 then if t.h ~= 0 then return string.format('%dd' .. sep .. '%dh', t.d, t.h) end return string.format('%dd', t.d) end
    if t.h ~= 0 then if t.m ~= 0 then return string.format('%dh' .. sep .. '%dmin', t.h, t.m) end return string.format('%dh', t.h) end
    return nil
  end
  function tools.convertTimeToStrForPurchase(t)   -- "%d小時%d分钟": time left on the 1st Recharge page, without seconds
    return span(t, ' ') or string.format('%d min', t.m)
  end
  function tools.convertTimeToStr(t)              -- "%d分钟 %d秒"
    local long = span(t, ' ')
    if long then return long end
    if t.m ~= 0 then if t.s ~= 0 then return string.format('%d min %d s', t.m, t.s) end return string.format('%d min', t.m) end
    if t.s ~= 0 then return string.format('%d s', t.s) end
    return 'None'
  end
end
`;

  // labels of one layout made smaller / wrapped, right after it is built
  const each = (n, names, fn) => { for (const k of names) if (n[k]) fn(n[k]); };
  const LAYOUT = {
    // the Shop's VIP gifts: three lines of contents ran into the price under them
    VipItemView(n) { each(n, ['label_desc'], (l) => { l.size = 20; l.setText(l.text); }); },
    // 1st Recharge: the two paragraphs ran into each other, the four prize names into their neighbours
    FirstMoneyAward(n) {
      each(n, ['label_first_gift_info', 'label_second_gift_info'], (l) => { l.size = 20; l.setText(l.text); });
      each(n, ['label_award_1', 'label_award_2', 'label_award_3', 'label_award_4'], (l) => { l.size = 15; l.dims = [124, 0]; l.ha = 1; l.ay = 1; l.y += 14; l.setText(l.text); });
    },
  };

  // ---------------------------------------------------------------- the tables
  let byButton = null; // member name -> Map(layout -> text)
  function index() {
    byButton = new Map();
    const ui = HB.strings.ui || {};
    for (const k of Object.keys(ui)) {
      if (!k.startsWith('BTN_TEXT_')) continue;
      const rest = k.slice(9), cut = rest.lastIndexOf('_');
      if (cut <= 0) continue;
      const name = rest.slice(0, cut), file = rest.slice(cut + 1);
      if (!byButton.has(name)) byButton.set(name, new Map());
      byButton.get(name).set(file, ui[k]);
    }
  }
  function applyUI() { if (HB.strings && HB.strings.ui) { Object.assign(HB.strings.ui, UI); index(); } }
  const load0 = HB.loadStrings;
  HB.loadStrings = async function () { const r = await load0.apply(this, arguments); applyUI(); return r; };
  applyUI();

  function buttonText(b, doc) {
    if (!byButton) index();
    const ui = HB.strings.ui || {};
    const own = ui['BTN_TEXT_' + b.name + '_' + doc];
    if (own !== undefined) return own;
    const all = byButton.get(b.name);
    if (!all) return undefined;
    const texts = [...new Set(all.values())];
    if (texts.length === 1) return texts[0];                       // the same word in every layout that has such a button
    return CJK.test(String(b.titles[1] || '')) ? texts[0] : undefined; // better than Chinese
  }
  function fixButtons(root, doc) {
    const walk = (n) => {
      if (n instanceof HB.Button && n.name && !n.selector) {
        const t = buttonText(n, doc);
        if (t !== undefined && t !== null && t !== '' && t !== n.titles[1]) { for (const s of Object.keys(n.titles)) n.titles[s] = t; n.titles[1] = t; n.layout(); }
      }
      for (const c of n.children) walk(c);
    };
    walk(root);
  }
  const build0 = HB.build;
  HB.build = function (file, owner, ...rest) {
    const root = build0.call(this, file, owner, ...rest);
    try {
      const doc = String(file).split('/').pop();
      fixButtons(root, doc);
      if (LAYOUT[doc]) LAYOUT[doc]((owner && owner.n) || {}, root);
    } catch (e) { console.warn('texts.js', file, e); }
    return root;
  };

  // ---------------------------------------------------------------- a title that fits its button
  // A cocos button grows with its title: a long English word made a button wider than the layout drew it, over its neighbours
  // ("Ranking reward" on the Lucky Wheel, "Recharge" in the recharge-streak rows). Here the title is set smaller first, down to
  // 60 % of its size, so the button keeps the width the layout gives it; only what is still too long makes it grow as before.
  const layout0 = HB.Button.prototype.layout;
  HB.Button.prototype.layout = function () {
    layout0.call(this);
    const room = this.pref[0] - 14;
    if (!(this.pref[0] > 0) || !this.label || this.label.w <= room || !this.label.text) return;
    const size = Math.max(Math.ceil(this.titleSize * 0.6), Math.floor(this.titleSize * room / this.label.w));
    this.label.size = size; this.label.setText(this.label.text);
    const w = Math.max(this.label.w + 16, this.pref[0]), h = Math.max(this.label.h + 4, this.pref[1]);
    this.w = w; this.h = h;
    this.bg.w = w; this.bg.h = h; this.bg.x = w / 2; this.bg.y = h / 2;
    this.label.x = w * this.labelAnchor[0]; this.label.y = h * this.labelAnchor[1];
  };

  // ---------------------------------------------------------------- the scripts' texts
  let luaDone = null; // the Lua state these were set in (a new login starts a new one)
  const quote = (s) => '"' + String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n') + '"';
  setInterval(() => {
    if (HB.tip && !HB.tip.ours) { const tip0 = HB.tip; HB.tip = function (t, ...rest) { return tip0.call(this, TIPS[String(t).trim()] || t, ...rest); }; HB.tip.ours = true; } // HB.tip is made after this file
    if (!HB.L || luaDone === HB.L || !HB.luaCall) return;
    try {
      if (HB.L.get('localizable') == null) return; // the scripts are still starting
      HB.luaCall(HB.L.load(Object.keys(LUA).map((k) => 'localizable.' + k + ' = ' + quote(LUA[k])).join('\n') + '\n' + LUA_CODE));
      luaDone = HB.L;
    } catch (e) { /* tried again in a moment */ }
  }, 300);

  HB.texts = {
    UI, LUA, LAYOUT, TIPS,
    // the Chinese texts showing right now: labels and button titles
    report() {
      const out = [];
      const walk = (n) => {
        if (!n || !n.visible) return;
        if ((n instanceof HB.Label || n instanceof HB.BMLabel) && CJK.test(String(n.text)) && !(n.parent instanceof HB.Button)) out.push((n.name || 'label') + ': ' + n.text);
        if (n instanceof HB.Button && CJK.test(String(n.titles[1] || ''))) out.push('button ' + (n.name || n.selector || '?') + ': ' + n.titles[1]);
        (n.children || []).forEach(walk);
      };
      if (HB.game && HB.game.subContent) walk(HB.game.subContent);
      if (HB.scene) HB.scene.children.filter((c) => c.z >= 500).forEach(walk);
      return out;
    },
  };
})();
