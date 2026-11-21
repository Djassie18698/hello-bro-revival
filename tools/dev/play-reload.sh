#!/bin/sh
# reloads the game page that tools/dev/play.js serves and waits until Home shows
cd "$(dirname "$0")/../.."
node tools/dev/play.js ev "location.reload()" $1 >/dev/null
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  r=$(PLAY_WAIT=2000 node tools/dev/play.js ev "!!(window.HB && HB.game && HB.game.user && HB.L && HB.game.subContent && HB.game.subContent.children.length)" $1 | head -1)
  [ "$r" = "true" ] && break
done
PLAY_WAIT=2500 node tools/dev/play.js ev "'ready ' + HB.game.user.level" $1 | head -1
