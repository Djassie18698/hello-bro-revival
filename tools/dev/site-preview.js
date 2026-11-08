// Look at the home page on this PC the way https://ninjaonlinereborn.com serves it (Caddy, tools/vps/wiki-site.sh):
// / = server/site, /wiki/ = server/wiki, /status and /api/* = the dev server's (port 18081, tools/dev/restart.sh), the short links, /p/<name> = p.html.
//   node tools/dev/site-preview.js   then open http://127.0.0.1:18090/
const http = require('http'), fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..', '..', 'server');
const TYPES = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json', '.webp': 'image/webp', '.png': 'image/png' };
const PORT = Number(process.env.PORT) || 18090, STATUS = Number(process.env.STATUS_PORT) || 18081;
http.createServer((req, resp) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  const SHORT = { '/discord': 'https://discord.gg/2Cbp4UDHrU', '/download': 'https://github.com/Djassie18698/hello-bro-revival/releases/download/tailscale-play/HelloBro-ninjaonline.xapk',
    '/install': '/wiki/#/guides/install-help', '/play': '/#play' };
  const sk = p.replace(/\/$/, '');
  if (SHORT[sk]) { resp.writeHead(302, { Location: SHORT[sk] }); return resp.end(); }
  if (p.startsWith('/p/')) p = '/p.html';
  if (p === '/status' || p.startsWith('/api/')) {
    const q = http.get({ host: '127.0.0.1', port: STATUS, path: req.url, headers: { 'X-Forwarded-For': req.socket.remoteAddress } }, (r) => { resp.writeHead(r.statusCode, r.headers); r.pipe(resp); });
    return q.on('error', () => { resp.writeHead(502); resp.end(); });
  }
  if (p === '/wiki') { resp.writeHead(308, { Location: '/wiki/' }); return resp.end(); }
  const base = p.startsWith('/wiki/') ? path.join(ROOT, 'wiki') : path.join(ROOT, 'site');
  if (p.startsWith('/wiki/')) p = p.slice(5);
  if (p.endsWith('/')) p += 'index.html';
  const file = path.resolve(base, '.' + p);
  if (!file.startsWith(base + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { resp.writeHead(404); return resp.end('not found'); }
  resp.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
  fs.createReadStream(file).pipe(resp);
}).listen(PORT, () => console.log(`home page preview: http://127.0.0.1:${PORT}/`));
