#!/bin/sh
# Side-by-side picture of the real app (BlueStacks instance "Claude", left) and the rewritten game (tools/dev/play.js, right).
#   sh tools/dev/compare.sh <name>            both pictures now -> re/compare/<name>.png (760x1350 each)
#   sh tools/dev/compare.sh <name> app|web    take only that side again, then join
# Start the rewrite first: PLAY_ACCOUNT=1 node tools/dev/play.js serve cmp   (logs in as the emulator's test account)
cd "$(dirname "$0")/../.." && mkdir -p re/compare/parts
FF=$(ls "$LOCALAPPDATA"/Microsoft/WinGet/Packages/Gyan.FFmpeg*/*/bin/ffmpeg.exe 2>/dev/null | head -1)
N="$1"; A="re/compare/parts/$N-app.png"; W="re/compare/parts/$N-web.png"
[ "$2" = "web" ] || { sh tools/dev/emu.sh shot >/dev/null && cp re/s.png "$A"; }
[ "$2" = "app" ] || node tools/dev/play.js shot "$W" >/dev/null
"$FF" -y -loglevel error -i "$A" -i "$W" -filter_complex "[0]scale=760:1350:flags=lanczos[a];[1]scale=760:1350:flags=lanczos[b];[a][b]hstack" "re/compare/$N.png" && echo "re/compare/$N.png"
