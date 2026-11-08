#!/bin/sh
# The website https://ninjaonlinereborn.com (owner, 8 Nov 2026; the owner bought the name at Namecheap, its A records @ and www point at
# this machine): the home page (server/site) at /, the wiki (server/wiki) at /wiki/, no :18080, with a free HTTPS certificate.
# Caddy (Ubuntu's own package) answers on ports 80 + 443 and serves those files straight from the git checkout, so tools/vps/update.sh
# refreshes the site without anything else. Only /status goes on to the game server (the home page's "server online / N playing").
# The game server on :18080 (and its own /wiki/) is not touched.
# www.ninjaonlinereborn.com and the plain ninjaonline.duckdns.org (no port) lead to the home page, wiki.ninjaonline.duckdns.org to the wiki
# (DuckDNS answers every name under ninjaonline.duckdns.org with this machine's address, so those need nothing on duckdns.org).
# Oracle's firewall must let ports 80 and 443 in (docs/CLOUD-SERVER.md, "Open ports 80 and 443"); until then Caddy keeps retrying the certificate.
#   sudo sh tools/vps/wiki-site.sh          install / apply (safe to rerun)
#   sudo sh tools/vps/wiki-site.sh stop     switch the website off (ports 80/443 closed again)
#   sudo journalctl -u caddy                its log (certificate problems show here)
WIKI_HOST=${WIKI_HOST:-ninjaonlinereborn.com}
ALSO=${ALSO:-www.ninjaonlinereborn.com, ninjaonline.duckdns.org}
WIKI_ALSO=${WIKI_ALSO:-wiki.ninjaonline.duckdns.org}
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
[ -f "$DIR/server/wiki/index.html" ] && [ -f "$DIR/server/site/index.html" ] || { echo "no $DIR/server/wiki or server/site: update the server first (tools/vps/update.sh)"; exit 1; }
command -v caddy >/dev/null || { apt-get update -q; apt-get install -y -q caddy >/dev/null; }
cat > /etc/caddy/Caddyfile <<EOF
# Made by tools/vps/wiki-site.sh: edit that script, not this file.
$WIKI_HOST {
	encode zstd gzip
	header X-Content-Type-Options nosniff
	@pictures path /img/* /wiki/img/*
	header @pictures Cache-Control "public, max-age=86400"
	@text not path /img/* /wiki/img/* /status /api/*
	header @text Cache-Control "no-cache"
	# live numbers for the home page (version, start time, players online); the game server counts each visitor by X-Forwarded-For
	handle /status {
		reverse_proxy 127.0.0.1:18080
	}
	# short links (home page footer, Discord guides)
	@discord path /discord /discord/
	redir @discord https://discord.gg/2Cbp4UDHrU 302
	@download path /download /download/
	redir @download https://github.com/Djassie18698/hello-bro-revival/releases/download/tailscale-play/HelloBro-ninjaonline.xapk 302
	@install path /install /install/
	redir @install /wiki/#/guides/install-help 302
	@play path /play /play/
	redir @play /#play 302
	# public read-only data from the game server (server/webapi.js): top 10, player pages, today in the game, players-online graph, team calculator
	handle /api/* {
		reverse_proxy 127.0.0.1:18080
	}
	# player pages: every /p/<name> is the one page p.html, which reads the name from the address
	handle /p/* {
		root * $DIR/server/site
		rewrite * /p.html
		file_server
	}
	redir /wiki /wiki/ 308
	handle_path /wiki/* {
		root * $DIR/server/wiki
		respond /img/icons.json 404
		file_server {
			hide .*
		}
	}
	handle {
		root * $DIR/server/site
		file_server {
			hide .*
		}
	}
}

# other names lead to the site too; the game itself keeps using ninjaonline.duckdns.org:18080
$ALSO {
	redir https://$WIKI_HOST{uri}
}
$WIKI_ALSO {
	redir https://$WIKI_HOST/wiki{uri}
}
EOF
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 || { caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile; exit 1; }
for p in 80 443; do iptables -C INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport $p -j ACCEPT; done
netfilter-persistent save >/dev/null 2>&1 || true
systemctl enable -q caddy
systemctl restart caddy
sleep 3
if systemctl is-active -q caddy; then
  echo "== website on: https://$WIKI_HOST (home page) and https://$WIKI_HOST/wiki/ (the certificate comes once Oracle lets ports 80 + 443 in)"
else
  echo "== caddy did not start:"; journalctl -u caddy -n 30 --no-pager; exit 1
fi
