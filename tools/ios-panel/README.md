# Ninja Panel: the control panel as an iPhone app

The control panel (https://ninjaonlinereborn.com/panel) in its own app with the NINJA ONLINE logo. Same pages as the home-screen app;
the app adds its own tab bar at the bottom (Server, Players, Team, Bugs with a red number when the fixer waits for you, More),
a start screen with the logo, pull down to reload, and links to other sites (Discord) opening in Safari or the Discord app.

GitHub's Mac builds it by itself when anything in this folder changes (`.github/workflows/ios-panel.yml`) and puts
**NinjaPanel.ipa** on the release **ios-panel**: https://github.com/Djassie18698/hello-bro-revival/releases/tag/ios-panel

## Install it (Windows PC + USB cable, about 10 minutes the first time)
1. On the PC install **iTunes** from apple.com (the website version, not the Microsoft Store one; Sideloadly needs it), and
   **Sideloadly** from https://sideloadly.io.
2. Download **NinjaPanel.ipa** from the release link above.
3. Plug the iPhone into the PC, unlock it, tap **Trust** on the phone.
4. Open Sideloadly: drag NinjaPanel.ipa onto it, type your **Apple ID** e-mail in the box, press **Start**, then type your Apple ID
   password when it asks (Sideloadly sends it only to Apple, to sign the app).
5. On the iPhone: **Settings > General > VPN & Device Management** > your Apple ID > **Trust**.
6. iOS 16 or newer: **Settings > Privacy & Security > Developer Mode** > on, the phone restarts, tap **Turn On**.
7. Open **Ninja Panel**, type the admin password once.

## Every 7 days
With a free Apple ID the app stops opening after 7 days. Plug the phone in and press **Start** in Sideloadly again (same file):
the app and your login stay. (A paid Apple Developer account, $99 a year, makes it last a year.)

## Changing the app
- Icon: `node tools/make_ios_icon.js` (draws `NinjaPanel/Assets.xcassets/AppIcon.appiconset/icon-1024.png` from the website logo).
- Code: `NinjaPanel/App.swift` (one web view), `NinjaPanel/Info.plist`, `project.yml` (XcodeGen).
- Push, the build runs (repo > Actions > "iPhone panel app"), then sideload the new NinjaPanel.ipa.
