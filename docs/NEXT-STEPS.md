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
