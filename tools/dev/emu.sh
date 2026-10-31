#!/bin/sh
# Drive the test emulator (BlueStacks instance "Claude") from Git Bash.
# Its adb address changes per PC/start: put it in tools/dev/emu.device (one line, e.g. emulator-5564) or set HB_EMU.
#   sh tools/dev/emu.sh shot            screenshot -> re/s.png (read it with the image viewer tool)
#   sh tools/dev/emu.sh tap X Y         tap (portrait 1080x1920 screen coordinates, as in the screenshot)
#   sh tools/dev/emu.sh restart         force-stop + launch the game (then: tap 540 1270 = START, ~20 s later)
#   sh tools/dev/emu.sh update          tap Confirm on the "confirm update?" dialog (545 1650)
#   sh tools/dev/emu.sh log             crashes, Lua errors, missing XML nodes and server replies from logcat
#   sh tools/dev/emu.sh back            Android back key (closes BlueStacks ad pages that steal taps)
# Never use other BlueStacks instances: the owner tests the game on them.
ADB="/c/Program Files/BlueStacks_nxt/HD-Adb.exe"
cd "$(dirname "$0")/../.." && mkdir -p re
D="${HB_EMU:-$(cat tools/dev/emu.device 2>/dev/null | tr -d '\r\n ')}"
[ -n "$D" ] || { echo "No emulator set. Start BlueStacks instance 'Claude', find its adb address (HD-Adb.exe devices) and write it to tools/dev/emu.device"; exit 1; }
case "$1" in
  shot) "$ADB" -s $D exec-out screencap -p > re/s.png && echo re/s.png ;;
  tap) "$ADB" -s $D shell input tap "$2" "$3" ;;
  back) "$ADB" -s $D shell input keyevent 4 ;;
  restart) "$ADB" -s $D shell am force-stop com.hello.bro.yo; "$ADB" -s $D logcat -c
           "$ADB" -s $D shell monkey -p com.hello.bro.yo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 ;;
  update) "$ADB" -s $D shell input tap 545 1650 ;;
  log) "$ADB" -s $D logcat -d | grep -E "SIGSEGV|Fatal signal|LUA ERROR|this is no node|Respose data|POST completed" | tail -${2:-40} | cut -c1-300 ;;
  *) sed -n 2,9p "$0" ;;
esac
