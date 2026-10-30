# Hello Bro Discord manager bot

You type what you want in plain English, the bot (powered by Claude) does it in your Discord server.

> "Add a tutorial on how to install the project in #tutorial"
> "Update the gacha tutorial, the wheel now gives a jackpot"
> "Post an announcement that the server is back online"

It can read channels, post, edit and delete **its own** messages, and read the project docs (README, docs/*.md) so tutorials are based on real information. It cannot touch other people's messages, ping @everyone, or post passwords / API keys / IP addresses (those are blocked in code).

## One-time setup (about 10 minutes)

1. **Create the bot:** https://discord.com/developers/applications -> New Application -> *Bot* tab.
   - Click *Reset Token*, copy it (this is `DISCORD_TOKEN`; treat it like a password).
   - Under *Privileged Gateway Intents* turn on **Message Content Intent**.
2. **Invite it:** *OAuth2 -> URL Generator*, tick scopes `bot`, then permissions *View Channels, Send Messages, Read Message History, Manage Messages* (Manage Messages is only needed to delete its own old posts; you can skip it). Open the generated link and add the bot to your server.
3. **Your Discord user id:** Discord Settings -> Advanced -> Developer Mode on, then right-click your name -> *Copy User ID*. This is `OWNER_IDS`; only you (and anyone you list) can give orders.
4. **Claude API key:** https://console.anthropic.com -> API keys (`ANTHROPIC_API_KEY`). Usage is billed per request, tutorials cost a few cents.
5. In this folder: copy `.env.example` to `.env`, fill in the three values, then
   ```
   npm install
   node --env-file=.env bot.js
   ```
   Leave that window open. The bot is only online while it runs.

Never commit `.env` (it is git-ignored) and never paste the token or key into chat or Discord. If one leaks, reset it in its dashboard.

## Using it
- In the server: **@HelloBroBot add a tutorial on how to install the project in #tutorial**
- Or set `CONTROL_CHANNEL=bot-control` in `.env` and just type there, no mention needed.
- Or DM the bot.
- Follow-ups work ("make it shorter", "also add a troubleshooting section").

From a terminal (same brain, no Discord chat needed):
```
node --env-file=.env cli.js "Add a tutorial on how to install the project in #tutorial"
node --env-file=.env cli.js --dry "..."    # shows what it WOULD do, changes nothing
node --env-file=.env cli.js --fake "..."   # no Discord token: tries it on an in-memory fake server
```
Try `--dry` or `--fake` first. Better still, try the bot on a spare test server before your real one.

## Cost / model
Default model is `claude-opus-5-5` (best quality). For a cheaper bot set `CLAUDE_MODEL=claude-sonnet-5-5` or `claude-haiku-5-5` in `.env`.

## Files
`bot.js` Discord connection + owner check, `agent.js` the Claude tool loop, `tools.js` what the bot may do and the safety rules, `adapter.js` Discord/fake server glue, `test.js` offline tests (`npm test`).

## Not tested against live Discord/Claude yet
The logic is covered by `npm test` (scripted fake Claude, fake Discord). The first real run may need small fixes.
