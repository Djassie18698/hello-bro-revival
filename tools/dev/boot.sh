export MSYS_NO_PATHCONV=1; A="/c/Program Files/BlueStacks_nxt/HD-Adb.exe"; D=127.0.0.1:5595
timeout 15 "$A" -s $D shell am force-stop com.hello.bro.yo; timeout 15 "$A" -s $D logcat -c
timeout 15 "$A" -s $D shell monkey -p com.hello.bro.yo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 13
timeout 15 "$A" -s $D shell input tap 540 1270; sleep 15
timeout 15 "$A" -s $D shell screencap -p /sdcard/s.png; timeout 40 "$A" -s $D pull /sdcard/s.png "$TEMP/hb/${1:-boot}.png" >/dev/null
timeout 20 "$A" -s $D logcat -d | grep -aE "LUA ERROR|Fatal signal" | head -4 | cut -c40-230
