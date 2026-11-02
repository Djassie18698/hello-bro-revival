// Bad-input sweep: calls every handler with every Cmd the game uses, but with missing, zero, negative, huge, text and
// injection-like parameter values, on a throwaway DB, then every handler first thing on a brand-new save. Reports crashes and non-XML replies.
// Usage: node tools/dev/fuzz.js     (does not touch hellobro.db)
const os = require('os'), path = require('path'), fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const tmp = path.join(os.tmpdir(), 'hb-fuzz-' + process.pid + '.db');
const db = new DatabaseSync(tmp);
require('../../schema')(db);
const handlers = require('../../handlers');

// every parameter name the client sends (scraped from AddData / GetUrlNormalHeader in the Lua scripts) plus the common ones
const lua = path.join(__dirname, '..', '..', 'reference', 'lua-scripts');
const names = new Set(['Cmd', 'Type', 'Free', 'Goodsid', 'Count', 'Counts', 'ToUid', 'ToRank', 'Chip', 'BagId', 'BagID', 'SRCBagID', 'EATCardsBagIDList', 'ExId',
  'PackID', 'Packageid', 'AwardID', 'GiftId', 'SignId', 'Chap', 'Round', 'DupId', 'traintype', 'multitype', 'ToCountry', 'Code', 'GroupName', 'GroupId', 'Pos',
  'ExchId', 'reward_id', 'box_index', 'ChipBagID', 'AttackCardBagIndex', 'DefenseCardBagIndex', 'Exchg', 'ActType', 'ActID', 'SubID', 'Page', 'Nick', 'Card']);
const cmds = {};
if (fs.existsSync(lua)) {
  const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.lua') ? [path.join(d, e.name)] : []);
  for (const f of walk(lua)) {
    const t = fs.readFileSync(f, 'utf8');
    for (const m of t.matchAll(/AddData\([^,]*,\s*"([A-Za-z_0-9]+)"/g)) names.add(m[1]);
    for (const m of t.matchAll(/GetUrlNormalHeader\([^,]*,\s*(\d+)\s*,\s*"([a-z_0-9]+)"\s*\)/g)) (cmds[m[2]] = cmds[m[2]] || new Set()).add(Number(m[1]));
  }
}
const VALUES = [undefined, '', '0', '-1', '-999999', '99999999999', '1.5', 'abc', "1' OR '1'='1", '<x>', '1|2|-3|abc', '%00'];
const base = { Uid: '77', Session: 'fuzz', ServerID: '1', GroupID: '2' };
let bad = 0, calls = 0;
const seen = new Set();
const run = (name, params) => {
  calls++;
  try {
    const out = handlers[name]({ db, params, host: 'localhost:18080', method: 'POST', body: '' });
    const s = String(typeof out === 'string' ? out : JSON.stringify(out)).trim();
    if (!/^<root|^<\?xml|^\{/.test(s)) { const k = name + ' non-xml'; if (!seen.has(k)) { seen.add(k); bad++; console.log('NON-XML', name, JSON.stringify(params).slice(0, 160), s.slice(0, 80)); } }
  } catch (e) {
    const k = name + ' ' + e.message.slice(0, 60);
    if (!seen.has(k)) { seen.add(k); bad++; console.log('CRASH  ', name, JSON.stringify(params).slice(0, 200), '->', e.message.split('\n')[0]); }
  }
};
handlers.rl_w_reg2({ db, params: { ...base, Nick: 'Fuzz', Card: 1, Ninja: 55, Country: 1 } });
db.prepare('UPDATE players SET gold=100000, coin=10000000, level=100').run();
const settings = require('../../settings');
for (const e of settings.EVENTS) settings.setEvent(db, e.id, true); // events are off by default: switch all on so their paths run too
for (const name of Object.keys(handlers)) {
  const cs = [0, ...(cmds[name] || [])];
  for (const c of new Set(cs)) for (const v of VALUES) {
    const p = { ...base, Cmd: String(c) };
    for (const n of names) if (!['Cmd', 'Uid', 'Uin', 'Session', 'ServerID', 'GroupID'].includes(n) && v !== undefined) p[n] = v; // a real player, broken everything else
    run(name, p);
  }
  // broken player id / no player at all
  run(name, { ...base, Cmd: String(cs[cs.length - 1]), Uid: '1.5' });
  run(name, { Cmd: String(cs[cs.length - 1]), Uid: '424242', Session: 'x', ServerID: '1' });
}
db.close(); try { fs.unlinkSync(tmp); } catch {}
// every handler x Cmd called FIRST on a brand-new save: finds screens that read a table only another screen creates (a new server)
for (const name of Object.keys(handlers)) for (const c of new Set([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, ...(cmds[name] || [])])) {
  const fresh = new DatabaseSync(':memory:');
  require('../../schema')(fresh);
  handlers.rl_w_reg2({ db: fresh, params: { ...base, Nick: 'Fresh', Card: 1, Ninja: 55, Country: 1 } });
  calls++;
  try { handlers[name]({ db: fresh, params: { ...base, Cmd: String(c), ToUid: '78', Id: '1' }, host: 'localhost:18080', method: 'POST', body: '' }); }
  catch (e) { const k = name + ' fresh ' + e.message.slice(0, 60); if (!seen.has(k)) { seen.add(k); bad++; console.log('FRESH  ', name, 'Cmd', c, '->', e.message.split('\n')[0]); } }
  fresh.close();
}
console.log(bad ? `${bad} problems in ${calls} calls` : `no crashes in ${calls} calls`);
