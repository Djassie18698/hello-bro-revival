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
