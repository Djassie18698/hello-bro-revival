# Hello Bro / Ninja Online revival - handover for Claude

You are continuing a hobby project: a replacement game server so the dead mobile game "Hello Bro" (Naruto-themed card RPG, Android
package `com.hello.bro.yo`, v28.0, Cocos2d-x 2 + Lua 5.1) can be played offline with friends. The owner is NOT a developer. They want
everything in the original game to work again, no payments (everyone can be admin). Work autonomously, don't ask for confirmation,
follow `PLAN.md`, and **commit + push after every working change** (`git add -A; git commit; git push`).

## What is in this repo
- `server.js` (HTTP server, port 18080), `handlers.js` (one function per client endpoint), `game.js` (game logic: cards, team stats,
  gear, sets, gacha, shop, training, spar, daily tasks, events, soul shop), `admin.js` (web admin page /admin), `schema.js`.
- `hellobro.db` = SQLite save (Node 24 `node:sqlite`). `START-SERVER.bat` runs it. `README.txt`, `FRIENDS-README.txt` = user docs.
- `data/*.json` = all game tables from the original game (ninjainfo, equipmentinfo, suit_info, vipinfo, vip_gift, roundinfo, dropinfo,
  consumeinfo, giftinfo, secret_shop, playerlevel, ...). `tools/mbs.py` + `tools/export_tables.py` regenerate them from `tables.bin`.
- `reference/lua-scripts/` = the game's own Lua UI scripts (from the OBB). THE source of truth for reply formats: search for the
  endpoint name (e.g. `rl_r_vipshop`) and read how the reply XML is parsed with `:find("tag")`.
- `reference/client-endpoints.txt` = every endpoint the client can call. `PROTOCOL-NOTES.txt`, `docs/PROJECT-NOTES.md` = verified formats
  and lessons learned (READ THESE FIRST).
- `tools/` = apk patcher (`patch_apk.py`, `patch_dex.py`), `armdis.py` (ARM disassembler for libgame.so), `dev/*.sh` (adb test helpers).
- NOT in the repo (copyright/size): the original APK/OBB, `libgame.so`, the signing keystore, the patched xapk. The owner has them on
  their PC (`Desktop\HelloBro-revival.xapk`). C++ screens are parsed inside libgame.so (disassemble it when Lua has no answer).

## Protocol basics
- Client POSTs/GETs `/<endpoint>` with params `Uid, Session, ServerID, GroupID, Cmd, ...`. Replies are XML `<RENLONG code="0">...</RENLONG>`
  (server.js rewrites `<root` to `<RENLONG`). Any non-zero code = error tip. Accounts auto-create; any session is accepted.
- C++ parsers (tinyxml) usually read values from child element text OR attributes - it differs per endpoint; check the notes.
- A missing element/attribute usually crashes the C++ client (SIGSEGV, fault addr 0x0/0x18) or logs `this is no node:X`.
  Lua parsers crash with `LUA ERROR ... attempt to index nil`. Always return every field the parser reads.

## How to test
- With an Android emulator (BlueStacks) and the patched APK: `tools/dev/*.sh` (adb screenshots + logcat). Cloud sessions have no emulator,
  so there: write handlers from the Lua/disassembly, then smoke test with `node tools/dev/probe.js <endpoint> <Cmd> [k=v ...]`
  (starts nothing, just POSTs to a running `node server.js`), and keep the changes small and defensive.
- Rule: never trust a format you have not verified against the Lua script or disassembly.

## Status (see PLAN.md for the ordered plan)
Working in game: login/character creation, home, team (real stats, gear, sets), backpack, card level-up, gacha (single/10x),
shop (items, gift packs, buy/use), Event popup (login/level gifts), daily tasks, Spar vs players/bots with battle animation,
Training (stages auto-win), soul shop, hall of fame, admin panel.
Known broken/unbuilt: VIP shop (`rl_r_vipshop`, `rl_w_vipshopbuy`, vipinfo/vip_gift tables), top-up, gacha reveal text "Sample Text",
Training battle animation, guilds (Akatsuki), Dun upgrades, equipment upgrade (rl_w_star), plunder/seals, arena, tower, war, friends, mail.

## Conventions
- Keep `data/` and handlers deterministic and offline: no real payments; top-up screens should grant things freely.
- Admin page: anyone can give gold/coins/cards (the owner wants this).
- When you learn a new reply format, append it to `docs/PROJECT-NOTES.md` and PROTOCOL-NOTES.txt.
