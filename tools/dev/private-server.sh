#!/bin/sh
# A private copy of the dev server with its clock moved, for features with opening hours (run it in the background):
#   sh tools/dev/private-server.sh 14:01 [port] [fresh]     the server thinks it is 14:01 local time; port 18083; "fresh" copies hellobro.db again
# World Boss 14:00-14:30 local; Border war 12:00-15:00 New York time (= 18:00-21:00 here in winter).
# Its save is a copy of the dev save in %TEMP%/hb/private.db (edit it with PLAY_DB=<that file> node tools/dev/play-save.js <uid> "...").
# Play it: PLAY_BASE=http://127.0.0.1:18083 node tools/dev/play.js serve <guest> <chrome port>
cd "$(dirname "$0")/../.."
PORT=${2:-18083}
D="$(node -e "console.log(require('path').join(require('os').tmpdir(), 'hb').replace(/\\\\/g, '/'))")"
mkdir -p "$D/private-backups"
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort $PORT -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }; Start-Sleep 1"
if [ "$3" = "fresh" ] || [ ! -f "$D/private.db" ]; then
  rm -f "$D/private.db" "$D/private.db-wal" "$D/private.db-shm"
  node -e "new (require('node:sqlite').DatabaseSync)('hellobro.db').exec(\"VACUUM INTO '$D/private.db'\")"
fi
echo "private server on :$PORT, clock $1, save $D/private.db"
HB_SHIFT_TO=$1 PORT=$PORT DB="$D/private.db" HB_BACKUPS="$D/private-backups" RATE_LIMIT=100000 exec node -r ./tools/dev/shift-clock.js server/server.js > "$D/private.log" 2>&1
