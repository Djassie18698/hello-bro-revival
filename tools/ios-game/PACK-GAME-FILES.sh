#!/bin/sh
# Packs the big game files the iPhone game app carries (made by: node tools/build_webclient.js --emu) into game-files.tar and puts it on
# the GitHub release "ios-game", where the app's build (.github/workflows/ios-game.yml) picks it up. Run again only when those files
# change (a new libgame / obb / sounds); the page and the hot update come from git at every build.
#   sh tools/ios-game/PACK-GAME-FILES.sh
set -e
cd "$(dirname "$0")/../.."
A=server/webclient/assets/emu
[ -f $A/libgame.dat ] || { echo "missing $A: run node tools/build_webclient.js --emu"; exit 1; }
OUT=re/game-files.tar # re/ is never committed
tar -cf "$OUT" -C $A libgame.dat parts.json apk obb sound
ls -la "$OUT"
gh release view ios-game >/dev/null 2>&1 || gh release create ios-game --latest=false --title "Ninja Online for iPhone (sideload app)" \
  --notes "The game as an iPhone app with every game file inside. Install NinjaOnline.ipa with Sideloadly: see tools/ios-game/README.md. game-files.tar is only for the build."
gh release upload ios-game "$OUT" --clobber
echo "uploaded game-files.tar to the release ios-game"
