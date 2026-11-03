#!/bin/sh
# Started by the hellobro service (see install.sh): the public server with the same settings as START-PUBLIC-SERVER.bat.
cd "$(dirname "$0")/../.." || exit 1
# never run a public server with an open admin page
[ -s admin-password.txt ] || { echo "no admin-password.txt: run  sudo sh tools/vps/password.sh"; exit 1; }
ADMIN_PASSWORD=$(head -n 1 admin-password.txt | tr -d '\r\n')
export ADMIN_PASSWORD DB=public.db HB_BACKUPS=backups-public LOGIN_LOCK=1 STRICT_SESSIONS=1 HB_MANAGED=1
exec node server/server.js
