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

<a href="https://discord.gg/Z7nCMgmcx"><img src="https://img.shields.io/badge/JOIN%20OUR%20DISCORD-Bugs%20%C2%B7%20Help%20%C2%B7%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join our Discord" height="56"></a>

*Report bugs, get help installing, and play with the community.*

</div>

---

## ✨ What works

| | | |
|---|---|---|
| 🥷 **Cards & team** with chains that turn red when active | 🎰 **Recruit** with free timers and a pity counter | 🗺️ **Training** in parts, bosses, drops, reward wheel |
| ⚔️ **Spar, Arena, Battles, War, Border war** | 🎁 **Daily tasks, sign-in, login & level gifts, top-up rewards** | 🐾 **Pets, Seals, Breakthrough, Ninja Test** |
| 🏯 **Base buildings, guilds (Akatsuki)** | 👑 **VIP, shop, mystery shop, events** | 🛠️ **Admin page**: give anything or everything, inventory, reset |

Every number that came from the game's own data is kept as it was. Where the original value was lost on the dead server we picked one and marked it **(ours)** in the code and in the docs.

---

## 🚀 Play in 5 minutes

> You need a Windows PC and **BlueStacks 5**.

1. **Get the files:** *Code → Download ZIP*, unzip to e.g. `Desktop\HelloBroServer`
   (or use the zip your host sent you).
2. **Get the game file:** from the [Releases page](https://github.com/Djassie18698/hello-bro-revival/releases) download `HelloBro-Tailscale-….xapk`.
3. **Set up once:** double-click `HOST-MY-SERVER.bat`.
4. **Start the server:** double-click `START-SERVER.bat` and keep the window open.
5. **Play:** drag the made `.xapk` onto BlueStacks, open the game, press **START**.

Details and troubleshooting: [`HOST-YOUR-OWN-SERVER.md`](HOST-YOUR-OWN-SERVER.md) · playing on someone else's server: [`PLAY-ON-TAILSCALE.md`](PLAY-ON-TAILSCALE.md)

### 🔄 Getting the newest fixes

Close the server window, double-click **`UPDATE.bat`** (first time it installs the GitHub tool and asks you to log in), start the server again and tap **Confirm** in the game. Your save is never touched.

---

## 🐞 Found a bug?

**Quickest:** post it in our [Discord](https://discord.gg/Z7nCMgmcx) with a screenshot.

Open an issue with the **Bug report** template: [new issue](https://github.com/Djassie18698/hello-bro-revival/issues/new/choose).
Or add a comment with a screenshot and one line to the running lists:

- [Bugfix List 1](https://github.com/Djassie18698/hello-bro-revival/issues/2)
- [Bugfix List 2](https://github.com/Djassie18698/hello-bro-revival/issues/3)
- [Bugfix List 3](https://github.com/Djassie18698/hello-bro-revival/issues/4) · [Bugfix List 4](https://github.com/Djassie18698/hello-bro-revival/issues/5)

What is still open is listed in [`docs/OPEN-ISSUES.md`](docs/OPEN-ISSUES.md).

A good report says **where** it happened, the **taps**, what **should** happen, what **did** happen, and a **screenshot**.

---

## 📜 What changed recently

The big fix day (training in parts, fights that don't crash, chains, rewards, recruits, daily tasks and more) is written up in
[**`docs/FIXES-2026-10-31.md`**](docs/FIXES-2026-10-31.md).

---

## 🗂️ Project map

| Path | What |
|---|---|
| `server.js`, `handlers.js`, `game.js` | the HTTP server, one function per game screen/endpoint, the core game rules |
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
