// The wiki (server/wiki: index.html + app.js + style.css + data.json + img/), served at /wiki/ by the game server (server.js), so the
// public server shows it at http://<address>:18080/wiki/ with no extra port. Static files only: GET/HEAD, nothing outside server/wiki,
// gzip for text (kept in memory per file version), ETag so browsers only fetch a file again after a change.
const fs = require('fs'), path = require('path'), zlib = require('zlib');

const ROOT = path.join(__dirname, 'wiki');
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.txt': 'text/plain; charset=utf-8' };
const TEXT = new Set(['.html', '.js', '.css', '.json', '.svg', '.txt']);
const gz = new Map(); // file -> { tag, body }

function serve(req, resp, pathname) {
  if (req.method !== 'GET' && req.method !== 'HEAD') { resp.writeHead(405, { Allow: 'GET, HEAD' }); return resp.end(); }
  let rel;
  try { rel = decodeURIComponent(pathname.slice('/wiki/'.length)); } catch { resp.writeHead(400); return resp.end(); }
  if (!rel || rel.endsWith('/')) rel += 'index.html';
  const file = path.resolve(ROOT, rel);
  const ext = path.extname(file).toLowerCase();
  if (!file.startsWith(ROOT + path.sep) || rel.includes('\0') || !TYPES[ext] || path.basename(file) === 'icons.json') { resp.writeHead(404); return resp.end(); }
  let st;
  try { st = fs.statSync(file); } catch { st = null; }
  if (!st || !st.isFile()) { resp.writeHead(404, { 'Content-Type': 'text/plain' }); return resp.end('not found'); }
  const tag = `"${st.size.toString(36)}-${Math.floor(st.mtimeMs).toString(36)}"`;
  const head = { 'Content-Type': TYPES[ext], ETag: tag, 'Cache-Control': TEXT.has(ext) ? 'no-cache' : 'public, max-age=86400', 'X-Content-Type-Options': 'nosniff' };
  if (req.headers['if-none-match'] === tag) { resp.writeHead(304, head); return resp.end(); }
  if (TEXT.has(ext) && /\bgzip\b/.test(req.headers['accept-encoding'] || '')) {
    let c = gz.get(file);
    if (!c || c.tag !== tag) { c = { tag, body: zlib.gzipSync(fs.readFileSync(file), { level: 9 }) }; gz.set(file, c); }
    resp.writeHead(200, { ...head, 'Content-Encoding': 'gzip', Vary: 'Accept-Encoding', 'Content-Length': c.body.length });
    return resp.end(req.method === 'HEAD' ? undefined : c.body);
  }
  resp.writeHead(200, { ...head, 'Content-Length': st.size });
  if (req.method === 'HEAD') return resp.end();
  return fs.createReadStream(file).pipe(resp);
}

module.exports = serve;
