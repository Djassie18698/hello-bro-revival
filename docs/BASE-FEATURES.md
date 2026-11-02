# Base buildings: what each one needs (original rules)

Everything here follows the original game: unlock levels, help texts and numbers come from the game's own
files (Lua screens, `localizable.lua`, and the data tables). Where the original server's numbers are lost, the
row says **(ours)**: that value is our best guess and can be changed.

## Unlock levels (unchanged from the original, `ui_myBaseLayer.lua`)

| Building | Opens at player level |
|---|---|
| Advance (gear) | 0 (always) |
| Breakthrough | 0 (always, but needs a god card) |
| Ninja Test | 45 |
| Pets ("telepathize beasts") | 150 |

## Ninja Test (`exam.js`, endpoint `rl_x_exam`)

Original help text: 15 rounds, cleared one by one; only 4 or 5-star ninjas; ninjas who fall can't come back.

| Needs | Where it comes from |
|---|---|
| 1 to 5 ninjas with 4 or 5 stars | your own cards |
| Tries | 3 a day **(ours)**; more cost 20 gold each **(ours)** |
| Chest on a cleared stage | free; every 5th stage has 3 chests, 2nd and 3rd cost 30 / 80 gold **(ours)** |
| Score (exchange points) | 10 x stage, +30 on stages 5/10/15 **(ours)** |
| Exchange shop prices | **(ours)**: silver, sage stones, pills, recruitment orders, grain, nostrum, 5-star gear, fragments of your own god card |

Resets every day: stage back to 1, tries back to 3, fallen ninjas back. Score is kept.

## Breakthrough (`tupo.js`, endpoint `rl_x_breakthrough`)

Original help text: only god cards; each level raises element restrain and ninjutsu trigger chance; the stats it
raises depend on the card's element (fire ATK + chakra, water chakra, wind DEF + chakra, earth DEF, thunder ATK).

| Needs | Where it comes from |
|---|---|
| A god card (6-star) | recruiting, events, or merging 50 of its fragments in the Backpack |
| That card's own fragments | mystery shop, Ninja Test exchange shop, event drops |
| Fragments per level | 5, 10, 15 ... (5 + 5 x level) **(ours)** |
| Silver per level | 50 000 x (level + 1) **(ours)** |
| Max level | 10 **(ours)** |
| Gain per level | +4% on the element's stats, +2% ninjutsu trigger, +1% restrain **(ours)** |

## Pets (`pet.js`, endpoint `rl_x_pet`)

Original help text: pets come from the mystery shop; the master pet (centre) casts its skill in battle and adds
stats, helpers only add stats; all pet stats are spread evenly over your ninjas; normal training gets more
expensive with each use and resets at midnight.

| Needs | Where it comes from |
|---|---|
| Player level 150 | to open the building |
| A pet | collect 30 of its fragments (mystery shop) and press Synthesis in Backpack > Fragments |
| Helper slots | open at player level 1 / 80 / 100 / 120 / 140 / 160 / 180 / 200 |
| Level up | grain (item 36): 20 to 70 per level (`petupgrade` table), max level 50 |
| Rank up | nostrum (item 37): 50 to 240 per rank, success 100% down to 10% (`petupgradeequ`), max rank 10 |
| Stars (training) | normal: 30 gold, +30 per use up to 150, 100 points; special: 100 gold, 150 points (`petinfo`); points per star from `petupgradestar`, max 10 stars |
| Stats | base + per-level growth from `petinfo`, rank bonus from `petupgradeequ`, star % from `petupgradestar` |

Grain and nostrum are sold in the mystery shop (5 or 10 at a time).

## Shared pieces these need

| Piece | Status |
|---|---|
| Mystery shop | sells the original mix again: ninjas, ninja fragments, pet fragments, grain, nostrum, sage stones, reincarnation pills (6 a day, weighted like the original table, each once a day) |
| Fragment merge (Backpack > Fragments > Synthesis, `rl_w_comm` Cmd 10) | works: 30 fragments make a ninja or pet, 50 make a god card |
| Fragments saved on the server | yes, shown in the Backpack after login |
| Item counts (grain/nostrum) in pet screens | refresh after opening the Shop once |

## Not original / still to check

- Every **(ours)** value above.
- Pet master skill in fights: the master pet is sent with each fight, but the skill's damage is only shown by the client.
- The 3-chest boss stages of the Ninja Test (5, 10, 15) have not been played in game yet.

- **Ninja Treasure (2 Nov 2026):** refresh 100 gold, board every 2 h, explore 35 / 70 / 300 / 320 / 1000 (original), 1000 after the 5th **(ours)**.
- **Arena daily reward (2 Nov 2026):** 26 000 - 1000 x rank silver for ranks 1-10 (original), then -60 a rank **(ours)**, at least 2000 (original); reputation = silver / 5 (original).
- **Treasure chests (2 Nov 2026):** prize lists original; weights, gold price without a key (50 / 20 / 5), 25 + 5 x VIP gold-chest opens a day and 8% key drops in story fights **(ours)**.
- **Eight Gates (2 Nov 2026):** 8 points a level, cost 80 x level souls + 15 x souls silver (original); bonus curve fitted to the photo totals **(ours)**, max level 150.
- **Daily task chests (2 Nov 2026):** 250 points, chests 30 / 60 / 90 **(ours)**, 120 / 160 / 210 / 250 (original); 250 chest original; other contents **(ours)**.
- **Shinobi training (2 Nov 2026):** 2 Super Ninja Pills or 1 pill + 10 gold (original); 10 times 20 pills or 10 + 80 gold **(ours)**.
- **Growth Fund (2 Nov 2026):** 500 gold, VIP3, 2500 back at Lv50 150 / 70 150 / 90 200 (original); Lv110 200, 130 250, 150 250, 170 300, 190 300, 210 350, 230 350 **(ours)**.
- **Save time (2 Nov 2026):** one Big Ramen = ceil(200 / stage energy) fights of the furthest story stage, rounded down to hundreds (fits the original photo exactly); VIP1 and level 80 (original); 2 chances a day per VIP level **(ours)**, then 10 gold (original).
- **Login streak (2 Nov 2026, Sign-in tile):** ORIGINAL day 1-8 rewards from the client's keeplogin_info.lua. (ours): missing a day starts again at day 1.
- **Month card (2 Nov 2026, switch `monthcard`, off by default):** ORIGINAL $4.99 = 60 gold a day, $9.99 = 120 a day, for 30 days. (ours): a free top-up of exactly that price activates it.
- **God of Wealth (2 Nov 2026, switch `caishen`):** ORIGINAL table wealthactivity: 8 steps, invest 25 / 150 / ... / 7500 gold and get 30-40 / 175-185 / ... / 8000-8500 back; level 10, 7 days. (ours): uniform return inside each range, one round per event run.
- **Flower Worship (2 Nov 2026, switch `flower`, off by default):** ORIGINAL 1 rose per $ topped up, the 5 goddess rewards (game text) and the prices Mei 40 / Hinata 24 / Konan 95 roses (photos). (ours): Tsunade and Sakura 95 roses, a goddess can be won again, 7 days per run.
- **Succession price (2 Nov 2026):** ORIGINAL the price is a base plus the card's trained attack and defense (the client adds them). (ours): base = 50 gold x (level - 1), which fits the one photo (level 50 = 2450).
- **Ramen / Hyourou-gan daily uses (2 Nov 2026):** ORIGINAL vipinfo: ramen 20 a day + 2 per VIP level, Hyourou-gan 30 a day + 3 per VIP level; Hyourou-gan refills 50 % / 100 % of the maximum grudge.
- **VIP limits (2 Nov 2026):** ORIGINAL the game reads the VIP table at row VIP + 1 (VIP0 = first row): gold chests 25, arena 25 attacks, mystery shop 80 refreshes, high-level soul training 3 a day at VIP0, each a bit more per VIP level.
- **Second team line-up (2 Nov 2026):** ORIGINAL: opens at level 100, can use every card (also Team 1's), Activate chooses the used team (the screen's own text).
- **Battle reports (2 Nov 2026):** ORIGINAL texts from the game. (ours): a defender loses no silver or fragments when sparred / plundered (as before), the last 30 reports are kept.
- **Seal packs (2 Nov 2026):** (ours) a "seal fragment" pack gives one random fragment of any tailed-beast seal; a "complete seal" pack one of the nine tailed-beast seals with equal chances (the Ten-Tails Seal only from its own fixed drops).
- **Gear / ninjutsu sets (2 Nov 2026):** ORIGINAL table skill_suit_info, the bonuses the game's own set panel shows for 2 / 3 / 4 pieces. (ours): ninjutsu sets only add their skill chance (as an expected value), because fights are worked out from stats.
- **Battles (2 Nov 2026):** ORIGINAL 25 chapters x 7 rounds (the client's rushtower/towerfloor), round 7 the boss, the next chapter opens after it. The boss drop is one of the four the game shows; equal chances (ours).
- **W.A. titles (2 Nov 2026):** ORIGINAL table playemedal (Junior Genin 500 W.A. +25 ... Supreme Gaiden 3 000 000 +2550 to attack, defense and chakra). (ours): the title follows all W.A. ever earned, so spending W.A. does not lower it.
- **Plunder (2 Nov 2026):** ORIGINAL fragment chance after a won fight = the game's plunderinfo table by level difference (the same table the "Plunder success rate" label shows), from 100 % ("Shall", rival 91+ levels higher) to 0 % ("No", rival 81+ levels lower).
- **Spar win draw (2 Nov 2026):** ORIGINAL drop ids (first spar 1284, below level 30 drop 397, otherwise duelinfo drop 27); the star chances inside 397 / 27 are (ours).
- **Game settings table (2 Nov 2026):** see NEXT-STEPS "The game's own settings table": every price / limit the client's normalconfig gives is now used, except where a photo of the live game showed another number (cross-server ticket 500, secret shop refresh 20 gold). Soul training (`soultrain.js`): advanced doubling x2 and keeping a failed normal doubling's souls are (ours).
- **Free ramen (2 Nov 2026):** owner's choice: the game's own settings, 12:00-14:00 and 18:00-20:00, one bowl in each (the English stall sign says "Once All Time", which is RAMEN_ALLDAY=1).
- **World boss (2 Nov 2026):** ORIGINAL (normalconfig + the game's own text): open 14:00-14:30 ("Battle begins 14:00 daily", 30 minutes from rows 106/107), 10 hits then a 75 s wait (15 gold to skip), reputation per hit = damage / 30 000, silver = damage / 100 (owner chose the originals). **(ours)**: at least 1 reputation a hit, 500 for the killing blow, the server PC's clock.
- **Recharge streak (2 Nov 2026):** days 1-3 and the 7-day bonus ORIGINAL (photo 3942; the "万" ticket is Tael (large), same picture); days 4-6 (ours). "2~5S Shinobi" = a 2-5 star shinobi, weights 40/30/20/10 % (ours).
- **Second-year Christmas list (2 Nov 2026, switch `xmas2`):** ORIGINAL trades from photos 3623-3676; crystals / orbs / red tokens = Sage Stone III / Development Dan / Refresh Order (ours).
- **Generic card fragments (2 Nov 2026):** ORIGINAL item text: 50 fragments = one card of that kind and star (4 or 5; shinobi, equipment, ninjutsu); which card is random (ours).
- **Arena limits (2 Nov 2026):** ORIGINAL (normalconfig rows 18-22, photo 3924): 25 challenges a day, a 10-minute cooldown after every 3, 30 gold clears it; VIP adds one challenge a level from VIP2 (vipinfo col 21). Buying extra challenges is not built.
- **Anniversary festival (2 Nov 2026, `festival.js` theme `anniversary`, switch `anniv`):** ORIGINAL (photos 3720-3817): Fireworks (training) 100 gold, Balloon (spar) 140 gold, the 8 trades with their costs and limits, Anniversary Sasuke as top prize. **(ours)**: crystals = Sage Stone III, purple orbs = Development Dan, the fragment = Anniversary Sasuke (DEF), armour = Sage Robe, shop limits 700 / 600 like Christmas, item ids 40 / 41 with the unused pictures props_343 / props_344, drop chance like Christmas.
- **Country war hours (1 Nov 2026):** original 19:30-20:30 every evening (normalconfig rows 7/8). **Owner decision:** War is open all day; hot update 28.0.27 sets those rows to 0 / 86400 so the clock counts down to midnight.
- **Cross-server battle (1 Nov 2026, `crosswar.js`):** original: arena top 20 free, 500-gold ticket, list Friday 8 pm, battle Saturday 8-9 pm, positions 44-45 +5 and 46-49 +3 points a second, Inspire 200 gold +10 % 300 s, point shop prices 24 000 / 100 000 / 300 000 / 600 000 / 850 000. **(ours)**: 50 positions held by bots at the start (bots grow from 60 % to 140 % of the challenger's strength towards position 1), points of positions 1-43 (50 / 40 / 35 / 30 / 20 / 15 / 10 / 5), 5 boosts a battle, what the shop items are, top-10 rewards (1000 / 800 / 600 / 300 gold + Sage Stone III), points carry over between weeks. There is only one server, so "cross-server" rivals are bots plus your own server's players.
- **Top-up limit (1 Nov 2026, owner):** one free top-up a day per player, on by default; switch "Top-up limit" off in the control panel (Server tab, events) for unlimited top-ups **(ours)**.
- **Starting energy (1 Nov 2026):** a new account starts with 50 energy (above the level-1 maximum of 10) so it gets a few levels in **(ours, owner's choice)**.
- **Gear packs (1 Nov 2026):** stars follow each pack's own text (original): 3☆ bags 2-4 stars (they gave 5-star 29-42 % before), 4☆ bags 3-5, "Five-Star weapon Card" exactly 5-star of that slot. Split for "chance of X, higher chance of Y, at least Z" = 10 / 60 / 30 % and "chance of X, at least Y" = 25 / 75 % **(ours)** (4☆ bags: 5-star about 45 % before, 10 % now).
- **Element restrain (1 Nov 2026):** +15% and who beats whom from the game table `ninjafiveprop` (original); NPC enemies get a fixed element from their ninja id **(ours)**; the bonus only changes the replay, not who wins **(ours, owner keeps the balance)**.
- **Enemy strength (ours, 1 Nov 2026):** enemy team defence 285 at stage 1-2 (from the owner's video of the original) growing evenly to 2 500 000 at the last story stage; Battles use the same range over their 175 rounds; Ninja Test guards = stage value (1160 / 1950 / 2980 / 10 065 at stages 1 / 2 / 4 / 14, from photos) x min(1, (level/280)^2) (fits 5 photos; 2 Nov 2026), bosses +30% (ours).

## Recharge events (added 2 Nov 2026)
- Great gift for total recharge (`totalgift.js`): tiers, rewards and 48 h are ORIGINAL (photo 1238). (ours): which cards match the photo's faces (The Fourth Sage ATK, Hokage Kakashi (God), Kaguya (God)); the amount counted is the dollars of the top-up packages bought while it runs.
- Time limited GiftPack (`limited.js` DISCOUNT): $19 / $60 / 70 h and the four rewards are ORIGINAL (photo 2755). (ours): Gold Key as "the key", the golden Choji EXP card, the pack icons.
- Daily spending gift (`dailyevents.js`): all tiers and rewards (ours): 100 / 500 / 1000 / 2000 gold a day.
- Recharge streak (`dailyevents.js`): "$3 a day" is the screen's own text; the 7 daily gifts and the bonus (300 Reincarnation Pills + 200 Souls Dan) are (ours).

## Limited Super Ninja (added 2 Nov 2026, owner's request)
- `limitsuper.js`, Home button "Super Ninja". The screens and protocol are ORIGINAL; every number is **(ours)** because the dead server decided them:
  featured card = each of the game's 82 god cards in turn, a new one every hour (owner: "for now"; `ROTATE_HOURS`); a pull costs the premium-recruit
  price (300 gold, ten for 2800); 4 % for the featured god card, sure on the 25th pull without one (the count carries over); otherwise a 4-5 star
  premium-recruit card; 1 free pull every 8 hours; 10 points a pull; 3-day ranking rounds (local midnight), prizes mailed to the Awards chest:
  1st Six Paths Naruto (God) + 1000 gold (needs 600 points, about $300 of free top-ups: $99.99 = 5500 gold), 2nd-3rd Hokage Kakashi (God) + 500 gold,
  4th-10th 500 gold, 11th-20th 200 gold. The 1st-prize minimum is the screen's own rule ("The MINIMUM for 1st prise is ...").

## Balancing from the photos (2 Nov 2026, later)
- Monthly sign-in (`signin.js`): days 1-16 and their VIP x2 marks are ORIGINAL (photos 0516, 1871). (ours): which cards (4-star pack days 4 / 9, 5-star pack day 12), days 17-28 = days 5-16 again with VIP marks +4 (at most v15).
- Top-up (`handlers.js` TOPUPS): ORIGINAL packages and the first-top-up x3. (ours): $49.99 = 2400 + 300.
- Akatsuki (`guild.js`): ORIGINAL max levels, the level-5 / level-9 costs and requirements, members 6 + level, donation amounts, mall prices and 30 min refresh. (ours): lower-level costs, +5% donation / +10% mission profit per building level, which item the 2100 + 900 / 3000 + 1800 / scroll goods are, 9 mall spots (last 3 at Mall Lv5), one buy per spot per refresh.
- Country war (`war.js`): ORIGINAL 10 points + 10 exploit + 36 EXP + 36 silver a win, 2 + 2 to the defender. (ours): nothing for a failed attacker.
- Spar (`game.sparFight`): ORIGINAL 15 / 5 W.A.; EXP = level + 4 / a third (ours, fitted to one photo); silver ours.
- Element Change (`game.elementChange`): ORIGINAL 12 pills + 2000 silver for a God card. (ours): 10 / 9 / 6 pills for 5 / 4 / 3-star cards.
- God evolve: ORIGINAL 100 Development Dan. Equipment advance: ORIGINAL 50 000 silver. Small EXP-card bags: ORIGINAL 2000 silver (armor / trinket / skill bags ours).

