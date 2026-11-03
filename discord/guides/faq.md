# ❓ FAQ
Common questions. Not answered here? Ask in <#1565697834571927694>.

## 1. I can't connect to the server after an update
If you host your own server and the game can't connect after you updated it, make a new game file for your server:
1. Update your server folder (run **UPDATE.bat**), then start the server again.
2. Double-click **HOST-MY-SERVER.bat** in your server folder.
3. Type your server address when it asks (the same one your friends use, for example your Tailscale IP), or press Enter for your own PC.
4. It makes a new game file. Install it on every phone or emulator that plays on your server (uninstall the old game first if it won't install over it).
5. Open the game and tap **Confirm** if it asks to download an update.

## 2. The game won't install on my phone or tablet
Install it from a PC with a USB cable: turn on **USB debugging** on the phone, put **HelloBro-ninjaonline.xapk** and **INSTALL-WITH-USB.bat** (both on the Releases page) in one folder and double-click the .bat. Step by step: <#1565697833150058507>, chapter 2. That works on every phone, also Android 14 and 15.
Own server? Android 14 and newer refuse game files made before 2 Nov 2026: run **UPDATE.bat**, make a new game file with **HOST-MY-SERVER.bat**, and install that one the same way.

## 3. How do I update my own server?
1. Close the server window.
2. Double-click **UPDATE.bat** in your server folder. No UPDATE.bat? Download the folder again from GitHub (Code > Download ZIP).
3. Start the server again with **START-SERVER.bat**, and tap **Confirm** in the game if it asks to update.
4. If the game can't connect afterwards, see question 1.
Playing on the public server? You only need step 3: tap **Confirm** when the game asks.

## 4. I lost my account after reinstalling
The game links your account to your device. To move it, first tap **Change** > **Login with Gumptech** > **Signup** on the old device and pick a name and password. Then use **Login** with them on the new device. Without a name and password, a reinstall makes a new account.

## 5. Is it really free?
Yes. Top-ups cost nothing and still raise your VIP level. On the public server you can top up once a day; on your own server as often as you like (the owner of a server can change this in its control panel). Never pay anyone for gold, accounts or items.

## 6. Is the public server always on?
Yes. Since 3 Nov 2026 **ninjaonline** runs in the cloud, so it's online day and night, also when the owner's PC is off. Now and then it restarts for an update (a minute or so). Your progress is saved and backed up every 6 hours.

## 7. Can I add gold and items myself?
Yes, on the public server for now. Open **http://ninjaonline.duckdns.org:18080/admin** in a browser (PC or phone), type your in-game name under **Players** and click it. Then use **Resources** (gold, silver, energy, level ...), **Give** (one card or item) or **Team editor**. Close the game and open it again to see what you added.
Only change **your own** account: leave other players alone.

## 8. Something is broken
Post it in <#1566415215220752444> with a screenshot and what you did. Fixes are announced in <#1565697769874919515>.
