#!/bin/sh
# Sets (or changes) the password of the admin page and Server Manager on the cloud server, then restarts it.
# Run on that machine:  sudo sh /opt/hellobro/tools/vps/password.sh
DIR=/opt/hellobro
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }
PW=""
while [ -z "$PW" ]; do
  printf "New admin password: "; stty -echo 2>/dev/null; read -r PW; stty echo 2>/dev/null; echo
  [ -z "$PW" ] && echo "The password can't be empty."
done
printf '%s\n' "$PW" > "$DIR/admin-password.txt"
chown hellobro:hellobro "$DIR/admin-password.txt"; chmod 600 "$DIR/admin-password.txt"
systemctl restart hellobro && echo "Saved. The server restarted with the new password."
