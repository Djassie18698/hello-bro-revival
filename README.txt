HELLO BRO REVIVAL
=================
1. Double-click START-SERVER.bat (keep the window open while playing).
2. Install HelloBro-revival.xapk in BlueStacks (drag it on; already patched to use this PC at 192.168.178.111:18080).
3. Open the game, press START. Your save is in hellobro.db next to the server.

If your PC's LAN address changes, rebuild the game file:
  python tools\patch_apk.py <original com.hello.bro.yo.apk> HelloBro.apk <new-ip>:18080 <patched classes.dex>
(see tools\patch_dex.py for the billing crash fix)

Done so far: boot, login, character creation, main screen (name, gold, coins, energy).
Not done yet: cards/team, chapters (Training), Plunder, War, Arena, shop, etc.
Every endpoint the game asks for that the server doesn't know is printed as [UNHANDLED] in the server window.

ADMIN PANEL (added): open  http://192.168.178.111:18080/admin  in any browser on the same network.
  - add Gold / Coins / Energy, set level, give any character (search by name). No password: offline hobby use only.
  - after giving a character, restart the game to see it.
GACHA: server side done (rl_w_recruit, Type 1/2/3 = premium/standard/free, ten-pull Cmd 1901). Not yet tested from the game UI (the Shop screen needs shop data first).
KNOWN: Shop crashes/needs real goods data; Training/Plunder/War/Arena not built; the starter team shows 3 of 4 cards (slot mapping to fix).

----- UPDATE (gacha + training) -----
* Shop > Recruit tab: the gacha screens open and pulls work (single + 10x). Cards are saved in your account.
  Premium banner: 300 gold (10x = 2800). Standard banner: 150 gold (10x = 1400). The "free recruitment" button is free every time.
  KNOWN ISSUE: the pull RESULT screens still show placeholders ("?" cards / "Sample Text"); the card is added, check Team/Backpack
  after restarting the game. Fixing this is next.
* Training: chapters open, stages can be started and give coins + exp and unlock the next stage. There is NO battle animation yet
  (stages are auto-won). Progress is saved.
* Admin panel unchanged: http://<your PC ip>:18080/admin  (add gold, coins, characters).
* Debug aid: put a ninja id in force_ninja.txt (next to server.js) to make every pull give that character. Delete the file for normal random pulls.

----- UPDATE 2 -----
Works now: Daily Task (with point chests), Spar (fight other players or bots, battle animation, rewards), Plunder list screen, Training with level-ups.
Playing with a friend: see FRIENDS-README.txt. Energy refills to full every time you log in (offline server).
Still broken: War button (crashes), Event popup, gacha result screens show placeholders, no real shop items, many other features not built yet.

----- UPDATE 3 -----
New: Event popup (login days + level-up gifts you can claim), Shop with all real items and gift packs (buy + use), card level-up in Backpack (feed spare cards), hall of fame, War/Country screens open.
Known gaps: equipment (weapons/armor/ninjutsu) not supported yet, so equipment gift packs say "not available"; Dun, Soul shop, Akatsuki, top-up/VIP and real training battles are not built.

----- UPDATE 4 -----
New: equipment. Weapon/armor/trinket bags from the Shop now give real equipment cards (they appear in Backpack after you re-enter the game or switch screens). In Team, tap a Weapon/Armor/Trinket slot and Choose a card to equip it.
Fixed: the team screen now shows all 4 starting characters.
Not done yet: equipment does not add attack/defense yet, equipment upgrading, soul shop, Akatsuki, Dun upgrades, battle animation for Training stages (they are won automatically).

----- UPDATE 5 -----
New: Soul shop (Soul tab > Secret shop: exchange ninja souls for characters; you start with 30000 souls), gear level-up (same screen as characters).
Akatsuki (guilds) is only a placeholder screen.
