#!/bin/sh
# The Hello Bro Discord bot (shows online, posts in #server-status) as a service on the cloud machine, so it runs day and night and can't
# be closed by accident (owner, 7 Nov 2026). It needs the bot token in /opt/hellobro/discord/.env (copied from the owner's PC; never in git).
#   sudo sh tools/vps/bot.sh          install / restart the service "hellobro-bot"
#   sudo sh tools/vps/bot.sh stop     stop it and switch it off (then the bot can run on the PC again with START-BOT-ONLINE.bat)
#   sudo journalctl -u hellobro-bot   its log
DIR=/opt/hellobro
set -e
if [ "$1" = "stop" ]; then
  systemctl disable --now -q hellobro-bot 2>/dev/null || true
  echo "== bot service stopped and switched off"
  exit 0
fi
[ -s "$DIR/discord/.env" ] || { echo "no $DIR/discord/.env: copy the bot token file from the PC first"; exit 1; }
chown hellobro:hellobro "$DIR/discord/.env"; chmod 600 "$DIR/discord/.env"
[ -f "$DIR/discord/status-state.json" ] && chown hellobro:hellobro "$DIR/discord/status-state.json"
NODE=$(command -v node)
cat > /etc/systemd/system/hellobro-bot.service <<EOF
[Unit]
Description=Hello Bro Discord bot (online + #server-status)
After=network-online.target hellobro.service
Wants=network-online.target

[Service]
User=hellobro
WorkingDirectory=$DIR/discord
# the game server is on this same machine: check it directly
Environment=STATUS_URL=http://127.0.0.1:18080/status
ExecStart=$NODE --env-file=.env online.js
Restart=always
RestartSec=10
# exit code 2 = bad token / missing .env (online.js): don't retry every 10 s
RestartPreventExitStatus=2

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q hellobro-bot
systemctl restart hellobro-bot
sleep 4
if systemctl is-active -q hellobro-bot; then echo "== bot running"; journalctl -u hellobro-bot -n 5 --no-pager -o cat; else echo "== bot did not start:"; journalctl -u hellobro-bot -n 30 --no-pager; exit 1; fi
