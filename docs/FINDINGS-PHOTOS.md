# Original Hello Bro / Ninja Online numbers seen in the Facebook group photos

Source: Facebook group "Ninja Online EN" (Media > Photos), downloaded in batches of 300 into `batch-NN\`.
File names are `NNNN_<facebook photo id>.jpg` (NNNN = order in the group's photo list, newest first).
Each finding names the picture it came from. "Server now" = what the revival server uses today;
values the server marks **(ours)** are guesses that these pictures could replace.

## What the server guesses today (to look for)
| Topic | Server now (ours) | Where in the repo |
|---|---|---|
| VIP thresholds | $1, 10, 30, 50, 100, 200, 300, 500, 800, 1200, 2000, 3000, 5000, 8000, 12000, 20000, 30000, 50000 for VIP 1-18 | `vip.js` VIP_EXP |
| Recruit pity | 20 pulls to a sure 5-star | `game.js` PITY |
| Free recruits | purple 300 gold free every 24 h, blue 150 gold every 8 h (owner's memory) | `game.js` FREE_EVERY |
| Daily task chests | 5000 silver, 20 gold, 10000 silver, 50 gold, 100 gold | `game.js` DAILY_AWARDS |
| Stage drops | one low-tier item per win | `handlers.js` stageAward |
| Reward wheel | 40% work harder, 20% EXP x2, 20% silver x2, 20% gold (3) | `handlers.js` |
| Boss / stage enemies | average card stats x 0.6 | `game.js` ENEMY_SCALE |
| Boss tries | 3 free a day, then 10 gold | FIXES-2026-10-31 |
| Spar grudge | +1 every 2 h | `game.js` |
| Ninja Test | 3 tries a day, 20 gold extra; chests 30/80 gold; score 10 x stage | `exam.js` |
| Breakthrough | 5+5 x level fragments, 50 000 x (level+1) silver, max 10, +4% stats | `tupo.js` |
| Millionaire | board, 20 gold a throw, rewards | `monopoly.js` |

## Findings

Note: a few photos are from other (copy) games (Pocket Ninja, Bleach Ninja, a landscape "BlackClover" UI) or not
from the game at all; those are skipped. Most screenshots are from the English Hello Bro / Ninja Online itself.

### Checks that the server is already right
- Stage rewards and energy match the game's own `roundinfo` exactly: 1-1 "Book of Seal" energy 3, EXP 6, silver 15,
  needs 2 clears (`batch-01/0004`); "Madara's Jeer" energy 23, EXP 598, silver 713, 4 clears and "Enjoy Battle"
  energy 24, EXP 624, silver 744 (`batch-01/0084`). So the data tables are the real ones.
- Sage growth silver cost: Sage 12 uses 650, Sage 13 uses 700 silver per try (`0026`, `0076`, `0200`-`0203`) = server's
  50 x (level + 1). Help text: "More purple sage stones, higher success rate. Never regresses when level reaches 3, 6, 9."
- 10-pull recruit costs **2800 gold**, single recruit had "Free recruitment this time" (`0003`).
- Shop (Tool tab) prices that match `consumeinfo`: Sage Stone I 5, Sage Stone III 10, Ramen (Large) 20,
  Hyourou-gan Small 8 / Big 10, Immigration Card 50 gold (`0080`-`0082`, `0251`).
- War Achievement ranks (player info): 1 Junior Genin 500 W.A. +25 ATK/DEF/Chakra, 2 Middle Genin 1000 +50,
  3 Senior Genin 2000 +100, 4 Elite Genin 4000 +150, 5 Junior Chunin 8000 +250, 6 Middle Chunin 12000 +350,
  7 Senior Chunin 15000 +450 (`0083`, `0129`, `0252`). Same as `data/playemedal.json` (check the higher ranks there).
- Daily task list and points per task are the ones in `dailytask_info` (Training 20x = 10, Advance 5x = 10, Plunder
  2 seals = 10) (`0175`).

### Values that DIFFER from the server (server guess can be replaced)
| Topic | Original (picture) | Server now |
|---|---|---|
| Daily task chests | Points bar total **250**; chests at (at least) **120, 160, 210, 250** points; the list scrolls left so there are more chests before 120 (`0175`). The enabled tasks in `dailytask_info` add up to 255, so 250 fits. | total 100, chests at 20/40/60/80/100 |
| Arena daily rank reward | rank 1: **25 000 silver + 5 000 reputation**, rank 2: 24 000 + 4 800, rank 3: 23 000 + 4 600, rank 4: 22 000 + ?, rank 5: 21 000 + 4 200, rank 6: 20 000 + 4 000 (`0211`, `0051`) = 26 000 - 1 000 x rank silver, 5 200 - 200 x rank reputation (top 6 seen) | 6 000 - 100 x rank silver, 200 - 5 x rank reputation |
| Eight Inner Gates | Gates have a **level** (seen LV 10, 11, 25, 53) and 8 points per level. Cost of a point: souls + **silver = 15 x souls**: LV10 point 5: 1018 souls + 15 270 silver, +331 ATK/Chakra; LV11 point 5: 1153 + 17 295, +346; LV25 point 7: 3624 + 54 360, +604 each; LV53 point 3: 4403 + 66 045, DEF +1277. Totals: at LV25 +41 939 flat and +7% ATK / +7% DEF / +8.5% Chakra; LV53: +138 529 and +28/31/31%; LV10: +10 312 and +1.5% (`0053`, `0123`, `0180`, `0217`) | 8 gates total, 100 x n souls, 1000 x n silver, +120 flat, +2% each |
| Sage growth success rate | Sage 12 with 1 stone: **10%** (+10% shown with more stones); Sage 13: **2%** / **1%** (`0026`, `0076`, `0200`-`0203`) | at least 30% |
| Reincarnation Pill price | **120 gold** (`0080`) | `consumeinfo` 180 |
| Development Dan price | **120 gold** (`0082`) | `consumeinfo` 200 |
| Ninja Treasure (3x3 board, `sudoku.js`) | Refresh **100 gold**; board refreshes by itself every **2 h** (countdown 1:54:59, 1:57:07); "Explore" cost grows: **300** gold with 2 prizes taken, **1000** with 4 taken (`0018`, `0150`) | refresh 20 gold, every 4 h, explore 10 + 10 x taken |
| Spar preview | Win: EXP 228, silver (big number, looks like a share of the rival's silver), **15 W.A.**, chance of equipment/ninjutsu chest; Lose: EXP 76, **-542 silver**, **5 W.A.** (`0078`, player level 224) | done 2 Nov: spar EXP = level + 4 (win) / a third (loss), +15 / +5 W.A.; silver still ours |
| Spar log | "Player X has been defeated by you in the spar, you won 0 silver" / "you won 1000 silver" (`0299`) | |
| Shinobi training (potential, `rl_x_develop`) | uses **1 Super Ninja Pill** per try, **70%** success, **4000 silver**, attributes +1-2 (`0206`) | free, no pills |

### Other original screens and numbers
- Consecutive login reward (`0280`, `0177`): day 1: 2 Ramen (small) + 2 Hyourou-gan (small) + 500 silver; day 2: 3 + 3 + 800;
  day 3: 3 + 3 + 1000; day 4: 2 Ramen (large) + 2 Hyourou-gan (big) + 1500; day 5: 2 large + 3 big + 2000; day 6: 2 + 3 + 2500;
  day 7 and after: **20 gold** + 2 Ramen (large) + 3 Hyourou-gan (big).
- Event "multiple" top-up wheel (`0132`): 6 segments 1.2 / 1.8 / 2 / 1.5 / 2.2 / 3 times, spin costs 300 gold.
- Event ranking rewards: "S-shinobi draw" gold draw 300 gold, free draw on a timer, rank 1 Susa Kakashi, 2 Kyuubi Naruto,
  3-5 Obito (A), 6-10 Kabuto (A), first prize needs 240 points (`0099`). Wheel of Fortune ranking (`0247`): ranks 1 / 2-3 / 4-6 /
  7-12, points rewards at 40 / 40 / 100 / 1400 score, first prize needs > 240 points. Other rankings: 20 / 320 / 720 / 3300 score
  and 20 / 150 / 320 / 2500 score (`0147`, `0131`, `0134`); "Fighting of Rich" ranking 20 / 40 / 128 / 248 (`0250`).
- Gold recruit results that are gold itself: "Gold*1000", "Gold*210" (`0148`, `0222`, `0231`, `0235`, `0236`).
- Victory screens with "Please draw your victory reward": 3 face-down cards, e.g. Tunic of Kage / Gentle Fist / 20 000 silver
  (`0199`), Kunai / Tsukuyomi / Toth (`0232`); boss win EXP +600 (`0199`).
- God card "closed" stat panels (team screen): e.g. "17 Five-Star Cards ATK+4200 ATK+8% ... still closed 19 / 21 Five-Star Cards",
  "15 Nine-Level Cards ... ATK+2600" (`0009`, `0086`, `0109`, `0162`, `0288`).
- Mystery-shop fragments in the shop Tool tab: 5-star equipment purple fragment, 4-star ninjutsu blue fragment, 5-star ninjutsu
  purple fragment (50 fragments -> card) (`0174`).
- Many full team screens with real card stats at level 50 (ATK/DEF/Chakra ranges per card, gear, chains) from high-level players:
  `0009`-`0017`, `0060`-`0070`, `0086`-`0095`, `0139`-`0146`, `0162`-`0170`, `0187`-`0194`, `0205`-`0218`, `0288`-`0298`.
### Batch 2 (`batch-02`, photos 0300-0595)
| Topic | Original (picture) | Server now |
|---|---|---|
| God breakthrough +1 (Kyuubi Naruto) | needs **10** of the card's fragments ("0/10") + **60 000 silver**; +1 gives ATK +615, DEF +966, Chakra +175 (flat), ninjutsu trigger **+1%**, element restrain **+2%** (`0365`) | 10 fragments + 50 000 silver, +4% stats, +2% trigger, +1% restrain (trigger/restrain swapped) |
| Reincarnation | Reincarnation 4 (5-star Madara): basic value +70%, restrain 35% -> 35%; needs **1 same card OR 500 Reincarnation Pills** (`0413`); results screens show "attributes con 20% -> 25%, skill activation 16% -> 21%" (`0517`, `0563`) | game table says 480 pills for Reincarnation 4 (kept); photo 500 = older version |
| Mystery (secret) shop | refresh by Refresh Order or **20 gold**; **80 refreshes a day** (+5 per VIP level shown "VIP1 +5"; one shows 100/100 at higher VIP); auto refresh every **2 h** (countdown 1:58:15); prices in ninja souls: Sage Jiraiya frags x3 650, Mei Terumi 130, Second Mizukage 170, Fourth Raikage x5 600, Jashin Hidan x5 2500, Orochimaru 170, Pakkun 600/400, Naruto 15000, Kaguya for New Year 1500, Gamakichi 620 (`0357`, `0446`, `0508`) | refresh free, 99 a day, once a day |
| Scratch card ("Lottery", `rl_w_guaguale`, not built) | 3x3 board, match 3 to win; prizes seen 800, 500, 150, 20, 5 gold; costs gold (player had "Free chances 0") (`0425`) | built 1 Nov (`scratch.js`) |
| Country war exploit shop | Shinobi Pack III 5000 exploit, Five-Star Shinobi Card 6000, Five-Star Shinobi Purple Card Fragment x15 7000, Five-Star Equipment Card 8000 (`0543`); war every night **18:30-19:30**, auto declare war (`0380`) | matches (warconfig 1000 / 3000 / 3000 / 4000 / 5000) |
| Monthly sign-in (May) | day 1 10000 silver (v1 x2), 2: 20 gold, 3: 3 Recruitment Orders (v2 x2), 4: shinobi card (v3 x2), 5: 3 Refresh Orders, 6: 25000 silver (v3 x2), 7: 5 Development Dan (v4 x2), 8: 50 gold, 9: card (v5 x2), 10: 5 Refresh Orders, 11: 20 Sage Stone III (v5 x2), 12: card (v6 x2), 13: 15 Reincarnation Pills, 14: 30000 silver, 15: 6 Development Dan (v7 x2), 16: 50 gold (v8 x2) ... ("vN x2" = VIP N or higher gets double) (`0516`) | done 2 Nov (`signin.js`, original days 1-16, VIP x2) |
| Akatsuki (guild) upgrades | Group Lv8 -> 9: 45 000 contribution, member +1, needs Hall Lv4; Mall Lv4: 15 000, 3 more spots, needs akatsuki Lv9; Donate Lv4: 13 000, 20% donation profit; Hall Lv4: 20 000, 140% mission profits, needs Mall Lv5 (`0567`) | done 2 Nov (`guild.js` costs and requirements) |
| Evolve (god card) | material card + item 201, cost 100 (`0553`); "Reincarnation and growth will be retained" | |
| Eight Gates more points | LV11 point 8: 1680 souls + 25 200 silver (= 15x) Chakra +1% (`0408`); LV20 1312 + 19 680 (`0379`); LV79 7624 + 114 360, totals +245 015 and +56/59/59% (`0571`); LV150 45 163 + 355 500?? (`0334`) | |
| Sage growth | Sage 12 attempts at 10% (+10% with more stones), Sage 15 shows 8%, 650-700 silver (`0351`, `0369`, `0418`, `0439`-`0441`, `0518`-`0521`) | |
| Cumulative gold (Consume) event | 8000 gold spent: Gaara(G) + OuterPath + 60 Souls Dan + 100 Development Dan; 13000: S&S(G) + Chibaku + 100 Souls Dan + 150 Super Ninja Pill; 30000: Susa Indra(G) + Rinnegan + 200 Souls Dan + 300 Reincarnation Pill; one below 8000: Hinata(G) + Shinra + 100 pills + 70 Reincarnation Pill (`0347`) | |
| Daily "multiples" tasks | "32 multiples 3 times -> 20 Reincarnation Pill", "3 times 1 in 10000", "10 times to soul" (`0346`, `0402`, `0497`) | |
| Arena rank reward (more) | rank 6: 20 000 + 4 000, ranks 23-26: **15 200 silver + 3 040 reputation** (`0389`, `0409`, `0430`); rank 1 seen 25 000/5 000 again (`0460`) | |
| Wheel of Fortune ranking | ranks 1 / 2-4 / 5-10 / 11-20; points rewards at 30, 250, 600, 2500 score; first prize needs > 580 points (`0318`, `0406`, `0417`, `0428`) | |
| S-shinobi draw | gold draw 300 gold; rewards ranks 1 / 2-3 / 4-8 / 8-15 (Hokage(A), Susa Shisui(A), Kakashi(A), Ultimate) (`0399`, `0489`, `0510`, `0534`) | |
| World boss | "Battle begins 14:00 daily", reputation shop items 65000 / 45000 / 15000 / 12000 / 10000 (`0524`) | |
| Cross-server arena gift pack | 900000 / 800000 / 300000 / 100000 / 24000 merit points (`0476`, `0561`) | |
| Monthly card | "The 750$ you just paid can't afford the Monthly Card, so it's been transferred into gold"; top-ups shown: $10 -> 750 gold, $5 -> 375 gold (`0529`) = **75 gold per $** | ignored (other store, see the next row) |
| Spar losses in log | "you lost 2311 / 2432 / 2560 / 2695 silver" to a level 261 player (`0356`), 89 700 - 107 997 at level 282 (`0538`) | |
| Card fragments needed | 5-star cards 30 fragments, god cards 50 (Backpack fragments lists, many photos) | same |

### Batch 3 (`batch-03`, photos 0596-0894)
| Topic | Original (picture) | Server now |
|---|---|---|
| Shinobi reincarnation (5-star cards, pills OR 1 same card) | Reinc 1: **80 pills**, basic value +15%, restrain 15% -> 20% (`0826`, `0827`); Reinc 2: **160**, +35%, 20 -> 25% (`0825`); Reinc 3: **320**, +50%, 25 -> 35% (`0824`); Reinc 4: **500**, +70%, 35 -> 35% (`0413`); Reinc 8: **1200**, +185%, 45 -> 50% (`0876`); Reinc 9: **1230**, +230%, 50 -> 60% (`0780`) = there are at least **9** shinobi reincarnations. Christmas Naruto card text lists rebirth 1-8 bonuses: Attack +250, +280, +400, +620, +1240, +2480, +4960, +9920 (`0620`) | `NEWLIFE_MAX` 8, cost 5000 x grade silver (`newlifeconfig` has pill counts 10/20/40/60/80/100 per type) |
| Equipment reinforce (advance) | "Available of reinforce three times, attribute +350%"; merge two lower +N cards into one +N+1; costs **50 000 silver**; level goes back to 1 from 50 after advancing; Triple-Bladed Scythe +2 587 -> +3 1057 (`0683`, `0684`, `0751`, `0752`) | done 2 Nov: 50 000 silver, max 3 (`game.newlife`) |
| Arena reputation shop | "The eight" Naruto Uzumaki (attack card) 480 000 rep, total 1 exchange; "The nine" 30 Sage Stone I 8000 rep, 4 a day; "The ten" 15 Sage Stone III 8000 rep, 2 a day; "The eleven" 5 Reincarnation Pills; one row at 120 000 (`0708`) | matches (exchange_award) |
| Akatsuki mall | prices in contribution: 20 Sage Stone I 70 con, 20 Sage III 140, 1400 con + 600 gold item, 4 Reinc Pills 504 con / 3 for 378, 10 Sage III 70, 3 Dev Dan 420, green scroll 196, 5-star weapon 2100, 100 Sage I 280, 1-in-10000 ticket 190, blue scroll 700; refresh every **30 min** (`0655`) | done 2 Nov: Akatsuki mall built with these prices, 30 min refresh |
| Akatsuki list | guild level 9, members 6/15 (`0605`) | |
| Border war (wander / taunt) | daily: taunting reward 2, wandering reward 2, taunting clearance 4, wandering clearance 4; wandering twice at thunder: EXP 6600 + 1572 merit; breaking a country's border: 50 gold + Super Ninja Pill + Reincarnation Pill (`0666`); border HP 300/300, open "EST 12:00-15:00" (`0540`) | not changed yet (`border.js`) |
| Country war | each kill: **10 points and 10 exploit** (`0831`-`0835`); war 18:30-19:30 (`0754`, `0843`) | |
| Ninja Treasure (3x3) | refresh 100 gold, **Explore 70 gold**, auto refresh countdown ~2 h (1:59:53, 1:59:26, 1:59:28); prizes like 10/150/25/30 Dev Dan etc. (`0609`, `0680`, `0700`) | |
| Fighting of Rich / "Listing of Rich" (Millionaire) | first prize needs 140; ranks 1-4 card rewards; achievement steps 20 (1-in-10000), 60 (40 Reinc pills), 100 (scroll), 200 (card) (`0673`, `0810`) | `monopoly.js` ours |
| Wheel of Fortune ranking | first prize needs 580 points; ranks 1 / 2-3 / 4-6 / 7-15; point rewards 30, 250, 600, 2500 score (`0636`, `0670`, `0715`) | |
| Christmas event | "go training, batter" / "go spar" collect items; exchange 40+40 -> 5-star card 15x, 100+100 -> card 1x, 350+350, 450+400; 30 -> 15 Sage III, 25 -> 10 Reinc pills, begin 12.28 end 1.3 (`0848`, `0858`, `0874`, `0887`) | |
| Cumulative gold event | 400 gold: 1-in-10000 + ... ; 1500 gold: 55 ninjutsu frags ...; 2500: Ultimate + 100 ...; 4500 ... (`0857`) | |
| Multiple top-up wheel | 3 / 12 / 18 / 2 / 15 / 22 x, needs 300 gold (`0775`) | |
| Sage growth | Sage 13 at **2%**, Sage 13 8% / 700 silver (`0674`, `0723`) | |
| Spar log | "won 0 silver" vs low levels (`0688`, `0762`, `0891`); plunder seal steal +778 (`0787`) | |
| World boss | 14:00 daily; "Akatsuki is invading" countdown; boss levels up to Lv 20 with 50 155 W HP (`0692`); reputation shop 65000/45000/35000/15000/12000 (`0616`) | |
| Consecutive login | same table as batch 1, again (`0686`, `0814`) | |

### Batch 4 (`batch-04`, photos 0895-1194; contact sheets up to 1086 read)
| Topic | Original (picture) | Server now |
|---|---|---|
| **VIP** | VIP4 player at **580/1000** VIP exp, "Load another **42$**" to VIP5 (`1077`) -> VIP 5 = 1000 exp = **$100** total, and exp = $ x 10 is confirmed | `vip.js` VIP 5 = 1000: **matches** |
| **Top-up (gold per $)** | $0.99 = **45 gold** (bonus 0), $4.99 = **225** + bonus 15, $9.99 = **450** + bonus 40 (`1077`); system mail "You paid 1 $ and purchased 45 gold" (`1024`). (Batch 2 "75 gold per $" came from a different store/region, ignore it.) | done 2 Nov (top-up packages) |
| Recruit screen | 1 in 10000 (4-5 star) **300 gold**, free after **2 days 16 hours** shown; 1 in 1000 (3-5 star) **150 gold**, free after 0 days 16 hours; 1 in 100 (2-5 star) uses 1 Recruitment Order (`0905`). The free timers here are longer than 24 h / 8 h, so free recruits may be **every 72 h / 24 h** | free every 24 h / 8 h |
| Recruit 10x result | "Congratulations in winning" shows 10 cards (`0906`) | |
| **Top-up full list (web "PayPal exchange")** | $0.18 = 8 gold, $1 = 45, $5 = 240, $10 = 485, $15 = 740, $30 = 1590, $100 = 5500, $200 = 12 000, $500 = 29 000; in-app row $99.99 = 4800 + bonus 700 (`1112`) | web store, not used |
| Cumulative gold event (later version) | ... Sage Jiraiya(G) + Sasuke(G) frag x10 + 100 Super Ninja Pill + 80; **8500**: Indra(God) + Sasuke frag x15 + 100 + 100 Reinc pills; **16000**: Six Paths Naruto(A) + frag x15 + 150 + 150; **38000**: Kaguya(God) + Six Paths Naruto(D) + frag x15 + 300 Reinc pills (`1114`) | |
| Ninja Treasure / Wheel of Fortune ranking | ranks 1 / 2-3 / 4-6 / 7-12; first prize needs 580 (`1126`) | |
| Seal levels (Chomei Seal, legendary) | level 2: ATK/DEF/Chakra +150; level 3: +200; level 4: +250 (+ "increase chance of skill activation") (`1138`) | matches (markupgrade) |
| Evolve cost | evolving a 4-star card costs 15 (`1149`), god cards 100 | |
| Millionaire ("Rich") board | 10 Spin button, "Good luck!" (`1183`); Listing of Rich achievements 20 / 80 / 140 / 300 (`1173`) | |
| Admin post | the game's admin ("Rui") changed the wheel reward to 2 ninjas (`1135`) | |
| Super Ninja Pill | shop: "Currently not for sale" (`1011`); Reincarnation Pill 120 gold, Sage Stone III 10 gold (`1011`) | |
| Cross-server battle (`rl_r_cross_war`, not built) | Arena top 20 of each server enter (arena ranking ends every Friday 8 pm); others pay **500 gold** ticket; list made Friday 8 pm, battles Saturday 8-9 pm; points on the "celestial ladder"; only 12 shinobi cards used (`0937`, `0938`) | not built (cross-server, left for later) |
| Eight Inner Gates (new screen version) | LV100: cost 7120 chakra + 106 800 silver (=15x), totals +334 236 and +81% each (`0924`); LV73: 5165 + 77 475, +218 523 / +50-53% (`0940`); LV24 point 6: 2332 + 34 980 (`1051`) | |
| Daily "complete the designated lines" | "32 multiples 3 times" -> 20 Reincarnation Pills, 2 a day; "3 times 1 in 10000"; "10 times to soul" (`1009`, `1061`) | |
| Boundary monument (border) | contribution ranking, Merit chest (merit > 200 claimable) (`0952`) | |
| Akatsuki | guild Lv3, fund 15 429, members 8/9 (`1012`) | |
| Ninja Treasure | refresh 100, Explore **35 / 70 / 200** (rises), board ~2 h (`1015`, `1018`, `1070`-`1073`) | |
| Sage growth | Sage 13 **2%** at 700 silver with green stone (`1068`); Sage 12-15 10% / 8% (`0965`, `0975`, `1074`) | |
| Spar preview | win: 15 W.A., silver 4712 (`1029`) | |
| Wheel of Fortune | 1st try is free daily, "Turning once 10 points" (`0954`) | |
| God breakthrough screen | silver 0 shown, fragments needed by card (`1014`) | |

- Recruit pity text "Recruit 0 more will get one" (`0099`, event draw) and "Assured to get 5-Star Card, Recruit more will get one"
  (`0003`); the actual pity number is not visible in batch 1.

### Batch 5 (`batch-05`, photos 1196-1252)
| Topic | Original (picture) | Server now |
|---|---|---|
| "Great gift for total recharge" (timed top-up event, 48 h countdown) | top up **$240**: Kyuubi Minato(A) + Shakujo + 160 Reincarnation Pills + 100 Souls Dan; **$420**: 2nd-Rebirth(G) card + 250 red pots + 200 Development Dan + 200 Reinc Pills; **$750**: 7th-Rebirth(G) card + 500 purple crystals + 400 Reinc Pills + 300 Souls Dan (`1238`) | built 2 Nov: `totalgift.js` (Timed Gift) |
| Wheel of Fortune (New Year look) | 12 prizes around a **Super award pool 600 000 gold**; prizes seen: 5 scrolls, purple orb, card, 5 cards, ghost card, **210 gold**, Souls Dan, 15 crystals, 2 Reinc Pills, 5 gold piles, 5 bags, Orochimaru card; "Turning once 10 points (1st try is free daily)" (`1213`); ranking: minimum for 1st prize **580** points, points rewards at **30 / 250 / 600 / 1000** score (`1214`) | `wheel.js` |
| Akatsuki max levels | Group **Lv9**, Mall **Lv5**, Donate **Lv5**, Hall **Lv5** all show "level max", fund 559 (`1198`) | done 2 Nov: max Lv9 / 5 / 5 / 5 |
| Flower Worship (Mei Terumi) | "Given 40 flowers", favorability 0/1, refresh with roses, event countdown (`1240`) | built 2 Nov (`flower.js`, switch, off by default) |
| World boss Kakuzu | Lv 4, HP **16 848 W** (=168 million), Power +15%, reputation shop 40 000 / 25 000 / 12 000 / 1000 / 350 (`1222`) | `boss.js` |
| S-shinobi draw (Kaguya D) | points list rank 1 = 210 points, "Recruit 4 more will get one"; rewards 1 Kaguya(D), 2 Hamura(D), 3-5 Gaara(A), 6-10 Tobirama(A) (`1216`) | |
| Consecutive login | same as before; one player at **347** consecutive days, one at 500 (`1203`, `1247`) | |
| Sage growth | Sage 13 at **10% (+10%)** with 650 silver (`1236`); Sage 12 green stone 0% (`1242`) | |
| Game end | post from the publisher's community manager: servers were in China, the Chinese company shut the game down (`1241`) | (background) |

### Batch 6 (`batch-06`, photos 1253-1552)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Daily task 250-point chest** | 250 points: **30 000 silver + 100 gold + 10 Reincarnation Pills + 1 Killer B fragment**; chests at 120 / 160 / 210 / 250 points of 250; "reset at 00:00 everyday" (`1328`) | 5th chest 100 gold only; chests 20-100 of 100 |
| **Top-up screen (Google Play)** | VIP0 "0/10, Load another 1$" -> **VIP1 = 10 exp = $1**; VIP2 at 20/300 "Load another 28$" -> **VIP3 = 300 = $30**; VIP4 at 290/1000 "Load another 71$" -> **VIP5 = $100** (`1332`, `1527`, `1402`) | `vip.js` VIP1 $1, VIP3 $30, VIP5 $100: **match** |
| First top-up | "Gold x3 for 1st Recharge": $0.99 = **135**, $4.99 = **675**, $9.99 = **1350** (each pack's first buy is triple, stamp "Rewards x3 for 1st Recharge"); after: $0.99 = 45, $4.99 = 225 + award 15, $9.99 = 450 + award 40, $19.99 = **950 + award 100** (`1332`, `1527`, `1402`, `1550`) | done 2 Nov: first top-up pays triple |
| First Recharge gift + "49$ gift" | First Recharge claim: Tsunade card + Shakujo-like weapon + Rasengan ninjutsu; **$49 gift**: Naruto card + **80 Reincarnation Pills + 150 purple crystals** (progress "12/49") (`1332`, `1527`) | first recharge gift = game table (matches); $49 gift done 2 Nov |
| **Secret shop refresh limit** | refreshes a day = **75 + 5 x VIP**: VIP1 80, VIP3 90 (`1546`), VIP6 105, VIP7 110 (`1362`), VIP10 125 (`1491`); refresh 20 gold, auto 2 h | 99 a day, free |
| Reincarnation 1 pill cost by card | 5-star (Susa Sasuke) **80** pills (batch 3); orange-frame card (Obito) Reinc 1 = **100** pills, +15%, restrain 15 -> 20% (`1492`); god card Reinc results 15 -> 20% con, skill 15 -> 18% (`1289`, `1296`) | `newlifeconfig` per type |
| Sage growth | **Sage 0 -> 1: 95%**, 50 silver, +5% (`1255`); Sage 10 11% / 550; Sage 12 10% / 650; Sage 13 1% / 700; Sage 14 green stone 0% / 750; Sage 15 = +160% (`1364`, `1291`, `1529`, `1370`, `1367`) | silver matches; chances differ |
| God card growth / rebirth bonuses | Pedestrian Sasuke (God): growth Lv3 Chakra +291, Lv6 Attack +291, Lv9 Defense +346, Lv12 Max Attack +937; rebirth 1-8 Attack +222 / 264 / 388 / 572 / 1144 / 2288 / 4576 / 9152 (`1351`); Reincarnated Itachi growth +233 / +233 / +280 (`1542`) | |
| Shinobi training (potential) | "foster 5" = 5 tries at once: **10 ninja pills**, or "gold advance" 5 pills + **40 gold**; god card caps ATK 25 200 / DEF 25 200 / Chakra 12 600 (`1347`); single try 1-2 points, **70%**, **4000 silver** (`1521`) | free, no pills |
| Change Element | **Element Change Pill** x 12 (5-star god card) + **2000 silver**, random element, "Higher quality needs more pills"; pill "Currently not for sale" in shop (`1425`, `1494`) | done 2 Nov: Element Change works (12 pills + 2000 silver for God cards) |
| Shop Tool tab | Tael (small) 2000 silver = **5 gold**, Tael (large) 10 000 = **25 gold** (`1494`) | matches `consumeinfo` |
| Arena exchange (reputation) | The second: Development Dan 15 000 rep; third: Double Exp Pill 8000; four: Element Change Pill 15 000; five: Seal of Kyubi; eight: Naruto Uzumaki (attack card) **480 000** rep (total 1), nine at 120 000 (`1426`, `1488`); rank 1 daily reward 25 000 silver + 5000 rep again (`1421`, `1523`) | matches (exchange_award) |
| Country war | win = **10 points + 10 exploit**; rival who attacks you and fails gives you **2 points + 2 exploit** (log) (`1307`); exploit shop: Shinobi Pack I **1000**, 5x five-star purple fragments **3000**, Equipment Pack III **3000**, Ninjutsu Pack III (`1489`) | done 2 Nov (`war.js`: 10 points + 10 exploit, defender 2 + 2) |
| Cumulative gold (Consume) event, small version | **400** gold: 1-in-10000 ticket + 20 + 30 + 10; **1300**: 5-star Equip + 20 + 50 + 30; **2500**: Ultimate + 40 + 100 + 50 (`1401`, `1416`) | other version; the 1 Nov event uses photo 0347 |
| "Great gift for total recharge" (other version) | **$290**: Susa Shisui(G) + Rinnegan + 160 Reinc Pills + 100 Souls Dan; **$480**: 2nd-Rebirth(G) + **10K gold** + 200 Dev Dan + 250 red pots; **$800**: 7th-Rebirth(G) + 400 crystals + 300 Reinc + 300 Souls Dan (`1363`) | `totalgift.js` uses the `1238` version |
| Listing of Rich (Millionaire) | first prize needs 140; achievements 20 / 60 / 100 / 200 (`1259`), 20 / 60 / 120 / 250 (`1322`, `1379`), 25 / 85 / 160 / 390 (`1497`), 20 / 80 / 130 / 200 (`1540`) | `monopoly.js` |
| Wheel of Fortune ranking | first prize 580; points rewards 30 / 250 / 600 / **1400** or **1600** / 1200 score (`1397`, `1411`, `1415`, `1439`, `1440`); 780 / 1200 score in another (`1500`) | |
| S-shinobi draw | Hokage Naruto(A) / Susa Kakashi(D) / Hashirama(A) / Kaguya(D) / Kazekage(A) headliners; **20 points a draw** (some 30); "Recruit N more" N = 0-4, 7; first prize 240 (`1306`, `1430`, `1445`, `1471`, `1522`) | |
| World boss Sasori | "Battle begins 14:00 daily", Lv 2, HP **23 328 W**, Power +15% (`1419`) | |
| No.1 Shinobi list (arena top) | top players level 350, offense points shown (`1338`, `1456`, `1525`) | |
| Cross-server rank ("Score Ranking") | points per second: rank positions give **+3 or +5 points a second**, "Inspire" button, 18:22 countdown (`1422`) | not built (cross-server) |
| Ninja Test | stage 1 enemies ~1150-1170 DEF, 3/3 tries, score 2150 (`1321`) | |
| Equipment reinforce | cost **50 000** silver (`1323`, `1520`) | |
| iOS store change | "Ninja Online is back in the store" as **Beast World** by XIAOTENG CHEN (Gumptech) (`1437`, `1442`) | (background) |

### Batch 7 (`batch-07`, photos 1553-1745)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Second team line-up** | "When the second team line-up has reached **level 100**, it is activated"; it can use all shinobi, ninjutsu and equipment (shared with team 1); "Activate team" picks the one used; only one active (`1723`) | not changed (team 2 is in the game app) |
| Secret shop refresh limit | **75 + 5 x VIP** again: VIP1 80 (`1587`), VIP3 90 (`1567`), VIP5 100 (`1600`), VIP6 105 (`1594`), VIP14 145 (`1578`); 20 gold a refresh, auto refresh 2 h | |
| Secret shop prices (souls) | Danzo 130 / 4000, Hanzo 600, Six Paths Obito 1200 / 800, Fourth Kazekage 170, Sasuke 650 / 25 000, grain x10 400, nostrum x10 400, Sasori 130, Killer B 270 / 650, Kaguya 1000, Fukasaku 170 / 20 000, Second Mizukage 600, Goddess Sakura 1000, Kakashi Hatake 600 / 500, Madara 45 000, Kurama 650, Naruto 500 / 15 000, Mei 600 / 130, Itachi 10 000, Deva Path 130, Rebirth Tsunade 1000, Senju Tsunade 170 / 600, Hiruzen 170, Night Kai 1000, Hashirama 15 000 / 700, Human Path 4000, Minato 650 / 500, Six Paths Madara 1000, Six Paths Naruto 1000, Santa of the Six Paths 3500, Sasuke and Sakura 4000, Gamakichi 620, Nagato 650, Kushina 1000, Teenager Naruto 650, Kabuto 650 / 25 000, Ten Tails 8000, Gama Sennin 25 000, Sage Naruto 780 / 45 000, Indra 850, Obito 500, Fourth Raikage 600 / 460 (`1567`-`1611`) | |
| Soul disenchant (card -> ninja souls) | 5-star level-50 cards give **2000** souls, other cards **1000**, low cards 150 (`1568`-`1571`, `1588`) | `game.soulOf` |
| Grudge | "Grudge Lv 3/8", next 1:23:02, full 9:23:02 = **2 h a point**, max **8** at VIP11 (`1590`, `1591`); batch 20 showed 7/7 | matches (playerlevel grudge max, 2 h a point) |
| Spar | lost 1679 / 1787 / 1901 / 2022 silver in a row (each ~6.5% more = a share of own silver) (`1584`); win preview vs level 206: 15 W.A., silver 1978 (`1703`) | |
| Tailed-beast seals (8 fragment kinds each, from Plunder) | Shukaku ATK +35%; Matatabi ATK +40%; Isobu DEF +45%; Son Goku DEF +50%; Kokuo DEF/ATK +30%; Saiken DEF/ATK +40%; Chomei DEF/ATK +50% and skill +3%; Gyuki DEF/ATK +60% and skill +3%; Kurama DEF/ATK +70% and skill +3%; Ten-Tails DEF/ATK/Chakra +80% and skill +3% (`1596`-`1599`, `1696`) | matches (markinfo) |
| Reincarnation 4 (5-star orange Naruto) | basic value +70%, restrain 35% -> 35%; 1 same card OR **550** Reincarnation Pills (`1656`) | |
| Reincarnation result (Six Paths Naruto God) | 900-1240 / 543-747 / 637-880 -> 1033-1423 / 623-857 / 731-994 (x1.147), con 35%, skill 25% (`1616`) | |
| God breakthrough +1 (Six Paths Sasuke God) | ATK +1136, DEF +723, Chakra +206, trigger ninjutsu +1%, five-line restrain +2%; **250 000 silver** (`1706`) (Kyuubi Naruto was 60 000, so the price depends on the card) | |
| Equipment reinforce | help text "reinforce three times, Attribute **+50%**", merge two lower advanced cards, level back to 1, **50 000** silver (`1698`) | |
| Eight Inner Gates | LV45 point: **3514 souls + 52 710 silver** (15x), Chakra +1230; totals +106 159 each and +21% / +21% / +23.5% (`1737`) | |
| Sage growth | Sage 12 **10%** at 650 silver (+10% with more stones; 19 stones gave +3.8%); green stone 0% at Sage 12 (`1561`, `1604`, `1653`, `1665`, `1686`-`1688`); Sage 15 bonus +160% (`1613`) | |
| Giftpack shop | **SageStone I Bag** (100 Sage Stone I, levels 1-5) **500 gold**; **SageStone Bag** (100 Sage Stone III, levels 6-12) **1000 gold**; **golden Choji Akimichi** (EXP card) **50 gold**; one item 200 gold (`1699`, `1734`) | matches (giftinfo) |
| Top-up | "The first charge 3 times": $19.99 = **2850** (= 950 x 3) (`1728`) | |
| Wheel of Fortune | "Turn 10 times" costs **1000 gold** (8239 -> 7449 incl. a 210 gold prize -> 6449 -> 5449 ...); prizes The Fourth Sage (God) card, Orochimaru card, 5 grain, 5 nostrum, Development Dan, 5 Tael (large), 2 Reinc Pills, 15 Sage Stone III, Souls Dan, Gold x210 (`1627`-`1632`); "Turning once 10 points (1st try is free daily)", Super award pool (`1725`) | `wheel.js` |
| Event rankings | min for 1st prize **700**, points rewards 20 / 300 / 500 / 1600 (`1586`), 30 / 320 / 720 / 2000 (`1704`), 50 / 320 / 720 / 2500 (`1726`); "points rewards will be cleared 1 day after the event" | |
| S-shinobi draw | Susa Madara (D): 300 gold, **10 points a draw**, "Recruit 5 more will get one", min 240; rewards 1 Susa Madara, 2 Six Paths Obito, 3-4 Hashirama, 5 Ten Tails (A) (`1625`); Madara+Senju (G) fragments: rank 1 frag x20, 2 x15, 3-5 x10, 6-10 x5 (`1673`) | |
| Listing of Rich (Millionaire) | min 1st prize 120, achievements 10 / 80 / 120 / 280 (`1650`); min 200, achievements 50 / 200 / 360 / 650 (`1663`) | `monopoly.js` |
| Scratch card ("Lottery" tab in Event) | "Scratch out 3 identical cards to get great rewards", free chances, prizes 5 gold, **150 gold** "So lucky" (`1658`, `1729`) | built 1 Nov (`scratch.js`) |
| Cumulative gold (small) | 150 gold -> 5 items; 500 -> 10 scrolls; 2000 -> 1-in-10000 ticket + 20 purple orbs (`1724`) | |
| Akatsuki worship (donate) | 10 gold -> fund +12, contribution +12; each 4-star ninja / equipment / ninjutsu -> fund +18, contribution +12; each 5-star -> fund **+180**, contribution **+180** (`1676`-`1680`) | done 2 Nov (`guild.js` donations, card donations built) |
| Akatsuki upgrades | Mall Lv4 15 000 (3 spots, needs Lv9), Donate Lv4 13 000 (20%), Hall Lv4 20 000 (140%), Group Lv9 max (`1730`) | same as batch 2 |
| World boss Kakuzu | Lv1 HP **9072 W**, Power +15%; reputation shop 40 000 / 25 000 / 12 000 / 1000 / 350 (`1603`) | `boss.js` |
| Border | wander/taunt 2 a day, clearance 4 a day; wandering cleared: EXP 6600 + 1608 merit; breaker reward Sage Stone II + Hashirama chest (`1733`) | |
| Country war | war every night 18:30-19:30, auto declare war (`1583`); win screen W.A. +10, combos 10 (`1560`); exploit shop 5-star purple fragment x15 = 7000 (`1716`) | |
| Pets (beasts) | Ningame 950 / 740 / 780, "beast hit 1/3 chance cause 200 damage"; Gamakichi 870 / 660 / 700, 185 damage; total beast bonus panel 26 525 / 22 235 / 19 795 (`1623`, `1641`, `1642`) | `pet.js` |
| Ninjutsu set | "Six Paths" set of 4 ninjutsu; "Ninjitsu set points will be counted in during activation of ninjutsu"; Shinra Tensei 719 ATK/DEF at lv50 (`1649`) | |
| Ninja Treasure (3x3) | refresh 100 gold, explore 35 gold, ~1:27 countdown (`1619`) | |
| System mails (compensation) | "100 golds, 100 ninja pills, 30 evo pills"; 30 000 silver + 5 Double Exp Pill + 50 Sage stone; 30k silver + 30 Sage stone + 5 Development Dan; "Last festivity 1600 gold"; "Compensation for WB issue: 100 Gold"; Christmas gift (`1621`, `1667`, `1668`) | |
| **Killer B (Santa Claus)** | card found: Rewards preview 412-420 each; chains Third Raikage +25%, equip Tailed Beast Mode +25%, Naruto Uzumaki +25%, Fourth Raikage +25%, trinket Kohaku Johei +25%, all ATK/DEF +3% (`1566`) | |
| Other cards (Rewards screens) | Six Paths Madara 515-700 / 310-420 / 353-490, chains Six Paths Obito / Rinnegan / Shakujo / Sage of Six Paths +25% ATK, all +13% (`1582`); Dice Tsunade 520-712 / 311-422 / 365-500 (`1607`); Susa Shisui 315-415 / 515-695 / 360-495 (`1612`); Six Paths Obito 490-620 / 294-372 / 343-434 (`1624`); Naruto and Hinata (DEF) 290-375 / 480-620 / 340-440 (`1581`); Kazekage Gaara 452-592 / 280-360 / 315-415 (`1589`); Ten Tails chains all Chakra +40%, Kurama all Chakra +30% (`1638`, `1639`) | data tables |

### Batch 40 (`batch-40`, photos 1751-1924)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Reincarnation pills (god cards)** | a player's note: "God 100 1st, 180 2nd, 350 3rd, 510 4th, 720 5th, 850 6th, 1030 7th, 1130 8th" (`1817`) = exactly `newlifeconfig` grade 6; 5-star level 4 needs 550 (`1656`) | **matches** (server reads `newlifeconfig`) |
| **Arena daily rank reward** | shown next to rivals: rank 7 19 000 silver + 3800 rep, 8 18 000 + 3600, 9 17 000 + 3400, 10 16 000 + 3200 (`1901`) = 26 000 - 1000 x rank and 5200 - 200 x rank, confirmed to rank 10; arena win: EXP +60, silver +90, rep +190 (`1842`) | |
| Shinobi training (potential) | "Attributes increase 1-2, 1 pill a time, success **70%**, silver **4000**"; "Shinobi's Potential: 1219 - Level Up, Reincarnation grants potential points" (`1796`); caps 5-star card **9600 / 9600 / 4800**, god card **12 400 / 12 400 / 6200** (ATK / DEF / Chakra); "foster once" 2 ninja pills, or "gold advance" 1 pill + **10 gold** (`1835`, `1839`, `1840`) | |
| Top-up | system mails "You paid 1$ and purchased **45** gold", 5$ -> **240**, 10$ -> **490** (`1813`); PayPal web list again 0.18 = 8, 1 = 45, 5 = 240, 10 = 485, 15 = 740, 30 = 1590, 100 = 5500, 200 = 12 000, 500 = 29 000 (`1919`) | |
| Monthly sign-in (July) | day 1 **5000** silver (VIP1 x2), 2 Sage Stone x20, 3 x3 (V2 x2), 4 card (V3 x2), 5 x3, 6 25 000 silver, 7 x5 purple (V4 x2), 8 50 gold, 9 card (V5 x2), 10 x5, 11 20 purple (V6 x2), 12 card, 13 15 Reinc (V7 x2), 14 30 000 silver (V8 x2), 15 x6 purple, 16 50 gold (V9 x2) (`1871`, `1884`) - same pattern as May but day 1 5000 | done 2 Nov (`signin.js`) |
| Ninja Test | "The 4 Checkpoint": 5 guards with **~2971-2986 DEF** each, exchange points 1150, 3 tries a day (`1811`); team of 5 picked from all cards (`1845`). With stage 1 1150 and stage 2 1950 this is about **+500 to +800** a stage | server +800 a stage |
| Sage growth | "More purple sage stones, higher successful rate will be. Never regress when level reach to 3,6,9."; **5 Growth** button; Sage 10 11% / 550; Sage 12 10% / 650 (2% with 0 stones); Sage 13 8% / 700; growth bonus Sage 10 +70% -> +90% (`1870`, `1877`, `1885`, `1887`) | |
| Eight Inner Gates | LV23 point 4: **2252 souls + 33 780 silver** (15x), +563; totals +35 599, +5.5% / +7% / +7% (`1825`) | |
| Evolve | 4-star card **30** evolve pills, 5-star **85** (`1762`, `1764`); "Reincarnation and growth will be retained" | |
| Akatsuki | Lv3 = **9** members (fund 349) (`1769`); Lv8 = **14** members (fund 16 804) (`1786`); jobs chieftain / vice chieftain / ordinary; mall prices 190 / 420 / 700 / 420 / 2100 + 900 gold / 2250 contribution, refresh ~30 min (`1864`) | done 2 Nov: members = 6 + level, mall prices |
| War exploit shop | two price lists: Shinobi Pack I **1000** / 6000; five-star purple fragments x5 3000 / 7000; Equipment Pack III 3000 / 8000; Ninjutsu Pack III (`1832`, `1833`); war rewards chests 1000 / 3000 / 3000 / 4000 / 5000 achievements, resurrections can be bought (`1850`) | |
| Country war win | vs level 219: EXP +30, silver +30, W.A. +10 (`1898`) | |
| Daily "Complete the designated lines" | "10 times to soul" -> 15 Sage Stone III (2 a day); "Ninja-cultivation-10-times" -> 5 Super Ninja Pills (4); "1-times-of-evolution" (`1803`) | `rl_r_multiple_task` |
| Pet fragments | Aoda, King of Hell, Katsuyu, Gamakichi, Kamatari: 30 fragments each, "Fragment can be obtained at mystery shop" (`1806`, `1807`); King of Hell 980 / 770 / 790 (`1900`) | |
| Ninjutsu base values (level 1) | Tailed Beast Mode 91, Sage Mode 95, Big Ball Rasengan 99, Reincarnation 103, Eternal Mangekyo 107, Izanagi 119, Sword of Flying Thunder God 121 (weapon), Nativity of a World of Trees 127, Shinra Tensei 131, Demonic Statue 135, Dead Demon Consuming Seal 139, Raiton Elbow 143, Six Paths Rinnegan 150; Iai Beheading (4-star) lv50 355 (`1808`, `1851`-`1860`, `1863`) | matches (ninjutsuinfo) |
| Event rankings | wheel: min **700**, points rewards 20 / 320 / 720 / 3000 or 3300 (`1799`, `1805`, `1868`); S-shinobi draw: Hokage Kakashi / Kyuubi Naruto / Madara (A) / Minato, min 240 (`1816`) | |
| World boss | Hidan Lv5 17 496 W (`1821`), Obito Lv10 145 800 W (`1892`), Sasori Lv15 126 554 W (`1918`); "Battle begins 14:00 daily"; reputation shop 40 000 / 25 000 / 12 000 / 1000 / 350 | |
| Plunder log | "won you, and stole Saiken Seal Fragment 5 from your hands" / "failed to steal" (`1888`) | |
| Story stage | "Defeated Sasuke Uchiha": EXP 60, silver 90, drop "Mystery Treasure" (`1815`); victory "Please draw your victory reward" with 3 cards (`1847`, `1866`) | |
| Double Exp Pill | "receiving X2 exp during training in 5 min" (`1907`) | |
| Other cards | Asura 455-578 / 266-345 / 320-425; Indra 268-351 / 446-585 / 310-412; Uzumaki Boruto 468-608 / 284-368 / 330-428 (chains Naruto +30%, Hinata / Sage Fourth / Kushina +25%, all +12%); Itachi 466-500 / 279-300 / 327-350; Sage Jiraiya 465-515 / 275-315 / 335-365; Hiruzen 192-252 / 321-421 / 225-295; Hashirama 458-550 / 274-330 / 321-385; Uchiha Madara 265-348 / 442-580 / 310-406 (`1779`-`1923`) | data tables |

### Batch 80 (`batch-80`, photos 1928-2227)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Save time (ramen -> exp)** | "Chapter 11 chapter, 6 round, Benefit: Exp **3200**, Silver **3800**"; Ramen = **Big Ramen** (Buy); "chances", "Gain **10 Gold**", "VIP1 **+2/day**"; "(only for **VIP1** and those over **Lv.80**)" (`2212`). Stage 11-6 = 18 energy, 270 exp, 324 silver, so 3200 / 3800 = 12 fights (ceil 200/18) rounded down to hundreds | **changed 2 Nov to match exactly** |
| Level up | "LEVEL UP 280 -> 281", attack/defence up, "Energy ↑ Grudge ↑" = a level-up refills energy and grudge (`2156`) | |
| Evolve | god evolve 100 pills (`2065`, `2066`, `2169`); "Successful evolution! [53] super ninja pills returned!" = pills spent on shinobi training come back when a card evolves (`2167`) | done 2 Nov: evolve costs 100 Development Dan (pills returned: not tracked) |
| Succession (inherit) screen | "Succession card level, reincarnation and growth are transferred to the inheritance card ... After succession is complete, succession card will ..." (`2016`) | built 1 Nov (succession, no button in v28) |
| Reincarnation | Reinc 1: 80 pills, +15%, 15 -> 20% (`2214`); Reinc 2: 160, +35%, 20 -> 25% (`2161`, `2184`); Reinc 3: 320, +50%, 25 -> 35% (`2149`); results: Goddess Sakura attributes 15 -> 20%, skill 15 -> 18% (`2106`); Kamui Kakashi 20 -> 25%, skill 18 -> 21% (`2108`); Mei Terumi 25 -> 35%, skill 21 -> 25% (`2020`) | `newlifeconfig` **matches** |
| God card growth / rebirth | The Fourth Sage (God): growth Lv3 Chakra +236, Lv6 Attack +236, Lv9 Defense +284, Lv12 Max Attack +793; rebirth 1 Attack +177, 2 +213, 3 +319 (`2141`); Night Kai same growth, Lv12 +782 (`2145`) | |
| Arena | rank 1-4 rewards 25 000 + 5000, 24 000 + 4800, 23 000 + 4600, **22 000 + 4400**; claim countdown (daily); "Number of challenges: VIP2 **+1** times" (`2119`, `2128`, `2203`) | |
| Spar | win vs lv118: EXP +54, silver +1520, grudge -1, draw a victory card (`2163`); search result win W.A. 15, silver 488 (`2117`) | |
| Eight Gates | LV1 first point: **80 souls + 1200 silver**, Chakra +200 (`2171`) | |
| World boss reputation shop | Super Ninja Pill 2000 rep; Souls Dan ("receive 1000 souls per day for eight gates") 2500; Six Paths Obito (God) fragment 3000 rep + 150 gold; 5 Reinc Pills 4500; 20 Sage Stone III 3500 (`2172`); bosses Konan Lv15 40 778 W (`2028`), Hidan Lv15 40 824 W (`2094`), Sasori Lv15 104 859 W / 126 554 W (`2179`, `2191`), Deidara Lv30 69 700k (`2215`) | `boss.js` |
| Secret shop | refresh 1/80 at VIP1, 61/95 at VIP4 (+5) = 75 + 5 x VIP again; prices Fukasaku 170 / 5000, Hiruzen 170, Senju Tsunade 650, Fourth Kazekage 650 / 170, Reincarnation x2 460, Naruto and Hinata 600 / 800, nostrum x5 260, Danzo 4000, Gamakichi 620, Gama Sennin 220, Onoki 170; Disenchant button (`2101`, `2209`, `2210`) | |
| Pets | King of Hell Lv2 "1/3 chance cause **227**" 1130 / 920 / 870 -> Lv3 **234**, 1280 / 1070 / 950 (+7 damage, +150 / +150 / +80 a level), uses "grain" (`2099`); Aoda 925 / 765 / 785 (`2125`) | `pet.js` |
| Akatsuki | Lv3 = 9 members; jobs chieftain / vice chieftain / team leader / ordinary (`2183`); max levels Group 9, Mall 5, Donate 5, Hall 5 (`2115`); mall 3000 con + 1800 gold, 1500 + 900, 1400 + 600, 4000 + 2400, 190, refresh ~27 min (`2113`) | |
| Change country | Wind / Thunder / Water / Soil; costs gold, "related to population of target country" (`1999`) | |
| Team bonus panel | "Five Six-Star Cards ATK+5400 ATK+11% DEF+5400 DEF+11%", "12 Six-Level Cards ATK+1300 ATK+2% DEF+1300 DEF+2%" (`2005`) | |
| Story achievements | per-chapter tab ("is Tobi", "Returning", "Dead Madara", ...): requirement 22 -> EXP 550 + 600 silver, progress 0/4 (`2054`) | |
| S-shinobi draw | "Recruit 9 / 4 / 2 / 1 more will get one" = event pity **10**; 300 gold; 10-20 points a draw; min 240; headliners Six Paths Madara (D), Asura (A), Uchiha Shisui (A), Six Paths Sasuke (A), Naruto&Hinata (D), Sasuke (A) (`2003`, `2017`-`2022`, `2116`, `2218`, `2219`) | |
| Event rankings | wheel min 700 / 1000; points rewards 50 / 320 / 720 / 3600, 30 / 320 / 720 / 3500, 50 / 350 / 420 / 3000 (`1994`, `2077`, `2132`); Listing of Rich min 200, achievements 20 / 120 / 320 / 390, 20 / 160 / 200 / 480 (`2004`, `2070`, `2165`) | |
| Limited group purchase | "All-server limited group purchase gifts" (34 h): Super giftpacks with original and discount price, 49 left each, e.g. 100 Super Ninja Pills 1500 gold (`1931`) | built 1 Nov (`groupbuy.js`) |
| Tool shop fragments | 5-star shinobi purple / 4-star equipment blue / 5-star equipment purple / 4-star ninjutsu blue fragments: "Every 50 fragments can synthesise to a ... card", not for sale (`2002`) | |
| Recruit gold prizes | Gold*100, *270, *500, *2000 (`1939`, `1940`, `1992`, `2076`) | |
| Ninjutsu at level 50 | Big Ball Rasengan 589, Tailed Beast Mode 532, Sage Mode 530, Reincarnation 593, Amaterasu 650, Tsukuyomi 654, Susanoo 711, Nativity 715, Shinra Tensei 719 (`1962`-`1967`) = level 1 value + 49 x growth from `ninjutsuinfo` | **matches** |
| Fan-made / other games | `2186`-`2189`, `2227` (a different Naruto game), `2018`, `2031`, `2170` (not game screens) | skip |

### Batch 81 (`batch-81`, photos 2228-2250 and 2383-2660)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Ninja Test guards scale with level** | stage 14 guards ~480 for a **level 61** player (`2553`) but ~10 062 for a **level 281** player (`2448`); stage 4 ~2979 at level 302 (`1811`). One rule fits all three within 1%: **0.00705 x stage^1.1 x level^2** | **changed 2 Nov** (was 1150 + 800 a stage for everyone) |
| Ninja Test chests | stage 15: free / 160 gold / 250 gold (`2446`); stage 5: free / 160 / 250 (`2617`) | |
| **Growth Plan (Growth Fund)** | "Only insert **500** Gold, can get **5** feedback, total **2500** Gold (Only **VIP3** and above buyers may purchase)"; Lv.50 **150**, Lv.70 **150**, Lv.90 **200**, Lv.110 ... (`2627`) | **built 2 Nov** (steps from Lv.110 ours) |
| Level gift packs | Lv.260 / 270 / 280 / 290 Gift Pack ("Lv.260 player will win Newbie Gift Pack"): ramen, 14 000-15 000 silver, 270-410 gold, 12 ..., 5-star ninjutsu card (`2655`) | matches (the game's own level gift table, up to Lv350) |
| Team slots | "Lv. 100 and customs clearance 7 Round 6" (`2505`), "Lv. 70 and customs clearance 4 Round 4" (`2640`) | `newcardinfo` **matches** |
| Treasure event | "Whatever you want can be found": gold / silver / bronze chests opened with keys; "chances today to open the treasure chest: 75/75, VIP1 +5 times" (`2442`); keys drop as victory cards ("Bronze Key", `2500`) | built 1 Nov (`box.js`) |
| Battles (story missions) | 1-6 requirement 21 -> EXP 546 + 651 silver (Finish); 1-7 "Tragically Hopeless" (offensive war) 22 -> 572 + 682, 3 challenges left (`2232`); 4-6 20 -> 520 + 600, 4-7 "Madara Vanish" BOSS 21 -> 525 + 630 (`2479`); copy progress rewards 147 / 154 / 161: 450-500 souls + Reinc Pill + 4-star card (`2428`) | matches (roundinfo: Madara Vanish 525 / 630, Tragically Hopeless 572 / 682) |
| Reincarnation | Reinc 2 160 pills, Reinc 3 320 pills (`2161`, `2399`); Night Kai con 30 -> 35%, skill 21 -> 25% (`2528`) | matches |
| Equipment reinforce | Flying Thunder God Kunai 225 -> +1 **337** (x1.5), 50 000 silver (`2497`) | |
| Ramen shop | small ramen 100 energy **10 gold**, large 200 energy **20 gold**; "VIP +2 times/day" buys (`2519`) | |
| Seals | Ten-Tails Seal "Shinobi damage increase", level 2 +15% (`2494`); Son Goku DEF +50%, Kokuo DEF/ATK +30% (`2514`) | |
| Akatsuki members | Lv2 = 8, Lv3 = 9, Lv6 = 12 (`2465`, `2551`) | |
| Messages | War: "has defeated you, and stole Elder position"; Plunder: "stole Kurama Seal Fragment 6"; Spar -1645 silver (`2541`); "You paid 48$ and purchased 2395 gold"; "Compensation for servers merging 30000 silver" (`2556`) | |
| Daily lines | "32-multiples-3-times" 20 Reinc Pills 2/2; "3-times-1-in-10000"; "10-times-to-soul" (`2653`) | |
| Sage growth | Sage 10 5% / 550, Sage 12 10% / 650, Sage 13 8% / 700, Sage 14 7% / 750 (`2402`-`2407`, `2620`, `2621`, `2637`, `2638`); player memes about failing Sage 11 -> 12 (`2588`-`2590`) | |
| Event rankings | wheel min 700, points rewards 20 / 150 / 320 / 2500-3300; Listing of Rich min 200, 20 / 160 / 200 / 450 / 600, or 20 / 50 / 100 / 1000 Steps (`2417`-`2600`) | |
| W.A. titles | No.1 Shinobi list "Ninja Rank": Elite Jonin, Junior Kage, Middle Kage (`2593`) | game table (playemedal) |
| Other | official Twitter @NinjaOnlineEN (`2424`, `2538`); Chinese-version screenshots (`2398`, `2534`, `2539`) and memes skipped | |

### Batch 82 (`batch-82`, photos 2661-2976)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Arena daily reward (all ranks)** | rank 2053: claimable 2700 silver + 540 rep; rivals at ranks 1253-1953: **2000 + 400** (`2719`); reputation always = silver / 5 | **changed 2 Nov** |
| **Ninja Treasure prices** | explore by prizes taken: 0 -> **35**, 1 -> **70**, 2 -> **300**, 3 -> **320**, 4 -> **1000**; refresh **100**, board every **2 h** (`2816`, `2819`, `2833`, plus `0018`, `0150`, `1070`-`1073`) | **changed 2 Nov** |
| **Shop prices** | Reincarnation Pill **120**, Development Dan **120**; Souls Dan, Double Exp Pill, Super Ninja Pill "Currently not for sale" (`2964`, `2965`) | **changed 2 Nov** (table 180 / 200) |
| Recruit free timers | 1 in 10000 "Free after **4 days 9 hours**", 1 in 1000 "Free after **2 days 9 hours**" (`2780`, level 44 player); batch 4 showed 2 d 16 h / 0 d 16 h | owner remembers 24 h / 8 h: **owner's decision** |
| Seal slots | slot 1: "reach level 230, or Middle Chunin and level above 220" (`2837`); slot 2: "level 290, or Elite Jonin and level above 280" (`2939`) | decided by the game app |
| Team bonus panel | "12 Five-Star Cards ATK+3800 +7%", "7 Six-Star Cards ATK+5800 +12%", "19 Nine-Level Cards ATK+2900 +5%", "still closed 21 Nine-Level / Five Twelve-Level Cards" (`2837`, `2939`) | game table (suit_info) |
| Five-element (camp) bonus panel | per element: ATK 81.31% / DEF 60.98% / Chakra 61.00% / ninjutsu rate +8.15%; 40.65 / 40.65 / 40.65 / 5.10%; 35.57 / 35.57 / 35.55 / 4.05%; 60.98 / 81.31 / 61.00 / 8.15%; 30.49 / 30.49 / 30.50 / 3.05% (`2666`) | not built (camp bonus) |
| Ninja Test | stage 1 guards 1173-1184 for a level-272 player (`2678`); stage 15 chest "spend gold 250 to open?" (`2954`) | fits the 2 Nov formula |
| Spar losses | same rival in a row: 626, 659, 693, 730, 768 ... 980 silver (`2724`, `2725`); at level 294: 165 811 -> 206 141 (`2765`) = about 5-7% of own silver each time | not changed: the silver pattern could not be worked out |
| Eight Gates | LV17 point 7: **2449 souls + 36 735 silver** (15x), +449; totals +23 163, +4% (`2910`) | |
| Border | taunted once: EXP 6900 + 1385 merit; breaker special award Gold*50 + Super Ninja Pill + Reincarnation Pill (`2705`) | |
| Award Center | "rewards remain for 7 days", Claim All (`2706`, `2737`) | |
| Daily lines | "secret-shop-refresh-5" -> Refresh Order; "1-times-of-evolution" -> 15 Development Dan; "3-times-1-in-10000" -> 1-in-10000 ticket (`2730`, `2731`) | `rl_r_multiple_task` |
| Arena exchange | 1st Sasuke Uchiha (attack card) 480 000 rep (total); 2nd Development Dan 15 000 (daily); 3rd Double Exp Pill 8000; 4th Element Change Pill (`2691`) | |
| Giftpack shop | Ninja Bag (S) 10 EXP ninja cards **2000 silver**; Ninja Bag (L) 50 cards **13 000**; Weapon Bag (S) 10 weapon cards 2000; Armor Bag (S) (`2695`) | done 2 Nov: small bags 2000 silver |
| Limited group purchase | super giftpacks: 500 -> 250 gold (198 left), Kamatari 250, Pakkun 12 000 -> 5500, 15 000 -> 7500 (`2792`) | built 1 Nov (`groupbuy.js`) |
| Pets | Ningame Lv1 214 damage, Pakkun Lv5 250 damage (`2781`); Kamatari 880 / 650 / 720 (`2825`); pet fragments from the mystery shop (`2960`) | |
| Sage growth | Sage 8 **20%** / 450 silver (+50% -> +60%); Sage 10 11% / 550; Sage 12 10% / 650; Sage 13 4% / 700 (`2709`, `2710`, `2758`, `2817`, `2958`) | |
| World boss | "Heroes ranking", "The reputation will be clean at 14:00 next day" (`2750`, `2806`); Konan Lv3 12 816 W (`2936`), Hidan Lv9 26 827 W (`2866`) | |
| Evolve | 5-star 80, god 100 (`2677`, `2919`) | |
| New account | "Please choose a teammate": Shikamaru / Sakura / Neji (`2711`) | **matches** |
| Event rankings | wheel min 700, points 20 / 150 / 320 / 2200-2500; S-shinobi draws (Susa Shisui, Kaguya (A), Six Paths Madara (D), Hamura Otsutsuki (A)...) min 240 | |
| Not game screens | Google image searches `2842`-`2857`, fan art, memes, a player spreadsheet (`2932`) | skip |

### Batch 83 (`batch-83`, photos 2977-3281)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Ninja Test guards (more photos)** | stage 15: ~12 066 (level 269, `3049`), ~13 600 (level 267, `3098`), ~21 300 (level 289, `3075`); stage 14: ~11 330 (level 267, `3104`). The same stage differs a lot between players of nearly the same level, so the original guards followed **each player's own team strength**, not only level (all 10 Ninja Test photos side by side: `zexam2` contact sheet) | server: stage value x (level/280)^2 (a fair middle, ours) |
| Secret shop | refreshes 106/110 at VIP7, 68/80 at VIP1 (= 75 + 5 x VIP), refresh countdown 1:59:40 (`3045`, `3046`, `3108` 99/100 VIP5) | **matches (built 2 Nov)** |
| Shop | Ramen small 10 / large 20, Hyourou-gan 8 / 10 (`3018`); Development Dan 120 (`3230`); fragments and ninja souls "Currently not for sale" (`3261`) | matches |
| Reincarnation | Sasori of the Red Sand (god) Reinc 1: +15%, constrains 10% -> 15%, 1 card OR **100** pills (`3004`); Reinc 3: +50%, 20% -> 30%, 320 pills (`3061`); results con 20 -> 30%, skill 21 -> 25% (`3081`); 10 -> 15%, 15 -> 18% (`3183`, `3184`) | `newlifeconfig` matches |
| Change country | costs **300 gold** ("related to population of target country") (`3270`) | built 1 Nov (Immigration Card + 300 gold), checked in game 2 Nov |
| Story stage | "Defeated Uchiha Obito": EXP 150, silver 225, drop "Mystery Treasure" (`3266`); Battles 10-7 requirement 14 -> EXP 194 + 190 silver, 10-8 "Seal Summon" BOSS 15 (`3167`) | |
| Spar | losses to a level-273 player: 3226, 4306, 4581, 4873, 5184 silver (`3021`); spar search: win W.A. 15, silver 392 / 1499 / 2604 (`3006`, `3231`, `3239`) | |
| Cross-server | server ranking points (147 843 ...), Cross-Server Arena GiftPack 850 000 / 600 000 / 300 000 / 100 000 / 24 000 points (`3015`, `3023`); live score "+3 points / second", Inspire (`3238`) | not built (cross-server) |
| Country war | win: EXP +54, silver +54, W.A. +10, combos 600 (`3030`); "Victory in the war! Your country won the war against Land of Thunder (click the box to claim)" (`3029`, `3242`) | |
| Akatsuki | mall 70 / 30 / 20 / 225 / 1500 + 900 gold / 1400 + 600 contribution, refresh 29:33 (`3008`, `3063`); max levels Group 9, Mall 5, Donate 5, Hall 5 (`3011`); guild list level 4 with 8-10 members (`3085`) | |
| Daily lines | "32-multiples-3-times" -> Souls Dan (`3277`) | |
| World boss | Konan, Kakuzu, Obito Lv9 134 136 W, "Power +80%"; reputation 30 000 / 15 000 / 12 000 / 400 / 350 (`3207`, `3208`, `3217`, `3256`) | |
| Event rankings | wheel min 700 / 1000 / 1200 / 1500, points 50 / 140 / 360 / 3500 (`3216`, `3218`, `3249`); Listing of Rich min 200 / 400, achievements 50 / 120 / 200 / 480 (`3044`, `3235`) | |
| Sage growth | Sage 12 7-10% / 650, Sage 13 4% / 700 (`3050`, `3143`, `3191`, `3245`) | |
| Not game screens | fan drawings `3109`-`3132`, `3140`-`3147`, `3156`, `3168`, `3171`, Storm 4 game boxes, a group notice about a quiz (`3236`) | skip |

### Batch 84 (`batch-84`, photos 3282-3584)
| Topic | Original (picture) | Server now |
|---|---|---|
| W.A. ranks 7-13 | 7 Senior Chunin 15 000 +450, 8 Elite Chunin 30 000 +550, 9 Junior Jonin 45 000 +650, 10 Middle Jonin 60 000 +750, 11 Senior Jonin 90 000 +850, 12 Elite Jonin 120 000 +950, 13 Junior Kage 160 000 +1100 (`3382`) | `playemedal` **matches** |
| Shinobi colour / growth cards panel | "Five Six-Star Cards ATK/DEF/Chakra +5400, +11%", "7 Six-Star +5800 +12%"; "Five Twelve-Level Cards +3200 +6%", "7 Twelve-Level +3400 +6%", "Five Nine-Level +2000 +2%" (`3453`, `3544`); 12 Five-Star +3800 +7% (`3429`) | 4/5-star and growth rows **match** `suit_info`; Six-Star rows are from a later game version (not in this app) |
| Seal slots | "level 240, or Senior Chunin and level above 230" (`3381`); "level 250, or Elite Chunin and level above 240" (`3429`) | decided by the game app |
| Pet advance | Pakkun Lv2 "advance": attributes +1450 -> +2600, consumes nostrum, **success rate 70%** (`3483`) | matches (petupgradeequ: 70%, 1450 -> 2600) |
| Battles (copy) progress rewards | 161: 500 Ninja Souls + Reinc Pill + Five-Star Armor Card; 168: + Five-Star Ninjutsu Card; 175: + Five-Star Weapon Card (`3486`); stage rewards 8-5 EXP 598 / 713, 8-6 BOSS 624 / 744, 9-6 650 / 775 (`3508`-`3511`) | matches (roundinfo) |
| Story | "Defeated Sage of the Six Paths": EXP 172, silver 258, Mystery Treasure (`3488`) | |
| Arena "Lucky ranking" | rank 1 25 000 + 5000, rank 2 24 000 + 4800 (`3365`) | matches |
| World boss reputation exchange | Super Ninja Pill 2000, Souls Dan 2500, Six Paths Obito (God) fragment 3000 + 150 gold (`3372`); bosses "Battle begins 12:30 daily" on some servers (`3391`) | |
| Treasure event | gold / silver / bronze chests with keys, "Chances today 25/25, VIP1 +5 times" (`3574`) | built 1 Nov (`box.js`) |
| Limited group purchase | super giftpacks 80 x item 4000 -> 2000, 300 purple 3000 -> 2000, 100 x 3000 -> 1500, 500 -> 250 (`3364`, `3450`, `3568`) | built 1 Nov (`groupbuy.js`) |
| Akatsuki | "Join Akatsuki" group details: min level 69, min attack 420 (`3458`); Lv3 = 9, Lv6 = 12 members (`3504`, `3562`) | |
| Eight Gates | LV25 point 7: 3624 souls + 54 360 silver (`3569`) = same as batch 1 | |
| Event rankings | wheel min 500 / 600 / 2000; Listing of Rich min 250 / 400; S-shinobi draw (Kaguya for New Year, Hokage Kakashi (D), ...), "After another 6 recruits, the next will grant you a Purple Card" | |
| Other | Vietnamese-language screens (`3394`, `3445`, `3571`, `3577`-`3584`), fan art, game boxes | skip |

### Batch 20 (`batch-20`, photos 2251-2346)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Ninja Test chests** | stage 10 (boss stage) shows 3 chests: first free, then **160 gold** and **250 gold** (`2302`); 3 tries a day ("times left 0/3", "3/3") (`2302`, `2333`); score 4050 at stage 10, 1100 at stage 2 (`2302`, `2333`) | 3 tries ok; chests **30 / 80** gold (ours) |
| Ninja Test enemies | stage 2 "exame room" (Guarder DesertGai): 5 enemies with **~1950 DEF** each (1951-1956) (`2333`) | done 1 Nov (`exam.js`) |
| **Energy** | "Energy 7/500, next energy 00:02:06, full energy 24:38:06" = **1 energy per 3 min** (`2317`) | 180 s: **matches** |
| Grudge | Grudge 7/7, next/full 00:00:00 (`2317`) | |
| W.A. ranks 1-7 | same as batch 1 table (`2317`) | matches |
| Country war screen | each kill gives **10 W.A.**, EXP +36, silver +36 (`2315`); war screen: total points 120 = **29 kills** (≈ 4 points a kill?) , "Resurrection counts left 0", "Purchase resurrection", Autoplay button; war reward chests cost **1000 / 3000 / 3000 / 4000 / 5000** achievements (`2264`) | done 2 Nov (`war.js`); chests match warconfig |
| Reincarnation (god card, Kaguya) | 1 same card **OR 350 Reincarnation Pills** (`2310`) | |
| Evolve | cost **80** for a 5-star/god card (Hidan, Itachi) (`2251`, `2326`); "Reincarnation and growth will be retained" | |
| Secret (mystery) shop | refresh **20 gold** or Refresh Order; "Number of refresh today **100/105**, VIP6 +5"; auto refresh **2 h** (01:58:35); prices in ninja souls: Human Path 4000, Kakashi frag 350, Shima 170, Second Mizukage x5 850 / x1 170, Danzo 130 (`2331`) | refresh free, 99 a day, once a day |
| Akatsuki mall | items 20 / 45 / 20 contribution, 210 / 210 / 280 con, 2100 con + 900 gold, 225 con, 3000 con + 1800 gold; countdown to refresh ~**30 min** (27:41, 27:50) (`2303`, `2322`, `2330`) | done 2 Nov (Akatsuki mall) |
| Scratch card (Lottery) prizes | 3x3 board: 150, 500, 800, 150, 500, 5, 150, 50 gold (`2313`) | built 1 Nov (`scratch.js`) |
| Gold recruit gold prizes | "Gold*500", "Gold*1000", "Gold*210" from the 300-gold recruit (`2339`-`2346`) | not built yet: gold prizes need the recruit result screen researched |
| S-shinobi draw (cross-server) | headliner SusaMadara (D), 300 gold per draw, free draw timer 23:58:38 (= **once a day**), "After another 3 recruits, the next will grant you a Purple Card"; **20 points a draw**; rewards 1 SusaMadara, 2 Six Paths Obito, 3-5 Indra(A), 6-10 Kurama(A); minimum for 1st prize **480**; event 72 h (`2258`) | |
| Wheel ranking | first-prize line 850 points; rewards rank 1 / 2-10 / 11-50 / 51-100 gift packs; points reward 50 score / 1000 (`2329`) | |
| Eight Gates | LV15 point 6: **1383 souls + 20 745 silver** (=15x), ATK/DEF +415; totals +18 882 / +19 297 Chakra, +3/3/4% (`2335`) | |
| Sage growth | Sage 12 **7%**, Sage 10 **11%**, cost **550** silver at Sage 10 (= 50 x 11) (`2318`, `2319`); Sage 13 8% at 700 (`2253`) | silver matches; chance higher |

### Batch 21, 22 and 70 (`batch-21`, `batch-22`, `batch-70`, photos 2347-2382, 2801-2806)
| Topic | Original (picture) | Server now |
|---|---|---|
| Gold recruit gold prizes | "Gold*210" and **"Gold*2000"** as recruit results (`2347`, `2348`) | not built yet (see above) |
| Evolve | god card evolve cost **100** evolve pills (Boruto, Madara, Minato and Kushina) (`2366`-`2369`); "Reincarnation and growth will be retained" | |
| Sage growth | Sage 13 **6%** / 8% at 700 silver; growth bonus +130% -> +140% (`2352`, `2382`) | |
| Wheel ranking | min for 1st prize **1000**; points rewards 50 / 320 / 720 / 3500 (`2354`) | |
| Country war loss | "Loser! Your country has lost the war"; players' points 880, 340, 200 ...; war chests 1000 / 3000 / 3000 / 4000 / 5000 (`2356`) | |
| Training victory | "Please draw your victory reward": Sword of Flying Thunder God / **20 000 Silver** / Baiu; EXP +270 / +374 (`2377`, `2378`) | |
| Weapons at level 50 +1 | Sword of Flying Thunder God 916, Sword of Kusanagi 1033 (`2361`, `2362`); lv1: Bashosen 200, Sword of Totsuka 175 (`2363`); trinket Violet Gold Benihisago Chakra 200 (`2804`) | game table (equipmentinfo) |
| Ninjutsu lv1 | Big Ball Rasengan 99, Tsukuyomi 115, Demonic Statue 135 (`2801`-`2803`) | |
| Cards | Susa Kakashi 525-710 / 320-430 / 369-495, chains Six Paths Obito / Kaguya / Six Paths Naruto / Six Paths Sasuke +30% ATK, all +15% (`2371`); Otsutsuki Momoshiki (ATK) 520-720 / 320-425 / 360-490, chains Kinshiki / Six Path Naruto / Kaguya +25%, Boruto +23%, all +15% (`2372`); Otsutsuki Kinshiki (ATK) 515-710 / 310-420 / 355-480 (`2355`); Butterfly Choji 462-490 / 277-294 / 324-343 (`2349`); Six Paths Obito 294-372 / 490-620 / 343-434 (`2373`); Night Kai 475-610 / 285-360 / 333-428 (`2806`) | data tables |

### Batch 60 and 61 (`batch-60`, `batch-61`, photos 2751-2756)
| Topic | Original (picture) | Server now |
|---|---|---|
| World boss Obito | Lv **10**, HP **145 800 W** (=1.458 billion), Power +80%; top damage 615 million; "The reputation will be clean at 14:00 next day"; reputation shop 30 000 / 15 000 / 12 000 / 400 / 350 (`2751`, `2752`) | `boss.js` |
| Time limited GiftPack ("Preferential" tab) | "lowest **$19** recharge, claim **$60** price giftpack": 5-star Shinobi (God) chest + 5 keys + 4-star Ninjutsu + 3 EXP; event 70 h (`2755`) | built 2 Nov: Preferential (`limited.js`) |

### Batch 90-96 (`batch-90` to `batch-96`, photos 1195, 1746-1750, 1925-1927, 2357-2358 and 3585-4737; read 2 Nov)
| Topic | Original (picture) | Server now |
|---|---|---|
| **Christmas Buy price** | "buy prop": **1 Christmas Cap = 80 gold, 1 Christmas Tree = 100 gold**; limits "number **700**/700" caps and "number **600**/600" trees (per event); "time for buying: 12.23-12.29" (`batch-90/3627`) | 80 / 100 gold (consumeinfo) **matches**; limit 10 a day (ours) |
| **Christmas drop** | a **Christmas Tree** is one of the 3 face-down cards in the spar "Please draw your victory reward" (next to Adamantine Staff and a Gyuki Seal Fragment) (`3673`); caps come from training fights. No count per fight is shown | 60% chance of 1-2 per win (ours) |
| Christmas exchange (second year, begin 12.23-12.28, end 12.29; another run 12.23-12.26, end 12.27) | 10 Caps -> 5 red order tokens (50/50); 20 Trees -> 10 purple crystals (50/50); 30 Caps -> 5 Reincarnation Pills (50/50); 40 Caps + 35 Trees -> 5 purple orbs (40/40); 50 + 45 -> 3 Itachi fragments (20/20); 50 + 45 -> 1 Santa of the Six Paths fragment (1/1); **230 + 180 -> Seven-star Sword (1/1)**; **220 + 180 -> Sexy Technique (1/1)**; **650 + 600 -> Santa of the Six Paths card (1/1)** (`3623`, `3630`, `3658`, `3672`, `3676`) | `festival.js` uses the first-year list |
| **Anniversary event** (same screen as Christmas, "Anniversary", begin 12.16-12.20, end 12.21) | items: **Fireworks** ("go training, batter") and **Balloon** ("go spar"); shop price **Fireworks 100 gold, Balloon 140 gold** (`3817`); exchange: 20 Balloons -> 10 crystals (50), 30 Fireworks -> 5 Reinc Pills (40), 40 + 35 -> 5 purple orbs (30), 45 + 40 -> 5 Souls Dan (30), 35 + 30 -> 1 Anniversary Sasuke fragment (30), 230 + 180 -> Seven-star Sword (3), 200 + 170 -> armour (3), **550 + 500 -> Anniversary Sasuke card (1)** (`3720`, `3722`, `3732`, `3774`, `3809`); mail "Anniversary Reward: Anniversary Sasuke Fragment(D) x1, God x50, silver x50000" (`3695`, `3768`, `3782`) | not built |
| Anniversary Sasuke cards | Anniversary Sasuke (ATK) chains Sage of Six Path +30% ATK, Six Path Naruto +30%, Kaguya +25%, Rinnegan +25%, all +13%; the (God) version adds all +7% (`3811`, `3815`, `3822`-`3824`) | |
| **Daily task chests (all six)** | bar 250 points, chests at **30 / 80 / 120 / 160 / 210 / 250** (`4107`, `4211`, `3685`); tasks: Treasure Chest "Opened Gold Chest 3 times" **15**, Ramen 3x **10**, Money Tree 3x **15**, Get 1000 Arena Reputation 10, Upgrade Shinobi 3x 10, Reincarnation 1x **30**, Training 20x 10, Advance 5x 10, Plunder 2 seals 10 | 7 chests at 30/60/90/120/160/210/250: original has 6, with 80 instead of 60 and 90 |
| **Normal recruit pity** | the **1 in 10000** "Shinobi recruitment" window says **"Recruit 2 more will get one - Five Star Purple"**, with "Free recruitment this time" and 10x = 2800 gold (`batch-93/4435`). So the normal recruit DID have a pity counter; this photo only shows 2 left, so the full number is still unknown | 20 (ours) |
| Treasure chests (keys) | "Chances today to open the treasure chest **45/45**, VIP5 +5 times"; gold / silver / bronze key (`4380`) | vipinfo col 24 (VIP5 = 45) **matches** |
| Recharge streak ("charging") | "Top up 3 dollars and get the rewards"; day 1: 2 order tokens + 5 purple items + 2~5S Shinobi; day 2: 4 tokens + 2 tickets + 5 + 2~5S; day 3: 5 nostrum + 10 crystals + 5 + 2~5S; 7 days in a row: Minato (ATK) + 30 Reinc Pills + 8 tickets + 5 (`3942`) | compare `dailyevents.js` |
| Flower Worship rewards | Mei Terumi: Sasuke(G) + Amaterasu + 100 crystals; Konan: 5-star equip + 5-star ninjutsu + 20 Reinc Pills; Hinata: 5-star shinobi + 5 ramen + 50 tokens; another: Boruto(A) + Tensei + 80 (`3863`); Tsunade: Kushina(God) + 80 + 15; Sakura: Sakura(God) + Izanagi + Bashosen (`4709`); flowers given 24 / 95 (`3864`, `4543`) | built 2 Nov with the list written in the game itself (v28); these photos are two later runs with other lists, both cut off, and Boruto is not in v28 |
| Arena reputation shop (later) | first about **40 000**, second Seal of Ten Tails **80 000**, third Flying Thunder God Kunai **120 000**, four Naruto Uzumaki (Attack Card) **480 000**, each "Total Exchange 1 Times" (`3882`, `4364`, `4618`) | check arena exchange |
| Arena rules (player guide) | "3 hits and a cool down of **10 minutes**" (limit by VIP); rank reward collected **9:00-9:30**; cross-server **Friday 11:30**; super ninja draw: 1 free draw and another 24 h later (`3924`, `3926`) | |
| Spar preview | win: EXP 129, silver **2758**, **15 W.A.**, chance of equipment/ninjutsu chest; lose: EXP 43, silver **-271**, **5 W.A.**; "Insufficient spar value, unable to spar" (`4372`) | |
| World boss (later version) | "Battle begins **12:30** daily"; "The reputation will be clean at 12:30 next day"; "Akatsuki is invading" countdown about 27 min before (`3776`, `3807`, `4622`) | earlier photos: 14:00 |
| Pets | "Nov 11, pets officially online ... Obtain pets in secret shop" (`4286`); Pakkun "beast hit 1/3 chance cause 175 damage", fragments from the mystery shop (`4153`, `4248`) | `pet.js` |
| Daily "complete the designated lines" | Development Dan claim; "secret-shop-refresh-5-times" -> Refresh Order; "5 times of successful ..." -> Gold*30 (`4295`, `4639`) | |
| Mails | "New version players hit 5000, reward 1000 gold"; "Android V21.3 players hit 4600 reward 1120 gold" (`3695`, `4377`) | |
| VIP groups (publisher post) | transfer to World of Ninjas grouped by VIP 1-4 / 5-7 / 8-12 / 12-15 / 15+ (`4430`); no thresholds shown | |
| Eight Gates | point cost 647 souls + 9705 silver (= 15x) (`4270`) | same as before |

### Second full pass (all batches 01-96, 2 Nov): things missed the first time
Every photo (about 4 740) was looked at again on contact sheets, this time for all screens, not only events. Rows below are new; rows saying "matches" confirm the server.

| Topic | Original (picture) | Server now |
|---|---|---|
| Pets (beast) stats | Pakkun Lv1 (card level 2): ATK 1000 / DEF 740 / Chakra 760, team bonus +650 each, "beast hit 1/3 chance cause 180 damage"; Pakkun Lv3 (card level 50): 15 000 / 10 660 / 10 040, +2600 each, 420 damage; Gamakichi Lv1 185 damage (`0059`) | `pet.js` |
| Country war win screen | win gives **EXP +35, silver +35, 10 War Achievements** ("Combos 482") (`0074`) | |
| Arena daily rank reward (ranks 7-10) | rank 7: 19 000 silver + 3800 rep; 8: 18 000 + 3600; 9: 17 000 + 3400; 10: 16 000 + 3200 (`0339`) = the 26 000 - 1000 x rank rule holds to rank 10 | matches the 2 Nov change |
| Akatsuki donate equipment | donating 116 selected 4-star equipment cards (Puppet Hiruko lv1 110, Kurosawa sword 90) gives **Fund +2908, Contribution +2236** (about 25 fund and 19 contribution per 4-star card) (`0438`) | check `guild.js` donate |
| Tool shop prices | Ramen Ichiraku (Large) 200 energy **20 gold**, Hyourou-gan (Small) 50% duel points **8**, (Big) 100% **10**, Sage Stone I **5** (`0081`, `0447`) | matches |
| Limited group purchase ("Limited Gift" tab) | "All-server limited group purchase gifts": Super giftpack = Katsuyu (pet) + Grain + Nostrum, **original 20 000 gold, price 15 000**, 10 left, about 74 h (`0491`) | `groupbuy.js` compare |
| Christmas Naruto (G) growth | Lv3 Chakra +325, Lv6 Attack +325, Lv9 Defense +380, Lv12 Max Attack +1000 (as well as the rebirth list) (`0620`) | data tables |
| "Timed Gift" / "diligence gift" icons on the home screen (`0651`, `0654`) | not seen inside | |
| Arena reputation exchange (check) | photo rows "The eight" Naruto (Attack Card) 480 000 total 1; "The nine" 30 Sage Stone I 8000, 4 a day; "The ten" 15 Sage Stone III 8000, 2 a day; "The eleven" 5 Reincarnation Pills, 2 a day (`0708`) | `data/exchange_award.json` has exactly these rows: **matches** |
| Home screen icons (VIP4 player) | top row: EXP (double exp), Daily Task, 1st Recharge, Growth Fund, Event; left: Super Ninja, Cross; bottom bar: Ninjabook, News, evolve, Dun, Soul, Growth, Train, Reincarnate; buildings Plunder, akatsuki, War, Battles, Arena, Awards, Cross (`0703`) | layout reference |
| EXP card | gold "EXP" Akimichi Choji card (material), shown ATK/DEF/Chakra 100 000 each, "used for other shinobi to upgrade" (`0849`) | check feeding EXP |
| Reincarnation pills at Reinc 8 | Kaguya (God) reincarnation 8 -> 9 uses **1200** pills (`0876`); Reinc 9 1230 (`0780`) | matches `newlifeconfig` |
| Evolve cost | evolve of god cards: cost **100** and needs 2 copies of the card; 4-star/5-star cost 0 when filled (`0866`-`0871`) | |
| Settings screen | Audio: Music / Sound tick boxes; **Invitation Code** box with "Claim Award" button (`1027`) | check if invitation code exists |
| Millionaire ("Rich") prizes | "Congratulations in winning" after 10 spins: Indra card, Sage Stone III, Reincarnation Pills, Development Dan, grain, nostrum (`1172`); Super Ninja Pill (large), Sage Stone, Reincarnation Pill, Susa Sasuke card, Souls Dan (`1193`) = board prizes are items, pills and sometimes a 5-star card | compare `monopoly.js` prize list |
| Anniversary Hashirama (card from an earlier anniversary) | Anniversary Hashirama (G) chains Kaguya +35%, Sage Six Path +35%, Naruto +35%, Madara +35% ATK and DEF, all +20%, all +15%; normal version +35% x4 and all +20% (`1316`, `1318`) | |
| Top-up mails (Monthly Card) | "The 250 $ you just paid can't afford the Monthly Card, so it's been transferred into gold"; "You paid 1 $ and purchased 45 gold" (`1311`) | |
| Team "collection" bonus panel + Seal slot | "7 Six-Star Cards: ATK/DEF/Chakra +5800 and +12%"; "15 Nine-Level Cards: +2600 and +4% (still closed: 17, 19 Nine-Level Cards)"; the **seal slot** on the team screen opens with "1. reach level 260; 2. Junior Jonin (W.A. rank) and level above 250" (`1432`) | check seal slot unlock |
| Award Center | "rewards remain for **7 days**", "Claim All" button (`1502`) | check award center expiry |
| 5-star cards from recruits (one player's long run of "Rewards" screens) | Kakashi Hatake, Tobirama Senju, Jiraiya, Killer B, Sword of Totsuka (weapon), Sasuke Uchiha, Human Path, Yakushi Kabuto, Uchiha Shisui, Second Mizukage, Gaara, Minato Namikaze, Naruto Uzumaki, Onoki, Sasori of the Red Sand, Six Paths Obito, Kurama, Hanzo of the Salamander, Fukasaku, Uzumaki Nagato, Third Raikage, Kamui Kakashi, Violet Gold Benihisago (trinket), Ten Tails, Sage Mode Sakura, Hiruzen Sarutobi, Night Kai, Demonic Statue (ninjutsu) (`2254`-`2308`) = what the 1-in-10000 pool held | compare the recruit pool |
| Akatsuki rankings | top guilds level **9** with 10-14 members; level 8 with 11-13 members (`1761`); a level 3 guild has 6/9 members (`1769`), level 8 has 14/14 (`1786`) = member cap grows by level (9 at Lv3, 14 at Lv8, 15 at Lv9) | check `guild.js` member caps |
| Level-up (feeding) screen | "Cards awaiting level-up", Provide EXP / Requires silver, "All 1-2 cards" tick box, Material card button; materials are 1-2 star Lv1 cards (Ebisu, Moegi, Tobitake, Inutsuka, Hyuga, Uchiha, Iruka, Gerotor, Akimichi, Mitokado) (`1781`) | |
| Victory draw cards (more) | spar/training "Please draw your victory reward" prizes seen: **Development Dan x1, Reincarnation Pill x2, Double Exp Pill x1** ("X2 exp during training in 5 min") (`1905`-`1907`); ninjutsu cards, Nara Shikaku / Yugao cards (`1847`, `1866`) | compare victory draw pool |
| Spar log (plunder) | "Player iPeePee won you, but failed to steal Son Goku Seal Fragment 1 from your hands" / "stole Saiken Seal Fragment 6" (`1888`, `1889`) = plunder can fail | |
| Border war screen | "EST 12:00-15:00", HP 0/300, Water wandering / Water taunting "Defeated 0", "My status: Defeated at Water by ..." (`1911`) | `border.js` |
| Country war ranking titles ("National honour") | by past war achievements: 87 800 = **War Jonin**; 33 000 / 30 760 = **War Chunin**; 9200 / 8260 = **War Genin**; 5070 / 3380 / 2930 / 2750 / 1400 = **War Minor Shinobi** (`2026`); exploit pack "Equipment Pack III: chance of Five-Star, great chance of Four-Star, at least Three-Star" (`2027`) | matches `data/countrywarhonor.json` (Minor 3600, Genin 7200, Chunin 18 000, Jonin 36 000; also seen in `4700`) |
| Sage auto-growth | "Auto-Growth: grown to Sage Mo... 13, stopped" (auto-grow up to a chosen sage level) (`1960`) | |
| Level-up screen (player level) | Lv 280 -> 281: "Attack 3089 -> 3100, Defense 3089 -> 3100, Participants 14 -> 14; Energy up, Grudge up" (`2155`) = player stats +11 per level at 280 | check `playerlevel` table |
| Wheel ranking points rewards (later UI) | 40 score: 20 000 silver; 100: 5 ramen; 400: 100 crystals; 800: a card; rank 1 Sasuke, 2 Kurama, 3-5 a card, 6-10 a 1-in-10000 ticket; minimum 700 (`2087`) | `wheel.js` |
| Settings (later) | Audio Music / Sound effects, **Account Centre** id, Invitation Code + Claim reward (`2134`) | |
| Country officials screen | Kazekage + Left / Right Custodian + 4 Elders, each with a "Match" button and a salary bag (purple for Kage, red for custodians, green for elders); a 23:59:53 cooldown after a match; "War has not started, it will begin at Today **19:30**" (`2476`) | `country.js` compare |
| 10x S-shinobi draw result (event) | 10 cards: 3 purple 5-star (Orochimaru, Senju Tsunade, Jiraiya) and 7 blue 4-star (Neji, Mifune x2, Fourth Kazekage, Preta Path, Yugito Nii, Naraka Path) (`2469`); another 10x: 4 purple + 6 blue (`2470`) = a 10x event draw gave about 3-4 five-star cards | check event-draw odds |
| Cross-server battle final ranking | "Previous Final Ranking" (deadline Already Ended): ranks 21-24 with scores **57 640 / 56 411 / 56 289 / 56 ...**; tabs Battle / Merit / Betting / Description; "view unit" (`2522`) | `crosswar.js` scores scale |
| Akatsuki (bigger guild) | guild level **6**, fund 33 505, members **12/12** (`2551`) = Lv6 holds 12 | check guild member caps |
| Boundary monument ranking (border war) | intruder / defender ranking, Yesterday / History; contribution 3161 / 1612 / 1476 / 1420 / 1356 / 819 with award chests: rank 1 purple-gold, 2 silver, 3 gold, 4-6 wooden; "Merit chest (merit > 200 claimable)" (`2650`) | `border.js` |
| World boss reputation shop (cheap end) | items 12 000 / 400 / 350 / 200 / 200 / 50 reputation; the 200 one "Contains 3-5 star weapon cards" (`2610`) | `boss.js` shop |
| Cross-server battle sign-up | "Current event namelist", battle countdown, "buy ticket" button, "Your qualifications: You have entered already"; entrants listed with current position 36-38 and previous scores 0 / 109 (`2746`) | `crosswar.js` |
| Spar losses (high level) | "you lost 626 / 659 / 693 / 731 / 770 / 840 / 884 / 931 / 980 silver" to the same player in a row (each about 5% more) (`2724`, `2725`); 169 811 / 178 291 / 187 711 / 206 141 at level 260+ (`2765`) | |
| Country war "Active kills ranking" | "You have actively killed **217** enemies ... Achievement earned: **2170**" = **10 achievement per kill** confirmed; war reward chests 1000 / 3000 / 3000 / 4000 / 5000 achievements (`2830`) | check `war.js` |
| Scratch card prize per character | each face has a fixed prize: Shikamaru 50, Neji 150, Hinata 20, Naruto 800, Sakura 5, Gaara 500 gold (match 3 of the same face) (`2930`) | `scratch.js` prizes match the amounts |
| Akatsuki max | a guild at level **9**, fund 9999, **22** members (`2921`) = the member cap goes above 15 (maybe with Hall/Group upgrades) | check guild caps |
| Akatsuki join requests | "Approval" list with level and fighting power, Accept / Refuse (`2968`) | |
| Wheel of Fortune 10-spin result | 10 spins gave: 6x "Reincarnation Pill 2x2", 3x Double Exp Pill, 1x Development Dan (`3255`) = common wheel prizes are small item packs | compare `wheel.js` prize weights |
| Super Ninja event pop-up | "Join super ninja - Win unbeatable ninjas", dates **Jan 25th - 27th 23:59 (GMT+8)** = a 3-day event (`3338`) | event length |
| Reputation shop prices (one screen) | Fourth Sage card **28 000**, Flying Thunder God Kunai **16 000**, Kurama **10 000** reputation (`3344`) | compare boss / arena shop |
| Soul Disenchant (VIP1, level 208) | a level-1 purple 5-star card gives **2000** souls ("Refine Shinobi to get Ninja Soul 2000"); 5 card slots, Add shinobi / Soul / Secret shop buttons; the result pop-up shows 2000 (`3416`, `3417`). This player had only 1143 silver and 5 gold. | `game.soulOf` gives every player 30 000 starter souls (not seen in any photo) |
| Plunder target list | "Click Plunder to steal seal fragments on other players"; each target shows level, attack range and **Plunder success rate: Very low / General / Higher** (depends on the target's power vs yours: a level-216 target showed "Higher", level-102/103 "Very low"); Refresh button (`3617`) | check `seals.js` success rate |
| Reincarnation 3 (Minato, 5-star) | basic value **+50%**, restrain 20% -> 30%, **320** pills or 1 same card (`3622`) | matches `newlifeconfig` |
| Wheel / event 10x result | Super Ninja Pill (large) x3, Sage Stone, Reincarnation Pill, Susa Sasuke, Souls Dan (`1195`) | |
| Border war daily award (level 261) | taunting reward 2 a day, wandering reward 2, taunting clearance 4, wandering clearance 4; "wandered 2 times" = **EXP 6600 + 1566 merit**; "wandering cleared 4 times" = EXP 6600 + 1564 merit; breaking a country = **Gold 50 + Super Ninja Pill + Reincarnation Pill** (`3734`) | `border.js` |
| Generic fragments (Tool tab) | Four-Star Shinobi Blue / Five-Star Shinobi Purple / Four-Star Equipment Blue / Five-Star Equipment Purple Card Fragment: **every 50 fragments -> one random card** of that kind; "Currently not for sale" (`3738`) | check generic fragments |
| Tool tab (VIP8) | Recruitment Order "recruit shinobis of 2-5 stars" and Refresh Order "refresh the mystery shop": both **not for sale**; Immigration Card **50 gold**; War Achievements Increase Pill (double W.A.) listed (`3788`) | check the server does not sell orders |
| Player guide (more) | **World boss: "You have 10 hits. After you use them, wait about 1 min 20 s and you get 10 more hits, until the boss is killed or time runs out"**; collect reward from the hero list; boss starts 11:30 pm US-Eastern (= 12:30 GMT+8); war starts 5:30 am Eastern (= 18:30 GMT+8); border: next day collect monument reward if you did at least one full hit or defence (`3925`) | check `boss.js` hit limit |
| Player guide (growth / restrain) | sage growth does not drop at 3, 6, 9, 12; stone advice "1-3 green x3, 3-6 green green purple, 6-12 green purple purple"; **element restrain: green beats purple, purple beats yellow, yellow beats blue, blue beats red, red beats green**; "Before making a card God, reincarnate it first" (`3923`, `3927`) | server uses the game's own `ninjafiveprop` table (water > fire > wind > thunder > earth), same 5-step circle |
| Daily alarms (a player) | War 4:30 am, Arena 8:20 am, Reset 10:00 am (player's own time zone) (`3876`) | |
| **Save time (second photo)** | "Chapter: 16 chapter, 8 round, Exp **4800**, Silver **5800**", Ramen 312, chances 11, Gain 10 Gold, VIP1 +2/day (`4035`). The 12-fight rule fits a chapter-16 stage costing 20 energy (exp 480 / silver 580, e.g. roundinfo chapter 16 rows 45, 51, 56, 61, 63 -> 10 fights = 4800 / 5800). Roundinfo row "16-8" (22 energy) would give 4800 / **5500**. So the photo's "round 8" is not roundinfo column [2] = 8. It is probably a later round (part 8 of the chapter) | `handlers.rl_r_savetime` looks up `r[2] === round`: check it picks the same stage as the screen shows |
| Arena list (VIP0) | rank 32 reward "Claimable 15 200 silver + 3040 reputation" (rank 30-33 all the same); "Countdown to battle 00:05:14" + **Eliminate CD** button; "Number of challenges today ... VIP1 +1 times" (`3989`) | 15 200 / 3040 at ranks 23-33 (flat band) |
| Great gift for total recharge (third version) | **$280**: Hashirama (God) + Nativity of Trees + 200 purple crystals + 120 Reincarnation Pills; **$400**: Susa Shisui (ATK) + Susanoo + Izanagi + 100 Development Dan; **$650**: Night Kai (God) + Six Paths Rinnegan + 160 Reincarnation Pills + 100 Souls Dan (`4096`) | `totalgift.js` uses one version |
| "Multiple" top-up wheel rule | 6 slots 1.2 / 1.8 / 2 / 1.5 / 2.2 / 3 "M", **Start requires 300 gold**; "Multiple for this time: 2.2"; note: the multiple **does not stack with the 3x first-recharge bonus**, a win "only grants 1 recharge rebate" (`4120`) | not built (`rl_r_multiple_pay`, marked not possible) |
| Ninja Test checkpoint 10 | "Guarder Valley Sarutobi, death forest", chests: first opened, then **160** and **250** gold; Exchange score 3800; times left 2/3 (`4095`) | matches (160 / 250) |
| Pet advance Lv1 | Pakkun Lv1 advance: attributes +0 -> **+650** each, consumes **50 nostrum**, **success 100%** (`4249`) | `petupgradeequ` row 1 (50 nostrum, 100%, 650): **matches** |
| Ninja Treasure board (prize amounts) | the 9 face-down prizes show amounts 2 / 1 / 1 / 5000 / 100 / 10 / 3 / 50 / 1; event timer 1:7:59:50; Refresh 100, Explore **35**, Refresh countdown 1:56:41 (`4178`); other boards 5000 / 20 / 10 / 600 explore (`4231`, `4234`) | `sudoku.js` |
| Real top-up receipts | Google Play receipts "GUMP TECH CO., LIMITED" $0.18 / $30.00 / $15.00 / $0.18 (`4204`) = the $0.18 pack (8 gold) really existed | top-up table |
| Great gift for total recharge (fourth version) | lower tier: Sarada (DEF) + Demonic Statue + 200 crystals + 50 Development Dan; **$400**: Otsutsuki (ATK) + Chibaku Tensei + 160 Reincarnation Pills + 100 Development Dan; **$1300**: Kaguya (God) + Rinnegan + Indra + 100 Souls Dan (`4334`) | `totalgift.js` uses one version |
| Ninja Treasure "Top Level Rewards" | the possible top prizes are 16 cards: Six Paths Obito, Sasuke, Hinata, Fourth Sage, Obito, Jiraiya, Killer B, Tsunade (orange = god), Madara, Choji, Indra, Hashirama, Shisui, Itachi, Sakura, Bashosen; event timer 1:13:58:54 (`4335`) | `sudoku.js` prize pool |
| **Succession (inherit) price** | Six Paths Obito (5-star, level 50, growth **9**, **1** reincarnation): "Use up **2450** gold" to pass level, reincarnation and growth on to another card of the same kind (`4440`). | changed 2 Nov: price = 50 x (level - 1) (ours, fits this photo exactly) + trained attack + trained defense (the client's own sum) |
| Tool tab prices (VIP9, later) | Sage Stone III **10**, Reincarnation Pill **120**, Super Ninja Pill not for sale, Recruitment Order listed; Hyourou-gan Small **8** / Big **10**, Sage Stone I **5** (`4449`, `4450`); Element Change Pill not for sale, Tael Large 10 000 silver (`4451`) | match the 2 Nov shop |
| National treasure (water country) | "Treasure Amount 3006"; "You can get some **3000 silver** for each plunder"; "You currently have 5 national treasure(s)! (**Cleared after 24 hours**)"; Tries left 0; Defending / Contribute / Plunder; conditions per element (wind 8, thunder 20, fire 69, earth 9 / 222 each) (`4520`) | `tear.js` 3000 silver: **matches** |
| Hyourou-gan (spar points) daily buy limit | "Left today **0/6**", **VIP2 +3 times/day**; Small 8 gold (+50% duel points), Big 10 gold (+100%) (`4550`) | check the daily limit in the plunder / spar buy |
| PayPal top-up (late, double event) | $1 = **70** gold, $5 = 370, $10 = 745, $15 = 1120, $30 = 2395, $100 = 8245, $200 = 17 995, $500 = 43 495, each "x 2" (double-gold event) (`4666`) | a third price table, later than $1 = 45 |

## Holiday events
(Checked in all batches 01-96. **No** Valentine, Goddess Tsunade, Halloween or "God recruit" slot screens. Batch 90 adds the Christmas **Buy price: cap 80 gold, tree 100 gold**, limits 700 / 600, a second-year exchange list and the Anniversary event: see "Batch 90-96" above.)

### Santa Killer B and other holiday finds (batches 07-84)
- **Killer B (Santa Claus)** is a real 5-star card. Its card screen shows chains Third Raikage +25% DEF and ATK, equip Tailed Beast Mode +25%, Naruto Uzumaki +25%,
  Fourth Raikage +25%, trinket Kohaku Johei +25%, all shinobi ATK/DEF +3% (`batch-83/3133`, `batch-07/1566`). In the shop Tool tab it is sold as
  **"Killer B (Santa Claus) Ninja Soul": every 50 souls synthesise one card**, shown as "Currently not for sale" outside the event (`batch-83/3261`). On the same
  screen, Sage Naruto Ninja Soul needs 40. So the Santa card came from soul items sold or dropped during the event, not from a recruit screen.
- **Santa of the Six Paths (God)** card screen: chains Kaguya +30% ATK and DEF, Six Path Madara / Naruto / Sasuke +30%, all shinobi +15% ATK and DEF, all +10%
  (`batch-84/3550`, `3572`). It is sold for **3500 souls** in the Secret shop (`batch-07`).
- **Kaguya for New Year** is the headliner of an S-shinobi draw, with ranking rewards 1 Kaguya for New Year, 2-2 Six Paths Sasuke, 3-5 Hashirama, 6-10 Tobirama (A).
  The screen says "After another 6 recruits, the next will grant you a Purple Card" (`batch-84/3564`).
- **Christmas mails:** system mails "Christmas gift : Merry Christmas" and "Last festivity 1600 gold" (`batch-82/2913`); a player title "S73-Christmas" (`batch-81/2761`).
- **Chinese New Year look:** the Wheel of Fortune has a red New Year skin with a 100-Gold-draw super pool (`batch-82/2975`, `batch-83/3055`), and the "Rich" board
  says "wishing everyone prosperity and luck in the year" (`2828`, `2871`).

### Normal recruit (not the event draw)
- Free timers seen: "Free after 4 days 9 hours" / "2 days 9 hours" (`batch-81/2780`), "Free after 00:01" (`batch-84/3360`).
- **Pity counter found (batch 93):** the 1 in 10000 "Shinobi recruitment" window shows "Recruit **2** more will get one - Five Star Purple"
  (`batch-93/4435`). Only that one photo shows it, with 2 left, so the full pity number is still unknown (the S-shinobi event draw is every 10th draw).

### Christmas festival ("Merry Christmas" tab in the Event menu, next to Flower Worship / Treasure / Growth Fund)
- **How you get the items:** Christmas Cap = "go training, batter" (training fights), Christmas Tree = "go spar" (spar fights). A **Buy** button on the
  same screen buys more (price not visible on any photo yet). Players held 344 caps / 341 trees, 512 / 402, 710 / 246 near the end
  (`batch-03/0848`, `0874`, `0858`). Per-fight drop count is not shown on any photo yet.
- **Dates:** one year "begin 12.28 - 1.4, end 1.4" (`0848`); another "begin 12.29 - 1.3, end 1.3" (`0858`, `0874`, `0860`); "Event has ended" after.
- **Exchange list** (limit is per event, shown as "exchange N/N"; not per day as far as the screens show):

| Pay | Get | Limit | Photo |
|---|---|---|---|
| 30 Caps | 15 Sage Stone III | 30 | `0874`, `0858` |
| 25 Trees | 10 Reincarnation Pills | 30 | `0874`, `0858` |
| 40 Caps + 30 Trees | 10 purple orbs (Development Dan) | 30 | `0874`, `0858` |
| 50 Caps + 40 Trees | 5 blue flames (Souls Dan) | 30 | `0874` |
| 40 Caps + 40 Trees | 5 fragments of a 5-star card (Naruto, "Fragments" badge); a second 40+40 row above gives 5 of another card | 15 each | `0848`, `0887`, `0878`, `0860` |
| 100 Caps + 100 Trees | 1 "Sexy Technique" ninjutsu card | 1 | `0848`, `0862` |
| 350 Caps + 350 Trees | 1 Kushina for New Year (shinobi card) | 1 | `0848` |
| 450 Caps + 400 Trees | 1 Christmas Naruto (shinobi card) | 1 | `0848` |

### Holiday cards and holiday recruit ("S-shinobi draw" event, 300 gold per Gold draw, free draw on a timer)
- **Christmas (A) = Christmas Naruto**: S-shinobi draw headline card; ranking rewards 1: Christmas (A), 2: Dice (A), 3-5: Asura (D), 6-10: Sakura (A);
  first prize needs at least 240 points; text "Recruit 3 more will get one" (5-star purple card) (`batch-03/0778`, `batch-04/0899`).
  Card: stats 650-900 / 400-550 / 450-600, chains: Kaguya +35% ATK and DEF, Six Paths +30%, Sasuke +30%, Kaguya +35%, all +22%, all +15% (`0904`, `0909`);
  text lists rebirth 1-8 attack +250 ... +9920 (`0620`).
- **Kaguya for New Year**: "New year new card, the people who own Kaguya for new year will receive power and happiness"; stats 500-800 / 350-500 / 400-580
  (`0791`, `0966`, `1033`); Sage 15 version shown (`0801`, `0818`).
- **Kushina for New Year**: "Happy New Year! Kushina brought luck to Konoha"; stats 600-850 / 350-550 / 410-600; chains Kaguya +30%, Naruto +30%,
  Namikaze Minato +30%, Madara +30%, all +18% (`0847`, `0852`, `0873`, `0910`). Also the 350+350 Christmas exchange prize.
- **Santa of the Six Paths**: stats 340-465 / 340-450 / 340-450 (Rewards screen), chains Kaguya +30% ATK, Six Path Madara +30%, Six Path Naruto +30%,
  Six Path Sasuke +30%, all +15% ATK and DEF (`0783`, `0784`, `0933`, `1144`); Sage 15 shown (`0721`).
- **Mother Kaguya (God)** and **Goddess Sakura** appear as event cards (`0760`, `0776`, `0915`, `1017`), Goddess Tsunade only as fragments (`0776`, `1015`).
- Other S-shinobi draw headliners seen: Kaguya (D) with rewards Kaguya (D) / Momoshiki / Gaara (A) / Tobirama (A) (`0739`, `1023`); Naruto (A) (`0963`);
  Susa Madara (D) with Susa Madara / Susa Shisui / Susa Sasuke / Nagato(A) (`1124`); Sasuke (`1095`); Hokage Naruto (A) (`1180`).
- **Event draw pity:** the S-shinobi draw shows "Recruit N more will get one" (a five-star purple card) with N = 0, 2, 3, 4, 7 seen (`0778`, `0899`,
  `1095`, `0963`, `1124`), so that event pity is **10 draws or fewer** (likely 10).

## Update 2 Nov 2026: all batches read
All 19 folders (about 3 580 photos, batch-01 to batch-84) are now read. Changed on the server because of these photos (pushed to GitHub):
1. **Save time** = the original screen (11-6 gives 3200 EXP / 3800 silver; VIP1 and Lv80; 10 gold after the free chances).
2. **Level-up** refills grudge as well as energy.
3. **Ninja Test** guards follow the photos (stage values 1160 / 1950 / 2980 / 10 065, lower for low levels).
4. **Growth Fund** built (500 gold, VIP3, 2500 back).
5. **Arena daily reward** 25 000 + 5000 at rank 1 down to 2000 + 400.
6. **Ninja Treasure** refresh 100 gold, every 2 h, explore 35 / 70 / 300 / 320 / 1000.
7. **Secret shop** Refresh works (Refresh Order or 20 gold, 75 + 5 x VIP a day, new goods every 2 h).
8. **Shop** Reincarnation Pill and Development Dan 120 gold.
9. **Change country** (Immigration Card + 300 gold).

Checked and already right: stage rewards, reincarnation pill costs, ninjutsu values, W.A. ranks, team slot unlocks, set bonuses, energy timer, VIP thresholds 1/3/5.

Still open (seen in photos, not built): daily task 250-point chests, Eight Gates with levels (15 x souls silver), shinobi training with pills, Treasure (key) chests, limited group purchase, cross-server battle, scratch card, succession (inherit) screen, sage growth chances per level, recruit free timers (owner keeps 24 h / 8 h).

## Summary 1 Nov (batches 1-6, 20, 60, 61 only; see the newer summary at the end)
Read so far: batch-01 to batch-06, batch-20, batch-60, batch-61 (about 1 660 photos). Later batches (07+, 21+, 40+) were not there yet.

**Server already right:** VIP thresholds VIP1 $1, VIP3 $30, VIP5 $100 (exp = $ x 10); energy 1 point per 3 min; stage energy/EXP/silver
(`roundinfo`); sage growth silver 50 x (level + 1); W.A. ranks; Tael and most shop prices; 10-pull 2800 gold; Ninja Test 3 tries a day.

**Biggest differences (server guess -> original):**
1. **Daily task chests:** 100 points with 20/40/60/80/100 -> **250 points**, chests at (..)/120/160/210/250; the 250 chest = 30 000 silver + 100 gold + 10 Reincarnation Pills + Killer B fragment.
2. **Ninja Test boss chests:** 30 / 80 gold -> first free, then **160 / 250 gold**.
3. **Secret (mystery) shop:** free refresh, 99 a day, daily -> **20 gold** a refresh, **75 + 5 x VIP** a day, auto refresh **every 2 h**.
4. **Arena daily rank reward:** 6 000 - 100 x rank silver -> **26 000 - 1 000 x rank silver + 5 200 - 200 x rank reputation**.
5. **Sage growth chances** are much lower at high levels: Sage 0 95%, Sage 10 11%, Sage 12 7-10%, Sage 13 1-2%, Sage 15 8% (server: at least 30%).
6. **Eight Gates** have levels and cost souls + **15 x souls in silver** per point (server: 8 gates, small flat cost).
7. **Shinobi training (potential):** free -> **1 Super Ninja Pill + 4000 silver per try, 70%**; 5 tries = 10 pills, or 5 pills + 40 gold.
8. **Reincarnation:** at least **9** levels; pills 80/160/320/500/.../1200/1230 (5-star), 100 at level 1 for higher cards, 350 seen on a god card; or 1 same card.
9. **Top-up first buy is x3** (0.99 -> 135, 4.99 -> 675, 9.99 -> 1350); later packs give bonus gold (4.99 +15, 9.99 +40, 19.99 = 950 +100).
10. **Ninja Treasure (3x3):** refresh 100 gold, board every 2 h, explore cost rises 35 -> 70 -> 200 -> 300 -> 1000 (server: 20 gold, 4 h, 10 + 10 x taken).
11. **Shop prices:** Reincarnation Pill **120** gold (table 180), Development Dan **120** (table 200).
12. **Free recruits** may be longer than 24 h / 8 h (300-gold free after "2 days 16 h" was seen).
13. **God breakthrough:** 60 000 silver at +1; ninjutsu trigger +1% and restrain +2% (server has them swapped).

**Still not found:** normal recruit pity number (event draw pity is <= 10, "Recruit 3 more" etc.), VIP 6-18 thresholds, VIP benefit list, Christmas cap/tree drop per fight and Buy price, Valentine / Santa Killer B / Goddess Tsunade recruit screens.

## Summary 2 Nov (all batches): what still differs most from the server
All folders batch-01 to batch-84 are read (about 3 580 photos). The "Update 2 Nov" list above says what was already changed on the server.
Still different, or still to build, ordered by how much a player notices:
1. **Daily task chests:** 250 points, chests at 120 / 160 / 210 / 250 (the 250 chest = 30 000 silver + 100 gold + 10 Reincarnation Pills + Killer B fragment). The server uses 100 points.
2. **Sage growth chance per level:** Sage 0 95%, Sage 10 11%, Sage 12 6-10%, Sage 13 1-8%, Sage 14 4-7%, Sage 15 8%. The server uses at least 30%.
3. **Eight Inner Gates** have levels: each point costs souls plus 15 x souls in silver, with +7% to +81% totals at high levels.
4. **Shinobi training** costs 1 Super Ninja Pill + 4000 silver per try at 70%. "Foster 5" = 10 pills, or 5 pills + 40 gold.
5. **First top-up is x3** ($0.99 = 135 gold). The later Google Play table is $19.99 = 2850, $49.99 = 7200, $99.99 = 14 400 (`batch-84/3478`), which differs from the earlier $0.99 = 45 / $19.99 = 950 table. Two price eras existed.
6. **Ninja Test boss chests:** first free, then 160 and 250 gold ("spend gold 250 to open?" `batch-82/2954`). The server uses 30 / 80.
7. **W.A. ranks 8-14** are also confirmed by `batch-84/3382`: 30 000 / 45 000 / 60 000 / 90 000 / 120 000 / 160 000 W.A. = +550 ... +1100, the same as `data/playemedal.json`.
8. **Not built:** Treasure (key) chests, limited group purchase, cross-server battle, scratch card (prizes 5-800 gold), ~~Time limited GiftPack, "Great gift for total recharge"~~ (built 2 Nov).

**Never shown on any photo (batches 01-84; see the batch 90-96 update below for the Buy price and the recruit pity line):** normal recruit pity number, VIP 6-18 thresholds, VIP benefit list, Christmas cap/tree drop per fight and Buy price, Valentine and Goddess Tsunade events.

**Built since (2 Nov 2026, later):** Treasure (key) chests, limited group purchase, scratch card, Growth Fund, Great gift for total recharge, Time limited GiftPack, Ninja Test boss chests 160 / 250 gold, Eight Gates levels, daily task 250-point chests, shinobi training with pills.

## Update 2 Nov (batches 90-96, about 1 160 more photos)
Most useful new numbers: Christmas Buy 80 / 100 gold with limits 700 caps / 600 trees per event (server: 10 a day); daily task chests are
exactly 30 / 80 / 120 / 160 / 210 / 250 (server has an extra chest and 60 / 90); the normal 1-in-10000 recruit has a pity counter ("Recruit 2 more",
full number still unknown); Anniversary event (fireworks 100 gold / balloons 140 gold, Anniversary Sasuke); a second Christmas exchange list;
recharge-streak and Flower Worship reward lists; world boss later at 12:30. Still never shown: VIP 6-18 thresholds, VIP benefit list, Valentine, Goddess Tsunade.

## Update 2 Nov (second full pass over all photos)
Most useful new finds: **succession (inherit) cost 2450 gold** for a 5-star level-50 card with growth 9 and 1 rebirth (server: about 200);
**world boss: 10 hits, then about 1 min 20 s wait for 10 more** (player guide); Hyourou-gan buys **6 a day, +3 at VIP2**; Save time on a
second stage (16-8: 4800 / 5800) suggests the server may pick the wrong roundinfo row for "round N"; two more "Great gift for total
recharge" versions ($280/400/650 and $400/1300); plunder success rate depends on the target's power; Ninja Treasure top prize list.
Confirmed right: arena reputation exchange, war honour titles, pet advance (50 nostrum, 100%), national treasure 3000 silver,
reincarnation 3 (320 pills, +50%), Ninja Test 160 / 250 chests, element circle.
