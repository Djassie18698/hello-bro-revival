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

## Profile grudge timers and the "1 in 100" recruit (GitHub #3, 2026-10-31)
- Profile screen showed "10/3" grudge and negative timers ("Full grudge -12:00:-5"): cursp was a fixed 10 above the max (playerlevel column 3). Now grudge is real:
  max = playerlevel[3], +1 every 2 h (ours; derived from the client's "01:59:55" at pass time 0), a spar (rl_w_pvp) costs 1 and is refused at 0. Mainpage sends cursp and
  LastSPUpdatePastTime (seconds into the current 2 h tick). Verified on the emulator: Profile shows 3/3 and 00:00:00.
- Shop > "1 in 100" (recruit type 3): "claim -1 times today" and "Free after 00:-54" came from recruit_limit 0 / recruit_time 86400. It is now the original "Use up recruitment
  orders x 1": costs prop 30 per card, at most recruitinfo[5] = 5 cards a day, no free timer (it used to be unlimited and free). Shows "You have: N" in the game.

## Chains (ninjamatch) now count (GitHub #3, 2026-10-31)
- The "Chains" list on a card's detail screen is data/ninjamatch.json (1910 rows; col 3 = the card, 5 = type, 6-13 = partner ninja ids, 14 = equipment id, 15 = ninjutsu id,
  16/17/18 = attack/defence/chakra ratio). Nothing used it, so no chain ever worked. game.teamStats now adds, per slot after gear: type 1 chain = ratio x that slot's stats when ANY partner is in
  the team or the listed equipment / ninjutsu is worn by it; type 0 (leader) = the ratio goes to every slot while that card is in the team. Several chains stack additively.
- Verified on the Claude emulator: Susa Indra next to Sage of the Six Paths shows 811-1112 attack (raw 525-720); the numbers also feed fights, rankings and spar strength.
- The client's own detail screen lists chains but does not highlight active ones; nothing more is needed from the server for that. Not verified: stack rules of the original (we add them), chains that need a
  specific star/level (the table has no such column).

## Reward wheel lands on every segment (GitHub #3, 2026-10-31)
- handlers.stageAward: a dropped card -> cards segment (award type 1); otherwise luck (ours): 40% work harder (type 4), 20% EXP x2 (type 3), 20% silver x2 (type 2), 20% gold (type 5, 3 gold).
  The client already credits the stage's own exp/silver, so a doubled segment sends ONE extra copy in the award fields (client adds them) and the server pays the same.
  Verified on the emulator: gold segment (+3 gold, panel "EXP 8 / gold 3 / silver 20") and EXP x2 (client bar +16 = 8+8). Silver x2 uses the same path but was not run in game.
  Test aid: HB_WHEEL=<type> forces a segment. Fixed on the way: the doubled exp used a stale player row and overwrote the base exp.

## Active chains turn red on the card detail screen (GitHub #3, 2026-10-31)
- CNinjaDetailView::SetCombin paints a chain red when its ninjamatch id is in the team card's `<combinlist><combin><combinid>` (CTeamCard::firefly_InitFromXml; also `<readycombinlist>`).
  slotXml now sends the active chain ids per slot (game.teamStats s.active, the same rule that adds the bonus) and, in readycombinlist, chains whose partner is owned but not in the team.
  Verified on the emulator: Susa Indra + Sage of the Six Paths -> chains 1 ("Fight with Sage Six Path") and 5 ("All Shinobi") red, the others black.
- Test aids added: HB_SPAR=win|lose (forces a spar result), HB_WHEEL, HB_STAGE_DROP.

## Lost fights and free recruits checked in game (2026-10-31)
- Lost fights (spar, arena, exam, border, war, country, tear) used the turn-by-turn replay and broke the client exactly like the old boss bug: enemy counter 0/3 -> -1/3 -> -2/3, "2000K" cards, then a crash.
  battleXml(win:false) now plays ONE enemy hit per ninja of mine (FinalAttack > my hp, no hits from me). Verified on the emulator (forced with HB_SPAR=lose): Fight banner -> LOSE screen with Compare, no crash.
- Free recruit (rl_w_recruit Free=1) verified in game: the blue 1-in-1000 pull cost no gold, state saved, and the button then reads "Free after 0 days 7 hours". The pity counter text ("recruit N more times")
  was not seen on screen yet.

## Victory-screen silver 0: why it stays (2026-10-31)
- CNewResultWinView::InitUI shows exp and silver as reward.exp / reward.coin (+ the round table values for fight type 0). The exp label shows the table value (+6) but the silver label shows 0 while
  the award carries coin 0. Putting the stage silver in `<award><coin>` fixes the label but the client then credits it a SECOND time (CSectionCellView::CalcRoundReward -> AddDataFromReward), which
  would double the silver. Left at 0: a game-side display issue, not changeable from the server.

## Training enemies scale through the whole campaign (GitHub #4 URGENT, 1 Nov 2026)
- Before: every training fight used the same 3 enemies (ninja 21-23, level 1, fixed stats), so all bosses looked alike ("3 cards, 1023 defence").
- Now game.stageFoes(chap, stage): boss rows of roundinfo list their real enemies in cols 7-21 (npc ninjainfo ids: col 7 = level, col 11 = star, no stats).
  An npc gets (ours) the AVERAGE base+growth stats of the game's playable cards of that star at its level, times ENEMY_SCALE (0.6, env HB_ENEMY_SCALE to tune).
  At most 5 enemies (fight screen). Examples: 1-2 Mizuki + Chūnin L2; 1-23 boss L17-20; chapter 8 L120-125; chapter 19 L300.
- Only boss rows are real fights (normal rows are story stages: no fight, the wheel). A boss fight is decided by team power vs enemy power (luck 0.85-1.15, ours);
  a loss costs the energy and one boss try (game.stageTried) and opens nothing. Starter card: first boss won 60/60, chapter-1 last boss 0/30 (needs a team).
- Lost replays: only the attacking side has rounds (CFightResultData::AddFightRoundData), so a loss is my ninjas each landing one weak hit; the client still greys the
  enemies out by itself but shows LOSE, no crash, no negative counter (verified, HB_PVE=lose). Won boss fight verified: real enemies (Moegi, Udon L5), Victory.

## New admin page (1 Nov 2026)
- The page is now admin.html (served by admin.js). Players sidebar, stats, Resources (quick buttons), Give (one catalog of shinobi/equipment/ninjutsu/seals/items/
  fragments/pets with type + star filters and counts), Give everything (whole group, optional star, capped at 5000), Inventory (cards with Remove, items), Reset
  (name must be typed). APIs: /admin/api/catalog, givething {cat,id,count}, bulk {cat,stars,count}, inventory, delcard; old give/givecard/reset kept.
- "I give a weapon and nothing arrives": verified the server stores it and the game shows it (Sword of Kusanagi + Uchiha Shisui) after the game is CLOSED and opened;
  the client reads cards only at login. The page now says that in a banner.

## EXP bar and energy (GitHub #5, 1 Nov 2026)
- `<score>` in rl_r_mainpage is the client's EXP field (CPlayerDataMgr::UpdatePlayerDataFromXML stores it at +0xd4, the same field AddExp uses). We sent 0, so every main-page
  visit reset the exp bar: exp went "up and down" and the client and server levelled at different moments. Now score = players.exp, and the old "exp = 0 at login" hack is removed.
- The main page refilled energy to the level maximum on every visit ("go back to the main menu and stamina is full"). Now game.energyTick: the original rule normalconfig row 9 =
  1 energy per 180 s up to playerlevel col 4, and LastActionUpdatePastTime = seconds into the current tick (the client runs the same timer). normalconfig row 10 = 1 grudge per 7200 s
  confirms the grudge value we already used. The client has no refill on level-up (CPlayerDataMgr::firefly_FullRecover has no callers).
- Chains match partners by character name (variants and "(God)" count), because the table has only 8 partner places (Kaguya lists Susa Kakashi 5026 only, not 5027/5028).
- Unsolved items of all bug lists now live in docs/OPEN-ISSUES.md.

## Bug list 3 leftovers (GitHub #4, 1 Nov 2026)
- "Beast" placeholder card: the <award><card><type> is the CLIENT's reward kind (1 shinobi, 2 any equipment, 4 ninjutsu, 5 seal), not our cards.type (2/3/4 equipment, 6 ninjutsu).
  grantDrop now maps them (AWARD_TYPE). Verified in game: first-recharge shows Senju Tsunade (God), Sword of Kusanagi, Big Ball Rasengan (ninjutsu card).
- Same victory card every time: "X-Star ... Card" drops have one example card in dropinfo col 3/4 and drop type 1 (random); grantDrop gave the example. Now rolls a random card
  of that star/kind (17 different 3-star shinobi in 40 rolls instead of always Aburame Torune).
- Recruit odds now stay within each banner's promise (purple 4-5 star, blue 3-5, green 2-5; weights ours). Pity text verified on screen ("Recruit 19 more will get one Five-Star Purple").
- Free recruit repeat: verified in game that a second press without closing the window is charged (300 gold); the server refuses a second Free=1.
- 0 defence in training: the friend's screenshot shows the attacked enemies' defence (blue shield) = 0 at that moment, i.e. broken; the boss scaling now gives real defence
  (shown on the victory screen). The number on the card itself follows the client's SetFinalData rule.
- 7-day goals: hot update 28.0.10 adds ui_sevenDayCell.lua with English goal texts (SEVEN_DAY_EN). Verified in game ("Reach player level 70"); Go opens the right screen.

## Energy: level-up refill, ramen (1 Nov 2026, owner request)
- A level-up fills the energy to the new level's maximum (game.addExp); training pays its energy BEFORE the exp so the refill stays, and the pve reply sends the real energy.
- Ramen (BuyRemenDlg -> rl_w_propuse): the client SETS its energy to <propuse ap>, so ap is now the new total (was the +200 delta); rest/max (daily ramen limit) 99.
  rl_w_ramen fills to the level maximum (was a fixed 106). The 180 s regen (normalconfig row 9) stays.

## List 4 + admin (1 Nov 2026)
- Reincarnation (game.newlife): shinobi go to rebirth 8 (cards show 8 stars; NEWLIFE_MAX). The invented silver cost (5000 x grade) is gone: the
  original screen asks ONE copy of the same card OR newlifeconfig[grade][star] reincarnation pills (prop 11), e.g. grade 7 star 6 = 1030.
  The rebirth-7 "Your energy level is full" tip was our code-5 'not enough silver' (the client shows its own text for code 5).
- Training: after the last boss of a chapter the reply's <pve curchapter> points at the next chapter so its map opens.
- Chains: partner names are compared without "(God)", spaces and dashes ("Ten-Tails (God)" = "Ten Tails").
- Soul refinery (rl_x_mystery_shop Cmd 5 preview, Cmd 3 refine): cards become souls (prop 9999) by refinery_info quality (6=2000, 5=1000, 4=150).
- Akatsuki buildings (rl_w_group_admin Cmd 8 list, Cmd 9 upgrade): (ours) max level 10, cost 100 x next level from group score, Hall first.
- Admin: rebirth up to 8, item amounts editable in Inventory (/admin/api/setprop).
- Shinobi training crash (dropdown): CPotentialView keeps the cost rows in one list (even = pill, odd = gold) and onClickMode jumps 2 rows
  (1 time <-> 10 times); we sent only 2 rows, so the dropdown read past the list. rl_x_develop Cmd 1 now sends 4 rows (cost_id 3/4 = 10 times,
  rolled 10x in potentialRoll). Verified on the emulator. Training stays free (ours; the 2015 costs are lost, a later version used 1 Super Ninja Pill + 4000 silver).
- Shinobi rebirth goes to 9 (owner's screenshot shows "Shinobi 9 Reincarnation", 1230 pills; newlifeconfig has grades 1-9). The card info lists only 8 bonus lines: that list is the client's own data.

## Server Manager (1 Nov 2026, owner request)
- /manager (manager.js + manager.html), settings in table server_settings (settings.js): events_off (ids from activity_config.lua; game.actXml leaves them out of <conf><items>; stage gift 31 gets timeleft 0), news (shown as the System note in News, rl_r_msg Cmd 1802, dated news_at).
- START-SERVER.bat sets HB_MANAGED=1, opens the manager after 3 s, and loops while node exits with code 3 (Restart button). Stop = exit 0.
- console.log/error are mirrored into a 300-line ring buffer for the live log; settings.hit() tracks uid -> last request for "online now" (5 min).
- In game (Claude emulator): switching the lucky wheel off removed its home button; the announcement shows in News > System.
- TRAP: rl_r_bulletin must keep <id>1</id>. A new bulletin id crashed the client a minute after login (CSystemADMgr::SaveLocalNotice on its
  ADMsg.xml cache, 'this is no node:bulletin', SIGSEGV 0x28). So the announcement does not use the bulletin.

## Sage growth uses the original table (1 Nov 2026)
- The screen shows chances from ninjastrength (rows 1-15 Sage Stone I = prop 7, 16-30 Sage Stone III = prop 8; cols 3-6 = chance with 1-4 stones,
  col 7 = chance to keep the level on a failure, col 8 = lowest level a failure drops to, col 9 = silver). The server used its own 30-100%, so
  growth went up far too fast (owner: 0 to 15 quickly). game.sageGrow now uses the table; max level 15. star_list sends 2 rows per level
  (stone_level = stone id 7/8, stone_added_percent per extra stone, max_percent cap): those numbers are (ours), +1%/+2%, cap = 4x Stone III chance.
- Shinobi rebirth back to max 8: v28 GetTopInlayFrame draws outlines 1-8 only (>8 returns nothing); 9 is from a later game version.
- Admin: sage growth (cards.starlevel, 0-15, shinobi only) can be set when giving cards and edited in Inventory.
- In-game Discord link (hot update 28.0.13): Settings (home icon row > Settings) shows "Join our Discord!", the invite text and a "Join Discord" button (the
  hidden switch-account row) that calls openHyperlink (C++ global) and opens the browser. Verified on the emulator (Chrome opened discord.gg).
- Top banner (the scrolling bar with the horn on the home screen): rl_r_mainpage now ends with <horn><horninfo>TEXT</horninfo><hornflag>1</hornflag></horn>
  (CDefaultMainMenu::onHttpRequestCompleted -> CMainMenu::setHornInfo/InitAnnounceMsg, "|" = gap). Text = settings banner (Server Manager "Top banner"),
  default = the Discord invite. Verified on the emulator: it scrolls and repeats.

## Festival trade event (1 Nov 2026)
- festival.js: event button 44 in the Event menu (conf type 2; type 1 = home column needs a ccbResources path, activityNN frames only work in the Event menu).
  rl_x_small_activity Cmd 9 info (<activity> + ONE <exchange_list> with <exchange> children), 10 shop (<prop_info><prop .../>), 11 ExId trade;
  rl_w_shopbuy Cmd 1700 Goodsid 38/39 Counts=1. Items: Christmas Cap 38 (training + battles), Christmas Tree 39 (spar + Ninja Test).
  Christmas trade list = the original from the photos (FINDINGS.md Holiday events); limits per event run (keyed by switch-on time).
  Result icons: a_type 2 item / 5 fragment (piece id) / 1 card, a_id = a dropinfo id. Verified in game: list, counts, buy window.
- Event switches: settings.events {id: on}; limited events (festivals) start off; festivals share screen 44, so switching one on switches the other off.
- Do NOT switch on events 30 (dailyRestriction) or 39/40 (dailyFirstPay): no activityNN image, would blank the event list.
- FIX top banner piling up (owner screenshot): every <horninfo> adds another label to the top bar (it stays across screens; the old one freezes).
  The horn now goes out once per login, on the first rl_r_mainpage Cmd 1301 (the login call Cmd 1302 ignores it). settings.hornPending is filled by rl_w_login2.
  Verified: three home visits, one clean scrolling line.

## God Recruit (1 Nov 2026)
- godrecruit.js, Event menu id 46 ("luck draw"): rl_x_small_activity 17 info (<basic> + <card_info_list><item id card_id drop_id card_drop_gold
  card_exchange_point/>), 18 spin (<id> slot index, <castCash>), 19 keep (<award>), 20 return (<add_cash><left_cash><left_score>), 21 ChangeId trade
  (<award> + <leftScore>). 300 gold per spin from the photos; line-up of holiday god cards, return gold, energy (20 per return) and trade costs are (ours).
  Verified in game: list, spin + confirm, win window, return (120 gold, energy 20), exchange window.

## Hot Treasure (1 Nov 2026)
- hottreasure.js, Event menu id 43 ("treasure"): rl_x_small_activity 12 info (<remain_time><one_cost><ten_cost><main><item/></main><second>items</second>
  <all>items</all><left_free_count>; item = drop_id/desc/main_type/sub_type/prop_id children), 13 one hunt (<cash><left_free_count><award>),
  14 ten hunts (<cash><award_list> of <award dropid>). Prices, prizes and chances (ours). Verified in game: screen and ten hunts.

## Gold spending event (1 Nov 2026)
- consumption.js, Event menu id 37 ("Consume"): rl_r_comm Cmd 13 (<basic><cash><remain></basic><award><item id cash status drop1-4 name1-4 icon1-4/></award>),
  rl_w_comm Cmd 18 ID claim. Tiers/rewards ORIGINAL from photo 0347; lowest tier gold 3000 (ours). Gold spent = trigger gold_spent_log on players.gold
  (every decrease is logged; the event counts from its switch-on time). Verified in game: tiers, icons, claim buttons.

## No-energy pop-up (1 Nov 2026)
- The client checks energy itself and opens a ramen "Purchase item" window (CommonBuyItemDialog, items 3/4). It crashed (line 88, nil item) because
  the client only knew items after opening the shop: rl_r_shoplist Cmd 1600 (login) is ALSO parsed for <goods> (CTradeMgr: LoadGiftPackInfo then
  LoadConsumInfo), so 1600 now carries the goods list. The server also refuses a training fight without energy with code 40004 (= the client opens
  its ramen window). Verified in game: GO with 2 energy -> ramen window -> Use -> energy 203.

## Control panel + team editor (1 Nov 2026)
- panel.html at / /admin /manager (admin.panel(res, start)); pages embedded with ?embed=1 (html.embed hides their header/backdrop); tabs via postMessage.
  Pages are sent with Cache-Control no-store (an old cached admin.html was served inside the panel once).
- Team editor: GET /admin/api/team?uid (slots, owned cards by type, power), POST /admin/api/setteam {uid, slots:[{ninja:{seq}|{give}, level, newlife,
  growth, equip:{kind:{seq}|{give}, level, newlife}}]} in one transaction (rolls back on a duplicate or a gear piece of the wrong slot). Capped at maxTeam.

## Card stats = the game formula (1 Nov 2026)
- game.ninjaStats now copies CPlayerNinja::firefly_GetAttackMin + CNinjaDetailView::InitUI: base = (1+basis)*lv1 + (1+grow)*perlevel*(lv-1)
  (newlifeprop row with m_newlife_times = rebirth grade: basis col 4, grow col 5), growth bonus = (min+max)/2 * ninjastrengthconfig[growth] added to min
  and max, + training points. Old guess was +5%/growth level and +10%/rebirth (far too low at high levels). Checked on Susa Indra lv50 R8 G15:
  detail screen 6663-8336 +12092 = server 18755-20428 exactly. equipStats: equipnewlifeprop matched by col 3 (grade), rounded down like the client.

## Diligence gift, limited discount, lottery (1 Nov 2026)
- limited.js. Diligence (id 33): rl_r_multiple_task 1/2 (<tasks><task id desc done current_recv total_recv can_recv><item id icon name/></task></tasks><remain>),
  counters = dailytask. Discount (id 27): rl_r_activity 9004 (<preview mincash resttime maxval/><award state><item drop icon name/></award>), claim rl_w_activity
  9100 ActType 10; gold topped up is logged in topup_log (rl_x_free_topup, rl_w_ky_payorder). Its activity_config entry was a home-button script call
  ("Get data from file(GetMainMenu():ChangeToActivity(...).lua) failed" = empty page): fixed in 28.0.16. Lottery (id 22): rl_r_lottery 1/2/3, rl_w_lottery
  1 No / 2 claim; draw 20:30 server time, prize = digits in place (3+/2/1), from the game texts. All numbers (ours). Verified in game: all 3 screens.
- Chains (GitHub #5 again): the partner id lists in ninjamatch miss whole variants (Six Paths Madara (God) "Fight with Six Paths Obito" lists only
  Uchiha Obito 4/156; Hokage Naruto "Fight with Madara" misses Six Paths Madara). teamStats now ALSO matches the name in the chain text: every word
  of "Fight with X" (minus of/the/and, plural s, bracket tags) must be in the card name. Verified: 7 reported/control pairs, and in game the
  Six Paths Madara (God) + Six Paths Obito (God) team now counts the chain (G 3/6).
- Chains, all of them: audited every "Fight with" row (1223 rows, 238 partner names). Names are split into parts: "X and Y" / "X, Y" need all
  parts in the team, "X or Y" one. Typos/other names aliased (Kyubi = Kurama, Eight Tails = Gyuki, Forth, Fukasakun, Sasu Sasuke, Raikagand,
  Itachiand, "Mei Tsunade Onoki", "Fourth Sage Minato"). Every part now matches at least one card by name; a part that would match none falls back
  to the listed ids. NOTE: "and" chains were "any partner" before; now all partners are needed (as the text says).
- Fight cards before the hit: CNewFightCardView::InitUI shows round Attack (attacker) / Defense (defender) and counts down by the damage, then
  SetFinalData. We sent Defense 0 -> enemies showed 0 before any hit. Now Defense = the enemy defence (FinalAttack stays >= defence+1).
  Verified in game (Battles): enemies show 523/482/523, count to 0 on the hit, no crash.
- Admin "Unlock everything" (game.unlockAll): level = last playerlevel row (350), all 19 chapters cleared (stage_clears + progress),
  Battles 3x6 cleared, energy full; team slots follow (newcardinfo has 26 rows, the last at level 350). Verified in game: slots open.
- Battles (rl_w_dup) enemies + reward from towerfloor ([2] chapter, 7 rows per chapter in id order, [4..8] the 5 enemies, [20] exp, [21] silver);
  before it was always the same 3 placeholder enemies (owner screenshot). npc level = 10 x chapter + round (ours). Verified in game (Kidomaru + 4 Amegakure).
- Chain text also reads "Fight X +" and "Fight together with X to raise" (50 rows never matched: Six Paths Sasuke (God) etc.). Helpers at module level
  (game.chainPartsOf/chainFits/chainKnown) for the admin.
- Admin team builder "Complete chains" (/admin/api/chainplan -> plan + list, then setteam): for the ninjas already in the team, missing partners
  join free slots (own card first, else the highest-star card with that name, new at level 50) and "Equip X" gear/ninjutsu is put on the ninja.
  Added partners do not pull in their own partners (press again for that). Panel iframes load with ?v=<time> (no stale cached page).
- Team builder gear calculator (/admin/api/gearplan mode owned|best -> plan + list, then setteam): per team ninja the weapon/armor/trinket/seal
  with the highest total stats (same math as teamStats; best = level 50, equipment rebirth 3), 4 different ninjutsu by power (ninjutsuinfo col 10,
  our stat model gives every ninjutsu the same boost). Gear a chain of that ninja asks for is kept/chosen first. Owned mode only uses free cards.
- Set bonuses (suit_info, "Shinobi colour card" / "Shinobi Growth Cards"): type 2 counted card LEVEL (every lv 50 card counted) instead of growth
  (cards.starlevel); per type the set with the most cards won, so 21 four-star beat 21 five-star/six-star. Now the biggest bonus wins.
  Owner save: 21 Six-Star Cards + 21 Twelve-Level Cards. Not checked on screen.

## Fights = the original rule (owner video youtu.be/8AFcM2mFGMs 1:42, 1 Nov 2026)
- Only my side attacks. My ninja hits the first standing enemy; the enemy defence is taken off its attack; attack left -> same ninja hits the next
  enemy; defence left -> next ninja of mine continues against that enemy. Win = all enemy defence used up. Video: 291(+72 skill)=363 vs 140(+20)=160
  -> 203 left, vs 125 -> 78; victory screen "total attack 671 vs total defence 285". game.battleXml play(): one roll per my ninja; enemy defence
  scaled so the replay ends the way the server decided. Verified in game: a lost spar (attack < defence rounds) plays out and shows Lose, no crash.
  Not built yet: ninjutsu "skill damage increase" pop-ups (FinalAttack > Attack with <skills>).

## Account picker (1 Nov 2026, owner request)
- The login screen region list (xk_r_dir serverlist) now has 4 entries: 1 "Konoha (main)", 2-4 "Starter slot 1-3". Every save is keyed by
  (uid, server_id), so one login can hold a main and up to 3 starters; each slot is its own world (rankings, guilds, friends per server).
  Verified in game: the list shows, Starter slot 1 + START opens a new character (nation choice).
- Admin/control panel: players are keyed "uid:server_id" (findPlayer); the list says "starter slot N"; Reset only deletes that slot.

## Enemy strength curve (1 Nov 2026, owner request)
- Enemy npc rows have no stats in the client data (originals lived on the dead server). Now: enemy TEAM defence grows by the same factor every
  story stage from 285 at stage 1-2 (owner video: Mizuki 140 + 125, "total defence 285") to 2 500 000 at the last stage of chapter 19 (owner
  choice). First enemy x1.12. Battles: 175 rounds on the same 285..2.5M curve; a Battles round can now be LOST (attack x 0.85-1.15 < defence).
  Training win check = my total attack vs their total defence. Ninja Test guards: 1150 at stage 1, 1950 at stage 2 (photos), +800 a stage.
  Values: 1-2 285, 2-1 481, 5-1 2.5k, 10-1 38k, 15-1 289k, 19-1 1.33M, 19-87 2.5M. Verified in game: Battles 3-5 shows 159/142.
- Recruit "1 in 100": the orders count stayed at 39 until the shop was reopened. CItemView subtracts <recruit costprop> from item 30; we sent 0.
  pullXml now sends costprop=1 for type 3. Verified in game: 39 -> 38 right after a recruit.
- docs/PROGRESS.md = one page with every bug-list item + owner request and its status; control panel Progress tab renders it (/progress.md).
- Fight ninjutsu: round <skills><skill><cardid>NINJUTSU ID</cardid><chakraattack>damage</chakraattack><chakra>part from chakra</chakra></skill></skills>
  (max 2 per round, CFightResultData::AddFightRoundData). Attack = before, FinalAttack = after the skill. cardid is the ninjutsuinfo id (a card seq
  showed another name). Damage = m_attackvalue (col 10) + m_attackvalue_up (col 18) x (level-1) + 20% of avg chakra (ours; video: 40 + 32 = 72).
  Fires per worn ninjutsu with m_rate (col 4, 15%) when a ninja starts attacking; not in fights the server decided to lose. HB_SKILLS=1 forces it.
  Verified in game: Chibaku Tensei pop-up "Skill damage increase 2086 (Chakra 1306)", Skill bonus, animation. Enemy defense skills not sent.
- Team builder Benchmark (/admin/api/bench {uid, targets}): 300 simulated fights per enemy team defence with the battleXml rule (attack rolled
  low..high per ninja, worn ninjutsu by m_rate, attack spent in team order); win %, ninjas used, story stage with that defence (game.stageForDefence).
- Fights ignored team-wide bonuses (sets, Eight Gates, pets: only in teamStats.total). teamStats.fight = each slot scaled by total/sum per stat;
  battleXml, the benchmark, the training and Battles win checks use it / the total. Owner save: slots 6.0M-6.3M -> fight 7.67M-8.09M = Team screen.
- Spar Benchmark rivals (settings switch "bench", off by default, noconf so it is not an event button): ids 8000001-6, 100K..8M defence over
  5 enemies (spreadFoes), free (no grudge), no reward, battleXml opt.real = no outcome scaling, the replay decides. Verified in game (100K).
- Victory/Lose screen "ATK / DEF" = sum of <ninja><end> of each side (video 671 / 285). end was an old HP model (enemies def x4, mine (dl+dh)x2+300)
  -> Benchmark 4M showed DEF 16M. Now mine.end = avg attack, foes end = final defence. Verified in game: Benchmark 1M shows DEF 1,000,002.
- Login toast "INTERSTITIAL 'Leaderboard' REQUEST FAILED - NETWORK_FAILURE" = Chartboost SDK in classes.dex (com/chartboost/sdk). Only an APK
  patch can silence it; owner chose to leave it (1 Nov). Do it together with the next APK change.
- Loading screen ("Loading for you, Master"), 1 Nov: measured every request (server log now shows ms and KB per request). Every handler
  answers in 0-30 ms. Training and Team make NO server request: that wait is the phone loading the screen's images (client only).
  Home makes 8 small requests. rl_r_mainpage Cmd 1301 (every return to Home, level-up, store) sent the whole card list + chip bag
  (183 KB on the owner's save) although its callers (CDefaultMainMenu, CPlayerLevelUp, CStoreItemsView) only read <user>/team/horn:
  now only Cmd 1302 (login, CLoadInitInfoScene builds the card bag) sends them (1301 = 21 KB). Checked in game: Backpack/Team still full.
- Team screen name overflow: names are a CCLabelTTF in sub_ui/TeamNinjaView.ccbi (Arial-BoldMT 24, no width). 28.0.17 patches it
  (font 18, width 28% = name bar, centred): 21-letter names fit on one line, longer (up to 29 owned) wrap to 2 lines. Checked in game.
  Backpack list (another ccbi) still overlaps the element icon for long names: not changed yet.
- "So lucky !" pop-up (CDialogShowBox, dlg_ui/RunLevelDrop.ccbi, shown on a random lucky roll after a normal story stage): button picture
  said "Fold" and the game drew its own title ("Proceed", Helvetica 12, white) on top. 28.0.18 repaints the picture to "Proceed" and sets
  the title size to 1 (tools/patch_runlevel_drop.py). Sprite sheets *.pvr.ccz are 'CCZp' = cocos2d-x encrypted CCZ; key
  0xf013c6ef 0x5ca560ce 0x01471215 0xca9bada1 (ccSetPvrEncryptionKey call at 0x265b96); tools/pvrccz.py topng/frompng. Not seen in game
  after the change (the lucky roll didn't come up in 7 tries); file checks pass.
- Save time (rl_r_savetime) paid 500 x player level exp AND silver (level 60 = 30 000 each, even in chapter 1), used ramen id 3 and gave 99
  free ramen. The screen's item is BIG_ENERGY_ITEM_ID = 4 (Lua constant set in libgame.so at 0x3e4964, 4.0) = Large ramen, 200 energy.
  Now: one Large ramen = what 200 energy earns fighting the player's current story stage (roundinfo [22] cost, [23] exp, [24] silver)
  (ours); chapter 1-1 = 396 exp / 990 silver, chapter 19 end = 4 860 / 5 760. No free ramen. Chapter/round = furthest story stage.
- 28.0.18 broke the "So lucky" pop-up: every drop showed a dark purple box (I mistook that for a different pop-up while testing). The
  re-encoded .pvr.ccz is wrong somewhere (decoding is right: the original decodes to a clean picture). 28.0.19 ships the original files
  back; owner chose to keep "Fold". Verified in game: So lucky + Fold show again.
- 2 Nov, from the Facebook photos (G:/HELLO BRO/Pictures/FINDINGS.md, batches 7, 40, 80 read):
  * Save time now = the original screen (photo 2212: chapter 11-6 -> Exp 3200 / Silver 3800, VIP1 and Lv.80 needed, "VIP1 +2/day",
    "Gain 10Gold"): ceil(200 / stage energy) fights of the furthest story stage, rounded down to hundreds (matches the photo exactly);
    chances a day 2 x VIP (ours), then 10 gold an exchange. Table `savetime` (day counter).
  * A level-up now also refills grudge (sp = -1 = full), like the original "LEVEL UP!" pop-up "Energy ↑ Grudge ↑" (photo 2156).
  * Checked as already right: reincarnation pill costs (newlifeconfig, photo note "God 100/180/350/510/720/850/1030/1130"),
    ninjutsu values at lv1/lv50 (ninjutsuinfo), secret shop 75 + 5 x VIP refreshes, arena rank rewards to rank 10.
  * Ninja Test guards now follow the photos: value = 0.00705 x stage^1.1 x player level^2 (min 50). Fits level 61 / stage 14 = 480,
    level 281 / stage 14 = 10 062, level 302 / stage 4 = 2979 (photos 2553, 2448, 1811) within 1%. Old rule (1150 + 800 a stage) was the same
    for every level, too hard for low levels. Bosses at 5/10/15 +30% stays (ours).
  * Growth Fund built (growthfund.js, Event menu id 19, rl_x_small_activity Cmd 1 info / 2 buy / 3 Id claim; preview attrs buycash multiple
    totalcash buystate needvip [cash], fundlist items id level cash state 0/1/2). Original numbers from photo 2627 (500 gold, x5 = 2500, VIP3,
    Lv50 150 / Lv70 150 / Lv90 200); Lv110-230 steps (ours) add up to 2500. Server Manager switch "Growth Fund". Checked in game (buy, collect).
  * Ninja Test refit with a 5th photo (2678: level 272, stage 1 = ~1175, which the level^2 formula got wrong): guard = stage value
    (1160 / 1950 / 2980 / 10 065 at stages 1 / 2 / 4 / 14, lines between, +708 after) x min(1, (level/280)^2). All 5 photos within 7%.
  * Arena daily rank reward = the photos: 26 000 - 1000 x rank (ranks 1-10), then -60 a rank (ours) to a 2000 floor; reputation = silver / 5
    (photos 0211, 1901, 2119, 0389, 2719). Was 6000 - 100 x rank in the list and 50 000 - 1000 x rank when claimed (two different rules);
    now one function game.arenaReward used by both.
  * Ninja Treasure (sudoku.js) = photos 0018, 0150, 1070-1073, 2816, 2819, 2833: refresh 100 gold, auto reroll every 2 h, explore
    35 / 70 / 300 / 320 / 1000 by prizes taken (0-4), 1000 after (ours). Was 20 gold, 4 h, 10 + 10 x taken.
  * Secret shop Refresh (rl_x_mystery_shop Cmd 2) did nothing before. Now: Refresh Order (prop 31) or 20 gold, 75 + 5 x VIP a day
    (code 325006 when used up), goods change every 2 h by themselves; table secret_state (day, used, seed); bought rows per board.
    Checked in game.
  * Shop: Reincarnation Pill 120 gold and Development Dan 120 gold like the original shop photos (consumeinfo says 180 / 200);
    game.SHOP_GOLD overrides both the list (rl_r_shoplist prop_yuanbao) and the price paid.
  * Change country (switchCountry.lua): rl_r_migrate_price -> <price>300</price> (photo 3270); rl_w_propuse Cmd 1802 with ToCountry
    takes 1 Immigration Card (prop 18) + 300 gold and sets players.country. Not checked in game yet.
- Database (2 Nov): kept SQLite (one file, no install, fine for dozens of players; Node is single-threaded so a DB server would not
  add speed). New db.js: WAL mode + synchronous NORMAL + busy_timeout, PRAGMA quick_check on start (Server Manager tile "Save health"),
  backup with VACUUM INTO on start and every 6 h while running (backups/hellobro-start|auto-*.db, newest 10 kept; manual-* never
  deleted). The old start backup copied the .db file before opening, which could miss data left in a -wal file. Extra indexes
  (pets, mail, war_log, equipped.seq, team.seq, accounts.session) + PRAGMA optimize. hellobro.db-wal / -shm are git-ignored.
  * Daily task chests = original 250-point bar (photos 0175, 1328): chests 30/60/90 (ours), 120/160/210/250; the 250 chest pays the
    original 30 000 silver + 100 gold + 10 Reincarnation Pills + Killer B fragment (drops 226, 260, 108, 1166). Tasks now also counted:
    3 seals, 7 refine, 8 world boss, 10 war, 11 border clear, 12 shinobi training, 13 recharge, 14 1-in-10000 recruit, 19 arena reputation,
    21 reincarnation (before only 1,2,4,5,6,17,18,20 = max 95 points). Checked in game (10/250 bar, 7 chests).
  * Shinobi training costs like the original (photos 1835-1840, 1347): 2 Super Ninja Pills, or 1 pill + 10 gold; 10 times = 20 pills
    or 10 + 80 gold (ours). Was free. Checked in game (screen shows the costs, pills taken).
  * Eight Gates rebuilt with levels (ui_limitTrainLayer.lua: gate_level = LV, gate_id = next point 1-8, *_per in TENTHS of a percent:
    we sent 2 for 2% = shown 0.2%). prop 9997 = points opened, 8 a level, cap LV150. Cost a point = 80 x LV souls + 15x silver
    (photo 2171 LV1 = 80 + 1200 exact). Bonus after n points (x = n/8): flat 340 x^1.5, percent 0.006 x^2 + 0.2 x (fits LV10-LV100
    photo totals within ~5%). Old saves keep their 0-8 points (now LV1-2 with a smaller bonus than the old flat 120/2% a point).
    Checked in game (LV:1 -> LV:2, costs, totals).
  * Scratch card built (scratch.js, rl_w_guaguale Cmd 1700 <root free usercash>, 1701 <root usercash><win cash/><cards><card><id/><cash/>
    <icon/></card>x9</cards>; Event menu id 7 "Lottery", Server Manager switch). Prizes 5-800 gold from the photos; odds (ours) average
    20 gold back per 20-gold card; 1 free card a day (ours); faces = icon_<ninjainfo[3]>. Counts daily task 9. Checked in game.
  * Treasure chests built (box.js, Event menu id 16 boxOpenActivityView.lua, rl_w_propuse Cmd 1804 info / 1803 Goodsid open; table boxopen).
    Prize lists = boxOpenInfoData.lua (original), weights/key gold prices/opens a day (25 + 5 x VIP) ours; "Double the reward" sets
    the chest's double flag (next prize x2). Keys 22/23/24: 8% bronze key on normal story wins, 8% silver key on boss wins (ours).
    Counts daily task 15 (gold chest). Checked in game (gold + bronze chest rewards shown).
  * Limited group purchase built (groupbuy.js, Event menu id 13, rl_r_comm Cmd 4 list <preview resttime/><itemlist><item><id/><cost/>
    <origincost/><restnum/><awardlist><award><name/><icon/><dropid/><newlife/></award></awardlist></item>; rl_w_comm Cmd 8 LimitPackID buy
    -> <preview restnum/><award>). Stock shared per server, 50 a pack a run of 72 h (Server Manager switch "Limited group purchase", off by
    default). Packs/prices from the photos; pet packs left out (icon is always loaded from props/<icon>.plist). Checked in game.
  * Succession (ui_ninjaInheritLayer: rl_r_comm Cmd 9 SrcCardIndex info, rl_w_comm Cmd 13 Src/DstCardIndex) answered on the server
    (game.inherit: level, exp, growth, rebirth, training points move to the other card of the same quality; source back to level 1;
    price 50 + 50 a rebirth + 50 per 3 growth (ours)). NOT checked in game: the v28 Backpack card screen shows no Succession button
    (CMyBackpackCardView::ninjaInheritClick exists but its button is not on the card view we see).

## 2 Nov 2026 (later): small events
  * Great gift for total recharge (Event menu id 11, rl_r_pay_cumula + rl_w_activity ActType 6): totalgift.js. Checked in game: list, Claimed
    stamp, rewards (rebirth 2 / 7 cards). Card icons in this cell come from props/<icon>.plist, which has no ninja icons, but sending the
    icon/ frame name (icon_npc42_6, small_weapon_033) works because rl_get_iconsprite has just loaded that sheet into the frame cache.
  * topup_log has a new `cents` column (price of the package) so events can count dollars like the original.
  * Time limited GiftPack (id 27): switched to the photo's $19 / $60 / 70 h and rewards. Checked in game.
  * Daily spending gift (id 25, rl_w_dailycost) and recharge streak (id 26, rl_r_activity 9003 / rl_w_activity ActType 9): dailyevents.js,
    checked in game. Long item names overlap in these cells, so only the amount is shown under each icon.
  * NOT possible in v28: limited daily gift (id 30, rl_r_dailylimit): activity/DailyRestrictionCell.ccbi lacks label_item_name*, node_icon_*,
    label_remain_amount, label_price, btn_buy, so ui_dailyRestrictionCell.lua:47 crashes (seen in game). Card split (rl_w_split_card):
    ShowSplitDlg is never called. Recharge rebate wheel (id 31/32, rl_r_multiple_pay): only multiplies real-money top-ups.
  * rl_r_marquee answers an empty <marquee/> (ui_borderWarTip reads its children). Every rl_x_small_activity Cmd a Lua screen sends is handled.
  * mergeAwards now sums <soul> (it always sent 0, so souls vanished from combined reward pop-ups; the souls were still given).

  * 28.0.20: ui_sevenDayView.lua shows the server's <message> when a 7-day Claim fails ("finish all goals first"); checked in game.
  * Checked in game (test save): shop prices 120 (Reincarnation Pill, Development Dan), Immigration Card -> Change country 300 gold
    (card used, country changed), Ninja Treasure refresh 100 / explore 35 / 2 h board.
  * Shop quirk (not fixed): after rl_w_shopbuy the Tool tab keeps the old count and USE stays grey until the next login, although
    CItemView::onHttpRequestCompleted adds <retobj count> to CTradeMgr's ConsumeInfo bagnum (retobj layout type/costyb/costyz/id/count
    matches) and the tab re-requests rl_r_shoplist 1601 (which sends the new bagnum). Using an item updates the count at once.

## 2 Nov 2026 (later): photo rows compared
  * All "check / compare" rows of FINDINGS-PHOTOS.md now say what was done (both copies). Changed: war.js rewards, guild.js (levels, costs,
    members 6 + level, donations incl. rl_r_group_contri Cmd 3 card list / Cmd 4 card donation, mall rl_r_group_store Cmd 1 / 2), signin.js
    (original table, status 2 = sign again after VIP-up, monthsign.copies), top-up packages + first top-up x3 (rl_r_paypack first_pay),
    $49 gift drops 1312 / 122 / 558 (28.0.21 lets ui_purchaseLayer load icon/ pictures), spar EXP / W.A., Element Change
    (rl_w_newlife Cmd 5 price / Cmd 6 change; reply needs attack_tupo / defence_tupo / cha_tupo), god evolve 100 Development Dan
    (rl_r_comm Cmd 20 / 8 report the real count), equipment advance 50 000 silver, small bags 2000 silver, gold chest opens from vipinfo[24].
  * Checked in game: top-up screen + $49 gift claim, monthly sign-in (VIP x2 paid 20 000). Not yet in game: Akatsuki, war, spar, element, evolve.
  * Open: recruit gold prizes (Gold*210 / 500 / 1000 / 2000 from the 300-gold recruit) need the recruit result screen researched;
    border war daily rewards; five-element camp bonus panel.

## 2 Nov 2026 (later): real login
  * The Uin/Session came from the Gumptech SDK in classes.dex (com.gumptech.sdk), which talked to http://api.gumptech.com (still online):
    POST /quick/login.do (deviceId, appId 10015, passwd = phone-kept secret), /quick/reg.do, /gump/login.do + /gump/reg.do (email, passwd).
    Answer JSON read by com.gumptech.sdk.d.a: code 100000 OK, nick, userId (= game Uin), sessionKey (= game Session); 100010 bad
    password, 100011 name taken, 100012 no such user. The game then sends Uin/Session to rl_w_login2.
  * release/classes-revival.dex: com/gumptech/sdk/c/a/b.smali now takes its base address from assets/baseconfig.json server.url
    (tools/patch_login_smali.py, built with apktool 2.10.0). make_game_for.py puts it in every game file.
  * gumplogin.js answers those .do paths (server.js routes *.do); table logins (guest by deviceId, named by email; scrypt hashes).
    A phone the server does not know yet is asked at api.gumptech.com once, so players keep their old account number.
  * LOGIN_LOCK=1 (START-PUBLIC-SERVER.bat): rl_w_login2 and every request need the session the login handed out; unknown uids are not
    auto-created. Checked in game: guest login keeps 22080033, relaunch logs in by itself, Signup names the same account, fake session refused.
  * START-PUBLIC-SERVER.bat: DB=public.db, HB_BACKUPS=backups-public, LOGIN_LOCK, STRICT_SESSIONS, ADMIN_PASSWORD from admin-password.txt.

## 2 Nov 2026 (evening): checked in game while the owner was away
  * Akatsuki: mall (needed item_index per item), buildings upgrade (costs, Lv shown on the map from the real levels), worship incl.
    card donations (Cmd 4 must answer <item_list> again, else ui_orgDonateEquipLayer.lua:257 errors), Hall shows the Hall bonus.
  * errcodes.js: the client shows Struct_String_Menu text for the reply code; code 5 = "Your energy level is full". Code-5 replies
    are re-coded by their message (10006 gold, 10008 silver, 170007 claimed, 312000 event over, 277 materials, 166 not open, 8000 other).
  * Fights: game.foeTeam gives 3 different enemy ninjas (a real player's own team; bots seeded by id). War guard gets random ninjas.
  * War win checked: EXP +36, silver +36, W.A. 10 shown like photo 2315.
  * Element Change checked (12 pills + 2000 silver, Water -> Fire). Cards with attri 0 are sent as 1 (the screen showed "nil").
    Element Change Pill is not for sale (photos); shopBuy refuses items without a price.
  * God evolve checked (100 Development Dan); the new card keeps the best rebirth / growth (the screen says so).
  * Spar now uses the game's duelinfo table by RIVAL level (exactly what CFightPreView shows): win/lose EXP [5]/[6], W.A. [7]/[8],
    silver = rival silver x [3] on a win, your silver x [4] lost on a loss. Result screen shows W.A.; it shows silver 0 although the
    silver is given (+568 seen in the save) - not found yet which field that label reads.
  * FIXED a login crash I caused: an inline // comment in game.js cardXml cut off starlevel/newlife/... (every card). smoke.js now checks
    that every card of rl_r_mainpage 1302 has type/id/seq/level/attri/starlevel/newlife.
  * Second-device login checked in game: pm clear (= new phone) -> Login with Gumptech name + password -> same account; relaunch logs in
    by itself. Note: after a fresh install the region list starts on the LAST region ("Starter slot 3", empty -> character creation).
  * Border war rewards (border.js) checked in game: Get Award screen like photo 0666 (counters 0/2, 1/2, 0/4, 0/4; "Wandered 1 time(s)
    3300 / 786"), monument HP 300/300 like photo 0540. Claim without items sends no <award> (else an empty "Sample Text" card pops up).
  * 300-gold recruit gold prizes: coded (drop rows 137/290/295/298) but OFF: the single-recruit reveal shows a blank card; the gold is given.
  * Five-element panel (photo 2666, "Shinobi attack increase: %.2f%%" = Struct_String_Menu 300-303): no server data found; not built.
  * Fight "Restrain: 0": the element restrain table (ninjafiveprop, +15% vs the weak element) is not used in our fights yet.


## 2 Nov 2026 (night): balance simulations
  * tools/dev/sim_balance.js -> docs/BALANCE-SIMULATIONS.md (+ .json). Nothing applied; the report lists what I would change (owner decides).
  * Owner decided: keep the balance as is (last boss 2.5M, recruit rates, EXP) - let it play out.
  * Player log (playerlog.js): table player_log; hooks in game.addExp (level), game.setStage (stage + chapter, chap<1000), vip.addExp,
    rl_r_mainpage (login day + team attack when it moved 2 %+). Page /admin/playerlog, panel tab "Player log". Also: addExp no longer goes past 350.

## 1 Nov 2026: element restrain in fights
  * game.battleXml: every round sends AttackAttri / DefenseAttri (my card attri, 0 = water) and CauseLimit / LimitVal. CFightResultData::
    firefly_CalcAttackVal sums round LimitVal (+0x44) into "my restrain" (field 0xd4) when CauseLimit (+0x40) = -1 and into "enemy restrain"
    (0xd8) when it is 1; CNewResultWinView/FailView show them as label_myRestrain / label_enemyRestrain.
  * ninjafiveprop: my element beats theirs -> CauseLimit -1, FinalAttack = attack + 15 %; theirs beats mine -> CauseLimit 1, FinalDefense + 15 %.
    NPC enemies get a fixed element from their id (ours: no element in the data). ninjaXml now sends the real attri in <guard>/<killer>.
  * The win/lose decision is unchanged (owner keeps the balance): if restrain would flip the replay, enemy defence is nudged until it ends
    the decided way (300 test fights: 0 mismatches). Skills are rolled once per ninja now (same chances). NOT checked in game yet.
  * Cross-server battle researched, parked by the owner: it opens from CDefaultSLGMenu::ClickNinja (Base); util/common.lua sends it to a
    fixed MULTI_BATTLE_CGI_IP 23.91.96.227:8080 (patch to CServerListMgr:instance():GetServerConfig().m_url). Endpoints: rl_r_cross_war
    (warlefttime/curwarid/status 1 ticket, 2 fighting, 3 over; <user> + <positionlist> of 20 posts; leftTime must be > 0 or the screen
    reopens itself in a loop), rl_w_cwar Cmd 1 ticket 500 / 2 inspire 200 (+10 %, 300 s) / 3 exchange ExchId (myscore_left + award) / 4 top-10
    award, rl_w_cwar_war Cmd 1 Pos (ShowArenaView fight + <newlist><user/><positionlist/>), rl_r_crosswar_rank Cmd 1-4 (<player> first,
    rank_list rows col0-col4 attributes, score_package id/icon/cost/desc, topten_award id/rank/desc). rl_w_cross_war Cmd 2 is unused.
  * Checked in game (dev server, 1 Nov): spar vs Riskeric showed element icons on all cards and "Restrain: 101" on the win screen.
  * FIXED: foeTeam / sparFight tested `uid < 9000000` for a real player, but real uids are 22 000 000+, so every real rival fought as a bot
    (made-up team and strength, bot silver). Now: real = has a players row. Spar vs Ninja78277 showed his real team and a fair loss.
    battleXml takes opt.enemyCountry (preview defensecountry was always 1 = "Land of Thunder"): spar, arena, war pass the rival's country.
  * Dev setup: dev server on PORT 18081 (tools/dev/restart.sh), Claude emulator runs release/HelloBro-for-127.0.0.1-18081.apk and reaches
    it through `adb reverse tcp:18081 tcp:18081` (emu.sh restart sets it; the firewall only lets 18080 in). Test login in tools/dev/emu.account
    (git-ignored), dev account 55501235.
  * Checked in game (dev server): team slots open at level 1/2/6/15, level 30 stops at 4 with "Lv. 30 and customs clearance 1 Round 12";
    a $4.99 top-up shows VIP1 at once (top bar + top-up screen 50/100, $49 bar 5/49); Ninja Test stage 5 chests free / 160 / 250 gold
    (gold 725 -> 315), then Challenge sends Cmd 7 and stage 6 opens.
  * exam.js guard element came from ninjainfo [5], which is an index, not an element (values 0-163, so the screen showed Water): now
    game.foeAttri like the fights. tools/dev/dev.js: admin-API shortcuts + `sql` on the dev save + `relog`.
  * Spar list (rivalsXml) sent coin = 100 + level x 20 for everyone, but the preview silver is that coin x duelinfo [3] and sparFight now pays
    from a real rival's real silver: real rivals now send their real coin (Riskeric 21 500 -> "Silver: 215", paid 215: checked in game).
  * Spar WIN screen still shows silver 0 although <award><coin>215</coin> is sent and paid. Ruled out: CFightPreView::onHttpRequestCompleted
    (InitFromXML on the root, SetFightType 6, AddDataFromReward), AddRewardData (coin -> this+0x38 = reward+4, no early exit), InitUI round
    layer (label_round_getsilver = reward+4, only write), setIntegerVal (plain "+%d"). EXP / W.A. on that screen also equal the preview values,
    so the screen may be built from another CFightResultData than the one parsed. Left as is (silver is paid; loss screen shows it).
  * Recruit gold prizes researched further (still OFF): CCommonPrayDialogView single recruit always opens CDialogShowBox with SetShowType(1) /
    SetCurrShowType(1) / SetForJieYin(true). CDialogShowBox::InitUI switches on the current show type (box+0x1b0): 1 ninja card, 4 gold (needs
    cash >= CConfigMgr value 0xce, label "%s*%d" with props_037), 2 / 8 / 0x20 other kinds. So the single reveal can only draw a card (blank 5-star
    "Sample Text" card seen in game with HB_GOLD=137). The 10-pull (CPrayTenDialogView) lists "Gold*210" with a "?" ninja picture, and tapping it
    opens a placeholder tip "ddddd...". The photos 2339-2348 show the plain Rewards card (show type 4), from a screen not identified.
  * Checked in game (dev server): Save time 1-1 = 400 EXP / 1000 silver (one Big Ramen, chances 2 -> 1); arena reward amounts (rank 1
    25 000 / 5000, rank 16 15 640 / 3128); level-up refills grudge 1/3 -> 3/3; a story stage at full energy shows no ramen window; equipment
    advance (ui_equipListLayer only lists 5-star, level 50, grade < 3, not in a team) 50 000 silver, Blood Kunai 125 -> 187.
  * Arena teammates: CArenaListView::AddOpponentData reads <teammate><mate><ninja/><firstninjastar/></mate>... (was empty -> purple slots).
    game.teammateXml sends the same cards the fight shows (foeTeam: real team slots / bot partners). Compete list = mates after <ninja>;
    the Rank tab (<sportrank><item>) fills all slots from the list, so it gets the first ninja too (withFirst). Checked in game.
  * Fresh install picked "Starter slot 3": CServerListMgr::GetRecommendServer takes the first cached (recently played) server, else the
    server whose para1 (ServerInfoData +0x14) equals baseconfig.json "Recommend" (1000 in every game file), else the highest id. Konoha
    now sends para1 1000 (others 1062; the server never reads Pt). Checked: pm clear on the emulator -> the start screen shows Konoha (main).
  * Brand-new account checked in game (guest 55501236, Shikamaru): Lv 1, 50 gold, 18 000 silver, VIP 0 (original); energy starts at 50 over
    a level-1 max of 10 (schema default, ours; original unknown). 1-1 clears fine. FIRST BOSS 1-2 LOST: starter attack 263 (198-329) vs the
    stage-1-2 anchor 285 (owner video). handlers rl_w_pve decides by average attack x 0.85-1.15 -> 23 % win, 45 % stuck after 3 tries on
    day 1. If the replay decided (attack roll + ninjutsu + element, battleXml real mode, like the original fight) it would be 55 % / 9 %.
    Asked the owner (balance decision); nothing changed.
  * Shop Tool tab count re-checked with the reply log: after rl_w_shopbuy (retobj type 2 id 1 count 1) the client does NOT re-request
    rl_r_shoplist (older note was wrong). CItemView buy branch: LoadTradeInfo -> GetRetObj {type, costyb, costyz, id, count} -> AddGold(-cost)
    (gold label updates) -> GetConsumByID(id) (match on ConsumeInfo first field) -> bagnum += count -> SetConsumByID -> member callback +
    InitHeader. All of that matches, so the stale label is the cell redraw inside the C++ screen. Still harmless (item is in the bag).
## 1 Nov 2026 (evening): shop replies fixed
  * CTradeMgr::LoadTradeInfo reads <shopbuy costyb costyz/>, <retobj type id count/>, <bagid bagid="a|b"/> and <attr attr=".."/> as ROOT
    children. We nested retobj inside <shopbuy> (logcat: "no node: retobj / bagid / attr"), so nothing was added on the phone: the Tool tab
    kept the old count and bought gear only showed after a re-login. Now siblings (handlers.retobjXml).
  * retobj type is UseGiftPackItem's own: 1 item (ConsumeInfo bagnum += count), 2 shinobi, 3 weapon, 4 trinket, 5 armor (each bagid added as a
    card via AddObjFromNetCardData). Our cards.type differs (2 weapon, 3 armor): RETOBJ_TYPE maps it. Items now send type 1.
  * Checked in game: Tael bought -> count 0 -> 2 -> 3 at once, USE turns blue; Armor Bag (S) -> 10 Samurai Attire in the Armor tab at once,
    no crash (the old "reveal crash" was the wrong type). Live they show Lv3 until the next login (server Lv 1): display only.
  * Gear packs: game.equipFromText reads the dropinfo text (pack type 1 and shop bags giftinfo 7-12). Before: randomEquip(slot, min) picked
    uniformly up to 5 stars (3☆ bag "at least 2, chance of 4" gave 5-star 29-42 %; 4☆ bag 41-50 %) and "Five-Star weapon Card" packs gave
    3-5 stars of a random slot. Measured after: 3☆ bag 2* 30 / 3* 60 / 4* 9 %, 4☆ bag 3* 29 / 4* 60 / 5* 11 %, named packs exact + right slot.
  * First boss 1-2 (owner not answered): replay-decided would be 55 % / 48 % / 29 % at 1-2 / 1-6 / 1-10 vs now 22 / 10 / 1 % for the starter;
    mid-game teams barely change. Left as is.
## 1 Nov 2026 (evening): cross-server battle built
  * crosswar.js + handlers rl_r_cross_war / rl_w_cwar / rl_w_cwar_war / rl_r_crosswar_rank (rl_w_cross_war = team compare, unused, stub).
    Hot update 28.0.22 util/common.lua: MULTI_BATTLE_CGI_IP = CServerListMgr server url (works for every game file / host). 28.0.23
    ui_multiBattleScoreDlg.lua: rankData = {} at init (the table asked #nil before the reply: Lua error).
  * Opens from the Home map building "Cross" (btn_ninja -> CDefaultSLGMenu::ClickNinja; scroll the map right). Phases by server time:
    1 tickets until Friday 20:00, 3 list made, 2 battle Saturday 20:00-21:00. HB_CWAR_PHASE=1|2|3 forces a phase, HB_CWAR=win forces wins.
  * Status 1 / 2 / 3 screens: BuyTicket / Battling / Before. warlefttime must stay > 0 (0 makes the screen reopen itself in a loop).
  * Checked in game: ticket (535 -> 35 gold, "You have entered already"), battle list like photo 3238, challenge 41 -> win -> position 41
    +5 points a second, list moves to 35-40, Score Ranking, Merit tabs (present / server / nation / history), shop exchange 24 000 points ->
    4-star Gamabunta with the card reveal. The rank screen's client-side check uses the points from its last Present load.
## 1 Nov 2026 (evening): first boss stays hard; replay = skip
  * Owner: keep the first boss hard (~23 % for an un-upgraded starter). Decision unchanged (rl_w_pve average attack x 0.85-1.15).
  * Checked in game: lost 1-2 watched (LOSE, 1 enemy left) and skipped (LOSE), won 1-2 skipped (Victory): the result screen always
    follows the server's decision. But the replay used to scale the enemy defence to reach that result (same boss showed DEF 215 / 285 / 385).
    battleXml now keeps the real enemy stats and re-rolls only my luck (attack inside my card range, ninjutsu chances) up to 400 times until
    the replay ends as decided; defence nudging is only a last resort. 400 test fights at 1-2: 0 mismatches, enemy defence 285 every time.
## 1 Nov 2026 (evening): enemy teams scale, with variance
  * game.foeTeam(db, uid, sid, first, level, botAtk, around): a real player = their WHOLE team (every slot, own element / level / growth /
    attack range from teamStats); a bot = about the challenger's team size (that, +1 or -1, fixed per bot), never more than teamSizeAt(level)
    (newcardinfo levels, max 12). Arena lists show the same team.
  * battleXml: every enemy card has a defence range +-7 % (ours), rolled each fight and on every re-roll; training/tower foes too. The enemy
    team total = my average total attack x opt.ratio (the fight's own decision: their strength / mine), split by the cards' real defence
    (real player) or a fixed weight (bot). Spar, arena, war, border war, officials, national treasure and cross-server pass ratio.
  * Tried deciding PvP by the whole-team replay (true stats both sides): spar became all-or-nothing (team totals barely vary; one card more
    or less = 0 % or 100 %), so the decisions stay (owner keeps the balance). Measured after: same win counts (235 / 277 of 480), 0 mismatches.
  * Checked in game: spar vs Ninja19427 showed his real 4-card team (Shikamaru, Naruto, Kakashi, Sasuke).
## 1 Nov 2026 (night): new-player play-test (dev server, fresh install)
  * Fixed: "Login with Facebook" opened /facebook2/login.do in a web view and showed raw JSON; gumplogin.js now serves a short HTML page
    ("not available, close with X, tap PLAY"). Checked in game.
  * Fixed: world boss name picture. boss.js sent props_115/085/100 (coin pictures), so fightBossView kept its default "Deidara" over Madara.
    Names are boss_wt_01-11 in ccbResources/activity_05 (01 Hidan, 02 Zetsu, 03 Kakuzu, 04 Sasori, 05 Madara, 06 Kisame, 07 Obito, 08 Nagato,
    09 Konan, 10 Itachi, 11 Deidara). Bosses rotate Kakuzu, Sasori, Deidara, Hidan, Konan, Zetsu, Itachi, Obito, Madara; the fight shows the boss.
  * Fixed: ui_sevenDayView.lua:412 Lua error (layout has no label_get_award_day_left) skipped the rest of setLockInfo, so Claim looked green
    for unfinished goals. 28.0.24 guards those lines; checked: no error, Claim grey.
  * Fixed: wheel of fortune countdown showed 3649:23:59 (lasttime 10 years, 4-digit hours). Now runs to next Monday 00:00 (ours).
  * Checked fine: login days 1-14 (day 1 claim = 2 recruitment orders), level-up gifts, monthly sign-in, Growth Fund, Lottery and Wheel
    (level-10 gates from the game's own config), Treasure chests, Daily Task counts, recruit with an order, account window, fresh-install
    region = Konoha (main).
  * docs/GEAR-REPORT.md: where 5-star gear comes from (report only).
  * Betting tab of the cross-server battle: ui_multiServerLayer only shows "Betting event isn't open" (no Lua screen behind it; the
    multiBattleBingo.ccbi layouts exist without code). Not buildable without writing a new Lua screen.
## 1 Nov 2026 (night): one top-up a day (owner)
  * settings EVENTS "paylimit" (on by default; control panel > Server > events: switch off = unlimited). rl_x_free_topup and
    rl_w_ky_payorder refuse a 2nd top-up the same day (limited.topupsToday, local midnight) with code 8000 + message.
  * 28.0.25 ui_purchaseLayer.lua shows the refusal message (it did nothing on a non-0 code). Checked in game: 1st top-up VIP0 -> VIP1,
    2nd shows "You can top up once a day. Come back tomorrow!", gold unchanged. Switch seen in the control panel.

## 1 Nov 2026 (late): Arena crash fixed
  * Opening the Arena crashed the game (signal 11). Since enemy teams scale with level, rl_r_sport sent up to 6 <mate> per rival,
    but ArenaCellViewNew/ArenaRankCellView.ccbi have only node_icon1-4 and CArenaListView puts mate i in node_icon(i+2)
    (COpponentCardView::initArena, `adds r2, #2`). teammateXml now sends at most 3 mates (4 on the Rank tab, which lists the
    first too). Checked in game: Compete and Rank tabs open, 4 pictures per row.
  * Re-checked in game (dev server): Ninja Test stage 5 chests free / 160 / 250 gold (gold 2170 -> 1760), team slot 5 opens
    after stage 1-12 at level 30+.
  * Screen tour in game (level 45 test account, fresh start before each screen): Plunder, Akatsuki, War, Battles, No.1 list,
    Daily Task, Event menu + all 8 sub-pages, Wheel, Mora, Treasure, Millionaire, Award Center, login gifts, Save time, Top-up,
    Growth Plan, all 8 bottom-row icons, Team, Backpack, Training, Shop, Advance, Breakthrough: no crash, no Lua error.
    Ninjabook first page all grey is correct (sorted by ninjabookrank; this account's ninjas are at places 49-111).
  * War countdown shows negative times ("00:-59:-30"). Cause: CWarInfoView::UpdateUI sets the clock to normalconfig row 8 (war END,
    73800 s = 20:30) minus the phone's local time of day; row 7 = start 70200 (19:30). The original war ran 19:30-20:30 every
    evening; our war is open all day, so outside that hour the clock is negative. Tried: preview resttime>0 = "War has not started
    yet!" (closes the war); fightlefttime = the attack cooldown ("attack-CD"). Neither fixes it; both reverted. Real fixes: run the
    war 19:30-20:30 like the original (owner decision), or patch normalconfig in the client (table not found in the OBB yet).
  * Fights checked in game: Spar (win, reward draw), Arena (loss screen), no crash.

## Victory-screen silver 0 fixed; War all-day table ready (1 Nov 2026, late)
- Real cause of "victory screen shows silver 0": core_combat/NewFightResult_WinView.ccbi has label_round_getsilver (visible=False) and
  label_round_getsilver_pre (visible, same position, never written by any code). InitUI writes reward.coin (+ the stage silver for fight type 0)
  into the hidden one. Hot update 28.0.26 (tools/patch_winview.py, tools/ccbi.py can now write Check/visible) shows it and moves _pre away.
  Checked in game: Spar win with a test award of coin 4321 / exp 77 / merit 55 showed +4321 / +77 / +55. The earlier "double pay" note was
  about putting the stage silver into <award><coin> for training, which is still not done (the client adds the stage silver itself).
  Training wins should now show the stage silver too (type 0 adds roundinfo silver to that label): not checked in game.
- For fight type 6 (Spar) the round layer labels are: getexp = reward exp, getgold (merit icon) = reward+0x1c merit, getsilver = coin,
  needbdoy (grudge icon) = reward+0x18.
- War clock: the client tables are tables.bin in the OBB (zip with '@B>R' local headers, MBS .dbf files) and a hot update CAN replace it
  (CCFileUtils search path). tools/patch_tables.py edits numbers in it. Test: normalconfig row 7 = 0, row 8 = 86400 -> the War screen
  counted down to midnight properly (01:03:10 at 22:56), no errors. Not shipped (waits for the owner: original 19:30-20:30 vs all day).
  The Claude emulator still has that patched tables.bin (newer zips don't contain it); a fresh install removes it.
- War open all day SHIPPED (owner: "All day open", 1 Nov 2026): hot update 28.0.27 = patched tables.bin (normalconfig 7/8 = 0/86400).
  Checked in game: War clock 00:04:33 at 23:55, no Lua errors. Note war.js day() is the UTC date, so lives/scores reset at 01:00 Dutch
  time while the clock counts to the phone's midnight (small mismatch, left as is).

## From photo batches 90-96 (2 Nov 2026)
- Daily task chests now the ORIGINAL 6 at 30 / 80 / 120 / 160 / 210 / 250 points (photos 4107, 4211; was 7 with 60/90 ours). Task points already
  matched dailytask_info (gold chest 3x 15, Money Tree 3x 15, Reincarnation 30).
- Festival shop: ORIGINAL limit per event, 700 Christmas Caps / 600 Christmas Trees (photo 3627); was 10 a day (ours).
- Not changed (needs more info or owner): recruit pity (photo 4435 shows "Recruit 2 more" only; server PITY 20 stays), second-year Christmas
  exchange list and Anniversary event (12.16-12.20, Fireworks/Balloon) not built, world boss time (later 12:30 vs earlier 14:00).
- Daily chest "Parameter error" (owner, 2 Nov 01:04): every daily reset used the UTC date, so days flipped at 01:00 Dutch time; a screen opened
  before 01:00 showed yesterday's points and the claim after 01:00 was refused ("points not reached" -> code 8000 "Parameter error").
  Now all 26 day keys use the server PC's local date (reset at local 00:00, as the game says), and "not reached" maps to "Insufficient
  materials". Checked in game: 30-point chest claimed, 5000 silver.
- Anniversary festival built (owner: "Build it"): festival.js theme `anniversary` (switch `anniv`), items 40/41 added to the client's
  consumeinfo by hot update 28.0.28 (tools/patch_tables.py can now append rows: `table:+[json row]`). festival.js now takes each theme's
  item pair (t.a / t.b) instead of the fixed Christmas ids. Checked in game: screen title "Anniversary", fireworks/balloon icons, exchange
  20 Balloons -> 10 Sage Stone III paid, Buy window 100 / 140 gold with 700 / 600 limits, buying 1 Fireworks works. The Event menu button still
  reads "Merry Christmas" (client label for event 44). The unused item pictures props_340-383 include other later-version holiday art
  (scratch sheet in the session scratchpad); only 343/344 are used.
- Festival trade rewards that are equipment (Seven-star Sword, Sage Robe) showed the client's "更新整包显示图片" placeholder: festival.js sent
  the dropinfo ninja column (0) as a_goods; now dropinfo [4] (equipment id) is used. Checked in game.
- Arena limits like the original (owner: "do it like the original"): normalconfig 18/19/20/22 = cooldown after 3 attacks, 25 attacks a day,
  600 s cooldown, 30 gold to clear it; VIP adds vipinfo[21]-20 attacks (screen says "VIP2 +1 times"). rl_r_sport <my> sends todayresttime/
  todayall/resttime/restbatter; rl_w_sportpack (Cmd 8301, CArenaCdDialogView) clears the cooldown for 30 gold. Checked in game: after 3
  fights the built-in "Countdown to battle 00:09:xx" overlay with "Eliminate CD" appears, "Spend 30 gold to remove cool-down?" -> gold
  3660 -> 3630, challenges 22/25. Buying extra attacks (restpack, BtnPurchase) is not built (restpack 0).
- From the second full photo pass (commit b125397): World boss now uses the game's own normalconfig numbers: 10 hits a round (row 192),
  then a 75 s wait (row 207), 15 gold clears it (row 193); shown values everyone's reward 20 on win and loss (109/110), gold inspire 15 for
  +5..10 (194-197), silver inspire 5000 for +1..3 (198-201). Server check: cdallnum 10, cdrestnum 9 after one hit. The boss screen's
  "Number of challenges: 00" is label_cd_time (the cooldown, format 3); label_pk_limit (n/10) is hidden in the original layout.
  NOT changed (need the owner or more data): boss reputation per hit (original normalconfig 258 = damage / 30 000, ours damage / 5000:
  original would give 6x less; asked), boss hours 12:30-13:00 (normalconfig 106/107, ours all day), succession price (one photo: 2450
  gold for 5-star Lv50 growth 9 rebirth 1, ours 200; one point is not enough for a formula), Save time "round N" (photos 2212 and 4035
  fit different stage rules), Hyourou-gan "Left today 0/6, VIP2 +3" (vipinfo says 30/33 uses; which limit is unclear).
- Boss reputation per hit now ORIGINAL damage / 30 000 (owner: "Yes, original"); min 1 (ours). Owner's main account (team attack ~8800) gets ~7 a hit instead of ~44.
- 2 Nov night batch (owner: "Do all that"): recharge streak days 1-3 + 7-day bonus original (photo 3942: 万 ticket = Tael (large) props_021,
  green 忍 card = props_039 "2~5S Shinobi" = dropinfo 1508, icon/label forced in dailyevents.itemXml); second-year Christmas list = festival
  theme `christmas2` (switch `xmas2`); world boss 14:00-14:30 (client text fightBoss_status_1; closed = inact 0 + seconds to 14:00, the screen
  shows "Battle begins 14:00 daily / World Boss event has ended" and locks Challenge) and silver = damage / 100; generic fragments 12-17 (type 6):
  50 -> a card via <propuse ... ninjaid/ninjabagid/ninjaattr | equipid/equipbagid | skillid/skillbagid> (CItemView reads attributes);
  festival items hidden from the Tool tab off-season. All checked in game. Not done: plunder success text is the client's own (by level; no
  numbers known), Ninja Treasure top prizes (photo shows 16 portraits only), 300-gold recruit gold prizes (client can only show a card).

## The game's own settings table, all 303 rows compared (2 Nov 2026, night; owner: "Yes, do it")
Applied (normalconfig row numbers): treasure chests without a key 100 / 50 / 20 gold, double chance 5 / 10 / 10 % (121-126); world boss
dice 25 gold (111), kill +200 reputation (108); war: 10 revives for 30 gold (15/17); Save time bonus roll x1 / 1.2 / 1.4 / 1.6 / 1.8 at
50/20/15/10/5 % (231-235, the client plays its own crit animation from <ratio>); spar: a loss costs at most 1000 silver (89), the same
player at most 5 times a day (44); energy refills to max every day at 22:00 (87); money tree 5 shakes, 1 free, 10 gold, 2000 x 1-6 (50-55);
tower: instant finish 3 gold a round and VIP3 (290/291), 2 resets (296); Millionaire throw 100 gold (135); slot spin 100 gold / 10 points
(300/301, payouts scaled 10x so the return stays the same). NEW soultrain.js = Eight Gates "Train soul" (rl_w_eight_gate Cmd 3-6; was
answered with the gate screen): normal 10 000 silver -> 50 souls x3/day, advanced 35 gold -> 70 souls (vipinfo[27] a day), doubling
5/10/20/30/50 gold at 100/80/60/10/5 % or advanced 7/25/75/150/250 always (2 free a day) (263-283). Needs level 80 (functionconfig 21).
Checked in game: info, train, both doublings (x4), collect (+200). Advanced "100% up to 3x" (layout text) is played as x2 (ours).
Kept because photos of the live game show other numbers: cross-server ticket 500 (table 400), secret shop refresh 20 gold / 75+5xVIP
(table 15 / 150), arena reward time. Already equal: element change 2000, lottery, scratch, growth fund, border war, gates, first top-up x3.
Not built: free ramen times 12:00-14:00 / 18:00-20:00 (46-49), seal direct merge 30 gold (180), stronger-country help (56).
- Free ramen (owner: "Yes, add it" to 12-14 / 18-20): the "Noodle" stall on the home map (CRamenView, rl_w_ramen) was answered with an
  unlimited free refill. The English v28 stall sign says "Once All Time (0:00~24:00)" and the client sends at any hour, so it is now ONE bowl a
  day at any time (fills energy + grudge). The Chinese rule (normalconfig 46-49 / CRamenView TimeRange constants 12:00-14:00, 18:00-20:00, one
  per window) is behind RAMEN_WINDOWS=1. Checked in game: 88/106 + 2/4 -> 106/106 + 4/4, second bowl refused ("already claimed", 170007).
- Ramen: owner chose 12:00-14:00 / 18:00-20:00 ("Use 12-14 / 18-20"); now the default, RAMEN_ALLDAY=1 for the English sign's once-a-day rule.
- Recruit window (owner, 2 Nov): "stays on Free recruitment, Recruit 17 doesn't go down, can pull free 20 times, gives God cards".
  The server already charged 300 after the free pull; the window never redrew. CCommonPrayDialogView::onHttpRequestCompleted (pull reply)
  only calls InitUI when root > protect_comming > protect_comming (NESTED, same name, text) exists; then it redraws the count and swaps
  "Free recruitment this time" for the price. Now sent (plus protect_comming="" on <recruit>). The window shows value-1 ("Recruit N-1 more",
  value 1 = "this one is the five-star"), matching our toGo. The 10-pull branch (recruit_list) never redraws in v28: the count updates on
  reopening. Recruit pools (rollOne -> recruitPools): only classic cards (ids < 2000), ATK AND DEF (ninjainfo [6] 0/1); the later premium
  cards with God versions (Teenager Naruto, Goddess Sakura, Susa..., 48 five-stars) and DEF were wrong (DEF was never given). Checked in
  game: free pull 18->17 + price shown, paid pull, 5-star resets to 19.
- Discord (owner, 2 Nov): #announcements renamed #updates (every update); new read-only #announcement for big news only (new app, releases). layout.js channels can now take was: for a rename.

## Big test round (2 Nov 2026, from 04:39 until 13:00; owner's list)
- B16 bad input: new tools/dev/fuzz.js (every handler x every Lua Cmd x missing/0/-1/huge/text/injection values, valid and broken player
  ids, 3692 calls) and tools/dev/exploit.js (sane vs negative/huge/0 parameters with identical dice, flags extra gold/silver/items/cards).
  Found + fixed: a non-whole Uid ("1.5", "-1") crashed every handler at the account insert (accountBySession now needs a positive whole
  id); rl_w_dup with a bad Chap/Round wrote exp NULL (now "no such round"). Exploit check: nothing.
- Lottery tile in the Event menu shows Chinese 忍村彩票: it is the picture activity21 in ccbResources/activity_btns_2 (sprite sheet; re-encoding broke 28.0.18), left as is.
- Lottery screen: header/labels 第1期忍村彩票, 本期彩票开奖时间, 领奖截止时间, 一等奖.. are pictures in LotteryTicketView (left); the draw time reads '11Month02Day20Hour30' (ui_lotteryTicketLayer open_time + localizable ui_lottry_month/day/dian/min): candidate for a hot-update tidy.
- Soul training "up to 3x": LimitTrainSoulView.ccbi's static labels say normal "(Up to 2x)", advanced "(100% up to 3x)" and the batch "(Up to
  32x)". 32 = 2^5, so five doublings of x2 each (what soultrain.js does) fits the layout. Kept.
- Card upgrades walked through on a throwaway save (new tools/dev/upgrades.js): level-up, reincarnation (pills), element change (2000 silver +
  10 pills), potential roll/save, succession (stats move to the twin, 100 gold), sage growth x3, god evolve (Minato -> Minato God),
  equipment level-up, Eight Gates: all OK. Team screen vs home attack differ by the set bonus (5 five-star cards +3200): by design.
- New-account check: Card 1/2/3 -> Shikamaru 57 + jutsu 54 / Sakura 56 + 14 / Neji 55 + 12, 50 gold, 18 000 silver, team 1. OK.
- Timers that still counted to UTC midnight now count to local midnight: country officials, war, Ninja Treasure; tower sweep day key and the
  monthly sign-in month use the local date.
- Spar victory draw: the card you pick showed an empty "大拉面" and gave nothing. Cause: the win award had dropid 0 (the draw shows the award's
  drop as your pick; the two other cards are client fillers, fillDropData). Now ORIGINAL drops from the game's tables: first spar ever 1284
  (normalconfig 182, "One, Two-Star Weapon Card"), below level 30 drop 397 (normalconfig 113/114), else duelinfo [10] = 27 ("Drop from
  Equipment, Seal"). (ours): 397 = 2-star 60 % / 3 35 % / 4 5 % gear or ninjutsu, 27 = 3-star 80 % / 4 18 % / 5 2 % gear. rollPack now
  turns "Weapon/Armor/Trinket Card" packs into that slot's gear (1284 gave a shinobi). Checked in game: picked card = 4-star Scroll of Seal.
  Also hot update 28.0.30: RS_WinAnim.ccbi / BuyItemDialogCellView.ccbi default label "大拉面" -> "Big Ramen" (tools/patch_winanim.py,
  tools/ccbi.py replace_string); the filler ramen card now reads "Big Ramen".
- Battles (tower) win showed EXP 0 / silver 0 and the top bar lagged until relog (server paid 58 / 87). The tower result screen does not add
  the round reward itself (story stages do): the award now carries <exp>/<coin> = the round's own reward (+ any drop silver). Checked in
  game: +58 / +87 shown, top bar 1172 / 22197 = server. First in-game tower fight ever (rl_w_dup had never been called in the replies log).
- Plunder chance ORIGINAL: the game's plunderinfo table (700 rows, col [1] = level difference, [2] = chance, [3] = label) is what the
  client's "Plunder success rate" label reads (CPlunderCardView::InitUI, key = rival lv - my lv, 0 -> 1, negative -> 300 - diff). Rival
  higher: 1-10 40 %, 11-20 50 %, 21-30 60 %, 31-50 70 %, 51-70 80 %, 71-90 90 %, 91+ 100 % ("Shall"); lower: 1-10 50 %, 11-20 40 %, 21-30
  20 %, 31-40 15 %, 41-50 5 %, 51-80 1 %, 81+ 0 % ("No"). seals.plunder now rolls that (after a won fight) instead of a flat 70 %.
  data/plunderinfo.json re-exported (mbs.py now reads 'i' = signed int; the old export had NaN).
- W.A. titles were missing: login sent <meritlevel>0, so nobody had a title ("NinjaLv.") or its bonus. ORIGINAL table playemedal: Junior
  Genin at 500 W.A. (+25 attack/defense/chakra) ... Supreme Gaiden at 3 000 000 (+2550); the client adds the same flat bonus to the team
  attack (CPlayerDataMgr::firefly_GetPlayerAttack / CActiveTeamMgr::GetAttack). game.meritLevel counts every W.A. ever earned (new prop 9993,
  starts at the current W.A. for old players) so spending W.A. in the shop does not drop the title; teamStats adds the bonus. Checked in
  game: 600 W.A. -> "NinjaLv.: Junior Genin", attack 3410 -> 3435. The owner's main account (4010 W.A.) becomes Elite Genin (+150).
- Card feeding (rl_w_strengthen) now uses the game's own tables, like the client does (CPlayerNinja/CPlayerWeapon/CPlayerMark/
  CPlayerNinjutsu::firefly_ExpCost = row[3] EXP given, GetNeedSilver = row[4] silver, of the EATEN card's kind and level; the growing card
  levels by row[2] of its own kind). Before: flat 75 EXP / 150 silver per card and ninjaupgrade for gear too, so gear/ninjutsu/seal levels
  on the server differed from what the client showed (the client computes the result itself from the tables; reply only carries eatexp).
  Level-1 ninja food unchanged (75 / 150); a level-1 gear card now gives 250 EXP. Not checked in game (math = client tables).
- Arena ladder rewards (ladderconfig 2000 ranks -> ladderdesc 7 tiers -> dropinfo packs 159-165: rank 1 '5-star / 4-star equipment, full seal or 300 gold' ... rank 501-1000 '4/3-star equipment or 5000 silver'): shown by CArenaAwardRuleDialogView (Arena rules). Not given by the server; unclear if it was in addition to the photo-confirmed daily silver/reputation. Asked the owner.
- Server-side checks (2 Nov test round): Akatsuki between two players (create, join, list, hall, store, donate, admin), cross-server battle (ticket, inspire outside the battle refused, fight outside Saturday refused, ranks, point shop), money tree in game (free 2000 silver, then 'continue for 10 gold'), W.A./arena/war/boss awards match what is paid. All OK.
- Battles (tower) like the original: the client has 25 chapters (rushtower) x 7 rounds (towerfloor), round 7 = the chapter boss (the big
  portrait, CTowerBossView), process 8 = passed and the next chapter opens (CPlayerDataMgr::firefly_ChapterProcessForward). The server had
  maxchap 3 and 6 rounds (so the boss could never be fought, chapters 4-25 never opened); this morning's bad-input check had also locked round 7.
  Now: open chapters = 1 + passed (max 25), rounds 1-7, sweep ids (chap-1)*7+round. Boss drop = one of the 4 the "Possibility of boss
  landing" window shows (rushtower [9]-[12] = fillDropData 284/285/286/288 -> dropinfo 1332 Shukaku Seal, 1285 Recruitment Order, 1297
  Refresh Order, 176 five-star fragments; equal chances, ours). Checked in game: chapter 1 shows 7 rounds + Zabuza, boss win +60 EXP / +39
  silver + fragment, chapter 1 turns red and chapter 2 opens. Accounts that played chapters 2-3 under the old rules keep that progress
  (it shows once chapter 1 is passed).
- Gear and ninjutsu SETS (skill_suit_info, 13 sets: Six Paths, Technique ... Thunder, Legendary, Hōzuki) were never applied. The game's own
  set panel (EquipSuitSubView: per 2 / 3 / 4 pieces "Attack+ flat / %, Defense+, Chakra+, Chance of skill+ %") confirmed the columns:
  [8]-[25] = attack, defense, chakra, each 3 tiers of (flat, share); [26]-[28] = skill chance per tier. game.skillSets/setBonus: gear sets
  (weapon, armour, trinket, seal on one ninja) add their stats; ninjutsu sets only add their skill chance (expected value, ours; the game
  counts their stats when a ninjutsu fires). Team slots now send <skillsuit><item id num/></skillsuit>. Checked in game: the Thunder set
  pieces show the game's "Suit" ribbon and the set panel; team card attack 856-1088.
- God of Wealth (财神, Event menu "God of Wealth", activity id 4, CLotteryView) built: caishen.js + switch `caishen`. ORIGINAL table
  wealthactivity (8 steps: invest [3] gold, get [4]-[5] back: 25 -> 30-40 ... 7500 -> 8000-8500), level 10 (normalconfig 183), 7 days (298).
  The client reads the step from rl_r_activity <activity type="3"><item actid="3" pos> (was always -1 = finished) and invests with
  rl_w_activity Cmd 9100 ActType 3 ActID 3 SubID; reply <caishen recash/>, the client adds recash - invest. Checked in game: tile shows,
  "Investing 25 / gain at least 30 / 8 chances", bet -> recash 32, gold 7123 -> 7130, next step 150 / 175 / 7 chances.
- Month card (Event menu "Monthly Card", activity id 3, monthCardActivity.lua) built: monthcard.js + switch `monthcard` (off by default:
  top-ups are free, so it is free daily gold). ORIGINAL monthCardData.lua: $4.99 = 60 gold a day x 30 days, $9.99 = 120 x 30. State via
  rl_r_activity <activity type="4"><item actid="4"><canget subid/> | <ing><card subid/></ing></item> (was always empty = "Buy"); claim =
  rl_w_activity ActType 4 ActID 4 SubID. (ours): Android has no buy flow for it, so a free top-up of exactly $4.99 / $9.99 activates the card.
  Hot update 28.0.31: the screen adds <month recash> to the top bar (the original line was commented out). Checked in game: "Claim" shown
  after a $4.99 top-up, claim +60 gold, second claim the same day refused; after relog the button does nothing (the original screen never
  greys it).
- Not built (needs invented rewards): the server-opening level / power ranking events (levelRank_business, fightRank_business; <conf><opentype>, rank awards come from the server and are lost; normalconfig 99/100 = 7 days after server start + 1 day to claim). Our server has run for weeks, so a 'new server' race makes little sense.
- Login streak ("Sign-in" tile = keepLoginView, activity id 14) built: keeplogin.js, Server-tab switch "Login streak" (on). ORIGINAL rewards
  = the client's keeplogin_info.lua (day 1: 2 small ramen + 2 small Hyourou-gan + 500 silver ... day 7/8+: 20 gold + 2 big ramen + 3 big
  Hyourou-gan). State = rl_r_activity <activity type="5" desc="conlogin" condays got>, claim = rl_w_activity ActType 5 ActID 1 SubID day.
  A missed day restarts at day 1 (ours). Checked in game: tile shows, "Continuous Login: Day 1", Claim -> reward pop-up.
- Flower Worship (goddess event "nvshen", Event menu activity id 15, ui_nvshenLayer.lua) built: flower.js, Server-tab switch "Flower Worship"
  (off by default, runs 7 days from switch-on). ORIGINAL: 1 rose per $ topped up (game text ui_nvshen_description), the 5 goddesses' rewards
  (same text), favourability 0/1 and the rose prices Mei 40 / Hinata 24 / Konan 95 (photos 1240, 3864, 4543). (ours): Tsunade and Sakura
  95 roses, a goddess can be won again. Protocol: rl_r_comm Cmd 5 (<preview open myflower resttime/> + <itemlist><item> ninja_id/name/icon/
  flowers/alllikenum/own_like/index + <awardlist>), rl_w_comm Cmd 9 GirlID (<preview currsat currflower/> + <award>; code 320002 = not enough
  roses, the client opens Top-up). Item index must equal the picture the layout starts with (sprite_avtor_N = nvshen_meinvN), else names and
  prices land on the wrong goddess. Roses = prop 9992. Checked in game: screen, Mei "Given 40 flowers", gift -> Gaara + Silver Key*3, roses
  45 -> 5, too few roses -> Top-up window.
- Succession price: the client shows and charges cost_cash + add_attack + add_defense (ui_ninjaInheritLayer, comment "gold + training
  values"); we sent the trained points as 0. Now add_attack/add_defense = the card's trained attack/defense (pot_att/pot_def) and cost_cash
  = 50 x (level - 1) (ours: photo 4440 shows 2450 for a level-50 card with training 0/0; was 50 + 50 a rebirth + 50 per 3 growth = 200).
  ninjaupgrade's last column (2450 at level 49) is m_sellprice, not a succession price. The v28 card view still has no Succession button.
- Flower Worship photos 3863/4709 show two later runs with other reward lists (both cut off; Boruto is not in v28): kept the list
  written in the game itself.
- Hyourou-gan did nothing: the server took the pill but never restored grudge (duel points), and replied sp="0" (the client,
  CTradeMgr::UseConsumeItemByID, sets energy = ap and duel points = sp only when they are not 0). Now consumeinfo type 2 adds [8] x the
  level's maximum grudge (Small 50 %, Big 100 %, up to the maximum; refused when full) and sends the new total. Daily uses ORIGINAL vipinfo
  [6] ramen 20 (+2 a VIP level) and [7] Hyourou-gan 30 (+3 a VIP level), row = VIP + 1; sent as <propuse rest max> and in rl_r_shoplist
  1600/1601 <limit><actiongoods>/<bingliangwan> (the item window's "Left today" number; it was 0). Photo 4550 ("0/6 ... 30, VIP2 +3")
  = grudge 0/6 and 30 uses left for a VIP1 (33). Checked in game: grudge 0/4 -> 2/4 with a Small one, window shows 44 left at VIP5.
- Item USE (CItemView::onBtnUseIt switch on consumeinfo [7]): types 1 ramen, 2 Hyourou-gan, 3 Tael, 6 fragments, 9 ninja souls, 10 W.A.
  Increase Pill, 15 Double Exp Pill and 18 Souls Dan call rl_w_propuse; 5/7/8/12/13/14/16 open a screen, 4 (shields 免战牌) does nothing, 19
  pet food says "use it in Pets", 11/17/20+ go to itemScriptManager.lua. The server only handled 1/3/6 and ate the rest for nothing. Now:
  fragments and souls give the card of their own drop ([9]: The Fourth Sage 531, Six Paths Obito 532, Goddess Tsunade 559, Sage Naruto 337,
  Killer B (Santa) 375, Itachi 285; random packs 10-15 as before; The Fourth Sage fragments used to give a random ninjutsu); Souls Dan
  +1000 Eight Gates souls ("receive 1000 souls per dan for eight gates"); W.A. pill doubles spar W.A. and Double Exp Pill doubles training
  EXP for [8] = 300 s (another pill adds 300 s; the client shows no timer). Checked in game: Souls Dan 5200 -> 6200 gate souls, "Used
  successfully"; Double Exp Pill timer runs. Not checked in game: soul items (the test account has none in the client list yet).
- VIP table rows were read one level too low. The game reads vipinfo at row VIP level + 1 everywhere (ui_vipRightInfoView shows VIP L from
  row L + 1; CommonBuyItemDialog, boxOpenActivityView, ui_secretShopLayer use viplevel + 1), so VIP0 = row 1. Photo 3574 agrees: a VIP0
  player ("VIP1 +5" = the next level) has 25/25 gold chest opens. Fixed with game.vipRow: gold chests VIP0 25 (was 20 ours, and every VIP
  one level short), arena attacks +1 a level from VIP1 (was from VIP2), mystery shop refreshes 80 + 5 a level (was 75 + 5), high-level soul
  training 3 at VIP0 + 1 a level (VIP0 had none).
- Brand-new save check (now the second pass of tools/dev/fuzz.js: every handler x Cmd called first on a fresh save): 6 screens crashed
  because their table is made by another screen: arena ranking (arena), guild ranking (groups), war result (war), border war player /
  enemy / award claim (border_station). handlers.saveReady makes those tables on the first request of a save. Normal play opened the main
  screen first, so it showed up only on a new server. Border war clears a day: vipinfo [23] "monument can remove players 20 times" at
  VIP0, +5 a VIP level (was 10, ours; the reply's nextlv_cleartimes_lmt now shows the next level's number).
- Battles floor rewards (Ranking button > Achievement tab, CTowerRankDlg / CTowerRewardCell) were never paid: the list showed every 7
  floors a reward with a Claim button, but rl_r_dup 7001 sent <award>0</award> and rl_w_dup Cmd 3101 (AwardID) had no handler. ORIGINAL
  table tower_reward: [2] floors (7, 14 ... 175), drops [3] [5] [7] (chapter 1: 50 gold + 10 Sage Stone III + Kubikiribocho; later 100 /
  150 gold, 15 Sage Stone III, 5 Super Ninja Pills, the chapter's boss gear), fillDropData [4] [6] [8] for the icons. <award> is a bit mask
  (the client: claimed = (award >> id) & 1); rankings.towerClaim checks floors (= the Copy progress number) and pays all three drops.
  Checked in game: 7-floor row Claim -> Kubikiribocho + 50 gold + 10 Sage Stone III, row shows "Claimed".
- Unused game tables checked (server never read them): tower_reward -> built (Battles floor rewards). ninjiasoulconfig = an 8-prize roll in
  the recruit reveal box (Itachi soul x1-4, 2000 / 5000 silver, 10 / 50 gold; CDialogShowBox::InitRandomPropsUI) but its switch
  SetShowRandomProp is never called in v28 (dead code), so it cannot be used. functionconfig (feature unlock levels), countrywarhonor (war
  titles), *bookrank (Ninjabook), packtips, sysnotice: read by the client only. ladderconfig/ladderdesc (arena rank rewards): waiting for
  the owner. iapiteminfo has no prices that match the top-up screen (not used).
- Training "difficulty" (adventure) leftovers: storyinfo = the training chapter titles (+ 15 EXP / silver columns per difficulty) and
  CListLevelView shows a "Reset <chapter>?" dialog (ReNewLevel.lua, rl_w_adventure 2609) when a chapter's hardLevel > normalconfig 59 (15).
  CRunLevelView, which would pay those per-difficulty chapter rewards (rl_w_adventure 2605/2606), has empty stubs for its network reply,
  round data and reward code in v28: the mode is dead. We send hardLevel 0, so the reset dialog never shows. War progress chest
  (rl_w_warresultnew 8200) only shows with canrequire 1 (never sent; reward lost): now answers a tip instead of an empty reply.
- Arena Exchange tab: the reply to rl_x_sport_ext Cmd 1 was code 1 (the tab showed "Successfully purchased" and reputation 0) and buys
  had no limits. Now <renown_value> + <renown><ritem><id/><dayget/><totalget/></ritem></renown> (CHILD elements; attributes crash at
  0x18). Values = times LEFT, -1 = no limit of that kind: the row shows "Total Exchange N Times" if totalget is not -1, else "Today's
  Exchange N Times", and greys its button at 0. ORIGINAL limits exchange_award [4] total (Sasuke, Naruto, seals, kunai: once ever) and [5]
  a day (pills 2, Sage Stone I 4); the server enforces both. Checked in game: reputation shows, Development Dan 2 -> 1 -> 0 left and greys.
  Found by a new check: every reply tag a C++ screen reads vs every tag our code sends (scratchpad tags.py).
- Second team line-up built (it IS in v28: Team screen tabs "Team 1 / Team 2", Activate, Detail). ORIGINAL rules = the screen's Detail
  text + normalconfig 211 (100): Team 2 opens at level 100, may use any card (also ones in Team 1), Activate picks the used line-up (tick).
  Client: index 0 = <ninjalist>/<suitlist>, 1 = <defenseninjalist>/<defensesuitlist> (login, rl_r_ninjalist), <activeTeamId>; every
  edit sends TeamId (reply <teamid> + that team's <suitlist><ninjalist>, CMyGroupCardView), Activate = rl_w_ninjalist 2310 ActiveId ->
  <activeid> + attactlow..chakrahigh as root children. Server: team / equipped = the USED line-up (so fights, rankings, rivals, arena
  need no change), team_alt / equipped_alt = the other; players.active_team; game.activateTeam swaps them in one transaction. Cards in
  either line-up count as "in use" (feeding, refining, succession, donating). Checked in game (test account set to level 120): Team 2
  tab, add Naruto, Activate -> tick on Team 2, Team 1 keeps Shikamaru + gear, after a restart Home shows Naruto.
- Level-up: CPlayerLevelUp::requestActivity calls rl_r_newbie_pay Cmd 3; <on_off>1</on_off> in the reply makes the client re-read the
  event red dots (Lua readActivityNewsData). Now sent; checked in game (level 120 -> 121: rl_r_activity + rl_r_paypack follow, no errors).
  Plunder preview "plundertip" is built by the client itself (Markinfo name + string 0x31/0x32), nothing to send.
- Akatsuki leader screens (Manage > deport / apply / membership, Setup) got empty replies (rl_w_group_admin had only Cmd 1/8/9). Now:
  2 member list (<member_list> + <pos>), 3 expel (Members = JSON uid list; the chieftain selecting himself disbands -> <dismiss_group>1),
  5 promote / demote (PositionAction 1 / 2; promoting a vice chieftain = abdicate), 6 / 7 settings (minlevel, minfightscore, desc; now
  checked when someone joins), 10 / 4 approval list (empty: joining is instant here), rl_r_group_comm 4 "Akatsukis I applied to"
  (empty). Positions 0 ordinary, 1 team leader, 2 vice chieftain, 3 chieftain (localizable OrgTitleName). Who may do what is (ours).
  Checked in game: membership list, Promotion (ordinary -> team leader), Setup shows and saves ("modify succeed"), no Lua errors.
  Found by a new check: every find("tag") a Lua screen reads vs the tags our code sends (scratchpad luatags.js).
- Ninja Treasure "Top Rewards" window was empty: rl_r_sudoku Cmd 2 must return <mibao_info><item index drop_id/>...</mibao_info> (the
  Lua xml find() returns the FIRST element and # counts its children). Now lists the 14 prizes the board really uses (sudoku.POOL), best
  first. Checked in game. The original top list (photo 4335: 16 cards incl. Six Paths Obito, Fourth Sage, Indra, Hashirama...) would
  change the prize pool: not done, asked the owner.
- Border war: attacking while already stationed answered 329018 (= "not enough gold": the client showed that tip and opened the top-up
  window). Now like ui_borderWarAttackLayer expects: same country -> 329012 "already attacking this country"; another country -> 329020
  + <basic country status has_award min_time/><award exp merit/> so the "switch target?" dialog (ui_borderWarChangeAttackDlg) shows;
  its confirm resends with Switch=1, which ends the old station (no reward: that only comes after the full stay) and starts the new one.
  Not enough gold for a taunt now returns 329018 (top-up offer), not enough silver a plain tip. Checked on a test save only (did not find
  the border war entrance in game this round).
- War progress windows (the "?" next to "killing number" / "casualty" on the War screen = CWarAttackProgressDialog, rl_r_countryranknew
  4201 kills / 4204 times attacked, Country = the side; CCountryWarProgressDialog 4203) showed the power ranking with no values: they
  read <userrank myscorecount myrank myscore> + <user><rank/><uid/><nick/><realval/><countryid/></user>. war.progressXml now sends
  today's war: kills (or casualties) per player of that country, my kills, rank in my country and merit. Checked in game: "Active kills
  ranking" after one war win: actively killed 1, country ranking 1, achievement earned 10, list row Ninja5613 1.
- Team edit reply (rl_w_ninjalist 2300-2308) for the USED team now carries <usernum><AttackLow/><AttackHigh/><DefenseLow/><DefenseHigh/>
  <ChakraLow/><ChakraHigh/></usernum>: CMyGroupView then updates the player's attack / defense right away (it reads them only when
  <usernum> is there and teamid = activeTeamId). The stats are CHILDREN of usernum: as flat siblings the game crashed (0x18), checked.
  Checked in game: adding Obito / Gaara to the used team, no crash.
- Battle reports built (News > Battle tab, CNoticeDataHelper / CFightMsgCellView; was always empty): notices.js records a notice for the
  defender when a real player spars or plunders a real player (rl_w_pvp 2701 with / without Chip); rl_r_msg Cmd 1800 lists them
  (<msglist><msg> with child elements subtype 0 spar / 1 plunder, fromnick/uid/ninja/firstninjastar/country/level, result 0 = attacker
  won, iTime, ID, iCoin, iTakeRes 0 stolen / 1 failed, iChipid = seal piece (markinfo) id, iStatus, newlife); rl_w_msg 2901 Op 1 delete
  ("Ignore") / Op 2 read, Index = ID; Revenge = an ordinary spar. Texts are the game's own (Struct_String_Menu 26-34). The defender loses
  nothing here (ours), so the reports say "you lost 0 silver" / "failed to steal". 30 kept per player (ours). Checked in game: three
  reports (spar won / plunder / spar lost) with the right texts, Ignore removes one, Revenge starts the spar.
- Event red dots: rl_r_trackpoint (mainActivity / reloadActivityData readActivityNewsData, also CWarDefaultView) now answers
  <activity><item actid display count period/>...</activity> for what the server knows (activity_config.activityTipConfig): 8
  cumulative top-up steps ready to claim, 19 month cards to claim today, 5 world boss open now, 9 Flower Worship and 14 group buy while
  switched on (period = the switch-on time, so a new run lights the tile again). Others (roulette, mora, monopoly, war award ...) are
  left out = the client keeps its default. Checked in game: no errors; the News button shows "1" for an unread battle report.
- errcodes.js: more refusals now show a fitting game text instead of "Parameter error" (already collected/opened, Akatsuki full / name taken / authority, cooldowns, boss defeated, cross-server registration/battle time, morale boosts, free recruit not ready, maximum level, stage cleared, grudge full, exchange limits, daily item use limit, nothing to claim). Codes checked: only the client's text table uses them (no special handling).
- Shop gift packs checked one by one (Shop > Giftpack): the item bags (giftinfo [7] = 2: Rāmen Bag S/L 10 / 50 Rāmen (L), Tael Bag S/L 10
  taels, SageStone I / SageStone Bag 100 stones) read [8] as a drop id, so a Rāmen Bag gave 10 Chōji cards, a Tael Bag one random ninja and
  the SageStone Bag failed. Now they give [9] x item [8] and reply <retobj type="1" id count/> (CTradeMgr::UseGiftPackItem adds items
  itself). Checked in game: SageStone Bag 1000 gold -> Sage Stone III 42 -> 142. Ninjutsu / Skill bags stay refused: UseGiftPackItem
  only knows retobj types 1-5 (item, shinobi, weapon, trinket, armor) and an empty item reply crashed the game (fault 0x0), so they
  cannot be shown. Bag 22 (一尾印记包) drops fragments, also refused as before.
- Friend messages (left from the friend chat, rl_w_friend Msg + ToUid) now show in News > Friend as "Friend notification" (subtype 3,
  rl_r_msg 1801: same <msg> fields as the battle reports + <text>) with the sender's card; the text starts with the sender's name (the cell
  shows none). Manage -> Confirm marks it read (rl_w_msg 2902 Op Index). Before, they were plain lines in the System tab. Checked in game.
- Chinese text check over every game table (data/*.json): visible ones fixed (golden Chōji card name via 28.0.32; Giftpack bag 22 "一尾印记包" -> "Shukaku Seal Bag" in data/giftinfo.json, the server sends package names so no game update needed). Not visible (left): mystery shop rows 217-241 (filtered), suit_info 49-56 (duplicates of 41-48, never win), ninjamatch 1292-1307 (cards 2073/2076/2079 don't exist), wheelconfig/wheelpackconfig (no screen reads them), vip_gift 101/102 (filtered), functionconfig names (tips are English), dropinfo internal names, normalconfig labels.
- Award Center built (the "Awards" chest on Home, ui_awardCenterLayer; was always empty): awardcenter.js + control panel tab "Award
  Center" (admin /admin/api/sendmail): send gold / silver / arena reputation with a title and message to one player or everyone. ORIGINAL
  protocol rl_x_award_msg: Cmd 1 <expiry>7</expiry><msglist><msg><id/><ts/><title/><content/><awards><item type dropid/></awards></msg>,
  Cmd 2 MsgID / Cmd 3 claim (<award>); item type 1 = drop (gold goes as the game's gold-only drops, e.g. 2500 = 2000 + 500), 2 = silver,
  3 = reputation. Kept 7 days. Checked in game: message shows like the original, Claim -> reward card Gold*250, top bar updates on the
  next screen change.
- VIP gift packs, the Lucky Wheel and the stage gift used drops.js, which paid every ninjutsu, seal and fragment as 20 000 silver
  ("not implemented yet"). VIP2 had no Kurama Seal, VIP6/7/8/9/11/14-17 no ninjutsu (Amaterasu, Tsukuyomi, Susanoo, Shinra Tensei ...),
  VIP12 no Ten-Tails Seal. They now use game.grantDrop like everything else. Checked in game: VIP2 gift -> Kurama Seal card, VIP6 gift ->
  Amaterasu (5-star ninjutsu card), no errors. (The VIP2 text says 10 Large Ramen; the game's own drop 1395 gives 5: kept.)
- Random packs checked one by one against their own text (all 337 dropinfo packs): equipFromText read "chance of X-Star ..." in ANY pack
  text, so "One,Two-Star Shinobi Card" (drop 16 = 20 % of normal story stage wins) gave 1-2 star gear, "Shinobi Pack III" gave gear and
  the ninjutsu packs ("Ninjitsu", the game's spelling) gave gear; seal packs ("Tailed Beast Seal Fragment" x5 / x3 in the gold / silver
  treasure chests, "Seal fragments", "Complete Tail-Beast Seal", "Tail Beast Seal") gave a random shinobi. Now: equipFromText only for
  equipment texts; /Ninj[ui]tsu/; seal fragment packs give a random fragment of any seal (props 20000 + markinfo id, shown in the award
  as a seal card with the fragment's id and bagIndex 0: the reward screen shows "Seal fragments: X Seal Fragment N", the Seal tab stays
  clean), complete seal packs a random tailed-beast seal 1-9 (ours: equal; Ten-Tails only from its own drops). Only mixed packs differ
  now (26 "Card and Seal", 219/220 one of shinobi / gold). Checked in game via the Award Center: drop 174 -> Ten Tails Seal Fragment 5,
  drop 16 -> Moegi (1-star shinobi).
  Lucky Wheel checked in game after the switch: free spin -> Gold*210 card, no errors.
  Border war target switch now checked in game: wander at Water, then Fire -> the original "You are already at Water border ... Want to wander?" dialog, Confirm -> Fire Wander 30min, Fire monument 300 -> 295, Water station ended. (The Border building is on the left of the Home map; its tap area is the stone's lower half.)
