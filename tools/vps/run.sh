#!/bin/sh
# Started by the hellobro service (see install.sh): the public server with the same settings as START-PUBLIC-SERVER.bat.
cd "$(dirname "$0")/../.." || exit 1
# the control panel (/, /manager) always needs the password
[ -s admin-password.txt ] || { echo "no admin-password.txt: run  sudo sh tools/vps/password.sh"; exit 1; }
ADMIN_PASSWORD=$(head -n 1 admin-password.txt | tr -d '\r\n')
# HB_WATCHDOG=1: restart the server when it stops answering for 3 minutes (server/watchdog.js). ADMIN_OPEN=1: players may use the item page /admin without the password (owner, 3 Nov 2026, "for now"; see server/admin.js)
export ADMIN_PASSWORD ADMIN_OPEN=1 HB_WATCHDOG=1 DB=public.db HB_BACKUPS=backups-public LOGIN_LOCK=1 STRICT_SESSIONS=1 HB_MANAGED=1
exec node server/server.js
