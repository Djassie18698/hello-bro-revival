# Next steps (written by the cloud session, 2026-10-29)

## 1. Test on the PC first (nothing below was run in the real client)
Run `node tools/dev/smoke.js` (server-side sanity), start the server, then open each screen and watch logcat for `LUA ERROR` / `no node:` / signal 11:
1. Shop > VIP tab (rl_r_vipshop): list shows 23 gifts, buy VIP1 gift, buy again (should say bought), gift detail popup.
2. Home screen: new buttons for Lucky Wheel (activity 20) and Month Sign-in (activity 41). If missing, check the `<conf>` items in game.js actXml and getDisplay() in mainActivity.lua.
3. Wheel: single spin, ten spin, reward dialog, score increases.
4. Month sign-in: list shows 28 cells, tap today, reward dialog.
5. Admin page: "Set VIP level" (0-18).
If a reply crashes the client, find the parser (Lua in reference/lua-scripts, C++ via tools/armdis.py on libgame.so), fix the handler, note it in docs/PROJECT-NOTES.md.

## 2. Known gaps
- Equipment upgrade (rl_w_star), reincarnation / breakthrough (rl_w_newlife, rl_x_breakthrough), pets (rl_x_pet), Akatsuki (rl_r_group_comm / rl_w_group_admin), Dun upgrades, friends/mail, arena (rl_r_sport), tower, seven-day quests, mora (rl_r_comm).
- Many are C++ screens: needs `libgame.so` disassembly (tools/armdis.py).
- drops.js converts ninjutsu / seals / fragments into silver (20000 each); real support needs card types 5/6 and a chip bag.
- Gear stats in battles, gacha reveal "Sample Text", training battle animation: need emulator.

## 3. Endpoints the client can call that have NO handler yet
Format: endpoint  - Lua files that call it (empty = C++ only, disassemble libgame.so)
- `rl_got` - 
- `rl_r_adventure` - 
- `rl_r_bagage` - 
- `rl_r_countryranknew` - 
- `rl_r_dup` - ui_towerSweepLayer.lua
- `rl_r_friend` - 
- `rl_r_fwheel_rank` - 
- `rl_r_ky_checkorder` - 
- `rl_r_mtree` - 
- `rl_r_newbie_pay` - ui_stageGiftLayer.lua
- `rl_r_nickinfo` - 
- `rl_r_ninjalist` - 
- `rl_r_readconf` - 
- `rl_r_sport` - 
- `rl_r_sportrank` - 
- `rl_r_tear` - 
- `rl_r_tearcountry` - 
- `rl_r_warmsgnew` - 
- `rl_r_warresultnew` - 
- `rl_w_adventure` - ReNewLevel.lua
- `rl_w_comm` - collectCardActivity.lua, moraDialogRankView.lua, moraView.lua, ui_consumptionLayer.lua
- `rl_w_countrynew` - 
- `rl_w_dup` - ui_towerSweepLayer.lua
- `rl_w_friend` - 
- `rl_w_invitecode` - ui_gameSettingLayer.lua
- `rl_w_ky_payorder` - 
- `rl_w_markchip` - 
- `rl_w_msg` - 
- `rl_w_mtree` - 
- `rl_w_newlife` - ui_advanceEquipLayer.lua, ui_attributeDanLayer.lua
- `rl_w_notify_gp` - 
- `rl_w_ramen` - 
- `rl_w_sport` - 
- `rl_w_sportpack` - 
- `rl_w_star` - 
- `rl_w_tear` - 
- `rl_w_tearcountry` - 
- `rl_w_tearguard` - 
- `rl_w_warnew` - 
- `rl_w_warresultnew` - 
- `rl_w_wheel_gift` - 
- `rl_x_develop` - 
- `rl_x_sport_ext` - 

## Local test results (PC, BlueStacks "Claude Root", 2026-10-29 evening)
- Merge of cloud branch OK; smoke test passes (41 handlers).
- Month sign-in must be a POPUP entry (type 2) in actXml: type 1 = home-screen button needs a `btnImg` icon file, which activity 41 does not have (crashed ui_mainActivityBtn.lua:47). Fixed.
- Lucky wheel verified in game (opens, spin works, reward screen). Wheel needs player level >= 30 (functionconfig row 15), same for other locked modes.
- Rooted instance tips: `su -c 'ls /data/tombstones'` for native crash dumps; the game sometimes renders sideways after long taps - relaunch it.
- VIP gift purchase verified in game (cloud vip.js): list, buy, reward dialog OK. Reward dialogs (CDialogShowBox) sometimes render ROTATED 90 degrees on Android 11 x86 - same cause as the gacha "Sample Text" look; it is a client/emulator layout quirk, not a server data problem. Next idea: test the gacha reveal on the Nougat32 (Android 7) instance or force portrait via the activity's screenOrientation in the APK manifest.
- Month sign-in verified in game (list + claim + reward dialog). VIP buy verified. Wheel verified.
- KEYSTORE FIX: the original signing key (SHA-256 4F:17:60:BB...) is now release/revival.keystore (it was briefly a wrong, newer key). Updates signed with it install over the game.
- Display tip (rooted BlueStacks "Claude Root"): `wm size 1080x1920` on a 1920x1080 emulator display makes the game natively portrait; but changing it can freeze the emulator (restart only that instance).
- Gacha single-pull reveal still shows an empty card + "Sample Text": tried patching SetForJieYin(true->false) in libgame.so (0x299790 and 0x3530f2, `movs r1,#1`->`#0`): no change, so NOT the jieyin animation. Prop rewards (Tael etc.) render fine in the same dialog; ninja cards render fine via soul shop (Lua ShowAward path) but not in the gacha C++ path (CDialogShowBox created manually in CItemView::onHttpRequestCompleted / CCommonPrayDialogView). Probably InitUI's item index/vector differs; needs deeper disassembly of CDialogShowBox::InitUI (0x2a445c) vs ShowNext (0x2a3c60).
- Story stages in Training (e.g. 1-1, 8-1) skip the fight by design (Struct_Roundinfo flag) and go straight to the reward wheel.
- Sage growth (Growth button, rl_w_star): Cmd3 = rate table (`<star_list><item star_now max_percent stone_level stone_added_percent/>`), Cmd1 = upgrade (ReadyCard=card seq, StarStoneID=prop 7/8, StarStoneNum, Ext...). Reply = ATTRIBUTES on root: levelSuccess levelDrop currentLevel propLeft extPropLeft. Stored in cards.starlevel; +5% base stats per level (teamStats). Item counts reach the client only when the Shop opens (Cmd 1601 bagnum) - open Shop first after giving items by DB.
- Eight Gates (Dun, rl_w_eight_gate Cmd1 info / Cmd2 open): verified in game. Needs player level 80 (client table functionconfig row 20); souls = prop 9998 (5000 granted on first view), gate level = prop 9997; bonus +120 flat per gate and +2% per gate on the team total (teamStats).
- Friends: rl_r_friend returns all other players (auto-friends). Mailbox: rl_r_msg Cmd 1802 = system notices (welcome text), 1800/1801 empty.
- Still to do: Akatsuki (guilds), arena (rl_r_sport), tower (rl_r_dup/rl_w_dup), pets, reincarnation (rl_w_newlife), plunder seals, world boss, mora (rl_w_comm), real Training fight animation (fight stages), gacha reveal display.
- Arena (Compete tab; unlocks at level 25) verified: rl_r_sport (Cmd 2000 list: `<sport><my>rank,renown,...</my></sport><oppe><user>id,rank,nick,level,ninja,country,firstninjastar,newlife,winexp,wincoin,rewardcoin,rewardrenown,failexp,failcoin,host,<teammate/></user>..</oppe>`), rl_r_sportrank (top list `<sportrank><item>..`), rl_w_sport Cmd 8200 ToRank = fight (fight XML + `<sport renown_delta fromrank torank/>`). Ladder table `arena` (20 bots + real players join at the bottom; win swaps ranks). Reputation = prop 9996. Still not done: Exchange tab (rl_r_sport Cmd with exchange list), daily rank rewards.
- Tower / "Battles" (home, level 30): rl_r_dup Cmd 7000 -> `<duplist maxchap current_round remain_reset_count status><dup><chapid/><process/></dup>..</duplist>`; map and per-stage reward dialogs render. NOT built: the actual fights (rl_w_dup, reached via the Enter button -> stage intro with Rush Tower boss, then a fight request I have not captured yet). Next: tap through the intro, capture the request, reply with the usual `<fight>` XML.
- Akatsuki: rl_r_group_comm Cmd 8 -> `<min_user_level/><member_status/><groupid/>` (status 0 = no guild -> list screen), Cmd 1 -> `<member_status/><grouplist/>`. Create/join/apply flows not built.
- Regression sweep (all main screens open without crashing): daily, event, shop, team, backpack, training, spar, soul, growth, dun, arena, war, plunder, akatsuki.

## Update: guild + tower (verified in game)
- Akatsuki (guild.js): create (789 gold), list, join (instant), detail, base map, member list, quit all work. `rl_r_group_comm` rows are ATTRIBUTES (Lua cell.field), single values child text. Also built: hall check-in (rl_r_group_hall), rankings, gold donate (rl_r_group_contri Cmd 1/2). Guild shop opens empty (rl_r_group_store); ninja/equip/ninjutsu donation and admin actions beyond Cmd 1 (manage, kick, upgrade, setting) are NOT built.
- Tower (rl_w_dup Cmd 3100, params Chap + Round): reply MUST contain `<userinfo>` or the client crashes ~8 s into the fight animation. Process per chapter is stored in progress with chap = 1000 + chapter; process = the round to fight next (starts at 1), the icon whose index equals process is clickable. Rewards 60*chap exp, 90*chap silver. Sweep (`DupId`) and reset not built.
- Gacha reveal (still unsolved): reply parsing is fine (award cardlist -> CFightResultData::AddRewardData -> CPlayerDataMgr::AddDataFromReward adds the card to the client bag, then CDialogShowBox type 1 shows it). Tried: bagIndex = ninja id instead of seq (no change). The jieyin ccbi flag (SetForJieYin) is only set by the two gacha call sites (0x299792, 0x3530f4); InitUI never reads that flag. Next idea: decompile CDialogShowBox::InitUI branch at 0x2a4c74 (type 1) or test a normal fight-drop card dialog to see if card rewards render at all.
- Reincarnation / equipment advance (rl_w_newlife Cmd 7/8, game.newlife): server logic done and unit-tested (ReadyCard + same-id EatCard -> newlife+1, level reset to 1, silver cost 5000*grade, max grade = equipnewlifeprop rows = 3; stats: equipment x(1+row[4]), ninja +10%/grade). NOT yet clicked through in the game (screen reached from backpack equipment detail). The home "evolve" icon is a different C++ screen asking `rl_r_comm Cmd=20` (unbuilt), and the ninja "Reincarnate" screen (C++) request format is unknown.
- Potential training ("Train" icon, CPotentialView, rl_x_develop) VERIFIED in game: Cmd 1 load (`<attack limit_att add_att/><defense .../><chakra .../><cost_list><cost cost_id name type need_miyao need_golden/>`), Cmd 2 roll (BagId, CostId -> `<add_num att def ckr/><cost miyao yuanbao/>`), Cmd 3 save. Free (no pills). Saved potential adds flat to ninja stats and shows as attack_add/defence_add/cha_add in the card XML.
- The "select card" buttons on C++ screens need ~6 s after the screen opens before taps register on the emulator; wait before tapping.

## GACHA REVEAL SOLVED (2026-10-29)
Cause: C++ `CFightResultData::AddRewardData` reads `<award dropid=...>` and SKIPS the whole `<cardlist>` when dropid == 0, so the dialog had no card ("Sample Text"). Fix = `<award dropid="1">` (game.js awardXml). No libgame patch needed (the original APK works). Also: `<award>` and `<protect_comming>` are children of the ROOT, siblings of `<recruit>`.
Second bug found: `<suitlist>` items must be ATTRIBUTES `<item id=".." type=".."/>` (child elements made atoi(NULL) crash at login as soon as a set bonus became active, e.g. 5 four-star cards).
Pool fix: gacha only rolls ninjainfo rows with col6 == 0. Ten-pull (Cmd 1901, `recruit_list/item/award`) not re-tested after the fix.

## Session 3 additions
- Evolve screen (rl_r_comm 20/8, rl_w_comm 28 = god-card synthesis via game.godSynth): opens with 99 pills; card selection + synthesis not clicked through.
- Save time (rl_r_savetime Cmd 1/2): real data, ramen = prop 3 (starts at 99). rl_w_msg acknowledged.
- rl_r_comm other Cmds (13 consumption, 15/18 slot machine, 9 inherit) return empty stubs. Border war (rl_r_frontiers_war_*) unhandled but screen opens with defaults.
- Settings dialog + invitation code (rl_w_invitecode: any new code = +500 gold) verified. Friend screen verified (lists other players); its "Communicate" button and "Add friend" send nothing/unhandled (rl_w_friend not built). Bottom icon bar scrolls by swipe (arrows don't): page 2 has Settings and Friend.
- REINCARNATION VERIFIED (ninja screen): needs card level 50 (max), 80 pills (prop 11) or a duplicate card; pill counts reach the client only after the Shop was opened once this session (CTradeMgr is filled from shoplist bagnum). Result dialog shows before/after stats from the client's own formulas.
- All Training chapters unlocked (mainpage `<chapinfo currentchap="19">`); stage list + fight + reward wheel verified (rl_w_pve Cmd 2/3). Stages require ninja level (shown as "Requirements").
- EVOLVE (god card) works in game: needs two 5-star cards of the SAME character (npc icon): the attack version (ninjainfo r[20]>=r[22]) + the defense version (e.g. ids 1 + 153 Sage of the Six Paths -> god 2028). Both not in team. rl_r_comm Cmd 8 asks cost; rl_w_comm Cmd 28 does it. Award card needs `<newlife>` etc. or the client Lua errors in GetTopInlayFrame.
- Top-up screen (shop icon): $49 gift claim works (rl_r_comm 16 / rl_w_comm 26: +4900 gold once per player). The top-up package grid below stays empty (ui_purchaseLayer.lua:137 wants fields from rl_r_paypack Cmd 1 that the cloud handler doesn't send; rl_r_readconf unhandled) - cosmetic, everyone gets gold from admin anyway.
- MORA built + verified (mora.js; rl_r_comm 3 info, rl_w_comm 4 play / 5-6 exchange / 7 buy life). Icon on home left column; activity id 21 added to actXml conf. res 0 lose / 1 draw / 2 win. Rank list shows only the player.
- MONEY TREE built + verified (rl_r_mtree / rl_w_mtree; reached via Daily Task -> "Money Tree" Go). The write reply must return the player's NEW TOTAL gold in `<cash>` and silver in `<coin>` (client sets, not adds). 5 free shakes, then 20 gold; reward 5000 x1..5.
- rl_w_ramen added (energy to full; reply only needs code=0; untested in game). Adventure (rl_r_adventure at login LoadRoundInfo, rl_w_adventure from CRunLevelView, probably the "Awakens" tab in Training) NOT built: the tab did not react to taps. Still unbuilt: slot machine real data, border war, friend add/chat (rl_w_friend), rl_r_readconf, rl_r_nickinfo (friend search).
- Friend search (rl_r_nickinfo) and slot machine (slot.js; rl_r_comm 15/18, rl_w_comm 23/24/25) added; slot logic unit-tested only: no home button opens ShowSlotMachine (only C++ may call it), so it was NOT seen in game. Border war and adventure still unbuilt.

## Public repo
https://github.com/Djassie18698/hello-bro-revival-public (published 2026-10-30). To update it: `python -I tools/make_public.py C:\Users\dj199\hello-bro-public`, then commit + push in that folder (author = GitHub noreply email). Never copy game files, saves, keys or IPs there; make_public.py refuses them.
- WHEEL RANKING verified (rankings.js; rl_r_fwheel_rank, rl_w_wheel_gift Cmd 1 rank gift daily / Cmd 2 points gift). Lua containers: `<rank><item>..</item></rank>` and `<wheelpackage><item attrs/></wheelpackage>`.
- game.grantDrop(db, pl, dropId) grants any dropinfo row (ninja/equip/prop/silver/gold/souls) and returns a full <award> - use it for every new reward so prizes match the original game.
- ARENA EXCHANGE verified (rl_x_sport_ext Cmd 2 Exchg = exchange_award row, cost col 6 reputation, reward drop col 7; Cmd 1 must answer code 1 or the client crashes; Cmd 3 daily rank reward). Admin page can now give arena reputation and ninja souls.
- TOP-UP: package grid shows (rl_r_readconf rechargelist, rl_r_paypack VIP header). Recharge = rl_w_ky_payorder (ItemId): server grants gold, answers code 1 ("Successfully purchased") so Google Play never opens. Not yet clicked after this change.
- HOT UPDATE WORKS (verified: download + unzip on device): rl_r_version must have `<updatechip><version val/><cdn/><filelist><file name="<val>_update.zip" val md5 size/>`. Zip name must start with the target version + '_'; zip needs explicit folder entries (tools/build_cdn.py). Files land in /data/user/0/com.hello.bro.yo/files/script/... Not yet proven that the game LOADS the updated Lua (the purchase layer still used the old code path) - next: check setSearchPath / renlong_res folder.
- Wheel ranking, arena exchange verified. M1 security done.

## Tower sweep (built from Lua, NOT yet clicked in game)
- rl_r_dup Cmd 7002 = `<dup_count><total/><remain/><vip/></dup_count><dup_list><dup name selectable/>..</dup_list>`; sweep id = (chap-1)*6+round (3 chapters x 6 rounds).
- rl_w_dup Cmd 3102, DupId 'id|id|..' = `<dup_list><dup name><award>..</award></dup>..</dup_list>`. 5 sweeps per day (counter in progress table, key 100000+day). Reward = same as winning the round (60*chap exp, 90*chap silver). Only cleared rounds are selectable.
- WORLD BOSS built + verified (boss.js; rl_w_xiao Cmd 1/3/4/6/7/8/9/10/11, rl_w_xiao_war fight). Shown in Event popup via conf items [12,6,2] + `<xiaoopen>1</xiaoopen>`. One shared boss per server per day (3M HP x level; level +1 if killed yesterday). 5 fights then 10 min rest. Reputation = prop 9995, spent in the boss shop (grantDrop). Damage feed + daily ranking + rank award claim.
- Tower ranking (rl_r_dup 7001) verified. Tower SWEEP: cloud built the server side, but this client version has no sweep button on the tower screen (CTowerView::onBtnSweep is never bound) - unreachable.
- Player messages: friend "Communicate" (rl_w_friend Msg+ToUid) lands in the receiver's mailbox (System tab).
- Hot update now LOADS: files must be under renlong28/ in the zip (see docs/HOT-UPDATE.md).
- COUNTRY WAR built + verified (country.js, war.js):
  - Country tab: 7 official seats per country (Hokage, custodians, elders); empty seat = direct take, occupied = fight vs holder (rl_w_countrynew 4002 Offical=seat, reply `<officaltake direct=0|1>` + fight). Daily official reward box (4003) via grantDrop.
  - War tab: always-on war vs the other two countries (rl_r_warnew `<preview resttime="0" open="1" myCountryID fightlefttime="0" curintercost>` + `<user>` stats + `<country><my killnum/><he killnum/>` + autoinfo). Attack = rl_w_warnew 4102: root children `<CountryWar batter/>`, `<userinfo>`, `<fight>`, `<award>` (InitFromXML takes the ROOT). 10 lives/day, revive 4101.
  - News ticker/personal log: rl_r_warmsgnew 7700 `<warmsglist><warmsg>` / 7701 `<usermsglist><warmsg>` with child text fields (id, fromnick, tonick, fromcountry, tocountry, killnum, fromofficer, toofficer, msgtype, iswin, score, powernum).
  - rl_r_warresultnew 8100: `<winpace><canrequire/></winpace><lastres><open>0</open>...`.
  - Ranking tab: rl_r_countryranknew 4202 individuals (`<userrank myrank curpage><userlist><user> rank uid nick power countryid`), 4200 nations (`<countryrank><country> id king winnum falinum`).
  - NOT built: Reward tab (war exploit shop, rl_w_warnew exchange), auto-attack purchase effects.
- War Reward tab verified (rl_w_warnew 4100 PackID = warconfig row type 2: cost col 5 exploit (prop 9994, shown via mainpage meritscore), drop col 6). Attacks earn exploit (10 per win).
- grantDrop now: col 10 gold, col 11 silver (was wrong), and resolves RANDOM packs (drop type 1 without a fixed item) from their description (shinobi pack -> ninja by star, equipment pack -> gear, gift pack -> card or gold).
- PLUNDER / TAILED-BEAST SEALS verified (seals.js): rl_r_markchip `<cash/><chiplist><chip><id/><count/></chip>..</chiplist><markmerge><mark><id/><resttime/></mark>..` (fragment ids = markmerge cols 3-8, stored as props 20000+id). Plunder = rl_w_pvp Cmd 2700 ToUid + Chip: win -> 70% to steal the fragment. Merge = the seal's "Claim" button -> rl_w_markchip Cmd 2801 MarkID (+UseCash), reply `<markchip bagid="seq"/>`; seal = card type 5 (ninja_id = markinfo id).
- Seals equip in the team Seal slot (rl_w_ninjalist Cmd 2304) and multiply the wearer's stat by markinfo col 7 ("ATK +35%") - verified 791-1236 -> 1068-1669.
- BORDER WAR (Boundary Monument) built + verified (border.js; rl_r_frontiers_war_info/user_info/attack/enemy_info/clear/award_info/recv_award/rank). Countries 0-4 (Wind, Thunder, Water, Fire, Earth). Taunt (gold, Cmd 1) / Wander (silver, Cmd 2) station 30 min in an enemy country and damage its monument (2M HP/day); enemy list + Clean fights for defenders (clear not clicked: needs a second player stationed in your country); intruder/defender rankings (yesterday = today, history = all); rank chest claim = 500 gold via grantDrop. Lua list nodes use ATTRIBUTES (`<item id num/>`, `<item rank nick country level score award/>`).
- Endpoints now handled: 61 of 73 client endpoints + border/boss/etc. Left: adventure (rl_r/w_adventure, no reachable button found), tear raids (rl_*_tear*, C++ only), rl_got, rl_r_bagage, rl_r_ninjalist, rl_w_sportpack, payment-only endpoints.

## National treasure raids + Ninja Treasure (2026-10-30)
- tear.js: rl_r_tear (<trea> bank info), rl_r_tearcountry (<countrylist>), rl_w_tearcountry (raid ToCountry; guard fight or direct grab),
  rl_w_tear (hand in: 5000 silver + 10 merit each), rl_w_tearguard (toggle guard). 5 raids/day. Screen is C++ CCountryTreasure,
  only reachable from the seven-day event (quest index 12 "Go") -> not yet verified in game.
- sudoku.js: Ninja Treasure (activity 24, chest icon on the home screen's left column). rl_r_sudoku board, rl_w_sudoku Cmd 1 reroll (20 gold),
  Cmd 2 explore (10 + 10 per prize taken), Cmd 3 take all. Verified in game: board, explore, take-all, auto reroll.

## Seven-day goals (2026-10-30)
- sevenday.js: rl_r_activity Cmd 9002 (<seven_target><item><day/><reward/><tlist><t><id/><st/></t></tlist></item>x7) and
  rl_w_activity ActType 7 ActID day (grants the 3 sevendays_info drops). Day = account age, claim on day d or d+1.
  Tracked goals: level, top ninja level, arena rank, team attack/defense, treasures turned in; other goal types count as done.
- Shown via hot update 28.0.5 (conf item 47, type 2). Verified in game: list, day 1 claim, "Go" to the national treasure screen.
- National treasure verified in game: plunder (no defender -> direct grab), contribute (+3000 silver), defend. Nations are 0-4.
- Quest texts come from the Thai data table (sevendays_quest), so they show in Thai; would need a table edit to fix.

## Base: Ninja Test, Breakthrough, Pets (2026-10-30) - all verified in game
- exam.js (rl_x_exam): 15 stages x 5 guards (odd = you attack, even = you defend), team of 4-star+ ninjas, fallen ninjas stay
  fallen for the day, 3 tries/day (+20 gold each), chests (3 on every 5th stage), score shop incl. grain/nostrum and the
  player's own god-card fragments. Cmd 1 info, 2 team, 3 exchange, 4 buy try, 5 fight, 6 chest, 7 next stage.
- tupo.js (rl_x_breakthrough): god cards (quality 6) only; level n -> n+1 costs 5+5n of that card's fragments and
  50000*(n+1) silver, max 10; each level +4% stats (cards.breaklvl, used in game.ninjaStats).
- Card fragments are now real: props 30000+pieceId, granted by drops (dropinfo col 8), sent at login as <chipbag><chipitem id num/>.
  Soul drops (dropinfo col 9) are granted too.
- pet.js (rl_x_pet): everyone gets all 8 pets + 200 grain + 200 nostrum. Level (grain, petupgrade), rank (nostrum,
  petupgradeequ chance), stars via training (gold, max 5 = what the screen draws). Master pet 50% + helpers 15% of their
  stats go to team stats; master pet id is sent in fights (<master_pet>). Pets open at level 30 via hot update 28.0.6.
- rl_r_shoplist 1601 now also lists owned items without a price: the client reads bag counts from it (opening the Shop
  once refreshes them). Pet screens show 0 grain until the Shop has been opened once after login.

## Base kept original (2026-10-30)
- Pet unlock (150) and helper slot levels are the original ones again (28.0.7 undoes 28.0.6). No free pets or food:
  pets come from 30 fragments merged in Backpack > Fragments (rl_w_comm Cmd 10, game.mergeChips), fragments/grain/nostrum
  from the mystery shop, which now sells the original secret_shop mix by weight.
- Pet stats/training use petinfo values; breakthrough raises only the card's element stats; Ninja Test takes 4-5 star only.
- Full list of what each Base building needs: docs/BASE-FEATURES.md.

## Team swap fixed (2026-10-30)
- rl_w_ninjalist Cmd 2300 (Team > card > Change) was ignored. Params: Seq (slot, 1-based), OldID (card leaving, 0 = empty),
  NewID (card joining), TeamId. game.teamSwap: replace, trade places if the new card is already in the team, or add to an
  empty slot (max 5). Verified in game. HB_DEBUG=1 logs the params of this endpoint.
- Claude Root rotation lock removed (accelerometer_rotation 1, user_rotation deleted); the game still asks for portrait itself.

## Main-function fixes (2026-10-30)
- Crash after level-up -> Team: client calls rl_r_ninjalist (C++ CMyGroupView), which was unhandled. Now answered with
  activeTeamId + suitlist + ninjalist (+ empty defense lists). Also added rl_r_bagage, rl_r_adventure/rl_w_adventure
  (campaign round info), rl_w_sportpack. Every '/rl_...' the C++ client calls now has a handler.
- Campaign fight crash: <master_pet> in fights must contain BOTH <id> and <pet_id>; only sent when a master pet exists.
- Left event column vanished: conf item 31 (stage gift) uses ccbResources/activity_icon_11.png, missing in the v28 OBB.
  Kept off (onoff 0).
- Ninjutsu cards are real now (dropinfo col 5 -> card type 6, equipped adds chance x 20% attack); seal cards (col 6) too.
- Millionaire/Monopoly (monopoly.js) verified in game: board, dice, ranking.
- Admin page: "Reset a player" (keeps the login, deletes the character; backup first).
- cdn/ (hot update zips) is now committed so a fresh clone serves the game fixes. PLAY-ON-TAILSCALE.md + release xapk.

## Training progression by PARTS (2026-10-31)
- The client counts PARTS, not single stages. roundinfo [3] restarts at 1 for every part and the last stage of each part is its boss
  (165 parts over the 19 chapters, checked: every part ends in a boss). The fight request sends `StageID` = part number and `Pos` = row inside
  the part; `<preview currentstage>` / `<stage stageid>` / `<pve curstage>` and mainpage `<chapinfo currentstage>` are PART numbers
  (CSectionCellView::InitUI compares CurrentSection with the selected part; CChapterCellView::onHttpRequestCompleted fills the rest).
- `<stagelist>` = one `<stage stageid=part pos pos_time pk_boss_times/>` per part reached: pos = open row inside the part, pos_time = clears of
  that row, pk_boss_times = boss tries left. Beating the boss (needed clears) opens the next part; the last boss opens the next chapter.
- Before, the server sent global stage numbers as part numbers, so parts opened far too early and rows did not open top to bottom.
- game.chapterParts / stagePart / globalStage / partEntry; handlers.trainingFight(db, pl, chap, part, pos). A chapter without a progress row
  (never opened) now refuses fights. Accounts that already have progress rows for later chapters keep them open.
- Verified with a simulated player on a temp DB (not yet in the real game). Training fights are still always wins against fake enemies.

## Event pack claims pay the real items (2026-10-31)
- Login (actid 1) and Level-up (actid 2) gifts used to pay an invented amount of silver + gold, so the "Rewards" dialog showed "Gold*25" and the
  backpack never got the tickets/fragments listed on the button. The client's own tables (reference/lua-scripts loginActivityData.lua /
  upgradeActivityData.lua, 1-4 dropinfo ids per row) are now read and every drop is paid with game.grantDrop (merged into one <award>).
  Verified on a temp DB (login day 1 = 2 recruitment orders + 1500 silver). Reported in GitHub issue #2.

## Training wins drop items (2026-10-31)
- trainingFight now pays one dropinfo drop per win via game.grantDrop (handlers.stageAward). The original drop rule is lost: (ours) normal stage =
  50% ramen*1 (drop 31) / 30% "One, Two-Star Equipment Card" (19) / 20% "One,Two-Star Shinobi Card" (16); boss stage = 50% "Three-Star Equipment
  Card" (21) / 50% "Three-Star Shinobi Card" (17). Owner asked for "a low tier ninja or equipment".
- rollPack: "One, Two-Star ..." and "Three-Star ..." packs are now exactly those stars. randomEquip crashed for slot 3 (slots are 0-2) and has a
  maxStar argument now.
- Verified: the card/prop arrives in the save (temp DB + the Claude emulator). NOT verified: how the client's 3-card victory screen and the
  story-stage reward wheel (always lands on "work harder", FightReward+0x20 decides the segment) show the new drop. Open.

## Fights replay consistently; spar balance (2026-10-31)
- battleXml now plays a real turn-based replay (my ninjas and the enemies hit in turn, a ninja falls when damage taken reaches its `end`), so the
  winner shown on screen is the one still standing. When the server already decided win/lose (spar, arena, exam, border, war, country, tear)
  the enemy stats are scaled to the player's ninja until the replay agrees (tested 300/300). Before, enemies had fixed weak stats and a
  decided "lose" was a win replay -> "enemies 0 defense, then you lose" (GitHub issue #2). Training still uses fixed weak enemies (always wins).
- Bot strength for spar = 60 + 30*level + 30*star (ours; was 150+55*level+60*star, a level-1 player could never win). About 60% wins at equal level.

## Boss stages: 3 free fights, then gold (2026-10-31)
- Owner/friend: the original gave 3 boss fights a day, not roundinfo [43] (10-20). game.BOSS_FREE = 3; with 0 left the client shows a gold button and
  sends WastCashBoss=1: the server then charges BOSS_COST = 10 gold (the number on the button) and lets the fight happen. (GitHub issue #2.)
- 10-pull orange-card zoom: NOT a server thing. This client (CCommonPrayDialogView / CItemView onHttpRequestCompleted) goes straight from the
  recruit_list reply to the CPrayTenDialogView list; CDialogShowBox (the zoomed card) is only used for a single pull. Needs a libgame.so
  patch or a client change; open.

## Free recruits, pity counter, first-recharge gift (2026-10-31)
- Free recruits (GitHub #2): game.FREE_EVERY = purple (type 1, 300 gold) every 24 h, blue (type 2, 150 gold) every 8 h. State in table
  recruit_state(last_free, pity). rl_r_shoplist 1600 sends recruit_time (interval), last_recruit_time, free_recruit_time_left (CPlayerNinjaRecruitMgr::
  AddNinjaInfoFromXML reads those); rl_w_recruit Free=1 is refused until the timer is 0. NOT verified in game: which button the client shows as free.
- Pity counter: rl_r_recruit sends <recruit protect_comming=N> (pulls still needed for a sure 5-star). (ours) PITY = 20 for both types; the original
  number is lost. A 5-star card resets it; the 20th pull is forced to 5-star or better.
- First-recharge Claim (rl_w_paypack without HeapID): needs VIP exp >= 10 ($1 top-up), once (actclaim 9027), pays firstpurchase.json drops (cols 2, 5, 8);
  errors 250011 (not topped up) / 250010 (already claimed) are the codes the Lua shows tips for. The "49$ gift" (payheap) rewards are NOT built.
- Not server-fixable / open: opening cartoon cannot be skipped (client code), victory screen shows silver 0 and Chinese names for the 3 filler cards
  (client-side fillDropData), story-stage wheel always lands on "work harder", 10-pull orange zoom (owner: skip).

## Monthly sign-in opens one slot a day (2026-10-31)
- Before, every day up to today's date was claimable at once. Now (signin.js) slot N+1 opens after N slots are signed and only if nothing was signed
  today (monthsign.date). Verified on a temp DB. GitHub issue #2 ("Sign in rewards are all available").

## Story-stage reward wheel lands on the dropped item (2026-10-31)
- CDialogRunLevelTurnView::StartTurn (libgame.so) reads `<award type=N>`: types 1..5 stop the wheel on segment 4,3,1,0,2; any other value = 0.
  Segments (counter-clockwise from the top): 0 "work harder", 1 EXP x2, 2 gold, 3 silver x2, 4 cards. handlers.stageAward now sends type 1 when a
  card/equipment dropped (wheel stops on the cards, then the "So lucky!" card reveal shows), type 5 for gold, type 4 (work harder) otherwise.
  Verified on the Claude emulator with a forced drop (env HB_STAGE_DROP=<dropinfo id>, test aid). EXP x2 / silver x2 are never selected: no doubling is paid.

## Cumulative top-up rewards ("pay history" / 49$ gift) (2026-10-31)
- rl_r_paypack now sends `<payheaplist><payheap><id/><state/></payheap>..` (mainActivity.lua initPayHisData; state 0 = claim, 250011 = not reached, 2 = claimed) and
  rl_w_paypack HeapID=n pays the step (game.payHeapXml / payHeapClaim). Steps and drops come from the client's payhistorydropData.lua
  (month_dayback = total $ topped up, up to 4 dropinfo ids). Total $ = VIP exp / 10 (top-ups are free on this server but count). Claimed = actclaim 9028.
  Verified on a temp DB; not yet seen in the game's top-up screen.

## The "49$ gift" row on the top-up screen (2026-10-31)
- It is the first-pay bonus of ui_purchaseLayer.lua: rl_r_comm Cmd 16 `<basic><status 0 not reached / 1 received / 2 can claim><amount cents><current cents>` +
  `<awards><item icon1..3 drop1..3>`, claim = rl_w_comm Cmd 26 (errors 610001 not enough top-up, 610002 received). Before, it showed 49/49 and handed out 4900 free
  gold. Now: needs $49 of top-ups in total (VIP exp / 10), pays drops 11 (5-star shinobi card), 15 (4-star ninjutsu card) and 374 (Madara) once - those are
  the three icons the button shows (props_015 / props_049 / props_073). The original reward list is lost (ours, from the icons).
- Ninjutsu packs ("Four-Star Ninjutsu Card" etc.) now give a real ninjutsu card of that star (was 30000 silver placeholder).

## Victory-screen items without image / with Chinese name (2026-10-31)
- Cause (GitHub #2 "rewards without an image"): the ramen item (consumeinfo 4, dropinfo 31) renders on the 3-card victory screen with the ccbi default
  swirl icon and the Chinese label "大拉面"; other props (recruitment order, Sage Stone III, Silver Key) show the correct icon and English name. Backpack/shop
  show ramen fine, so it is only the victory/award card for ramen (client side; not found why). Workaround: stage drops give Sage Stone III (dropinfo 250)
  instead of ramen. Other drops that award ramen (login/level packs, first-recharge) may still show the broken card.
- The 2 filler cards beside the real drop come from the client's own fillDropData table, not from us.
- Victory screen still shows silver 0 (the `<award coin>` is paid; the screen reads it from another field I have not found).

## Fight replay rules learned from the client (2026-10-31)
- CNewFightCardView::SetFinalData: each round has FinalAttack (FA) and FinalDefense (FD). The attacker's card shows FA - FD, the defender's card (the shield
  number under the enemy portrait) shows FD - FA when positive, else 0. So the enemy "0" under its portrait is the client's normal display when the hit gets through;
  a number only shows when the defence beats the attack. FA < FD makes the client's UNSIGNED subtraction wrap ("2000K") and crash (fault addr 0xa4), so FA >= FD+1 always.
- <Defense> (the non-Final field) with a real value crashed the fight: leave it 0.
- A replay longer than the number of enemies (several hits per enemy, enemy attack rounds) made the client's "Enemy Team" counter go to -1/3, -2/3 with garbage cards.
  Won fights now send exactly one hit per enemy (enemy `end` below any hit), enemy defence shown on the victory screen (DEF 326). Lost fights keep the
  turn-based replay (spar/arena/exam/war etc.): NOT verified in game.
- BlueStacks "Claude" keeps opening an ad page (Whiteout Survival) over the game during tests: `emu.sh back` + `emu.sh restart` brings the game back.

## Exp / silver counted twice -> level jumping back (GitHub #3, 2026-10-31)
- The client credits a training win's exp and silver from its own roundinfo table (CSectionCellView::CalcRoundReward) AND again from <award><exp>/<coin>.
  Verified on the emulator: server +6 exp showed +12 in the client bar, silver +15 too much. The award for training wins now carries 0 exp / 0 coin
  (only the drop), so client and server agree (checked: bar 6/54 and silver 19995 on both).
- The client never reads the player's exp from the server (UpdatePlayerDataFromXML has no 'exp'): its bar starts at 0 after every login. rl_w_login2 therefore
  sets players.exp = 0 so the server levels up at the same moment as the client.

## Battles (tower) duel crash fixed (GitHub #3, 2026-10-31)
- Crash ~8 s into a Battles duel, after the fight played to 0/3: the reply used game.awardFull (<award dropid="0">), and the result screen crashes on dropid 0
  (same trap as the training "award needs dropid != 0"). rl_w_dup now answers with stageAward (a real low-tier drop, exp/silver not repeated because the
  client credits them from its own table). Verified on the Claude emulator: duel plays, round advances (DEFEAT stamp), no crash.

## Daily task rewards and one-clear bosses (GitHub #3, 2026-10-31)
- Daily Task chests: the reward dialog reads `<award><drop_list><item>DROPID</item>..` (ui_dailyRewardLayer: prop_list[i][1] = dropinfo id) - we sent an empty drop_list, so it
  showed 4 empty boxes and the claim paid made-up coin/gold the dialog never showed. Now each chest lists real dropinfo ids (ours: 20 pts 5000 silver, 40 pts 20 gold,
  60 pts 10000 silver, 80 pts 50 gold, 100 pts 100 gold; the original list is lost) and the claim pays exactly those via grantDrop, only when the points are reached, once a day.
  Verified on the emulator (dialog shows "5000 Silver*1", chest opens, server +5000). The top bar silver refreshes on the next screen change (AddSoulAwardData does not add silver).
- Boss stages need ONE win to open the next part (game.clearsNeeded; roundinfo [42] says 3 for all 165 boss rows, the owner says the original needed 1). Verified in game.
