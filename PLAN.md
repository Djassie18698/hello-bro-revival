# Hello Bro revival - master plan

Goal: everything playable offline with friends. Work happens in this order. Each finished step is tested in the
game (BlueStacks instance "Claude Root", adb 127.0.0.1:5595), then committed and pushed to GitHub.

## How each step is done (the loop)
1. Open the screen in the game, watch the server log for `[UNHANDLED]` requests and logcat for `no node:X` / `LUA ERROR`.
2. Find the exact reply format in the Lua scripts (obb/script) or by disassembling libgame.so (tools/armdis.py).
3. Add the handler in handlers.js / game.js, restart the server, retest, screenshot.
4. Update PROJECT-NOTES.md, run PUBLISH.bat (commit + push).

## Phase 1 - Power and gear (highest value)
1. **Gear stats**: add equipment attack/defense/chakra (equipmentinfo cols 7-12, times level scaling from equipupgrade.json)
   to the team slot values in slotXml, to Spar power, and to training/spar fights.
2. **Gear sets**: suit_info.json (set bonuses) -> compute active set per ninja, return `skillsuit` / suit list, apply bonus.
3. **Gear upgrade/refine**: rl_w_star (equipment star/strengthen), equipupgrade.json costs; refinery (refinery_info.json).
4. **Ninja stats properly**: ninjastrength/ninjaupgrade tables for attack/defense/chakra per level and star, tupo (breakthrough), newlife (reincarnation).

## Phase 2 - VIP and shop economy
5. **VIP**: vipinfo.json (levels, perks), vip_gift.json (daily/level gifts). Server tracks total "top-up"; since this is offline,
   give admin page a "set VIP level" button and a free top-up shortcut. Implement VIP screens (Shop > VIP tab) and perks
   (extra refreshes, energy cap, etc.).
6. **Top-up / 1st recharge**: fake top-up packages in rl_r_paypack + admin "grant top-up" so VIP and first-pay rewards are reachable.
7. **Remaining shop items**: item effects for all consumeinfo types (energy, duel points, ninja souls, fragments, ramen...).

## Phase 3 - Gacha polish
8. Fix the "Sample Text" reveal in the pull dialog (compare with the working soul-shop reveal; check landscape/rotation glitch and the
   CDialogShowBox ForJieYin branch), add pity counter (protect_comming), free-pull timer, recruitment orders item (id 30).
9. Real rates from recruitinfo (cols), 10-pull guarantee.

## Phase 4 - Fights
10. **Training battles with animation**: find why CRoundFightView does not play for pve (compare with Spar which animates),
    multi-fight stages (progress 0/2), boss stages, drops (dropinfo.json), star ratings.
11. Spar polish: battle count, rewards, rank. Plunder (seals: markinfo/markmerge), arena/sport (rl_r_sport), tower (towerfloor/rushtower),
    world boss, war (warconfig), countries.

## Phase 5 - Social and long-term
12. Akatsuki (guild) system: rl_r_group_comm / rl_w_group_comm - create, join, base buildings.
13. Friends (rl_r_friend, rl_w_friend), chat/mail (rl_r_msg, rl_w_msg), hall of fame.
14. Dun (eight gates) upgrades, reincarnation (rl_w_newlife), growth/potential, pets (petinfo).
15. Daily/seven-day/month events: seven-day quests (sevendays_quest.json), month sign-in, wheel (wheelconfig), mora, treasure.

## Phase 6 - Quality
16. Admin page: VIP, souls, items, gear, level, reset player.
17. Backups of hellobro.db, installer script for friends, README for non-technical setup.

## Rules for working unattended
- Never touch BlueStacks instance "Rootstack". Test only on "Claude Root".
- Keep the server compatible with the unmodified patched APK.
- After each working step: restart server, retest, update notes, publish to GitHub.
