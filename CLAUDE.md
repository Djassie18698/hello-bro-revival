# Hello Bro revival server: start here

You are continuing a hobby project: a replacement server for the dead mobile game **Hello Bro / Ninja Online**
(Android package `com.hello.bro.yo`, v28.0, 2015, Naruto-themed card RPG; Cocos2d-x 2 + Lua 5.1 + C++ `libgame.so`).
The owner (Djassie, GitHub `Djassie18698`) is **not a developer**: give click-by-click steps, ready-made `.bat` files, short
answers. Goal: the game plays **exactly like the original**, with friends, for free (top-ups cost nothing), with an admin page.

**Phase (since 2 Nov 2026): bug fixing.** Every screen of the game works; what comes in now is mostly bug reports from the owner
and players. Section 2 is the bug-fix loop. New features only on the owner's request.

Read this file fully, then the bottom of `docs/NEXT-STEPS.md` (newest findings). Don't re-read everything else up front.

**The five places this project lives** (know which one a request is about):
| Place | What | Section |
|---|---|---|
| `C:\Users\dj199\Desktop\HelloBroServer` | the main repo: you work here; dev server on :18081 | 3, 4, 5 |
| `C:\Users\dj199\Desktop\Hello Bro Locked Server` | the owner's own play server (:18080, their save): only the owner starts/stops it | 5 |
| Oracle cloud machine `ninjaonline.duckdns.org` | the PUBLIC game server (:18080), the Discord bot, and the website | 5, 6 |
| https://ninjaonlinereborn.com | the website: home page + wiki at `/wiki/` (Caddy on the cloud machine; domain at Namecheap) | 6 |
| GitHub `Djassie18698/hello-bro-revival` (public) | the code, README front page, issues (bug lists), release `tailscale-play` (game files) | 1, 2, 10 |

## 1. Rules (the owner asked for all of these)
1. **Keep it original.** Unlock levels, starting cards, VIP, stage clears, prices: take them from the game's own data
   (`server/data/*.json`), Lua (`server/reference/lua-scripts/`) or the C++ disassembly. If the original number is lost (it lived on the dead
   server), choose one, mark it `(ours)` in a code comment and in `docs/BASE-FEATURES.md`. Don't "improve" or hand out freebies.
   "Is this normal?" questions: check the game's own code first; often the answer is "yes, the original did that" (e.g. finished
   story stages show Finish and only bosses can be replayed).
2. **After every working change**, in this order:
   `sh tools/dev/check.sh` (smoke + bad input + cheat + real-save + wiki/website checks; non-zero on any problem) `&& git add -A && git commit && git push` →
   `sh tools/sync_test_folder.sh` (copies the push into `C:\Users\dj199\Desktop\Hello Bro Locked Server`, the folder the owner plays on;
   keeps its save, removes files deleted from git) → tell the owner to restart their server (never stop or start it yourself while they
   may be playing; ask first). The PUBLIC cloud server is NOT updated on every push: only when the owner says so (section 5; website-only
   changes: section 6). Then post a short plain-words note of the update in Discord #updates (owner's request, 1 Nov 2026); skip it only
   for something too small to announce (say so).
   Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. GitHub sometimes answers "Internal Server Error": just push again.
3. Repo `Djassie18698/hello-bro-revival` is **PUBLIC on purpose** (owner's decision on 31 Oct 2026: it is shared with several people and this is easier).
   It still holds game files and the signing keystore, so never add anything secret to it: no tokens, passwords, personal data, `discord/.env`.
   `hellobro.db` (the save), `public.db`, `START-PUBLIC-SERVER.bat` and `re/` are never committed. Never read `admin-password.txt`.
4. **Emulator:** only the BlueStacks instance named **"Claude"** (Android 11). Its adb address is in `tools/dev/emu.device`
   (now `127.0.0.1:5615`; or set `HB_EMU`). If it stops working: the owner starts it, run `HD-Adb.exe devices`, ask which entry is "Claude",
   save it there. `emu.sh` refuses to run without it so it never hits the owner's own game instances. Never touch any other BlueStacks
   instance (the owner tests there; a window titled "BlueStacks App Player 5" is theirs) and never use the Multi-Instance Manager.
   The owner allows starting and using the "Claude" instance whenever a check needs it (3 Nov 2026): test in game yourself, don't wait.
   Start it detached (a plain Start-Process dies when the tool command ends): PowerShell `Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = '"C:\Program Files\BlueStacks_nxt\HD-Player.exe" --instance Rvc64_6' }`, then `HD-Adb.exe connect 127.0.0.1:5615`.
5. Keep working through open bugs without asking at every step; ask only for real decisions (e.g. "original vs. free").
   Explain what changed in plain words; say what is not verified in game.
6. Update this file when a rule, path or the open list changes. Append findings to `docs/NEXT-STEPS.md`. Keep `docs/CHECKLIST.md` (who does what) current.
7. **Big changes** (a new feature, a day with many fixes) also update the GitHub front page `README.md` ("What works" table and
   "What changed recently", newest first, one short line per day) and get a plain-words entry in a dated `docs/FIXES-<date>.md`
   (same layout as `docs/FIXES-2026-10-31.md`). Small fixes only need `docs/PROGRESS.md` + `docs/NEXT-STEPS.md`.
   The owner approved the README look on 31 Oct 2026: keep that style. README news also feeds the website and wiki (run `node tools/build_wiki.js`).
8. Balance: the owner keeps it as is (`docs/BALANCE-SIMULATIONS.md`); don't change rates or prices without asking.
9. **Accounts that are the owner's:** never log in to Oracle Cloud, Namecheap, DuckDNS or Discord settings yourself, and never change their
   security settings: give the owner click-by-click steps (with screenshots of what they'll see when you can) and check the result from outside.

## 2. Fixing a bug (the usual job now)
1. **Where reports come from:** the owner in chat; GitHub issues #2-#5 (lists 1-4, closed), **#6 (list 5, open)** and new issues from the
   Bug report template (`gh issue list`); Discord #bugs-and-issues and #support
   (`cd discord && node --env-file=.env dc.js read bugs-and-issues`). Never reply in Discord chat channels, EXCEPT on bug reports in
   #bugs-and-issues (owner, 3 Nov 2026): see step 7. `docs/DISCORD-REPORTS.md` logs every report and its state: read it first.
   **Bug helper + fixer (8 Nov 2026, owner):** `discord/bughelper.js` (inside the cloud bot) opens a thread on every new #bugs-and-issues post,
   asks the player for the missing details with Claude (ANTHROPIC_API_KEY in the cloud `discord/.env` only; claude-opus-5-5, low effort; a fixed
   checklist when the key fails; owner posts and replies are skipped) and posts the finished report in **#bot-logs** (also after 15 minutes without an answer to a question, BUG_IDLE_MIN; "🐞 Bug report" / "💡 Wish",
   ending `report-id: <thread> · post-id: <post>`). The scheduled task **"hellobro-bug-fixer"** on the owner's PC (every 2 h while the Claude app
   is open, `~/.claude/scheduled-tasks/hellobro-bug-fixer/SKILL.md`) picks up reports whose report-id is not in DISCORD-REPORTS.md yet, fixes
   them with this section's steps, answers in the thread (`dc.js post <thread> <file>`), reacts ✅ on the post and keeps one post per report in the staff forum **#bug-fixer** (state tags; a question tags the owner with `--ping-owner`; each run acts on posts where the owner wrote last, also old #dev-chat answers; the pinned post "📦 Waiting to go live" lists what is pushed but not on the public server, and the owner saying "update the public server" there makes the fixer update it);
   the public server is updated only after the owner's OK. The API key ends about **8 Dec 2026** (30 days); then the helper uses the checklist.
   **Claim** (owner, 10 Nov 2026): the owner types `.claim` (or `/claim`, `!claim`) in a report thread and the helper stays quiet there (no answers, no
   forwarding) until `.reclaim` (`.unclaim` / `.release`); it reacts 🤐 / 🤖. The owner's own messages never get a bot answer. Who may claim: OWNER_IDS + CLAIM_IDS (.env).
   **`BUG-FIXER-VIEWER.exe`** (owner's Desktop, built by `tools/fixer-viewer/BUILD.bat`, C# with Windows' own csc.exe; not in git) shows the fixer's runs live from
   their transcripts (working / idle / stuck, next run, a plain-words timeline per run, #bot-logs reports waiting / being fixed / handled, tray pop-ups). Read-only.
   Website/wiki problems are bugs too (section 6).
2. **Add a row** to `docs/PROGRESS.md` (⏳) under its list, and keep the Summary counts matching the rows.
3. **Reproduce:** `node tools/dev/probe.js <endpoint> <Cmd> k=v` against a test save, or in the game on the Claude emulator
   (section 5). `emu.sh log` shows crashes and the server's replies. Real player data: `node tools/dev/realsave.js <copy of save>`.
4. **Find the cause** (section 7: which Lua or C++ code reads the reply). Fix it in the server if at all possible; a game-side
   change goes through a hot update (section 8). Something inside the C++ app that no reply can change is 🚫 "not possible".
5. **Guard it:** add a check to `tools/dev/smoke.js` (normal use), `fuzz.js` (bad input) or `exploit.js` (cheating) so it can't
   come back (website: `wiki-test.js`). Run `sh tools/dev/check.sh`.
6. **Check in the game** when it shows on screen (✅); if only checked on a save, mark 🧪 and say so.
7. Ship it (rule 2), set the PROGRESS row to ✅/🧪, add a line to `docs/NEXT-STEPS.md`, and comment on the GitHub issue it came from
   (write the text to a file in the scratchpad, `gh issue comment N --body-file <file>`; `/tmp` paths failed once).
   If players will notice it, also update `discord/guides/how-to-play.md` or `faq.md` and apply it (section 10), then `node tools/build_wiki.js`
   (the wiki shows the guides).
   A Discord report: react ✅ on it (`dc.js react bugs-and-issues <id>`), reply to it with what is fixed and what not
   (`dc.js reply bugs-and-issues <id> <file>`), add a row to `docs/DISCORD-REPORTS.md` and to PROGRESS "Discord reports".

## 3. First-time setup in a new session (5 minutes)
- Work in `C:\Users\dj199\Desktop\HelloBroServer` (main repo). Git Bash: use short paths, `cd /c/Users/dj199/...`
  (Windows programs fail from very long working directories). Don't put backslashes in Python heredocs; write a script file.
  Long edit scripts: write them to a file with the Write tool (a bash heredoc full of quotes once failed to parse).
- `git status` / `git log --oneline -5` first: the owner (or a friend's UPDATE.bat) never commits here, so local changes are yours.
- `pip install pyelftools capstone` (once), then `python -I tools/setup_re.py`: makes `re/libgame.so`, `re/obb/` (the
  original game files: Lua, ccbi, xml, images) and `re/all.txt` (44 MB disassembly of every C++ function with string and
  symbol hints, ~1 minute). It needs a Hello Bro `.xapk` (Desktop has `HelloBro-Tailscale-100.111.115.0.xapk`, the release has `HelloBro-base-host-your-own.xapk`; otherwise it
  downloads it from the `tailscale-play` release with `gh`). `re/obb` is needed for the wiki icons and website art (section 6).
- Tools on this PC: Node 24 (`node:sqlite`, built-in WebSocket and fetch), Python 3.12 (no PIL), JDK 21 (jarsigner), `gh` (logged in), BlueStacks adb at
  `C:\Program Files\BlueStacks_nxt\HD-Adb.exe`, ffmpeg (WinGet: `%LOCALAPPDATA%\Microsoft\WinGet\Packages\*FFmpeg*\*\bin\ffmpeg.exe`, used for WebP),
  Chrome (headless screenshots, `tools/dev/pageshot.js`), ssh key `~/.ssh/hellobro-oracle.key` for the cloud machine.

## 4. Map of the repo
Layout since 2 Nov 2026 (owner: "only the .bat files on top"): the top folder holds only the .bat files, README.md and CLAUDE.md;
all server code plus `data/`, `cdn/`, `reference/`, `site/`, `wiki/` live in **`server/`** (the .bat files run `node server\server.js` from the top
folder, so the save `hellobro.db` and `backups/` stay on top). START-SERVER.bat deletes the old top-level code copies a friend's
UPDATE.bat left behind. Paths below without a folder are in `server/`.
| Path | What |
|---|---|
| `server.js` | HTTP server on :18080 (rewrites `<root` to `<RENLONG`, %20-encodes raw spaces, flood guard 300 requests / 10 s per visitor (behind Caddy: the last X-Forwarded-For), `/admin`, `/cdn/`, `/wiki/`, `/progress.md`, `/status` = `{ok, version, started, online, players}`) |
| `handlers.js` | one function per client endpoint (`rl_r_*` read, `rl_w_*` write, `rl_x_*` mixed, `xk_*` login/directory) |
| `game.js` | core: cards, team/stats, gear, sets, drops (`grantDrop`), gacha, training, fights (`battleXml`), shop, props; Team 2 = `team_alt`/`equipped_alt` |
| `errcodes.js` | turns code-5 refusals into the codes the game's own tip table knows (else every refusal reads "Your energy level is full") |
| `webapi.js` | the website's **public read-only data** at `/api/*` (Caddy passes it on): `/api/top` top 10 (rl_r_ninja_rank sort, glowing names), `/api/player?name=` player pages, `/api/today` god card of the hour + ramen/energy times + events, `/api/online?days=1\|7` players-online graph (table `web_online`, logged every 5 min by server.js), `/api/calc?s=` the wiki's team calculator (game.teamSlots). GET only, cached 60 s, never uid/account/device/email |
| feature modules | `totalgift` total-recharge gifts · `dailyevents` daily spending + recharge streak · `consumption` gold spending gifts · `exam` Ninja Test · `tupo` Breakthrough · `pet` Pets · `monopoly` Millionaire · `tear` national treasure · `sudoku` Ninja Treasure · `sevenday` 7-day goals · `boss` world boss · `crosswar` cross-server battle · `war` country war · `country` officials · `border` border war · `seals` plunder/seals · `guild` Akatsuki · `vip` · `wheel` Lucky Wheel · `mora` · `slot` · `signin` monthly sign-in · `keeplogin` Sign-in login streak · `rankings` · `stagegift` · `drops` gift-pack drops · `caishen` God of Wealth · `monthcard` Month card · `flower` Flower Worship · `notices` News battle reports + friend messages · `awardcenter` Awards chest mail · `festival` festival trades (Christmas, Anniversary ...) · `godrecruit` God Recruit · `hottreasure` Hot Treasure · `limited` Diligence gift, Limited discount, Lottery · `scratch` scratch card · `box` treasure chests · `groupbuy` group purchase · `growthfund` Growth Fund · `soultrain` Eight Gates soul training · `specialnames` glowing names (a fixed name + colour + effect per login account, glows on Home and in the No.1 Shinobi list, survives a reset; `rl_r_purplename` is ours, for the Home top bar; control panel tab ✨ Glowing name, owner only) · `rotation` weekly event rotation (PLAN: which event runs which day/hours; settings.eventOn / switchedOnAt / capLeft ask it first; Server Manager "Weekly rotation") · `shards` god card fragments from won fights (training, bosses, Spar, Arena; rates in the Server Manager; Shard Rush doubles) · `limitsuper` Limited Super Ninja (hourly god card draw + ranking; its gold draws are premium-recruit requests sent while its screen is open) |
| `site/` | the **home page** https://ninjaonlinereborn.com (served by Caddy only, section 6): `index.html`, `site.css`, `site.js`, `home.json` (made by `tools/build_wiki.js`), `img/` (made by `tools/build_site_art.py`; `img/shot-*.webp` are emulator screenshots) |
| `wiki/` + `wikiserve.js` | the **wiki**: one page (`index.html`, `app.js`, `style.css`) reading `data.json` (made by `tools/build_wiki.js`); icons in `img/*.webp` (made by `tools/build_wiki_icons.py`). Public at https://ninjaonlinereborn.com/wiki/ (Caddy, section 6); every game server also serves it at `:18080/wiki/` (`wikiserve.js`: GET/HEAD only, nothing outside server/wiki) |
| `tracker.js` / `track.html` | **full progress tracker** of chosen accounts (owner, 10 Nov 2026: DEAN uid 7, reset and played like a normal player, max $100 free top-ups a day, for balance feedback): server.js `begin()`/`end()` snapshot every uid-table row of the account around each game request and log the differences (gold/silver/energy/exp by source, cards/items gained and from where, level, VIP, top-ups, stages reached, other changes) to `track_log`; `game.battleXml` / `grantDrop` add fights (won/lost) and drop packs; power (team attack/defence + why) after each change; requests per minute in `track_time` (time played). Changes between requests = "outside the game" / "item page" / "Award Center mail arrived" / "New character"; another player's request that changes the account (spar, plunder, ladder) = "Other player <nick>: <what>" (watched when total_changes() moves). Hooks: `game.addExp` (exp really gained: the save keeps only the exp inside the level), `game.energyTick` / level-up (energy that came by itself: own sources "Energy: refills over time / 22:00 refill / level-up refill"), `battleXml` (my attack vs their defence). Summary: what every fight gave (per kind: silver/exp/gold/energy per fight, items, cards), levelling (time per level, exp still needed), arena rank. **Every player** (not only tracked ones): `drop_stats` = per day x source the fights, gold/silver/exp/energy and every item/card/drop pack (light snapshot: players row, props, newest card/pet; setting `drop_stats=false` stops it); tab Tracker > Drops in the whole game, `track.js drops [day]`. Who: setting `track_uids` (Tracker tab) else `HB_TRACK_UIDS` (run.sh: 7). Reset keeps track_* and logs a reset. Panel tab 🔎 Tracker = `/admin/track` (owner only). Day summary for you: `node tools/dev/track.js yesterday\|today\|YYYY-MM-DD\|all [--events] [--db public.db]` (on the cloud: `ssh ... "cd /opt/hellobro && sudo -u hellobro node tools/dev/track.js yesterday --db public.db"`). Don't change rates from it yourself (rule 8): report, the owner decides |
| `playerlog.js` / `playerlog.html` | progress log per player (level-ups, team attack changes of 2 %+, new stages / chapters, VIP, login days); control panel tab "Player log" = /admin/playerlog |
| `gumplogin.js` | the APK's account window (Play / Login / Signup, *.do paths) on our server; `LOGIN_LOCK=1` = only its sessions count |
| `admin.js` / `admin.html` | admin page (players keyed "uid:server_id", server 1 = main, 2-4 = starter slots from the login region list): give gold/items/cards, set level/VIP, inventory edits, **team editor** (`/admin/api/team`, `setteam`: whole team + 8 gear slots in one transaction, Team 2 too; **Best team** `bestteam` = the line-up with the highest attack / defence, own or all cards, copies allowed, runs in `bestteam-worker.js` so the game keeps answering), **Award Center mail** (`sendmail`), **purple name** (`purplename`, owner only, specialnames.js), **reset a player** (keeps the login and the purple name) |
| `panel.html` | the control panel at `/`, `/admin`, `/manager`: tabs Server / Players & items (with an Award Center sub-tab) / Team builder / Player log / Tracker / Progress; it embeds `/manager?embed=1` and `/admin?embed=1` (iframes, postMessage {tab}/{goto}) |
| `manager.js`/`manager.html`/`settings.js` | Server Manager `/manager`: status, online players, live log, events on/off (`server_settings.events_off`, used by `game.actXml`), announcement (`rl_r_bulletin`), backup, restart (exit code 3, `START-SERVER.bat` loops; `HB_MANAGED=1`) |
| `watchdog.js` | forked by server.js when `HB_WATCHDOG=1` (cloud): checks /status every minute, stops a frozen server after 3 failures |
| `db.js` | opens the save: SQLite WAL, health check, backups on start + every 6 h (VACUUM INTO), extra indexes |
| `schema.js` | base tables (modules create their own with `CREATE TABLE IF NOT EXISTS`) |
| `server/data/*.json` | original game tables `{types, rows}` (ninjainfo, equipmentinfo, roundinfo, dropinfo, consumeinfo, petinfo, ...) |
| `server/reference/lua-scripts/` | the client's Lua UI (same as `re/obb/script`); `server/reference/client-endpoints.txt` every endpoint the app calls |
| `server/cdn/` | hot-update files the server pushes to every phone (section 8) |
| `.bat` files | `START-SERVER.bat` (runs the server, restarts it on exit code 3) · `HOST-MY-SERVER.bat` (one-time setup + game file for any address) · `UPDATE.bat` (pulls the newest version, keeps the save) · `OPEN-FIREWALL.bat` (opens port 18080, run as admin) · `INSTALL-WITH-USB.bat` (installs a game file on a phone over adb: USB debugging, `--bypass-low-target-sdk-block` for old files on Android 14+, obb push checked by size; `HB_ADB` / `ANDROID_SERIAL` to pick adb and device) |
| `tools/dev/` | `check.sh` all checks · `smoke.js` every handler on a temp DB · `fuzz.js` bad input · `exploit.js` cheat check · `realsave.js` every screen for every player of a real save (read-only copy) · `watchdog-test.js` · `socket-test.js` (cut connections, /status counts, flood guard behind Caddy) · `wiki-test.js` (wiki + home page data, pictures, links, file-server refusals) · `probe.js` call one endpoint · `track.js` a tracked account's day (tracker.js) · `dev.js` set level / VIP / items on the test account, `relog` · `emu.sh` emulator (restart, tap, shot, log, update) · `boot.sh` / `go.sh` / `survey.sh` quick emulator walks · `restart.sh` dev server on :18081 · `site-preview.js` the website as Caddy serves it, on :18090 · `pageshot.js` full-size page screenshots (headless Chrome) · `upgrades.js` card upgrade walk-through · `sim_balance.js` balance simulations |
| `tools/` | `table_columns.py` -> `docs/TABLE-COLUMNS.md` (every table's column names from the game code: read it before guessing a column) · `build_wiki.js` (wiki `data.json` + website `home.json`; `--check`) · `build_wiki_icons.py` (wiki icon sheets) · `build_site_art.py` (website pictures) · `make_login_logo.js` + `make_name_sparkle.js` (game pictures we draw: the login logo, the name sparkle; both render with `chrome_png.js`) · `ocr_photos.ps1` (Windows OCR of the Facebook photos -> `G:\HELLO BRO\Pictures\ocr.tsv`, grep it to find screens) · `setup_re.py` (+ `setup_from_xapk.py` for a fresh public install) · `armdis.py` disassembler · `build_cdn.py` hot update zip · `add_numb_zero.py` (gold 0/1 in the "+N" font) · `patch_apk.py` / `make_game_for.py` game file for an address · `patch_login_smali.py` + `patch_dex.py` account window / billing crash patches (→ `release/classes-revival.dex`) · `patch_tables.py` + `mbs.py` + `export_tables.py` the client's tables.bin · `ccbi.py` .ccbi layouts · `pvrccz.py` sprite sheets (read only: re-encoding breaks them) · `patch_winview.py` / `patch_winanim.py` victory screen patches · `sync_test_folder.sh` · `fixer-viewer/` (BUG-FIXER-VIEWER.exe, section 2) · `movechar.js` move a character between worlds · `make_public.py` (public copy, archived) |
| `tools/vps/` | the cloud machine: `install.sh` (fresh machine) · `run.sh` (how the game server runs there) · `update.sh [check]` · `bot.sh [stop]` (Discord bot service) · `wiki-site.sh [stop]` (Caddy: the website) · `password.sh` · `snapshot.sh` · `backup-to-pc.ps1` · `UPDATE-CLOUD-SERVER.bat` (the owner's double-click update) |
| `release/` | `revival.keystore` (password/alias `revival`; ALWAYS sign with it, never make a new one), `classes-revival.dex`; built `HelloBro-for-*.apk` stay local (git-ignored) |
| `discord/` | `dc.js` read/post as the bot (token in `discord/.env`, git-ignored) · `guides.js` + `guides/*.md` the guide channels · `layout.js` channel layout · `online.js` + `statuswatch.js` (cloud service `hellobro-bot`, tools/vps/bot.sh; `START-BOT-ONLINE.bat` = on the PC instead) keeps the bot shown online and posts #server-status · `bot.js`/`cli.js`/`agent.js`/`tools.js`/`adapter.js` an AI manager bot (needs a paid API key, not in use) · `test.js`, `test-dc.js` offline tests |
| docs | `README.md` GitHub front page · `docs/PROGRESS.md` every bug and request with its state · `docs/CHECKLIST.md` who does what next · `docs/NEXT-STEPS.md` findings log · `docs/FIXES-<date>.md` plain-words fix days · `docs/BASE-FEATURES.md` Base rules + (ours) values · `docs/FINDINGS-PHOTOS.md` original numbers read from ~3 580 Facebook photos (source folder `G:\HELLO BRO\Pictures`, keep both copies in sync) · `docs/DISCORD-REPORTS.md` · `docs/HOT-UPDATE.md` · `docs/CLOUD-SERVER.md` (cloud machine guide incl. Oracle ports) · `docs/BALANCE-SIMULATIONS.md` · `docs/GEAR-REPORT.md` · `docs/history/` old plans and notes (outdated, for reference) · `docs/HOST-YOUR-OWN-SERVER.md` · `docs/PLAY-ON-TAILSCALE.md` |

## 5. Running and testing
- **Three game servers:**
  - the **public server `ninjaonline`** (strangers play here) runs **in the cloud** since 3 Nov 2026, so it is on when the owner's PC is off:
    Oracle Cloud Always Free, VM.Standard.E2.1.Micro (1 GB, Ubuntu 24.04, region Netherlands Northwest / Amsterdam), public IP `134.98.153.241`,
    address `ninjaonline.duckdns.org:18080` (DuckDNS points at that IP; the owner changes it on duckdns.org).
    Reach it: `ssh -i ~/.ssh/hellobro-oracle.key ubuntu@ninjaonline.duckdns.org`.
    Code in `/opt/hellobro` (a git clone, owned by user `hellobro`: run git as `sudo -u hellobro git ...`), save `public.db`, systemd service
    `hellobro` (`tools/vps/run.sh` = LOGIN_LOCK, STRICT_SESSIONS, DB=public.db, HB_BACKUPS=backups-public, ADMIN_PASSWORD from
    `admin-password.txt`). Restart=always, back by itself after a reboot. Logs `sudo journalctl -u hellobro`. Control panel
    `http://ninjaonline.duckdns.org:18080/` (the owner's admin password). The owner plays there as **DEAN** (uid 7), friend **Riskeric** = uid 12; both have gold glowing names with sparkles (specialnames.js, colour ffd21f, effect sparkle). `HB_ONE_WORLD=1` (owner, 6 Nov 2026): only Konoha (main) in the server list, every request plays on world 1 (starter slots stay on the PC servers; `tools/movechar.js` moves a character between worlds). `ADMIN_OPEN=1` (owner, 3 Nov 2026, "for now"): players use the item
    page `/admin` without the password; the panel, /manager and wiping a player still need it. Owner's later wish: each player only their own account (5 Nov 2026: NOT now, "I want people to have fun for now"). Guide + restore steps: `docs/CLOUD-SERVER.md`.
    **Updating (owner, 3 Nov 2026): NOT on every push. Only when the owner asks ("update the public server"), or now and then when a
    batch of player-visible fixes is waiting: then propose it and wait for a yes.** Show what is waiting first:
    `ssh ... sudo sh /opt/hellobro/tools/vps/update.sh check`; update: `ssh ... sudo sh /opt/hellobro/tools/vps/update.sh`. It restarts the
    game server (away ~3 s; players stay logged in: sessions are in the save, they only see a network error if they tap during it) only when files under
    `server/` changed, not counting `server/site` and `server/wiki` (plain website files). The owner can also double-click
    `tools\vps\UPDATE-CLOUD-SERVER.bat` (shows what's new, asks Y/N). Game-side hot updates (`server/cdn`) reach ninjaonline players only after
    such an update. Never `git pull` there without the restart when server code changed (a crash restart would then load half-updated code).
    Other scripts: `tools/vps/install.sh` (fresh machine, safe to rerun), `password.sh` (admin password), `snapshot.sh` (consistent copy).
    Backups: every 6 h in `/opt/hellobro/backups-public`, plus a daily copy on the owner's PC by the scheduled task "Hello Bro cloud backup"
    (`tools/vps/backup-to-pc.ps1` -> `Documents/HelloBro-cloud-backups`, 30 kept, `backup.log`). Free-tier risk: Oracle may reclaim an
    idle Always Free machine; the owner was advised to upgrade to Pay As You Go (stays free) with a budget alert (not done yet).
    Oracle firewall (security list, owner's console): ingress TCP 18080 (game), 80 + 443 (website, 8 Nov 2026); the VM's own iptables
    opens the same ports (install.sh / wiki-site.sh). Memory is tight (1 GB, no swap): node ~300 MB, bot, Caddy ~30 MB.
    **Watchdog** (3 Nov 2026, after a 10-min freeze): run.sh sets HB_WATCHDOG=1, server.js forks `server/watchdog.js`, which checks
    127.0.0.1/status every minute and stops the server after 3 failed checks; systemd (Restart=always) starts it again.
    Discord **#server-status** (owner, 3 Nov 2026): `discord/statuswatch.js` runs inside `online.js` and checks `/status` every minute:
    posts offline (2 failed checks), back online, updated (new version) or restarted.
    It also runs the #bugs-and-issues helper (`bughelper.js`, section 2; state in `discord/bughelper-state.json`; `BUG_HELPER=0` in .env turns it off;
    `bot.sh` installs its only package, the Claude SDK). **The bot runs on the cloud machine since 7 Nov 2026** (owner: "so I can't close it by accident"): systemd service `hellobro-bot`
    (`tools/vps/bot.sh` installs / restarts it, `bot.sh stop` switches it off; `sudo journalctl -u hellobro-bot`), token in
    `/opt/hellobro/discord/.env` (copied from the PC with scp, mode 600, git-ignored), STATUS_URL=127.0.0.1:18080. It can't report the whole
    cloud machine being down (it is on it). The PC's START-BOT-ONLINE.bat asks before starting a second copy (double posts).
    Pinned in #server-status: how to connect + the item page.
    The website (Caddy) runs on this machine too: section 6.
    The old PC public server (`START-PUBLIC-SERVER.bat`, its pre-move public.db, backups-public, admin-password.txt) was moved out of the
    play folder on 3 Nov 2026 to `Documents\HelloBro-old-files` (with 3 old .apk builds): it must NOT run any more.
    The play folder holds exactly the GitHub files plus the owner's save (hellobro.db + backups/) and two .xapk files.
  - the **play server** the owner uses: `C:\Users\dj199\Desktop\Hello Bro Locked Server` (its own `hellobro.db`, port 18080).
    Only the owner starts and stops it (rule 2). Restart (only when asked, PowerShell): stop the process listening on 18080 and its
    parent cmd, then `explorer.exe "<that folder>\START-SERVER.bat"` (Start-Process from the tool gets its node killed when the command ends: 6 Nov 2026).
  - the **dev server** in the main repo: `bash tools/dev/restart.sh` (port **18081**, so the owner can play on 18080 at the same time;
    logs `%TEMP%\hb\server.log`; run it in the background: it keeps the tool call open). The Claude emulator runs `release/HelloBro-for-127.0.0.1-18081.apk` and reaches it through
    `adb reverse` (`emu.sh restart` sets it up). Test login: `tools/dev/emu.account` (git-ignored), account 55501235 (Ninja68490, level 101, VIP 18;
    8 Nov 2026 it got a full god-card team via `/admin/api/bestteam` mode all + `setteam`, for screenshots).
    `node tools/dev/dev.js` sets level / VIP / gold / items / SQL on the test account and `relog` restarts the game. The main repo's
    `hellobro.db` holds the owner's main account `22079117` (Ninja78277, level 80, VIP 18) and a friend `22078671`.
- Tests without the game: `sh tools/dev/check.sh` runs them all; or `probe.js`, or a small node script with
  `new DatabaseSync(':memory:')` + `require('./schema')(db)` + `handlers.rl_w_login2/rl_w_reg2`.
- In the game: `sh tools/dev/emu.sh restart` → wait ~20 s → `emu.sh update` if "confirm update?" shows → `emu.sh tap 540 1270`
  (START) → `emu.sh shot` and view `re/s.png`. Screen is portrait 1080x1920. Bottom bar y=1860: Home 85, Team 270, Backpack 447,
  Training 630, Spar 805, Shop 980. Base building 530,1215. Training: chapter tiles, then a stage's GO button. `emu.sh log` shows crashes/Lua errors/missing nodes/server replies.
  BlueStacks sometimes opens an ad page that eats taps: `emu.sh back`, then relaunch. A dialog left open (e.g. Save time) also
  eats taps: close it first. Don't relaunch the game for every check; walk between screens when you can.

## 6. The website: https://ninjaonlinereborn.com (owner, 8 Nov 2026)
**What it is.** A home page (the owner loved https://platinumtogether.online: big game scene, chunky logo, big Play button) at `/`, and the
wiki at `/wiki/`. Everything on it comes from the game itself: art cut from the game files, numbers and names from its tables.
- **Look (8 Nov 2026 evening, owner: "the page feels too AI"):** the page wears the game's own interface: buttons are the game's green / blue / red buttons (`.btn.green/.blue/.red`, 9-slice `border-image` of `img/ui/btn-*.webp`), How to play is the game's dialog window (`.dialog`), the header turns into the wooden bar on scroll, features are a list with the element icons next to the 7 posters pinned up. Kept out on purpose (template habits): labels above headings, stat boxes, pill badges, fade-ins on scroll, glows/halos, self-scrolling rows. `impeccable detect` still reports the dialog text as low contrast (it cannot see the parchment picture) and the god cards' rays: both fine.
- **Home page** `server/site/`: hero (the game's blue moon with crows, falling petals on a canvas, five god cards bobbing: Itachi, Kakashi,
  Kyuubi Naruto, Sasuke, Sakura; logo = the owner's NINJA ONLINE picture `img/logo-ninjaonline.webp` (8 Nov; source with black background: owner's Pictures/Ninja Online Logo.png, made see-through + 1100 px WebP) with the text REBORN under it; Play + Join Discord; live line
  "Server online · N ninjas playing now · M ninjas so far" from `/status`), "The game" (Hello Bro logo, counts), Features (6 tiles + the 7
  original event posters), Shinobi (14 god cards → wiki pages), Screenshots (5 emulator shots), Story (19 chapter banners in two rows you scroll by hand, → wiki
  training pages), How to play (download `HelloBro-ninjaonline.xapk` from the release, install guide, Discord), News (README's newest 4), footer.
  Fonts: Lilita One + Nunito (Google Fonts). Theme: night blue + fire orange + parchment bands. Respects reduced motion. Works at phone size.
  Design notes: the logo outline is the span's own text-stroke, the coloured letters are its `::after` (background-clip:text on the span itself
  would hide them); the header's class is `.top` (never reuse that class name: a picture once jumped to the top); no drawn stars in the sky
  (one looked like a speck of dust above a link, owner 8 Nov); old wiki links `/#/shinobi/...` jump to `/wiki/#/...` (script in `<head>`).
- **Wiki** `server/wiki/`: built from the game tables; shows a "Home" link only on the website (no port in the address).
- **Hosting:** Caddy 2.6 (Ubuntu package) on the Oracle machine, ports 80 + 443, config `/etc/caddy/Caddyfile` written by
  `tools/vps/wiki-site.sh` (edit the SCRIPT, never the Caddyfile). Short links (8 Nov): `/discord`, `/download` (the release xapk), `/install` (wiki install guide), `/play` (#play), `/patreon`. **Control panel on the domain (10 Nov 2026, owner: "I don't like the duckdns"):** `/panel`, `/manager*`, `/admin*`, `/progress.md` → `reverse_proxy 127.0.0.1:18080` (https; the game server still asks for the admin password, ADMIN_OPEN keeps /admin open; footer "Item page" + "Control panel"); run.sh sets `HB_SITE_URL=https://ninjaonlinereborn.com`, so a browser opening /, /panel, /admin, /admin/playerlog or /manager straight on `:18080` is sent there (requests from Caddy itself are not; socket-test.js checks it). The game app keeps using ninjaonline.duckdns.org:18080;
  `/api/*` → `reverse_proxy 127.0.0.1:18080` (server/webapi.js), `/p/<name>` → `server/site/p.html` (player pages). Routes: `/` → `server/site`, `/wiki/` → `server/wiki` (`/wiki` → 308),
  `/status` → `reverse_proxy 127.0.0.1:18080` (the only thing that reaches the game server), `/wiki/img/icons.json` 404, dotfiles hidden.
  Pictures cached a day, pages/scripts `no-cache`. `www.ninjaonlinereborn.com` and plain `ninjaonline.duckdns.org` (no port) redirect to the home
  page, `wiki.ninjaonline.duckdns.org` to `/wiki/` (DuckDNS answers every name under ninjaonline.duckdns.org, nothing to set there).
  Caddy serves the files straight from the git checkout `/opt/hellobro`, so **a website change goes live with `update.sh`, without restarting the
  game** (update.sh skips the restart when only `server/site` / `server/wiki` changed). A change to wiki-site.sh itself: push + update.sh, then
  `ssh ... "sudo sh /opt/hellobro/tools/vps/wiki-site.sh"` (or before pushing: `ssh ... "sudo sh -s" < tools/vps/wiki-site.sh`).
  `sudo systemctl status caddy`, log `sudo journalctl -u caddy` ("no OCSP stapling" lines are harmless: Let's Encrypt dropped OCSP).
- **Certificates:** Let's Encrypt, obtained and renewed by Caddy by itself (needs ports 80/443 open and the DNS right). Valid ~90 days, renewed at ~60.
- **Domain:** `ninjaonlinereborn.com`, bought by the owner at **Namecheap** on 8 Nov 2026 (first year €5.98, then about €14 a year, auto-renew
  ON, Domain Privacy ON; next renewal ~8 Nov 2027). DNS: Namecheap BasicDNS, **Advanced DNS** = two A records, Host `@` and Host `www`, both
  `134.98.153.241`. **If the Oracle IP ever changes**: the owner updates both A records (Domain List > Manage > Advanced DNS) AND DuckDNS.
  Check DNS: `nslookup ninjaonlinereborn.com 8.8.8.8`; registry state: `curl https://rdap.verisign.com/com/v1/domain/ninjaonlinereborn.com`.
- **Oracle ports 80/443:** added by the owner 8 Nov 2026 (docs/CLOUD-SERVER.md step 3b). In the new Oracle console: instance > **Networking** tab >
  Subnet link > **Security** tab > Default Security List > **Security rules** > Add Ingress Rules: Source CIDR `0.0.0.0/0`, TCP, Destination Port.
  **Source Port Range must stay EMPTY** (the owner first typed 80 there and the ports stayed closed). Test from outside: `curl -I http://ninjaonline.duckdns.org/`.
- **Changing the website** (what to edit → what to run):
  | Change | Edit | Then |
  |---|---|---|
  | home page text, sections, links, buttons | `server/site/index.html` (+ `site.css` for looks) | check.sh |
  | home page behaviour (status line, petals, card rows) | `server/site/site.js` | check.sh |
  | the five hero cards / the 14 shinobi cards | `HERO` / `FEATURED` card ids (ours) in `tools/build_wiki.js` | `node tools/build_wiki.js` then `python -I tools/build_site_art.py` |
  | backgrounds, posters, chapter banners, Hello Bro logo, the game's interface pieces (img/ui: buttons, dialog window, wooden bar, element icons) | `FIXED` list in `tools/build_site_art.py` | `python -I tools/build_site_art.py` |
  | news (home page + wiki) | README "What changed recently" | `node tools/build_wiki.js` |
  | wiki content (cards, sources, chains, stages, guides) | `server/data`, the event modules, `discord/guides/*.md`, `tools/build_wiki.js` | `node tools/build_wiki.js` |
  | wiki icons | `tools/build_wiki_icons.py` | `python -I tools/build_wiki_icons.py` then `node tools/build_wiki.js` |
  | the live line's numbers | `server.js` `/status` (`online` = characters that played in the last 5 min, `players` = characters; 30 s cache) | game server restart |
  | screenshots | take them on the Claude emulator (`emu.sh shot` → `re/s.png`, copy each), then `ffmpeg -i shot.png -vf scale=540:-2:flags=lanczos -c:v libwebp -quality 80 server/site/img/shot-<name>.webp` | |
  Every big card picture is `re/obb/npc/<ninjainfo[3]>.pvr.ccz` (394 px, all 493 wiki cards have one). Posters `advertise1-7` = super ninja, dice,
  big wheel, time limit, flowers, 5-star cards, treasures. Chapter banners `level_chapter_<n>` on `level_page1-4` (6 per page).
  `build_wiki.js --check` (in check.sh) fails when `data.json` or `home.json` is out of date: rebuild after editing tables, guides or README news.
- **Design notes (Impeccable, 8 Nov 2026):** `server/PRODUCT.md` = who the site is for, its main goal (download and play), voice (plain words, never AI-template copy), constraints and what must never be invented. Impeccable design commands (`/impeccable ...`) read it; `server/.impeccable/` holds their config. Not served by Caddy; `update.sh` skips the game restart for `server/*.md` and `server/.impeccable`.
- **Live parts (8 Nov 2026 late, owner's 8-idea project via the main session):** home page section `#live` = Strongest players (top 10, glowing names glow and
  sparkle like in the game), Today in the game (god card of the hour, free ramen 12-14 / 18-20, energy 22:00, events running; server clock + the visitor's own time),
  Players online graph (24 h / 7 days); player pages `/p/<name>` ("Where the power comes from": webapi.js breakdown(), parts add up exactly; VIP badge pictures `img/ui/vip-0..18.webp`, team cards with the wiki's icons via `home.json` `icons`);
  wiki `#/calculator` (team calculator, state in the address). All in `live.js` + `server/webapi.js`; checks in `tools/dev/wiki-test.js`. `robots.txt` + `sitemap.xml` in
  server/site. Same-named characters: `/p/<name>?n=2` (place among that name, highest level first). Live since 8 Nov 2026.
  E-mail: contact@ninjaonlinereborn.com forwards to the owner's Gmail (Namecheap Email Forwarding: MX eforward1-5.registrar-servers.com + SPF TXT).
  Google Search Console: domain property verified by the owner 8 Nov 2026 (TXT `google-site-verification=...` at Host @: never delete it); sitemap.xml submitted there by the owner.
- **Search engines (9 Nov 2026, owner: "do everything, also with the cards, just no naruto in the name"):** every wiki entry has its own page
  `server/wiki/<shinobi|gear|ninjutsu|seals|pets|items|training|guide>/<id>.html` (771, made by `tools/wiki_pages.js` from `build_wiki.js`; the wiki's index.html + own
  title/description/canonical + the facts in <main>; app.js opens the entry from that address). **Titles and descriptions never contain Naruto/Konoha** (wiki_pages.js plain();
  app.js filters document.title the same way; "Konohagakure" = "Leaf Village", Konohamaru = "Shinobi card 121"); page text keeps the game's names. `sitemap.xml` is generated
  by build_wiki.js (773 addresses) and checked by --check. Home page: Questions part (#faq) + FAQPage JSON-LD, title "Hello Bro / Ninja Online revived ...", share picture
  `img/og.jpg` 1200x630 (source `tools/og/og.html`). GitHub repo website = ninjaonlinereborn.com, README links the site. The owner set up Google Search Console + Bing
  Webmaster (sitemap submitted, indexing requested).
- **Look before shipping:** `bash tools/dev/restart.sh` (dev server, for /status) + `node tools/dev/site-preview.js` → http://127.0.0.1:18090/ and /wiki/.
  The app's browser pane is small and blurry: judge the design with `node tools/dev/pageshot.js http://127.0.0.1:18090/ re/home.png 1440 900 1 1`
  (and `390 844` for a phone; last two args: full page, reduced motion), then view the PNG. It also reports page errors and sideways overflow.
- **Ship:** rule 2, then (website-only change the owner asked for) `ssh ... sudo sh /opt/hellobro/tools/vps/update.sh` (no game restart) and
  check from outside: `curl -s -o /dev/null -w "%{http_code}" https://ninjaonlinereborn.com/<file>`. Post visible changes in #updates.
- **Copyright** (owner asked 8 Nov 2026): low risk for a free, non-commercial fan project of a dead game (worst case usually a takedown request);
  the public repo's game files matter more than the site. Keep "Naruto"/"Konoha" out of names and titles, no money. A "fan project, not
  affiliated, contact us to remove" footer notice was offered: owner said **not now**. The footer says "A free fan revival of Hello Bro / Ninja Online (2015), made by its players."

## 7. Protocol and debugging (how every crash so far was fixed)
- Client POSTs `/<endpoint>` with `Uid, Session, ServerID, GroupID, Cmd, ...`; reply XML `<root code="0">...</root>`.
  Non-zero code = error tip (`code="5"` with `<message>`, mapped by `errcodes.js`). Accounts auto-create; sessions only checked with `STRICT_SESSIONS=1`.
- Find the parser: **Lua screen** → grep `server/reference/lua-scripts` for the endpoint, read every `:find("tag")` (Lua `find` searches
  recursively). **C++ screen** → `grep -n "'/rl_x_name'" re/all.txt`, find the `onHttpRequestCompleted` of that class
  (`awk 'NR<=L && /^=====/'` to get the function), list `-> 'tag'` strings and `FirstChildElement`/`Attribute` calls.
- Crash signs in `emu.sh log`: `Fatal signal 11 ... fault addr 0x18/0x0` = C++ read a missing element; `LUA ERROR` = Lua read nil.
  `this is no node:X` at the END of a list is harmless (tinyxml looking for the next sibling); elsewhere it means element X is missing.
  **Return every field the parser reads.** Attribute vs child element matters per endpoint. Empty lists can crash too (shop needs ≥1 entry).
- Error tips: C++ screens (ShowErrorTip) read the code's text from Struct_String_Menu; some Lua screens read `text.lua`
  `text_config[code]` instead (a missing code there is a Lua error); some screens only show their own codes (e.g. total-recharge
  314000/314002/314004, gold spending 580001/580002).
- Known traps: award needs `dropid` ≠ 0 (else the card list is skipped); list rows often must be attributes; `<master_pet>` in
  fights needs both `<id>` and `<pet_id>` (only send it with a real pet); `CFightResultData::InitFromXML` reads
  `<userinfo>`/`<fight>`/`<award>` as **root** children; a feature's conf item with a missing icon (stage gift id 31,
  `activity_icon_11.png`) blanks the whole home event column; the client reads item counts only from `rl_r_shoplist` Cmd 1601
  and the VIP level only at login (top-up reply carries `<viplevel>`); training sends one `<stage pos>` per part and draws every
  earlier row as "Finish" (C++ CSectionCellView); every `/rl_...` the C++ calls has a handler.
- Enable param logging for one endpoint by adding `if (process.env.HB_DEBUG) console.log(...)` and starting with `HB_DEBUG=1`.

## 8. Game-side changes (hot update)
The game downloads `server/cdn/<val>_update.zip` (via `rl_r_version` `<updatechip>`) and unpacks it over its files. To change a game
file: copy it from `re/obb/<path>` (or `server/reference/lua-scripts`) to `server/cdn/src/<same path>` (Lua goes in `server/cdn/src/script/...`),
edit, `python -I tools/build_cdn.py 28.0.N` with a **higher** N, `git rm` the previous zip, note it in `docs/HOT-UPDATE.md`.
Players tap Confirm once. `mainActivity.lua` is run straight from the OBB by C++: patching it does nothing. Text and numbers in the
client's tables go through `tools/patch_tables.py` (tables.bin), layouts through `tools/ccbi.py`; sprite sheets can't be re-encoded.
Current: **28.0.47** (glowing names in the colour and effect picked in the control panel (effect "sparkle" = diamond twinkles, ccbResources/name_sparkle.png from tools/make_name_sparkle.js), on Home and in the No.1 Shinobi list: util/common.lua PurpleGlow / PurpleTopBar, hooked from ui_mainActivityBtn.lua; 28.0.43 = login logo "NINJA ONLINE / REBORN", made by tools/make_login_logo.js; 28.0.41 = the "+N" font characters/NumB.fnt got a gold 0 and a gold 1, so Breakthrough +10 shows everywhere; tools/add_numb_zero.py makes it; 28.0.37 = boss retry price 10 gold for every boss, 28.0.36 = Chinese button texts in English, 28.0.35 = tutorial off for everyone). The full list is in `docs/HOT-UPDATE.md`.

## 9. Data model cheat sheet
- `cards.type`: 1 ninja (ninja_id = ninjainfo id) · 2 weapon · 3 armor · 4 trinket (ninja_id = equipmentinfo id) · 5 seal
  (markinfo) · 6 ninjutsu (ninjutsuinfo). Extra columns: level, exp, starlevel (sage growth), newlife, pot_*, breaklvl, attri.
- `team(slot 0-based, seq)`; slots open by `newcardinfo` rows (`game.maxTeam`). `equipped(slot 1-based, kind)`: kind 1 weapon,
  2 armor, 3 trinket, 4 seal, 5-8 ninjutsu. Team 2: `team_alt` / `equipped_alt` (from level 100). Equipped cards count as in use.
- `props(prop_id,count)`: consumeinfo ids, plus 9999 souls, 9998 gate souls, 9997 gate level, 9996 arena reputation,
  9995 boss reputation, 9994 war merit, 20000+id seal fragments, 30000+piece_info id card/pet fragments (`game.CHIP_BASE`).
- `progress(chap, stage)`: chap 1-19 training chapters (stage = next open stage), 1000+ tower, 100000+day sweeps.
  `stage_clears` counts clears per stage (roundinfo [42] clears needed, [38] boss, [43] boss tries/day). Bosses: 3 free tries a day
  each (`BOSS_FREE`), then 10 gold (`BOSS_COST`); 165 boss stages of 1234.
- dropinfo row: [3] ninja, [4] equipment, [5] ninjutsu, [6] seal, [7] prop, [8] fragment, [9] souls, [10] gold, [11] silver,
  [12]=1 random pack (contents read from its text), [13] amount, [14] pet. `game.grantDrop(db, pl, dropId)` handles all and returns the `<award>` XML.
- roundinfo: [4] chapter, [2] stage in chapter, [22] energy cost, [23] exp, [24] silver.
- ninjainfo: [1] name, [3] picture name (`icon/icon_<it>`, big art `npc/<it>`), [11] 6 = god card, [19] > 0 = a real card (the wiki lists those).
- Breakthrough (`tupo.js`, like the original photos): god cards only, max +10; level n+1 costs 10 + 5n fragments and 60 000 (or 250 000 for god
  cards with base attack 690+) × (n+1) silver; +1 % ninjutsu trigger and +2 % restrain a level (shown on screen; fights don't read them).
  Only 18 of the 83 god cards have a fragment pack in dropinfo (the Ninja Test shop offers the oldest of yours that has one).
- New player (original): chosen ninja (Neji 55 / Shikamaru 57 / Sakura 56) + its ninjutsu, 50 gold, 18 000 silver, VIP 0.
  VIP exp = $ topped up × 10, thresholds in `vip.js` (ours). Accounts made before 30 Oct 2026 kept VIP 18. Max VIP 23 since 7 Nov 2026 (the game's vipinfo + VIP shop go to 23); the app has badge pictures only for 0-18 and crashes drawing 19+, so every reply tells the game at most 18 (`vip.shown`, SHOW_MAX).
- Daily things reset at local midnight; energy refills at 22:00; free ramen 12-14 and 18-20.

## 10. Releases, sharing and Discord
- Release `tailscale-play` on the repo: `HelloBro-base-host-your-own.xapk` (base game + OBB; HOST-MY-SERVER.bat patches it for any address),
  `HelloBro-ninjaonline.xapk` (the owner's public server ninjaonline.duckdns.org:18080; the website's Download button links it) and
  `INSTALL-WITH-USB.bat`. A new game file is needed only when the app itself changes (login, dex); everything else goes through the hot update.
- Game files made since 2 Nov 2026 target Android 7 (`tools/patch_targetsdk.py`, run by `patch_apk.py`): Android 14+ refuses the original's target 19.
  Without granted permissions the account window sends `deviceId=""`; `gumplogin.js` then keys the guest by its kept password.
- `HOST-MY-SERVER.bat` + `tools/make_game_for.py <address>` build a game file for any server address (friends who host their own;
  guide in `docs/HOST-YOUR-OWN-SERVER.md`). The owner's public server (LOGIN_LOCK, public.db; owner-only: GitHub only offers
  solo/private hosting + joining ninjaonline) runs in the cloud since 3 Nov 2026: everything about it is in section 5 ("Three game servers").
  Phones install a game file from a PC with USB debugging + `INSTALL-WITH-USB.bat` (also a release asset; the guides lead with it).
- Public code-only repo `Djassie18698/hello-bro-revival-public` is ARCHIVED by the owner (2 Nov 2026, read-only): don't rebuild or push it.
- **Discord invite (never expires): https://discord.gg/2Cbp4UDHrU**: use this link everywhere (README badge, issue template, repo homepage, website).
- Discord: `cd discord && node --env-file=.env dc.js channels|read <ch>|post <ch> <file.md>` (≤2000 chars per message,
  write the text to a file first). The bot is online day and night as the cloud service `hellobro-bot` (section 5); `START-BOT-ONLINE.bat` / `BOT-AUTOSTART.bat` on the PC are only for running it there instead (stop the cloud one first: `bot.sh stop`).
  Layout (owner, 1 Nov 2026; `discord/layout.js` keeps it, dry run first, `apply` to change; it only deletes empty channels):
  START HERE (read-only): #welcome (Carl-bot welcomes; our pinned guide links the website) · #rules (Carl-bot reaction-role message + our rules) · #announcement (big news only: a new game app / release, owner request 2 Nov 2026) · #updates (every update) · #server-status (public server up/down/updated, bot-posted; pinned connect + item page) · #faq ("can't connect after an update -> make a new game file with HOST-MY-SERVER.bat").
  Roles (layout.js ROLES, 9 Nov 2026): "Master Shinobi" = ADMINISTRATOR (never give it to supporters) · "Moderator" (no admin: delete messages, timeout,
  kick/ban, voice, nicknames; Goat_RyouYuuta🧛🎃 has it, owner's choice) · Patreon supporter roles (cosmetic, no permissions) "Shinobi Recruit" €1, "Shadow Ninja" €3,
  "Shinobi Elder" €5 (also sees #patch-testing) · "Training Shinobi" = member role (Carl-bot), kept below them so their colours show.
  💎 SUPPORTERS: #supporters (supporter roles + staff only; pinned-style welcome post by the bot). Supporter perks are never in-game things.
  GUIDES & HELP: #install-help + #how-to-play (read-only guides: EDIT the bot posts when the game changes) · #support (players ask) ·
  #bugs-and-issues (players report). COMMUNITY: #general, #screenshots, voice. DEV & STAFF (Master Shinobi only): #dev-chat, #patch-testing, #bot-logs.
  Guides (#welcome, #install-help, #how-to-play, #faq) are built from `discord/guides/<channel>.md` ("## " = one chapter, contents with jump links on top):
  edit the file, then `node --env-file=.env guides.js <channel>` (dry run) and `... <channel> apply` (replaces only the bot's own posts there),
  then `node tools/build_wiki.js` (the wiki shows how-to-play, install-help and faq).
  Keep it updated: new feature or visible fix -> #updates + how-to-play.md; new app or release -> #announcement; install/update change -> install-help.md / faq.md. Never reply in chat channels.
  Website links in the guides: home page https://ninjaonlinereborn.com, wiki https://ninjaonlinereborn.com/wiki/.

## 11. Open work (update this list)
Who does what next: **`docs/CHECKLIST.md`** (owner + Claude, keep it current). Every bug-list item and owner request is tracked in **`docs/PROGRESS.md`** (✅ fixed in game / 🧪 test save only / ⏳ to do / 🚫 not possible;
the per-list Summary counts must match the rows). It is also the control panel's **Progress** tab (served at `/progress.md`). Update it with every fix.
State on 8 Nov 2026: bug lists 1-4 done (48 ✅, 2 🚫; issues #2-#5 closed); list 5 (issue #6, open): 3 ✅, 1 🚫; Discord reports: 10 ✅, 1 🧪, 1 🚫.
Built 8 Nov: Breakthrough like the original photos; the wiki; the website ninjaonlinereborn.com (section 6). All live on ninjaonline.
**Decided 9 Nov 2026 (owner):** god card fragments for every god card from won fights (`shards.js`, rates in the Server Manager, ours) and a
**weekly event rotation** (`rotation.js`: the limited events come and go so all of them show in 7 days; Super Ninja twice a day for 4 hours with a
new god card every hour; Shard Rush days 4 and 7; Server Manager panel "Weekly rotation": on/off, take an event out, reset to day 1).
**DEAN reset run (from 10 Nov 2026):** the owner resets DEAN and plays it like a normal player (max $100 free top-ups a day); the tracker (tracker.js, tab 🔎 Tracker, `tools/dev/track.js`) records it so owner and Claude look at each day together (fun / too fast / too slow). Balance changes only on the owner's word.
**Waiting for the owner's decision:** (3) Oracle Pay As You Go with a budget alert (steps on request). (4) Item page per player: "not now". (5) Fan-project footer notice: "not now".
The wiki lists 9 five-star cards with no known source (ATK/DEF variants of Teenager Naruto, Susa Itachi / Kakashi / Shisui, Goddess Sakura ATK).
Arena ladder rank rewards (ladderconfig/ladderdesc) built 2 Nov on top of the daily silver (owner); Eight Gates 5000 starter souls kept (owner).
Limited Super Ninja (limitsuper.js) built 2 Nov with our numbers; hourly god card (ROTATE_HOURS); since 9 Nov only in the rotation's windows
(11:00-15:00 and 18:00-22:00 server time = UTC on the cloud), its god cards stepping one per window hour (rotation.superNinjaHour).
Tutorial (5 Nov 2026): OFF for everyone via hot update 28.0.35 (owner: leave it off). The app starts its guide by itself (first_login only shows an ad), so it can only be on/off for all players through server/cdn/src/home/userguideConfig.xml; the Server Manager switch is gone (handlers.js TUTORIAL = false keeps the server helpers off). See NEXT-STEPS 5 Nov.
Left as is: 300-gold recruit gold prizes coded but OFF (CDialogShowBox show type 1 can only draw a card; see NEXT-STEPS);
five-element panel (photo 2666) not found in any v28 layout; first boss 1-2 stays hard on purpose (owner: ~23 % for an un-upgraded starter).
Not possible in v28 (see NEXT-STEPS 2 Nov): limited daily gift `rl_r_dailylimit` (layout lacks its nodes), card split `rl_w_split_card`
(never opened), rebate wheel `rl_r_multiple_pay`, opening scene skip, 10-pull zoom, Chartboost ad error, 64-bit / iPhone versions. Login: gumplogin.js +
release/classes-revival.dex (see NEXT-STEPS 2 Nov). Find missing endpoints with: compare `server/reference/client-endpoints.txt` to
`Object.keys(require('./handlers'))`.
