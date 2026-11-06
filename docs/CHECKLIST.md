# Checklist: what's left (6 Nov 2026)

All 4 bug lists are done (48 fixed, 2 not possible) and GitHub issues #2-#5 are closed. Every Discord report so far is fixed.
The public server **ninjaonline** runs in the cloud (Oracle) since 3 Nov, so it stays on when your PC is off.
From here on it's mostly new bug reports. This list says who does what. Tick a box (`[x]`) when it's done.

## You (Djassie)

### Do now
- [ ] **Restart your play server** (`Hello Bro Locked Server\START-SERVER.bat`) after an update: close its window, then double-click it again.
- [ ] **Bot always online:** double-click `discord\BOT-AUTOSTART.bat` once, if you haven't yet. After that the bot (and the #server-status
      messages) start with Windows. (I'm not allowed to set up auto-start myself.)
- [ ] **Cloud server safety:** Oracle can take back an idle "Always Free" machine. Switching the account to "Pay As You Go" (stays free)
      with a budget alert prevents that. Ask me for the steps when you want it.

### Keep doing
- [ ] Play and write down anything odd. Put it in **GitHub issue #6** (bug list 5) or tell me in chat. A screenshot helps.
- [ ] Look in Discord **#bugs-and-issues** and **#support** now and then. I read them too when you ask me to, and the bot replies to
      fixed bug reports.
- [ ] Say **"update the public server"** when you want the newest fixes on ninjaonline (or double-click `tools\vps\UPDATE-CLOUD-SERVER.bat`).
      It is not updated on every push.
- [ ] Events you can switch on in the control panel (Server tab) when you like: festivals (Christmas, New Year, Anniversary), Flower Worship,
      Month card, God of Wealth, Lottery, Group purchase, and more. They're off by default, like the original, where they only ran some of the time.
- [ ] Only try the **Cross-server battle** on a Saturday, 8-9 pm (it needs a ticket bought before Friday 8 pm).

## Claude (me)

### Ready to do when you say so
- [ ] Fix every new bug from issue #6, Discord or chat (test it, push, sync, post in #updates).
- [ ] Super Ninja: switch it from the hourly god to the original 3-day event.
- [ ] Lock the item page so each player only sees their own account (you said: not now, let people have fun).
- [ ] Steps to switch Oracle to Pay As You Go with a budget alert.

### Bigger, only if you want it (needs a new game app, so everyone reinstalls)
- [ ] Remove the old ad error after login ("INTERSTITIAL ... NETWORK_FAILURE"). It's harmless, so it's only worth doing together with another app change.

### Left as is (on purpose)
- Tutorial: off for everyone (your choice, 5 Nov). The game can only switch it on or off for all players at once.
- First boss (1-2) stays hard: your choice.
- Balance and prices: your choice, unchanged.
- 300-gold recruit gold prizes: coded but off, because the game can only show a card in that window.
- Five-element panel (photo 2666): no screen for it exists in this game version.

## Not possible
Inside the game app, so no server reply can change these:
- "Limited daily gift" packs: the screen's layout is missing its buttons.
- Card split: no button in this version opens it.
- Recharge rebate wheel: only multiplies real money, and top-ups are free here.
- Skipping the opening scene, and the zoom on 10-pulls.
- The "Loading for you, Master" wait: that's the phone loading pictures.
- A 64-bit version (phones that only run 64-bit apps, e.g. Pixel 7 and newer) and an iPhone version: the game's engine is 32-bit Android
  only and there's no source code. Those players can use BlueStacks on a PC (see #faq).
