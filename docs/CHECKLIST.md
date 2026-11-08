# Checklist: what's left (8 Nov 2026)

All 4 bug lists are done (48 fixed, 2 not possible) and GitHub issues #2-#5 are closed. Every Discord report so far is fixed.
The public server **ninjaonline** runs in the cloud (Oracle) since 3 Nov, so it stays on when your PC is off. The Discord bot runs there too (since 7 Nov),
and so does the website **https://ninjaonlinereborn.com** (home page + wiki at /wiki/, since 8 Nov).
From here on it's mostly new bug reports. This list says who does what. Tick a box (`[x]`) when it's done.

## You (Djassie)

### Do now
- [ ] **Bug helper bot** (#bugs-and-issues): runs on the cloud. Your own posts are skipped, so ask a friend (e.g. Riskeric) to post a test bug.
      The fixer runs on your PC every 2 hours while the Claude app is open: open "Scheduled" in the app sidebar > "Hello Bro: fix new Discord bug
      reports" and set its permission mode (or press "Run now" once and approve), so it doesn't stop to ask. Fixes go live only after you say so.
- [ ] **The Claude API key ends around 8 Dec 2026** (30 days). After that the bug helper asks with a fixed checklist; a new key keeps the smart questions.
- [ ] **Restart your play server** (`Hello Bro Locked Server\START-SERVER.bat`) after an update: close its window, then double-click it again.
- [ ] **Your domain** ninjaonlinereborn.com (Namecheap): auto-renew is on; it renews around **8 Nov 2027** for about €14. Keep a working card
      on Namecheap, or the name expires and someone else can buy it.
- [ ] **If Oracle ever gives the machine a new address:** change it in 2 places: duckdns.org (ninjaonline) and Namecheap (Domain List >
      Manage > Advanced DNS: both A records). I can't do this for you (your accounts), but I'll give you the steps.
- [ ] **Cloud server safety:** Oracle can take back an idle "Always Free" machine. Switching the account to "Pay As You Go" (stays free)
      with a budget alert prevents that. Ask me for the steps when you want it.

### Website (when you have 10 minutes)
- [ ] **E-mail address** contact@ninjaonlinereborn.com that lands in your Gmail: Namecheap's free Email Forwarding (the website session gave you the click steps).
- [ ] **Google Search Console:** prove the site is yours with one DNS record at Namecheap, so Google lists it (click steps from the website session).

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
- [ ] Fragments for the 65 god cards that can't get any in the game now (for example in the Ninja Test shop): you haven't decided yet.
- [ ] Website: anything you want changed on ninjaonlinereborn.com (the website session handles it).
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
