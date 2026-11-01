# Balance simulations (2 Nov 2026)

The owner asked: "do a lot of simulations for drop rates, and whether it's possible to finish the game ... without waiting hours for
stamina. Don't apply the results yet, save them in a list and tell me what you would do with them."

**Nothing in the game was changed.** Owner's decision (2 Nov 2026): keep everything as it is (last boss stays 2.5 million) and let it play out, since gold and pulls are freely available. The script is `tools/dev/sim_balance.js` (run it with `node tools/dev/sim_balance.js`); it uses the
game's own tables and the server's own formulas (team power, enemy strength, energy, EXP). Raw numbers: `BALANCE-SIMULATIONS.json`.

## What was simulated

- **A free player** (no top-ups, VIP 0) who plays 4 times a day ("casual") or every 2 hours while awake ("active").
- **Energy:** 1 point every 3 minutes (480 a day), the energy cap of each level, a level-up refills energy.
  The player always pushes the story; when a boss is too strong, they farm the best stage already cleared.
- **Extra EXP per day:** 12 spars (grudge 1 per 2 h), 2 border-war wanders from level 50, 10 country-war wins.
- **The team of a free player grows like this** (an assumption, (ours)):

  | Player level | Cards | Gear |
  |---|---|---|
  | below 30 | 3-star | 3-star |
  | 30-79 | 4-star | 4-star |
  | 80-149 | 5-star, growth 10, rebirth 2 | 5-star |
  | 150+ | God cards, growth 15, rebirth 6 | 5-star |

  - Team slots open by level (from the game's table: 3 at the start, 26 at level 350).
  - Eight Gates, seals, pets, ninjutsu, potential training and set bonuses are **left out**, so this team is on the weak side.
- **Story enemies:** the server's curve, from 285 defence (stage 1-2, from the original video) to 2 500 000 (the last boss, our own choice).

## Results

### 1. The story

| | |
|---|---|
| Stages / bosses | 1 234 stages in 19 chapters, 165 bosses (every boss needs 1 win, 3 tries a day) |
| Wins needed to clear everything once | 3 167 |
| Energy needed to clear everything once | 51 777 = **108 days** of natural energy (level-up refills shorten this early on) |
| EXP per energy | chapter 1: 5, chapter 9: 15, chapter 16: 24, chapter 18: 30 |
| Boss defence (last boss of the chapter) | ch 5: 4 260 · ch 9: 38 021 · ch 12: 127 324 · ch 15: 486 871 · ch 16: 786 053 · ch 18: 1 316 711 · **ch 19: 2 500 000** |

### 2. How strong a free player's team gets (server's own power formula)

| Level | Team | Team attack | Story reachable |
|---|---|---|---|
| 10 | 3 x 3-star | 1 333 | chapter 4 |
| 30 | 5 x 4-star + gear | 7 896 | chapter 7 |
| 50 | 6 x 4-star + gear | 13 186 | chapter 8 |
| 80 | 7 x 5-star + gear | 65 481 | chapter 11 |
| 100 | 8 x 5-star + gear | 77 875 | chapter 12 |
| 150 | 10 x God + gear | 344 196 | chapter 15 |
| 200 | 12 x God + gear | 513 645 | chapter 16 |
| 250 | 16 x God + gear | 784 775 | chapter 17 |
| 300 | 21 x God + gear | 1 261 939 | chapter 19, not the last boss |
| 350 | 26 x God + gear | 1 932 166 | chapter 19, not the last boss |

Real saves for comparison:
- **The level-350 save** (26 God cards, rebirth 8, growth 15, 208 pieces of gear) has 7.9 million attack and beats everything.
- **The level-80 save** has 8 792 attack and gets stuck at boss 7-56.

### 3. Levelling (days of play)

| Player | Lv 50 | Lv 100 | Lv 150 | Lv 200 | After 1 year |
|---|---|---|---|---|---|
| Casual, training only | 7.8 | 20 | 43 | 138 | level 226, story 16-61 |
| Casual + spar, border, war | 5.9 | 12 | 28 | 86 | level 240, story 17-20 |
| Active + spar, border, war | 3.7 | 9 | 23 | 79 | level 240, story 17-20 |

EXP needed in total (the game's own table):

| Level | Total EXP |
|---|---|
| 100 | 82 860 |
| 150 | 325 907 |
| 200 | 1.5 million |
| 250 | 10.3 million |
| 300 | 53.9 million |
| 350 | 164.5 million |

Story progress over time:

| Player | 1 week | 1 month | 2 months | 1 year |
|---|---|---|---|---|
| Casual | chapter 2-3 | chapter 9 | chapter 15 | chapter 16-17 |
| Active | chapter 4 | chapter 11 | chapter 16 | chapter 16-17 |

### 4. Recruits (100 000 pulls each, with the 20-pull pity)

| Recruit | Chance of a 5-star (or better) |
|---|---|
| 300-gold (purple) | 13 % |
| 150-gold (blue) | 7.1 % |
| Recruitment Order | 0.9 % |

- **Free recruits:** 1 purple a day (24 h) and 3 blue a day (8 h) give about **10 five-star cards a month** without spending gold.

### 5. Gold for a free player

| Source | Gold |
|---|---|
| Daily task chests (60 + 120 points) | 70 a day |
| Free scratch card | about 21 a day on average |
| Monthly sign-in | 120 a month |
| Login gifts | 330 once |
| Level-up gifts | 7 310 over levels 10-350 |
| Story wheel | 3 gold on 1 in 5 normal wins |

- **Total:** about **95 gold a day** plus the gifts, which is one 300-gold recruit every 3 days.

### 6. Drops from story fights

| Stage | Drops |
|---|---|
| Normal stage | 46 % Sage Stone III, 28 % 1-2 star gear, 18 % 1-2 star shinobi, 8 % Bronze Key |
| Boss stage | 46 % 3-star gear, 46 % 3-star shinobi, 8 % Silver Key |

- **Keys:** about 1-2 keys a day for a player using all their energy.

## Findings, and what I would do with them (nothing applied yet)

1. **Stamina is not the problem.** Early on, level-ups refill energy, so nobody waits hours: level 50 in 4-8 days, chapter 9 in a month.
   Later, the brakes are boss strength and EXP, not energy.
   **I would:** leave energy as it is.

2. **A free player can't finish the story.** After a year, the model team is at about 0.75 million attack, while the last boss has 2.5 million.
   The 2.5 million is **our own choice** (the original number is lost), so it may be changed.
   **I would:** lower the last boss to about **800 000**, keeping the first stage at 285 (one number, `CURVE.last` in `game.js`).
   Then a dedicated free player finishes in about a year, and the level-350 save still beats it easily.
   If you want the story finished in 6 months: about 550 000.

3. **Levels 250-350 are out of reach without admin help.** The EXP table is the original one, and a free player stops around level 240 after a year.
   Level 350 needs 164 million EXP, about 20 years at the late-game rate.
   **I would:**
   - keep the table (rule: keep it original);
   - add an **"EXP x2" event switch** in the Server Manager for weekends;
   - check later whether the original game had more late-game EXP (EXP pills, events). The photos may show it.

4. **Border war gives a lot of EXP early.** 6 600 EXP a day from level 50 (the photo's numbers, from a high-level player) is about 12 levels' worth at level 50.
   **I would:** scale it with the player's level the way spar does (the game's duel table): about 3 300 at the photo player's level, less below it. Only if you find early levelling too fast.

5. **Recruits are generous.** About 10 five-star cards a month for free, plus the pity. The chances are our own choice.
   **I would:** leave them for friends playing together.
   For a public server, consider 8 % instead of 12 % for the purple recruit, and keep the 20-pull pity.

6. **Gold:** about 95 a day is fine. The free scratch card (about 21 a day on average) is the second biggest daily source.
   **I would:** leave it.

7. **The first boss (1-2):** in the simulation a level-1 player with one 3-star card loses it 3 times and is stuck for the rest of day 1.
   A real new player has their chosen starter card and its ninjutsu, which should win.
   **I would:** check this once with a fresh account in the game.

8. **Fights ignore elements.** "Restrain: 0" on every fight: the game's element table (+15 % against the weak element) isn't used in fights yet.
   **I would:** add it, since it's original, and it makes Element Change worth using.

9. **Gear and team slots matter most.** On the level-350 save, gear makes the team about 17x stronger than the bare cards.
   A free player's real speed depends on how quickly they get 5-star gear, which this model only assumes.
   **I would:** look at where gear comes from (packs, war shop, gear drops) in the next round of simulations.
