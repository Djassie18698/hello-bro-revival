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
//   TIDY      a layout's name -> rules kept true while that layout is on screen (the scripts write their texts later, after a
//             reply): words and numbers of one sentence set next to each other, a text said shorter, a smaller or wrapped label,
//             a label moved. See the table for the rule kinds.
//   TIPS      tips a script shows with Chinese words of its own
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
    ui_slotExchange_text1: 'Score reached ',                   // "Score reached100" on the slot machine's Exchange list
    vip_gift_text: ' Honorable gift',                          // "VIP1Honorable gift"
    vip_list_need_gold: 'Top up $%s more',
    ui_btn_fight_title: 'Ranking Rules',                       // "Battle Point Ranking Rules and Regulation" made the button wider than the screen
    ui_lable_my_fight: 'My points:',                           // "My Battle Point"                     // "Recharge %s $ You will become:"
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
  local watchDay = tools.convertTimeElectronicWatchHaveDay
  function tools.convertTimeElectronicWatchHaveDay(sec, count)  -- "2:2:49:59:" (days:hours:minutes:seconds:) on the rank events
    local t = tools.convertTimeToTable(sec)
    if count == 3 and t.d > 0 then return string.format('%dd %02d:%02d:%02d', t.d, t.h, t.m, t.s) end
    return watchDay(sec, count)
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

  // ---------------------------------------------------------------- TIDY: rules kept true while a layout is on screen
  // Per layout (the .ccbi's name without folder) a list of rules; names are the layout's member names (tools/dev/play-dump.js lists them):
  //   { row: [names], gap: 6, center: true | x }   the labels stand next to each other in this order, as one sentence: centred on the
  //                                               middle of the place the layout gave them (center: true), around x of their parent
  //                                               (center: number), or from the first label's left edge (no center). Hidden or empty
  //                                               ones are left out. All must have the same parent.
  //   { say: { name: 'text' } }                   the label always reads this, whatever the script wrote ('' hides it)
  //   { swap: { name: [/regex/, 'text'] } }       the script's text with a part said differently
  //   { size: { name: px } }                      a TTF label's letter size
  //   { wrap: { name: width } }                   the label breaks its lines at this width, each line centred (0 = one line)
  //   { look: { name: { color: [r, g, b], stroke: ['#000', 2], z: 20 } } }   colour, outline, drawn over its brothers
  //   { move: { name: [dx, dy] } }                moved once from where the layout put it
  //   { edge: { name: ['right' | 'left', x] } }   the label ends (or starts) at x of its parent, whatever its text
  //   { anchor: { name: [ax, ay] } }              the label's anchor (0 = grows to the right, 0.5 = stays centred, 1 = grows to the left)
  //   { title: { name: 'text' } }                 a button's word
  //   { relabel: { 'text': 'new text' | ['new text', px] } }   a label WITHOUT a name, found by what it reads (the Akatsuki layouts'
  //                                               headings have no names): another word and / or letter size
  const TIDY = {
    // Growth Fund: "Only insert | 500 | Gold." and "can get | 5 | feedback,total | 2500 | Gold" stood in pieces on the red board
    growth_fund: [
      { say: { label_fund_desc1: 'Pay', label_fund_desc2: 'gold once,', label_fund_desc3: 'get', label_fund_desc4: 'times as much back:', label_fund_desc5: 'gold' } },
      { row: ['label_fund_desc1', 'label_val_1', 'label_fund_desc2'], gap: 8, center: 115 },
      { row: ['label_fund_desc3', 'label_val_2', 'label_fund_desc4', 'label_val_3', 'label_fund_desc5'], gap: 8, center: 115 },
      { size: { label_growth_fund0: 21, label_growth_fund1: 21 } }, // "(Only VIP3 and above buyers may purchase)" ran over the board's edge
    ],
    // Daily Task: the chests' "30Points" were cut by the bar under them
    // (now written on the chest's foot, in white with a dark edge)
    DailyTaskAwardCell: [{ swap: { label_need_score: [/^(\d+)\s*Points$/, '$1 pts'] } }, { size: { label_need_score: 20 } }, { move: { label_need_score: [0, 20] } },
      { look: { label_need_score: { color: [255, 255, 255], stroke: ['#4a2400', 2], z: 30 } } }],
    // Lucky Wheel: "Reward Pool:" lay under its number, the three button words were wider than their buttons, the two
    // sentences ran into their numbers
    RouletteView: [
      { size: { label_gold_pool: 18 } }, { row: ['label_gold_pool', 'label_super_award'], gap: 6, center: 248 },
      { say: { label_RouletteView0: 'turns', label_RouletteView2: 'Ranking', label_aaa_desc: 'until the wheel ends', label_RouletteView3: 'One turn earns', label_textview: 'points (1st of the day free)' } },
      { size: { label_RouletteView1: 27, label_RouletteView0: 27, label_left_roll: 27, label_RouletteView3: 22, label_score: 22, label_textview: 22 } },
      { row: ['label_left_roll', 'label_RouletteView0'], gap: 6, center: 95 },
      { row: ['aaa', 'label_aaa_desc'], gap: 8, center: 275 },
      { row: ['label_RouletteView3', 'label_score', 'label_textview'], gap: 7, center: 275 },
    ],
    // Millionaire: the greeting was wider than its banner; "Ten Summerset"
    MonopolyView: [{ say: { label_MonopolyView0: 'New Year Millionaire: prosperity and luck to everyone!' } }, { title: { btn_roll_tentimes: 'Ten throws' } }],
    CrossMonopolyView: [{ title: { btn_roll_tentimes: 'Ten throws' } }],
    // Gold spending: the heading ran under the countdown
    ConsumptionGiftView: [{ swap: { label_unuse1: [/^Cumulative gold：$/, 'Gold spent:'], label_activity_time: [/^Count down：$/, 'Time left:'] } }],
    // Limited discount: the four item names ran into each other (two lines each now)
    LimitDiscountView: [
      { anchor: { label_item_name1: [0.5, 1], label_item_name2: [0.5, 1], label_item_name3: [0.5, 1], label_item_name4: [0.5, 1] } },
      { size: { label_item_name1: 15, label_item_name2: 15, label_item_name3: 15, label_item_name4: 15 } },
      { wrap: { label_item_name1: 120, label_item_name2: 120, label_item_name3: 120, label_item_name4: 120 } },
      { say: { label_LimitDiscountView0: 'Time left:' } }, { title: { btn_get: 'Claim' } },
    ],
    // Mora: "Your current luck level:" ran under its coin, the four "10 Luck level" captions were squeezed into their plates,
    // the word "Check" lay on the Rules picture
    MoraView: [
      { say: { label_MoraView2: 'Your luck:', label_MoraView1: 'Your lives:' } },
      { size: { label_MoraView3: 18, label_MoraView4: 18, label_MoraView5: 18, label_MoraView6: 18, label_fortune_get1: 20, label_fortune_get2: 20, label_fortune_get3: 20, label_fortune_get4: 20 } },
      { anchor: { label_MoraView5: [0, 1], label_MoraView6: [0, 1] } },
      { row: ['label_fortune_get1', 'label_MoraView3'], gap: 5, center: true }, { row: ['label_fortune_get2', 'label_MoraView4'], gap: 5, center: true },
      { row: ['label_fortune_get3', 'label_MoraView5'], gap: 5, center: true }, { row: ['label_fortune_get4', 'label_MoraView6'], gap: 5, center: true },
      { title: { btn_detail: '' } },
    ],
    // Secret shop: the lines under the Refresh button lay over each other and ran off the screen; "Current number of Ninja Souls:"
    secretShopLayer: [
      { say: { label_secretShopLayer0: 'Souls:', label_secretShopLayer2: 'Refresh Orders:', label_secretShopLayer3: '', label_secretShopLayer4: 'A refresh: 1 order or', label_secretShopLayer5: '', label_secretShopLayer6: 'Refreshes today:', label_vip_unit: 'a day' } },
      { row: ['label_secretShopLayer2', 'label_update_token'], gap: 6 },
      { row: ['label_secretShopLayer6', 'label_today_times'], gap: 6 },
    ],
    secretShopItem: [{ wrap: { label_cost_type: 0 } }, { say: { label_cost_type: '' } }],
    // Inherit: the three rules were wider than the screen; "Growth: 0 Grade", "Reincarnation: 0 Reincarnation" and the two
    // "Training can increase ..." lines ran into their numbers
    NinjaInheritReadmeCell: [{ size: { label_text: 18 } }],
    NinjaInheritView: [
      { say: { label_NinjaInheritView2: 'Cost', label_NinjaInheritView6: '', label_NinjaInheritView7: 'Reborn:', label_NinjaInheritView8: '', label_NinjaInheritView9: 'Trained ATK:', label_NinjaInheritView10: 'Trained DEF:' } },
      { edge: { label_NinjaInheritView5: ['right', 308], label_NinjaInheritView7: ['right', 505] } }, // each caption ends at its number's dark box
    ],
    // the card lists of Inherit and Change Element: "Choose" was wider than its button, long names started left of their plate
    AttributeDanNinjaItem: [{ size: { label_AttributeDanNinjaItem0: 24, label_name: 19 } }, { move: { label_name: [16, 0] } }],
    NinjaInheritNinjaItem: [{ size: { label_NinjaInheritNinjaItem0: 24, label_name: 19 } }, { move: { label_name: [16, 0] } }],
    // World Boss, Heroes ranking: "claim reputation" was wider than its button
    FightBossRankView: [{ say: { label_FightBossRankView4: 'Claim' } }],
    // Stage gift (Home > Receive): the note behind the gift's name ran out of the window
    StageGiftView: [{ size: { label_StageGiftView0: 17 } }, { wrap: { label_StageGiftView0: 290 } }],
    // Level rank / Fight rank (one layout): "Ranking" and "Challenge" were cut by the board's edges, "Battle Point" and
    // "My Battle Point" were squeezed, the number stood away from its words
    LevelRank: [
      { say: { label_LevelRank0: 'Rank' } }, { size: { label_LevelRank3: 19, label_lv_or_power: 20 } }, { move: { label_LevelRank3: [-6, 0] } },
      { row: ['label_my_lv_or_power', 'label_level'], gap: 6 },
    ],
    // Super Ninja, the cross-server layout: "10 ... Purple Card" stood in two far corners (the words between them were never in
    // this layout), "Server" touched "Points", a row without a server name read "[nil]"
    LimitSuperNinjaForCross: [
      { say: { label_LimitSuperNinjaForCross1: 'draws until a sure 5-star purple card' } }, { size: { label_LimitSuperNinjaForCross1: 20, label_limit_desc: 20 } },
      { row: ['label_protect', 'label_LimitSuperNinjaForCross1'], gap: 8, center: 343 },
      { size: { label_LimitSuperNinjaForCross3: 20, label_LimitSuperNinjaForCross4: 20, label_LimitSuperNinjaForCross5: 20, label_LimitSuperNinjaForCross8: 20 } },
      { move: { label_LimitSuperNinjaForCross5: [8, 0], label_LimitSuperNinjaForCross4: [-8, 0] } },
      { swap: { label_limit_desc: [/^The MINIMUM for 1st prise is (\d+)\.?$/, '1st prize needs at least $1 points'] } },
    ],
    LimitIntegralRankCellForCross: [{ swap: { label_server_id: [/^\[?nil\]?$/, ''] } }, { size: { label_name: 20 } }, { move: { label_name: [-8, 0], label_score: [8, 0] } }],
    // Slot machine: the word "Check" lay on the Rules picture
    SlotMachineView: [{ title: { btn_detail: '' } }],
    // Akatsuki: the headings of its lists were lower-case words that touched each other ("Contri.", "select" against the window's
    // edge), "vice chieftain" ran into the numbers beside it, the Check buttons of the rankings stood on the screen's edge,
    // the Upgrade window read "demand: / cost: 4000contrucation points", a button read "Domotion"
    OrgMainView: [{ relabel: { list: ['Name', 30], level: ['Level', 30], job: ['Job', 30], 'Contri.': ['Points', 30], login: ['Login', 30] } }],
    OrgMainCell: [{ size: { label_title: 23, label_name: 26 } }],
    OrgMemOfficeView: [{ relabel: { list: ['Name', 28], level: ['Level', 28], job: ['Job', 28], 'Contri.': ['Points', 28], select: ['Pick', 28] } }, { title: { btn_demotion: 'Demotion' } }],
    OrgMemOfficeCell: [{ size: { label_office: 22, label_name: 24 } }],
    OrgMemExpelView: [{ relabel: { list: ['Name', 28], level: ['Level', 28], job: ['Job', 28], 'Contri.': ['Points', 28], expel: ['Expel', 28] } }],
    OrgMemExpelCell: [{ size: { label_job: 22, label_name: 24 } }],
    OrgMemCheckView: [{ relabel: { list: ['Name', 28], level: ['Level', 28], select: ['Pick', 28] } }],
    OrgRankingsView: [{ relabel: { rank: ['Rank', 26], name: ['Name', 28], level: ['Level', 26], leader: ['Leader', 28], number: ['Members', 22], detail: ['Detail', 26] } }],
    OrgRankingsCell: [{ move: { btn_detail: [-8, 0] } }, { size: { label_org_name: 26, label_org_leader: 26 } }],
    OrgListView: [{ relabel: { akatsuki: ['Akatsuki', 28], level: ['Level', 28], leader: ['Leader', 28], number: ['Members', 24], detail: ['Detail', 28] } }],
    OrgUpgradeView: [
      { relabel: { 'demand：': 'Needs:', 'cost：': 'Cost:', 'effect：': 'Effect:' } },
      { swap: { label_expend_1: [/contrucation points/, ' fund'], label_expend_2: [/contrucation points/, ' fund'], label_expend_3: [/contrucation points/, ' fund'], label_expend_4: [/contrucation points/, ' fund'] } },
    ],
    // Border war. The Taunt / Wander question stood in pieces ("Want to cost   20Gold   to   Taunt  ?", "Taunt 5:0      can
    // receive:", "Reduced bloodt:      10", "Everyday you can claim 2 rewards)"); the two lists' titles ran words together
    // ("My CountryWander state") and "times/day" ran off the window; the reward window read "0/2left"
    BorderWarAttackView: [
      { say: { label_BorderWarAttackView0: 'Pay', label_BorderWarAttackView2: 'to', label_BorderWarAttackView4: 'gives:', label_BorderWarAttackView5: 'Damage to the monument:', label_BorderWarAttackView6: '(rewarded', label_BorderWarAttackView7: 'times a day)' } },
      { swap: { attack_goldLabel: [/^(\d+)\s*Gold$/, '$1 gold'], attack_timeLabel: [/^(\d+):0$/, 'for $1 min'] } },
      { row: ['label_BorderWarAttackView0', 'attack_goldLabel', 'label_BorderWarAttackView2', 'attack_typeLabel_1', 'label_BorderWarAttackView1'], gap: 9, center: true },
      { row: ['attack_typeLabel_2', 'attack_timeLabel', 'label_BorderWarAttackView4'], gap: 9, center: true },
      { row: ['label_BorderWarAttackView5', 'attack_bloodLabel'], gap: 8 },
      { row: ['label_BorderWarAttackView6', 'attack_roundLabel', 'label_BorderWarAttackView7'], gap: 7 },
    ],
    BorderWarStateRewardView: [{ swap: { label_1: [/(\d)left$/, '$1 left'], label_2: [/(\d)left$/, '$1 left'], label_3: [/(\d)left$/, '$1 left'], label_4: [/(\d)left$/, '$1 left'] } }],
    BorderWarWanderInfoView: [{ swap: { wanderInfo_titleLabel: [/\s*Wander state$/, ': wanderers'] } }, { say: { label_add_desc: 'a day' } }, { size: { wanderInfo_titleLabel: 32 } }],
    BorderWarProvokeInfoView: [{ swap: { provokeInfo_titleLabel: [/\s*Taunting situation$/, ': taunters'] } }, { say: { label_add_desc: 'a day' } }, { size: { provokeInfo_titleLabel: 32 } }],
    // Lottery ticket: "Random Bet" lay across the narrow lever (the Chinese stood letter under letter), "50Bet in gold"
    LotteryTicketView: [{ say: { label_rand: 'R\nA\nN\nD\nO\nM' } }, { size: { label_rand: 16 } }, { swap: { label_cost_cash: [/^(\d+)\s*Bet in gold$/, 'Bet $1 gold'] } }],
    LotteryMyLuckyNumListView: [{ title: { btn_close: '' } }], // the word "Close" lay on the X
    LotteryWinerList: [{ title: { btn_close: '' } }],
    // Change country: the two sentences were wider than the window and its button
    SwitchCountryDialogView: [
      { say: { label_SwitchCountryDialogView0: 'This country costs:', label_SwitchCountryDialogView2: 'Change' } },
      { size: { label_SwitchCountryDialogView0: 26, label_SwitchCountryDialogView1: 15 } }, { wrap: { label_SwitchCountryDialogView1: 600 } },
    ],
  };
  const tidyRoots = new Set();
  const find = (root, name) => { if (root.tidyNames && root.tidyNames[name] !== undefined) { const c = root.tidyNames[name]; if (c && c.parent) return c; }
    let hit = null; const walk = (n) => { if (hit) return; if (n.name === name) { hit = n; return; } for (const k of n.children) walk(k); }; walk(root);
    (root.tidyNames = root.tidyNames || {})[name] = hit; return hit; };
  const isText = (n) => n instanceof HB.Label || n instanceof HB.BMLabel;
  const unfit = (n) => { if (n._fitSx !== undefined && n.sx === n._fitSx && n._fitBase) { n.sx = n._fitBase[0]; n.sy = n._fitBase[1]; n._fitSx = undefined; } }; // fit.js's last shrink: measured at full size
  const setText = (n, t) => { if (String(n.text) !== t) n.setText(t); };
  function tidy(root, rules) {
    for (const r of rules) {
      if (r.say) for (const k of Object.keys(r.say)) { const n = find(root, k); if (n && isText(n)) setText(n, r.say[k]); }
      if (r.swap) for (const k of Object.keys(r.swap)) { const n = find(root, k); if (n && isText(n)) { const t = String(n.text).replace(r.swap[k][0], r.swap[k][1]); setText(n, t); } }
      if (r.title) for (const k of Object.keys(r.title)) { const n = find(root, k); if (n instanceof HB.Button && n.titles[1] !== r.title[k]) { for (const st of Object.keys(n.titles)) n.titles[st] = r.title[k]; n.titles[1] = r.title[k]; n.layout(); } }
      if (r.relabel) { const walk = (n) => { if (n instanceof HB.Label && !n.name && !(n.parent instanceof HB.Button) && Object.prototype.hasOwnProperty.call(r.relabel, n.text)) { const v = r.relabel[n.text], t = Array.isArray(v) ? v[0] : v; if (Array.isArray(v) && v[1]) n.size = v[1]; n.setText(t); } for (const k of n.children) if (!k.ccbDoc) walk(k); }; walk(root); }
      if (r.size) for (const k of Object.keys(r.size)) { const n = find(root, k); if (n instanceof HB.Label && n.size !== r.size[k]) { n.size = r.size[k]; n.setText(n.text); } }
      if (r.wrap) for (const k of Object.keys(r.wrap)) { const n = find(root, k); if (n instanceof HB.Label && !(n.dims && n.dims[0] === r.wrap[k])) { n.dims = [r.wrap[k], 0]; if (r.wrap[k]) n.ha = 1; n.setText(n.text); } }
      if (r.look) for (const k of Object.keys(r.look)) { const n = find(root, k), o = r.look[k]; if (n) { if (o.color && String(n.color) !== String(o.color)) n.color = o.color.slice(); if (o.stroke && String(n.stroke) !== String(o.stroke)) n.stroke = o.stroke.slice(); if (o.z !== undefined && n.z !== o.z) n.z = o.z; } } // the scripts colour their labels again later
      if (r.edge) for (const k of Object.keys(r.edge)) { const n = find(root, k); if (n) { unfit(n); const right = r.edge[k][0] === 'right', x = r.edge[k][1] + (right ? -(1 - n.ax) : n.ax) * n.w * n.sx; if (Math.abs(n.x - x) > 0.5) n.x = x; } }
      if (r.anchor) for (const k of Object.keys(r.anchor)) { const n = find(root, k); if (n && !n.tidyAnchor) { n.tidyAnchor = true; const [ax, ay] = r.anchor[k]; n.x += (ax - n.ax) * n.w * n.sx; n.y += (ay - n.ay) * n.h * n.sy; n.ax = ax; n.ay = ay; } }
      if (r.move) for (const k of Object.keys(r.move)) { const n = find(root, k); if (n && !n.tidyMoved) { n.tidyMoved = true; n.x += r.move[k][0]; n.y += r.move[k][1]; } }
      if (r.row) {
        const all = r.row.map((k) => find(root, k)).filter(Boolean);
        if (all.length < 2 || all.some((n) => n.parent !== all[0].parent)) continue;
        all.forEach(unfit);
        const wOf = (n) => n.w * n.sx, left = (n) => n.x - n.ax * wOf(n);
        if (!root.tidyRow) root.tidyRow = new Map();
        // where the layout put the sentence: from the first label's left edge to the last one's right edge (kept from the first look)
        let home = root.tidyRow.get(r);
        if (!home) { home = { x0: Math.min(...all.map(left)), x1: Math.max(...all.map((n) => left(n) + wOf(n))) }; root.tidyRow.set(r, home); }
        const shown = all.filter((n) => n.visible && String(n.text) !== '' && wOf(n) > 0);
        if (!shown.length) continue;
        const gap = r.gap === undefined ? 6 : r.gap, total = shown.reduce((t, n) => t + wOf(n), 0) + gap * (shown.length - 1);
        let x = r.center === true ? (home.x0 + home.x1) / 2 - total / 2 : typeof r.center === 'number' ? r.center - total / 2 : home.x0;
        for (const n of shown) { const nx = x + n.ax * wOf(n); if (Math.abs(n.x - nx) > 0.5) n.x = nx; x += wOf(n) + gap; }
      }
    }
  }
  setInterval(() => {
    for (const root of [...tidyRoots]) {
      let top = root; while (top.parent) top = top.parent;
      if (top !== HB.scene) { if (root.tidySeen) tidyRoots.delete(root); else if ((root.tidyWait = (root.tidyWait || 0) + 1) > 40) tidyRoots.delete(root); continue; } // gone (or never shown)
      root.tidySeen = true;
      try { tidy(root, TIDY[root.ccbDoc]); } catch (e) { console.warn('texts.js tidy', root.ccbDoc, e); tidyRoots.delete(root); }
    }
  }, 200);

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
      root.ccbDoc = doc;
      fixButtons(root, doc);
      if (LAYOUT[doc]) LAYOUT[doc]((owner && owner.n) || {}, root);
      if (TIDY[doc]) { tidyRoots.add(root); try { tidy(root, TIDY[doc]); } catch (e) { /* done again in a moment */ } }
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
    UI, LUA, LAYOUT, TIDY, TIPS,
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
