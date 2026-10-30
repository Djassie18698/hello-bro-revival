# Hello Bro revival server: start here (keep this file short and current)

Replacement server for the dead mobile game Hello Bro (com.hello.bro.yo v28.0, Cocos2d-x 2 + Lua 5.1). The owner is not a
developer. Goal: play exactly like the original with friends, free (top-ups cost nothing), with an admin page.

## Rules
- **Keep it original.** Unlock levels, starting cards, VIP, stage rules come from the game's own data/Lua. If a number is unknown,
  pick one and mark it "(ours)" in code and docs/BASE-FEATURES.md.
- After every working change: `node tools/dev/smoke.js` → `git add -A; git commit; git push` → `sh tools/sync_test_folder.sh` →
  restart the test server (it runs `START-SERVER.bat` from `C:\Users\dj199\Desktop\HelloBro-Fresh-Test\HelloBroServer`).
- Repo **Djassie18698/hello-bro-revival must stay private** (game files, keystore). `hellobro.db` (the save) is never committed.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Emulator: BlueStacks "App Player 5" = adb `emulator-5554` (user's test instance, may be in use: ask before tapping).
  Never touch other instances. Test server address in the game: `100.111.115.0:18080` (Tailscale).

## Where things are
- `server.js` HTTP server :18080 · `handlers.js` one function per endpoint · `game.js` core logic · one module per feature
  (exam, tupo, pet, monopoly, tear, sudoku, sevenday, boss, war, country, border, seals, vip, ...) · `admin.js` /admin page.
- `data/*.json` original game tables · `reference/lua-scripts/` original client Lua (reply formats: grep the endpoint, read `:find()`).
- C++ parsers live in libgame.so; full disassembly at `%TEMP%\hb\all.txt` (grep `'/rl_x'` or a tag name like `'pos_time'`).
- Game-side fixes ship as hot updates: put files in `cdn/src/` (OBB paths), `python -I tools/build_cdn.py 28.0.N` (higher each time,
  delete the previous zip). Log in docs/HOT-UPDATE.md. Current: 28.0.9.
- Docs: `docs/NEXT-STEPS.md` (findings log, newest at the bottom), `docs/BASE-FEATURES.md`, `docs/HOT-UPDATE.md`,
  `HOST-YOUR-OWN-SERVER.md`, `PLAY-ON-TAILSCALE.md`. Discord posting: `discord/dc.js` (`node --env-file=.env dc.js post <channel> <file>`).

## Protocol in one paragraph
Client POSTs `/<endpoint>` with `Uid, Session, ServerID, Cmd, ...`; reply XML `<root code="0">…</root>` (rewritten to `<RENLONG>`).
A missing node a C++ parser reads = SIGSEGV (fault 0x18/0x0) or `this is no node:X` in logcat; Lua = `LUA ERROR`. Return every
field the parser reads. Debug: `adb -s emulator-5554 logcat -d | grep -E "SIGSEGV|LUA ERROR|no node|Respose data"`.

## Open work
Events: scratch card (rl_w_guaguale), lottery (rl_r/w_lottery), daily offers (rl_r_dailylimit, rl_w_dailycost, rl_r_multiple_task,
rl_r_multiple_pay), card split (rl_w_split_card), cross-server battle (rl_*cross_war, rl_w_cwar*). Verify in game: stage clear
counts (pos_time / pk_boss_times guess), team slot unlocks, 28.0.9 VIP refresh.
