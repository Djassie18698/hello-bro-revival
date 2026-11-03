#!/bin/sh
# Installs the Hello Bro PUBLIC server on an always-on Linux machine (Ubuntu, e.g. Oracle Cloud Always Free) and starts it.
# Run it on that machine:  curl -fsSL https://raw.githubusercontent.com/Djassie18698/hello-bro-revival/main/tools/vps/install.sh | sudo sh
# Running it again is safe: it updates the code and keeps the save (public.db), backups and admin password.
# The server runs as the "hellobro" service: starts with the machine, restarts itself if it stops (also after Restart in the manager).
# Same settings as START-PUBLIC-SERVER.bat: save public.db, backups in backups-public, login through the game's account window.
set -e
DIR=/opt/hellobro
REPO=https://github.com/Djassie18698/hello-bro-revival.git
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }
export DEBIAN_FRONTEND=noninteractive

echo "== tools"
apt-get update -q
apt-get install -y -q git curl ca-certificates iptables-persistent >/dev/null
# node:sqlite needs Node 22.5 or newer; Ubuntu's own Node is too old
if ! node -e 'process.exit(+process.versions.node.split(".")[0] >= 24 ? 0 : 1)' 2>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null
  apt-get install -y -q nodejs >/dev/null
fi
echo "node $(node -v)"

echo "== server files"
id hellobro >/dev/null 2>&1 || useradd --system --home-dir "$DIR" --shell /usr/sbin/nologin hellobro
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" config --global --add safe.directory "$DIR" 2>/dev/null || true
  git -C "$DIR" pull -q --ff-only
else
  git clone -q --depth 1 "$REPO" "$DIR"
fi
chown -R hellobro:hellobro "$DIR"

echo "== service"
cat > /etc/systemd/system/hellobro.service <<EOF
[Unit]
Description=Hello Bro public server
After=network-online.target
Wants=network-online.target

[Service]
User=hellobro
WorkingDirectory=$DIR
ExecStart=/bin/sh $DIR/tools/vps/run.sh
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q hellobro

echo "== open port 18080"
# Oracle's Ubuntu blocks every port but SSH inside the machine too (the Security List in the Oracle website is the other half)
iptables -C INPUT -p tcp --dport 18080 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport 18080 -j ACCEPT
netfilter-persistent save >/dev/null 2>&1 || true

if [ -s "$DIR/admin-password.txt" ]; then
  systemctl restart hellobro
  sleep 3
  systemctl is-active -q hellobro && echo "== the server is running on port 18080" || { echo "== the server did not start:"; journalctl -u hellobro -n 30 --no-pager; exit 1; }
else
  echo "== no admin password yet: set one with  sudo sh $DIR/tools/vps/password.sh  (the server starts after that)"
fi
