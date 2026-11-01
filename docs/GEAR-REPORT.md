# Gear report: where 5-star gear comes from (1 Nov 2026)

Report only: nothing was changed. Numbers come from the server code and the game's own tables; **(ours)** marks values we chose.

## The big one: top-ups are free and unlimited

A top-up costs nothing and has no daily limit, so **gold is unlimited** for anyone who taps the top-up button.
One $99.99 package is 4 800 + 700 = 5 500 gold, which buys about **2 five-star gear pieces** (see the gold prices below).
Everything sold for gold is therefore only limited by patience. The rest of this report assumes a player who does **not** top up.

## Sources for a player who doesn't top up

| Source | 5-star gear | Rate for a free player |
|---|---|---|
| **Ninja Test exchange** (Base, level 45) | Naruto's Tunic 400 / Blood Kunai 450 / Konoha Headband 450 points | Points = 10 x stage (+30 on 5/10/15). Clearing 5 stages = 180 a day, about **1 piece every 2-3 days**; clearing all 15 = 1 290 a day, about **3 pieces a day**. The biggest free source, but it needs 4-5 star ninjas |
| **Monthly sign-in** | 5-star pack on day 12 and day 24 **(ours)** (exactly 5 stars) | **2 a month** |
| **Gold chest** (25 + 5 x VIP opens a day) | 24 % chance of a 4☆-type bag, 10 % of those 5-star | **2.5 % a chest**. With ~95 gold a day at 50 gold a chest: about **1.4 a month** |
| **Shop 4☆ bags** (280 gold) | 10 % 5-star **(ours)** | ~95 gold a day: about **1 a month** (chests are a bit better per gold) |
| **Akatsuki mall** | a 5-star weapon for 2 100 contribution | Gold donations give 12 contribution per 10 gold, so 1 750 gold of donations: about **1 every 18 days** from daily gold alone, and it competes with chests and bags for the same gold |
| **Cross-server shop** | a 5-star weapon for 600 000 points | Position 41 earns 18 000 points a battle, position 1 about 180 000: **3 weeks to 8 months** |
| **Story stages** | none (1-2 star gear, bosses 3-star) | 0 |

**Free player total:** about **3 to 4 five-star pieces a month** without the Ninja Test. With the Ninja Test that rises to **10 to 90 a month**, depending on how far they get each day.
A full team is 4-8 ninjas x 3 gear slots = 12-24 pieces, so a casual free player gears a first team in about **2-3 months**, and a strong one in a few weeks.

## Observations

1. **Free top-ups make gear trivial** for anyone who wants it. This is the design you chose ("top-ups cost nothing"). If you ever want gear to feel earned on the public server, the simplest switch is a **daily top-up limit** (for example one package a day). Not done: your call.
2. **The Ninja Test is the free player's gear source**, and it grows very fast once a team can clear all 15 stages (about 3 pieces a day). Its shop prices are ours. If late-game gear comes too easily, raising those three prices is the knob.
3. **Gold chests beat 4☆ bags** per gold spent (2.5 % for 50 gold vs 10 % for 280 gold = 0.05 vs 0.036 five-star per 100 gold), and chests also give silver, ramen and keys. Fine as is.
4. **Story stages never give 5-star gear.** That matches the original stage drops we know of.

## How the numbers were found
`box.js` (chest weights), `exam.js` (exchange prices and points), `signin.js` (sign-in days), `game.js` `equipFromText` (bag stars), `guild.js` (mall
prices and donation rate), `crosswar.js` (points a second), `handlers.js` `stageAward` (story drops), `docs/BALANCE-SIMULATIONS.md` (about 95 gold a day for a free player).
