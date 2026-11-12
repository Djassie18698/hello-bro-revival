# Web version: the full list

Everything the Android game has, and where the browser version (`server/webclient`, opened at `/play/`) stands.
Goal (owner, 12 Nov 2026): the whole game in a browser, so iPhone players can play again.

✅ works · 🟡 partly · ⬜ not yet · 🚫 not planned. "C++" = had to be rebuilt by hand; "Lua" = the game's own script runs, it only needs the helpers it calls.
Update this file with every round of work. How it is built and the rules found: `server/webclient/README.md`.

## 0. Foundations

| | Part | Notes |
|---|---|---|
| ✅ | Game files for the browser (`tools/build_webclient.js`) | sprite sheets, layouts, fonts, texts, tables, Lua scripts |
| ✅ | Drawing engine (`engine.js`) | sprites, 9-slice, labels, bitmap fonts, buttons, scroll views, layout timelines |
| ✅ | Lua 5.1 engine (`lua.js`) | checked against real Lua 5.1 |
| ✅ | Bridge for the scripts (`luabind.js`, `gamebind.js`) | cocos classes, CCBProxy, table views, actions, HTTP, XML |
| ✅ | Requests like the phone (`net.js`) | same server, same accounts |
| ⬜ | Player data kept like the phone (CPlayerDataMgr): every card, item, fragment, team | section 2 needs it; many Lua screens too |
| ⬜ | Card / item pictures and frames (CGameObjElement) | icons, quality frames, stars, element marks |
| ⬜ | Common windows: confirm (CommonDialogView), buy item (BuyItemDlg), reward box (ShowBoxView), item details | used everywhere |
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
| ⬜ | Home: team cards row with arrows | MainCardView |
| ⬜ | Home: the base scene buttons (Base: ramen, money tree, national treasure, secret shop, border war, shinobi house) | CDefaultSLGMenu, firescene.xml |
| ⬜ | Home: red number bubbles (events, messages) | |
| ⬜ | Player info window (tap the top bar) | PlayerInfoDlg, meritRankCell |
| 🟡 | Bottom bar | Home, Training work |
| ⬜ | **Team**: line-up, change ninja, gear slots, ninjutsu slots, seals, chains, Team 2 | ListMyTeamView, TeamNinjaView |
| ⬜ | **Backpack**: ninja / weapon / armor / trinket / ninjutsu / seal / item tabs, sell, use | MyBackpackView, gameobjlist/*, BackpackTips |
| ⬜ | Card details: ninja, gear (+ set), ninjutsu, seal, pet | NinjaDetailView, EquipDetailView, NinjasuDetailView, MarkDetailView, PetDetailView |
| ⬜ | Upgrade a card (feed cards) | upgrade/CardUpgradeView, UpgradeNinja, MaterialNinjaView, UpgradeProcessView, UpgradeCompleteView |
| ⬜ | Strengthen gear (Growth) | sub_ui/StrengthView |
| ⬜ | Potential (Train) | sub_ui/Potential* |
| ⬜ | Reincarnate | sub_ui/ReincarnationView |
| ⬜ | Seals: list, merge | MarkListView, MarkMergaView |
| ⬜ | Ninjabook (collection) | GameObjBookList, GameObjBookCard |
| ✅ | **Training**: chapters, stages, parts | ChapterView, SubChapterListView, SubChapter |
| ⬜ | Training extras: chapter complete window, boss retry for gold, exp-card timer, sweep | ChapterCompleteView |
| ✅ | **Fight** playback: cards, rounds, Skip | RoundTeamView, CoreFightCardView |
| ⬜ | Fight extras: ninjutsu cut-ins, element "restrain" effect, pets, hurt numbers, card frames by quality | CoreFightSkillView, RestraintView, PetSkill_ef |
| ✅ | Victory screen with the three prize cards | NewFightResult_WinView, RS_WinAnim |
| 🟡 | Defeat screen | built, its five help buttons not yet |
| ⬜ | Team compare | NewTeamCompare, TeamCompareItemView |
| ⬜ | **Spar** (fight other players): list, preview, fight | FightListView, FightNinjaView, FightPreView |
| ⬜ | **Shop**: items, packs, recruit (3 kinds, 10 pulls), VIP shop | StoreItemsView, StoreGoodsView, StorePacksView, StoreNinjaView, ShowBoxView, TurnTenDialogView |
| ⬜ | Top-up list and confirm (free on our server) | PurchaseListView, PurchaseItemView, PurchaseConfirmDialogView + Lua ui_purchaseLayer |
| ⬜ | **Plunder** (seal fragments) | PlunderListView, PlunderNinjaView, PlunderPreView |
| ⬜ | **Arena** (ladder): list, ranks, rewards, cooldown, exchange shop | ArenaViewNew, ArenaCellViewNew, ArenaRank*, ArenaExchangeCellView |
| ⬜ | **Battles** (tower): floors, boss, ranks, first-pass reward, sweep | TowerView, TowerLevelView, TowerBossView, TowerRank* + Lua ui_towerSweepLayer |
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
