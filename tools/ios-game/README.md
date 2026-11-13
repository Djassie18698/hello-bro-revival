# Ninja Online for iPhone: the game as an app

The browser version of the original game (`server/webclient/emu`) inside an iPhone app, with **every game file packed in**
(about 145 MB): nothing big is downloaded, it starts in a few seconds, full screen, sound also on silent, and the login and the
downloaded hot update are kept. It plays on the public server (https://ninjaonlinereborn.com/game/), so players log in with their
own account like in the browser.

How it works: `NinjaOnline/App.swift` runs a tiny web server on 127.0.0.1 inside the app and shows the game page from it. `/play/...`
are the page and the game files from the app (a file the app lacks, such as a newer hot update, comes from the website); every other
address is a game request and goes on to the public server. If the phone runs JavaScript slowly on that page (iPhones only keep the
fast compiler on secure pages; 127.0.0.1 should count as one), the page switches to the website's page and still reads the files from
the app (`server/webclient/emu/main.js`, `?app=1` / `?files=`).

GitHub's Mac builds it when this folder, the game page (`server/webclient/emu`) or the hot update changes
(`.github/workflows/ios-game.yml`), and puts **NinjaOnline.ipa** on the release **ios-game**:
https://github.com/Djassie18698/hello-bro-revival/releases/tag/ios-game

## Install it (Windows PC + USB cable, about 10 minutes the first time)
1. On the PC install **iTunes** from apple.com (the website version, not the Microsoft Store one; Sideloadly needs it), and
   **Sideloadly** from https://sideloadly.io.
2. Download **NinjaOnline.ipa** from the release link above.
3. Plug the iPhone into the PC, unlock it, tap **Trust** on the phone.
4. Open Sideloadly: drag NinjaOnline.ipa onto it, type your **Apple ID** e-mail in the box, press **Start**, then type your Apple ID
   password when it asks (Sideloadly sends it only to Apple, to sign the app).
5. On the iPhone: **Settings > General > VPN & Device Management** > your Apple ID > **Trust**.
6. iOS 16 or newer: **Settings > Privacy & Security > Developer Mode** > on, the phone restarts, tap **Turn On**.
7. Open **Ninja Online**: Play as guest, Log in or Sign up.

## Every 7 days
With a free Apple ID the app stops opening after 7 days. Plug the phone in and press **Start** in Sideloadly again (same file or a
newer one): the app and your login stay. (A paid Apple Developer account, $99 a year, makes it last a year.)

## Changing the app
- Icon: `node tools/make_game_icon.js`.
- Code: `NinjaOnline/App.swift`, `NinjaOnline/Info.plist`, `project.yml` (XcodeGen).
- The big game files (libgame, apk, obb pieces, sounds) are not in git: after `node tools/build_webclient.js --emu` made new ones,
  run `sh tools/ios-game/PACK-GAME-FILES.sh` (uploads game-files.tar to the release), then run the build again
  (repo > Actions > "iPhone game app" > Run workflow).
- A change to the game page or a new hot update rebuilds the app by itself on push; players sideload the new NinjaOnline.ipa.
