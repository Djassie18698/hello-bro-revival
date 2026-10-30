#!/bin/sh
# Copy the latest committed version into the user's fresh-install test folder (what a friend would download),
# keeping that folder's own save (hellobro.db), made game files (*.xapk) and release/ apks.
# usage: sh tools/sync_test_folder.sh        (run after every push)
set -e
cd "$(dirname "$0")/.."
DEST="${HB_TEST_DIR:-/c/Users/dj199/Desktop/HelloBro-Fresh-Test/HelloBroServer}"
[ -d "$DEST" ] || { echo "no test folder at $DEST"; exit 0; }
TMPD="$(mktemp -d)"
git archive HEAD | tar -x -C "$TMPD"
rm -f "$TMPD/hellobro.db"
cp -r "$TMPD"/. "$DEST"/
rm -rf "$TMPD"
echo "test folder updated to $(git log --oneline -1)"
