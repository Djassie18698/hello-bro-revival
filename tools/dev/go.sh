export MSYS_NO_PATHCONV=1; A="/c/Program Files/BlueStacks_nxt/HD-Adb.exe"; D=127.0.0.1:5595
# usage: go.sh name x,y x,y ...   (launches only if game isn't focused on its own activity)
n=$1; shift
"$A" -s $D logcat -c
if ! "$A" -s $D shell dumpsys window | grep -a mCurrentFocus | grep -aq hello.bro; then
  "$A" -s $D shell monkey -p com.hello.bro.yo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  sleep 16; "$A" -s $D shell input tap 540 1270; sleep 14
fi
for t in "$@"; do x=${t%,*}; y=${t#*,}; "$A" -s $D shell input tap $x $y; sleep 4; done
"$A" -s $D shell screencap -p /sdcard/s.png; "$A" -s $D pull /sdcard/s.png "$TEMP/hb/$n.png" >/dev/null
"$A" -s $D logcat -d | grep -aE "no node|LUA ERROR|Fatal signal|SIGSEGV" | grep -v "cdn\|filelist\|notice" | head -6
grep -a "^\[" "$TEMP/hb/server.log" | tail -3 | cut -c1-110
