# Playing with a friend over Tailscale

Tailscale is a free private network: your friend's BlueStacks reaches the server on your PC as if you were on the same Wi-Fi.
Setting up your own server is in [`HOST-YOUR-OWN-SERVER.md`](HOST-YOUR-OWN-SERVER.md); this page is only the Tailscale part.

## On the server PC (yours)
1. Install Tailscale (https://tailscale.com/download) and log in. Its app shows your address (`100.x.x.x`).
2. Double-click `HOST-MY-SERVER.bat`. It picks up your Tailscale address and makes `HelloBro-for-<address>.xapk`.
   Run it again if your Tailscale address ever changes.
3. Double-click `START-SERVER.bat` and keep the window open. The control panel is at http://localhost:18080.

## Your friend
1. Install Tailscale, log in and accept your invite (Tailscale admin console → Share or Invite users).
2. Install BlueStacks 5 and drag the `HelloBro-for-<address>.xapk` you sent them onto it.
3. Open Hello Bro and press START. When it says "confirm update?", tap Confirm: those are the server's game fixes.

## Starting over
Control panel → Players & items → Reset a player → pick the player → Reset. A backup of the save is written to `backups/` first.
Close and reopen the game afterwards. The next START makes a new character.

## Updating
Close the server window, double-click `UPDATE.bat`, start the server again. Players get game fixes automatically (tap Confirm once).
