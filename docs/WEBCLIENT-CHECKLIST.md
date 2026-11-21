# Web version: the full list

Everything the Android game has, and where the browser version (`server/webclient`, opened at `/play/`) stands.
Goal (owner, 12 Nov 2026): the whole game in a browser, so iPhone players can play again.

**13 Nov 2026: a second, better route exists.** `server/webclient/emu` runs the original app itself in the browser (an ARM emulator), so every screen below comes for free once its open points are done (sound, typing, files, iPhone memory and speed: see `server/webclient/emu/README.md`). This list stays as the plan for the hand rebuild, the fall-back.

✅ works · 🟡 partly · ⬜ not yet · 🚫 not planned. "C++" = had to be rebuilt by hand; "Lua" = the game's own script runs, it only needs the helpers it calls.
Update this file with every round of work. How it is built and the rules found: `server/webclient/README.md`.

## 0. Foundations

**21 Nov 2026 (owner: "port it over, make it HD and modern"):** every picture is redrawn at double size (`tools/build_hd.js`, Real-ESRGAN; `?hd=0` shows the originals), on a wide PC window the game stands on a stage with side panels (`stage.js`), and Shop, Spar, card upgrade, Arena and Battles were added. Open points for the look: a real landscape layout, the phone's own card-turn and upgrade animations.

| | Part | Notes |
|---|---|---|
| ✅ | Game files for the browser (`tools/build_webclient.js`) | sprite sheets, layouts, fonts, texts, tables, Lua scripts |
| ✅ | Drawing engine (`engine.js`) | sprites, 9-slice, labels, bitmap fonts, buttons, scroll views, layout timelines |
| ✅ | Lua 5.1 engine (`lua.js`) | checked against real Lua 5.1 |
| ✅ | Bridge for the scripts (`luabind.js`, `gamebind.js`) | cocos classes, CCBProxy, table views, actions, HTTP, XML |
| ✅ | Requests like the phone (`net.js`) | same server, same accounts |
| 🟡 | Player data kept like the phone (CPlayerDataMgr): cards and teams (data.js); items and fragments not yet | section 2 needs it; many Lua screens too |
| 🟡 | Card / item pictures and frames (CGameObjElement, data.js) | icons, quality frames, stars, element marks |
| 🟡 | Common windows: confirm (CommonDialogView) and "you got" (ours: the card fades in, the phone turns it over) are in shop.js (HB.dialog, HB.confirm, HB.showCards); buy item (BuyItemDlg), item details not yet | used everywhere |
| ✅ | Level-up window (PlayerLevelUpDlg): pops up when your level went up (old and new level, attack, defence, team size from the playerlevel table; "new team slot" and the every-10-levels gift button), with its sound (extras.js) | its light rays are tried, not checked against the phone |
| ⬜ | Loading picture (LoadingView), time-out window, system notice window | plain grey cover for now |
| 🟡 | Sounds and music (sound.js): button tap, music per screen like the game's bgSoundConfig (home, Training, Spar / Plunder, Arena, fight), Victory / Defeat, level-up, "you got", card clash; music and effects switches in Settings, remembered; `?mute=1`; silent until the first tap | checked in headless Chrome (files load, play is called), not yet by ear; the War tab's music waits for the War screen (`HB.sound.screen('war')`), Training's run / coin / exp sounds and the slot machine's own files not yet |
| ⬜ | Top banner (horn messages scrolling) | |
| ⬜ | Glowing names (our hot update, util/common.lua PurpleGlow) | needs `rl_r_purplename` + CCLabelTTF effects |
| ✅ | Custom events (ours): the owner's own events from text files, screen + Home button (custom.js, `docs/CUSTOM-EVENTS.md`) | not in the phone game |
| 🟡 | Text that fits (ours): labels shrink to stay clear of each other and the screen (fit.js); pictures next to text and hand-shortened wording still to do | owner: "all text should match the boxes" |
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
| ⬜ | Logo / loading scene, update window | not needed in a browser |
| 🟡 | Game settings: music, effects, Discord link, invite code box (the game's own script, extras.js `HB.screens.settings`); Bind account (BindAccountView) not yet | C++ + Lua ui_gameSettingLayer |

## 2. Main menu and the core screens (C++)

| | Screen | Layouts |
|---|---|---|
| ✅ | Home: top bar, village, buildings, level locks | MainMenu, DefaultMainMenu, <Country>CountryDefaultMenu |
| ✅ | Home: team cards row with arrows | MainCardView |
| 🟡 | Home: the village is a wheel of six buildings (Base, Cross, Noodle, Border, Shop, money tree): swipe to turn it, tap to open (base.js; how far a swipe turns it is by eye). Noodle and the money tree open; Base, Shop, Cross, Border not yet | CDefaultSLGMenu, <country>CountryDefaultMenu |
| ⬜ | Home: red number bubbles (events, messages) | |
| ✅ | Player info window (tap the top bar on any screen): level, exp, attack / defence / chakra, gold, silver, W.A., team, VIP, energy and grudge with their clocks, the list of ranks (extras.js) | PlayerInfoDlg, meritRankCell |
| ✅ | Bottom bar | all six buttons open their screens |
| 🟡 | **Team**: line-up, change ninja, gear slots, ninjutsu slots, seals, chains, Team 2 (changing is coded, not tried yet) | ListMyTeamView, TeamNinjaView |
| 🟡 | **Backpack**: ninja / weapon / armor / trinket / ninjutsu / seal tabs (shown; no sell, use, fragments yet) | MyBackpackView, gameobjlist/*, BackpackTips |
| 🟡 | Card details (tap a card's picture in the Backpack): shinobi (the game's own page: big card, story, chains, growth and rebirth rows), gear, ninjutsu, seal with its five element rows (details.js); pets, the gear set window, opening it from the Team screen and the Growth / Rebirth / Train buttons not yet | NinjaDetailView + NinjaSubView, EquipDetailView, NinjasuDetailView, MarkDetailView + MarkInfoDetails, PetDetailView |
| 🟡 | Upgrade a card (feed cards): the card, material grid, Select all 1-2 star, exp and silver from the game's tables (upgrade.js); the phone's process and "complete" animations not yet | upgrade/CardUpgradeView, UpgradeNinja, UpgradeMeteriaInfoCard |
| 🟡 | Growth (sage steps of a shinobi): stones, 1-4 at a time, extra stones, chance and silver from the game's table (growth.js); automatic growth and the animations not yet | sub_ui/StrengthView |
| 🟡 | Train (potential): limits, pill / gold, once / 10 times, the roll and Keep (growth.js); the animations not yet | sub_ui/Potential* |
| 🟡 | Reincarnate: with a second copy of the card or with pills, what the next rebirth gives (growth.js); the animation not yet | sub_ui/ReincarnationView |
| ✅ | Seals: list, merge (start, clock, finish now for gold, take the seal) - part of plunder.js | MarkListView, MarkMergaView |
| ✅ | Ninjabook (collection): Ninja / Gear / Ninjutsu tabs, 4 across like the phone, cards you hold in their quality frame, the rest grey (ours), tap = the card's window (book.js) | GameObjBookList, GameObjBookCard |
| ✅ | **Training**: chapters, stages, parts | ChapterView, SubChapterListView, SubChapter |
| ⬜ | Training extras: chapter complete window, boss retry for gold, exp-card timer, sweep | ChapterCompleteView |
| ✅ | **Fight** playback: cards, rounds, Skip | RoundTeamView, CoreFightCardView |
| ⬜ | Fight extras: ninjutsu cut-ins, element "restrain" effect, pets, hurt numbers, card frames by quality | CoreFightSkillView, RestraintView, PetSkill_ef |
| ✅ | Victory screen with the three prize cards | NewFightResult_WinView, RS_WinAnim |
| 🟡 | Defeat screen | built, its five help buttons not yet |
| ⬜ | Team compare | NewTeamCompare, TeamCompareItemView |
| ✅ | **Spar** (fight other players): list, preview, fight (spar.js); search not yet | FightListView, FightNinjaView, FightPreView |
| 🟡 | **Shop**: Recruit (3 scrolls, free timers, once / ten times window), Giftpack, Tool with Buy and Use (shop.js); VIP shop and Top-up not yet | StoreItemsView, StoreGoodsView, StorePacksView, StoreNinjaView, PrayDialogView |
| ⬜ | Top-up list and confirm (free on our server) | PurchaseListView, PurchaseItemView, PurchaseConfirmDialogView + Lua ui_purchaseLayer |
| ✅ | **Plunder** (seal fragments): the seal list, rivals with the chance word from the game's plunderinfo table, preview, fight (plunder.js) | PlunderListView, PlunderNinjaView, PlunderPreView |
| 🟡 | **Arena** (ladder): rivals with teams, Challenge, daily place reward, Rank tab, cooldown clear, Exchange tab (reputation shop with its daily / total limits) (arena.js); rules window and lucky rank not yet | ArenaViewNew, ArenaCellViewNew, ArenaExchangeCellView |
| 🟡 | **Battles** (tower): floors (ours: plain rows, the phone draws a tower), a floor's seven rounds, fights (tower.js); ranks, first-pass reward, sweep not yet | TowerView, TowerLevelView |
| ✅ | **War** (country war, Home > War building; war.js): Country (the 7 seats, Match = take an empty seat or fight its holder, the gift bag of your own seat), War (scores, clock, Attack with the fight, the 3-attack wait + Clear, buy revives, Auto-Attack window, the three "?" windows, news line + your own fight lines as in the phone photos), Reward (exploit shop), Ranking (Individuals / Nations). Not done: the "Last Battle" result chest (the server never opens it); with Auto-Attack on, the server attacks every 20 s and the screen reloads (the phone attacked by itself while open) | countrywar/* (14 layouts) |
| ✅ | **National treasure** (war.js; `&open=treasure`; reached through `ChangeToSub(E_COUNTRYTREASURE)`, level 45 lock from functionconfig 6): numbers, Defend on/off, Contribute (silver + exploit), Plunder window with the four other countries, the fight against a guard or a free grab, the 1-hour wait and its 15-gold skip. Not done: the reward animation layer (layer_anim); no Home building leads to it yet | countrywar/CountryTreasury, SnatchDialogView |
| ✅ | Ramen shop (the Noodle building): eat to fill energy and grudge (base.js); the steam animation not yet | RamenView |
| ✅ | Money tree: rules, free and paid shakes, what the tree dropped (base.js); the phone's own shake animation and the list of winners not yet | MoneyTreeView |
| 🟡 | News: Battle reports (Ignore, Revenge), Friend messages (Reply), System note (social.js); a message is typed in the browser's own box | social/MessageListView, FightMsgView, FriendMsgView, SystemMsgView |
| 🟡 | Friends: every player with team numbers, leave a message, search by name (social.js); the phone's invite and chat windows not yet | social/Friend* |
| ⬜ | Event screen frame (the big Event list and its top bar) | activity/ActivityDefaultView, ActivityBarCellView |
| ⬜ | Lottery view, roulette turn window (C++ parts of Lua events) | activity/LotteryView, RouletteTurnDialogView |
| ⬜ | Daily ads (next day / days) | activity/NextDayAd, DaysAd |
| 🚫 | Tutorial | off for everyone on our servers |

## 3. Lua screens (the game's own scripts; each needs its helpers to exist)

**21 Nov 2026:** the two frames these screens live in are built (luascreens.js): the Event screen (icon strip + the event's own
layer) and the empty sub menu the helper functions fill (ShowRouletteView, ShowOrgView, doShowBase ...), plus the Home buttons and
village buildings that lead to them, and the C++ helpers they asked for (the player's cards as objects, items held, VIP level, what a
drop pack holds, the Event card view). `node tools/dev/lua-screens.js` opens 57 of them one after another and reports Lua errors and
missing C++ names, with a picture of each in re/lua/: 49 open without an error. The rest are not client faults: the event is off on
the test server (level rank, fight rank, collect cards, gold spending, slot machine), a script v28 does not have (lotteryActivity),
the wheel's last prize has no drop row (same on the phone), Ninja inherit needs a card. 🟡 below = opens and draws like the phone;
its buttons and what they pay out are NOT all tried yet.

Home buttons and windows:

| | Screen | Script |
|---|---|---|
| ✅ | Middle button row | MenuBtnsView |
| ✅ | Left event buttons | mainActivity, ui_mainActivityBtn |
| ✅ | Event window (icons) | ui_activityPopupLayer |
| 🟡 | Daily Task | dailyTask_business, ui_dailyTaskLayer |
| 🟡 | Save time (EXP card) | saveTime_business |
| 🟡 | 1st Recharge | firstMoneyAward |
| 🟡 | Growth fund | growthfund_b |
| 🟡 | 7-day goals | sevenDay_business, ui_sevenDayView |
| ⬜ | Receive (stage gift) | ui_stageGiftLayer |
| 🟡 | Awards (Award Center mail) | ui_awardCenterLayer |
| 🟡 | Hall of Fame (No.1 Shinobi) | ui_hallOfFameView |
| ✅ | Settings (switches, Discord button and close tried; the invite code box not) | ui_gameSettingLayer |
| 🟡 | VIP list (the Shop's VIP tab: your VIP bar, the VIP gift packs; opens and draws, Buy and "VIP benefits" not tried) | VipListView, ui_vipRightInfoView |
| 🟡 | Top-up window | ui_purchaseLayer |

Events (Event window and left column):

| | Event | Script |
|---|---|---|
| 🟡 | Login gift | loginPackActivity |
| 🟡 | Sign-in (login streak) | keepLoginView |
| 🟡 | Level-up gift | upradePackActivity |
| 🟡 | Monthly sign | monthSign_business |
| 🟡 | World Boss | fightBossView (+ 6 windows) |
| 🟡 | God Recruit | godRecruit_business (5 layers) |
| 🟡 | Monthly Card | monthCardActivity |
| 🟡 | Flower Worship | nvshen_business |
| 🟡 | Diligence gift | diligenceGift_business |
| 🟡 | Lottery ticket | lotteryTicket_business |
| 🟡 | Scratch card | ScratchCardActivity |
| 🟡 | Treasure chests (box open) | boxOpenActivityView |
| 🟡 | Group purchase | limitedGroupBuy_business |
| 🟡 | Daily pay, keep pay, rand pay, total recharge, gold spending | dailyPay, keepPay, randPay, accumulateMoney, consumption |
| 🟡 | Limited discount, daily restriction, hot treasure | limitDiscount, dailyRestriction, hotTreasure |
| 🟡 | Festival trades | festival_business |
| 🟡 | Lucky Wheel (roulette) + ranks | ui_rouletteLayer |
| 🟡 | Millionaire (dice) + ranks | ui_monopolyLayer |
| 🟡 | Mora | moraView |
| 🟡 | Slot machine | ui_slotMachineLayer |
| 🟡 | Super Ninja (limited) + ranks | ui_limitSuperNinjaLayer |
| 🟡 | Ninja Treasure (sudoku) | ui_ninjaTreasureLayer |
| ⬜ | Collect cards | collectCardActivity |
| ⬜ | Level rank, fight rank | levelRank, fightRank |

Features:

| | Feature | Script |
|---|---|---|
| 🟡 | God card synthesis (evolve) | ui_godCardSyntheticLayer |
| 🟡 | Limit training (Dun) | ui_limitTrainLayer |
| 🟡 | Soul training / Eight Gates | secret_shop/ui_trainSoulLayer |
| 🟡 | Secret shop | secret_shop/ui_secretShopLayer |
| ⬜ | Breakthrough | ui_tupoLayer |
| 🟡 | Ninja inherit (opens from a card; not tried) | ui_ninjaInheritLayer |
| 🟡 | Attribute pills (element change) (opens from a card; not tried) | ui_attributeDanLayer |
| 🟡 | Advance gear | ui_advanceEquipLayer |
| 🟡 | Gear sets, colour sets, level sets | ui_colorSuitView, ui_levelSuitView |
| ⬜ | Pets: list, main, train, upgrade, advance, summon | ui_pet* (7 layers) |
| ⬜ | Ninja Test (exam) | ui_ninjaTestMain |
| 🟡 | My Base | ui_myBaseLayer |
| 🟡 | Akatsuki (guild): list, create, hall, donate, shop, map, members, ranks (the list of guilds opens; the rest not tried) | ui_org* (22 layers) |
| 🟡 | Border war | ui_borderWar* (14 layers) |
| 🟡 | Cross-server battle | multi_battle/* (14 layers) |
| ⬜ | Cross roulette / millionaire / super ninja | ui_cross* |
| ⬜ | Change country | switchCountry |
| ⬜ | Tower sweep, re-new level, split card | towerSweep, ReNewLevel, SplitCard |
| ⬜ | In-game news list | InGameNoticeListView |

## 4. Order of work

1. Player data + card pictures (everything else leans on them).
2. Home team row, Team, Backpack, card details: so a player can use what fights give.
3. Shop + recruit, upgrade, strengthen: the daily loop.
4. Spar, Arena, Plunder, Battles, War: the other fights (the fight screen is done).
5. The Lua events and features, one by one (most need only 1 and the common windows).
6. Sounds, polish, then online and the iPhone app.
