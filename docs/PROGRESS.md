# Progress

Everything reported in the bug lists and asked for in chat, and where it stands. Last update: **1 Nov 2026**.

✅ fixed and checked in the game · 🧪 fixed, only checked on a test save (please confirm in the game) · ⏳ still to do · 🚫 can't be fixed from the server (it is inside the game app)

Bug lists: [#2 List 1](https://github.com/Djassie18698/hello-bro-revival/issues/2) · [#3 List 2](https://github.com/Djassie18698/hello-bro-revival/issues/3) · [#4 List 3](https://github.com/Djassie18698/hello-bro-revival/issues/4) · [#5 List 4](https://github.com/Djassie18698/hello-bro-revival/issues/5) · found a new bug? Post it in [Discord](https://discord.gg/2Cbp4UDHrU) or in the newest list.

## Summary

| | Fixed | Test save only | To do | Not possible |
|---|---|---|---|---|
| Bug list 1 | 17 | 0 | 0 | 2 |
| Bug list 2 | 8 | 0 | 0 | 0 |
| Bug list 3 | 9 | 0 | 0 | 0 |
| Bug list 4 | 14 | 0 | 0 | 0 |
| Bug list 5 | 3 | 0 | 0 | 1 |
| Discord reports | 10 | 1 | 0 | 1 |

## Bug list 1

| | Problem | What happened |
|---|---|---|
| ✅ | Training: chapter bosses cost gold | 3 free fights a day per boss, then 10 gold |
| ✅ | Clearing 2-1 opened 3-1 instead of 2-2 | Stages open in order |
| ✅ | Some rewards in training have no image | Ramen (no icon in the game) replaced by Sage Stone III |
| ✅ | Enemies in boss fights show no stats | Real enemies per stage; their defence shows before the hit |
| ✅ | Boss shows 5 challenges instead of 3 | 3 a day |
| ✅ | No rewards from training | Every win drops something |
| ✅ | Reward wheel always "work harder" | Lands on every segment |
| ✅ | Enemies 0 defence, then you lose | Fights rebuilt like the original (from a video of the old game) |
| ✅ | Level rewards can't be claimed | Pay the items shown |
| ✅ | Recruit always free | Blue free every 2 days, purple every 3 days (the game's own recruit table, 7 Nov; was 8 h / 24 h) |
| ✅ | No pity counter on recruit | "Recruit N more will get one" counts down and resets; every 10th pull is a sure 5-star (original, 7 Nov; was 20) |
| ✅ | Rewards show "Sample text" and give nothing | Real rewards |
| ✅ | Recharge / top-up rewards can't be claimed | Work, once each |
| ✅ | Can't claim items, backpack empty | Items arrive |
| ✅ | All sign-in rewards open on day one | One per day |
| 🚫 | Opening scene can't be skipped | Inside the game app |
| 🚫 | No orange-card zoom on 10 pulls | Inside the game app (owner: skip) |
| ✅ | Victory screen shows silver 0 | The win screen had two silver numbers on the same spot: the real one was hidden and the visible one was never filled. Game update 28.0.26 shows the real one (Spar win checked in game) |
| ✅ | The two extra cards next to a drop have Chinese names | The Chinese "大拉面" was the layout's default label: it reads "Big Ramen" now (28.0.30). The card you pick after a Spar win is now a real reward (it was always empty) |

## Bug list 2

| | Problem | What happened |
|---|---|---|
| ✅ | Chains don't work (Sage of the Six Paths) | All chains work and turn red on the card screen |
| ✅ | Level jumps back (17 → 16 → 17) | Fixed |
| ✅ | Boss needs 3 wins to continue | 1 win |
| ✅ | Profile menu bugged | Grudge bar and timers fixed |
| ✅ | "1 in 100" recruit shows wrong numbers | Uses recruitment orders, 5 a day |
| ✅ | Wheel only card or "work harder" | All segments |
| ✅ | Daily tasks give no rewards | Chests pay |
| ✅ | Battles crash | Fixed; each round now has its own enemies |

## Bug list 3

| | Problem | What happened |
|---|---|---|
| ✅ | First-recharge gift gives a "beast" card | Gives Big Ball Rasengan |
| ✅ | Free recruit repeatable while the menu stays open | Second press costs gold |
| ✅ | 0 defence shown in training | Defence shows before each hit |
| ✅ | Same victory card all the time | Random card of that star |
| ✅ | All bosses the same (urgent) | Every stage has its own enemies; strength grows through the whole story |
| ✅ | 7-day goals not translated / do nothing | English, Go opens the right screen |
| ✅ | Shinobi training crashes | Fixed |
| ✅ | "1 in 100" orders count stays at 39 | Updates right after each recruit (fixed 1 Nov) |
| ✅ | 7-day goals: Claim says nothing when a goal isn't reached | Now says "finish all goals first" (update 28.0.20) |

## Bug list 4

| | Problem | What happened |
|---|---|---|
| ✅ | Kaguya + Susa Kakashi chain | Fixed |
| ✅ | Stamina refills when going back to the main menu | Removed; 1 point every 3 minutes like the original (checked: 50/62 shows next 1:19, full 34:19) |
| ✅ | EXP goes up and down before a level-up | Fixed (checked: 505/506 + 16 -> level up with 15/506) |
| ✅ | Same rewards every fight | Drops vary |
| ✅ | Next storyline doesn't open after the last boss | Opens |
| ✅ | Chains broken for all cards (Ten Tails etc.) | All 1,223 chains checked |
| ✅ | Ramen prompt while stamina is full | Gone (checked: a story stage at 70/70 energy runs straight away, no ramen window) |
| ✅ | Soul disenchant gives 0 souls | Gives souls |
| ✅ | Akatsuki upgrades don't work | Work |
| ✅ | Shinobi train menu crashes | Fixed |
| ✅ | Madara + Six Paths Obito chain | Fixed |
| ✅ | Rebirth 7 error | Costs one same card or the shown pills |
| ✅ | Defence 0 before the hit | Shows the enemy's defence |
| ✅ | Defence 0 in Battles too | Same fix |

## Bug list 5

GitHub issue #6 (6 Nov 2026).

| | Problem | What happened |
|---|---|---|
| ✅ | No.1 Shinobi list: challenging a player showed a weak made-up team | The list must send the uid with 5 extra digits (the game cuts 5 off before Challenge); it sent the plain uid, so 22079117 became 220 and the fight was against a made-up "Rival". Also a player far from your level now keeps his name and level. Seen in game: Ninja78277 with his real team |
| ✅ | The 1-in-100 recruit with recruitment orders crashed every time | After the 5 order recruits of the day the server refused, and the shop screen reads the refusal text from an attribute the server did not send, so the game aborted. Every recruit refusal now carries it (shows "You can recruit with orders 5 times a day. Come back tomorrow."). Seen in game: no crash |
| ✅ | Ranking fight showed too little defence (DEAN 4.8-5.1 M in the list, DEF 1.87 M in the fight) | The spar result is decided first and the enemy defence was always scaled to fit it. Now a real player's true defence is shown whenever it already fits the result (a loss against a stronger player); only a lucky win still scales it |
| 🚫 | "1st Recharge" stays on Home after claiming | That button is the Top-up shortcut (CDefaultMainMenu::onBtnPay opens purchase_business.lua); "1st Recharge" is printed in its picture and the app never hides it, in the original too |

## Discord reports
Reports from Discord #bugs-and-issues (log with message ids: docs/DISCORD-REPORTS.md).

| | Problem | What happened |
|---|---|---|
| ✅ | No.1 Shinobi list (Home, scroll icon) showed fake numbers: Offense / Defense Points were level x 10 - level x 20 | Each tab now shows the real thing: the team's attack range, defense range, and the W.A. medal + points. Seen in game |
| ✅ | War > Reward: rewards could not be exchanged | The shop's "current exploit" (and "war exploit" on the War tab) showed the team power, not the exploit you spend, so exchanges were refused. Now it shows the real exploit. Seen in game: 5000, exchange, 4000 |
| ✅ | Story stages took away the boss's tries ("Challenges left" went to 0 after winning a normal stage) | The server sent the tries of the stage just played (0 for a normal stage) instead of the part's boss. Seen in game: 3 left after a story stage |
| 🧪 | Seals: only part of the bonus worked | Seals with several stats ("DEF and ATK +40%", "DEF ATK Cha +80%") only boosted the last stat named. Every named stat now gets the %. Checked on a test save |
| ✅ | Gear sets: 2 of 4 pieces gave the same as the full set | The set screen lights the 2-, 3- and 4-piece lines together, so they add up (Armed: +15 / +30 / +45 %); the server only counted the highest line. Also a weapon whose number matched a seal could count as a set piece. Seen in game: all 3 lines lit with 4 pieces |
| ✅ | Pets ("beasts") never clawed in battle | The fight data never gave the pet a turn. Now the main pet's skill ("1/3 chance to cause X damage", X from the pet screen: Gamakichi 185 + 5 a level) can fire when each of your ninjas starts attacking; its damage counts and the pet jumps in and claws. Seen in game: the toad claws for 430 |
| ✅ | Ninjutsu cut-in showed a black silhouette ("update the full package") instead of the ninja | The fight told the game the attacker's CARD number where it expects the NINJA id, so the cut-in found no picture. Seen in game: Gentle Fist shows Neji and her line |
| ✅ | Elements the wrong way round: Water hitting Fire showed "Fire beats Water" (4 Nov) | The fight screen reads the server's "who beats whom" flag the other way round (CRoundTeamFightView::initLimitData). Now the winning element's icon shows on the beaten side with -15% (their defence, or my attack when they beat me). Seen in game both ways: the hit shows "水 克制 火" (Water restrains Fire) on the beaten Fire ninja, and the result screen's Restrain number lands on the beaten side |
| ✅ | Pets still did not claw for strong teams (4 Nov) | The claw skipped any hit where a ninjutsu fired, which for a strong team is almost every first hit. Now a missed claw waits for that ninja's next hit. Seen in game: ninjutsu on hit 1, the pet jumps in and claws on hit 2 |
| ✅ | War: Auto-Attack could not be bought ("I can't install Auto War", 7 Nov) | The server never handled the Autoplay button. Now Auto-Attack costs 50 gold (original) for the day and attacks for you, also offline; the original war cooldown is back (3 attacks, then 10 minutes, 30 gold skips it) and the two extra options skip it by themselves (5 times 150 gold, 10 times 300 gold, ours). Seen in game: 200 gold taken, "auto attack on", attacks every minute, cooldown after 3 with the paid clears used |
| ✅ | Reincarnation not shown in the fight Comparison list (7 Nov) | The fight data said "reincarnated 0" for every card (and for the first card in the Spar / Plunder lists). Now each card carries its real count. Seen in game: a twice-reincarnated card gets the silver reincarnation corners in Compare |
| 🚫 | The game does not run on 64-bit-only phones (4 Nov) | The game's engine (libgame.so) exists only as a 32-bit file and there is no source code to rebuild it; phones that dropped 32-bit apps can't run it (a player answered this on Discord) |

## Built on request (chat)

| | What |
|---|---|
| ⏳ | Website project (8 Nov, owner: "make it a full project"): short links /download /install /discord /play, top 10 players with glowing names, player pages, Today in the game, players-online graph, team calculator in the wiki, robots.txt + sitemap. Built and checked locally; live after the cloud update. E-mail forwarding and Google Search Console need the owner's clicks at Namecheap / Google |
| ✅ | Control panel: Server, Players & items, Team builder in one site |
| ✅ | Server Manager: who's online, events on/off, top banner, announcement, backups, restart |
| ✅ | Admin: give anything, edit levels / rebirth / growth / item amounts, Unlock everything, reset |
| ✅ | Team builder: whole team in one go, Complete chains, Best gear (owned / all), fight Benchmark (100K-8M); Benchmark rivals in Spar to fight in the game (switch in the Server Manager) |
| ✅ | Account picker: main + 3 starter slots on the login screen |
| ✅ | Limited events: Christmas, New Year, God Recruit, Hot Treasure, Gold spending, Diligence gift, Limited discount, Lottery |
| ✅ | Fights work like the original; enemy strength from 285 (stage 1-2) to 2.5 million (last story boss) |
| ✅ | Card stats use the game's own formula; set bonuses pick the best set; sets, Eight Gates and pets count in fights |
| ✅ | Sage growth with the original chances; rebirth up to 8 |
| ✅ | Discord link on GitHub, in the top banner and in Settings |
| ✅ | Ramen window when out of energy in training |
| ✅ | "Save time" paid far too much (30 000 EXP in chapter 1): now exactly like the original screen from the photos (chapter 11-6 = 3200 EXP / 3800 silver), VIP1 and level 80 needed, 2 free chances a day per VIP level, then 10 gold (checked: chapter 1-1 = 400 EXP / 1000 silver, one Big Ramen used, chances 2 -> 1) |
| ✅ | Levelling up refills grudge too, like the original pop-up (checked: 1/3 -> 3/3, energy full) |
| ✅ | Ninja Test boss chests cost 160 and 250 gold like the original (first one free); after the chests Challenge moves on to the next stage. Guards now show their element (they all showed Water) |
| ✅ | Limited group purchase (discount packs with stock shared by the whole server, original prices; switch in the Server Manager) |
| ✅ | Treasure chests (gold / silver / bronze, with keys from story fights) like the original |
| ✅ | Scratch card ("Lottery" in the Event menu) like the original: 20 gold a card, 1 free a day, 3 matching faces win 5-800 gold |
| ✅ | Eight Gates have levels like the original (LV1, LV2 ... up to 150; cost 80 souls + 1200 silver at LV1, rising) |
| ✅ | Daily Task: original 250-point bar and 250 chest (30 000 silver, 100 gold, 10 Reincarnation Pills, Killer B fragment); all tasks now count |
| ✅ | Shinobi training costs Super Ninja Pills like the original (2 pills, or 1 pill + 10 gold) |
| ✅ | Save file ready for many players: faster write mode, health check, automatic backup every 6 hours while running |
| ✅ | Change country with the Immigration Card (300 gold, from the photos) |
| ✅ | Shop: Reincarnation Pill and Development Dan cost 120 gold, like the original shop photos |
| ✅ | Secret shop Refresh works like the original (Refresh Order or 20 gold, 75 + 5 x VIP a day, new goods every 2 h) |
| ✅ | Ninja Treasure prices like the original (refresh 100 gold, new board every 2 h, explore 35 / 70 / 300 / 320 / 1000) |
| ✅ | Arena daily rewards like the original (rank 1: 25 000 silver + 5000 reputation, at least 2000 + 400). Amounts checked on the arena screens (rank 1 25 000 / 5000, rank 16 15 640 / 3128); the payout itself happens at the daily reset |
| ✅ | Growth Fund in the Event menu, like the original (VIP3, 500 gold, 2500 back) |
| ✅ | Ninja Test guards grow with the stage and your level, matching the original photos (low levels were far too hard). Checked at level 45: stage 1 guards 50-70, stage 6 114-134 |
| ✅ | Faster return to Home (it no longer resends every card); long ninja names fit their box on the team screen (update 28.0.17) |
| ✅ | Ninjutsu in fights: they fire with their own chance and add damage, with the pop-up and animation like the original video |
| ✅ | "Great gift for total recharge" (Timed Gift) like the original photo: top up $240 / $420 / $750 in 48 h for The Fourth Sage + Shakujo, a 2nd-rebirth Hokage Kakashi (God), a 7th-rebirth Kaguya (God) and pills |
| ✅ | "Time limited GiftPack" (Preferential) like the original photo: top up $19 in 70 h, claim a $60 pack (5-star God shinobi, 5 Gold Keys, 4-star ninjutsu, 3 EXP cards) |
| ✅ | Daily spending gift ("Consumption") and 7-day recharge streak ("charging") in the Event menu (rewards are ours: no photo) |
| ✅ | Monthly sign-in like the original May / July screens: 10 000 silver, 20 gold, Recruitment Orders ... with "vN x2" (VIP N or higher gets it twice, and you can sign again after a VIP-up) |
| ✅ | Top-up packages like the original screen ($4.99 = 225 + 15, $9.99 = 450 + 40, $19.99 = 950 + 100, $99.99 = 4800 + 700); your first top-up ever pays triple gold |
| ✅ | "49$ gift" like the original: Naruto card + 80 Reincarnation Pills + 150 Sage Stone III (update 28.0.21) |
| ✅ | Akatsuki like the original: members 6 + level, max levels 9 / 5 / 5 / 5, original upgrade costs, donations 10 gold = +12, 4-star card +18 / +12, 5-star +180 / +180 (card donations now work), the mall sells goods for contribution and refreshes every 30 min |
| ✅ | Country war like the original: a win = 10 points + 10 exploit + 36 silver + 36 EXP; a failed attack gives the defender 2 + 2 |
| ✅ | Spar pays exactly what the game's own preview shows (EXP, W.A., silver from its duel table) |
| ✅ | Element Change works (it did nothing before): 12 Element Change Pills + 2000 silver for a God card, random new element |
| ✅ | God evolve costs 100 Development Dan like the original (it was free); the new card keeps rebirth and growth |
| ✅ | Top-ups: one package a day per player (owner); a switch in the control panel (Server tab) unlocks unlimited top-ups. A second top-up says "You can top up once a day" (update 28.0.25) |
| ✅ | World Boss shows the right name for each boss (always said "Deidara"); bosses rotate and you fight the boss itself (update 28.0.24 not needed, server side) |
| ✅ | 7-day Goals: the Claim button stays grey until the goals are done (a screen error made it look ready; update 28.0.24) |
| ✅ | Wheel of Fortune countdown shows the time to Monday (said "3649 hours") |
| ✅ | "Login with Facebook" says it isn't available and to tap PLAY (showed a page of code) |
| ✅ | Arena lists (Compete and Rank) show each rival's 3 fighters instead of 1 card and empty purple slots (checked in game) |
| ✅ | Opening the Arena crashed the game once rivals had bigger teams: each row now shows the first ninja + 3 teammates, as many as the screen has room for (checked in game) |
| ✅ | Spar, arena and war against a real player now use their real team, strength, elements and nation (before, every real rival was treated as a made-up bot) |
| ✅ | Fights use elements like the original: when your ninja's element beats the enemy's it hits 15 % harder, when theirs beats yours their defence is 15 % higher, and the result screen shows "Restrain" (it always said 0). Water beats Fire, Fire beats Wind, Wind beats Thunder, Thunder beats Earth, Earth beats Water |
| ✅ | Equipment advance costs 50 000 silver like the original (checked: two level-50 5-star Blood Kunai -> +1, attack 125 -> 187, 50 000 silver paid); small EXP-card bags 2000 silver; gold chest opens a day from the VIP table (VIP1 25 ... VIP11 75) |
| ✅ | Real login on our own server: the account window remembers the phone, sign up with a name + password to move phones; public servers only let logged-in players in (new game file) |
| ✅ | Border war rewards like the original: monument HP 300, daily 2 taunt / 2 wander / 4 + 4 clear rewards, 3300 EXP + 786 merit a wander, Gold*50 + pills for breaking a border |
| ✅ | Player log in the control panel: per player when they level up, how long they stay at a team attack, when they reach new chapters and stages
| ✅ | Fights show 3 different enemy ninjas (a real player's own team) instead of the same card 3 times |
| ✅ | Errors show a fitting message (they all said "Your energy level is full") |
| ✅ | Reward pop-ups now also show Souls; every reward always lands in the bag even when the pop-up shows fewer items |
| ✅ | War open all day, the War clock counts down to midnight (game update 28.0.27) |
| ✅ | Victory screen shows the silver you win (game update 28.0.26) |
| ✅ | Daily task chests: the original 6 at 30 / 80 / 120 / 160 / 210 / 250; daily reset at local midnight |
| ✅ | Anniversary festival and the second-year Christmas list (control panel switches); Fireworks / Balloon items (28.0.28) |
| ✅ | Arena: 25 challenges a day (+1 per VIP from VIP2), 10-minute cooldown after 3, Eliminate CD 30 gold |
| ✅ | World Boss: 14:00-14:30, 10 hits then 75 s, original reputation and silver |
| ✅ | Recharge streak days 1-3 + 7-day bonus original; 50 generic fragments make a card |
| ✅ | The game's own settings table: Save time bonus roll, Spar limits, 22:00 energy refill, Money Tree, chests, tower, Millionaire, slot |
| ✅ | Eight Gates soul training (new) |
| ✅ | Free ramen 12:00-14:00 and 18:00-20:00 |
| ✅ | Recruit window updates after every pull; recruits give classic ATK / DEF cards only |
| ✅ | Discord: #updates for every update, #announcement for big news |
| ✅ | Big test round (2 Nov morning): Battles 25 chapters + boss + floor rewards, Spar win card, W.A. titles, set bonuses, plunder chances, Hyourou-gan, item USE, VIP limits, Arena exchange, Team 2, battle reports, friend messages, Akatsuki leader tools, war rankings, Ninja Treasure top list, red dots, Award Center, shop bags, VIP gifts / wheel / prize packs give what they say; new tests (bad input, cheats, new and real saves) |
| ✅ | Events: login streak, God of Wealth, Month card, Flower Worship (switches) |
| ✅ | **Limited Super Ninja** ("Super Ninja" button on Home, 2 Nov): a new god card every hour, won by 1st place of that hour (2nd-3rd 300 gold, 4th-10th 100 gold, every prize needs 50 points). Draws like the original photos: 300 gold, 4-5 star cards, every 10th draw a sure 5-star, a free draw once a day |
| ✅ | Invitation code (Settings): only a friend's game ID counts, once per player (any word used to give 500 gold again and again) |
| ✅ | Soul Disenchant checked again in the game: 4-star cards give 150 souls, 5-star 1000, purple 5-star / god 2000; 3-star cards give 0 (the game's own table) |
| ✅ | Ninja Treasure: "Top Rewards" shows the 16 original big prizes (photo 4335) and every board hides one of them; gold and silver squares show their real amount |
| ✅ | No more 30 000 free starter souls for new players (owner: original); souls come from Soul Disenchant. Players who already got them keep them |
| ✅ | Arena: the daily reward now also gives the ladder prize from the Arena Rules window (ranks 1-1000: gear, a full seal, gold or silver), on top of the daily silver (owner). Seen in the game: rank 3 got 23 000 silver + 4600 reputation + a 5-star Sword of Totsuka (the prize goes to the backpack; the pop-up only lists silver and reputation) |
| ✅ | Android 14 / 15 phones and tablets (owner's Galaxy Tab A9+, Android 15): every installer refused the game file, because the app was made for Android 4.4. Game files made from now on say Android 7, which new Android accepts; PLAY works without the phone permission. Checked on the emulator with a clean install, no permissions given: login, hot update, new player, Home, no tutorial. **Make a new game file** (HOST-MY-SERVER.bat) for phones on Android 14+ |
| ✅ | Public server always on (owner): runs on a free Oracle Cloud machine (tools/vps/install.sh, guide docs/CLOUD-SERVER.md), starts by itself after a reboot, save public.db moved there. Players keep their game file once ninjaonline.duckdns.org points at it |
| ✅ | Starter ninja: the pick on the create screen was ignored, everyone got Shikamaru (the game sends the ninja id 55/56/57, the server only knew 1-3). Seen in game: picked Neji, got Neji + Gentle Fist. The 2 players it hit were given the ninja they picked (owner) |
| 🧪 | Spar list showed made-up attack for real players (Serii level 350 read 4220-4240; her real team is ~7M): the list used 20 + level x 12 for everyone. Real players now show their real team attack / defense / chakra; bots keep the level value. The fight itself was already right. Checked on a copy of the public save |
| ✅ | Owner's 8M-damage local account copied onto his public-server account (uid 7) and named DEAN: tools/copy-player.js (personal data only; login, arena place, mail, war stay). Backup before: backups-public/before-dean-copy-20261103-1811.db |
| ✅ | Black screen on the 2nd start (owner's tablet, Android 15): quitting left the game's process alive, the next start reused it and the game skipped its own setup. The app now really ends when you quit (tools/patch_exit_dex.py -> release/classes-revival.dex). Seen on the emulator and confirmed by the owner on the tablet. New HelloBro-ninjaonline.xapk on the release (3 Nov) |
| ✅ | Players add items themselves on the public server (owner, for now): the item page /admin opens without the password there (ADMIN_OPEN=1 in tools/vps/run.sh). The control panel and wiping a player still need the owner's password. Later: each player only their own account |
| ✅ | Public server froze for ~10 minutes (owner's tablet could not connect): "Best gear" on the item page for a player with 2000 cards took minutes on the small cloud machine, because the server re-read its game data files on every stat calculation. They are now read once: Best gear 16-20 s -> 0.3 s here, every team calculation faster. Checked on a copy of the public save |
| 🧪 | Watchdog on the public server (owner): when the server stops answering for 3 minutes (stuck, like the 10-minute freeze), it restarts itself, also when the owner's PC is off. Tested here with a deliberately frozen server; live after the next cloud update |
| ✅ | Discord #server-status (owner): the bot posts when the public server goes offline, comes back, is updated or restarts (checks every minute while the owner's PC runs the bot). Pinned: how to connect + the item page |
| 🧪 | Super Ninja prizes (owner): the hour's prizes only reached the Awards chest once someone opened the event screen again. Opening the Awards chest now delivers them too. Checked on a test save |
| 🧪 | Starter gift (owner, tablet): the "Exclusive Gift" kept popping up after every level-up with a Chinese "already claimed" button. It now only pops up while the gift is unclaimed (as the original offer did). Checked on a test save, not yet seen after a level-up in game |
| ✅ | Tidier folder (owner): only the .bat files, README and CLAUDE.md on top; the server and its data are in the `server` folder. START-SERVER.bat cleans the old copies out of a friend's folder after UPDATE.bat. INSTALL-WITH-USB.bat can also connect over Wi-Fi (type W). README has a "Which file do I click?" table |
| ✅ | When a phone's XAPK installer still fails: **INSTALL-WITH-USB.bat** installs the game file over a USB cable (as was done for the owner's tablet). HOST-MY-SERVER.bat now suggests the home-network address instead of Tailscale (Tailscale only for friends elsewhere). Tested on the emulator |
| ✅ | Arena: the daily reward could never be claimed in the game (no Claim button). Your own row is now in the Compete list with a **Claim** button (once a day, any time until midnight), then "Claimed" |
| ✅ | Tutorial for new players (owner): built 4 Nov, then switched OFF for everyone on 5 Nov (owner: "leave it off"). The Server Manager switch did not work: the game starts its tutorial by itself for every new character, whatever the server says, so on the public server every new player got it. Game update 28.0.35 turns it off in the game; the switch is gone. Seen in game: a new character starts with no tutorial. Turning it back on is possible, but only for everybody at once (ask Claude) |
| ✅ | Chinese text on buttons (found while playing a new character, 5 Nov): the starter gift's button said 领取 ("Claim"), the guild shop timer could say 结束 ("Ended") and the guild description box said 请输入组织描述. All English now (game update 28.0.36). Seen in game: the starter gift button says Claim |
| ✅ | Reincarnation said "No Lv.50 cards" for maxed cards (late-game test run, 6 Nov): cards top out at level 50 in the original (the game reads it from its upgrade tables) and reincarnation only lists cards at exactly 50, but upgrading could push a card to 51 (one weapon on the public server). Cards now stop at 50 and any card above it is put back to 50 when the server starts. Seen in game: the list shows the level-50 cards and Karin reincarnated with 40 pills |
| ✅ | Country war log said "get 10 points and 0 exploit" while 10 exploit was really given (6 Nov). It now says 10 exploit. Seen in game |
| ✅ | Country tab said "war starts everynight 0:00-0:00" (6 Nov). The war is open all day here (owner's choice), so it now says 0:00-24:00. Seen in game |
| ✅ | Country officials (6 Nov): competing for a seat was free and the daily official gift did not match the bag's own text. Now the original prices (Raikage 20 gold, Custodian 10, Elder 0, the amount the game asks) and the game's own gift packs (Raikage: 5★ / 4★ card or 500 gold; Custodian: the same with 300 gold; Elder: 5★ / 4★ / 3★ card or 100 gold). Seen in game: Custodian cost 10 gold and gave 300 gold |
| ✅ | Evolve took any two cards (6 Nov): the game only lets you pair an attack and a defense card of the same 5★ ninja, but the server never checked, so a cheater could turn two 1★ cards into a god card. Now the server checks the same thing. Seen in game: Minato attack + Minato defense became the god Minato |
| ✅ | Evolve never gave back the Super Ninja Pills (6 Nov): the confirm window says "the super ninja pills used will be returned". The server now counts the pills spent training each card and gives them back on Evolve (with the game's own "[N] super ninja pills returned" message). Only training done from now on is counted. Seen in game: 3 pills spent training, 3 back after Evolve |
| ✅ | Akatsuki Hall log said "executedTask 1" (6 Nov). It now says "executed mission A" (B, C), also for old entries. Seen in game |
| 🧪 | Award Center crashed the game when a control-panel mail had an empty Message box (6 Nov). The server now always sends a text (the title if the message is empty, also for old mails), and gold must be in steps of 5 (the smallest gold pack). Checked on a test save |
| ✅ | Public server: one world only (6 Nov, owner). TRÌNH HÀ LÂN played level 350 on "Starter slot 1" by accident, so they were missing from the rankings. ninjaonline now lists only Konoha (main) (HB_ONE_WORLD=1) and their character was moved there (tools/movechar.js). Seen in game: a phone that last used a starter slot starts on Konoha |
| ✅ | Story bosses never dropped the card shown on their row (6 Nov, owner: Graduate II shows Kakashi Hatake). Now 5 % per boss win (ours) for all 165 bosses. Seen in game: Graduate II gave Kakashi Hatake on the victory card |
| ✅ | Boss button showed 20 gold while the server charged 10 (6 Nov, owner: make it 10). Hot update 28.0.37: every boss shows and asks 10. Seen in game |
| ✅ | Story enemies far too weak for players with the free top-ups (6 Nov, owner; Riskeric 7 283 attack vs 900-1 460 boss defence in chapter 3). Steeper curve: chapter ends 1 = 2 000, 3 = 8 000, 10 = 300 000, 19 = 10 million (was 477 / 1 463 / 55 000 / 2.5 million). Seen in game: Graduate II enemy DEF 1 160 (was 486) |
| ✅ | Training exactly like the original (7 Nov, owner: "I wanna play the game as it was back then"). Found in the game's own tables and checked against 7 boss victory photos: every boss brings all its own enemies (2 to 15) with their own stats (Kakuzu 9-70 21 162 defence, Hidan 19 474, Obito 31 425, Nagato 39 574, Night Kai 1 600 544). Replaces the steeper curve of 6 Nov: bosses from chapter 4 on are 2-15x weaker than before (chapter 10 end 24 905 instead of 300 000). The story wheel uses the game's own odds (silver x2 48 %, EXP x2 24 %, card 24 %, work harder 5 %, gold almost never; was 20 % 3 gold). The result screen shows the boss's name. Seen in game: Hidan 9/9 enemies 20 209 DEF, wheel silver x2 paid |
| ✅ | More original numbers from the game's own tables (7 Nov, owner: "any other tables you missed?"): Battles tower enemies and round drops (Sage Stone I), sage growth falls back to its safe level (3/6/9/12), Lucky Wheel 100 gold with a 1000 pot, border wander 2 500 silver and 5-minute stations, change-country price by population (1500/800/300/150/100), ninjutsu always fire below level 20, first purple recruit = Kimimaro. Also fixed: Battles rounds 1-6 gave an empty award since the morning update (hotfix on the public server). Seen in game: tower win 5 enemies 1 858 DEF + Sage Stone I, wheel asks 0 then 100 gold |
| 🧪 | Battles sweep paid made-up EXP / silver (60 / 90 x chapter) and no item (found 7 Nov night while double-checking). Now it pays exactly what winning that round pays: its own EXP and silver from the game's table and its drop (a Sage Stone I for rounds 1-6). Checked on a test save |
| ✅ | Plunder paid like a spar (a share of the rival's silver on a win). Now it pays what the game's own Plunder Preview shows: EXP for your level, no silver for a win, and a lost plunder costs a little silver (10 to 500 by level). Seen in game: the preview says win EXP 44 / silver 0, lose EXP 15 / silver -126 at level 100, and a win paid +44 EXP and no silver |
| ✅ | Recruit free waits and pity like the original (7 Nov, owner: "switch everything to the original"). The game's own recruit table (recruitinfo, column m_refresh) holds the old server's free waits: purple 3 days, blue 2 days (was 24 h / 8 h). A sure 5-star now comes every 10th purple pull (was 20; the game's news and the Chinese client say 10). Seen in game: blue "Free after 1 days 23 hours" right after its free pull (the same words as a 2016 video), purple window "Recruit 9 more will get one Five-Star Purple" |
| 🧪 | National treasure like the original (7 Nov, owner: yes). The game's own data: after a raid you wait 1 hour before the next (15 gold skips it, the screen asks first), and a guard who beats a raider gets 5 merit. Was no wait and nothing for guards. Checked on a test save |
| ✅ | Admin: **Best team** button (7 Nov, owner: "the team with the highest possible attack and defence, copies or not"). Team editor: 🏆 Best team (owned / all) for attack or defence; it searches the line-up with the team screen's own math (cards, gear, sets, seals, chains), copies allowed, and applies it on OK. Riskeric (29 M): already about the best his cards allow (+0.7 %: Susa Madara (God) for Six Paths Madara (God)); with any card at most +1.3 %. Checked on a copy of the live save and on the dev server. Later: it also picks the gear (sets count; DEAN 17 M -> 31-33 M with all cards), Best gear counts sets too |
| 🧪 | Eight Gates bonus too high above level 100 (7 Nov, owner: "150 % seems a lot"). Your LV150 photo shows +140.5 %, our curve gave 165 %. Now it follows all gate photos (LV100 81 %, LV150 140.5 %). Checked on a test save |
| ✅ | Special ninjutsu loophole (7 Nov, owner: close it). 34 ninjutsu (Sexy Technique, Shuriken, "level 1" Shinra Tensei ...) have a 100 % rate in the game data; our server counted each as +20 % team attack and fired them on every hit. They now count like normal ninjutsu (15 %). Checked by the automatic test |
| ✅ | Breakthrough 10 showed as "+1" and the max message said "Currently not open" (7 Nov, owner). The "+N" font had no 0; game update 28.0.40 adds a 0 to that font, so +10 shows on every screen (card detail, backpack, breakthrough), and the message now says "You have reached the highest possible level". Seen in game |
| ✅ | **Wiki** (8 Nov, owner: "a site like platinumtogether.online/wiki for Ninja Online, hosted on the Oracle server"): https://ninjaonlinereborn.com/wiki/ (own address since 8 Nov evening, owner bought the name; Caddy on the cloud machine, tools/vps/wiki-site.sh), /wiki/ on every server. Home page at https://ninjaonlinereborn.com (owner: "very pretty, with images of the game, like platinumtogether"): game art, screenshots, live status. Every shinobi, gear, ninjutsu, seal, pet, item, set and training stage from the game's own data, with where to get it, chains, stats, the Discord guides and a search. Checked in the browser (desktop, phone, dark mode) and by an automatic test |
| ✅ | Glowing names can **sparkle** (8 Nov, owner: "effects on the names, like sparks, like diamonds"). Game update 28.0.47: diamond twinkles pop up, turn and fade on the name, at Home and in the No.1 Shinobi list; control panel tab ✨ Glowing name > effect "Sparkles" (with a preview). Seen in game on the test server |
| ✅ | Glowing name also on **Home**, in any colour (8 Nov, owner: "make this name in home the same as in the leaderboard, editable from the admin menu ... gold glowing for both of us"). Game update 28.0.45: the name at the top of Home glows like in the No.1 Shinobi list; the control panel tab ✨ Glowing name has the name, a colour (8 quick colours or any) and a preview. A colour change shows in both places the next time Home or the list opens; a new name after reopening the game. DEAN and Riskeric are gold on ninjaonline. Seen in game on the test server (gold, then blue after a change in the panel, without restarting) |
| ✅ | Login screen says **Ninja Online Reborn** + **purple names** (8 Nov, owner: "change the login screen to Ninja Online Reborn ... me and Riskeric a special name in the leaderboard, when I reset my account it still shows my name in glowing purple"). Game update 28.0.43: the login logo is the NINJA ONLINE / REBORN logo of the website; names on the purple list glow purple in the No.1 Shinobi list (the 榜 scroll on Home). The name belongs to the login: after a reset the new character gets it back, nobody else can take it. Control panel > Players & items > 💜 Purple name (owner only). The other rankings (Arena, War, Tower, Wheel) are inside the game app: the name shows there in the normal color. Seen in game on the test server |
| ✅ | Breakthrough numbers like your photos (8 Nov, owner: yes). +1 now needs 10 fragments (was 5) and 60 000 silver (Kyuubi photo) or 250 000 for the strongest god cards (Six Paths Sasuke photo); each level gives +1 % ninjutsu trigger and +2 % restrain (we had them the other way round). Also: the Ninja Test shop now offers fragments for any of your god cards that has a fragment pack in the game, not only your first one. Seen in game: Minato (God) 0/10 and 60 000, Hokage Naruto (God) +9 -> +10 2 500 000 |
| ✅ | Spar and Plunder list (found while playing, 5 Nov): players from the old login (account numbers above 22 million, like yours on your own server) showed a made-up strength from their level (32-52) instead of their real team, so a "weak" rival could beat you. The list now shows their real team. Checked on a test save |
| ✅ | Seal synthesis (found while testing the tutorial): every seal showed "Claim" and was made at once, the green Synthesis button did nothing and the price showed your gold. Now like the original: Claim starts a 30-minute synthesis, Synthesis finishes it now for 30 gold, then Claim takes the seal. Seen in game |
| ✅ | Arena list stayed empty for new players after an admin "reset a player" (a gap in the ranks). Fixed; admin reset also no longer deletes the player's login. Seen in game |
| ✅ | Public server restarted 3 times in one night (owner, 4 Nov): a connection that was cut before it sent anything (a browser dropping a spare connection) stopped the whole server. Now ignored; reproduced and tested on the real server (tools/dev/socket-test.js) |

## Still to build

| | What |
|---|---|
| ✅ | VIP 19-23 (owner, 6 Nov 2026): reachable with top-ups ($70k-$300k, ours), VIP 19-23 shop packs buyable, daily VIP chances follow the game's own table. The badge stays VIP 18 (the app has no pictures for 19+ and crashed drawing them). Seen in game: VIP 23 pack gave Hokage Naruto (God) |
| ⏳ | Card search in the backpack / team picker (owner, 6 Nov 2026): those screens are C++, see NEXT-STEPS 6 Nov |
| ✅ | Cross-server battle ("Cross" building on Home): buy a 500-gold ticket (arena top 20 are in for free), Saturday 8-9 pm fight for positions on the ladder, points every second, Inspire (200 gold, +10 %), Score Ranking, server / nation / history rankings, point shop 24 000 - 850 000 like the original (update 28.0.23) |

## Known, harmless

| | What |
|---|---|
| ✅ | After buying an item in the Shop's Tool tab its count showed the old number (and USE stayed grey) until you logged in again: fixed, the count goes up at once. Gear from shop bags also shows in the Backpack at once |
| 🚫 | "Limited daily gift" packs: the game's own layout for that screen is missing its price, buy button and item labels, so it crashes whatever the server sends |
| 🚫 | Card split ("tear a card to fragments"): no button in this game version opens it |
| 🚫 | Recharge rebate wheel: it only multiplies real-money top-ups, which are free here |
| 🚫 | The "Loading for you, Master" wait on Training and Team: the server isn't asked anything there, it's the phone loading the screen's pictures |
| 🚫 | "INTERSTITIAL 'Leaderboard' REQUEST FAILED - NETWORK_FAILURE" after login: the game app's old ad service (Chartboost) can't load an ad. Harmless; removing it needs a new game app (left for a later app update) |
