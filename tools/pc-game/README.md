# Ninja Online for PC

The rewritten game (`server/webclient`) as a program you start with a double-click. Every picture and sound is in the folder next
to it, so nothing is downloaded while you play; only the game's own requests go to the game server.

- **Build:** double-click `BUILD.bat` (or `tools\pc-game\BUILD.bat "<folder>" zip` for a zip to share). It makes the folder
  `Ninja Online` on the Desktop: `Ninja Online.exe`, `game\` (a copy of `server\webclient` without the phone-app-in-a-browser),
  `server.txt` and three small Microsoft files (`tools/pc-game/webview2`: the WebView2 SDK 1.0.2792.45 from nuget.org, with its licence). Needs `server\webclient\assets` (`node tools\build_webclient.js`, `node tools\build_hd.js`). About 320 MB.
- **Play:** start `Ninja Online.exe`. It opens the game in **its own window** (`GameWindow.cs`: a Windows window named Ninja Online with the game's icon; the drawing engine that is part of Windows, WebView2, shows the game inside; no browser title, address, menus or keys; dark with the game's name while loading). F11 or Alt+Enter = full screen. Its data is in the folder NinjaOnline under %LOCALAPPDATA%. Only on a Windows without WebView2 does it fall back to an Edge / Chrome window without an address bar. `--dev` turns the right-click menu and the developer tools on.
  with its own profile in `%LOCALAPPDATA%\NinjaOnline`). Close the window to quit. F = full screen.
- **Which server:** the first line of `server.txt` (default: the public server). Change it and start again.
- **How:** `Launcher.cs` serves `game\` on `http://127.0.0.1:<free port>/play/` and passes every other request
  (`/rl_...`, `/xk_...`, `/gump/...`, `/api/...`, `/status`, `/cdn/...`) on to the game server. Nothing outside `game\` is served.
- **No lag:** files come from the disk, and `server/webclient/preload.js` reads every icon sheet and the player's own card art
  ahead of time (`HB.preload.state()` in the console shows how far it is).
- **Testing without a window:** `"Ninja Online.exe" --no-window --port=18222`, then open `http://127.0.0.1:18222/play/?pc=1`.
- After a change to the game, build again: the folder is a copy.
