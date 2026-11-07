# The Chinese original (火影大人) compared with our English v28

Downloaded on 7 Nov 2026 (owner's OK) from the Wayback Machine:
`renlong_android_qg.apk` (March 2015, 102.9 MB) and `renlong_zqb_.apk` (March 2016, 104.8 MB; its zip index is damaged, the files were
recovered from their local headers). The game is 《火影大人》 by ZQGame / XCKOO (Dec 2013); see `docs/WEB-RESEARCH-2026-11-07.md`.
The apks, their exported tables and the comparison scripts stay in the scratchpad (not in the repo: game files).

## What was compared
- All tables in `assets/tables.bin` (2015: 69, 2016: 74; the same table names as ours, plus the string tables) exported with
  `tools/mbs.py`, then compared row by row and number by number with `server/data/*.json`.
- The 342 Lua scripts and the Chinese texts (help texts, `localizable.lua`, `text.lua`) were searched for odds, VIP thresholds and rules.

## Result: our English v28 is the later, rebalanced edition
- Our tables are **bigger** than the 2016 Chinese ones: 2149 drops vs 1797, 2546 ninjas vs 2499, VIP 0-23 vs 0-18, rebirth table 54 rows vs
  30, 372 fragments vs 252. Gumptech's English release added content after the Chinese March 2016 build.
- Many values were **changed on purpose** for the English release (56 of the 295 shared `normalconfig` rows), for example: change country
  1500 / 800 / 300 / 150 / 100 gold (CN 2500 / 1000 / 500 / 200 / 150), Lucky Wheel pot 1000 + 10 a spin (CN 2000 + 20), ninjutsu sure
  below level 20 (CN 10), purple recruit 300 gold / ten for 2800 (CN 288 / 2590), Growth Fund 500 gold x5 (CN 1000 x3), cross-server
  ticket 400 (CN 500), new players 50 gold (CN 188), equipment advance 50 000 silver (CN 200 000).
- 264 enemy (npc) rows have different stats; sage growth chances, pet stats, VIP pack prices and God of Wealth steps differ too.
- **So a Chinese value never replaces ours.** The English game the players remember is our v28; the 15 boss screenshots of the English game
  all match our table, not the Chinese one. Every change of 7 Nov uses the English value.
- The story-wheel odds (roundinfo columns 26-36) are the same in all three versions.

## Not found in the Chinese client either
Recruit odds and pity count, VIP thresholds (VIP exp per level), boss drop contents, the story-wheel's meaning of the rates: all of it lived
on the server. The Chinese texts only say the same as ours ("a chance of a 5-star, at least a 4-star"). The web research found
"7 premium recruits = a sure 5-star" (Dec 2014, later "10") for the Chinese game; our pity is 20 (ours).
