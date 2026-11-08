#!/bin/sh
# The wiki on its own address, https://ninjaonlinereborn.com (owner, 8 Nov 2026; the owner bought the name at Namecheap, its A records @ and www
# point at this machine): no :18080, with a free HTTPS certificate.
# Caddy (Ubuntu's own package) answers on ports 80 + 443 and serves the files of /opt/hellobro/server/wiki straight from the git checkout,
# so tools/vps/update.sh refreshes the wiki without anything else. The game server on :18080 (and its own /wiki/) is not touched.
# www.ninjaonlinereborn.com, wiki.ninjaonline.duckdns.org and the plain ninjaonline.duckdns.org (no port) lead there too (DuckDNS answers every
# name under ninjaonline.duckdns.org with this machine's address, so those need nothing on duckdns.org).
# Oracle's firewall must let ports 80 and 443 in (docs/CLOUD-SERVER.md, "Open ports 80 and 443"); until then Caddy keeps retrying the certificate.
#   sudo sh tools/vps/wiki-site.sh          install / apply (safe to rerun)
#   sudo sh tools/vps/wiki-site.sh stop     switch the wiki address off (ports 80/443 closed again)
#   sudo journalctl -u caddy                its log (certificate problems show here)
WIKI_HOST=${WIKI_HOST:-ninjaonlinereborn.com}
ALSO=${ALSO:-www.ninjaonlinereborn.com, wiki.ninjaonline.duckdns.org, ninjaonline.duckdns.org}
DIR=/opt/hellobro
set -e
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }
if [ "$1" = "stop" ]; then
  systemctl disable --now -q caddy 2>/dev/null || true
  for p in 443 80; do while iptables -D INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null; do :; done; done
  netfilter-persistent save >/dev/null 2>&1 || true
  echo "== wiki address switched off"
  exit 0
fi
[ -f "$DIR/server/wiki/index.html" ] || { echo "no $DIR/server/wiki: update the server first (tools/vps/update.sh)"; exit 1; }
command -v caddy >/dev/null || { apt-get update -q; apt-get install -y -q caddy >/dev/null; }
cat > /etc/caddy/Caddyfile <<EOF
# Made by tools/vps/wiki-site.sh: edit that script, not this file.
$WIKI_HOST {
	root * $DIR/server/wiki
	encode zstd gzip
	header X-Content-Type-Options nosniff
	@pictures path /img/*
	header @pictures Cache-Control "public, max-age=86400"
	@text not path /img/*
	header @text Cache-Control "no-cache"
	respond /img/icons.json 404
	file_server {
		hide .*
	}
}

# other names lead to the wiki too; the game itself keeps using ninjaonline.duckdns.org:18080
$ALSO {
	redir https://$WIKI_HOST{uri}
}
EOF
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 || { caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile; exit 1; }
for p in 80 443; do iptables -C INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport $p -j ACCEPT; done
netfilter-persistent save >/dev/null 2>&1 || true
systemctl enable -q caddy
systemctl restart caddy
sleep 3
if systemctl is-active -q caddy; then
  echo "== wiki address on: https://$WIKI_HOST (the certificate comes once Oracle lets ports 80 + 443 in)"
else
  echo "== caddy did not start:"; journalctl -u caddy -n 30 --no-pager; exit 1
fi
