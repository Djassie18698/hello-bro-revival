# 📥 How to install Hello Bro (revival)
Hello Bro / Ninja Online (v28.0) is back on our own servers. It's free: top-ups cost nothing and there's nothing to buy.
All files are on the **Releases page**: https://github.com/Djassie18698/hello-bro-revival/releases
Questions? Ask in <#1565697834571927694>.

## 1. Play on the public server (easiest)
The public server **ninjaonline** is online day and night (it runs in the cloud, not on someone's PC).
The game file for it is **`HelloBro-ninjaonline.xapk`** on the Releases page: https://github.com/Djassie18698/hello-bro-revival/releases/tag/tailscale-play
**On a PC (BlueStacks 5):**
1. Install **BlueStacks 5**: https://www.bluestacks.com
2. Download **`HelloBro-ninjaonline.xapk`** and drag it onto the BlueStacks window. Wait until it's installed.
3. Open Hello Bro. When the account window shows, tap **PLAY**. The game remembers this device.
4. Tap **Confirm** if it asks to download an update, press **START**, then pick your nation and your ninja.
**On a phone or tablet:** see chapter 2.

## 2. Android phone or tablet
The surest way is **from a PC with a USB cable** (USB debugging). Phone XAPK installer apps often fail, or install the game without its data (then it shows a black screen or closes at start).
**A. Turn on USB debugging (one time)**
1. On the phone: **Settings > About phone** (Samsung: **About phone > Software information**). Tap **Build number** 7 times (Xiaomi: tap **MIUI / OS version**). Enter your PIN if asked: "You are now a developer".
2. Go back to **Settings > Developer options** (Samsung: at the bottom of Settings; others: **System > Developer options**) and turn on **USB debugging**.
**B. Install**
1. On the PC, download these 2 files from the Releases page into **one folder**: **`HelloBro-ninjaonline.xapk`** and **`INSTALL-WITH-USB.bat`**. (Own server? Use your `HelloBro-for-<address>.xapk` instead.)
2. Uninstall any old Hello Bro on the phone. Close BlueStacks on the PC.
3. Connect the phone with a USB cable (a data cable, not a charge-only one). The phone asks **"Allow USB debugging?"**: tick **Always allow** and tap **Allow**.
4. Double-click **`INSTALL-WITH-USB.bat`**. The first time it installs Android's USB tool (adb): close the window when it says so and double-click it again.
5. It installs the game and copies its data. When it says it's done, open Hello Bro on the phone and tap **PLAY**.
6. Google Play Protect says "unsafe app blocked"? Tap **More details > Install anyway**.
**No cable?** On Android 11+ it also works over Wi-Fi: when the .bat finds no phone, type **W** and follow its steps (Developer options > **Wireless debugging**, phone and PC on the same Wi-Fi).
**No PC?** Try an XAPK installer app (for example *XAPK Installer* or *APKPure*). If it fails or the game shows a black screen at start, use the USB way above.
Done? You can turn USB debugging off again.

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
• *Black screen or crash at start (phone)*: the game's data (.obb) wasn't copied. Install it with the USB way (chapter 2). Still black after that? Clear the game's data: Settings > Apps > Hello Bro > Storage > **Clear data**.
• *"This app was built for an older version of Android"*: tap **OK**, the game works.
• *Screen sideways in BlueStacks*: the game is portrait. Turn off forced landscape for the app in BlueStacks settings.

## 8. Bugs and help
• **Questions:** <#1565697834571927694>. Say: public server or your own, BlueStacks or phone, and what you see on screen.
• **Bugs:** <#1566415215220752444>, or on GitHub: https://github.com/Djassie18698/hello-bro-revival/issues
• **What's new:** <#1565697769874919515>
