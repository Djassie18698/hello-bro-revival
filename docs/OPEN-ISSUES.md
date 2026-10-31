# Open issues

Everything reported in the GitHub bug lists that is **not fixed yet**, in one place. When something here gets fixed, move it to
the dated `docs/FIXES-*.md` file and delete it here. Last update: 1 Nov 2026.

Bug lists: [#2 List 1](https://github.com/Djassie18698/hello-bro-revival/issues/2) ·
[#3 List 2](https://github.com/Djassie18698/hello-bro-revival/issues/3) ·
[#4 List 3](https://github.com/Djassie18698/hello-bro-revival/issues/4) ·
[#5 List 4](https://github.com/Djassie18698/hello-bro-revival/issues/5)

## To do (the server can fix these)

| From | Problem | Notes |
|---|---|---|
| List 3 | First-recharge gift gives a "beast" as its third item | Check the three drops of `firstpurchase.json` against what the gift screen shows |
| List 3 | Free recruit can be used again and again while the recruit menu stays open | The game only re-reads the timer when the menu opens; the server must refuse the second free pull and answer with the gold price |
| List 3 | Training still shows 0 defence | Partly the game's design (the number under a card is the defence that was *not* broken); check the boss screens again after the scaling fix |
| List 3 | The same card shows up very often after drawing the victory card | Probably the client's own filler table; check what the server drops |
| List 3 | 7-day goals menu is not translated and does nothing | Texts are Thai in `sevendays_quest`; the "Go" buttons and claims need checking |

## Not checked in the game yet

| From | What |
|---|---|
| List 1 | The pity text ("recruit N more times") on the recruit screen |
| List 2 | The chain "ready" list (a partner owned but not in the team) |
| List 1 | Lost fights other than spar (arena, exam, war, border, country) |
| List 4 | Energy refill every 180 s and the exp bar after a main-page visit (fixed on 1 Nov, only tested on a test database) |
| List 4 | Kaguya + Susa Kakashi chain (fixed on 1 Nov, only tested on a test database) |

## Cannot be fixed from the server (game code)

| From | What | Why |
|---|---|---|
| List 1 | The opening scene cannot be skipped | Lives in `libgame.so` |
| List 1 | No orange-card zoom on 10 pulls | Lives in `libgame.so` (owner said: skip) |
| List 1 | Victory screen shows silver 0 | Sending the silver makes the game credit it twice |
| List 1 | Two filler cards next to a drop have Chinese names / no icon | The game picks them from its own table |
| List 2 | Number under the enemy portrait during a fight is 0 | How the game draws a hit that got through; a number there crashes it |
