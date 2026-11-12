#!/bin/sh
# Gets the newest version from GitHub for the cloud server (the save and backups stay).
# Restarts the server (it is away for about 3 seconds; players stay logged in and at most see one network error) only when the server's own files changed.
# Run on that machine:  sudo sh /opt/hellobro/tools/vps/update.sh        (add "check" to only list what is waiting)
DIR=/opt/hellobro
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }
G() { sudo -u hellobro git -C "$DIR" "$@"; } # as the owner of the files (root gets git's "dubious ownership")
G fetch -q || exit 1
echo "Running now:  $(G log --oneline -1)"
NEW=$(G log --oneline HEAD..origin/main)
[ -n "$NEW" ] || { echo "Already the newest version."; exit 0; }
echo "Waiting on GitHub:"; echo "$NEW" | sed 's/^/  /'
[ "$1" = check ] && exit 0
OLD=$(G rev-parse HEAD)
G merge -q --ff-only origin/main || exit 1
chown -R hellobro:hellobro "$DIR"
# server/wiki, server/site and server/webclient are only files on disk (read fresh by the game server's /wiki/ and /play/ and by Caddy, tools/vps/wiki-site.sh): no restart for those (also notes: server/*.md, server/.impeccable)
if G diff --quiet "$OLD" HEAD -- server ':(exclude)server/wiki' ':(exclude)server/site' ':(exclude)server/webclient' ':(exclude)server/*.md' ':(exclude)server/.impeccable' tools/vps/run.sh; then
  echo "Updated to $(G log --oneline -1 | cut -c1-60). No server changes: no restart needed."
  exit 0
fi
systemctl restart hellobro && sleep 3
if systemctl is-active -q hellobro; then echo "Updated and restarted: $(G log --oneline -1 | cut -c1-60)"
else echo "The server did not start again:"; journalctl -u hellobro -n 30 --no-pager; exit 1; fi
