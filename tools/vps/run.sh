#!/bin/sh
# Started by the hellobro service (see install.sh): the public server with the same settings as START-PUBLIC-SERVER.bat.
cd "$(dirname "$0")/../.." || exit 1
# the control panel (/, /manager) always needs the password
[ -s admin-password.txt ] || { echo "no admin-password.txt: run  sudo sh tools/vps/password.sh"; exit 1; }
ADMIN_PASSWORD=$(head -n 1 admin-password.txt | tr -d '\r\n')
# HB_WATCHDOG=1: restart the server when it stops answering for 3 minutes (server/watchdog.js). HB_ONE_WORLD=1: only Konoha (main), no starter slots (owner, 6 Nov 2026). ADMIN_OPEN=1: players may use the item page /admin without the password (owner, 3 Nov 2026, "for now"; see server/admin.js)
# HB_SITE_URL: the control panel and item page open on the website (https), not on :18080 (server.js; owner 10 Nov 2026)
# HB_TRACK_UIDS=7: the full progress tracker follows DEAN (server/tracker.js; owner 10 Nov 2026). Only used until the control panel's Tracker tab saves a list.
# HB_MOD_PROTECT=7: mods (/mod, server/admin.js, password in mod-password.txt) cannot give DEAN a new password (owner 13 Nov 2026)
export HB_MOD_PROTECT=7 HB_TRACK_UIDS=7 HB_SITE_URL=https://ninjaonlinereborn.com ADMIN_PASSWORD ADMIN_OPEN=1 HB_ONE_WORLD=1 HB_WATCHDOG=1 DB=public.db HB_BACKUPS=backups-public LOGIN_LOCK=1 STRICT_SESSIONS=1 HB_MANAGED=1
exec node server/server.js
