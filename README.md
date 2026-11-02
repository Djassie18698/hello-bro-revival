<div align="center">

# 🍥 Hello Bro: Revival

**A fan-made replacement server that brings the dead mobile game *Hello Bro / Ninja Online* back to life.**

*Naruto-themed card RPG · 2015 · Cocos2d-x + Lua · v28.0*

![server](https://img.shields.io/badge/server-Node.js-3c873a?style=for-the-badge)
![game](https://img.shields.io/badge/game-Android%20v28.0-blue?style=for-the-badge)
![status](https://img.shields.io/badge/status-playable%20%C2%B7%20bug%20fixing-brightgreen?style=for-the-badge)
![bug lists](https://img.shields.io/badge/bug%20lists%201--4-48%20fixed-success?style=for-the-badge)
![update](https://img.shields.io/badge/game%20update-28.0.32-informational?style=for-the-badge)

**Goal: play exactly like the original, with friends, for free.**

<br>

<a href="https://discord.gg/2Cbp4UDHrU"><img src="https://img.shields.io/badge/JOIN%20OUR%20DISCORD-Bugs%20%C2%B7%20Help%20%C2%B7%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join our Discord" height="56"></a>

*Report bugs, get help installing, and play with the community.*

</div>

---

## 📍 Where it stands

**Every screen of the game works.** All four bug lists are done (48 fixed, 2 can't be fixed from the server), and new
reports are fixed as they come in. Fixes reach your game by themselves: tap **Confirm** when it asks for an update.

---

## ✨ What works

| | | |
|---|---|---|
| 🥷 **Cards & team** (two line-ups) with chains that turn red when active | 🎰 **Recruit** with free timers and a pity counter | 🗺️ **Training** in parts, bosses, drops, reward wheel |
| ⚔️ **Spar, Arena, Battles, War, Border war, Cross-server battle** | 🎁 **Daily tasks, sign-in, login & level gifts, top-up rewards** | 🐾 **Pets, Seals, Breakthrough, Ninja Test** |
| 🏯 **Base buildings, guilds (Akatsuki)** | 👑 **VIP, shop, mystery shop, events** (festivals, God of Wealth, Flower Worship, Month card) | 🛠️ **Admin page**: give anything or everything, inventory, reset |
| 🖥️ **Control panel** (one site): server status, events on/off, banner, backups, restart, players & items, **team builder** | ♻️ **Reincarnation up to 8**, sage growth with the original chances | 🧪 **Shinobi training** with Super Ninja Pills like the original |
| 🚪 **Eight Gates** with levels (LV1-150), ⭐ **Limited Super Ninja** (a new god card every hour) | 🎫 **Scratch card, treasure chests, Growth Fund, group purchase, total-recharge gifts, Time limited GiftPack, Akatsuki mall** | 📷 Numbers checked against **~3 580 photos** of the original game |

Every number that came from the game's own data is kept as it was. Where the original value was lost on the dead server we picked one and marked it **(ours)** in the code and in the docs.

---

## 🖱️ Which file do I click?

Everything you need is in the top folder. The rest is in sub-folders you don't have to open.

| File | When |
|---|---|
| **`HOST-MY-SERVER.bat`** | Once: sets up your server and makes the game file (`HelloBro-for-<address>.xapk`) that connects to it |
| **`START-SERVER.bat`** | Every time you play: runs the server (keep the window open) |
| **`UPDATE.bat`** | Gets the newest fixes (close the server first). Your save is never touched |
| **`INSTALL-WITH-USB.bat`** | The game won't install on a phone or tablet? Install it from your PC with a USB cable or over Wi-Fi |
| **`OPEN-FIREWALL.bat`** | Phones or friends can't connect: opens port 18080 (run as admin) |

Folders: `server` (the server itself and the game's data), `tools` (helpers), `docs` (guides and notes), `discord` (the Discord bot), `release` (the signing key).

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

Details and troubleshooting: [`docs/HOST-YOUR-OWN-SERVER.md`](docs/HOST-YOUR-OWN-SERVER.md) · playing on someone else's server: [`docs/PLAY-ON-TAILSCALE.md`](docs/PLAY-ON-TAILSCALE.md) · game won't install on a phone: [`INSTALL-WITH-USB.bat`](INSTALL-WITH-USB.bat)

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
- [Bugfix List 3](https://github.com/Djassie18698/hello-bro-revival/issues/4) · [Bugfix List 4](https://github.com/Djassie18698/hello-bro-revival/issues/5) · [Bugfix List 5](https://github.com/Djassie18698/hello-bro-revival/issues/6) (new reports go here)

📋 **What's fixed and what's still open:** [docs/PROGRESS.md](docs/PROGRESS.md) (also the **Progress** tab of the control panel).

A good report says **where** it happened, the **taps**, what **should** happen, what **did** happen, and a **screenshot**.

---

## 📜 What changed recently

| Day | What |
|---|---|
| **2 Nov 2026** | New event **Limited Super Ninja** ("Super Ninja" on Home): every god card takes a turn, a new one every hour, with a points ranking and prizes. Big test round with no new bugs found. The **second team** (Team 2, from level 100), **battle reports** and friend messages in News, all **25 Battles chapters** with floor rewards, the Arena **Exchange** with its real limits, **Akatsuki leader tools**, **war rankings**, an **Award Center** to send gifts from the control panel, the **Anniversary festival**, daily task chests like the original, **War open all day**, the real **silver** on the Victory screen, **real login** (play as guest or sign up to move phones), the public server **ninjaonline**, and new events (Sign-in streak, God of Wealth, Month card, Flower Worship). Items, gift packs and VIP gifts give what their text says. The Discord bot now shows as online. [Full list](docs/FIXES-2026-11-02.md) |
| **1 Nov 2026** | The **cross-server battle**, **elements in fights** (Water > Fire > Wind > Thunder > Earth > Water), real players fight with their real team, holiday and limited events (Christmas, New Year, God Recruit, Hot Treasure, Lottery and more), card stats exactly like the game, the **team builder** and one **control panel**, Server Manager, rebirth up to 8, sage growth with the original chances, a **Join Discord** button in the game's Settings. [Full list](docs/FIXES-2026-11-01.md) |
| **31 Oct 2026** | The big fix day: training in parts, fights that don't crash, chains, rewards, recruits, daily tasks and more. [Full list](docs/FIXES-2026-10-31.md) |

Every fix one by one, and what is still open: [**docs/PROGRESS.md**](docs/PROGRESS.md).

---

## 🗂️ Project map

| Path | What |
|---|---|
| `server/server.js`, `server/handlers.js`, `server/game.js` | the HTTP server, one function per game screen/endpoint, the core game rules |
| `server/manager.js` + `manager.html`, `settings.js` | the Server Manager page (`/manager`) and the server-wide settings (events on/off, announcement) |
| feature files (`server/exam.js`, `pet.js`, `war.js`, `sevenday.js` …) | one module per feature |
| `server/data/` | the game's own tables (cards, stages, drops, chains …) |
| `server/reference/lua-scripts/` | the game's own screens (read-only reference) |
| `server/cdn/` | hot updates the server pushes to every phone |
| `tools/` | test, build and emulator helpers |
| `docs/` | [`PROGRESS.md`](docs/PROGRESS.md) (every bug and its state), `FIXES-<date>.md` (plain-words fix days), [`NEXT-STEPS.md`](docs/NEXT-STEPS.md) (technical log), [`BASE-FEATURES.md`](docs/BASE-FEATURES.md), [`HOT-UPDATE.md`](docs/HOT-UPDATE.md), `history/` (old plans) |
| `discord/` | the Discord bot: guides, channel layout, keep-online |
| `.bat` files (top folder) | `HOST-MY-SERVER.bat` (setup), `START-SERVER.bat` (run), `UPDATE.bat` (get the newest fixes), `INSTALL-WITH-USB.bat` (install on a phone from the PC), `OPEN-FIREWALL.bat` |
| `CLAUDE.md` | start-here guide for the AI helper that maintains the project |

---

## ⚠️ Good to know

- This repository is **public** and shared with friends. It also contains the game files and the signing key, so nothing personal or secret may ever be put in it.
- `hellobro.db` is the save of **your** server; it is never uploaded.
- Top-ups cost nothing, but they count for VIP and the top-up rewards.
- A few things live inside the game app itself and can't be changed from the server (opening scene skip, the 10-pull zoom). They are listed in [docs/PROGRESS.md](docs/PROGRESS.md).

<div align="center">

*Made for fun, for friends, for a childhood game.* 🍜

</div>
