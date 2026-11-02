#!/bin/sh
# Copy the latest committed version into the owner's play folder (what a friend would download), keeping its own
# save (hellobro.db), made game files (*.xapk) and release/ apks. Does NOT restart a server: tell the owner to restart it.
# Files removed from git since the last sync are removed there too (the last synced commit is kept in .synced-commit).
# usage: sh tools/sync_test_folder.sh        (run after every push)
# Folder: HB_TEST_DIR, or by default the Locked Server folder the owner plays on.
set -e
cd "$(dirname "$0")/.."
TMPD="$(mktemp -d)"
git archive HEAD | tar -x -C "$TMPD"
rm -f "$TMPD/hellobro.db"
git ls-tree -r --name-only HEAD | LC_ALL=C sort > "$TMPD/.now"
sync_to() {
  [ -d "$1" ] || { echo "no folder at $1 (skipped)"; return 0; }
  last=$(cat "$1/.synced-commit" 2>/dev/null || git rev-parse HEAD~1)
  git ls-tree -r --name-only "$last" 2>/dev/null | LC_ALL=C sort | comm -23 - "$TMPD/.now" | while IFS= read -r f; do
    case "$f" in *.xapk|release/*.apk|hellobro.db*) continue ;; esac
    [ -f "$1/$f" ] && rm -f "$1/$f" && echo "removed $f"
  done
  cp -r "$TMPD"/. "$1"/; rm -f "$1/.now"
  git rev-parse HEAD > "$1/.synced-commit"
  echo "updated $1 to $(git log --oneline -1)"
}
sync_to "${HB_TEST_DIR:-/c/Users/dj199/Desktop/Hello Bro Locked Server}"
rm -rf "$TMPD"
