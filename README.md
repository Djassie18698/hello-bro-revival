<div align="center">

# 🍥 Hello Bro: Revival

**A fan-made replacement server that brings the dead mobile game *Hello Bro / Ninja Online* back to life.**

*Naruto-themed card RPG · 2015 · Cocos2d-x + Lua · v28.0*

![server](https://img.shields.io/badge/server-Node.js-3c873a?style=for-the-badge)
![game](https://img.shields.io/badge/game-Android%20v28.0-blue?style=for-the-badge)
![status](https://img.shields.io/badge/status-playable%20%26%20testing-orange?style=for-the-badge)
![repo](https://img.shields.io/badge/repo-public-brightgreen?style=for-the-badge)

**Goal: play exactly like the original, with friends, for free.**

<br>

<a href="https://discord.gg/2Cbp4UDHrU"><img src="https://img.shields.io/badge/JOIN%20OUR%20DISCORD-Bugs%20%C2%B7%20Help%20%C2%B7%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join our Discord" height="56"></a>

*Report bugs, get help installing, and play with the community.*

</div>

---

## ✨ What works

| | | |
|---|---|---|
| 🥷 **Cards & team** with chains that turn red when active | 🎰 **Recruit** with free timers and a pity counter | 🗺️ **Training** in parts, bosses, drops, reward wheel |
| ⚔️ **Spar, Arena, Battles, War, Border war** | 🎁 **Daily tasks, sign-in, login & level gifts, top-up rewards** | 🐾 **Pets, Seals, Breakthrough, Ninja Test** |
| 🏯 **Base buildings, guilds (Akatsuki)** | 👑 **VIP, shop, mystery shop, events** | 🛠️ **Admin page**: give anything or everything, inventory, reset |
| 🖥️ **Control panel** (one site): server status, events on/off, banner, backups, restart, players & items, **team builder** | ♻️ **Reincarnation up to 8**, sage growth with the original chances | 🧪 **Shinobi training** with Super Ninja Pills like the original |
| 🚪 **Eight Gates** with levels (LV1-150) | 🎫 **Scratch card, treasure chests, Growth Fund, group purchase, total-recharge gifts, Time limited GiftPack, Akatsuki mall** | 📷 Numbers checked against **~3 580 photos** of the original game |

Every number that came from the game's own data is kept as it was. Where the original value was lost on the dead server we picked one and marked it **(ours)** in the code and in the docs.

---

## 🚀 Play in 5 minutes

> You need a Windows PC and **BlueStacks 5**.

1. **Get the files:** *Code → Download ZIP*, unzip to e.g. `Desktop\HelloBroServer`
   (or use the zip your host sent you).
2. **Get the game file:** from the [Releases page](https://github.com/Djassie18698/hello-bro-revival/releases) download `HelloBro-base-host-your-own.xapk` (the base game; `HOST-MY-SERVER.bat` makes your own copy from it).
3. **Set up once:** double-click `HOST-MY-SERVER.bat`.
4. **Start the server:** double-click `START-SERVER.bat` and keep the window open. The **Server Manager** opens in your browser
   (events, who is online, restart).
5. **Play:** drag the made `.xapk` onto BlueStacks, open the game, press **START**.

Details and troubleshooting: [`HOST-YOUR-OWN-SERVER.md`](HOST-YOUR-OWN-SERVER.md) · playing on someone else's server: [`PLAY-ON-TAILSCALE.md`](PLAY-ON-TAILSCALE.md)

### 🥷 Your own playthrough (just you, on your own PC)

Want a world of your own? The server and the game run on the same PC, nothing to forward, no Tailscale.

1. *Code → Download ZIP* and unzip it, e.g. to `Desktop\HelloBroServer`.
2. From the [Releases page](https://github.com/Djassie18698/hello-bro-revival/releases) download `HelloBro-base-host-your-own.xapk` (the base game; `HOST-MY-SERVER.bat` makes your own copy from it) into that folder.
3. Double-click **`HOST-MY-SERVER.bat`**. When it asks for an address, **just press Enter** (it uses your own PC's address). It makes `HelloBro-for-<your address>.xapk`.
4. Double-click **`START-SERVER.bat`** and leave the window open.
5. Install **BlueStacks 5**, drag your `HelloBro-for-….xapk` onto it, open the game. The account window picks **Play** by itself (it remembers you), then press **START** and create your ninja.

Your save is `hellobro.db` in the folder: yours alone, kept safe by backups in `backups\`. The admin page (http://localhost:18080/admin) can give gold or reset your character.
Friends on the same Wi-Fi can join with the same `.xapk`.

### 🌍 Join the public server

Play with everyone on the official server: download **`HelloBro-ninjaonline.xapk`** from the [Releases page](https://github.com/Djassie18698/hello-bro-revival/releases), drag it onto BlueStacks 5, open the game and press **START**. The game remembers your phone; to use your account on another phone tap **Change > Login with Gumptech > Signup** and pick a name and password.

### 🔄 Getting the newest fixes

Close the server window, double-click **`UPDATE.bat`** (first time it installs the GitHub tool and asks you to log in), start the server again and tap **Confirm** in the game. Your save is never touched.

---

## 🐞 Found a bug?

**Quickest:** post it in our [Discord](https://discord.gg/2Cbp4UDHrU) with a screenshot.

Open an issue with the **Bug report** template: [new issue](https://github.com/Djassie18698/hello-bro-revival/issues/new/choose).
Or add a comment with a screenshot and one line to the running lists:

- [Bugfix List 1](https://github.com/Djassie18698/hello-bro-revival/issues/2)
- [Bugfix List 2](https://github.com/Djassie18698/hello-bro-revival/issues/3)
- [Bugfix List 3](https://github.com/Djassie18698/hello-bro-revival/issues/4) · [Bugfix List 4](https://github.com/Djassie18698/hello-bro-revival/issues/5)

📋 **What's fixed and what's still open:** [docs/PROGRESS.md](docs/PROGRESS.md) (also the **Progress** tab of the control panel).

What is still open is listed in [`docs/OPEN-ISSUES.md`](docs/OPEN-ISSUES.md).

A good report says **where** it happened, the **taps**, what **should** happen, what **did** happen, and a **screenshot**.

---

## 📜 What changed recently

- **2 Nov 2026 (later):** **real login**: the game's account window now logs in on our own server (no more Gumptech), remembers your phone (Play as guest) and can sign up a name + password to move to another phone; the official public server **ninjaonline** (game file on the Releases page), and a guide for solo playthroughs. Needs the new game file from the Releases page.
- **2 Nov 2026:** all ~3 580 photos of the original game read; Save time, Ninja Test, arena rewards, Ninja Treasure, secret shop refresh and shop prices now use the original numbers, new **Growth Fund**, **change country**, **Great gift for total recharge** and **Time limited GiftPack** with the original rewards, daily spending gift and recharge streak; monthly sign-in, top-up packages, Akatsuki, country war, spar and Element Change balanced to the original photos:
  [**`docs/FIXES-2026-11-02.md`**](docs/FIXES-2026-11-02.md).
- **1 Nov 2026:** holiday and limited events (**Christmas** with the original trades, New Year, God Recruit, Hot Treasure, Gold spending, Diligence gift, Limited discount, Lottery), card stats exactly like the game, a **team builder**, everything in one **control panel**, the ramen window when out of energy, new **Server Manager** (events on/off, announcement, who is online, backups, restart), rebirth up to 8, sage growth with the original chances, Shinobi training crash fixed,
  chapters open after the last boss, a **Join Discord** button in the game's Settings and the Discord link in the top banner, chains for God cards, soul refinery, Akatsuki buildings, admin edits item amounts, quicker return to Home, long ninja names fit their box:
  [**`docs/FIXES-2026-11-01.md`**](docs/FIXES-2026-11-01.md).
- **31 Oct 2026:** the big fix day (training in parts, fights that don't crash, chains, rewards, recruits, daily tasks and more):
  [**`docs/FIXES-2026-10-31.md`**](docs/FIXES-2026-10-31.md).

---

## 🗂️ Project map

| Path | What |
|---|---|
| `server.js`, `handlers.js`, `game.js` | the HTTP server, one function per game screen/endpoint, the core game rules |
| `manager.js` + `manager.html`, `settings.js` | the Server Manager page (`/manager`) and the server-wide settings (events on/off, announcement) |
| feature files (`exam.js`, `pet.js`, `war.js`, `sevenday.js` …) | one module per feature |
| `data/` | the game's own tables (cards, stages, drops, chains …) |
| `reference/lua-scripts/` | the game's own screens (read-only reference) |
| `cdn/` | hot updates the server pushes to every phone |
| `tools/` | test, build and emulator helpers |
| `docs/` | notes: [`NEXT-STEPS.md`](docs/NEXT-STEPS.md) (technical log), [`BASE-FEATURES.md`](docs/BASE-FEATURES.md), [`HOT-UPDATE.md`](docs/HOT-UPDATE.md) |
| `CLAUDE.md` | start-here guide for the AI helper that maintains the project |

---

## ⚠️ Good to know

- This repository is **public** and shared with friends. It also contains the game files and the signing key, so nothing personal or secret may ever be put in it.
- `hellobro.db` is the save of **your** server; it is never uploaded.
- Top-ups cost nothing, but they count for VIP and the top-up rewards.
- Some things are still open (opening scene skip, 10-pull zoom, silver shown on the victory card). See the last chapter of the fix document.

<div align="center">

*Made for fun, for friends, for a childhood game.* 🍜

</div>
