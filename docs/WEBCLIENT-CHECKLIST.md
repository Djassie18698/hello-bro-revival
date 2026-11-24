# Web version: the full list

Everything the Android game has, and where the browser version (`server/webclient`, opened at `/play/`) stands.
Goal (owner, 12 Nov 2026): the whole game in a browser, so iPhone players can play again.

**13 Nov 2026: a second, better route exists.** `server/webclient/emu` runs the original app itself in the browser (an ARM emulator), so every screen below comes for free once its open points are done (sound, typing, files, iPhone memory and speed: see `server/webclient/emu/README.md`). This list stays as the plan for the hand rebuild, the fall-back.

✅ works · 🟡 partly · ⬜ not yet · 🚫 not planned. "C++" = had to be rebuilt by hand; "Lua" = the game's own script runs, it only needs the helpers it calls.
Update this file with every round of work. How it is built and the rules found: `server/webclient/README.md`.

## 0. Foundations

**21 Nov 2026 (owner: "port it over, make it HD and modern"):** every picture is redrawn at double size (`tools/build_hd.js`, Real-ESRGAN; `?hd=0` shows the originals), on a wide PC window the game stands on a stage with side panels (`stage.js`), and Shop, Spar, card upgrade, Arena and Battles were added. **PC frame (21 Nov 2026, later the same day):** on a wide window the game stands between two wooden columns: left the player and a menu with the game's own buttons for every screen that exists (one click from anywhere, the open one marked), right the server, today's times and events and the strongest players; keys (Esc back, 1-6 bottom bar, F full screen), mouse wheel on lists, full screen, and the page installs as an app (manifest + a service worker that stores nothing). Phones are unchanged. Details: `server/webclient/README.md` (stage.js). Open points for the look: a real landscape layout of the game's own screens (they are all tall layouts: it needs a second arrangement per screen, not done), the phone's own card-turn and upgrade animations.

| | Part | Notes |
|---|---|---|
| ✅ | Game files for the browser (`tools/build_webclient.js`) | sprite sheets, layouts, fonts, texts, tables, Lua scripts |
| ✅ | Drawing engine (`engine.js`) | sprites, 9-slice, labels, bitmap fonts, buttons, scroll views, layout timelines |
| ✅ | Lua 5.1 engine (`lua.js`) | checked against real Lua 5.1 |
| ✅ | Bridge for the scripts (`luabind.js`, `gamebind.js`) | cocos classes, CCBProxy, table views, actions, HTTP, XML |
| ✅ | Requests like the phone (`net.js`) | same server, same accounts |
| ✅ | Player data kept like the phone (CPlayerDataMgr): cards and teams (data.js), the items you hold (game.loadItems, CTradeMgr for the scripts; loaded before every script screen and, since 22 Nov, before Home's script windows too), fragments (Backpack) | |
| ✅ | Card / item pictures and frames (CGameObjElement, data.js): icons, quality frames, stars, element marks, the reborn corner marks, what a drop pack holds (ShowDropByID) | the sweeps over 70 script screens report no C++ name missing |
| ✅ | Common windows: confirm (CommonDialogView) and "you got" (ours: the card fades in, the phone turns it over) in shop.js (HB.dialog, HB.confirm, HB.showCards); the game's own "buy this first" window (CommonBuyItemDialog, script) and the recruit window (CCommonPrayDialogView); an item's details = the drop window (ShowDropByID) | used everywhere |
| ✅ | Level-up window (PlayerLevelUpDlg): pops up when your level went up (old and new level, attack, defence, team size from the playerlevel table; "new team slot" and the every-10-levels gift button), with its sound (extras.js) | its light rays are tried, not checked against the phone |
| ✅ | Loading picture (the game's spinner, LoadingView, while a request runs; it comes after 0.3 s so quick answers do not flicker: ours), time-out window (TimeOutDialogView with Reconnect: a request the server does not answer waits for it and is sent again), the notice with the speaker (NormalNotice: the server's bulletin, from level 5, once per browser), the running-ninja loading box of the first load (system.js; `&sys=timeout`, `&sys=notice`, `&sys=loading`) | not built because v28 never shows them (no caller in re/all.txt): the system notice window (sub_ui/SystemNotice), the "no touch" time-out window |
| 🟡 | Sounds and music (sound.js): button tap, music per screen like the game's bgSoundConfig (home, Training, Spar / Plunder, Arena, fight), Victory / Defeat, level-up, "you got", card clash; music and effects switches in Settings, remembered; `?mute=1`; silent until the first tap | checked in headless Chrome (files load, play is called), not yet by ear; the War tab's music waits for the War screen (`HB.sound.screen('war')`), Training's run / coin / exp sounds and the slot machine's own files not yet |
| ✅ | Top banner: the horn bar on every screen runs through the game's own sysnotice table like the phone (CMainMenu::NextAnnounceMsg), with the Server Manager's announcement first (ours); the scripts' marquee (ui_borderWarTip.lua, `rl_r_marquee`, MarqueeTipView) runs too and lies on the same bar (system.js) | the two Chinese rows of the table are left out (ours); speed by eye; our server sends no marquee messages, tried with made-up ones |
| ✅ | Glowing names (our hot update, util/common.lua PurpleGlow): the No.1 Shinobi list glows by its own script, the top bar's name on every screen is handed to the same script (system.js asks `rl_r_purplename` when Home opens) | no engine change was needed; the sparkles are the script's own |
| ✅ | Custom events (ours): the owner's own events from text files, screen + Home button (custom.js, `docs/CUSTOM-EVENTS.md`) | not in the phone game |
| ✅ | Text that fits (ours): labels shrink to stay clear of each other and the screen (fit.js; a window or a second script screen laid over a screen is fitted on its own since 22 Nov), wording and places per layout in texts.js (TIDY), pictures with Chinese words have English versions (pictures.js) | owner: "all text should match the boxes"; checked by `js-screens.js` (no Chinese text left on any screen our server shows) |
| ⬜ | Online for players: game files on the cloud machine, `https://ninjaonlinereborn.com/play/` through Caddy | owner's OK needed |
| ⬜ | iPhone app shell (like Ninja Panel) around `/play/` | after it is playable |
| ⬜ | Tried on a real iPhone (Safari, Add to Home Screen) | |

## 1. Getting in

| | Screen | Kind |
|---|---|---|
| ✅ | Login screen (moon, START, account, region) | C++ CLoginScene |
| ✅ | Account: guest, log in, sign up | the app's Java window; ours is a small form |
| 🟡 | Region list | taps step through the regions; the phone has a list window (ServerSelector) |
| ✅ | Create character: country, ninja, name | C++ |
| 🚫 | Logo / loading scene, update window | not needed in a browser: the page loads the game files itself and updates arrive with the page |
| 🟡 | Game settings: music, effects, Discord link, invite code box (the game's own script, extras.js `HB.screens.settings`); Bind account (BindAccountView) not yet | C++ + Lua ui_gameSettingLayer |

## 2. Main menu and the core screens (C++)

| | Screen | Layouts |
|---|---|---|
| ✅ | Home: top bar, village, buildings, level locks | MainMenu, DefaultMainMenu, <Country>CountryDefaultMenu |
| ✅ | Home: team cards row with arrows | MainCardView |
| ✅ | Home: the village is a wheel of six buildings (Base, Cross, Noodle, Border, Shop, money tree): swipe to turn it, tap to open (base.js; how far a swipe turns it is by eye). All six open: Noodle and the money tree are JavaScript screens, Base, Secret shop, Cross-server battle and Border war the game's own scripts (luascreens.js `luaBuilding`) | CDefaultSLGMenu, <country>CountryDefaultMenu |
| ✅ | Home: red number bubbles: on Event the count the scripts set (CPlayerDataMgr:SetActivityNewsNum), on News the unread battle reports and friend messages (rl_r_msg 1800 / 1801 / 1802, asked when Home opens) (system.js) | |
| ✅ | Player info window (tap the top bar on any screen): level, exp, attack / defence / chakra, gold, silver, W.A., team, VIP, energy and grudge with their clocks, the list of ranks (extras.js) | PlayerInfoDlg, meritRankCell |
| ✅ | Bottom bar | all six buttons open their screens |
| ✅ | **Team** (team.js): the places with the server's numbers, chains running / all, the "chain misses a partner" strip; tap the shinobi = its window with Change, tap a slot = choose a card or the card's window with Change / Remove (weapon, armor, trinket, seal, four ninjutsu); Team 2 from level 100, Activate with the tick, Detail window, the two set buttons (the game's own Lua windows), the locked next place with Go Train, the set place. Every change was done with real taps on a guest and compared with the server | ListMyTeamView, TeamNinjaView, TeamNinjaSuitView, TeamNinjaTipView. The set windows close on any tap (their own X does not get taps here); the set buttons' coloured pictures (suit.plist) are not found, they show the grey / lit default |
| ✅ | **Backpack** (bag.js): the six card tabs with Level up and details; a tap on a row turns it over to its tip with Go shopping / Go training, sparring, plundering (packtips); Fragments tab (shinobi / gear / ninjutsu / pet) with Merge (rl_w_comm Cmd 10, the new card is shown), the tip to the Secret Shop, red dots where something can be merged | MyBackpackView, gameobjlist/*, BackpackTips, Backpack*Piece. v28 has NO selling and no soul / element / inherit / split buttons on a row (not in the app's row code; no server request): nothing to port. Not done: the red dot on the bottom bar's Backpack button (game.js), Top-up button |
| 🟡 | Card details (tap a card's picture in the Backpack): shinobi (the game's own page: big card, story, chains, growth and rebirth rows), gear, ninjutsu, seal with its five element rows (details.js); opened from the Team screen with Change / Remove, the server's totals and the running chains in red; pets and the gear set window not yet | NinjaDetailView + NinjaSubView, EquipDetailView, NinjasuDetailView, MarkDetailView + MarkInfoDetails, PetDetailView |
| 🟡 | Upgrade a card (feed cards): the card, material grid, Select all 1-2 star, exp and silver from the game's tables (upgrade.js); the phone's process and "complete" animations not yet | upgrade/CardUpgradeView, UpgradeNinja, UpgradeMeteriaInfoCard |
| 🟡 | Growth (sage steps of a shinobi): stones, 1-4 at a time, extra stones, chance and silver from the game's table (growth.js); Auto-Growth (tick box, "Stop at step N", Cancel), the Growth bonus panel and the burning rings; compared with the phone 24 Nov; the result animations not yet | sub_ui/StrengthView |
| 🟡 | Train (potential): limits, pill / gold, once / 10 times, the roll and Keep (growth.js); the animations not yet | sub_ui/Potential* |
| 🟡 | Reincarnate: with a second copy of the card or with pills, what the next rebirth gives (growth.js); the animation not yet | sub_ui/ReincarnationView |
| ✅ | Seals: list, merge (start, clock, finish now for gold, take the seal) - part of plunder.js | MarkListView, MarkMergaView |
| ✅ | Ninjabook (collection): Ninja / Gear / Ninjutsu tabs, 4 across like the phone, cards you hold in their quality frame, the rest grey (ours), tap = the card's window (book.js) | GameObjBookList, GameObjBookCard |
| ✅ | **Training**: chapters, stages, parts; a story row turns the wheel (the part the server chose, then what the row gave), a boss row is a fight; rows before the open one read Finish, a finished stage keeps GO on its boss | ChapterView, SubChapterListView, SubChapter, dlg_ui/RunLevelTurnable |
| 🟡 | Training extras: boss tries (3 a day; at 0 the game's orange button with the 10 gold price, asks first, pays), the EXP card's "EXP * 2" and clock on every row, no energy opens the ramen stall, a notice when a chapter is finished (the game's message window with its own words). Not there because v28 does not have it: the chapter-complete window (never opened by the phone, its pictures are not in the game files, its rewards were never paid) and a Training sweep (only the tower has a sweep, a Lua screen). Open: the server always answers "no EXP card running" in the stage list, so the clock only shows with the test switch `&expbuf=<seconds>` | ChapterCompleteView, SweepRewardDlg* (tower) |
| ✅ | **Fight** playback: the opening flash, cards in the frame of their stars, a grown card's glow, numbers that run, Skip; every kind (Training boss, Spar, Plunder, Arena, tower, War, and the fights the scripts start: World Boss, No.1 Shinobi, Ninja Test through `CFightResultData` / `CRoundFightView`) | RoundTeamView, CoreFightCardView |
| ✅ | Fight extras: ninjutsu cut-in (the ninja slides through, the ninjutsu's name, its bonus) and the ninjutsu's own effect, "Skill bonus", element restrain ("X beats Y" picture, "Constrain damage"), my pet's badge and its skill (glow, jump, claw), "+N" / "-N" off the cards, the blade and the red flash of a hit, the Lose stamp. By eye, not compared with the phone: the restrain picture's drop-in (its timeline is empty in the game file), where the claw lands (not seen in a picture after the last fix), which card wears the boss mark, the country flags | CoreFightSkillView, RestraintView, ShowEffectView, ShowRayView, PetSkill_ef |
| ✅ | Victory screen: the three prize cards (the one you tap turns over with its picture, stars and name), and its own part for each kind of fight (Training, Plunder, War, Arena with the old and new place, World Boss, tower with its prize, the plain one); a prize outside Training shows in the "you got" window. Team compare is hidden (not built) | NewFightResult_WinView, RS_WinAnim |
| ✅ | Defeat screen: the five help buttons open Recruit (Shop), Level-up (card upgrade), Strengthen (the Backpack's gear), Growth, Reincarnate; Team compare is taken away (not built) | NewFightResult_FailView |
| ✅ | Team compare: the Compare button of the Victory and Defeat screens lays the list into the result (my card left, theirs right, per place: picture, element, level, attack, defence, chakra); the button brings the result back (ours) (system.js; `&sys=compare`) | NewTeamCompare, TeamCompareItemView. The numbers are the cards' own table values at their level (ours: the reply does not carry them). The phone has no compare window on the Friends / Arena / Spar lists (dlg_ui/TeamCompareView is never created in v28) |
| ✅ | **Spar** (fight other players): list, preview, fight (spar.js); search not yet | FightListView, FightNinjaView, FightPreView |
| ✅ | **Shop**: Recruit (3 scrolls, free timers, once / ten times window), Giftpack, Tool with Buy and Use (shop.js), the VIP tab (the game's script: VIP bar, VIP benefits, a VIP gift bought on 22 Nov), Top-up (the game's script) | StoreItemsView, StoreGoodsView, StorePacksView, StoreNinjaView, PrayDialogView, VipListView |
| ✅ | Top-up list and confirm (free on our server) | PurchaseListView, PurchaseItemView, PurchaseConfirmDialogView + Lua ui_purchaseLayer |
| ✅ | **Plunder** (seal fragments): the seal list, rivals with the chance word from the game's plunderinfo table, preview, fight (plunder.js) | PlunderListView, PlunderNinjaView, PlunderPreView |
| 🟡 | **Arena** (ladder): rivals with teams, Challenge, daily place reward, Rank tab, cooldown clear, Exchange tab (reputation shop with its daily / total limits) (arena.js); rules window and lucky rank not yet | ArenaViewNew, ArenaCellViewNew, ArenaExchangeCellView |
| 🟡 | **Battles** (tower): the phone's scrolling map, the Level Cleared reward window, a floor's seven rounds, fights (tower.js); Sweep is the game's script and was played (v28 hides its button); **Ranking** window (24 Nov): Ranking tab (top 100: gold numbers for the first three, first card, level, name, rounds) and Achievement tab (a reward per floor, claimed for real in the test). compared with the phone 24 Nov. Open: the little ninja animation on the map | TowerView, TowerLevelView |
| ✅ | **War** (country war, Home > War building; war.js): Country (the 7 seats, Match = take an empty seat or fight its holder, the gift bag of your own seat), War (scores, clock, Attack with the fight, the 3-attack wait + Clear, buy revives, Auto-Attack window, the three "?" windows, news line + your own fight lines as in the phone photos), Reward (exploit shop), Ranking (Individuals / Nations). Not done: the "Last Battle" result chest (the server never opens it); with Auto-Attack on, the server attacks every 20 s and the screen reloads (the phone attacked by itself while open) | countrywar/* (14 layouts) |
| ✅ | **National treasure** (war.js; `&open=treasure`; reached through `ChangeToSub(E_COUNTRYTREASURE)`, level 45 lock from functionconfig 6): numbers, Defend on/off, Contribute (silver + exploit), Plunder window with the four other countries, the fight against a guard or a free grab, the 1-hour wait and its 15-gold skip. Not done: the reward animation layer (layer_anim); no Home building leads to it yet | countrywar/CountryTreasury, SnatchDialogView |
| ✅ | Ramen shop (the Noodle building): eat to fill energy and grudge (base.js); the steam animation not yet | RamenView |
| ✅ | Money tree: rules, free and paid shakes, what the tree dropped (base.js); the phone's own shake animation and the list of winners not yet | MoneyTreeView |
| 🟡 | News: Battle reports (Ignore, Revenge), Friend messages (Reply), System note (social.js); a message is typed in the browser's own box | social/MessageListView, FightMsgView, FriendMsgView, SystemMsgView |
| 🟡 | Friends: every player with team numbers, leave a message, search by name (social.js); the phone's invite and chat windows not yet | social/Friend* |
| ✅ | Event screen frame: the strip of event icons with its arrows and the place where the chosen event's script puts its layer (luascreens.js `changeToActivity`) | activity/ActivityDefaultView, ActivityBarCellView |
| ✅ | Roulette turn window (the ten-draw result window, gamebind.js). 🚫 Lottery view (activity/LotteryView): the screen of the old event "lotteryActivity", whose script v28 does not have (the Lottery ticket event of today is a script screen, section 3) | activity/LotteryView, RouletteTurnDialogView |
| ✅ | Daily ads: the next-day line ("Come again tomorrow, and gain 110 gold ...") in the running-ninja loading box, on the first login day only, like the phone (system.js; `&sys=ad` shows it on any day) | activity/NextDayAd. activity/DaysAd is never created in v28 (no caller in re/all.txt): not built |
| 🚫 | Tutorial | off for everyone on our servers |

## 3. Lua screens (the game's own scripts; each needs its helpers to exist)

**21 Nov 2026:** the two frames these screens live in are built (luascreens.js): the Event screen (icon strip + the event's own
layer) and the empty sub menu the helper functions fill (ShowRouletteView, ShowOrgView, doShowBase ...), plus the Home buttons and
village buildings that lead to them, and the C++ helpers they asked for (the player's cards as objects, items held, VIP level, what a
drop pack holds, the Event card view). `node tools/dev/lua-screens.js` opens 57 of them one after another and reports Lua errors and
missing C++ names, with a picture of each in re/lua/: 49 open without an error. The rest are not client faults: the event is off on
the test server (gold spending), an event our server never had (level rank, fight rank) or that v28 cannot run (collect cards), a script v28 does not have (lotteryActivity),
the wheel's last prize has no drop row (same on the phone), Ninja inherit needs a card. 🟡 below = opens and draws like the phone;
its buttons and what they pay out are NOT all tried yet.

Home buttons and windows:

| | Screen | Script |
|---|---|---|
| ✅ | Middle button row | MenuBtnsView |
| ✅ | Left event buttons | mainActivity, ui_mainActivityBtn |
| ✅ | Event window (icons) | ui_activityPopupLayer |
| ✅ | Daily Task | dailyTask_business, ui_dailyTaskLayer |
| ✅ | Save time (EXP card): Gain played at level 81 (ramen used, exp and silver in the save, the count follows), Buy opens the "buy this first" window | saveTime_business |
| ✅ | 1st Recharge | firstMoneyAward |
| ✅ | Growth fund: bought as VIP3+ (500 gold, the rows turn to Collect; below VIP3 the game's own refusal) | growthfund_b |
| ✅ | 7-day goals | sevenDay_business, ui_sevenDayView |
| ✅ | Receive (stage gift): opened, Claim tapped: 10 000 silver and the three items in the save, the button reads "Claimed" after | ui_stageGiftLayer |
| ✅ | Awards (Award Center mail) | ui_awardCenterLayer |
| ✅ | Hall of Fame (No.1 Shinobi) | ui_hallOfFameView |
| ✅ | Settings (switches, Discord button and close tried; the invite code box not) | ui_gameSettingLayer |
| ✅ | VIP list (the Shop's VIP tab: your VIP bar, the VIP gift packs): VIP1 gift bought (gold paid, items in the save), "VIP benefits" opens and closes | VipListView, ui_vipRightInfoView |
| ✅ | Top-up window | ui_purchaseLayer |

Events (Event window and left column):

| | Event | Script |
|---|---|---|
| ✅ | Login gift | loginPackActivity |
| ✅ | Sign-in (login streak) | keepLoginView |
| ✅ | Level-up gift | upradePackActivity |
| ✅ | Monthly sign | monthSign_business |
| ✅ | World Boss | played on a private server copy with its clock at 14:01 (`sh tools/dev/private-server.sh 14:01`): a hit plays and ends on the phone's result screen (Defeat with the silver earned; the win screen is the "Final kill" picture and only the killing hit gets it: server corrected), heroes ranking with country icons, rank reward claimed, a reputation prize exchanged. v28 has no dice: its place is the Enhance window, which opens, but **the server's Enhance is an empty answer** (pays nothing, adds nothing: never built) |
| ✅ | God Recruit | godRecruit_business (5 layers) |
| ✅ | Monthly Card: both cards shown; a card starts with a free top-up of its price on our server (the Buy button says so, ours) | monthCardActivity |
| ✅ | Flower Worship | nvshen_business |
| ✅ | Diligence gift: list with today's counts; Claim without the fights done = the game's refusal "Not qualified" (a claim with the fights done not played) | diligenceGift_business |
| ✅ | Lottery ticket: random numbers, bet with the confirm window (50 gold), "Your bets" and "Last winner" windows; its Chinese pictures are English now | lotteryTicket_business |
| ✅ | Scratch card | ScratchCardActivity |
| ✅ | Treasure chests (box open) | boxOpenActivityView |
| ✅ | Group purchase: a pack bought (gold paid, items in the save, the stock counts down) | limitedGroupBuy_business |
| ✅ | Daily spending gift (claimed), Recharge streak (day 1 claimed), Total recharge (opens; needs $240), Gold spending (3000 gold spent, first gift claimed: god card + ninjutsu + pills in the save). 🚫 rand pay (rebate wheel): the server answers "not implemented", not possible in v28 | dailyPay, keepPay, randPay, accumulateMoney, consumption |
| ✅ | Limited discount (Time limited GiftPack: claimed after a top-up), Hot Treasure (free hunt played; the two buttons read "One hunt" / "Ten hunts"). 🚫 daily restriction: the server answers "not implemented" (v28's layout lacks its nodes) | limitDiscount, dailyRestriction, hotTreasure |
| ✅ | Festival trades (Christmas): Buy opens the buy window and a Christmas Cap was bought (the button did not react to a real tap before: its two watching layers do not swallow the touch), Exchange without enough items = the game's refusal | festival_business |
| ✅ | Lucky Wheel (roulette) + ranks | ui_rouletteLayer |
| ✅ | Millionaire (dice) + ranks | ui_monopolyLayer |
| ✅ | Mora | moraView |
| ✅ | Slot machine | ui_slotMachineLayer |
| ✅ | Super Ninja (limited) + ranks | ui_limitSuperNinjaLayer |
| ✅ | Ninja Treasure (sudoku) | ui_ninjaTreasureLayer |
| 🚫 | Collect cards: cannot run in v28. Its layouts (CollectCardTableView, CollectCardView) lack the nodes the v28 script writes to (label_remain_time, label_card_lv_N), so the script stops on the phone too, and our server has no such event (rl_r_comm Cmd 1 answers empty) | collectCardActivity |
| 🟡 | Level rank, Fight rank: our server never had these two events (rl_r_comm Cmd 2 answers empty, no switch in the Server Manager). The game's side works: with made-up replies (`node tools/dev/play-fake.js`) both lists draw, the rules and gift windows open, texts tidied. Open: the server side (a new feature: owner's word and reward numbers needed) | levelRank, fightRank |

Features:

| | Feature | Script |
|---|---|---|
| ✅ | God card synthesis (evolve) | ui_godCardSyntheticLayer |
| ✅ | Limit training (Dun) | ui_limitTrainLayer |
| ✅ | Soul training / Eight Gates | secret_shop/ui_trainSoulLayer |
| ✅ | Secret shop | secret_shop/ui_secretShopLayer |
| ✅ | Breakthrough | ui_tupoLayer |
| ✅ | Ninja inherit: played (section 3a); v28 itself has no button that leads to it | ui_ninjaInheritLayer |
| ✅ | Attribute pills (element change): played through Shop > Tool > Use (section 3a) | ui_attributeDanLayer |
| ✅ | Advance gear | ui_advanceEquipLayer |
| ✅ | Gear sets, colour sets, level sets: both windows open from the Team screen's two set buttons and show the sets (they only show, nothing to press but close) | ui_colorSuitView, ui_levelSuitView |
| ✅ | Pets: list, main, train, upgrade, advance, summon | ui_pet* (7 layers) |
| ✅ | Ninja Test (exam) | ui_ninjaTestMain |
| ✅ | My Base | ui_myBaseLayer |
| ✅ | Akatsuki (guild): list, create, join, hall, donate, shop, map, members, ranks, leave (played with two guests, section 3a) | ui_org* (22 layers) |
| ✅ | Border war | two guests on a private server copy with its clock in the open hours: Wander and Taunt (the confirm window, silver / gold paid, monument loses HP, the running line), the other guest opens Clean, fights the wanderer (the fight now plays: `ShowArenaView(reply)`), win window, daily reward claimed, rankings, damage list. "Wander does nothing" was the confirm window opening and closing on two taps. Server replies corrected (phones too): stay times count up, a rewarded clean says what it earned, damage list times and names, Home's running-line request |
| ✅ | Cross-server battle: played on a private server copy in the battle hour (section 3a); Exchange and the top-10 reward not tried | multi_battle/* (14 layers) |
| ✅ | Cross roulette / millionaire / super ninja: on our one-world server the same events as the normal ones; opened directly: wheel turn, dice throw, rank windows (section 3a) and, 22 Nov with Super Ninja switched on, a free and a gold draw on the cross Super Ninja screen (card in the save, points and rank follow) | ui_cross* |
| ✅ | Change country: played through the Immigration Card (section 3a) | switchCountry |
| ✅ | Tower sweep: played (section 3a; v28 hides its button). 🚫 split card and re-new level: v28 never opens them (no caller in the app) | towerSweep, ReNewLevel, SplitCard |
| 🚫 | In-game news list: v28 never shows it (the script's own showInGameNoticeView has its body commented out, "inner notices closed for now"; CMainMenu::ShowActivityNews runs an empty function) | InGameNoticeListView |

## 3a. Played through (22 Nov 2026)

Every row was played with real taps in muted headless Chrome (`node tools/dev/play.js`: one browser stays open, `ui` lists what is on
screen, `tap` / `click` press it with a real mouse click, `log` shows the requests and Lua errors; `tools/dev/play-save.js <uid>` prints
the guest's save to compare before and after). ✅ = works to the end and the save changed; 🟡 = partly; ⬜ = not played.
What was wrong almost everywhere: taps went to "what lies on top" instead of the phone's touch order, so inside a window with its
own tap-catching layer the X, the arrows, list rows and row buttons did nothing (the tester's `--press` calls the button directly and
never saw it).

| | Feature | What was played, what is left |
|---|---|---|
| ✅ | Login gift | day 1 claimed: "You got" window, items and silver in the save; the list keeps its place after a claim (was jumping to the end) |
| ✅ | Sign-in (login streak) | day 1 claimed, save changed; the list now starts at the top (it opened at the bottom) |
| ✅ | Level-up gift | level 10 pack claimed: items, silver and gold in the save |
| ✅ | Monthly sign | day 1 tapped: 10 000 silver |
| ✅ | Daily Task | chest window opens from the chest row, Receive reward pays, the X closes (none of the three reacted to a real tap before: touch order). Go buttons of unfinished tasks not tried |
| ✅ | 7-day goals | day 1 claimed: card + silver |
| ✅ | 1st Recharge | claimed from the Top-up window after a top-up: three cards |
| ✅ | Award Center mail | a mail sent from the admin page claimed with Claim; a single mail now stands at the top of the list |
| ✅ | Top-up window | a row tapped: gold arrives, VIP bar and the top bar badge change, VIP benefits list opens and closes (rows did not react to a real tap before) |
| ✅ | Lucky Wheel | free turn, ten paid turns (the ten-draw result window is new: CRouletteTurnResultDialogView), rank window opens |
| ✅ | Millionaire | one throw and ten throws, rank window |
| ✅ | Mora | rounds, Bound to Win, a rival beaten, chest exchanged for luck. Server fix: the rank list was not a list (a Lua error per field, on phones too) |
| ✅ | Slot machine | bet, spin, win window. Server fix: the reels and prize rows were empty (wrong reply shape and picture names, on phones too); the shown price is now what a spin costs |
| ✅ | Ninja Treasure | one Explore: the square is ticked, silver paid |
| ✅ | Super Ninja | free draw, gold draw once and ten times through the recruit window (new: CCommonPrayDialogView), points and rank follow |
| ✅ | Scratch card | a whole card scratched, win window, gold in the save |
| ✅ | Treasure chests | a chest opened for gold: "You got" |
| ✅ | Flower Worship | flowers after a top-up, 40 given: card and items (event switched on in the dev save for the test) |
| ✅ | God Recruit | spin, Remain: the god card is in the save; the win card now shows the big picture (event switched on for the test). Exchange and Return not tried |
| ✅ | My Base | the four buildings open by tapping them; level tips now show (every script tip with time -1 was invisible) |
| ✅ | Pets | list with pictures, names and skill texts, level up, train, advance, a helper put into the array (new: CPlayerPet, CCProgressTimer). 22 Nov (second round): **Summon** = Backpack > Fragments > Pet > Merge (30 fragments: the pet is in the save), **set as master** = the middle place of the array > select (the old master steps out) |
| ✅ | Ninja Test | crew picked, a whole exam fight played to the Defeat screen and back, Exchange list and one exchange. The server's refusal of a god card in the crew shows no words (code 8000 has no text in the game) |
| ✅ | Breakthrough | god card picked from the list (cards were drawn as tip rows), one breakthrough: level, fragments and silver in the save. The list shows the attack numbers also for defence and chakra |
| ✅ | Advance gear | two swords picked, advanced: rebirth 1, material gone, result window |
| ✅ | Soul Disenchant (ui_trainSoulLayer) | shinobi added, picked by hand, disenchanted: souls in the save, result window (it stopped with an error before) |
| ✅ | Eight Gates (Dun, ui_limitTrainLayer) | one gate opened: souls and silver paid, attack +15 |
| ✅ | Secret shop | one exchange for souls: "You got", item in the save. Refresh not tried |
| ✅ | Evolve | attack + defence card + 100 pills: the god card (the reborn mark GetFrameDragon was missing) |
| ✅ | Element change | opened the phone's way: Shop > Tool > Use on the Element Change Pill (CItemView::onBtnUseIt, item kind 16); card picked from the list, Change: pills and silver paid, the card's element changed in the save. The Tool list now also shows what you hold that the shop does not sell (it hid the pill) |
| ✅ | Inherit | played with a card outside the team as the source (`ShowNinjaInheritView(card seq)`): destination picked, confirm, level and growth moved, gold paid. **v28 has no way into it**: the only caller is CMyBackpackCardView::ninjaInheritClick, a Backpack row the app never builds (it uses CGameObjCardView), so no button leads there here either |
| ✅ | Change country | Shop > Tool > Use on the Immigration Card opens the game's own window (switchCountry.lua): price asked per country, change done, card and gold paid, top bar filled again. Wind is offered by the window but our server only knows countries 1-4 and refuses it without words (code 8000) |
| ✅ | World Boss (first round of play) | the fight plays, damage, rank and reputation follow; the result screen, the rank reward and a reputation prize were played in the second round (Events table above) |
| ✅ | Hall of Fame | Challenge on another player: fight and Victory screen. Your own row does nothing (same on the phone) |
| ✅ | Akatsuki | two guests: create (name typed), the other joins from Check > Apply, member list, hall task, donate gold, shop purchase, rankings, Flee. On our server Apply joins at once, so the Approval list stays empty; Setup, level up, deport and duties not tried |
| ✅ | Border war (first round of play) | "Wander does nothing" was the confirm window opening and closing on two taps; played to the end with two guests in the second round (Features table above) |
| ✅ | Cross-server battle | ticket bought in the sign-up days; on a private server copy in the battle hour (`HB_CWAR_PHASE=2`): morale boost, Challenge on a ladder place (fight, Victory, the place is yours, points tick), score ranking, Merit / Betting / Description tabs open. Exchange and the top-10 reward not tried |
| ✅ | Cross-server wheel, Millionaire, Super Ninja | on our one-world server they are the same events as the normal ones (same requests) and no button leads to them; opened directly: a paid wheel turn, a dice throw and both rank windows work; cross Super Ninja opens (its event was not running) |
| ✅ | Eight Gates soul training (ui_limitTrainSoulLayer) | Normal training, both Multiple buttons, Collect: souls in the save (50 x 4 = 200) |
| ✅ | Tower Sweep | the game's script (towerSweep_business.lua): rounds picked, Determine, reward window, gold paid. The list reply was wrong (every round stamped "done today", none could be picked: corrected). **v28's tower layout hides the Sweep button** (never shown by the app), so it stays hidden here; run it with `HB.luaRun('business_proxy/towerSweep_business.lua')` |
| 🚫 | Split card (SplitCard.lua) | v28 never opens it (its only caller is the unused Backpack row CMyBackpackCardView::splitClick) |
| ✅ | "Buy this first" window (CommonBuyItemDialog) | opens when silver or fight points run out (Advance gear, Change Element, Eight Gates, Border Clean, No.1 Shinobi): Buy and Use change the save, the count follows. It could not open: the item id constants (SMALL_COIN_ITEM_ID ...) and CTradeMgr:UseConsumeItemByID were missing |
| ✅ | Slot machine > Exchange | the list shows its three packs, Claim pays, the row turns to Claimed (server: the list reply had the wrong shape, every row was a Lua error) |
| ✅ | Stage gift (Home > Receive) | 22 Nov: Claim tapped, 10 000 silver + 5 large ramen + 5 recruitment orders + 10 refresh orders in the save |
| ✅ | Gold spending | 22 Nov, event switched on for the test (`node tools/dev/play-events.js on consumption`, `back` after): Claim before spending = the game's refusal; after 5 600 gold spent the 3000 gift paid a god card, a ninjutsu and pills |
| ✅ | Cross Super Ninja | 22 Nov, Super Ninja switched on for the test: free draw, gold draw through the recruit window, points 10 and rank 1 |
| ✅ | Slot machine | 22 Nov again: a 100-gold spin, the reels stop on the server's three faces, score follows |
| 🟡 | Level rank, Fight rank | only with made-up replies (our server has no such events): lists, rules window, gift window |
| ✅ | Group purchase, Limited discount, Daily spending, Recharge streak, Hot Treasure, Growth fund, Lottery ticket, VIP gift, Festival Buy, Save time | 22 Nov, one action each with real taps (events switched on for the test and back): every one changed the save. Two faults found and fixed on the way: the festival's Buy button never got a real tap, Save time's Gain said "no ramen" and then stopped with a script error |

**Closing round (22 Nov, evening):** every ⬜ and 🟡 row of this file was checked against the code and played where it could be (rows above). What is still open is written in its row: the three "online / iPhone" rows (owner's OK), the animations of the card screens, a few C++ windows (region list, Bind account, pet details, Arena rules, tower ranks, the phone's invite and chat windows), sounds not checked by ear, and the Level / Fight rank events, which our SERVER never had. One server fault found and NOT fixed here (server files were not part of this round): Akatsuki > Rankings > Check opens the details window with sample texts and "Parameter error", on phones too, because `rl_r_group_rank` rows carry no `groupid` (server/guild.js `rankXml`: add `groupid="${g.id}"` to each `<group>` of the list). Tools of this round: `tools/dev/play-tour.js` (every window of a screen), `play-first.js` (one action on many events), `play-events.js` (events on for a test and back), `play-fake.js` (made-up replies for the two rank events), `sheet-view.js` (a sprite sheet's frames), `tools/make_webclient_en.js` (the English pictures; before / after board `re/en/board.png`, screens `re/en/before-*.png` / `after-*.png`).

Sweeps after the closing round (22 Nov, late): `lua-test.js` OK; `lua-screens.js`, `--press` and `--tap` = 64 of 70 screens open without an error, no C++ name missing, no list tap with a problem, the same known presses as below; `js-screens.js` = no Chinese text on any JavaScript screen, and of the script screens only the old recharge-history event.

Last sweeps (22 Nov, after all of the above): `lua-screens.js --press` and `--tap` = 64 of 70 screens open without an error, no C++ name missing, no list tap with a problem. The six are not client faults (event off on the test server: level rank, fight rank, collect cards, gold spending; a script v28 does not have: lotteryActivity; Inherit opened without a card). Presses that still report: Super Ninja's arrows while its event is off, and Back on screens the tester opens without the entry the phone gives them (Advance gear, Pets).

## 3b. Text polish (21 Nov 2026: "all text should match the boxes")

How it is done: `server/webclient/fit.js` shrinks what runs into a neighbour (another label, an icon beside it, the screen's edge),
`server/webclient/texts.js` lays our own texts over the game's tables (buttons found by name, layout labels, the scripts'
`localizable` texts, small moves per layout, and since 22 Nov `TIDY`: rules per layout kept true while it is on screen, for texts the
scripts write after a reply: a sentence's words and numbers next to each other, shorter words, size, wrap, edge; `node tools/dev/play-dump.js`
lists a screen's labels with their names) without touching the game's scripts, and each JavaScript screen fixes its own
labels. Check everything again with `node tools/dev/js-screens.js [--lua] --tag=<name>`: a picture of every screen in
`re/js/<name>/` plus, per screen, the Chinese texts still showing and what fit.js had to shrink.

JavaScript screens (no Chinese text left; before / after pictures in `re/js/before` and `re/js/after`):

| | Screen | What was fixed |
|---|---|---|
| ✅ | Arena | the rows' frames had a hole that showed the background (9-slice with sides wider than its picture); "Reward:" clear of the card and the coin; tab titles; the note under Attacks today; Top-up out from under the 1st Recharge sticker |
| ✅ | Arena > Exchange | "Left today: 2" / "Left in total: 1" as one small label (was words with a hole and the number beside it, at 55 %); the Exchange button's word |
| ✅ | Shop | tab titles, "Free recruitment" clear of the star, the recruitment-order line no longer over the shinobi's picture, Top-up clear of the sticker; VIP tab: "VIP1 Honorable gift", "Top up $1 more to become: VIP1", the gift's contents above its price |
| ✅ | Spar | "Win:" |
| ✅ | Growth | Back / Min / Max; the Auto-Growth box that did nothing is gone |
| ✅ | Reincarnate | "Uses Reincarnation Pill or the same shinobi card" as one line; every number right behind its words; line 3 shows its number |
| ✅ | Level Up (cards) | the name clear of "Lv:" (moved up to the stars), Needs clear of the coin |
| ✅ | News | the red tag reads "System" / "Friend"; the message wraps before the Manage button |
| ✅ | Friends | level numbers readable on the card; long attack numbers shrink before the defence icon |
| ✅ | War | the three rows of numbers (Kills / Rank / War exploit ...), the news line whole inside its bar, capitals in the notes |
| ✅ | National treasure | the title reads "National treasure" (the country's sign moved to the end of its frame); "3000 silver", "Treasure Amount: 1" |
| ✅ | Ninjabook | tab titles |
| ✅ | Plunder | the "Plunder" tags on the fragments |
| ✅ | Player info | the rank list's titles no longer run into the W.A. numbers |
| ✅ | Settings | headings start inside the window, Music / Sound clear of their boxes, the Discord address inside its box, "Settings" |
| ✅ | Home | the Special button (custom events) stands in the left column under the last event button |

Script screens (the game's own Lua; before pictures in `re/lua-before`, after in `re/js/lua-after`): of all that `js-screens.js --lua` opens, only the old recharge-history event still shows Chinese text.

| | Screen | State |
|---|---|---|
| ✅ | every layout the scripts load | buttons the scripts find by name show the game's own English (Return, Evolute, Detail, Open, Recharge, Collect, Tips ...): they were Chinese on Evolve, Change Element, Growth Fund, Eight Gates, Dun, Inherit, Ninja Treasure, Lottery, Level rank, 1st Recharge, Group purchase, Recharge streak, Limited discount, Diligence gift, Save time, Cross-server battle, Akatsuki |
| ✅ | every button | a title that is too long is set smaller before the button grows over its neighbours |
| ✅ | 1st Recharge | the two paragraphs and the four prize names no longer run into each other |
| ✅ | Monthly Card | "$4.99 card" / "$9.99 card" on the ribbons |
| ✅ | Recharge streak | "Streak: day 1" on the ribbons |
| ✅ | Ninja Test, My Base, Hot Treasure | "Challenge", "Exam room", "Pets", "Ten hunts" |
| ✅ | God Recruit | Price / Now / Time left / Energy points (were Chinese) |
| 🚫 | Total recharge history (payhistorydrop) | gift names are Chinese in the script's own data file; an old event that is not in our server's event list, so no player sees it |
| ✅ | Lottery ticket | English pictures (pictures.js): title "No. 7 LOTTERY", the scrolls "BETS", "1st / 2nd / 3rd Prize", "This draw is at:", "Claim before:", the three red buttons of its windows; "RANDOM" stands letter under letter on the lever, "Bet 50 gold" |
| ✅ | Home | English pictures (pictures.js): "7-Day Goals" on the pouch, "TOP" on the rank scroll, "Lv.30" on the level gift button, "Lottery" on the Event bar's icon |
| ✅ | Growth Fund | the board reads "Pay 500 gold once, get 5 times as much back: 2500 gold" as two centred lines; the VIP line inside the board |
| ✅ | No.1 Shinobi list | a glowing name is its full size (fit.js took its stacked copies for neighbours; a sparkling name's copies stand further apart and were shrunk to 55 % again until 22 Nov); "Offense Points" / "Defense points" clear of the numbers; the twinkles of a sparkling name were pictures of a seal card (its HD copy was a wrong picture: pictures.js `NO_HD`) |
| ✅ | Daily Task | the chests' points ("30 pts") stand on the chest's foot in white, clear of the bar |
| ✅ | Lucky Wheel, Millionaire | "Reward Pool: 1010" side by side, "10 turns" / "Turn once" / "Ranking" inside their buttons, both sentences in one piece; Millionaire's greeting inside its banner, "Ten throws" |
| ✅ | Secret shop, Inherit, Limited discount, Mora | Secret shop: "Souls:", the four lines under Refresh each in one piece; Inherit: the rules inside the scroll, each caption ends at its number's box, "Choose" inside its button; Limited discount: item names on two lines; Mora: "Your lives:" / "Your luck:", "10 Luck level" inside the plates |
| ✅ | Change country, Change Element list, boss ranking | found while playing: the sentence and button word of Change country, the card list's name and "Choose", "Claim" on the heroes ranking |
| ✅ | Level rank, Fight rank | "Rank" and "Challenge" inside the board, "My points: 777540" in one piece, the button reads "Ranking Rules", the clock "2d 02:49:59" (was "2:2:49:59:") |
| ✅ | Gold spending | "Gold spent:" and "Time left:" clear of the countdown |
| ✅ | Akatsuki | every window looked at with a four-member test clan (`node tools/dev/play-tour.js`): headings Name / Level / Job / Points, jobs no longer run into the numbers, Upgrade window "Needs: / Cost: 2000 fund / Effect:", "Demotion", the rankings' Check buttons inside the screen; the card lists of Donate were shrunk to 55 % by the screen under them (fit.js) |
| ✅ | Border war | the Taunt / Wander question in whole sentences ("Pay 20 gold to Taunt ?", "Taunt for 5 min gives:", "Damage to the monument: 10", "(rewarded 2 times a day)"), the two lists' titles ("Wind: taunters"), "a day" inside the window, "0/2 left"; its windows no longer shrink the screen's texts |
| ✅ | Stage gift, cross Super Ninja, Daily spending, Festival, Group purchase, Hot Treasure, Slot machine | found while playing on 22 Nov: the gift's note inside its window, "10 draws until a sure 5-star purple card" as one line, the description clear of the countdown, "From Training fights" / "Left: 30/30", gift names on two lines, "One hunt" / "Ten hunts", no word on the Rules picture |

## 4. Order of work

1. Player data + card pictures (everything else leans on them).
2. Home team row, Team, Backpack, card details: so a player can use what fights give.
3. Shop + recruit, upgrade, strengthen: the daily loop.
4. Spar, Arena, Plunder, Battles, War: the other fights (the fight screen is done).
5. The Lua events and features, one by one (most need only 1 and the common windows).
6. Sounds, polish, then online and the iPhone app.
