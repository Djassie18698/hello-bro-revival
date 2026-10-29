export MSYS_NO_PATHCONV=1; A="/c/Program Files/BlueStacks_nxt/HD-Adb.exe"; D=127.0.0.1:5595
H=$TEMP/hb
for t in "$@"; do
  name=${t%%:*}; xy=${t#*:}; x=${xy%,*}; y=${xy#*,}
  "$A" -s $D shell am force-stop com.hello.bro.yo; "$A" -s $D shell monkey -p com.hello.bro.yo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 14; timeout 15 "$A" -s $D shell input tap 540 1270; sleep 14
  before=$(grep -ac "" $H/server.log)
  "$A" -s $D logcat -c
  "$A" -s $D shell input tap $x $y; sleep 5
  timeout 15 "$A" -s $D shell screencap -p /sdcard/s.png; timeout 40 "$A" -s $D pull /sdcard/s.png $H/sv_$name.png >/dev/null
  alive=$("$A" -s $D shell pidof com.hello.bro.yo)
  echo "== $name alive=[$alive]"
  tail -n +$((before+1)) $H/server.log | grep -a "^\[" | sed -E 's/Uid=.*Cmd=/ Cmd=/;s/(.{0,110}).*/\1/'
  "$A" -s $D logcat -d | grep -aE "LUA ERROR|no node" | grep -v "cdn\|filelist\|notice" | head -3 | cut -c40-200
done
