# Download, host your own server, and play

This guide is for anyone with access to this repository who wants to run **their own** Hello Bro server on a
Windows PC and play on it with friends. It takes about 15 minutes.

## 1. Download
1. Open the repository on GitHub: https://github.com/Djassie18698/hello-bro-revival
2. Green **Code** button, then **Download ZIP**. Unzip it somewhere easy, for example `Desktop\HelloBroServer`.
3. Open the **Releases** page (right side of the repo page, or
   https://github.com/Djassie18698/hello-bro-revival/releases/tag/tailscale-play) and download
   **HelloBro-Tailscale-100.111.115.0.xapk**. Put it in the unzipped folder (leaving it in Downloads works too).

## 2. Pick how players reach you
- **Tailscale (easiest, private):** install https://tailscale.com/download, log in, and invite your friends to your
  tailnet. Your address is shown in the Tailscale app (100.x.x.x).
- **Same Wi-Fi only:** your PC's local IP (`ipconfig` shows it as IPv4 Address, like 192.168.1.20).
- **Open to the internet:** see `public-template/docs/HOSTING.md` (playit.gg, a cloud server, or port forwarding).

## 3. Set up (one time)
Double-click **HOST-MY-SERVER.bat**. It:
1. installs Node.js, Python and Java if they're missing (if it installs something, close the window and run it again),
2. picks up your Tailscale address automatically, or asks you for one,
3. makes **HelloBro-for-YOUR-ADDRESS.xapk** in the folder. This is the game that connects to *your* server,
4. opens port 18080 in the Windows firewall (click Yes when Windows asks).

## 4. Start the server
Double-click **START-SERVER.bat** and leave that window open while people play.
Your server starts empty, with its own save (`hellobro.db` in the folder). Nobody else's save comes with the download.

## 5. Play
- Everyone, including you, installs **BlueStacks 5** and drags **HelloBro-for-YOUR-ADDRESS.xapk** onto it.
- Open Hello Bro, press **START** and create a character.
- When the game says **"confirm update?"**, tap Confirm. That loads the game fixes from your server.

## Admin page
http://localhost:18080/admin, on the server PC: give gold, items or characters, set levels, and **reset a player** to start over.

## Problems
| Problem | Fix |
|---|---|
| "network error" / stuck loading | Is START-SERVER.bat running? Are you and the player on the same Tailscale network? Did step 3.4 (firewall) run? |
| Your address changed | Run HOST-MY-SERVER.bat again and give players the new xapk. |
| "No Hello Bro .xapk found" | Download the xapk from Releases (step 1.3) into the folder. |
| Installing over an older version fails | Uninstall Hello Bro in BlueStacks first, then drag the new xapk. |

## Updating
Download the newest ZIP from GitHub and copy your `hellobro.db` into it (that's your save). Then start the server again.
