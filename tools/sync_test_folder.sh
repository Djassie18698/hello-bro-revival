#!/bin/sh
# Copy the latest committed version into the owner's play folders (what a friend would download), keeping each folder's own
# save (hellobro.db), made game files (*.xapk) and release/ apks. Does NOT restart a server: tell the owner to restart it.
# usage: sh tools/sync_test_folder.sh        (run after every push)
# Folders: HB_TEST_DIR (one folder) or, by default, the Locked Server folder the owner plays on + the old fresh-install test folder.
set -e
cd "$(dirname "$0")/.."
TMPD="$(mktemp -d)"
git archive HEAD | tar -x -C "$TMPD"
rm -f "$TMPD/hellobro.db"
sync_to() {
  [ -d "$1" ] || { echo "no folder at $1 (skipped)"; return 0; }
  cp -r "$TMPD"/. "$1"/
  echo "updated $1 to $(git log --oneline -1)"
}
if [ -n "$HB_TEST_DIR" ]; then
  sync_to "$HB_TEST_DIR"
else
  sync_to "/c/Users/dj199/Desktop/Hello Bro Locked Server"
  sync_to "/c/Users/dj199/Desktop/HelloBro-Fresh-Test/HelloBroServer"
fi
rm -rf "$TMPD"
