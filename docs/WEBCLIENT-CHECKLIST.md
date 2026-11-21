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
| ⬜ | Level-up window (PlayerLevelUpDlg) | |
| ⬜ | Loading picture (LoadingView), time-out window, system notice window | plain grey cover for now |
| ⬜ | Sounds and music (26 mp3) | |
| ⬜ | Top banner (horn messages scrolling) | |
| ⬜ | Glowing names (our hot update, util/common.lua PurpleGlow) | needs `rl_r_purplename` + CCLabelTTF effects |
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
| ⬜ | Bind account (BindAccountView), game settings (GameSetting: music, log out, Discord link) | C++ + Lua ui_gameSettingLayer |

## 2. Main menu and the core screens (C++)

| | Screen | Layouts |
|---|---|---|
| ✅ | Home: top bar, village, buildings, level locks | MainMenu, DefaultMainMenu, <Country>CountryDefaultMenu |
| ✅ | Home: team cards row with arrows | MainCardView |
| ⬜ | Home: the base scene buttons (Base: ramen, money tree, national treasure, secret shop, border war, shinobi house) | CDefaultSLGMenu, firescene.xml |
| ⬜ | Home: red number bubbles (events, messages) | |
| ⬜ | Player info window (tap the top bar) | PlayerInfoDlg, meritRankCell |
| ✅ | Bottom bar | all six buttons open their screens |
| 🟡 | **Team**: line-up, change ninja, gear slots, ninjutsu slots, seals, chains, Team 2 (changing is coded, not tried yet) | ListMyTeamView, TeamNinjaView |
| 🟡 | **Backpack**: ninja / weapon / armor / trinket / ninjutsu / seal tabs (shown; no sell, use, fragments yet) | MyBackpackView, gameobjlist/*, BackpackTips |
| 🟡 | Card details (tap a card's picture in the Backpack): shinobi (the game's own page: big card, story, chains, growth and rebirth rows), gear, ninjutsu, seal with its five element rows (details.js); pets, the gear set window, opening it from the Team screen and the Growth / Rebirth / Train buttons not yet | NinjaDetailView + NinjaSubView, EquipDetailView, NinjasuDetailView, MarkDetailView + MarkInfoDetails, PetDetailView |
| 🟡 | Upgrade a card (feed cards): the card, material grid, Select all 1-2 star, exp and silver from the game's tables (upgrade.js); the phone's process and "complete" animations not yet | upgrade/CardUpgradeView, UpgradeNinja, UpgradeMeteriaInfoCard |
| ⬜ | Strengthen gear (Growth) | sub_ui/StrengthView |
| ⬜ | Potential (Train) | sub_ui/Potential* |
| ⬜ | Reincarnate | sub_ui/ReincarnationView |
| ✅ | Seals: list, merge (start, clock, finish now for gold, take the seal) - part of plunder.js | MarkListView, MarkMergaView |
| ⬜ | Ninjabook (collection) | GameObjBookList, GameObjBookCard |
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
| 🟡 | **Arena** (ladder): rivals with teams, Challenge, daily place reward, Rank tab, cooldown clear (arena.js); exchange shop, rules and lucky rank not yet | ArenaViewNew, ArenaCellViewNew |
| 🟡 | **Battles** (tower): floors (ours: plain rows, the phone draws a tower), a floor's seven rounds, fights (tower.js); ranks, first-pass reward, sweep not yet | TowerView, TowerLevelView |
| ⬜ | **War** (country war): my country, war info, ranks, score shop, officials, auto fight | countrywar/* (14 layouts) |
| ⬜ | National treasure | countrywar/CountryTreasury, SnatchDialogView |
| ⬜ | Ramen shop | RamenView + Lua BuyRemenDlg |
| ⬜ | Money tree | MoneyTreeView |
| ⬜ | News / messages: battle reports, system mail, friend messages | social/MessageListView, FightMsgView, SystemMsgView |
| ⬜ | Friends: list, search, invite, chat | social/Friend* |
| ⬜ | Event screen frame (the big Event list and its top bar) | activity/ActivityDefaultView, ActivityBarCellView |
| ⬜ | Lottery view, roulette turn window (C++ parts of Lua events) | activity/LotteryView, RouletteTurnDialogView |
| ⬜ | Daily ads (next day / days) | activity/NextDayAd, DaysAd |
| 🚫 | Tutorial | off for everyone on our servers |

## 3. Lua screens (the game's own scripts; each needs its helpers to exist)

Home buttons and windows:

| | Screen | Script |
|---|---|---|
| ✅ | Middle button row | MenuBtnsView |
| ✅ | Left event buttons | mainActivity, ui_mainActivityBtn |
| ✅ | Event window (icons) | ui_activityPopupLayer |
| ⬜ | Daily Task | dailyTask_business, ui_dailyTaskLayer |
| ⬜ | Save time (EXP card) | saveTime_business |
| ⬜ | 1st Recharge | firstMoneyAward |
| ⬜ | Growth fund | growthfund_b |
| ⬜ | 7-day goals | sevenDay_business, ui_sevenDayView |
| ⬜ | Receive (stage gift) | ui_stageGiftLayer |
| ⬜ | Awards (Award Center mail) | ui_awardCenterLayer |
| ⬜ | Hall of Fame (No.1 Shinobi) | ui_hallOfFameView |
| ⬜ | Settings | ui_gameSettingLayer |
| ⬜ | VIP list and rights | VipListView, ui_vipRightInfoView |
| ⬜ | Top-up window | ui_purchaseLayer |

Events (Event window and left column):

| | Event | Script |
|---|---|---|
| ⬜ | Login gift | loginPackActivity |
| ⬜ | Sign-in (login streak) | keepLoginView |
| ⬜ | Level-up gift | upradePackActivity |
| ⬜ | Monthly sign | monthSign_business |
| ⬜ | World Boss | fightBossView (+ 6 windows) |
| ⬜ | God Recruit | godRecruit_business (5 layers) |
| ⬜ | Monthly Card | monthCardActivity |
| ⬜ | Flower Worship | nvshen_business |
| ⬜ | Diligence gift | diligenceGift_business |
| ⬜ | Lottery ticket | lotteryTicket_business |
| ⬜ | Scratch card | ScratchCardActivity |
| ⬜ | Treasure chests (box open) | boxOpenActivityView |
| ⬜ | Group purchase | limitedGroupBuy_business |
| ⬜ | Daily pay, keep pay, rand pay, total recharge, gold spending | dailyPay, keepPay, randPay, accumulateMoney, consumption |
| ⬜ | Limited discount, daily restriction, hot treasure | limitDiscount, dailyRestriction, hotTreasure |
| ⬜ | Festival trades | festival_business |
| ⬜ | Lucky Wheel (roulette) + ranks | ui_rouletteLayer |
| ⬜ | Millionaire (dice) + ranks | ui_monopolyLayer |
| ⬜ | Mora | moraView |
| ⬜ | Slot machine | ui_slotMachineLayer |
| ⬜ | Super Ninja (limited) + ranks | ui_limitSuperNinjaLayer |
| ⬜ | Ninja Treasure (sudoku) | ui_ninjaTreasureLayer |
| ⬜ | Collect cards | collectCardActivity |
| ⬜ | Level rank, fight rank | levelRank, fightRank |

Features:

| | Feature | Script |
|---|---|---|
| ⬜ | God card synthesis (evolve) | ui_godCardSyntheticLayer |
| ⬜ | Limit training (Dun) | ui_limitTrainLayer |
| ⬜ | Soul training / Eight Gates | secret_shop/ui_trainSoulLayer |
| ⬜ | Secret shop | secret_shop/ui_secretShopLayer |
| ⬜ | Breakthrough | ui_tupoLayer |
| ⬜ | Ninja inherit | ui_ninjaInheritLayer |
| ⬜ | Attribute pills (element change) | ui_attributeDanLayer |
| ⬜ | Advance gear | ui_advanceEquipLayer |
| ⬜ | Gear sets, colour sets, level sets | ui_colorSuitView, ui_levelSuitView |
| ⬜ | Pets: list, main, train, upgrade, advance, summon | ui_pet* (7 layers) |
| ⬜ | Ninja Test (exam) | ui_ninjaTestMain |
| ⬜ | My Base | ui_myBaseLayer |
| ⬜ | Akatsuki (guild): list, create, hall, donate, shop, map, members, ranks | ui_org* (22 layers) |
| ⬜ | Border war | ui_borderWar* (14 layers) |
| ⬜ | Cross-server battle | multi_battle/* (14 layers) |
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
