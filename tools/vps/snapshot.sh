#!/bin/sh
# Makes a consistent copy of the save (public.db) while the server runs, for backup-to-pc.ps1 to download:
# /tmp/hellobro-snapshot.db, readable only by the user that ran it with sudo.  Run:  sudo sh /opt/hellobro/tools/vps/snapshot.sh
set -e
OUT=/tmp/hellobro-snapshot.db
rm -f "$OUT"
sudo -u hellobro node -e "new (require('node:sqlite').DatabaseSync)('/opt/hellobro/public.db').exec(\"VACUUM INTO '$OUT'\")"
chown "${SUDO_USER:-root}" "$OUT"
chmod 600 "$OUT"
