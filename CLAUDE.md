# Hello Bro revival server: start here

You are continuing a hobby project: a replacement server for the dead mobile game **Hello Bro / Ninja Online**
(Android package `com.hello.bro.yo`, v28.0, 2015, Naruto-themed card RPG; Cocos2d-x 2 + Lua 5.1 + C++ `libgame.so`).
The owner (Djassie, GitHub `Djassie18698`) is **not a developer**: give click-by-click steps, ready-made `.bat` files, short
answers. Goal: the game plays **exactly like the original**, with friends, for free (top-ups cost nothing), with an admin page.

Read this file fully, then the bottom of `docs/NEXT-STEPS.md` (newest findings). Don't re-read everything else up front.

## 1. Rules (the owner asked for all of these)
1. **Keep it original.** Unlock levels, starting cards, VIP, stage clears, prices: take them from the game's own data
   (`data/*.json`), Lua (`reference/lua-scripts/`) or the C++ disassembly. If the original number is lost (it lived on the dead
   server), choose one, mark it `(ours)` in a code comment and in `docs/BASE-FEATURES.md`. Don't "improve" or hand out freebies.
2. **After every working change**, in this order:
   `node tools/dev/smoke.js` → `git add -A && git commit && git push` → `sh tools/sync_test_folder.sh` → restart the test server
   (section 4). Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. GitHub sometimes answers
   "Internal Server Error": just push again.
3. Repo `Djassie18698/hello-bro-revival` **must stay private** (it holds game files and the signing keystore).
   `hellobro.db` (the save) and `re/` are never committed. A public code-only copy is built by `tools/make_public.py`.
4. **Emulator:** only the BlueStacks instance named **"Claude"** (Android 11; "App Player 5" is gone). Its adb address is not fixed:
   the owner starts it, then run `HD-Adb.exe devices`, ask which entry is "Claude", and save it in `tools/dev/emu.device`
   (one line, e.g. `emulator-5564`; or set `HB_EMU`). `emu.sh` refuses to run without it so it never hits the owner's own
   game instances. Never touch any other BlueStacks instance (the owner tests there) and never use the Multi-Instance Manager.
5. Keep working through the open list (section 9) without asking at every step; ask only for real decisions
   (e.g. "original vs. free"). Explain what changed in plain words; say what is not verified in game.
6. Update this file when a rule, path or the open list changes. Append findings to `docs/NEXT-STEPS.md`.

## 2. First-time setup in a new session (5 minutes)
- Work in `C:\Users\dj199\Desktop\HelloBroServer` (main repo). Git Bash: use short paths, `cd /c/Users/dj199/...`
  (Windows programs fail from very long working directories). Don't put backslashes in Python heredocs; write a script file.
- `pip install pyelftools capstone` (once), then `python -I tools/setup_re.py`: makes `re/libgame.so`, `re/obb/` (the
  original game files: Lua, ccbi, xml, images) and `re/all.txt` (44 MB disassembly of every C++ function with string and
  symbol hints, ~1 minute). It needs a Hello Bro `.xapk` (Desktop has `HelloBro-Tailscale-100.111.115.0.xapk`; otherwise it
  downloads it from the `tailscale-play` release with `gh`).
- Tools on this PC: Node 24 (`node:sqlite`), Python 3.12, JDK 21 (jarsigner), `gh` (logged in), BlueStacks adb at
  `C:\Program Files\BlueStacks_nxt\HD-Adb.exe`.

## 3. Map of the repo
| Path | What |
|---|---|
| `server.js` | HTTP server on :18080 (rewrites `<root` to `<RENLONG`, %20-encodes raw spaces, rate limit, `/admin`, `/cdn/`) |
| `handlers.js` | one function per client endpoint (`rl_r_*` read, `rl_w_*` write, `rl_x_*` mixed, `xk_*` login/directory) |
| `game.js` | core: cards, team/stats, gear, sets, drops (`grantDrop`), gacha, training, fights (`battleXml`), shop, props |
| feature modules | `exam` Ninja Test · `tupo` Breakthrough · `pet` Pets · `monopoly` Millionaire · `tear` national treasure · `sudoku` Ninja Treasure · `sevenday` 7-day goals · `boss` world boss · `war` country war · `country` officials · `border` border war · `seals` plunder/seals · `guild` Akatsuki · `vip` · `wheel` · `mora` · `slot` · `signin` · `rankings` · `stagegift` · `drops` |
| `admin.js` | admin page: give gold/items/cards, set level/VIP, **reset a player** |
| `schema.js` | base tables (modules create their own with `CREATE TABLE IF NOT EXISTS`) |
| `data/*.json` | original game tables `{types, rows}` (ninjainfo, equipmentinfo, roundinfo, dropinfo, consumeinfo, petinfo, ...) |
| `reference/lua-scripts/` | the client's Lua UI (same as `re/obb/script`) |
| `cdn/` | hot-update files the server pushes to every phone (section 6) |
| `tools/` | `smoke.js`, `emu.sh`, `restart.sh`, `probe.js` (in `tools/dev/`), `setup_re.py`, `armdis.py`, `build_cdn.py`, `patch_apk.py`, `make_game_for.py`, `sync_test_folder.sh`, `make_public.py` |
| `release/` | patched apks + `revival.keystore` (password/alias `revival`; ALWAYS sign with it, never make a new one) |
| `discord/` | `dc.js` posts to the owner's Discord (token in `discord/.env`, git-ignored) |
| docs | `docs/NEXT-STEPS.md` findings log · `docs/BASE-FEATURES.md` Base rules · `docs/HOT-UPDATE.md` · `docs/PROJECT-NOTES.md` early history · `docs/MASTER-PLAN.md` old roadmap · `HOST-YOUR-OWN-SERVER.md` · `PLAY-ON-TAILSCALE.md` |

## 4. Running and testing
- **Two servers exist, only one can run (both use port 18080):**
  - the **test server** the owner plays on: `C:\Users\dj199\Desktop\HelloBro-Fresh-Test\HelloBroServer` (its own `hellobro.db`).
    Restart it after a sync (PowerShell): stop the process listening on 18080 and its parent cmd, then
    `Start-Process "<that folder>\START-SERVER.bat" -WorkingDirectory "<that folder>"`.
  - the dev server in the main repo: `bash tools/dev/restart.sh` (logs `%TEMP%\hb\server.log`). The main repo's
    `hellobro.db` holds the owner's main account `22079117` (Ninja78277, level 80, VIP 18) and a friend `22078671`.
- Tests without the game: `node tools/dev/smoke.js` (calls every handler on a temp DB), `node tools/dev/probe.js <endpoint> <Cmd> k=v`,
  or a small node script with `new DatabaseSync(':memory:')` + `require('./schema')(db)` + `handlers.rl_w_login2/rl_w_reg2`.
- In the game: `sh tools/dev/emu.sh restart` → wait ~20 s → `emu.sh update` if "confirm update?" shows → `emu.sh tap 540 1270`
  (START) → `emu.sh shot` and view `re/s.png`. Screen is portrait 1080x1920. Bottom bar y=1860: Home 85, Team 270, Backpack 447,
  Training 630, Spar 805, Shop 980. Base building 530,1215. `emu.sh log` shows crashes/Lua errors/missing nodes/server replies.
  BlueStacks sometimes opens an ad page that eats taps: `emu.sh back`, then relaunch.
- The game server address inside the app is fixed at build time: test apk/xapk use `100.111.115.0:18080` (owner's Tailscale IP).

## 5. Protocol and debugging (how every crash so far was fixed)
- Client POSTs `/<endpoint>` with `Uid, Session, ServerID, GroupID, Cmd, ...`; reply XML `<root code="0">...</root>`.
  Non-zero code = error tip (`code="5"` with `<message>`). Accounts auto-create; sessions only checked with `STRICT_SESSIONS=1`.
- Find the parser: **Lua screen** → grep `reference/lua-scripts` for the endpoint, read every `:find("tag")` (Lua `find` searches
  recursively). **C++ screen** → `grep -n "'/rl_x_name'" re/all.txt`, find the `onHttpRequestCompleted` of that class
  (`awk 'NR<=L && /^=====/'` to get the function), list `-> 'tag'` strings and `FirstChildElement`/`Attribute` calls.
- Crash signs in `emu.sh log`: `Fatal signal 11 ... fault addr 0x18/0x0` = C++ read a missing element; `this is no node:X` =
  element X missing; `LUA ERROR` = Lua read nil. **Return every field the parser reads.** Attribute vs child element matters
  per endpoint. Empty lists can crash too (shop needs ≥1 entry).
- Known traps: award needs `dropid` ≠ 0 (else the card list is skipped); list rows often must be attributes; `<master_pet>` in
  fights needs both `<id>` and `<pet_id>` (only send it with a real pet); `CFightResultData::InitFromXML` reads
  `<userinfo>`/`<fight>`/`<award>` as **root** children; a feature's conf item with a missing icon (stage gift id 31,
  `activity_icon_11.png`) blanks the whole home event column; the client reads item counts only from `rl_r_shoplist` Cmd 1601
  and the VIP level only at login (top-up reply carries `<viplevel>`); every `/rl_...` the C++ calls now has a handler.
- Enable param logging for one endpoint by adding `if (process.env.HB_DEBUG) console.log(...)` and starting with `HB_DEBUG=1`.

## 6. Game-side changes (hot update)
The game downloads `cdn/<val>_update.zip` (via `rl_r_version` `<updatechip>`) and unpacks it over its files. To change a game
file: copy it from `re/obb/<path>` (or `reference/lua-scripts`) to `cdn/src/<same path>` (Lua goes in `cdn/src/script/...`),
edit, `python -I tools/build_cdn.py 28.0.N` with a **higher** N, `git rm` the previous zip, note it in `docs/HOT-UPDATE.md`.
Players tap Confirm once. `mainActivity.lua` is run straight from the OBB by C++: patching it does nothing.
Current: **28.0.9** (top-up/VIP screen, 7-day goals in Event menu, tutorial off via `home/userguideConfig.xml` levels moved to
900+, original pet screens).

## 7. Data model cheat sheet
- `cards.type`: 1 ninja (ninja_id = ninjainfo id) · 2 weapon · 3 armor · 4 trinket (ninja_id = equipmentinfo id) · 5 seal
  (markinfo) · 6 ninjutsu (ninjutsuinfo). Extra columns: level, exp, starlevel (sage growth), newlife, pot_*, breaklvl, attri.
- `team(slot 0-based, seq)`; slots open by `newcardinfo` rows (`game.maxTeam`). `equipped(slot 1-based, kind)`: kind 1 weapon,
  2 armor, 3 trinket, 4 seal, 5-8 ninjutsu.
- `props(prop_id,count)`: consumeinfo ids, plus 9999 souls, 9998 gate souls, 9997 gate level, 9996 arena reputation,
  9995 boss reputation, 9994 war merit, 20000+id seal fragments, 30000+piece_info id card/pet fragments (`game.CHIP_BASE`).
- `progress(chap, stage)`: chap 1-19 training chapters (stage = next open stage), 1000+ tower, 100000+day sweeps.
  `stage_clears` counts clears per stage (roundinfo [42] clears needed, [38] boss, [43] boss tries/day).
- dropinfo row: [3] ninja, [4] equipment, [5] ninjutsu, [6] seal, [7] prop, [8] fragment, [9] souls, [10] gold, [11] silver,
  [12]=1 random pack, [13] amount, [14] pet. `game.grantDrop(db, pl, dropId)` handles all and returns the `<award>` XML.
- roundinfo: [4] chapter, [2] stage in chapter, [22] energy cost, [23] exp, [24] silver.
- New player (original): chosen ninja (Neji 55 / Shikamaru 57 / Sakura 56) + its ninjutsu, 50 gold, 18 000 silver, VIP 0.
  VIP exp = $ topped up × 10, thresholds in `vip.js` (ours). Accounts made before 30 Oct 2026 kept VIP 18.

## 8. Releases and sharing
- Release `tailscale-play` on the private repo: `HelloBro-Tailscale-100.111.115.0.xapk` (game + OBB, one file) + apks.
- `HOST-MY-SERVER.bat` + `tools/make_game_for.py <address>` build a game file for any server address (used by friends who
  host their own; guide in `HOST-YOUR-OWN-SERVER.md`). Public code-only repo: `Djassie18698/hello-bro-revival-public`
  (local clone `C:\Users\dj199\hello-bro-public`), rebuilt with `python -I tools/make_public.py C:/Users/dj199/hello-bro-public`
  (it refuses game files, keystores, the owner's IPs/uids) and pushed after features change.
- Discord: `cd discord && node --env-file=.env dc.js channels|read <ch>|post <ch> <file.md>` (≤2000 chars per message,
  write the text to a file first). Channels include #install-help, #guides, #how-to-play, #announcements, #patch-testing.

## 9. Open work (update this list)
Verify in game: stage clear counts (`pos_time` = clears / `pk_boss_times` = boss tries left is a guess), team slot unlocks,
VIP refresh after top-up (28.0.9), Ninja Test boss stages 5/10/15.
Not built yet (Lua screens exist): scratch card `rl_w_guaguale`, lottery `rl_r_lottery`/`rl_w_lottery`, daily offers
`rl_r_dailylimit`, `rl_w_dailycost`, `rl_r_multiple_task`, `rl_r_multiple_pay`, card split `rl_w_split_card`, cross-server
battle `rl_r_cross_war`/`rl_w_cross_war`/`rl_w_cwar`/`rl_w_cwar_war`/`rl_r_crosswar_rank`, `rl_r_marquee`, `rl_r_migrate_price`.
Other: several "small activities" (`rl_x_small_activity` besides month sign-in) reply empty; 7-day goal texts are Thai in the
data; real login auth (Gumptech SDK) not done. Find more with: compare `reference/client-endpoints.txt` to `Object.keys(require('./handlers'))`.
