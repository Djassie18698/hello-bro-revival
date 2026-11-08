# Product

<!-- impeccable:product-schema 1 -->

Scope: the public website **Ninja Online Reborn** at https://ninjaonlinereborn.com: the home page (`server/site/`) and the
wiki (`server/wiki/`). The game server, its control panel (`panel.html`, `admin.html`, `manager.html`) and the game app
itself are other products and are not described here. Kept in `server/` because the owner wants only the .bat files,
README.md and CLAUDE.md in the top folder, and because Caddy publishes everything inside `server/site` and `server/wiki`.

## Platform

web

## Users

All of these equally (owner, 8 Nov 2026):
- **Old players** who played Hello Bro / Ninja Online years ago and are looking for it again.
- **New players** who never played and need a reason to try it.
- **Current players** on the public server who come back for the wiki, the news and help.

Many players use phones; others play in BlueStacks on a PC. The site must work at both sizes.

## Product Purpose

Bring people into the revived game. The main thing a visitor should do on the home page is **download the game and play**
on the public server (owner, 8 Nov 2026). Joining Discord (help, news, community) and using the wiki (looking things up)
come next. Success = a visitor downloads the game file, installs it and plays.

## Positioning

The 2015 Android ninja card game (known as **Hello Bro** and **Ninja Online**, among other names; package
`com.hello.bro.yo`) runs again on a replacement server built by its own players, **exactly like the original**: the same
cards, story, events and prices, with top-ups free. Everything on the site comes from the game itself: art cut from the
game files, names and numbers from its own tables, screenshots taken in the game.

## Operating Context

- The download is one file, `HelloBro-ninjaonline.xapk` (~127 MB), from the GitHub release `tailscale-play`; it connects
  to the public server `ninjaonline.duckdns.org:18080` by itself. PC: BlueStacks 5, drag the file in. Phone: from a PC
  with a USB cable and `INSTALL-WITH-USB.bat`. Install guide: `/wiki/#/guides/install-help`.
- Help and news live in Discord: https://discord.gg/2Cbp4UDHrU (the permanent invite; use it everywhere).
- The live line on the home page reads the game server's `/status` (online now, characters so far).
- News on the home page and in the wiki comes from README "What changed recently" (`node tools/build_wiki.js`).
- Hosting: static files served by Caddy on the Oracle cloud machine straight from the git checkout; how to change and ship
  the site is in CLAUDE.md section 6.
- The owner (Djassie) is not a developer: changes are explained in plain words and shown as screenshots.

## Capabilities and Constraints

- Home page sections: hero (logo, Play, Join Discord, wiki link, live status), what the game is, features + original event
  posters, god cards, screenshots, story chapters, how to play (3 steps), news, Discord, footer.
- Wiki: every shinobi, gear, ninjutsu, seal, pet, item, set, training stage and the guides, built from the game's tables.
- Static HTML/CSS/JS, no framework, no build step besides the data/picture scripts. Fonts from Google Fonts.
- Free and non-commercial: no money, no ads, nothing that looks like selling.
- Keep "Naruto" and "Konoha" out of names and titles (copyright caution, owner 8 Nov 2026).
- No "fan project, not affiliated" footer notice for now (owner: "not now"). The footer says "A free fan revival of
  Hello Bro / Ninja Online (2015), made by its players."
- Respect reduced motion; no sideways scrolling at phone width.

## Brand Commitments

- Name: **Ninja Online Reborn** (domain ninjaonlinereborn.com). The game's own names: Hello Bro, Ninja Online.
- Logo: the owner's NINJA ONLINE picture in the original Hello Bro logo style, `server/site/img/logo-ninjaonline.webp`
  (source on the owner's PC: Pictures/Ninja Online Logo.png), with REBORN under it. The original Hello Bro logo
  (`img/logo-hellobro.webp`) shows the game's old name.
- Voice: **like the old game**, hyped and official like its own ads, posters and event banners (owner, 8 Nov 2026), but
  never generic marketing or "AI-sounding" template copy (owner, 8 Nov 2026: "make it look a little less A.I."). No
  small labels above every heading, no slogan pile-ups.
- The owner loved https://platinumtogether.online as a reference for the home page (big game scene, chunky logo, big
  Play button).

## Evidence on Hand

- Game art from the original files (`re/obb`, made by `tools/setup_re.py`): card pictures (`npc/*.pvr.ccz`), backgrounds,
  the 7 original event posters (`advertise1-7`), 19 story chapter banners, the Hello Bro logo. Built by
  `tools/build_site_art.py` into `server/site/img/`.
- Five emulator screenshots (`server/site/img/shot-*.webp`).
- Real numbers from the game's tables (493 shinobi, 1 234 story stages, 91 ninjutsu) and the live `/status` counts.
- README news, the Discord guides (`discord/guides/*.md`).
- Not on hand, never invent: player reviews or testimonials, download counts, player totals beyond `/status`, press,
  any affiliation with the original makers.

## Product Principles

1. **Download and play first.** Every page should make the way into the game obvious and short.
2. **Only what the game really is.** Art, names and numbers come from the game; no invented claims, quotes or stats.
3. **Just like the original stays true.** The site promises the original game; it never advertises "improvements".
4. **Free, for real.** Nothing on the site asks for money or looks like a shop.
5. **Sound like the game, not like a template.** Hyped like the old posters, in plain words a player would write.
