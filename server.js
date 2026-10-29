// Hello Bro revival server. Node 22+ (built-in node:sqlite), no dependencies.
// Protocol (reverse-engineered from libgame.so): HTTP GET/POST to /<cgi>?Cmd=..&Uin=..&Session=..
// Responses are XML: <RENLONG code="0">...</RENLONG>, values are child-element text.
const http = require('http');
const net = require('net');
const url = require('url');
const { DatabaseSync } = require('node:sqlite');
const handlers = require('./handlers');
const admin = require('./admin');

const PORT = process.env.PORT || 18080;
const db = new DatabaseSync(process.env.DB || 'hellobro.db');
require('./schema')(db);

function parseBody(req) {
  return new Promise((res) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => res(Buffer.concat(chunks).toString('utf8')));
  });
}

const httpServer = http.createServer({ insecureHTTPParser: true }, async (req, resp) => {
  const u = url.parse(req.url, true);
  if (u.pathname.startsWith('/admin')) {
    try { return await admin(req, resp, u, db, parseBody); } catch (e) { console.error('admin error', e); resp.writeHead(500); return resp.end('error'); }
  }
  const body = req.method === 'POST' ? await parseBody(req) : '';
  const params = { ...u.query, ...Object.fromEntries(new URLSearchParams(body)) };
  const cgi = u.pathname.replace(/^\/+/, '');
  const h = handlers[cgi];
  let out;
  try {
    out = h ? h({ db, params, cgi, host: req.headers.host }) : null;
  } catch (e) {
    console.error('handler error', cgi, e);
    out = null;
  }
  if (out == null) {
    console.log(`[UNHANDLED] ${req.method} ${req.url} ${body}`);
    out = '<root code="1"><message>not implemented</message></root>';
  } else {
    console.log(`[ok] ${cgi} Cmd=${params.Cmd || ''}`);
  }
  resp.writeHead(200, { 'Content-Type': 'text/xml; charset=utf-8' });
  // The Lua side looks for a <RENLONG> root; the C++ side accepts any root name.
  out = out.replace(/^<root/, '<RENLONG').replace(/<\/root>$/, '</RENLONG>');
  resp.end('<?xml version="1.0" encoding="UTF-8"?>' + out);
});

// The game's Lua code puts raw spaces in request URLs ("Clinettime=2026/10/29 05:42:45 Thursday"),
// which Node's strict parser rejects. Percent-encode them in the request line before parsing.
net.createServer((sock) => {
  sock.once('data', (chunk) => {
    const eol = chunk.indexOf('\r\n');
    if (eol > 0) {
      const line = chunk.subarray(0, eol).toString('latin1');
      const a = line.indexOf(' ');
      const b = line.lastIndexOf(' ');
      if (a > 0 && b > a) {
        const fixed = line.slice(0, a + 1) + line.slice(a + 1, b).replace(/ /g, '%20') + line.slice(b);
        chunk = Buffer.concat([Buffer.from(fixed, 'latin1'), chunk.subarray(eol)]);
      }
    }
    sock.unshift(chunk);
    httpServer.emit('connection', sock);
    sock.on('error', () => {});
  });
}).on('error', (e) => console.error('listen error', e.message)).listen(PORT, '0.0.0.0', () => console.log(`Hello Bro server on :${PORT}`));
