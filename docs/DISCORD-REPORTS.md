# Discord bug reports

Every report from Discord #bugs-and-issues, so later sessions know what was handled. Newest at the bottom.
How: read `cd discord && node --env-file=.env dc.js read bugs-and-issues 50`, handle anything newer than the last entry here,
then react ✅ on the report (`dc.js react bugs-and-issues <id>`) and reply to it (`dc.js reply bugs-and-issues <id> <file>`)
with what is fixed and what not. The fixes themselves are rows in `docs/PROGRESS.md` ("Discord reports").
Since 8 Nov 2026 the bug helper (discord/bughelper.js) collects the details in a thread and posts the report in #bot-logs with
`report-id: <thread> · post-id: <post>`: put that report-id in the Message id column (the scheduled fixer checks it), answer in the
thread (`dc.js post <thread> <file>`) and react ✅ on the post id.

| Message id | Date | Report | State |
|---|---|---|---|
| 1566579797059174401 | 3 Nov 2026 | (Spanish) how to play on Android | question, not a bug: the install guide covers it |
| 1567205978535895103 | 3 Nov 2026 | 5 bugs: leaderboard power, war reward exchange, story stages using boss tries, seal bonuses, gear set bonuses | all 5 fixed (seals checked on a test save, the rest seen in game); ✅ + reply |
| 1567214376513966143 | 3 Nov 2026 | pets ("beasts") don't claw in battle (screenshot + 2 videos, also forwarded by the owner) | fixed, seen in game; ✅ + reply |
| 1567214670832738428 | 3 Nov 2026 | ninjutsu cut-in shows a black silhouette instead of the ninja (screenshot) | fixed, seen in game; ✅ + reply |
| 1567390561441153025 | 4 Nov 2026 | pet ("beast") still doesn't claw (level 350 team) | fixed on a test save (claw skipped when a ninjutsu fired); ✅ + reply |
| 1567390858418982912 | 4 Nov 2026 | elements wrong way round: Fire counters Water (+ 1567390645566316599 "only the Water element") | fixed on a test save (restrain sign); ✅ + reply, asked what "only Water" means |
| 1567392488426053733 | 4 Nov 2026 | Daily Task "display error" (screenshot) | unclear: texts are original, numbers look right; asked the reporter |
| 1567614732360351845 | 4 Nov 2026 | game won't run on 64-bit-only Android phones | not possible (32-bit engine, no source); a player (bakeddean) already answered, no bot reply |
| 1568478363167883306 | 7 Nov 2026 | "I can't install Auto War" (War screen screenshot) | fixed, seen in game (Auto-Attack 50 gold, offline too; original war cooldown back); ✅ + reply |
| 1568478566830702695 | 7 Nov 2026 | reincarnation not shown when comparing line-ups (fight Comparison) | fixed, seen in game (reincarnation corners on the card); ✅ + reply |
| 1569435156249313410 | 9 Nov 2026 | Golden Chōji EXP card gives far less EXP than the Level Up preview (Ronin, ninjaonline; brother too) | fixed on a test save (EXP cards start at their table level: Golden Chōji Lv 25 = 8125 EXP); thread reply + ✅; live after the next public update; already-eaten Chōjis not given back (owner's call) |
| 1569525817178857482 | 10 Nov 2026 | INSTALL-WITH-USB.bat: winget 404 downloading adb, still said "Installed" (enzobfer, Samsung S25 Ultra, 2 PCs) | installer fixed by the owner in the thread (6996649: adb straight from Google); the phone then refused the game: S25 is 64-bit only (not possible, same as 1567614732360351845); thread reply + ✅ |
| 1569525706851876895 | 10 Nov 2026 | "hello" (enzobfer), nothing else | no report; asked once in the thread what went wrong; waiting for the player |
| 1569733094368481320 | 10 Nov 2026 | Sage Growth: "maximum" does not add extra stones (buva, ninjaonline, Sage 13) | fixed 10 Nov (same fix as the next row), checked in the game; thread reply + ✅ |
| 1569733275319271478 | 10 Nov 2026 | Sage Growth: more extra stones do not raise the chance, "+0%" (buva, ninjaonline) | cause: rate list sends stone_level 7/8, the game wants 1/2 (CStrengthView parser), and our cap = the 4-stone chance; fixed 10 Nov: stone_level 1/2, ORIGINAL photo rates +0.2 % a Sage Stone III up to +10 % (owner chose original), Sage Stone I +0.1 % (ours); checked in the game; thread reply + ✅ |
| 1569809097627271301 | 10 Nov 2026 | Secret Shop: grain x10 costs 4000 Ninja Souls, should be 400 (buva, ninjaonline) | fixed on a test save: client table row 206 typo, original photos show 400 (game.js SECRET_COST_FIX); thread reply + ✅; live after the next public update |
| 1569810063873409064 | 10 Nov 2026 | Pet (Gamakichi) training / advance give tiny stat gains (+1 / +4) (buva, ninjaonline) | level-up and advance match the original; training stars now flat petupgradestar 50..1400 and the rank bonus in the "+" box, like the original Advance photos 3483/4124/4249 (owner: "what do the pictures say? give it to the fixer", 10 Nov); fixed on a test save; thread reply + ✅; live after the next public update |
| 1569828413659938877 | 10 Nov 2026 | Double EXP Pill: training EXP not doubled (buva, ninjaonline) | the server doubled the save, but the client credits only the stage table exp + the award <exp> (CSectionCellView / AddDataFromReward); the extra copy now goes in the award <exp>; fixed on a test save (smoke check); thread reply + ✅; live after the next public update |
| (#general, lephuc 14:07) | 12 Nov 2026 | Flower Worship reward list: "ninja card very big" (screenshot: Third Raikage art covers the list) (lephuc, ninjaonline) | flower.js sent folder npc (394 px art) for card rewards; now icon/icon_npcX_Y. Also swapped Tsunade/Sakura rows (ui_nvshenDescLayer names rows Hinata, Konan, Mei, Sakura, Tsunade). Seen in game on the emulator; smoke check. Posted in #general, so no bot reply there (chat channel) |
