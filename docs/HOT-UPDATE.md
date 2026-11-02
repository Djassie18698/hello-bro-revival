# Pushing client fixes without a new APK (hot update)

The game has its own resource updater. It is driven by `rl_r_version`:
`<updatechip><version val="X"/><cdn>http://host/cdn/</cdn><filelist><file name="X_update.zip" val="X" md5 size/></filelist></updatechip>`.

1. Put changed files in `cdn/src/` with the same paths as inside the OBB, e.g. `cdn/src/script/ui_layer/ui_purchaseLayer.lua`.
2. Run `python -I tools/build_cdn.py 28.0.4` (always a HIGHER version than the last one).
3. Restart not needed: the next game start shows "confirm update?", downloads, unzips to `files/renlong28/`, and the game loads those files first.

Rules learned the hard way: the zip name must start with the version followed by `_`; the zip needs explicit folder entries
and everything under `renlong28/` (build_cdn.py does both). `<updateversion>` is the separate APK updater and must stay at 0.0.1.

Shipped so far: 28.0.3 = ui_purchaseLayer.lua (top-up buttons call rl_x_free_topup instead of Google Play).
28.0.5 = adds config/activity_config.lua (activity id 47 = seven-day goals in the Event menu) and ui_sevenDayView.lua (day counter).
28.0.6 = changed pet unlock levels (withdrawn). 28.0.7 = ships the ORIGINAL ui_myBaseLayer.lua / ui_petPsychicLayer.lua so phones that got 28.0.6 are back to level 150 / original slots.
28.0.8 = adds home/userguideConfig.xml with every tutorial level moved to 900+ (tutorial off; levels were 1,5,10,20,25,30,35,40).
28.0.9 = ui_purchaseLayer.lua also sets the VIP level from <viplevel> in the rl_x_free_topup reply.
Note: mainActivity.lua is run by C++ straight from the OBB, so patching it does nothing; files loaded with `require` do pick up patches.
28.0.10 = adds ui_layer/ui_sevenDayCell.lua with English texts for the 7-day goals (the game's own table is Thai).
28.0.11-13 = ui_layer/ui_gameSettingLayer.lua: the hidden "switch account" row in Settings is now a "Join Discord" button (openHyperlink to https://discord.gg/2Cbp4UDHrU). Lua button titles: setTitleForState with a Lua string does nothing and with CCString errors here; set getTitleLabel() (CCLabelTTF) instead.
28.0.14-15 = ui_layer/ui_festivalLayer.lua: the festival item icons load their own sprite sheet (props/<icon>.plist) inside pcall (spriteFrameByName on an unloaded frame and GetConsumeIcon both failed and stopped the trade list).
28.0.16 = config/activity_config.lua: event 27 (limited discount) opens business_proxy/limitDiscount_business in the Event menu (its name was a home-button script call -> empty page).
28.0.17 = sub_ui/TeamNinjaView.ccbi (team screen card): label_ninjaname font 24 -> 18, width 28% (= the orange name bar) so long names wrap to 2 lines, centred. Made with `tools/ccbi.py` (reads/patches .ccbi files; `python -I tools/ccbi.py dump <file> [name]`).
28.0.18 = story-stage "So lucky !" pop-up: the button picture (dropbox_04 in ccbResources/runlevel_drop.pvr.ccz) says "Proceed" instead of "Fold", and dlg_ui/RunLevelDrop.ccbi shrinks the game's own tiny title (size 12 -> 1) that was drawn over it. Made by `python tools/patch_runlevel_drop.py`. Sprite sheets are encrypted ('CCZp'): `tools/pvrccz.py` decodes/encodes them with the key from libgame.so.
28.0.19 = reverts 28.0.18: ships the ORIGINAL runlevel_drop.pvr.ccz and RunLevelDrop.ccbi (the re-encoded sprite sheet drew a dark purple box instead of "So lucky"). Owner: keep the Fold button.
28.0.20 = ui_layer/ui_sevenDayView.lua: a failed Claim on the 7-day goals shows the server's reason ("finish all goals first") instead of nothing (bug list 3).
28.0.21 = ui_layer/ui_purchaseLayer.lua: the "49$ gift" row can show a card picture (icon_npc.. from icon/), for the original Naruto card.
28.0.22 = util/common.lua: the cross-server battle (MULTI_BATTLE_CGI_IP) talks to the game's own server (CServerListMgr server url) instead of the dead 23.91.96.227:8080.
28.0.23 = ui_layer/multi_battle/ui_multiBattleScoreDlg.lua: the cross-server Score Ranking pop-up starts with an empty list (it asked the size of a nil list before the server answered: Lua error).
28.0.24 = ui_layer/ui_sevenDayView.lua: the 7-day goals screen no longer stops with a Lua error (its layout has no label_get_award_day_left), so the Claim button is grey until the goals are done.
28.0.30 = core_combat/RS_WinAnim.ccbi + dlg_ui/BuyItemDialogCellView.ccbi: the default item label "大拉面" reads "Big Ramen" (tools/patch_winanim.py; tools/ccbi.py replace_string swaps a string-table entry).
28.0.29 = ui_layer/ui_lotteryTicketLayer.lua: the lottery draw time reads "11/02 20:30" (was "11Month02Day20Hour30").
28.0.28 = tables.bin also gets two new consumeinfo rows: 40 Fireworks (props_343, 100 gold) and 41 Balloon (props_344, 140 gold) for the Anniversary festival (festival.js). `python -I tools/patch_tables.py re/obb/tables.bin cdn/src/tables.bin normalconfig:7:2=0 normalconfig:8:2=86400 'consumeinfo:+[40,40,"Fireworks","props_343",100,0,"Anniversary Fireworks Get in Training and Battles",20,5,0,0,0,0]' 'consumeinfo:+[41,41,"Balloon","props_344",140,0,"Anniversary Balloon Get in Spar",20,15,0,0,0,0]'` (data/consumeinfo.json has the same rows). The Event menu button still says "Merry Christmas" (client label).
28.0.27 = tables.bin (the client data tables): normalconfig row 7 (war start) 70200 -> 0 and row 8 (war end) 73800 -> 86400, so the War screen counts down to midnight instead of going negative outside the original 19:30-20:30 (owner decision 1 Nov 2026: War open all day). Made by `python -I tools/patch_tables.py re/obb/tables.bin cdn/src/tables.bin normalconfig:7:2=0 normalconfig:8:2=86400`.
28.0.26 = core_combat/NewFightResult_WinView.ccbi: the round layer's real silver label (label_round_getsilver) was hidden under an empty one (label_round_getsilver_pre) that no code writes, so Spar/training wins showed silver 0. Made by `python -I tools/patch_winview.py`.
28.0.25 = ui_layer/ui_purchaseLayer.lua: a refused top-up shows the server's reason (the one-top-up-a-day limit).
