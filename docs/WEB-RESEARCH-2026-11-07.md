# Web research on the original game, 7 Nov 2026

A side session searched the internet (search engines in English, Chinese, Thai; APK mirror sites; the Wayback Machine;
Chinese game news sites; Baidu Baike) for anything about Hello Bro / Ninja Online. Nothing was changed in the repo. Raw
pages, images and text dumps are in the side session's scratchpad (not in the repo), listed at the end.

## 1. The big find: the game's real name and history

**Hello Bro / Ninja Online is the English release of the Chinese game 《火影大人》 ("Huoying Daren" = "Lord Hokage").**

- The client's own clues match: the internal name *renlong* (the Thai package is `com.xckoo.renlong.hydr_thai`, "hydr" =
  **H**uo**Y**ing **D**a**R**en), and the home-screen line "Thank you for accompanying **Hokage-sama**" is the game's title.
  Chinese guides also call the game 忍龙 (ren long) once.
- **Developer:** 深圳市炫彩酷游科技有限公司 (Shenzhen XCKOO / "Xuancai Kuyou" Technology), Shenzhen Nanshan, website xckoo.com
  (archived 2015-2018). Its game page: "火影大人, role-playing, updated 12 Sep 2014, version **V14.0**, 70.12 MB, iOS + Android".
  It made a cute-art copy of the same game called 《忍者无敌》 ("Ninja Invincible", iOS paid chart no. 4, Android Oct 2014), and
  later 古龙世界 / 指间江湖 (wuxia card games using the same design: nightly clan war, master/protector/elder officials).
- **Chinese publisher:** 中青宝 (ZQGame, Shenzhen Zhongqingbao Interactive), official site **hydr.zqgame.com** (archived
  Dec 2013 - Apr 2016, about 100 pages; see section 3). Baidu Baike wrongly says released 15 Jun 2015; the real first test
  ("不删档测试", no wipe) was **5 Dec 2013** on Android (360, 91, UC, Dangle, Xiaomi, Anzhi, Wandoujia), iOS jailbreak first,
  App Store on 10 Sep 2014. Still updated in Dec 2015 (pets, org boss, org tech). Last Baike version 12.0; alias 忍界传奇.
- **Thai publisher:** **Gump Tech Co., Limited** (gumptech.com / letsgame.mobi, founded 2012, "expert in mobile game publishing
  in Thailand"). Its 2014 home page lists "**Ninja Online** ... Top 2 game in App Store Free ranking, average rating 4.8 in the
  Google Play ... the most magnificent Naruto game of 2014! More 200 cartoon characters, Over 150 spells". Thai Google Play
  `com.xckoo.renlong.hydr_thai`, Thai App Store id908978944 / id887308071, site ninjaol.gumptech.com, Facebook
  facebook.com/ninjaonlinethai, Line ID ninjaol. **Our APK's top-up page is Gumptech's**: `ui_purchaseLayerForWeb.lua` opens
  `http://api.gumptech.com/p/index.do?appId=10015&...`. That portal is **still online** (Nov 2026): it shows "Ninja Online"
  in its game list and a payment page (languages English / Chinese / Thai) with no product prices.
- **English release:** Gumptech's 2015 "games" page lists NINJA ONLINE next to Summoners Alliance, Sailing World, Legend of
  Athena, The Zodiac War. Gumptech's 2014 ad tracker has campaigns "NinjaOnline" and "NinjaOnline_FB_iOS" (Oct 2014). Google
  Play `com.xckoo.renlong.hydr_gp.billing` was archived as already removed (404) in 2024; our `com.hello.bro.yo` (developer
  "BRO", v28.0) appears only on APK mirrors (APKCombo, apk-dl, APKFree, appjap, apkdom, androidapps.games: all blocked,
  dead or with no detail beyond "Train your ninjas to form a strong team and challenge other players to rank high in the
  arena", 4.5-4.57 stars, ~100+ installs, 127 MB, dated 2016).
- **Taiwan:** the 31 Jan 2015 archive of Google Play `com.gpdsb.kokoko.tw` shows **《激戰篇：英雄手裡劍》** by "wangping"
  (wangpinggphy@gmail.com), v22.0.0 of 13 Jan 2015, 101 MB, 5 000-10 000 installs, rating 4.6 (1 449 votes), in-app items
  **USD 1.93 - 101.58**, Android 2.3+. Its description is the same game (150+ characters, 200+ skills, country loyalty,
  country war, national treasury, five-element counters). The client's 4game.com.tw login fits this release.
  4game's 2014 top-up page sold a game called 木葉忍者村 / 木葉忍者(忍蛋) - maybe the same game's earlier Taiwan name (not confirmed).
- Gumptech also ran a different Naruto game, "World of Ninjas / สงครามโลกนินจา" (`world.ying.htgp.th`, QTE swipe combat,
  pre-registration page `gumptech.com/prereg/huoying/`): **not our game**.

Timeline in short: China Dec 2013 (ZQGame) -> Thailand 2014 (Gumptech, v14.0 Sep 2015) -> Taiwan Jan 2015 (v22) -> English
(Gumptech, then "Hello Bro" v28.0). The Chinese articles below describe versions 1.x (Dec 2013 - 2015); the English v28 is
newer, so some numbers may have changed (examples: world boss 12:30 in China vs "14:00 daily" on our English photos; arena
15 then 20/25 tries). Treat each fact as "the original at that date".

## 2. Facts for the revival server (by topic)

Source codes: **[OFF]** = official ZQGame site hydr.zqgame.com (archived), **[XC]** = developer site xckoo.com, **[BK]** =
Baidu Baike entry, **[17173] [7xz] [sina] [cr173] [4399] [18touch] [os]** = Chinese/Thai game news (URLs in section 4).

### Training (历练, "Battles" / story stages)
- **Old version (Dec 2013) [OFF 17206, cr173]:** 18 chapters; each chapter has rounds; a round advances 20% / 40% / 60% / 80% /
  100%; the first 4 steps randomly give silver or a dropped chest; **every round ends with a PK fight**. Energy per step grows
  in later chapters. If you can't win, a "retreat" button top right: **at most 5 retreats a day**. Every chapter can be
  replayed; clears are shown as **stars** next to the chapter (**red banner = clears 1-5, green banner = 6-10**); difficulty
  rises with each clear; **finishing a whole chapter pays gold + silver + a star ninja card**.
- **Chapter clear gold [OFF 17188, 7xz 8674]:** "each difficulty level cleared pays gold, higher difficulty pays more; chapter 1
  at its highest difficulty pays only **70 gold**"; players farmed chapter 1 "up to **difficulty 15**" then moved on; "gold
  from farming is a profit up to level 200". Chapter 1 had 70+ steps [OFF 17270 review].
- **New version (2014) [BK, 7xz 102606 of Feb 2015]:** each chapter is drawn as manga pages, split into small dungeons, each in
  small parts. **Each part's reward comes from a wheel: 2x EXP, gold, 2x silver, ninja card, "Work harder" (nothing)**; every
  part also has a **fixed EXP + silver** reward, so "Work harder" is not wasted. "The wheel often lands on 2x silver."
- **Bosses [BK, 7xz]:** the last stage of each small dungeon is an **attack battle (boss)**: winning it can give top items
  (4-5 star ninjas, equipment, ninjutsu, fragments, keys); the possible drops are shown bottom left. **Each boss battle has a
  try limit; after it you pay gold to open it again.** Every chapter has a boss battle with 5-star items. "At each part's
  BOSS you fight a set character; **after winning you get a pick-1-of-3 draw**, which can give lots of silver" (= our
  "Please draw your victory reward").
- Patch V10.0 [BK]: "training gets an **outstanding BOSS** (杰出BOSS) mechanic: beating it gives rich rewards"; Eight Gates level
  cap opened; W.A. pill (double W.A. from spar); consecutive-login pack; daily ramen use count changed.
- After a fight you win low-star cards (feed material) [OFF 17268 review, BK].

### Energy, spar points, ramen
- **Energy regenerates 1 point per 3 minutes**; levelling up refills energy (and spar points) [OFF 17184].
- **Spar points (斗力, "grudge")**: 1 per spar / treasure-raid fight, **regenerates 1 per 2 hours** (matches the server's +1
  every 2 h), refilled by Hyourou-gan pills and on level-up [OFF 17184].
- **Free ramen at the noodle shop 12-14 h and 18-20 h**, once each, refills energy and spar points [OFF 17184, 17358] (matches
  the server).
- Ramen: old version small = 50% energy, large = full; **new version small = +100 energy, large = +200, each kind max 20 a
  day** [BK]. Shop had a **700-gold ramen pack** (about 14 gold a bowl -> 50 bowls) [OFF 17188]. Thai version: "**10 gold buys
  100 energy**; a stage costs up to 12-15 energy" [os].

### Cards, levels, feeding, refining, reincarnation
- Team level max **300** (Dec 2013) [OFF 17184]; a new team slot about every 10 levels [OFF 17188]; up to 15 cards on a team
  [OFF 17187]. Starting choice: Neji / Sakura / Shikamaru (4-star), plus a free 4-star Kimimaro [OFF 17186, 17268].
- Ninja, weapon, armor, trinket, ninjutsu, seal: each **max level 50, 1-5 stars** (white, yellow, green, blue, purple; later
  orange "god" cards: Six Paths Sage, Goddess Tsunade, Sage Fourth, Six Paths Obito) [OFF 17204, 17190, XC 42]; backpack 1000 items.
- Feeding: EXP given depends on the material's **level, not its stars**; a levelled material passes **50%** of its EXP [OFF 17203].
- Combos: a 5-star card can light up to 5 combos, 4-star 4, ... 1-star none; **each combo +25%**; only one of two named
  partners is needed [OFF 17203, 17186, 17187]. Leader skills: Naruto "+10% ATK/DEF to all", Kakashi "+10%" [OFF 17187].
- Card stats seen [OFF 17187]: 3* Neji ATK 159-261 DEF 95-156; 3* Hinata 150-197 / 90-118; 3* Rock Lee 174-227 / 104-136;
  4* Sakura 157-257 / 94-154; 4* Guy 231-315 / 138-189; 5* Naruto 470-510 / 282-306; 5* Kakashi 241-323 / 144-193.
- Card breakdown (old): **30 green = 1 blue, 17 blue = 1 purple** (later "3-star card split rule changed", notice 17240) [OFF 17188].
- Refining (淬炼, sage stones): normal stones good up to +5, advanced stones from +6; **failure drops a level; max 4 stones per
  try; once at 3, 6 or 9 it never falls below** [OFF 17213] (matches photo text).
- Reincarnation: needs level 50 and the same ninja or reincarnation pills; **3 times per card** [cr173, BK].
- Shop: card-upgrade material packs **2 800** (small) and **13 000** (large) [OFF 17186]; a **380-gold ninja pack** [OFF 17188].

### Recruit (招募)
- Three tiers 百里 / 千里 / 万里挑一 (1 in 100 / 1000 / 10000) with free draws on a cooldown [OFF 17186, 7xz 8674]; the
  starting draws guarantee 2 four-star cards [OFF 17186]. The 百里 free draw gave Kimimaro to new players [OFF 17188].
- "**万里挑一** (1 in 10000) gives the best chance at Madara" [BK]. Thai version: "4-5 star pack, **free once every 4 days**"
  [os] (photos show 2 days 16 h; versions differ).
- 万里挑一 soul system changed, Itachi soul added (notice 17260, Jan 2014) [OFF list].

### Arena (竞技场)
- Opens at **level 25** [17173 c2]. Dec 2013: **15 tries a day, a forced 10-minute rest after every 3 tries (gold skips it)**;
  every day the **top 1000 get a chest**, claimable 24 h after your last claim [OFF 17212, 17199]. Later: **20 tries** [17173
  c2, Nov 2015], **25 tries** [OFF 17342, Apr 2014]. Event "+10 arena tries" on 1 Mar 2014 [OFF 17285].

### Spar (切磋)
- Uses spar points; random rivals or search by name, **not more than 30 levels below you** [OFF 17199, 17208]. Win: EXP, W.A.,
  silver and **3-star equipment / ninjutsu drops** ("the main early source"); lose: silver taken [17173 c2].
- **Robbing the same player at most 5 times a day**, free rival refresh, total spars only limited by spar points [7xz 102606].

### Tower (闯关)
- Opens at **level 30**, each map **once a day**, one-click sweep [17173 c2, OFF 17211]. Best source of **sage stones**; on most
  maps one enemy attacks you, so defence matters [OFF 17211]. Each map has **7 enemies**; progress ranking (top 20); achievement
  rewards by progress, claimable once [XC 41]. Final boss Kaguya [17173 c5].

### Country war (国战) and officials
- **Every night 19:30, lasts 1 hour** (matches `war.js`). Free EXP and silver (no energy). **Winning country: 5 000 silver each.**
  **Merit = kills x 10.** Merit chests: **1 500 / 4 500 / 10 000 / 15 000 / 30 000** merit = blue fragment / purple fragment /
  5-star equipment / 5-star ninjutsu / 5-star ninja card. **10 deaths per player** (killing someone is not a death; losing an
  attack is); **50 gold buys 10 revives** [OFF 17197, 17199, cr173]. Passive kills give W.A. (rank), active kills give merit [XC 44].
- **Officials per country: 1 Kage, 2 protectors (护法), 4 elders** (Ninja Invincible: 2 elders); officials choose which country
  to declare war on. Official packs: **Kage 500 gold, chance of Six Paths Sage (at least 4-star); protector 300 gold, Madara
  (at least 4-star); elder 100 gold, Minato (at least 3-star)** [OFF 17197]. "Kage pack needs 24 h in the seat"; "don't pay
  100 gold to sit on the Kage seat" [OFF 17188].

### National treasury (国家宝库)
- Each country has a fixed **5 000 national treasures**; steal from others, guard your own, hand loot in for silver [OFF 17190, 17199].

### Border stone (边界碑, "boundary monument") [OFF 17341, Apr 2014]
- Each country's stone has **300 HP**, attackable **08:00-24:00**. **Taunt costs 20 gold, wander costs 2 500 silver**; both lower
  the enemy stone's HP and pay EXP + W.A.; being cleared also pays; **rewards max 2 a day**. Clearing intruders (1 spar point
  each) pays EXP + W.A.; **top 3 clearers = "country guardians"** with a guardian pack. When the stones close, everyone gets EXP +
  W.A. by how long their stone survived [OFF 17341, 17283]. Ninja Invincible version: wander 2 000 silver (-10 HP after 10 min),
  taunt 50 gold (-100 HP after 10 min) [XC 40].

### Cross-server battle (跨服战) [OFF 17327, 17330, 17342]
- Weekly: **Friday 20:00 the arena top 20 of each server qualify; others buy a 500-gold ticket; Saturday 20:00-21:00 battle**;
  points from "celestial ladder" positions; **only the first 12 ninja cards fight**; wins give cross-server merit for packs
  (an earlier preview said top 25 and Thursday-Saturday). Same as our photo findings.

### World boss (世界BOSS, Akatsuki) [BK, OFF 17270]
- An Akatsuki member each day (Hidan, Kakuzu, Deidara ...), HP in the tens of millions, **started 12:30 daily** (China).
- Reputation: **every player at least 20 a day**; damage top 10 get extra; **top 3: 200 / 150 / 100; last hit: 200**; gold buys a
  damage multiplier. Shop: **5 000 rep = 5-star Hashirama, 3 000 = his 5-star ninjutsu, 280 = one 万里挑一 draw, 180 = 5-star
  ninjutsu/equipment** (China 2014; the English photos show a different, bigger shop).

### Eight Gates (八门遁甲) [7xz 102606, Feb 2015]
- Souls come from training on wooden posts: normal or advanced training; **3 free a day, then a growing price**; souls can be
  doubled with silver (chance, up to 3x) or **150 gold = sure 3x**. Opening gates gives flat ATK/DEF/Chakra, higher levels add %.
  Gate opening also costs silver. Thai v14.0 (Sep 2015) added Eight Gates and redeem codes.

### Secret shop, souls [OFF 17342]
- Refining 3-star+ cards gives ninja souls; the secret shop shows **6 items, refreshes every 2 h**, **refresh token or 20 gold**.

### Goddesses (flower) [BK]
- Favour: Hinata **1 rose = 1 point**, Mei **30 roses = 1 point**, Tsunade **100 roses = 1 point**; **10 points** wins the goddess.
  Roses from the flower event.

### Events, top-up, month card, login (China, RMB; 1 RMB = 10 gold judging by the month card)
- **Month card [OFF 17358, 17368]: 25 RMB -> 85 gold a day x 30 = 2 550; 50 RMB -> 180 gold a day x 30 = 5 400**; both can be
  owned at once; "super month card, up to 3 at the same time" (Dec 2013) [OFF 17210]; month card doesn't count as first top-up.
- **First top-up:** double (later triple) gold for the first top-up in a new server's first 7 days, plus a free **5-star purple
  card and "Strongest Spear"** [OFF 17358, 17368, 17450]; Dec 2013: first top-up gave **4th Raikage + Strongest Spear** [OFF 17186].
- **Login:** daily login pack; **2 days in a row: +280 gold; 7 days: 5-star Naruto** [OFF 17210, 17358].
- **Level-up rewards every 10 levels** [OFF 17210].
- **God of Wealth (财神): 7 tries, the last needs 15 000 gold**, "about 1.5x gold back" [OFF 17210, 17186].
- **Big wheel (大转盘): 100 gold a spin, 1 free a day**, prizes Madara / gold jackpot / 5-star cards / ramen / stones; point
  ranking (e.g. 1st Naruto attack card, "supreme ninja card", 200 gold, 90 gold) and point shop [OFF 17264, 17279, 17346].
- **Timed top-up packs** (RMB thresholds, e.g. 10 / 50 / 100 / 150 / 250 / 400 / 650 / 1000 / 1500 with listed prizes)
  [OFF 17264, 17346].
- **"超忍限时抽" Limited Super Ninja draw (Apr 2014)**: each draw gives a 4- or 5-star ninja **+10 points** (shop 万里挑一 also
  counts); ranking **1st Six Paths Madara, 2-3 Nagato, 4-10 Tobirama, 11-50 a 5-star card** [OFF 17353]. Compare `limitsuper.js`.
- New-server 7-day rankings: power top 30 (1st/2nd/3rd an exclusive purple card, 4-10 500-1000 gold, 11-30 90-500 gold), level
  top 30 (5-star weapon/armor/trinket, then 50 advanced / 50 normal stones) [OFF 17358, 17368, 17450].
- Daily ramen times and "activity" ad page with exchange; Hot Treasure (热点寻宝): 1 free draw a day, 10-pull for gold,
  main hotspot 1 prize, side hotspots 3 [17173 c1, Dec 2015].
- Organisation (Akatsuki/guild, Dec 2015): leader replaced after **10 days inactive**; org boss = tailed beast in a "beast pen";
  org tech buildings (bonus lost when you leave) [17173 c1].

### Other
- Silver sources: sign-in, training, arena, spar, tower, country war, treasury [17173 c2]. Gift code: Settings menu [4399 a3].
- Five-element counters: **Lightning > Earth > Water > Fire > Wind > Lightning** [OFF 17188].
- Seals (印记): from treasure-raid fragments; **combining takes 30 minutes and the fragments can still be stolen meanwhile**
  [OFF 17202]; tailed-beast seals are the rarest, Ten Tails +40% chakra to all [BK].

### Later details (official news 2014-2015, [OFF hotNews 174xx])
- **Recruit (Dec 2014): 万里挑一 (4-5 star) costs 380 gold, 千里挑一 (3-5 star), 百里挑一 (2-5 star) uses Recruitment Orders;
  万里 and 千里 each have a free draw; "recruit 万里挑一 7 times and a 5-star is certain"** (a Jan 2015 tower article says "10
  draws = a sure 5-star"); new players get 5 Recruitment Orders; orders drop in every dungeon [OFF 17434, 17436]. (English
  photos: 300 gold, so prices were changed for the English version.)
- **Merit shop (Dec 2014): 3 000 merit = 5 five-star ninja fragments; 5 000 merit = advanced ninja pack** [OFF 17434].
- **Officials (Dec 2014): competing for elder is free, protector costs 50 gold, Kage 100 gold; the seat must be held 24 h;
  elder pack = one of 5-star / 4-star / 3-star card / 100 gold; protector and Kage packs differ only in +200 gold and the Six
  Paths Sage chance for the Kage** [OFF 17432]. If your country neither declares nor is declared on, it sits out (5 countries) [OFF 17406].
- **Tower (Jan 2015): 7 guards per map, one of them an attack-type guard (tests your defence); 1 star per guard beaten;
  achievement rewards by total stars: before 91 stars gold + Super Ninja Pills + ninjutsu/seals, 91-133 souls + Reincarnation
  Pills + 万里挑一 draws (2 per reward), from 147 souls + many Reincarnation Pills + 5-star ninja/trinket/armor cards** [OFF 17436].
- Refining a 4-star card gives **400 souls** [OFF 17436]. Refining tips: up to +6 easy, then green to 7, purple to 8 and 9 [OFF 17406].
- **Shinobi training (potential, Jan 2015): 1 Super Ninja Pill per try; "closed training" 2 000 silver at 70%, "master
  guidance" 15 gold at 100%** [OFF 17446] (English photos: 4 000 silver, 70%).
- Reincarnation resets the card to level 1, uses up the material, resets potential and returns the pills (master guidance
  returns more) [OFF 17427].
- Tailed-beast seals need **6-8 fragments**; ten tailed beasts; winning a raid can still miss the fragment ("they ran off with it") [OFF 17452].
- **Goddess flowers (Jan 2015): full favour Tsunade 3 000 flowers, Sakura 2 000, Mei 800** (+ Konan, Hinata); 1 rose per
  1 RMB topped up during the event; rewards e.g. Tsunade: 8 large ramen + 35 Reincarnation Pills + 5 Six Paths Obito
  fragments [OFF 17440, notice 17271].
- Several "all-attribute" cards of the same ninja: one attack + one defence copy give both effects, more copies add nothing [OFF 17406].
- Server merges ("data interworking") in Nov 2014 kept each character separate, renamed duplicates "server_name" [OFF 17410].

## 3. Official update notices (hydr.zqgame.com, newest last)
- 14 Dec 2013: auto-update added; 200 gold to level 30+ players.
- 21 Dec 2013: **Tsunade's rock-paper-scissors** added; Christmas Killer Bee god card; "first top-up super reward" and "timed
  top-up packs" added; **silver income from some sources adjusted**.
- 26 Dec 2013: splitting 3-star (green) cards no longer only gives 4-star fragments, may give silver; **50 blue fragments = 1 blue card**.
- 6 Jan 2014: **daily Akatsuki invasion (world boss) added**; **elite ninjas may appear in training** with rich rewards; W.A.
  pill added; **daily retreat count and ramen use count adjusted**.
- 16 Jan 2014: 万里挑一 soul drops changed: Sage Naruto souls removed, Itachi souls added.
- 20 Jan 2014: big-wheel infinite-claim bug, rollback, 500 gold to everyone, ramen limit reset.
- 26 Jan 2014: Sage Fourth and Six Paths Obito (legendary), Six Paths staff weapon; **treasure chests (gold/silver/bronze, keys
  from training or events, up to 1 000 gold)**; goddess flower event.
- 17 Feb 2014: Millionaire (大富翁) event exists (reward display bug).
- 24 Feb 2014 / **v1.8 (1 Mar 2014): cross-server battle, border stone, potential (Super Ninja Pill) system, new training**:
  "the new training shortens daily play time and increases the end-of-section challenge rewards; **end challenges are normal,
  elite and boss challenges; elite and boss challenges drop blue and purple cards**".
- 28 Mar 2014: arena reworked (points + exchange shop); 百里挑一 can give purple cards; tower achievements + better drops;
  **set bonuses** for ninjutsu/equipment/refine levels; **soul refining (4-star+) + secret shop**; fragments for all cards;
  seals reworked, tailed-beast seal max level 50; one-click seal combine. Note: "monsters were strengthened too".
- **v2.0 (23 Apr 2014): Limited Super Ninja draw; "No.1 Ninja" ranking; 7-day newbie goals (reward 5-star "Young Naruto" and
  all its bonds); Growth Fund ("buy, then claim by level, 8x return"); world boss levels, inspire, damage pop-ups; 10-pull for
  recruit, Millionaire and big wheel; red-dot hints; VIP reworked (VIP levels and VIP packs changed); Tsunade RPS gets a sure-win
  mechanic; 5x refine; material card drops in training changed; God of Wealth and total top-up packs removed.**
- **v12.0 (3 Jul 2014): card inheritance (level, reincarnation, refine, training pass between cards); "Save time" (省时间):
  large ramen converted straight into EXP and silver; new players' first top-up triple; first gold recruit gives a legendary
  Sannin; "Golden Choji" item (big card EXP, much less silver); team slot opening conditions changed.**
- 25 Mar 2014 notice ends with "一路有你，风雨也温柔" = the client's "with you even the storm is gentle".

## 4. Every source found
| Source | What it gives |
|---|---|
| https://web.archive.org/web/2014*/hydr.zqgame.com (official site, ~100 archived pages: `Main/gameData/newbieGuide/*`, `gameGuide/*`, `advancedMaster/*`, `Main/news/officialNotice/*`, `actionCenter/*`, `hotNews/*`) | **Best source**: official rules (training, arena, spar, tower, war, border, cross-server, refining, cards), events, update notes |
| https://web.archive.org/web/2015*/xckoo.com (developer; `gamesShow.php?proID=3` = 火影大人, `newsShow.php?newsID=39-45`) | developer, version V14.0, officials, divine cards, border costs (Ninja Invincible), tower |
| https://baike.baidu.com/item/火影大人/574956 (read in the browser; curl gets 403) | new training wheel + boss tries, ramen +100/+200 max 20, world boss rules, goddess favour, V10.0 patch notes |
| https://news.17173.com/content/09042014/114117597.shtml and the 2015 articles `.../12092015/152554707`, `11202015/151425516`, `10212015/150800811`, `09142015/111031295`, `08042015/120217668` | card system, arena 15-20 tries, tower level 30, silver sources, Dec 2015 update |
| https://www.7xz.com/huoyingdaren/ (articles 8674, 102606, 126537, 126540, 9926) | open beta tips, Eight Gates, story wheel, boss pick-1-of-3, spar 5 robs/day |
| https://www.cr173.com/html/25985_1.html | copy of the official guides (training, war, officials) |
| https://games.sina.cn/mg/st/2014-01-21/detail-ianfzhnh2806869.d.html , .../2014-01-03/detail-iavxeafr2169246.d.html | starter tips, launch article |
| https://news.4399.com/hydr/ , https://news.4399.com/gonglue/hydr/zixun/m/464677.html | gift code pack (100 000 silver notes, 5 large ramen, 5 large pills) |
| https://www.18touch.com/huoyingdaren-2.html | country war announcement (Nov 2013) |
| https://m.ali213.net/hydr , https://app.yeshen.com/games/single/7333 and other download sites | listings only |
| https://web.archive.org/web/20141010043348/http://www.gumptech.com/index.html , `.../20150724132848/http://www.gumptech.com/games.html`, `.../company.html` | Thai/English publisher Gumptech, Thai package and App Store links |
| http://api.gumptech.com/ (live) and `.../p/index.do?appId=10015` | Gumptech portal still up; Ninja Online in its list; no prices |
| https://web.archive.org/web/20140719032026/http://ninjaol.gumptech.com/ | Thai site (just store links) |
| https://www.online-station.net/mobile-game/155807/ | Thai launch article: 10 gold = 100 energy, stage 12-15 energy, 4-5 star pack free every 4 days, wheel EXP x2; YouTube `u2dLvDOrACo` (deleted) |
| https://m.apkpure.com/.../com.xckoo.renlong.hydr_thai | Thai v14.0 (1 Sep 2015, 98.5 MB XAPK still downloadable), description, "what's new: Eight Gates, redeem codes"; 8 promo screenshots |
| https://web.archive.org/web/20150131151333/https://play.google.com/store/apps/details?id=com.gpdsb.kokoko.tw | Taiwan release 激戰篇：英雄手裡劍, IAP USD 1.93-101.58 |
| https://web.archive.org/web/2014*/4game.com.tw (pay pages gid 30/31/35) | 4game top-up page lists 木葉忍者村 / 木葉忍者(忍蛋) (maybe our game) |
| https://web.archive.org/web/2015*/git.letsgame.mobi/document/gumptech-document (ServerDocument.md, GumpTechDocument.md) | Gumptech SDK / login / payment docs (downloaded, not yet read in detail; useful for `gumplogin.js`) |
| **Wayback copies of the original Chinese client** (not downloaded, needs the owner's OK): `https://web.archive.org/web/20150324113612/http://phone.hy.zqgame.com/renlong_android_qg.apk` (100.9 MB, Mar 2015), `.../20160314210311/http://phone.hy.zqgame.com/renlong_zqb_.apk` (103.2 MB, Mar 2016), `.../20150324124121/.../renlong_zqg.ipa` (74.9 MB), `.../20160625040001/.../renlong_zqb_.ipa` (79.6 MB) | the Chinese game itself (Lua + C++), older than our v28; could show Chinese texts, older tables, maybe a test-server URL |
| apkcombo.com, apk-dl.com, apkfree.com, appjap.com, apkdom.com, apksos.com, androidapps.games, apkpure.com (com.hello.bro.yo) | English listing data only; pages dead, blocked (DNS) or empty |

## 5. Searched with no result
- Wayback: `play.google.com/...id=com.hello.bro.yo` (never archived), `com.xckoo.renlong.hydr_thai` (only a 2015 "removed" page),
  `1251001108.cdn.myqcloud.com/*`, `s3-ap-southeast-1.amazonaws.com/renlong/*`, `api.4game.com.tw`, the old game server IPs
  (203.195.181.162, 203.90.233.3, 23.91.96.227), `facebook.com/ninjaonline*`, sgapk S3 bucket (deleted).
- Google Play / App Store live: all versions removed. AppBrain (rate limited), APKMirror, Uptodown: nothing.
- YouTube: the Thai trailer `u2dLvDOrACo` and Gumptech's `oHTYOX8n2_I` are deleted; no gameplay video of Hello Bro found.
- Reddit, GameFAQs, Fandom, Pantip, Bahamut, PTT, Kaskus, Vietnamese forums: nothing about this game (search engines return only
  Tencent's 火影忍者 or Naruto Online). Baidu Tieba 火影大人吧 not reached (needs JS/login).
- English text searches ("Thank you for accompanying Hokage-sama", "Please draw your victory reward"): nothing.
- VIP tables: nothing found for 火影大人 (all VIP results are Tencent's game). Recruit odds: no numbers anywhere.

## 6. Files saved (scratchpad, not in the repo)
Scratchpad root `C:\Users\dj199\AppData\Local\Temp\claude\03973e807da0fe9c\5dfe9e9b-4ed6-476f-9847-f1a0953094f6\scratchpad\`:
`hydr\` (official site pages; 5 of ~100 not archived: notices 17404/17409, hotNews 17355/17408, headline 17351),
`hydr_all.txt` + `gd.txt` (text of the official guides), `notices.txt` (update notices), `hot2016.txt` (2014-2015 news), `xckoo\` (developer site), `cn\` (Chinese
articles + `.txt` dumps), `web\` (Gumptech, 4game, Taiwan Play page, Gumptech SDK docs `doc_server.html`, `doc_gump.html`),
`img\th_screen-*.jpg` (Thai promo screenshots), `web\dl_*.jpg` (Gumptech portal banners), `cdx_*.txt` (archive indexes).

## 7. Most useful new facts (summary)
1. The game is the Chinese 《火影大人》 (ZQGame / XCKOO, Dec 2013); its official site's guides survive in the Wayback Machine.
2. Training: each part ends in a fight; parts pay from a wheel (2x EXP, gold, 2x silver, ninja card, Work harder) plus a fixed
   EXP/silver; each small dungeon ends in a boss with a **daily try limit, then gold**; boss win = **pick 1 of 3**; chapters are
   replayable with rising difficulty and **gold per difficulty cleared** (chapter 1 max 70 gold, up to difficulty 15); 5 retreats a day.
3. Energy +1 per 3 min, spar points +1 per 2 h, free ramen 12-14/18-20, ramen +100/+200 (max 20 each a day), 10 gold = 100 energy (Thai).
4. Country war rules complete: 19:30 for 1 h, winners 5 000 silver, merit = kills x 10, chests 1 500/4 500/10 000/15 000/30 000,
   10 deaths, 50 gold = 10 revives; officials 1 Kage + 2 protectors + 4 elders with 500/300/100-gold packs.
5. Border stone: 300 HP, 08-24 h, taunt 20 gold, wander 2 500 silver, 2 rewards a day, top 3 clearers.
6. Arena 15 tries (3 then 10-min rest), top 1000 daily chest, opens at level 25; tower opens at 30, once a day per map, 7 enemies.
7. Month cards 25 RMB -> 85 gold/day, 50 RMB -> 180 gold/day; login 2 days +280 gold, 7 days 5-star Naruto; God of Wealth 7 tries
   (last 15 000 gold); big wheel 100 gold a spin + 1 free a day; Limited Super Ninja draw = 10 points a draw.
8. Recruit: 万里挑一 380 gold (China), **7 draws = sure 5-star** (later "10"); merit 3 000 = 5 five-star fragments.
9. Patch history: v1.8 (Mar 2014) new training with **normal / elite / boss end challenges, elite + boss drop blue and purple
   cards**; v2.0 (Apr 2014) VIP rework, Growth Fund 8x, 7-day goals, 10-pulls; v12.0 (Jul 2014) "Save time" = large ramen to EXP
   + silver, card inheritance.
10. The original Chinese APKs (2015, 2016) and IPAs are in the Wayback Machine (URLs in section 4); the Thai v14.0 XAPK is on
    APKPure. Not downloaded (needs the owner's OK).
11. Not found in the first pass: VIP thresholds/benefits, recruit odds, exact story-wheel odds, boss enemy stats (see section 8).

## 8. Second pass (videos and forums)

Second session, same day. Videos were downloaded silently (video only) with yt-dlp and read as frame sheets; nothing was
played aloud. Frames and sheets are in the scratchpad folder `v2\` (paths in 8.5). Codes: **[YT-x]** = YouTube video,
**[BB-x]** = Bilibili video, **[TB]** = Baidu Tieba 火影大人吧, **[GP-EN]** = archived English Google Play page.

### 8.1 New releases found
- **English "Ninja Online" (before "Hello Bro")**: Google Play `gt.ninja.online.gpcharge.global.thai`, developer name
  **"CAPABLE STUDIO"**, contact gtstudio.game@gmail.com. Archived page of 15 Mar 2015 [GP-EN]
  (https://web.archive.org/web/20150315071147/https://play.google.com/store/apps/details?id=gt.ninja.online.gpcharge.global.thai):
  version **5.0** of 13 Mar 2015, **100 000-500 000 installs**, 4.4 stars from 21 970 votes, 110 MB, Android 2.3.3+,
  in-app items **USD 1.03 - 103.19**. Text (earlier version): "Register to receive a free five-star Naruto!", 200 characters,
  150 ninjutsu, 400 skill combinations, 800 bonds, 100 legendary items, all 10 tailed beasts. The 5 store screenshots still load
  from Google (saved to `v2\gp_shots\`): story wheel (5 equal parts: silver, gold, EXP x2, Work harder, ninja card; a part paying
  EXP 30 / gold 0 / silver 120 at stage 9-4), ramen shop (Lunch 12:00-14:00 / Dinner 18:00-...), recruit 1-in-10000/1000/100,
  a training win (EXP +59, silver +78, "Please draw your victory reward"), "No. 1 Naruto game in Asean of 2014!".
  A Russian review: "I farmed all **blue and purple missions** every day; after two weeks 60 blue and 2 purple shinobi; 60 blue
  can be broken down into another purple" (= the v1.8 elite/boss challenges); another asks for the game's time zone.
  Official English Facebook page: **facebook.com/ninjaonline.en** (from the [YT-SG] description; one 2016 photo post archived).
- **Vietnam: "I Am Naruto"**, publisher **GAMOTA** with a **Paramida Games** logo, launched end of **September 2014**
  (25 Sep 2014 per a listing), S8 "Tsunade" opened 23 Oct 2014, servers still opening mid-2016 (S94 May 2016, S103 Jul 2016).
  Same new-server events as China (power ranking 1st Obito / 2nd Sasuke / 3rd Fourth Hokage, 4-10 500 gold, 11-30 250 gold;
  level ranking 5-star Kusanagi / Shadow battle robe / Amber vase, then 50 advanced / 50 normal sage stones; first top-up pack).
  Sources: https://gamehub.vn/hub/i-am-naruto-ra-mat-may-chu-tsunade-cung-nhieu-su-kien-hap-dan.20037/ ,
  https://gamehub.vn/hub/soi-gmo-i-am-naruto-sau-2-tuan-ra-mat.17751/ , https://www.9gate.net/game/vn/i-am-naruto-82.html ,
  and video [YT-TB] (Vietnamese client, server S44).
- **China end of life**: Tieba posts say the Chinese servers shut down mid-May 2016 ("热烈祝贺关服" 14 May 2016; a player with
  735 consecutive login days, VIP12, current Kage of server 45; a VIP15 player asks about moving accounts, 11 Jun 2016).
  Private servers appeared from Aug 2016 (pinned thread https://tieba.baidu.com/p/4748702390). Aliases confirmed in a
  2016 post title: **火影大人（忍界传奇，忍龙）**.
- **Another fan revival in China (2026)**: Tieba thread "火影大人近期开放内测" (https://tieba.baidu.com/p/10925991051, Aug 2026):
  "hand-built, all features, closed beta soon"; a tester says it runs with **unlimited gold** and still has many bugs; QQ group
  name 怀旧火影卡牌阅读计划. Probably the source of the 2026 Bilibili clip [BB-2] (new account at VIP18 with 30 000 gold).
  Another 2026 thread asks for the original source code. Nothing technical posted.

### 8.2 Videos with gameplay (what each shows)
| Code | Video | Date | Version | Screens and numbers seen |
|---|---|---|---|---|
| YT-MA | "Ninja Online [Android / iOS] Gameplay (HD)", Maximumandroid, https://www.youtube.com/watch?v=8AFcM2mFGMs | 12 Jan 2015 | English v3.0, server "S3-Neji" | New account: **50 gold, 18 000 silver**, energy **10/10** at Lv1, spar 3/3, team EXP 0/6; starter choice Shikamaru / Sakura / Neji; stage 1-1 "Book of Seal" EXP 6 silver 15 progress 1/2; **1-2 "Will of Kill" (Offensive war, boss) "Challenges left 3"**, shows a 3-star weapon drop; boss fight vs Mizuki team: enemy Lv2 **total defence 285**, our total attack 671 (Lv3); win: **EXP +6, silver +15, gold 0, W.A. 0** + "Please draw your victory reward" (3 cards: ninjutsu, Sasuke card, 3-star weapon); 2-1 "Exam" EXP 4 silver 10 progress 0/2; 2-3 EXP 6 silver 15 0/1; 2-4 "Boss is Here"; energy max **12 at Lv2, 14 at Lv3**; team EXP needed **6 / 9 / 12** at Lv1/2/3; recruit 1-in-10000 **300 gold**, "Free after 4 days 23 hours", 1-in-1000 **150 gold** "Free recruitment", 1-in-100 uses recruitment orders; first draw "Assured to get 5-Star Card", 10 times **2800**; tip "Come again tomorrow, and gain **110 gold** for a login reward"; home unlocks **Plunder Lv10, Battles Lv30, Arena Lv25**; country war "will begin at Today 19:30", officials **Kazekage, Left Custodian, Right Custodian, 4 Elders**, war reward chests at **1000 / 3000 / 3000 / 4000 / 5000** achievement points; level 3->4: attack 42->53, defence 42->53 |
| YT-MT | "Ninja Online - Android Gameplay [Full HD]", MobileTouchGames, https://www.youtube.com/watch?v=XG1wXxoMtIM | 12 Jan 2015 | English v3.0 | Same opening; stage wins drop 1-star cards ("So lucky!" Mizuki, Hyuga Hanabi); boss 2-4 vs Moegi Lv5 **total defence 269**, our attack 642: EXP +6 silver +15; boss 1-2 vs Mizuki Lv2 defence 280; Lv4 energy **16**, Lv5 **18**, team EXP **15 / 18**; "Skill bonus +72" in a fight; spar vs a player; level-5 tutorial to card level-up |
| YT-SL | "Ninja Online/Hello Bro Trick get 5 stars ninja", SO LOONLY RO, https://www.youtube.com/watch?v=AgWYjKuOiJ4 | 9 Oct 2016 | v28 | Lv36 VIP0, energy **65/65**; recruit "Recruit 1 more will get one Five-Star Purple"; secret shop refresh by order or **20 gold**, "Number of refresh today 80/80", "VIP1 +5"; Wheel of Fortune **100 gold a draw, "Once earns 10 points (1st is free daily)"**, bonus pool 1060 gold, prizes incl. 210 gold; S-draw Susa Sasuke (D) **300 gold**, min 240 points; consecutive-login table (day 1 2+2+500 silver, day 2 3+3+800, day 3 3+3+1000: same as our photos); scratch card prizes 20/150/500/800/5 gold; **spar preview: win EXP 23, silver 6, W.A. 15; lose EXP 4, silver -466, W.A. 5**; stages **5-x: energy 6, EXP 12, silver 30, 0/3; 5-2: energy 7, EXP 14, silver 35, 0/3; 13-1: energy 10, EXP 50, silver 80, 0/1; 13-6 "Tough Care" boss: energy 14, EXP 70, silver 112, challenges left 3**; a wheel result EXP 65 / gold 0 / silver 208; boss 13-6 enemy "Konohagakure Middle Chunin" with 5 cards |
| YT-DQ | "Ninja Online - HelloBro gameplay01", DUQUE William, https://www.youtube.com/watch?v=eqEAjysefII | 28 Jun 2016 | v28 | Lv164 VIP0: energy **312/312**, spar 6/6; login days 16/17/18 packs: orders x3, **9000 / 9500 / 10000 silver**, 10 gold, 6 items; recruit **300 gold "Free after 1 days 19 hours"**, 150 gold "Free after 1 days 23 hours"; **stage 14-5: energy 13, EXP 65, silver 104, 0/2; 14-6 "Graduate II" boss: energy 13, EXP 65, silver 104, challenges left 3, a 4-star Kakashi card shown**; boss wins: Lv164 ATK 22 597 (Restrain 322) vs **"Konohagakure Senior Chunin" Lv34 DEF 3 077 (Restrain 187)**, and ATK 22 702 (Restrain 485) vs **Lv34 DEF 2 809 (Restrain 90)**: **EXP +65, silver 0, gold 0** + draw (Hyuga Hizashi / Baiu / Kakashi; Kakashi / Yuunyo Shibi / Katana); **4-2 "Crisis Again": energy 10, EXP 60, silver 90, 0/1; boss 4-3 "Zabuza": vs Zabuza Momochi Lv41 DEF 2 982 (Restrain 37): EXP +78**; spar list "win W.A. 15, silver 404 / 378 / 372 / 275 / 0..."; spar wins vs Lv160-163: **EXP +80 / +78, silver 0, W.A. +15, spar point -1**, draw shows armor cards; "Final kill" screen vs Lv0 DEF 1277 gives EXP 0 |
| YT-PB50 | "Hello Bro - spending 50$ part 1", Poil Bierre, https://www.youtube.com/watch?v=pazFOjNas6E | 25 Dec 2016 | **v28.0**, server S80-Satan | Lv256 VIP5: energy **476/500**, spar 8/8, team EXP 201 546 / 511 009; **treasure chest "Chances today to open the treasure chest 38/50, VIP6 +5 times"**, x2 bonus; **Cumulative gold (spending) gifts: 400 gold -> 1-in-10000 + 20 + 30 + 10; 1500 -> 5-star ninjutsu + 20 + 30 + 30; 2500 -> Ultimate card + 1 + 100 + 50**; **Skill Bag (S) 10 skill cards = 2 800 silver; Armor Bag (S) 2 800 silver; Ninja Bag (L) 50 ninja cards = 13 000 silver**; ninjutsu level-up 7 000 EXP for 3 500 silver; armor level-up 250 EXP for 150 silver; reincarnation Obito: ATK 278-318 -> 319-365, DEF 464-530 -> 533-609, Chakra 325-371 -> 373-426, "Attributes con." 15% -> 20%, skill activation 15% -> 18% |
| YT-SG | "MY NINJA ONLINE TEAM ! (HELLO BRO)", Spirit Gamaken, https://www.youtube.com/watch?v=Md98Egk3_8o | 20 Feb 2017 | v28 | Lv190 VIP1: energy **390/390**, team EXP 414 / **34 282** (same 34 282 as the Chinese Lv190 player), spar 5/6; Son Goku seal DEF +50% |
| YT-TB | "HELLO BRO (I AM NARUTO): Indra S and Asura S vip 0 pro", Trịnh Bảo, https://www.youtube.com/watch?v=5d3ueqdEJOw | 9 Nov 2016 | Vietnamese I Am Naruto | Paramida/GAMOTA splash; Lv254 energy 459/500, spar 8/8; evolve screen; card fragments x/30 |
| others | Gama_Sennin "Hello Bro" parts 1-2 (Jun 2016), Poil Bierre "Road to 600k" eps 1/3/4/5 and "My deck" (2017), Gam Tran "sage naruto" (Jul 2016), DUQUE "Jogando hellobro" (Nov 2016) | | v28 | listed, not all read (team/upgrade footage); copies in `v2\yt\` |
| BB-1 | "火影大人 这个以消失数年的游戏 我找到了", 白帝王xs, https://www.bilibili.com/video/BV1Wx41187jN/ | 27 Aug 2017 | Chinese (after a server merge, Jul 2017) | Lv190 VIP12: energy **390/390**, spar **2/6** (max 6), gold 36 558, silver 71 412; **total top-up packs: 30 RMB (5-star equipment card, 50 advanced stones, 20 Super Ninja Pills, 200 000 silver), 100 RMB (Itachi attack card, 5-star ninjutsu card, 30 evolution pills, 100 advanced stones), 300 RMB ...**; home icons timed gift, scratch card, treasure chest, growth fund; **shop: Evolution Pill 300 gold ("turns an attack/defence card into a god card"), Five-element change pill 500 gold, one item 2 000 gold, Silver note (small) = 2 000 silver; fragments: 50 = 1 card**; "No.1 Ninja" ranking tabs attack / defence / ninja rank |
| BB-2 | "巨好玩的火影卡牌游戏 #火影大人", 唯爱与美食不可辜负v, https://www.bilibili.com/video/BV1CGbh6iErJ/ | 17 Aug 2026 | Chinese client on a 2026 fan server (new account VIP18 with 30 251 gold: **not the original economy**) | Recruit 万里 (4-5 star) **288 gold**, free timer 4 h; 千里 (3-5 star) **180 gold**; 百里 (2-5 star) 1 order, free timer 9 h; **10-pull 2 590 gold**; texts "this recruit is a sure 5-star purple card", "first gold draw gives a legendary Sannin (once)", "first 10-pull gives Third Raikage or better (once)", pity text "再招1?0次后，下次招募必得一张五星紫卡" (digits unclear, probably 10); **shop: Hyourou-gan small (+50% spar points) 8 gold, big (+100%) 10 gold, Sage stone primary (ranks 1-5) 5 gold, advanced (6+) 10 gold, Truce token (1 h) not sold, Silver note small 2 000 silver = 5 gold, large 10 000 silver = 25 gold**; refining at rank 9: **2 stones 8%, 4 stones 16%**, each try 500 silver, "5x refine" 5 gold each; top-up tiers **648 RMB = 6 480 gold, 328 = 3 280, 198 = 1 980, 98 = 980**, "first top-up x2"; first top-up pack = 4th Raikage + Strongest Spear + Shadow Snake Hands; **VIP packs: VIP1 (10 000 silver, 5 large ramen, 5 recruit orders; was 226, now 20 gold), VIP2 (Nine-Tails seal, 30 000 silver, 10 large ramen, 10 orders; now 80 gold), VIP3 (Yasaka Magatama, 10 refresh orders, 10 large ramen, 10 orders; was 1 600, now 160 gold), VIP4 (Fire fan, 15 refresh orders, 10 Reincarnation Pills, 10 orders)**; home unlocks Plunder 10, Battles 30, Arena 25, Organisation 100 |
| BB-3, BB-4 | "你小时候玩的游戏，悄悄复活了？火影大人！" (BV1ggDCBAEKB, Apr 2026), "【火影大人】小时候玩的游戏" (BV1Agd1BzEcG, Apr 2026) | 2026 | | re-cuts of BB-1's footage (same VIP12 account), no new data |

Comments under BB-1 (player memories): "monthly cross-server battle that gave Six Paths Obito fragments", "country war 18-19 h"
(memory, conflicts with 19:30), "officials get one chest a day", "the limited draw's top card is fixed to come last, so it costs a
fixed amount of gold (about 100 000 remembered)", "the training screens were later redrawn in chibi style".

### 8.3 Forum facts (Baidu Tieba 火影大人吧, https://tieba.baidu.com/f?kw=火影大人 , first page of each thread readable without login)
- **VIP thresholds (players' answers in RMB, not official)**: Mar 2014 "VIP3 = 1000" / "700 is enough" / "VIP1 100, VIP2 200,
  VIP3 500" (https://tieba.baidu.com/p/2912548082); May 2014 "VIP3 about 800, VIP2 300+" and "**VIP2 is now 110**" (after the
  Apr 2014 VIP rework) (https://tieba.baidu.com/p/3020465374); Jun 2014 "**VIP18 = about 200 000 RMB**" (4 players agree)
  (https://tieba.baidu.com/p/3112356554). At 10 gold per RMB (month card, BB-2 top-up tiers) VIP18 = about 2 000 000 gold.
- **Recruit odds**: Sina 17 Mar 2014: 万里挑一 "**if the first 9 draws give no 5-star, the 10th is certain**"
  (https://games.sina.cn/mg/n/2014-03-17/detail-ianfzhnh2804740.d.html); a player estimates the 万里挑一 5-star rate at
  "**about 20%**" (sure draws excluded); the measured statistics thread (https://tieba.baidu.com/p/3377327849, Oct-Nov 2014) sent
  its numbers only by private message / QQ group, so they are lost. Many 2015-2016 complaints of 10-18 万里 draws without a 5-star.
  Other sources of 万里 draws: world boss 280 reputation, border defence, organisation shop.
- **Patch v21.0 (11 Nov 2015)** (https://tieba.baidu.com/p/4153408088): ninja house (忍宅) entry, **summon beasts (通灵兽 = pets)**
  and their materials, **world boss rewards changed**, **day-2 login reward changed**, **万里挑一 price changed** (so the
  380 / 300 / 288 prices are different versions).
- **Late training (2016)**: training could drop god-card fragments, whole god cards (attack Night Guy during a "double speed"
  event), Six Paths staff fragments; a training boss "禅杖" needed **2.4 million+ defence and 800 000 "restrain"**; late maps needed
  5-6 million attack; one player "spent 100 000 gold retrying the training Six Paths Madara" (boss retries cost gold).
- Not read in full (login wall after page 1): "final ranking" threads https://tieba.baidu.com/p/4557292041 and
  https://tieba.baidu.com/p/4545949685.

### 8.4 Searched with no result (second pass)
- Bilibili: 火影大人 / 手游 / 中青宝 / 国战 / 抽卡 / vip / 卡牌 / 忍龙 / 炫彩酷游 / 忍者无敌 / Hello Bro / Ninja Online: only the 4 videos
  above (忍龙 returns Ninja Gaiden). Youku, Tudou, iQiyi, Tencent Video, Dailymotion, Niconico: no hits through search engines;
  Douyin/Kuaishou not reachable.
- YouTube: Chinese and Thai title searches give nothing for this game (Tencent's 火影忍者 / Naruto Online only).
- Tieba keyword searches by script are blocked (JS check); only manual page loads work, and replies beyond page 1 need a login.
- Wayback: facebook.com/ninjaonline.en (only 1 photo page), woninja.th (none); the Tieba odds thread (archive offline at the time).
- Still not found anywhere: an official VIP table, official recruit rates, story-wheel odds, Battles (闯关) enemy numbers, arena
  reward claim time beyond "24 h after your last claim" (Dec 2013).

### 8.5 Files (scratchpad `C:\Users\dj199\AppData\Local\Temp\claude\03973e807da0fe9c\5dfe9e9b-4ed6-476f-9847-f1a0953094f6\scratchpad\v2\`)
`yt\*.mp4` (11 YouTube videos, video only); frame sheets `s_max\`, `s_mtg\`, `s_loon\`, `s_poil50\`, `s_duque\`, `s_spirit\`, `s_trinh\`
(`sheet_N.jpg`); `watch\watch-1h8uhvye\sheets\` (BB-1); `watch\watch-lih55wiq\big\s1-s8.jpg` and `vip.jpg` (BB-2 enlarged);
`gp_shots\s1-s5.jpg` (English Play screenshots); `gp_global.html` (English Play page); `yt_meta.txt`, `yt_desc.txt` (video details).

### 8.6 Most useful new facts (second pass)
1. **Boss enemy numbers from real fights**: v28 English (2016): chapter 4 boss Zabuza Lv41 DEF 2 982; chapter 14 bosses
   "Konohagakure Senior Chunin" Lv34 DEF 2 809 and 3 077; v3.0 (Jan 2015): Mizuki Lv2 DEF 280-285, Moegi Lv5 DEF 269. Boss
   cards show "Challenges left 3"; a win pays the stage's EXP (+65 / +78) with silver 0 (v28) or +15 (v3.0, chapter 1-2) plus a
   pick-1-of-3 draw (cards / equipment).
2. **Stage numbers seen** (energy / EXP / silver / clears): 1-1 ?/6/15/2, 2-1 ?/4/10/2, 2-3 ?/6/15/1, 4-2 10/60/90/1,
   5-x 6/12/30/3, 5-2 7/14/35/3, 13-1 10/50/80/1, 13-6 boss 14/70/112, 14-5 13/65/104/2, 14-6 boss 13/65/104 (compare with roundinfo).
3. **Energy cap by level**: Lv1 10, Lv2 12, Lv3 14, Lv4 16, Lv5 18, Lv36 65, Lv164 312, Lv190 390, Lv254-256 500;
   team EXP to the next level: 6 / 9 / 12 / 15 / 18 at Lv1-5, 34 282 at Lv190, 511 009 at Lv256.
4. **New account (English v3.0)**: 50 gold, 18 000 silver; login tip "110 gold"; recruit 300 / 150 gold with long free timers
   (4 d 23 h at the start; v28 1 d 19 h / 1 d 23 h); 10-pull 2 800 (2026 Chinese fan server: 288 / 180 / 2 590).
5. **Shop prices**: Hyourou-gan 8 / 10 gold, sage stones 5 / 10 gold, silver notes 2 000 for 5 gold and 10 000 for 25 gold,
   Evolution Pill 300 gold, Five-element pill 500 gold; material bags 2 800 silver (10 cards) and 13 000 silver (50 cards).
6. **VIP**: VIP1-4 pack contents and prices (20 / 80 / 160 gold ...); players say VIP2 = 110 RMB after the Apr 2014 rework and
   VIP18 = about 200 000 RMB; treasure chests 50 a day (+5 at VIP6); secret shop 80 refreshes a day (+5 per VIP level).
7. **Spar**: a win gives W.A. +15 and EXP roughly rival level / 2 (+80 vs Lv163, +78 vs Lv160-161); preview at Lv36 showed
   win EXP 23 / silver 6 / W.A. 15, loss EXP 4 / silver -466 / W.A. 5.
8. **Releases**: English "Ninja Online" by CAPABLE STUDIO (v5.0, Mar 2015, 100k-500k installs) came before "Hello Bro";
   Vietnamese "I Am Naruto" by GAMOTA (Sep 2014); China closed May 2016; a second Chinese fan revival is in closed beta (Aug-Oct 2026).
