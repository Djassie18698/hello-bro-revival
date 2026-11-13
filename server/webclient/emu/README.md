# Emulator route: the original app in the browser

Started 13 Nov 2026 (owner: "is there no way to just convert the app we have?"). Instead of rebuilding the game's C++ screens by
hand (the folder above), this runs the **original** `libgame.so` unchanged: an ARM emulator written in JavaScript executes the
app's own code, and everything the app asks Android for is answered by the browser. Open `/play/emu/`.

Why it is possible: the app is plain ARMv5TE code ("armeabi": ARM + Thumb-1, no FPU) and imports only 340 functions from the
phone (236 C library, 82 OpenGL ES 2, 21 threads, 1 log).

| File | What |
|---|---|
| `cpu.js` | the processor: ARM + Thumb-1 instructions, the phone's memory, "traps" (addresses that call JavaScript), threads run in turns, the Linux kernel helpers at 0xffff0fxx |
| `elf.js` | Android's linker: loads `libgame.so`, fills in addresses, points imports at traps, lists the 403 start-up functions |
| `sys.js` | the C library and friends in JavaScript: memory, strings, printf / sscanf, files on a virtual file system, time, math (soft-float calling convention), setjmp, pthread |
| `jni.js` | the JNI table (how the C++ calls Java); the Java methods themselves are in `main.js` |
| `gl.js` | OpenGL ES 2 -> WebGL, including "client arrays" copied into a buffer before each draw |
| `net.js` | the app's own libcurl replaced at `curl_easy_*` (browsers have no sockets): requests go to the page's server |
| `jit.js` | often-used code (64 runs) turned into JavaScript blocks with the decoding done once: flags nobody reads left out, registers in local variables, small loops kept inside a block; rare instructions call cpu.js. Same instruction count and results as cpu.js. At most 20 000 blocks (then all are made again). `?jit=0` / `HB_JIT=0` switch it off |
| `fast.js` | the busiest library functions in JavaScript (cut the start from 990 M to 350 M instructions): zlib `inflate_fast`, `crc32`, `adler32`, libpng `png_read_filter_row`, 64-bit division, the `__sync_fetch_and_add/sub` of std::string, CCImage's alpha loop. Code without a name is checked byte by byte first |
| `ui.js` | the page's own windows (dialog with fields and buttons): the account window and typing |
| `audio.js` | music and sound effects with Web Audio (assets/emu/sound/*.mp3; plays after the first touch; iPhone: also on silent) |
| `speed.html` | a browser speed test (is the browser's fast JavaScript compiler on?) |
| `main.js` | the page: files, the Java side (settings, text drawn with a 2D canvas, the account login as a guest, the opening video skipped), frames, touches |

Files it needs (not in git): `node tools/build_webclient.js --emu` copies `re/libgame.so`, an apk from `release/` and the data
file `re/emu/main.28.com.hello.bro.yo.obb` (unpack it once from the `.xapk`: `Android/obb/com.hello.bro.yo/main.28...obb`) plus the
hot-update zips into `server/webclient/assets/emu/` as `.dat`.

Test without a browser: `node tools/dev/emu-boot.js [frames] [-v]` (no graphics; shows how far the app gets, its requests and the
next missing function). `HB_PROFILE=1` lists the functions that take the most instructions (tools/dev/emu-profile.js); `HB_FAST=0` runs
without fast.js; `HB_FASTCHECK=1` runs fast.js and the original side by side for every call and stops at a difference
(tools/dev/emu-fastcheck.js); the "pictures" fingerprint must stay the same with and without fast.js. In a browser: `/play/emu/?log=1` (app log in the console), `&device=e1` (the same test guest every time),
`&taps=0.5,0.86@22;0.5,0.66@52` (tap at x,y of the screen, 0..1, so many seconds after the start), `&keep=1` (for screenshots).

## Where players open it

**https://ninjaonlinereborn.com/play/emu/** (Caddy passes /play/ and the game's requests at /game/ to the game server:
tools/vps/wiki-site.sh). It must be https: iPhones (iOS 27) only run JavaScript with Safari's fast compiler on secure pages
(arrays 52 ms on http, 3 ms on https). The plain http address on :18080 sends the page there (?stay=1 keeps it).
On the owner's iPhone 16 the start takes ~4 s and the home screen plays (13 Nov 2026).

- Accounts: the first visit shows Play as guest / Log in / Sign up (server/gumplogin.js, the same accounts as the Android
  app). Sign up on a browser that plays as a guest gives that guest's account the name. The login is kept in the browser;
  the game's own "Register Account"/"Change" button on the login screen and "User Center" in the settings open the window
  again (sign up, log in to another account, log out). Test URLs with &device=<x> skip the window (a fixed guest).
- Typing: CCEditBox -> Cocos2dxHelper.showEditTextDialog -> the page's input box -> nativeSetEditTextDialogResult (UTF-8).
- Files the app writes (the hot update) are kept in IndexedDB "emu-files": the update is downloaded once (?fresh=1 forgets them).
- The green diagnostics line only with ?diag=1.

## State on 13 Nov 2026 (headless Chrome on the PC)

The app starts (about 350 M instructions with fast.js, 2.4 s with jit.js; it was 990 M and 10-15 s). Speed: PC Chrome ~170 M/s;
a browser without its own compiler (an iPhone in Lockdown Mode; `node --jitless` shows the same) ~16 M/s, i.e. ~22 s to start (it was ~4 M/s), asks our server for the version, downloads and unpacks the hot update, logs
in as a guest, creates a character (nation, ninja, name), shows the real home screen and the Training stage list.
Home costs about 134 K instructions = 2 ms a frame.

## Not done yet

- Sound effects that the app pauses/resumes one by one just stop (rare).
- Typing with the in-game text field kind CCTextFieldTTF (openIMEKeyboard) is not wired: no screen found that uses it yet.
- Drag touches (scrolling lists) are wired but not tried; fights and the other screens are not walked through yet.
- Text: labels are close, not exact (the phone's font and line heights).
- A Lua error shows at Home (`mainActivity` line 30, string.format without its argument): to compare with the phone's log.

## Things learned

- Screen shape: the app lays its screens out for 1.5 to 16:9. Taller (an iPhone home-screen app: 390x797) leaves a black band on
  Home, so `fit()` in main.js caps the height at 1.78 x the width and the page centres the game (13 Nov 2026).
- Headless Chrome hands scripts an empty answer (status 204) for addresses ending in `.bin` / `.zip` served as octet-stream: the
  emulator's files are `.dat` (type application/x-game-data) and the update zip is fetched from its `.dat` copy.
- JNI functions with five arguments take the fifth from the stack (GetByteArrayRegion): the garbled text was that.
- `nativeSetObbPath` wants the path of the .obb FILE; the app reads the zip itself.
- The SDK login: `SDKHelper.login()` -> `SDKCallbacks.didLogined()`, then the app asks `userId()`, `session()`, `nickName()`.
- After creating a character the app plays a video in Java (`CustomDialog.playGameStartVideo`) and waits for
  `RLVideoActivity.playRLVideoComplete(0)`: the int is the "still playing" flag (the app set it to 1 and waits for 0); without the 0
  the iPhone hung on a black screen.
