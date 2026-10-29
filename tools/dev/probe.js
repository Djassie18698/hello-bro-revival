// Smoke test an endpoint on a running server:  node tools/dev/probe.js rl_r_vipshop 4000 Uid=1 Session=x
const http = require('http');
const [ep, cmd, ...kv] = process.argv.slice(2);
const body = ['Cmd=' + (cmd || 0), 'Uid=1', 'Session=probe', 'ServerID=1', 'GroupID=2', ...kv].join('&');
const q = http.request({ host: '127.0.0.1', port: 18080, path: '/' + ep, method: 'POST' }, (r) => { let d = ''; r.on('data', (c) => d += c); r.on('end', () => console.log(d)); });
q.write(body); q.end();
