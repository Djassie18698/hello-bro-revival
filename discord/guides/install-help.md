# 📥 How to install Hello Bro (revival)
Hello Bro / Ninja Online (v28.0) is back on our own servers. It's free: top-ups cost nothing and there's nothing to buy.
All files are on the **Releases page**: https://github.com/Djassie18698/hello-bro-revival/releases
Questions? Ask in <#1565697834571927694>.

## 1. Play on the public server (easiest)
1. Install **BlueStacks 5** on your PC: https://www.bluestacks.com
2. Download **`HelloBro-ninjaonline.xapk`** from the Releases page.
3. Drag the .xapk onto the BlueStacks window and wait until it's installed.
4. Open Hello Bro. When the account window shows, tap **PLAY**. The game remembers this device.
5. Tap **Confirm** if it asks to download an update, press **START**, then pick your nation and your ninja.

## 2. Android phone
**Android 14 or newer** (most phones and tablets from 2023 on): you need a game file made on or after 2 Nov 2026. Older files are refused with an error ("app not installed" or "built for an older version"). Ask your server owner for a new one, or make it again with HOST-MY-SERVER.bat.
1. Download the same .xapk. Open it with a zip app (it's a zip file).
2. Install `com.hello.bro.yo.apk` from it (allow "install unknown apps" if asked).
3. Copy `Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb` to the same folder on your phone: `Android/obb/com.hello.bro.yo/`
4. Open the game and continue at step 4 of chapter 1.

**Still won't install? Use a USB cable and a PC** (works for every game file, also older ones on new Android):
1. On the phone: Settings > About phone > Software information, tap **Build number** 7 times. Then Settings > Developer options: turn on **USB debugging**.
2. Connect the phone to the PC with a USB cable, tap **Allow** on the phone.
3. On the PC, in the server folder: drag the .xapk onto **INSTALL-WITH-USB.bat** (or put the .xapk in that folder and double-click it). It installs the game and its data. Close BlueStacks first.
4. If Google Play Protect says "unsafe app blocked": tap **More details > Install anyway**.

## 3. Your account and another device
Tapping **PLAY** makes an account tied to that device.
To keep it when you switch device: tap **Change** on the start screen > **Login with Gumptech** > **Signup**, and choose a name and password.
On the new device, use **Login with Gumptech** > **Login** with the same name and password.
Lost your account after reinstalling? Without that name and password the game makes a new account, so sign up before you switch.

## 4. Your own server (solo, or with friends)
Want your own world? The server runs on your Windows PC.
1. On the GitHub page: **Code > Download ZIP**, then unzip it (for example to `Desktop\HelloBroServer`).
2. From the Releases page, download **`HelloBro-base-host-your-own.xapk`** into that folder.
3. Double-click **`HOST-MY-SERVER.bat`**. Press Enter to play on your own PC, or type the address your friends will use (your Tailscale IP, for example). It makes **`HelloBro-for-<address>.xapk`**.
4. Double-click **`START-SERVER.bat`** and keep the window open. The control panel opens in your browser.
5. Drag your `HelloBro-for-….xapk` onto BlueStacks. Give the same file to friends who play on your server.
Full guide: https://github.com/Djassie18698/hello-bro-revival/blob/main/docs/HOST-YOUR-OWN-SERVER.md

## 5. Updates
• **Game updates** come in by themselves: when the game says **"confirm update?"**, tap **Confirm**.
• **Hosting your own server?** Close the server window, double-click **`UPDATE.bat`**, then start the server again. Your save is never touched.
• Can't connect after updating your server? Run **`HOST-MY-SERVER.bat`** again and install the new .xapk (see <#1565697836006375542>).

## 6. Friends in another house
They can't reach your PC directly. The easy way is **Tailscale** (free): you and your friends join the same Tailscale network, and you make the game file with your Tailscale IP in chapter 4, step 3.

## 7. Problems
• *"Network error" / stuck on loading*: the server is offline, or the game file was made for another address. Public server: ask in <#1565697834571927694>. Your own server: is `START-SERVER.bat` still open? After an update, make a new game file (chapter 5).
• *Black screen or crash at start (phone)*: the .obb file is missing or in the wrong folder (chapter 2, step 3).
• *"This app was built for an older version of Android"*: tap **OK**, the game works.
• *Screen sideways in BlueStacks*: the game is portrait. Turn off forced landscape for the app in BlueStacks settings.

## 8. Bugs and help
• **Questions:** <#1565697834571927694>. Say: public server or your own, BlueStacks or phone, and what you see on screen.
• **Bugs:** <#1566415215220752444>, or on GitHub: https://github.com/Djassie18698/hello-bro-revival/issues
• **What's new:** <#1565697769874919515>
