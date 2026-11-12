# Web client: the game in a browser (for iPhones)

Started 12 Nov 2026 (owner: "try the rebuild"). Background and the other routes: `docs/IPHONE-GAME-RESEARCH.md`.

The Android app is the game's own C++ (`libgame.so`) plus Lua scripts, layouts and pictures. iPhones can't run it, so this
folder rebuilds the **C++ part** in plain JavaScript and reuses **everything else** as it is: the layouts (`.ccbi`), the sprite
sheets, the fonts, the texts and the tables. It talks to the same game server with the same requests as the phone app, so the
server needs no changes and Android and browser players play together.

## Try it

1. `node tools/build_webclient.js` (once, ~20 s; needs `re/obb` from `python -I tools/setup_re.py`). It makes
   `server/webclient/assets/` (git-ignored, ~130 MB) from the game's own files, with our hot-update files laid on top.
2. Start a game server (`bash tools/dev/restart.sh` = dev server on :18081) and open `http://127.0.0.1:18081/play/`.
   Phones on the same Wi-Fi: `http://<PC address>:18081/play/`.

Test switches: `?auto=1` walks from the login screen to the home screen by itself (makes a guest and a character if needed); `&tap=btn_activity` then presses home buttons (comma list);
`?ccb=<layout>` shows one layout alone (e.g. `?ccb=sub_ui/DefaultMainMenu`, `&frame=0` = without the 768-wide frame).

## Files

| File | What |
|---|---|
| `index.html` | the page: one canvas, full screen, Add-to-Home-Screen ready |
| `lua.js` | **a Lua 5.1 engine in JavaScript**: turns each Lua script into JavaScript once, then runs it; numbers, byte strings, tables, metatables, `module(..., package.seeall)`, require, patterns, string.format work like the phone's Lua 5.1. Checked by `tools/dev/lua-test.js` (32 programs with real Lua 5.1 output + all 396 game scripts compile; check.sh runs it) |
| `luabind.js` | the bridge the scripts expect from the C++ (tolua++): cocos2d-x classes on top of engine.js (CCSprite, CCLabelTTF/BMFont, CCScale9Sprite, CCControlButton, actions, CCSpriteFrameCache, CCDirector, CCUserDefault ...), CCBProxy (layouts from Lua), LuaTableView + LuaEventHandler, CCHttpRequest (the server), LuaXML (xml.eval/parse/load/encode), io.open (small files kept in the browser), Lua touch layers |
| `gamebind.js` | the game's own C++ helpers for the scripts: GetMainMenu (tips, loading, dialogs, screens), CPlayerDataMgr (player numbers from rl_r_mainpage), CNetUser, CServerListMgr, DataMgr.GetDataByID (tables by their C++ field names), CSoundMgr, the event list (PushActivityName); anything missing answers nil and is logged once ("Lua wants ...") |
| `engine.js` | a small cocos2d-x 2 look-alike on a 2D canvas: nodes (y up, anchor points), sprites, 9-slice sprites, TTF and bitmap labels, buttons, colour layers, scroll views, CCB timelines, tweens, taps; builds a layout from its JSON (`HB.loadCCB` + `HB.build`) |
| `net.js` | `HB.api(endpoint, params)` = the phone's POST + XML reply; `HB.account(path, form)` = the account window (`gumplogin.js`) |
| `game.js` | the screens (what the C++ classes did): login (CLoginScene), account window, character creation, home (CMainMenu + CDefaultMainMenu + the country's village) |
| `assets/` | made by `tools/build_webclient.js`, not in git |

## Rules found so far (from the phone and `re/all.txt`)

- Screen size: `AppDelegate::applicationDidFinishLaunching`: tall screens (height/width > 1.5) are 686 wide, others 768 x 1024.
- The full-screen layouts are made for a 768-wide screen and centred; a layout's root covers the screen whatever its anchor.
- Sub-menus (home, team, ...) go into MainMenu's `node_content` in the same 768-wide frame (`CMainMenu::ChangeToSubView`).
- Texts: a label or button gets its English text from its member name: `STRING_UI_TEXT_` / `STRING_UI_BTN_TEXT_` + `NAME_FILE`
  in capitals -> a number (the giant `InitSTRINGUICONST`) -> `Struct_String_UI` (the English game keeps English in the `_zh` tables).
- A 9-slice sprite in a layout without an anchor point uses (0,0) (the Event window's frame, Home's side bars).
- The home layer is as tall as the screen (CCLayer::init), not as tall as `node_content`: the scripts place the event buttons at height - 550.
- Sheets: an encrypted `x.pvr.ccz` becomes `x.pvr.png`; a plain `x.png` next to it stays (the login moon is the plain one).
- Village: `CProfileData::firefly_GetCountryLayoutName`: country 0 Wind, 1 Mine (thunder), 2 Water, 3 Fire, 4 Earth, else Fire.
- Locked home buildings: functionconfig 1 / 5 / 2 / 22 with menu text 272 "Unlock at Lv.%d" (`CDefaultMainMenu::InitUI`).

## The Lua side (12 Nov 2026)

The game's own scripts run unchanged: at Home the web client starts Lua, runs `script/mainActivity.lua` (all its requires, its own
server requests for the events), waits for those answers (the phone's loading screen did that), then does what
`CDefaultMainMenu` did: `MenuBtnsView.lua` InitMenuBtnsView (the middle row: Ninjabook ... Reincarnate) and
`initMainMenuActivityBtn` (the event buttons on the left). The Event button runs `activityPopup_business.lua` +
`initactivityPopupLayer`: the whole Event window is the game's Lua. Tools: `node tools/dev/lua-test.js`; in the browser
`HB.luaErrors`, `HB.luaMissing` (C++ names a script asked for that are not there yet).
To list the C++ names all scripts use: parse every script with `Lua.parse` and collect globals read but never written (172 globals,
851 method names on 12 Nov 2026).

## Not done yet (the big parts)

- More of the C++ helpers the scripts call (`CGameObjElement` card icons and frames, `CTradeMgr`, item lists ...), so the Lua
  screens behind the event buttons open; Lua screens draw, but most of their buttons lead to C++ screens not rebuilt yet.
- Team cards on the home screen, every screen behind the bottom bar (Team, Backpack, Training, Spar, Shop), fights, sounds.
- The website route (`https://ninjaonlinereborn.com/play/` through Caddy) and the game files on the cloud machine.
