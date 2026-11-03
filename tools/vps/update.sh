#!/bin/sh
# Gets the newest version from GitHub and restarts the cloud server (the save and backups stay).
# Run on that machine:  sudo sh /opt/hellobro/tools/vps/update.sh
DIR=/opt/hellobro
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }
sudo -u hellobro git -C "$DIR" pull -q --ff-only && chown -R hellobro:hellobro "$DIR" && systemctl restart hellobro && sleep 3 &&
  systemctl is-active -q hellobro && echo "Updated to: $(sudo -u hellobro git -C "$DIR" log --oneline -1)" || journalctl -u hellobro -n 30 --no-pager
