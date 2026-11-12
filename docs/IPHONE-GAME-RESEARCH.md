# Can iPhone players play the game? (research, 12 Nov 2026)

The owner asked: "research how possible it would be to remake the full app for iPhone users".
This is about the **game** itself. The control panel already has an iPhone app (`tools/ios-panel`).
Nothing was built for this report. It only looks at what exists and what each route would take.

## The short answer

- iPhones **cannot run the Android game file**. There is no way around that on a normal iPhone (see route E).
- The original game **did come out on iPhone** in 2014-2015, in China and Thailand. Two original Chinese
  iPhone files (IPA) are still saved on the Wayback Machine. **Checked on 12 Nov 2026 (section 1b): both are
  32-bit only, so they can't run on any iPhone made to run iOS 11 or newer (2017 on).** That door is closed.
- So the only real way is to **rebuild the part of the game that lives in C++**.
  About a third of the game (the core screens and the fights) is C++. That is months of work, not weeks.
- The server never has to change much: every route talks to the same server the Android app uses.

## 1. Did the original ever ship for iPhone?

**Yes, but not as "Hello Bro".**

| What | Evidence |
|---|---|
| The Chinese original 《火影大人》 (XCKOO / ZQGame) was on the Chinese App Store from **10 Sep 2014** (jailbroken iPhones even earlier) | Baidu Baike and the official site, in `docs/WEB-RESEARCH-2026-11-07.md` section 1 |
| The Thai version "Ninja Online" (publisher Gumptech) was on the Thai App Store, ids **908978944** and **887308071**. Gumptech ran ads called "NinjaOnline_FB_iOS" in Oct 2014 | same file, section 1 |
| A 2015 YouTube video is titled "Ninja Online [Android / iOS] Gameplay" | same file, section 8 |
| Our own Android game still carries iPhone parts: `LoginViewAppStore.ccbi`, `LogoSceneAppStore.ccbi`, `BindAccountViewForAppStore.ccbi`, `GameSettingApple.ccbi`; the Lua asks `GetPlatformStr() == "IOS"` (`util/common.lua` line 57) and has an App Store price list (`ui_purchaseLayer.lua`, node `rechargeioslist`) | files in `re/obb/` and `server/reference/lua-scripts/` |
| The English "Hello Bro" (`com.hello.bro.yo`) on iPhone | **nothing found** (web searches for the name and the package gave nothing) |
| App Store today | both Thai ids answer "0 results" in Apple's lookup (checked 12 Nov 2026): removed |

**Original iPhone files that still exist** (Wayback Machine, checked today; not downloaded):

| File | Saved on | Size |
|---|---|---|
| `http://phone.hy.zqgame.com/renlong_zqg.ipa` | 24 Mar 2015 | 74.9 MB |
| `http://phone.hy.zqgame.com/renlong_zqb_.ipa` | 25 Jun 2016 | 79.6 MB |

(Next to them: the Chinese Android files `renlong_android_qg.apk` 2015 and `renlong_zqb_.apk` 2016.)

**Could such a file be pointed at our server?** Probably yes, if it is the right kind of file:
- The publisher handed these out from its own website, not the App Store. Files like that are usually
  **not locked** (App Store downloads are encrypted and can't be changed; these normally aren't).
- On Android the server address sits in a small text file inside the app (`assets/baseconfig.json`, which
  `tools/patch_apk.py` rewrites). The iPhone version of the same engine very likely has the same file.
  Change it, then re-sign the file the same way the owner already installs Ninja Panel (Sideloadly or Signulous).
- Old apps (made before iOS 9) may talk plain `http://` to our server without extra settings.

**Will it run on today's iPhones?** What was known before looking inside (the answer is in section 1b: no):
- iPhones stopped running **32-bit** apps in iOS 11 (2017). Apple demanded 64-bit for App Store updates
  from June 2015, so the **2016** file has a fair chance of being 64-bit. The 2015 file probably is not.
- The game draws with OpenGL ES. Apple called OpenGL ES "old" in 2018 but it still works in iOS 26.
  Apple has not said when it goes. That is a risk for every route that keeps the old engine.
- Very old apps open in a "compatibility" box on new screens (black bars). Fine for this game.

**What you would get even if it works:** the **Chinese** game, an older version than our English v28,
with Chinese text and its own tables. The server might need small changes for its replies.
English could perhaps be pushed in with our hot update (section 8 of CLAUDE.md), if the file formats match.

## 1b. The two original iPhone files, checked (12 Nov 2026)

The owner said yes, so both files were downloaded from the Wayback Machine into `re/ipa-wayback/`
(`re/` is never committed) and looked at.

| | 2015 file (`renlong_zqg.ipa`) | 2016 file (`renlong_zqb_.ipa`) |
|---|---|---|
| Name on the phone | 火影大人 (com.xckoo.renlong.zqg) | 火影大人 (com.xckoo.renlong.zqg) |
| Version | 5.0 | 11.0 (our English Android game is v28) |
| Made with | Xcode 5.1, iOS 7.1 | Xcode 7.0.1, iOS 9.0 |
| Runs on iOS from | 5.0 | 5.0 |
| **64-bit?** | **No: 32-bit ARM (armv7) only** | **No: 32-bit ARM (armv7) only** |
| Locked (App Store encryption)? | No (cryptid 0) | No (cryptid 0) |
| Server address | `baseconfig.json`, `http://203.195.181.135:8080` (same file and same fields as our Android `assets/baseconfig.json`) | same, a list with "release server" first |
| Same game as ours? | 624 of our C++ classes are in it; 55 of its 63 server endpoints are the same as in our C++; all 153 of its Lua files have the same names as ours | 638 of our C++ classes; 56 of 64 endpoints the same; 324 of its 339 Lua files have the same names as ours |
| Function names kept? | Yes (242 088 symbols) | Yes (257 163 symbols) |

**What this means:**
- The files are **not locked**, and the server address is easy to change. That part was as hoped.
- But **neither has a 64-bit part.** iOS 11 (2017) and newer refuse 32-bit apps. Every iPhone sold since
  the iPhone 8 / X (2017) started on iOS 11 or newer and can't go back. So **no modern iPhone can run them**.
- Only an old iPhone that was **never updated past iOS 10** (iPhone 4s, 5, 5c, or a 5s / 6 / 6s / SE / 7
  left on iOS 10) could run them, after changing the address and re-signing. Hardly anyone still has one,
  and it would be the older Chinese game.
- Changing the 32-bit machine code into 64-bit machine code automatically is a research problem, not something
  to try for a hobby project.
- **Useful for later:** these are the same game in a second machine language, with the function names kept.
  If a rebuild ever starts (route B or C), they help to double-check what the Android C++ does.

## 2. How much of the game would have to be rebuilt?

Counted in the Android game (`re/obb`, `server/reference/lua-scripts`, `re/all.txt`):

| Part | Size | Re-usable on iPhone? |
|---|---|---|
| Pictures (1 695 `.ccz` sprite sheets, 1 996 `.plist`, 144 `.png`), 30 fonts, 28 sounds | 128 MB in total | **Yes**, as they are (a web version would turn them into WebP first, like the wiki already does) |
| Screen layouts (`.ccbi`) | 735 files | **Yes** (our `tools/ccbi.py` already reads them) |
| Lua scripts (the event screens, most feature screens) | 374 files, about 80 000 lines; they call **124** server endpoints | **Yes**, but they lean on game parts made in C++ (`CPlayerDataMgr` 401 times, `CGameObjElement` 275, `LuaTableView`/`LuaEventHandler` 115 each, `CSoundMgr` 110, `CTradeMgr` 49, `CNetUser` 33) and on 57 cocos2d classes. Those must exist again. |
| Game tables (`tables.bin`) | all the numbers and texts | **Yes** (our `tools/mbs.py` already reads them) |
| C++ game code in `libgame.so` (no source code exists, only the 32-bit ARM machine code) | **233 game classes**, about 9 900 functions, 1.3 MB of machine code; **144 of the classes are screens** (views, dialogs, menus); it calls **69** server endpoints plus 3 login ones | **No.** It must be rewritten by reading the machine code. |
| The cocos2d-x 2 engine, Lua 5.1, tinyxml, zip, png | the rest of `libgame.so` | Not needed: free, public, ready for iPhone |

**What lives in that C++ part** (the most important screens): login and server select, the home menu, the
team screen, backpack and card views, card and gear details, upgrade / strengthen / potential / rebirth,
training chapters and stages (`CSectionCellView`, `CRunLevelView`), **the whole fight show**
(`CRoundTeamFightView`, `CRoundFightAnimView`, `CNewFightCardView`, `CFightResultData`, the win / lose screens),
arena, country war, the shop and buy dialogs, and the table loader (`CFileTableCache`, `CTableCache`) that
everything else uses.

**Good news:** fights are worked out **by our server** (`game.battleXml`). The app only plays them back.
So a rebuild has no game rules to copy, only screens and animations. And we already know every reply the
app expects, because the server answers all of them today.

**Bad news:** the core of the game is all in that C++ part. Without it, nothing starts.

## 3. The ways to do it

### Route A: wake up the original Chinese iPhone file
**Checked and closed (section 1b):** both files are 32-bit only. They would only run on an old iPhone left on
iOS 10 or older. The plan was: change the address in `baseconfig.json` to `ninjaonline.duckdns.org:18080`,
re-sign, sideload, then push English through the hot update. The first two steps would work; the phone
refuses the app.

### Route B: rebuild the app for iPhone with cocos2d-x
Rewrite the 233 C++ classes in new C++ on cocos2d-x (the same engine family), keep all Lua, layouts,
pictures and tables. Build it on GitHub's free Mac computers, the way `.github/workflows/ios-panel.yml`
already builds Ninja Panel. A newer, maintained branch of the engine (cocos2d-x 3.17 or its follow-up
**axmol**) can build the **same code** for iPhone, **64-bit Android** and the **web** at once. That would also
fix the 64-bit Android phones that today need VPhoneOS. (To check: whether that newer engine still reads
`.ccbi` layouts, and how much the Lua must change for its renamed classes.)

### Route C: a web version that runs in Safari
Same rewrite, but in JavaScript (or the C++ from route B turned into WebAssembly). Players open a web page on
ninjaonlinereborn.com and tap "Add to Home Screen". No Apple account, no sideloading, works on iPhone,
64-bit Android and PC. The Lua scripts would run in a Lua engine made for browsers. The server's game
addresses would need to go through the website's `https` (Caddy), because Safari blocks plain `http` from an
`https` page.

### Route D: stream a real Android phone to the iPhone
A computer in the cloud runs real Android with the real game. The iPhone only shows the picture in Safari and
sends the taps. For a slow card game, the small delay doesn't matter.
- Paid "cloud phone" services exist (about $5-10 a month per player). Not checked which still run 32-bit
  ARM games.
- Do it yourself: Oracle's free **Ampere** machines (up to 4 cores, 24 GB, free) can run 32-bit ARM code
  natively, with a tool called redroid. Each player needs their own Android copy (about 2-3 GB of memory),
  so only **4-6 players at once**. Not confirmed that redroid runs this 32-bit game there: a test is needed.
  Oracle often says "out of capacity" for these free machines.

### Route E: an Android emulator on the iPhone
**Not possible in practice.** iPhone apps may not use "JIT" (the trick that makes emulators fast). The only
allowed PC emulator, UTM SE, runs without it and is very slow even for old Windows; for an Android phone
running a game it would be unusable. Apple also gives no app access to the iPhone's virtual-machine support.
Jailbreak tricks exist but are not something to ask players to do.

(The other way round, an "iPhone emulator" on a PC like BlueStacks for Android, doesn't exist either. Apple's
iPhone Simulator runs only on a Mac and only runs apps built for it. A Mac with an M1 chip or newer can run real
64-bit iPhone apps, with PlayCover. Programs that call themselves an iOS emulator for Windows are fakes.)

## 4. The routes side by side

| | A: original iPhone file | B: rebuild (cocos2d-x) | C: web version | D: streamed Android | E: emulator on iPhone |
|---|---|---|---|---|---|
| **Will it work?** | **No** on any modern iPhone: both files are 32-bit (checked 12 Nov 2026). Only on an old iPhone left on iOS 10 | Yes, with enough work | Yes, with enough work | Probably (needs a test) | No |
| **Same as the Android game?** | Same game, but Chinese and older; English maybe later | Close copy; small differences will show up and need fixing over time | Close copy; same as B | **Exactly the same** (it is the real app) | - |
| **Claude's work** | 1-2 days to check; then 1-3 weeks to make it play well | About 3-6 months | About 4-7 months | 1-2 weeks | - |
| **Owner's work** | OK the download; test on own iPhone | Lots of testing on iPhone; decisions on small differences | Lots of testing in Safari | Create the Oracle Ampere machine (click-by-click steps) | - |
| **Cost** | Nothing (free Apple ID) or Signulous / a $99/year Apple developer account for easier installs | Same as A | **Nothing** | Nothing (Oracle free tier) or $5-10/month per player for a paid service | - |
| **How players install** | Sideloadly + PC every 7 days with a free Apple ID (max 3 apps), or Signulous (paid), or the owner's $99 account (signed for a year, max 100 iPhones) | Same as A | Open the website, "Add to Home Screen" | Open a web page; book a free slot | - |
| **Bonus** | - | Same code can make a **64-bit Android** app and a web version | Also works on PC and **64-bit Android** | Also works on PC and 64-bit Android | - |
| **Risks** | 32-bit = dead end; Chinese text; OpenGL ES may be dropped by Apple some day | Very long; two apps to keep in step with the server; OpenGL ES (newer engines use Metal) | Very long; easiest to find for the copyright owner (a public web game) | Few players at a time; each player gets a whole Android; free machine may be hard to get | - |

**Things that are true for every route:**
- **Copyright:** the art and the name belong to the game's makers. Every route spreads the same files as the
  Android release already does. The App Store is out of the question (Apple would refuse a Naruto-style game
  from a fan). TestFlight needs Apple's review too: same problem.
- **Apple's sideload limits:** free Apple ID = 7 days, 3 apps, a PC needed to renew. In the EU and Japan,
  AltStore PAL can install apps without a PC, but Apple still has to approve each app there.
- **Keeping in step:** every new server feature that needs the game app to change would have to be done twice
  (Android + iPhone) for routes A and B. Routes C and D don't have that problem (C is updated with the website,
  D *is* the Android app).

## 4b. Started: the web client (12 Nov 2026)

The owner said: "try the rebuild". It started as **route C, a web version**, because it can be built and tested on this PC in a
browser (no Mac needed), works on every iPhone without sideloading, and the same page could later go inside an iPhone app the
way Ninja Panel does. Where it stands is in `server/webclient/README.md`. After the first evening: the login screen, accounts,
character creation and the home screen draw from the game's own files and talk to our server. The big parts left are the Lua
screens, the team / backpack / training / shop screens, and fights.

## 5. Recommendation

1. **Route A is done and closed.** The two original Chinese iPhone files were checked on 12 Nov 2026: both
   are 32-bit only, so no modern iPhone can run them. There is no cheap shortcut.
2. **If a few iPhone friends need to play soon:** try route D (a streamed Android) on a free Oracle Ampere
   machine. Test first that the 32-bit game runs there. It is the only way to the *exact* game on an iPhone
   without months of work.
3. **Only if many players ask for iPhone:** a rebuild. If it comes to that, pick **one C++ rebuild on a modern
   cocos2d-x / axmol** (route B) that builds iPhone, 64-bit Android and a web version from the same code. Plan
   for months. Don't start without the owner deciding it is worth that.
4. Don't spend time on emulators on the iPhone (route E): it can't work.

## Sources

- `docs/WEB-RESEARCH-2026-11-07.md` (publisher, App Store ids, Wayback links), Wayback CDX listing of
  `phone.hy.zqgame.com` (checked 12 Nov 2026), Apple lookup API for ids 908978944 and 887308071 (no results).
- Counts made from `re/all.txt`, `re/obb/` and `server/reference/lua-scripts/` on 12 Nov 2026.
- OpenGL ES still on iOS 26, no removal date: [Apple developer forums](https://developer.apple.com/forums/thread/796543),
  [deprecated in iOS 12](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/BestPracticesforAppleA7GPUsandLater/BestPracticesforAppleA7GPUsandLater.html).
- UTM SE runs without JIT, slow: [AppleInsider](https://appleinsider.com/articles/24/07/14/apple-permits-first-pc-emulator-for-ios-into-the-app-store),
  [Gigazine](https://www.gigazine.net/gsc_news/en/20240716-windows-emulator-utm-se-ios).
- Sideloading limits and AltStore PAL: [Notebookcheck](https://www.notebookcheck.net/These-are-your-options-for-circumventing-the-Apple-App-store-without-a-jailbreak-but-the-risk-may-not-be-worth-it.1138333.0.html),
  [9to5Mac (Japan)](https://9to5mac.com/2025/12/18/following-sweeping-app-store-changes-altstore-pal-launches-in-japan/),
  [AltStore PAL in practice](https://sir-apfelot.de/en/altstore-pal-experiences-58852/).
- Ampere runs 32-bit Android apps natively (vendor claim): [Ampere](https://amperecomputing.com/solutions/arm-native);
  redroid with 32-bit apps not confirmed: [redroid images](https://hub.docker.com/r/erstt/redroid).
- Not confirmed from sources (my own knowledge, check before relying on it): the 100-iPhone limit of a paid
  developer account, that axmol still reads `.ccbi`, that pre-iOS 9 apps may use plain http.
