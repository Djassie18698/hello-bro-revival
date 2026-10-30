# Playing with a friend over Tailscale

Everything you need is in this private repository:
- **The server**: this folder.
- **The game for you and your friend**: `HelloBro-Tailscale-100.111.115.0.xapk`. It's under **Releases** on the GitHub page of this repo (tag `tailscale-play`) because it's too big for the code view. That one file holds both the game and its data. It connects to `100.111.115.0:18080`, the Tailscale address of the PC that runs the server.

## On the server PC (yours)
1. Tailscale is on and logged in. Check that its address is still `100.111.115.0`. If it changed, run `MAKE-FRIEND-APK.bat` with the new address.
2. Run `OPEN-FIREWALL.bat` once, as administrator.
3. Double-click `START-SERVER.bat` and keep the window open.
4. Admin page: http://localhost:18080/admin (give items, set levels, **reset a player**).

## Your friend
1. Install Tailscale, log in, and accept your invite to your tailnet (Tailscale admin console → Share or Invite users).
2. Install BlueStacks 5 and drag `HelloBro-Tailscale-100.111.115.0.xapk` onto it.
3. Open Hello Bro and press START. When it says "confirm update?", tap Confirm. Those are the server's game fixes.

## Starting over
Admin page → "Reset a player" → pick the player → Reset. A backup of the save is written to `backups/` first.
Close and reopen the game afterwards. The next START makes a new character.

## Updating
`git pull` in this folder, then restart `START-SERVER.bat`. Players get game fixes automatically through the in-game updater (`cdn/`).
